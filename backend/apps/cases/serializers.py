from rest_framework import serializers
from apps.cases.models import CaseRecord


class CaseRecordListSerializer(serializers.ModelSerializer):
    """
    Serializer for case list screens providing essential case fields and extra_fields.
    """
    class Meta:
        model = CaseRecord
        fields = [
            'id',
            'module_key',
            'title',
            'case_number',
            'description',
            'complainant',
            'accused',
            'location',
            'incident_date',
            'priority',
            'status',
            'assigned_officer',
            'assigned_officer_uid',
            'sub_category',
            'created_by',
            'station_name',
            'disposal_date',
            'extra_fields',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        try:
            extra = data.get('extra_fields')
            if not isinstance(extra, dict):
                extra = {}
                data['extra_fields'] = extra
            p_items = list(instance.preventive_action_items.all())
            if p_items:
                serialized_pa = [
                    {
                        'name': p.name or (p.person.name if p.person else None),
                        'action': p.action_type,
                        'action_type': p.action_type,
                        'action_date': p.action_date.strftime('%d/%m/%Y') if p.action_date else '',
                        'outward_number': p.outward_number or '',
                        'preventive_number': p.preventive_number or '',
                        'bond_date': p.bond_date.strftime('%d/%m/%Y') if p.bond_date else '',
                        'bond_cancellation_date': p.bond_cancellation_date.strftime('%d/%m/%Y') if p.bond_cancellation_date else '',
                    }
                    for p in p_items
                ]
                if not extra.get('preventive_actions'):
                    extra['preventive_actions'] = serialized_pa
                if not extra.get('preventive_action_items'):
                    extra['preventive_action_items'] = serialized_pa
                if not extra.get('preventive_action_type'):
                    extra['preventive_action_type'] = p_items[0].action_type
                if not extra.get('preventive_no') and p_items[0].preventive_number:
                    extra['preventive_no'] = p_items[0].preventive_number
                if not extra.get('preventive_outward_no') and p_items[0].outward_number:
                    extra['preventive_outward_no'] = p_items[0].outward_number
        except Exception:
            pass
        return data


class CaseRecordSerializer(serializers.ModelSerializer):
    arrest_date = serializers.SerializerMethodField()

    class Meta:
        model = CaseRecord
        fields = [
            'id',
            'module_key',
            'title',
            'case_number',
            'description',
            'complainant',
            'accused',
            'location',
            'incident_date',
            'priority',
            'status',
            'assigned_officer',
            'assigned_officer_uid',
            'sub_category',
            'created_by',
            'station_name',
            'extra_fields',
            'arrest_date',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
        extra_kwargs = {
            'module_key': {'required': False},
            'title': {'required': False},
            'case_number': {'required': False},
            'station_name': {'required': False, 'allow_blank': True},
            'created_by': {'required': False, 'allow_blank': True},
            'priority': {'required': False},
            'status': {'required': False},
            'extra_fields': {'required': False},
        }

    def get_arrest_date(self, obj):
        try:
            arrests = obj.persons.filter(arrest_status__arrest_datetime__isnull=False)
            if arrests.exists():
                return arrests.first().arrest_status.arrest_datetime.isoformat()
        except Exception:
            pass
        ex = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        return ex.get('arrest_datetime') or ex.get('arrest_date')

    def to_internal_value(self, data):
        if isinstance(data, dict):
            data = data.copy()
            known_fields = set(self.fields.keys())
            extra_fields = data.get('extra_fields')
            if not isinstance(extra_fields, dict):
                extra_fields = {}
            
            unknown_keys = [k for k in list(data.keys()) if k not in known_fields]
            for k in unknown_keys:
                extra_fields[k] = data.pop(k)
            
            data['extra_fields'] = extra_fields

        return super().to_internal_value(data)

    def validate_station_name(self, value):
        if not value or not str(value).strip():
            if self.instance and self.instance.station_name:
                return self.instance.station_name
            request = self.context.get('request')
            if request and hasattr(request, 'user'):
                station = getattr(request.user, 'station_name', '')
                if station:
                    return station
        return value or ''

    def validate_created_by(self, value):
        if not value or not str(value).strip():
            if self.instance and self.instance.created_by:
                return self.instance.created_by
            request = self.context.get('request')
            if request and hasattr(request, 'user'):
                uid = getattr(request.user, 'uid', getattr(request.user, 'id', ''))
                if uid:
                    return str(uid)
        return value or ''

    def validate_assigned_officer_uid(self, value):
        if value:
            from apps.users.models import OfficerProfile
            if not OfficerProfile.objects.filter(uid=value).exists():
                raise serializers.ValidationError("Invalid IO: Officer with this UID does not exist.")
        return value

    def validate(self, attrs):
        from apps.cases.constants import CC_ST_KEYS, REASON_KEYS, DISPOSAL_KEYS
        from apps.cases.cr_numbers import case_tab, duplicate_cr_message, normalize_cr

        # A CR number is used only once per tab of a station. An edit is checked only
        # when it changes the CR number, tab or station, so older duplicates stay editable.
        inst = self.instance
        case_number = attrs.get('case_number', getattr(inst, 'case_number', None))
        sub_category = attrs.get('sub_category', getattr(inst, 'sub_category', None))
        module_key = attrs.get('module_key', getattr(inst, 'module_key', None))
        station_name = attrs.get('station_name', getattr(inst, 'station_name', None))
        changed = inst is None or (
            normalize_cr(case_number) != normalize_cr(inst.case_number)
            or case_tab(sub_category, module_key) != case_tab(inst.sub_category, inst.module_key)
            or (station_name or '').strip().lower() != (inst.station_name or '').strip().lower()
        )
        message = changed and duplicate_cr_message(case_number, sub_category, module_key, station_name,
                                                   exclude_id=getattr(inst, 'pk', None))
        if message:
            raise serializers.ValidationError({'case_number': message})

        # Reject client status overrides
        if 'status' in attrs:
            attrs.pop('status')
            
        extra_fields = attrs.get('extra_fields')
        if extra_fields is None:
            extra_fields = {}
            if 'extra_fields' in attrs:
                attrs['extra_fields'] = extra_fields
            
        if self.instance and isinstance(self.instance.extra_fields, dict):
            # We must deeply merge dictionaries to avoid replacing entire nested objects
            def deep_merge(d1, d2):
                for k, v in d2.items():
                    if k in d1 and isinstance(d1[k], dict) and isinstance(v, dict):
                        deep_merge(d1[k], v)
                    else:
                        d1[k] = v
            
            merged = self.instance.extra_fields.copy()
            
            # Strip client-sent status_logs
            if 'status_logs' in extra_fields:
                extra_fields.pop('status_logs')
                
            deep_merge(merged, extra_fields)
            
            # Alias blanking recursively
            def find_keys(d, targets, found=None):
                if found is None: found = set()
                if isinstance(d, dict):
                    for k, v in d.items():
                        if k in targets: found.add(k)
                        find_keys(v, targets, found)
                return found

            def find_non_empty_keys(d, targets, found=None):
                if found is None: found = set()
                if isinstance(d, dict):
                    for k, v in d.items():
                        if k in targets and str(v).strip(): found.add(k)
                        find_non_empty_keys(v, targets, found)
                return found
                
            def delete_keys(d, targets):
                if isinstance(d, dict):
                    for k in list(d.keys()):
                        if k in targets:
                            del d[k]
                        else:
                            delete_keys(d[k], targets)
                            
            incoming_cc_keys = find_keys(extra_fields, DISPOSAL_KEYS)
            non_empty_cc_keys = find_non_empty_keys(extra_fields, DISPOSAL_KEYS)
            
            if incoming_cc_keys and not non_empty_cc_keys:
                # Client explicitly sent empty CC keys, meaning they removed it
                existing_cc_keys = find_non_empty_keys(self.instance.extra_fields, DISPOSAL_KEYS)
                if existing_cc_keys:
                    delete_keys(merged, DISPOSAL_KEYS)
                    from django.utils import timezone
                    if 'status_logs' not in merged:
                        merged['status_logs'] = []
                    merged['status_logs'].append({
                        'action': 'disposal_keys_removed',
                        'timestamp': timezone.now().isoformat()
                    })
            elif incoming_cc_keys:
                keys_to_delete = [k for k in DISPOSAL_KEYS if k not in incoming_cc_keys]
                delete_keys(merged, keys_to_delete)
                    
            attrs['extra_fields'] = merged
        elif extra_fields and 'status_logs' in extra_fields:
            extra_fields.pop('status_logs')

        return attrs

    def update(self, instance, validated_data):
        from django.utils import timezone
        extra_fields = validated_data.get('extra_fields')
        
        if extra_fields is not None:
            old_cc = instance.extra_fields.get('ccStNumber') or instance.extra_fields.get('cc_st_number')
            new_cc = extra_fields.get('ccStNumber') or extra_fields.get('cc_st_number')
            
            # If CC was removed, log it
            if old_cc and (not new_cc or str(new_cc).strip() == ''):
                if 'status_logs' not in extra_fields:
                    extra_fields['status_logs'] = []
                # Remove any identical action that might have been added by validate()
                extra_fields['status_logs'] = [log for log in extra_fields['status_logs'] if log.get('action') != 'cc_st_removed']
                
                extra_fields['status_logs'].insert(0, {
                    'action': 'cc_st_removed',
                    'timestamp': timezone.now().isoformat(),
                    'user_uid': getattr(self.context, '_current_user_uid', None)
                })
        
        return super().update(instance, validated_data)


class DisposalCaseRecordSerializer(CaseRecordSerializer):
    def to_representation(self, instance):
        data = super().to_representation(instance)
        from apps.cases.constants import DISPOSAL_KEYS, DISPOSAL_LABELS
        from apps.cases.constants import CC_ST_KEYS
        from apps.crimetab.models.groupings import CaseCategory
        
        extra = instance.extra_fields or {}
        mk = (instance.module_key or "").strip().lower()
        sub = (instance.sub_category or "").strip()
        
        types = []
        nums = []
        cc_st = []
        
        for key in DISPOSAL_KEYS:
            val = extra.get(key)
            if val is not None and str(val).strip():
                types.append(DISPOSAL_LABELS.get(key, key))
                nums.append(str(val).strip())
                
        for key in CC_ST_KEYS:
            val = extra.get(key)
            if val is not None and str(val).strip():
                cc_st.append(str(val).strip())

        is_ad = (mk == 'ad' or sub.lower() in ['ad', 'accidental death'])
        if is_ad and not types:
            from apps.cases.models import _extract_first_non_empty, AD_SUMMARY_NO_KEYS, AD_SUMMARY_DATE_KEYS
            ad_num = _extract_first_non_empty(extra, AD_SUMMARY_NO_KEYS)
            ad_date = _extract_first_non_empty(extra, AD_SUMMARY_DATE_KEYS)
            if ad_num:
                types.append("AD Summary No")
                nums.append(ad_num)
            if ad_date and not extra.get('disposal_date'):
                data['disposal_date'] = ad_date

        is_preventive = (mk in ['preventive', 'preventive_action', 'preventive_actions', 'chapter_case'] or
                         sub.lower() in ['preventive', 'preventive_action', 'chapter case', 'chapter_case', 'प्रतिबंधक कारवाई', 'प्रतिबंधक'])
        if is_preventive and not types:
            from apps.cases.models import _extract_first_non_empty, PREVENTIVE_NO_KEYS, PREVENTIVE_DATE_KEYS
            p_num = _extract_first_non_empty(extra, PREVENTIVE_NO_KEYS)
            p_date = _extract_first_non_empty(extra, PREVENTIVE_DATE_KEYS)
            istegasha_dict = extra.get('istegasha') if isinstance(extra.get('istegasha'), dict) else {}
            outward = extra.get('outwardNo') or extra.get('outwardNumber') or istegasha_dict.get('outwardNo') or istegasha_dict.get('outwardNumber')
            if p_num:
                types.append("Preventive No")
                nums.append(f"{p_num} (Outward: {outward})" if outward else p_num)
            if p_date and not extra.get('disposal_date'):
                data['disposal_date'] = p_date
                
        is_nc = (mk in ['nc', 'nc_register', 'nc_form'] or sub.lower() in ['nc', 'non-cognizable', 'non cognizable', 'nc register'])
        if is_nc and not types:
            p_details = extra.get('preventiveDetails') if isinstance(extra.get('preventiveDetails'), dict) else {}
            reason = extra.get('noPreventiveReason') or p_details.get('noPreventiveReason') or extra.get('preventive_not_done_reason') or extra.get('reason')
            p_num = p_details.get('preventiveNumber') or extra.get('preventiveNumber') or extra.get('preventiveNo') or extra.get('preventive_no')
            p_outward = p_details.get('outwardNumber') or extra.get('outwardNumber') or extra.get('preventiveOutwardNumber') or extra.get('preventive_outward_no')
            
            if reason:
                other = extra.get('noPreventiveOtherDetails')
                reason_str = f"{reason} ({other})" if (str(reason).lower() == 'other' and other) else str(reason)
                types.append("No Preventive")
                nums.append(reason_str)
            elif p_num or p_outward:
                types.append("Preventive Action")
                parts = []
                if p_num: parts.append(f"No: {p_num}")
                if p_outward: parts.append(f"Outward: {p_outward}")
                nums.append(", ".join(parts))

        data['disposal_type'] = ", ".join(types) if types else "N/A"
        data['disposal_no'] = ", ".join(nums) if nums else "N/A"
        data['disposal_date'] = extra.get('disposal_date') or data.get('disposal_date') or 'N/A'
        
        # Dedupe cc_st_no and return "" if empty
        unique_cc_st = []
        for x in cc_st:
            if x not in unique_cc_st:
                unique_cc_st.append(x)
        data['cc_st_no'] = ", ".join(unique_cc_st) if unique_cc_st else ""
        
        # Get crime_type_name from CaseCategory via context map
        cat_map = self.context.get('cat_map', {})
        
        # Priority: 
        # If it's a generic form (like form_1_5), the actual crime name (e.g., Murder, Sand Theft) is in sub_category
        if mk == 'form_1_5':
            data['crime_type_name'] = sub if sub else 'Other Crimes'
        elif is_ad:
            data['crime_type_name'] = 'Accidental Death (A.D.)'
        elif is_preventive:
            data['crime_type_name'] = 'Preventive Action (प्रतिबंधक कारवाई)'
        elif sub and not cat_map.get(mk):
            data['crime_type_name'] = sub
        else:
            data['crime_type_name'] = cat_map.get(mk, sub if sub else instance.module_key)
        
        # Extract act and section from acts_sections if present
        acts_sections = extra.get('acts_sections', [])
        if isinstance(acts_sections, list) and acts_sections:
            first_as = acts_sections[0]
            if isinstance(first_as, dict):
                data['act'] = first_as.get('act') or extra.get('act') or extra.get('preventiveAct') or ''
                data['section'] = first_as.get('section') or extra.get('section') or extra.get('sections') or extra.get('preventiveSecAct') or extra.get('preventiveSectionAct') or ''
        else:
            data['act'] = extra.get('act') or extra.get('preventiveAct') or ''
            data['section'] = extra.get('section') or extra.get('sections') or extra.get('preventiveSecAct') or extra.get('preventiveSectionAct') or ''
        
        return data

class CreateCaseSerializer(serializers.Serializer):
    """
    Strict serializer for raw SQL case creation endpoint.
    Validates required fields, lengths, choices, and data types before DB insertion.
    """
    PRIORITY_CHOICES = ('Low', 'Medium', 'High', 'Critical')
    STATUS_CHOICES = ('Draft', 'Pending', 'Detected', 'Disposal', 'Closed', 'Open')

    case_number = serializers.CharField(max_length=128, required=True, allow_blank=False, trim_whitespace=True)
    title = serializers.CharField(max_length=255, required=True, allow_blank=False, trim_whitespace=True)
    module = serializers.CharField(max_length=64, required=True, allow_blank=False, trim_whitespace=True)
    priority = serializers.ChoiceField(choices=PRIORITY_CHOICES, default='Low', required=False)
    status = serializers.ChoiceField(choices=STATUS_CHOICES, default='Draft', required=False)
    case_type = serializers.CharField(max_length=64, default='1-5', required=False, allow_blank=True)
    crime_type_master_id = serializers.IntegerField(required=False, allow_null=True, default=None)
    description = serializers.CharField(required=False, allow_blank=True, default='')
    station_name = serializers.CharField(max_length=255, required=False, allow_blank=True, default='')

    def validate_case_number(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("case_number cannot be blank.")
        return value.strip()

    def validate_title(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("title cannot be blank.")
        return value.strip()

    def validate_module(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("module cannot be blank.")
        return value.strip()

from rest_framework import serializers
from apps.cases.models import CaseRecord, _extract_first_non_empty
from apps.cases.constants import CC_ST_KEYS

def format_section_act(val):
    if not val:
        return ''
    
    # If val is a string, check if it's a stringified python/json list or dict
    if isinstance(val, str):
        s = val.strip()
        if (s.startswith('[') and s.endswith(']')) or (s.startswith('{') and s.endswith('}')):
            import ast, json
            parsed = None
            try:
                parsed = json.loads(s)
            except Exception:
                try:
                    parsed = ast.literal_eval(s)
                except Exception:
                    parsed = None
            if parsed is not None:
                return format_section_act(parsed)
        if s in ('None', 'null', '[]', '{}'):
            return ''
        return s

    if isinstance(val, list):
        items = []
        for item in val:
            formatted = format_section_act(item)
            if formatted and formatted not in items:
                items.append(formatted)
        return ', '.join(items)

    if isinstance(val, dict):
        if val.get('otherSections'):
            return str(val['otherSections']).strip()
        
        act = val.get('act_name') or val.get('act') or ''
        if isinstance(act, dict):
            act = act.get('act_name') or act.get('name') or ''
        elif not isinstance(act, str):
            act = '' if act is None or isinstance(act, (int, float)) else str(act)
        act = act.strip()
        if act in ('None', 'null'):
            act = ''

        # Normalize common Act names to short abbreviations
        act_lower = act.lower()
        if 'bharatiya nyaya' in act_lower or act_lower == 'bns':
            act = 'BNS'
        elif 'indian penal' in act_lower or act_lower == 'ipc':
            act = 'IPC'
        elif 'nagarik suraksha' in act_lower or 'nagrik suraksha' in act_lower or act_lower == 'bnss':
            act = 'BNSS'
        elif 'sakshya' in act_lower or act_lower == 'bsa':
            act = 'BSA'
        elif 'protection of children' in act_lower or 'pocso' in act_lower:
            act = 'POCSO'

        sec = val.get('subsection_code') or val.get('section_number') or val.get('section') or val.get('section_title') or ''
        if isinstance(sec, dict):
            sec = sec.get('number') or sec.get('section_number') or ''
        elif not isinstance(sec, str):
            sec = '' if sec is None else str(sec)
        sec = sec.strip()
        if sec in ('None', 'null'):
            sec = ''

        parts = []
        if act:
            parts.append(act)
        if sec:
            if not sec.lower().startswith('sec') and not parts:
                parts.append(f"Sec. {sec}")
            else:
                parts.append(sec)

        if parts:
            return ' '.join(parts)
        
        # Fallback to other sub-fields in dict
        for k in ['section', 'act', 'sections']:
            sub_val = val.get(k)
            if sub_val and sub_val != val and not isinstance(sub_val, (int, float)):
                res = format_section_act(sub_val)
                if res:
                    return res
        return ''

    return str(val).strip()


def extract_section_act(extra_fields):
    if not isinstance(extra_fields, dict):
        return ''
    
    if extra_fields.get('acts_sections'):
        res = format_section_act(extra_fields['acts_sections'])
        if res:
            return res

    sections = extra_fields.get('sections', {})
    if isinstance(sections, dict) and sections.get('otherSections'):
        return str(sections['otherSections']).strip()
        
    for key in ['otherSections', 'section', 'act', 'sectionAct', 'section_act']:
        if key in extra_fields and extra_fields[key]:
            res = format_section_act(extra_fields[key])
            if res:
                return res
            
    # Try searching in nested objects
    for val in extra_fields.values():
        if isinstance(val, dict):
            res = format_section_act(val)
            if res:
                return res
    return ''



class VictimCaseRecordSerializer(serializers.ModelSerializer):
    sr_no = serializers.IntegerField(read_only=True)
    parsed_date = serializers.SerializerMethodField()
    victim_details = serializers.SerializerMethodField()

    class Meta:
        model = CaseRecord
        fields = [
            'id', 'sr_no', 'module_key', 'title', 'case_number', 'description',
            'sub_category', 'status', 'station_name', 'incident_date', 'created_at',
            'parsed_date', 'victim_details', 'cc_st_number'
        ]

    cc_st_number = serializers.SerializerMethodField()

    def get_cc_st_number(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        cc = (extra.get('cc_st_number') or extra.get('ccStNumber') or extra.get('cc_st_no') or extra.get('ccStNo') or '')
        return str(cc).strip()

    def get_parsed_date(self, obj):
        return obj.incident_date.strftime('%Y-%m-%d') if obj.incident_date else ''

    def get_victim_details(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        
        # Determine module category name
        category = obj.sub_category or obj.module_key or ""
        
        # Generic KYC extractors
        def extract_age(k_dict):
            age_val = k_dict.get('age') or k_dict.get('Age')
            if age_val:
                try:
                    return int(float(str(age_val).replace('Y', '').replace('y', '').strip()))
                except ValueError:
                    return 0
            return 0
            
        def extract_gender(k_dict):
            g = str(k_dict.get('gender') or k_dict.get('Gender') or '').lower()
            if g.startswith('m'): return 'Male'
            if g.startswith('f'): return 'Female'
            if g.startswith('t') or g.startswith('o'): return 'Transgender'
            return 'Unknown'
            
        def get_age_category(age):
            if age < 0: return 'Unknown'
            if age < 5: return 'Below 5 Years'
            if age <= 10: return '5-10 Years'
            if age <= 15: return '11-15 Years'
            if age < 18: return '16-18 Years'
            if age < 60: return '18-59 Years'
            return '60 Years and Above'

        victims = []
        
        # Check if list of victims/kyc is in extra_fields
        kyc_list = extra.get('kyc_details') or extra.get('victims') or extra.get('persons')
        if isinstance(kyc_list, list) and len(kyc_list) > 0:
            for idx, kyc in enumerate(kyc_list):
                if not isinstance(kyc, dict): continue
                age = extract_age(kyc)
                victims.append({
                    'serial_no': idx + 1,
                    'name': kyc.get('name') or kyc.get('fullName') or 'Unknown',
                    'gender': extract_gender(kyc),
                    'age': age,
                    'age_category': get_age_category(age),
                    'injured': bool(kyc.get('injured') or kyc.get('is_injured')),
                    'deceased': bool(kyc.get('deceased') or kyc.get('is_deceased')),
                    'missing': bool(kyc.get('missing') or kyc.get('is_missing')),
                    'traced': bool(kyc.get('traced') or kyc.get('is_traced')),
                })
        else:
            # Fallback to singular victim data in extra_fields
            name = extra.get('victim_name') or extra.get('victimName') or extra.get('complainant') or 'Unknown'
            age = extract_age(extra)
            gender = extract_gender(extra)
            
            # Additional statuses from extra_fields
            injured = bool(extra.get('is_injured') or (str(extra.get('injury_type')).strip() != ''))
            deceased = bool(extra.get('is_deceased') or 'death' in str(extra.get('outcome')).lower())
            missing = obj.module_key == 'missing' or bool(extra.get('is_missing'))
            traced = bool(extra.get('is_traced') or obj.status == 'Traced' or (missing and obj.status in ['Disposal', 'Detected', 'Closed']))

            victims.append({
                'serial_no': 1,
                'name': name,
                'gender': gender,
                'age': age,
                'age_category': get_age_category(age),
                'injured': injured,
                'deceased': deceased,
                'missing': missing,
                'traced': traced,
            })
            
        return {
            'crime_category': category,
            'victims_list': victims
        }


from datetime import datetime, date
from django.utils import timezone

class ItssoCaseRecordSerializer(serializers.ModelSerializer):
    sr_no = serializers.IntegerField(read_only=True)
    charge_sheet_date = serializers.SerializerMethodField()
    itsso_status_color = serializers.SerializerMethodField()
    itsso_status = serializers.SerializerMethodField()
    section_act = serializers.SerializerMethodField()
    days_passed = serializers.SerializerMethodField()
    action_required = serializers.SerializerMethodField()

    class Meta:
        model = CaseRecord
        fields = [
            'id', 'sr_no', 'case_number', 'section_act', 'charge_sheet_date', 'assigned_officer', 'itsso_status', 'itsso_status_color', 'created_at', 'station_name', 'days_passed', 'action_required'
        ]

    def _get_cs_date(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        cs_date_str = extra.get('charge_sheet_date') or extra.get('chargeSheetDate') or extra.get('cs_date')
        if not cs_date_str:
            return None
        try:
            if isinstance(cs_date_str, str):
                return datetime.strptime(cs_date_str.split('T')[0], '%Y-%m-%d').date()
            return None
        except Exception:
            return None

    def get_charge_sheet_date(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        cs_no = extra.get('charge_sheet_number') or extra.get('charge_sheet_no') or extra.get('cc_st_number') or extra.get('ccStNumber')
        if cs_no:
            return str(cs_no)
        d = self._get_cs_date(obj)
        return d.strftime('%Y-%m-%d') if d else ''

    def get_section_act(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        if extra.get('acts_sections'):
            formatted = format_section_act(extra['acts_sections'])
            if formatted:
                return formatted
        for key in ['section_act', 'section', 'act_section', 'sections', 'sectionAct']:
            if extra.get(key):
                formatted = format_section_act(extra[key])
                if formatted:
                    return formatted
        if obj.description:
            return format_section_act(obj.description)
        return ''
        
    def _has_charge_sheet(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        cs_no = extra.get('charge_sheet_number') or extra.get('charge_sheet_no') or extra.get('cc_st_number') or extra.get('ccStNumber')
        return bool(cs_no)

    def get_itsso_status_color(self, obj):
        return 'Green' if self._has_charge_sheet(obj) else 'Red'

    def get_itsso_status(self, obj):
        return 'Chargesheeted' if self._has_charge_sheet(obj) else 'Pending'

    def get_days_passed(self, obj):
        reg_date = obj.created_at.date() if obj.created_at else timezone.now().date()
        return (timezone.now().date() - reg_date).days
        
    def get_action_required(self, obj):
        # Red button logic: >60 days and no chargesheet
        reg_date = obj.created_at.date() if obj.created_at else timezone.now().date()
        days_passed = (timezone.now().date() - reg_date).days
        return not self._has_charge_sheet(obj)

def format_section_act(val):
    if not val:
        return ''
    
    # If val is a string, check if it's a stringified python/json list or dict
    if isinstance(val, str):
        s = val.strip()
        if (s.startswith('[') and s.endswith(']')) or (s.startswith('{') and s.endswith('}')):
            import ast, json
            parsed = None
            try:
                parsed = json.loads(s)
            except Exception:
                try:
                    parsed = ast.literal_eval(s)
                except Exception:
                    parsed = None
            if parsed is not None:
                return format_section_act(parsed)
        if s in ('None', 'null', '[]', '{}'):
            return ''
        return s

    if isinstance(val, list):
        items = []
        for item in val:
            formatted = format_section_act(item)
            if formatted and formatted not in items:
                items.append(formatted)
        return ', '.join(items)

    if isinstance(val, dict):
        if val.get('otherSections'):
            return str(val['otherSections']).strip()
        
        act = val.get('act_name') or val.get('act') or ''
        if isinstance(act, dict):
            act = act.get('act_name') or act.get('name') or ''
        elif not isinstance(act, str):
            act = '' if act is None or isinstance(act, (int, float)) else str(act)
        act = act.strip()
        if act in ('None', 'null'):
            act = ''

        # Normalize common Act names to short abbreviations
        act_lower = act.lower()
        if 'bharatiya nyaya' in act_lower or act_lower == 'bns':
            act = 'BNS'
        elif 'indian penal' in act_lower or act_lower == 'ipc':
            act = 'IPC'
        elif 'nagarik suraksha' in act_lower or 'nagrik suraksha' in act_lower or act_lower == 'bnss':
            act = 'BNSS'
        elif 'sakshya' in act_lower or act_lower == 'bsa':
            act = 'BSA'
        elif 'protection of children' in act_lower or 'pocso' in act_lower:
            act = 'POCSO'

        sec = val.get('subsection_code') or val.get('section_number') or val.get('section') or val.get('section_title') or ''
        if isinstance(sec, dict):
            sec = sec.get('number') or sec.get('section_number') or ''
        elif not isinstance(sec, str):
            sec = '' if sec is None else str(sec)
        sec = sec.strip()
        if sec in ('None', 'null'):
            sec = ''

        parts = []
        if act:
            parts.append(act)
        if sec:
            if not sec.lower().startswith('sec') and not parts:
                parts.append(f"Sec. {sec}")
            else:
                parts.append(sec)

        if parts:
            return ' '.join(parts)
        
        # Fallback to other sub-fields in dict
        for k in ['section', 'act', 'sections']:
            sub_val = val.get(k)
            if sub_val and sub_val != val and not isinstance(sub_val, (int, float)):
                res = format_section_act(sub_val)
                if res:
                    return res
        return ''

    return str(val).strip()


class DarCaseRecordSerializer(serializers.ModelSerializer):
    """
    Serializer for DAR (Detailed Accident Report) Road Accident cases.
    Provides table-ready attributes:
    - Sr. No. (sr_no)
    - CR No. (cr_no / case_number)
    - Act and Section (act_and_section)
    - IO Name (io_name)
    - Status (status: Pending / Filled)
    - Status Color (status_color: Red / Green)
    - Remind Action (can_remind)
    """
    sr_no = serializers.IntegerField(read_only=True, required=False)
    cr_no = serializers.CharField(source='case_number', read_only=True)
    act_and_section = serializers.SerializerMethodField()
    io_name = serializers.SerializerMethodField()
    io_uid = serializers.CharField(source='assigned_officer_uid', read_only=True)
    status = serializers.SerializerMethodField()
    dar_status = serializers.SerializerMethodField()
    status_color = serializers.SerializerMethodField()
    dar_date = serializers.SerializerMethodField()
    dar_fields = serializers.SerializerMethodField()
    can_remind = serializers.SerializerMethodField()

    class Meta:
        model = CaseRecord
        fields = [
            'id',
            'sr_no',
            'cr_no',
            'case_number',
            'act_and_section',
            'io_name',
            'io_uid',
            'status',
            'dar_status',
            'status_color',
            'dar_date',
            'dar_fields',
            'can_remind',
            'station_name',
            'sub_category',
            'module_key',
            'incident_date',
            'created_at',
            'extra_fields',
        ]

    def _get_eval(self, obj):
        if self.context and 'dar_eval' in self.context:
            return self.context['dar_eval']
        from apps.cases.dar_service import RoadAccidentDarService
        return RoadAccidentDarService.evaluate_case_dar(obj)

    def get_status(self, obj):
        return self._get_eval(obj).get('status', 'Pending')

    def get_dar_status(self, obj):
        return self._get_eval(obj).get('status', 'Pending')

    def get_status_color(self, obj):
        return self._get_eval(obj).get('status_color', '#E74C3C')

    def get_dar_date(self, obj):
        return self._get_eval(obj).get('dar_date')

    def get_dar_fields(self, obj):
        return self._get_eval(obj).get('dar_fields', {})

    def get_can_remind(self, obj):
        return self._get_eval(obj).get('can_remind', True)

    def get_io_name(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        name = (
            obj.assigned_officer
            or extra.get('io_name')
            or extra.get('assigned_officer')
            or ''
        )
        return str(name).strip() or '-'

    def get_act_and_section(self, obj):
        # 1. Fetch from relational database table CrimeCaseActsSections
        try:
            from apps.crimetab.models.common_form import CrimeCaseActsSections
            acts_rel = CrimeCaseActsSections.objects.filter(case=obj).select_related('act', 'section')
            act_list = []
            for item in acts_rel:
                act_name = item.act.act_name if item.act and item.act.act_name else ''
                sec_num = item.section.section_number if item.section and item.section.section_number else ''
                combined = f"{act_name} {sec_num}".strip()
                if combined:
                    act_list.append(combined)
            if act_list:
                return ", ".join(act_list)
        except Exception:
            pass

        # 2. Fetch from extra_fields stored during form submission
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        for key in ['acts_sections', 'section_act', 'act_section', 'charges']:
            if extra.get(key):
                formatted = format_section_act(extra[key])
                if formatted and 'None' not in formatted and formatted.strip():
                    return formatted.strip()

        # 3. Fetch from direct charges or act_id / section_id in database
        if getattr(obj, 'charges', None):
            act_str = str(obj.charges).strip()
            if act_str and 'None' not in act_str:
                return act_str

        act_id = extra.get('act_id') or getattr(obj, 'act_id', None)
        section_id = extra.get('section_id') or getattr(obj, 'section_id', None)
        if act_id or section_id:
            try:
                from apps.crimetab.models.common_form import Act, ActSection
                act_name = ''
                sec_num = ''
                if act_id:
                    act_obj = Act.objects.filter(act_id=act_id).first()
                    if act_obj and act_obj.act_name:
                        act_name = act_obj.act_name
                if section_id:
                    sec_obj = ActSection.objects.filter(section_id=section_id).first()
                    if sec_obj and sec_obj.section_number:
                        sec_num = sec_obj.section_number
                combined = f"{act_name} {sec_num}".strip()
                if combined:
                    return combined
            except Exception:
                pass

        # 4. Check sub_category or title from database record
        if obj.sub_category and str(obj.sub_category).strip():
            return str(obj.sub_category).strip()

        if obj.title and str(obj.title).strip():
            return str(obj.title).strip()

        return '-'


class IradCaseRecordSerializer(serializers.ModelSerializer):
    """
    Dedicated dynamic serializer for Road Accident IRAD Table.
    Outputs:
    - Sr. No.
    - CR No.
    - Act and Section
    - IO Name
    - Status (Pending/Filled)
    - Action Button / Remind to IO (can_remind)
    """
    sr_no = serializers.IntegerField(read_only=True)
    cr_no = serializers.CharField(source='case_number', read_only=True)
    act_and_section = serializers.SerializerMethodField()
    io_name = serializers.SerializerMethodField()
    io_uid = serializers.CharField(source='assigned_officer_uid', read_only=True)
    status = serializers.SerializerMethodField()
    irad_status = serializers.SerializerMethodField()
    status_color = serializers.SerializerMethodField()
    irad_date = serializers.SerializerMethodField()
    irad_fields = serializers.SerializerMethodField()
    can_remind = serializers.SerializerMethodField()

    class Meta:
        model = CaseRecord
        fields = [
            'id',
            'sr_no',
            'cr_no',
            'case_number',
            'act_and_section',
            'io_name',
            'io_uid',
            'status',
            'irad_status',
            'status_color',
            'irad_date',
            'irad_fields',
            'can_remind',
            'station_name',
            'sub_category',
            'module_key',
            'incident_date',
            'created_at',
            'extra_fields',
        ]

    def _get_eval(self, obj):
        if self.context and 'irad_eval' in self.context:
            return self.context['irad_eval']
        from apps.cases.irad_service import RoadAccidentIradService
        return RoadAccidentIradService.evaluate_case_irad(obj)

    def get_status(self, obj):
        return self._get_eval(obj).get('status', 'Pending')

    def get_irad_status(self, obj):
        return self._get_eval(obj).get('status', 'Pending')

    def get_status_color(self, obj):
        return self._get_eval(obj).get('status_color', '#E74C3C')

    def get_irad_date(self, obj):
        return self._get_eval(obj).get('irad_date')

    def get_irad_fields(self, obj):
        return self._get_eval(obj).get('irad_fields', {})

    def get_can_remind(self, obj):
        return self._get_eval(obj).get('can_remind', True)

    def get_io_name(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        name = (
            obj.assigned_officer
            or extra.get('io_name')
            or extra.get('assigned_officer')
            or ''
        )
        return str(name).strip() or '-'

    def get_act_and_section(self, obj):
        # 1. Fetch from relational database table CrimeCaseActsSections
        try:
            from apps.crimetab.models.common_form import CrimeCaseActsSections
            acts_rel = CrimeCaseActsSections.objects.filter(case=obj).select_related('act', 'section')
            act_list = []
            for item in acts_rel:
                act_name = item.act.act_name if item.act and item.act.act_name else ''
                sec_num = item.section.section_number if item.section and item.section.section_number else ''
                combined = f"{act_name} {sec_num}".strip()
                if combined:
                    act_list.append(combined)
            if act_list:
                return ", ".join(act_list)
        except Exception:
            pass

        # 2. Fetch from extra_fields stored during form submission
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        for key in ['acts_sections', 'section_act', 'act_section', 'charges']:
            if extra.get(key):
                formatted = format_section_act(extra[key])
                if formatted and 'None' not in formatted and formatted.strip():
                    return formatted.strip()

        # 3. Fetch from direct charges or act_id / section_id in database
        if getattr(obj, 'charges', None):
            act_str = str(obj.charges).strip()
            if act_str and 'None' not in act_str:
                return act_str

        act_id = extra.get('act_id') or getattr(obj, 'act_id', None)
        section_id = extra.get('section_id') or getattr(obj, 'section_id', None)
        if act_id or section_id:
            try:
                from apps.crimetab.models.common_form import Act, ActSection
                act_name = ''
                sec_num = ''
                if act_id:
                    act_obj = Act.objects.filter(act_id=act_id).first()
                    if act_obj and act_obj.act_name:
                        act_name = act_obj.act_name
                if section_id:
                    sec_obj = ActSection.objects.filter(section_id=section_id).first()
                    if sec_obj and sec_obj.section_number:
                        sec_num = sec_obj.section_number
                combined = f"{act_name} {sec_num}".strip()
                if combined:
                    return combined
            except Exception:
                pass

        # 4. Check sub_category or title from database record
        if obj.sub_category and str(obj.sub_category).strip():
            return str(obj.sub_category).strip()

        if obj.title and str(obj.title).strip():
            return str(obj.title).strip()

        return '-'


class NafisCaseRecordSerializer(serializers.ModelSerializer):
    sr_no = serializers.IntegerField(read_only=True)
    charge_sheet_date = serializers.SerializerMethodField()
    nafis_status_color = serializers.SerializerMethodField()
    nafis_status = serializers.SerializerMethodField()
    section_act = serializers.SerializerMethodField()
    accused_name = serializers.SerializerMethodField()
    head = serializers.SerializerMethodField()
    days_passed = serializers.SerializerMethodField()
    action_required = serializers.SerializerMethodField()

    class Meta:
        model = CaseRecord
        fields = [
            'id', 'sr_no', 'case_number', 'section_act', 'head', 'sub_category', 'title', 'charge_sheet_date',
            'assigned_officer', 'accused_name', 'accused', 'nafis_status', 'nafis_status_color',
            'created_at', 'station_name', 'days_passed', 'action_required', 'extra_fields'
        ]

    def _get_cs_date(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        court = extra.get('court') or extra.get('commonForm', {}).get('court') or extra.get('courtDisposal') or {}
        cs_date_str = (
            extra.get('charge_sheet_date') or 
            extra.get('chargeSheetDate') or 
            extra.get('chargesheet_date') or 
            extra.get('cs_date') or 
            extra.get('csDate') or 
            court.get('chargeSheetDate') or 
            court.get('charge_sheet_date') or 
            court.get('chargesheet_date')
        )
        if not cs_date_str:
            return None
        try:
            if isinstance(cs_date_str, str):
                return datetime.strptime(cs_date_str.split('T')[0], '%Y-%m-%d').date()
            return None
        except Exception:
            return None

    def get_charge_sheet_date(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        court = extra.get('court') or extra.get('commonForm', {}).get('court') or extra.get('courtDisposal') or {}
        cs_no = (
            extra.get('charge_sheet_number') or 
            extra.get('charge_sheet_no') or 
            extra.get('cc_st_number') or 
            extra.get('ccStNumber') or
            court.get('chargeSheetNumber') or
            court.get('charge_sheet_no') or
            court.get('ccStNumber')
        )
        if cs_no:
            return str(cs_no)
        d = self._get_cs_date(obj)
        return d.strftime('%Y-%m-%d') if d else ''

    def get_section_act(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        if extra.get('acts_sections'):
            formatted = format_section_act(extra['acts_sections'])
            if formatted:
                return formatted

        for key in ['section_act', 'section', 'act_section', 'sections', 'sectionAct']:
            if extra.get(key):
                formatted = format_section_act(extra[key])
                if formatted:
                    return formatted

        if obj.description:
            formatted = format_section_act(obj.description)
            if formatted:
                return formatted

        return ''

    def get_head(self, obj):
        return obj.sub_category or obj.title or ''

    def get_accused_name(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        name = (
            getattr(obj, 'accused', None) or
            extra.get('accused_name') or
            extra.get('accused') or
            extra.get('commonForm', {}).get('accused') or
            extra.get('commonForm', {}).get('accused_name') or
            extra.get('commonForm', {}).get('accused_list') or
            extra.get('accused_list') or
            extra.get('commonForm', {}).get('suspected_accused_name') or
            ''
        )
        if isinstance(name, list):
            items = [str(x.get('name') if isinstance(x, dict) else x).strip() for x in name if x]
            res = ', '.join([x for x in items if x and x not in ('None', 'null')])
            if res:
                return res
        if isinstance(name, dict):
            res = str(name.get('name') or name.get('accused_name') or '').strip()
            if res and res not in ('None', 'null'):
                return res
        s = str(name).strip()
        if s and s not in ('None', 'null', '[]', '{}'):
            return s
        try:
            persons = obj.persons.filter(role__in=['accused', 'suspected_accused', 'suspect'])
            if persons.exists():
                return ', '.join([p.name.strip() for p in persons if p.name and p.name.strip()])
        except Exception:
            pass
        return ''

    def _has_charge_sheet(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        court = extra.get('court') or extra.get('commonForm', {}).get('court') or extra.get('courtDisposal') or {}
        cs_no = (
            extra.get('charge_sheet_number') or 
            extra.get('charge_sheet_no') or 
            extra.get('cc_st_number') or 
            extra.get('ccStNumber') or
            court.get('chargeSheetNumber') or
            court.get('charge_sheet_no') or
            court.get('ccStNumber')
        )
        return bool(cs_no)

    def _has_fingerprint_taken(self, obj):
        extra = obj.extra_fields if isinstance(obj.extra_fields, dict) else {}
        inv = extra.get('investigationNotes') or extra.get('commonForm', {}).get('investigationNotes') or {}
        forensics = getattr(obj, 'forensics', None)
        
        # Check forensics model relationship if available
        if forensics:
            if getattr(forensics, 'fingerprint_taken', None) is True or getattr(forensics, 'nafis_fingerprint', None) is True:
                return True
        
        # Check explicit booleans
        if extra.get('fingerprint_taken') is True or extra.get('nafis_fingerprint') is True:
            return True
        if extra.get('fingerprintTaken') is True or extra.get('nafisFingerprint') is True:
            return True
        if inv.get('fingerprint_taken') is True or inv.get('nafis_fingerprint') is True:
            return True

        # Check string values and dates
        fp_val = str(extra.get('fingerprintVal') or inv.get('fingerprintVal') or extra.get('fingerprint_taken') or '').strip().lower()
        fp_date = str(extra.get('fingerprintDate') or inv.get('fingerprintDate') or '').strip()
        nafis_val = str(extra.get('nafisFingerprint') or extra.get('nafis_fingerprint') or inv.get('nafisFingerprint') or '').strip().lower()
        nafis_date = str(extra.get('nafisDate') or inv.get('nafisDate') or '').strip()

        if fp_val in ['yes', 'true'] or nafis_val in ['yes', 'true']:
            return True
        if fp_date or nafis_date:
            return True
            
        return False

    def get_nafis_status_color(self, obj):
        return 'Green' if self._has_fingerprint_taken(obj) else 'Red'

    def get_nafis_status(self, obj):
        return 'Done' if self._has_fingerprint_taken(obj) else 'Pending'

    def get_days_passed(self, obj):
        reg_date = obj.created_at.date() if obj.created_at else timezone.now().date()
        return (timezone.now().date() - reg_date).days

    def get_action_required(self, obj):
        return not self._has_fingerprint_taken(obj)

