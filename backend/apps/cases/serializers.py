from rest_framework import serializers
from apps.cases.models import CaseRecord


class CaseRecordListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for case list screens to minimize egress.
    Omits heavy extra_fields JSON payload and deep relations.
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
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


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
                
        data['disposal_type'] = ", ".join(types) if types else "N/A"
        data['disposal_no'] = ", ".join(nums) if nums else "N/A"
        data['disposal_date'] = extra.get('disposal_date', 'N/A')
        
        # Dedupe cc_st_no and return "" if empty
        unique_cc_st = []
        for x in cc_st:
            if x not in unique_cc_st:
                unique_cc_st.append(x)
        data['cc_st_no'] = ", ".join(unique_cc_st) if unique_cc_st else ""
        
        # Get crime_type_name from CaseCategory via context map
        cat_map = self.context.get('cat_map', {})
        mk = (instance.module_key or "").strip().lower()
        sub = (instance.sub_category or "").strip()
        
        # Priority: 
        # If it's a generic form (like form_1_5), the actual crime name (e.g., Murder, Sand Theft) is in sub_category
        if mk == 'form_1_5':
            data['crime_type_name'] = sub if sub else 'Other Crimes'
        elif sub and not cat_map.get(mk):
            data['crime_type_name'] = sub
        else:
            data['crime_type_name'] = cat_map.get(mk, sub if sub else instance.module_key)
        
        # Extract act and section from acts_sections if present
        acts_sections = extra.get('acts_sections', [])
        if isinstance(acts_sections, list) and acts_sections:
            first_as = acts_sections[0]
            if isinstance(first_as, dict):
                data['act'] = first_as.get('act') or extra.get('act') or ''
                data['section'] = first_as.get('section') or extra.get('section') or ''
        else:
            data['act'] = extra.get('act') or ''
            data['section'] = extra.get('section') or ''
        
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

def extract_section_act(extra_fields):
    if not isinstance(extra_fields, dict):
        return ''
    
    sections = extra_fields.get('sections', {})
    if isinstance(sections, dict) and sections.get('otherSections'):
        return str(sections['otherSections']).strip()
        
    for key in ['otherSections', 'section', 'act']:
        if key in extra_fields and str(extra_fields[key]).strip():
            return str(extra_fields[key]).strip()
            
    # Try searching in nested objects
    for val in extra_fields.values():
        if isinstance(val, dict):
            if val.get('otherSections'):
                return str(val['otherSections']).strip()
            if val.get('section'):
                return str(val['section']).strip()
            if val.get('act'):
                return str(val['act']).strip()
    return ''
