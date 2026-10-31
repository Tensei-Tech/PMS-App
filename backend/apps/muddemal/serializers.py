from typing import Optional, List, Dict, Any
from rest_framework import serializers
from decimal import Decimal
from apps.muddemal.models import (
    MuddemalRegister,
    MuddemalPropertyCategory,
    MuddemalFieldDefinition,
    MuddemalProperty,
    MuddemalPropertyMovement,
    MuddemalFSLRecord,
    MuddemalDisposal,
    MuddemalAuditLog,
    MuddemalConfig,
)
from apps.muddemal.services.valuation_service import calculate_register_valuations, compute_item_value


class MuddemalConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = MuddemalConfig
        fields = ['id', 'config_key', 'config_value', 'description', 'updated_at']


class MuddemalPropertyCategorySerializer(serializers.ModelSerializer):
    fields_count = serializers.SerializerMethodField()
    category_label = serializers.SerializerMethodField()

    class Meta:
        model = MuddemalPropertyCategory
        fields = [
            'id',
            'category_code',
            'category_name',
            'category_label',
            'is_active',
            'display_order',
            'applicable_property_rules',
            'fields_count',
        ]

    def get_fields_count(self, obj) -> int:
        return obj.field_definitions.filter(is_active=True).count()

    def get_category_label(self, obj) -> str:
        try:
            cfg = MuddemalConfig.objects.filter(config_key='ui_labels').first()
            if cfg and isinstance(cfg.config_value, dict):
                return cfg.config_value.get('property_category_label', 'Type of Property')
        except Exception:
            pass
        return 'Type of Property'


class MuddemalFieldDefinitionSerializer(serializers.ModelSerializer):
    category_code = serializers.CharField(source='category.category_code', read_only=True)
    category_name = serializers.CharField(source='category.category_name', read_only=True)

    class Meta:
        model = MuddemalFieldDefinition
        fields = [
            'id',
            'category',
            'category_code',
            'category_name',
            'field_key',
            'display_label',
            'field_type',
            'is_required',
            'validation_rules',
            'dropdown_options',
            'default_value',
            'visibility_conditions',
            'display_order',
            'is_active',
        ]


class MuddemalPropertyMovementSerializer(serializers.ModelSerializer):
    class Meta:
        model = MuddemalPropertyMovement
        fields = [
            'id',
            'property',
            'from_location',
            'to_location',
            'movement_type',
            'movement_date',
            'responsible_officer',
            'reference_no',
            'remarks',
            'created_by',
            'created_at',
        ]
        read_only_fields = ['created_at']


class MuddemalFSLRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = MuddemalFSLRecord
        fields = [
            'id',
            'property',
            'fsl_reference_no',
            'dispatch_date',
            'dispatch_details',
            'report_received_status',
            'report_received_date',
            'report_reference',
            'remarks',
            'created_by',
            'created_at',
        ]
        read_only_fields = ['created_at']


class MuddemalDisposalSerializer(serializers.ModelSerializer):
    class Meta:
        model = MuddemalDisposal
        fields = [
            'id',
            'property',
            'disposal_type',
            'court_order_reference',
            'order_date',
            'owner_recipient_details',
            'supurdnama_details',
            'disposal_date',
            'authorization_details',
            'remarks',
            'created_by',
            'created_at',
        ]
        read_only_fields = ['created_at']


class MuddemalPropertySerializer(serializers.ModelSerializer):
    muddemal_record = serializers.PrimaryKeyRelatedField(
        queryset=MuddemalRegister.objects.all(), required=False
    )
    property_category = serializers.PrimaryKeyRelatedField(
        queryset=MuddemalPropertyCategory.objects.all(), required=False
    )
    seizure_date = serializers.DateField(required=False, allow_null=True)
    recovery_date = serializers.DateField(required=False, allow_null=True)
    remarks = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    owner_name = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    seized_from = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    unit_value = serializers.DecimalField(max_digits=14, decimal_places=2, required=False)
    total_item_value = serializers.DecimalField(max_digits=14, decimal_places=2, required=False)
    quantity = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    category_code = serializers.CharField(source='property_category.category_code', read_only=True)
    category_name = serializers.CharField(source='property_category.category_name', read_only=True)
    cr_number = serializers.CharField(source='muddemal_record.cr_number_snapshot', read_only=True)
    register_no = serializers.CharField(source='muddemal_record.muddemal_register_no', read_only=True)
    station_name = serializers.CharField(source='muddemal_record.station_name', read_only=True)

    source_module_display_name = serializers.SerializerMethodField()
    source_case_id = serializers.SerializerMethodField()
    source_case_number = serializers.SerializerMethodField()
    source_case_title = serializers.SerializerMethodField()
    current_custody_location = serializers.SerializerMethodField()
    fsl_status = serializers.SerializerMethodField()
    disposal_status = serializers.SerializerMethodField()
    display_cr_number = serializers.SerializerMethodField()

    # Common Master Form Fields
    act_section = serializers.SerializerMethodField()
    nature_of_crime = serializers.SerializerMethodField()
    io_name = serializers.SerializerMethodField()
    not_recovered = serializers.SerializerMethodField()
    fsl_sent_date = serializers.SerializerMethodField()
    fsl_report_received = serializers.SerializerMethodField()
    fsl_report_received_date = serializers.SerializerMethodField()
    disposal_date = serializers.SerializerMethodField()
    destroyed = serializers.SerializerMethodField()
    released_on_supurdnama = serializers.SerializerMethodField()
    returned_to_owner = serializers.SerializerMethodField()
    category_attributes = serializers.SerializerMethodField()
    category_label = serializers.SerializerMethodField()

    movements = MuddemalPropertyMovementSerializer(many=True, read_only=True)
    fsl_records = MuddemalFSLRecordSerializer(many=True, read_only=True)
    disposals = MuddemalDisposalSerializer(many=True, read_only=True)

    INTERNAL_TECHNICAL_KEYS = {
        'auto_fetched',
        'source_table',
        'last_synced_at',
        'first_synced_at',
        'source_module_id',
        'original_record_id',
        'original_record_reference',
        'source_module_display_name',
        'status_logs',
    }

    class Meta:
        model = MuddemalProperty
        fields = [
            'id',
            'property_uid',
            'display_cr_number',
            'muddemal_record',
            'register_no',
            'cr_number',
            'station_name',
            'source_module',
            'source_module_display_name',
            'source_record_id',
            'source_case_id',
            'source_case_number',
            'source_case_title',
            'property_category',
            'category_code',
            'category_name',
            'category_label',
            'property_serial_no',
            'description',
            'quantity',
            'unit',
            'unit_value',
            'total_item_value',
            'valuation_status',
            'owner_name',
            'seized_from',
            'seizure_date',
            'recovery_date',
            'property_status',
            'fsl_required',
            'current_custody_location',
            'fsl_status',
            'disposal_status',
            'remarks',
            'extra_fields',
            'category_attributes',
            'act_section',
            'nature_of_crime',
            'io_name',
            'not_recovered',
            'fsl_sent_date',
            'fsl_report_received',
            'fsl_report_received_date',
            'disposal_date',
            'destroyed',
            'released_on_supurdnama',
            'returned_to_owner',
            'movements',
            'fsl_records',
            'disposals',
            'created_by',
            'updated_by',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['property_uid', 'property_serial_no', 'created_at', 'updated_at']

    def get_source_module_display_name(self, obj) -> str:
        if isinstance(obj.extra_fields, dict) and obj.extra_fields.get('source_module_display_name'):
            return obj.extra_fields['source_module_display_name']

        # Dynamically inspect linked cr_case from database if available
        if obj.muddemal_record and obj.muddemal_record.cr_case:
            case = obj.muddemal_record.cr_case
            sub_raw = (case.sub_category or '').strip()
            mod_raw = (case.module_key or '').lower().strip()
            if mod_raw in ['form_1_5', 'crime']:
                return f"Crime ({sub_raw})" if sub_raw else "Crime"
            if sub_raw:
                return f"{mod_raw.replace('_', ' ').title()} ({sub_raw})" if mod_raw else sub_raw
            if mod_raw:
                return mod_raw.replace('_', ' ').title()

        mod_map = {
            'crime': 'Crime',
            'prohibition': 'Prohibition',
            'gambling': 'Gambling',
            'ndps': 'NDPS',
            'theft': 'Theft / Burglary',
            'two_four_wheeler': 'Two / Four Wheeler',
            'weapons': 'Arms Act / Weapons',
            'form_6': 'Form VI (Special Acts)',
            'manual': 'Direct Entry',
            'seizure_records': 'Seizure Record',
        }
        return mod_map.get(obj.source_module, obj.source_module.replace('_', ' ').title())

    def get_source_case_id(self, obj) -> Optional[str]:
        if obj.muddemal_record and obj.muddemal_record.cr_case_id:
            return str(obj.muddemal_record.cr_case_id)
        if isinstance(obj.extra_fields, dict):
            return obj.extra_fields.get('original_record_id')
        return None

    def get_source_case_number(self, obj) -> str:
        if obj.muddemal_record:
            return obj.muddemal_record.cr_number_snapshot
        return ''

    def get_source_case_title(self, obj) -> str:
        if obj.muddemal_record and obj.muddemal_record.cr_case:
            return obj.muddemal_record.cr_case.title
        return ''

    def get_current_custody_location(self, obj) -> str:
        latest = obj.movements.first()
        if latest and latest.to_location:
            return latest.to_location
        return 'Muddemal Room (मालखाना)'

    def get_fsl_status(self, obj) -> str:
        latest = obj.fsl_records.first()
        if latest:
            return 'Report Received' if latest.report_received_status else 'Report Pending'
        return 'Sent to FSL' if obj.property_status == 'Sent to FSL' else ('FSL Required' if obj.fsl_required else 'Not Required')

    def get_disposal_status(self, obj) -> str:
        latest = obj.disposals.first()
        if latest:
            return latest.disposal_type
        return 'Active in Custody'

    def get_display_cr_number(self, obj) -> str:
        cr_part = ''
        if obj.muddemal_record and obj.muddemal_record.cr_number_snapshot:
            cr_part = str(obj.muddemal_record.cr_number_snapshot).strip()
        reg_year = (
            obj.muddemal_record.registration_date.year
            if (obj.muddemal_record and obj.muddemal_record.registration_date)
            else (obj.created_at.year if obj.created_at else 2026)
        )
        if cr_part.upper().startswith('CR-') and '/' in cr_part:
            return cr_part
        import re
        match = re.search(r'(\d+)', cr_part)
        clean_cr = match.group(1) if match else (cr_part or '00')
        return f"CR-{clean_cr}/{reg_year}"

    def get_act_section(self, obj) -> str:
        if obj.muddemal_record and obj.muddemal_record.cr_case:
            case = obj.muddemal_record.cr_case
            extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
            raw_sec = extra.get('act_section') or extra.get('actSection') or extra.get('section_act') or extra.get('acts_sections')
            if isinstance(raw_sec, list):
                parts = []
                for item in raw_sec:
                    if isinstance(item, dict):
                        act = item.get('act') or item.get('act_name') or ''
                        sec = item.get('section') or item.get('section_number') or ''
                        if act or sec:
                            parts.append(f"{sec} {act}".strip())
                    elif item:
                        parts.append(str(item).strip())
                if parts:
                    return ', '.join(parts)
            elif isinstance(raw_sec, str) and raw_sec.strip():
                return raw_sec.strip()
            if getattr(case, 'sub_category', None):
                return str(case.sub_category)
        return 'IPC / BNS'

    def get_nature_of_crime(self, obj) -> str:
        if obj.muddemal_record and obj.muddemal_record.cr_case:
            case = obj.muddemal_record.cr_case
            extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
            noc = extra.get('nature_of_crime') or extra.get('natureOfCrime') or case.title or case.sub_category
            if noc:
                return str(noc)
        return obj.property_category.category_name if obj.property_category else 'Case Property'

    def get_io_name(self, obj) -> str:
        if obj.muddemal_record:
            if obj.muddemal_record.investigating_officer_name:
                return obj.muddemal_record.investigating_officer_name
            if obj.muddemal_record.cr_case and obj.muddemal_record.cr_case.assigned_officer:
                return obj.muddemal_record.cr_case.assigned_officer
        return '—'

    def get_not_recovered(self, obj) -> bool:
        return obj.property_status == 'Stolen – Not Recovered'

    def get_fsl_sent_date(self, obj) -> Optional[str]:
        fsl = obj.fsl_records.order_by('-dispatch_date').first()
        if fsl and fsl.dispatch_date:
            return fsl.dispatch_date.isoformat()
        if isinstance(obj.extra_fields, dict) and obj.extra_fields.get('fsl_sent_date'):
            return str(obj.extra_fields['fsl_sent_date'])
        return None

    def get_fsl_report_received(self, obj) -> bool:
        fsl = obj.fsl_records.order_by('-created_at').first()
        if fsl:
            return fsl.report_received_status == 'Received'
        if isinstance(obj.extra_fields, dict):
            status = str(obj.extra_fields.get('fsl_report_received') or obj.extra_fields.get('fsl_report_status') or '').lower()
            return status in ['received', 'yes', 'true']
        return False

    def get_fsl_report_received_date(self, obj) -> Optional[str]:
        fsl = obj.fsl_records.filter(report_received_date__isnull=False).order_by('-report_received_date').first()
        if fsl and fsl.report_received_date:
            return fsl.report_received_date.isoformat()
        if isinstance(obj.extra_fields, dict) and obj.extra_fields.get('fsl_report_date'):
            return str(obj.extra_fields['fsl_report_date'])
        return None

    def get_disposal_date(self, obj) -> Optional[str]:
        disp = obj.disposals.filter(disposal_date__isnull=False).order_by('-disposal_date').first()
        if disp and disp.disposal_date:
            return disp.disposal_date.isoformat()
        if obj.muddemal_record and obj.muddemal_record.cr_case and obj.muddemal_record.cr_case.disposal_date:
            return obj.muddemal_record.cr_case.disposal_date.date().isoformat()
        return None

    def get_destroyed(self, obj) -> bool:
        if obj.property_status == 'Destroyed':
            return True
        return obj.disposals.filter(disposal_type__icontains='destroy').exists()

    def get_released_on_supurdnama(self, obj) -> bool:
        if obj.property_status == 'Released on Supurdnama':
            return True
        return obj.disposals.filter(disposal_type__icontains='supurdnama').exists()

    def get_returned_to_owner(self, obj) -> bool:
        if obj.property_status == 'Returned to Owner':
            return True
        return obj.disposals.filter(disposal_type__icontains='return').exists()

    def get_category_attributes(self, obj) -> dict:
        """
        Returns only genuine category-specific attributes, cleanly stripping internal technical metadata.
        """
        if not isinstance(obj.extra_fields, dict):
            return {}
        return {
            k: v for k, v in obj.extra_fields.items()
            if k not in self.INTERNAL_TECHNICAL_KEYS
        }

    def get_category_label(self, obj) -> str:
        try:
            cfg = MuddemalConfig.objects.filter(config_key='ui_labels').first()
            if cfg and isinstance(cfg.config_value, dict):
                return cfg.config_value.get('property_category_label', 'Type of Property')
        except Exception:
            pass
        return 'Type of Property'

    def validate(self, attrs):
        qty = attrs.get('quantity', getattr(self.instance, 'quantity', 1))
        u_val = attrs.get('unit_value', getattr(self.instance, 'unit_value', 0))
        tot_val = attrs.get('total_item_value', getattr(self.instance, 'total_item_value', 0))

        # Recalculate automatic valuation
        attrs['total_item_value'] = compute_item_value(qty, u_val, tot_val)

        # Preserve internal technical keys in extra_fields when updating
        extra_fields = attrs.get('extra_fields')
        if extra_fields is not None and self.instance and isinstance(self.instance.extra_fields, dict):
            merged = self.instance.extra_fields.copy()
            merged.update(extra_fields)
            attrs['extra_fields'] = merged

        return attrs


class MuddemalRegisterSerializer(serializers.ModelSerializer):
    properties_count = serializers.SerializerMethodField()
    valuations = serializers.SerializerMethodField()
    properties = MuddemalPropertySerializer(many=True, read_only=True)

    class Meta:
        model = MuddemalRegister
        fields = [
            'id',
            'muddemal_register_no',
            'police_station_id',
            'station_name',
            'cr_case',
            'cr_number_snapshot',
            'registration_date',
            'investigating_officer_id',
            'investigating_officer_name',
            'record_status',
            'remarks',
            'properties_count',
            'valuations',
            'properties',
            'created_by',
            'updated_by',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['muddemal_register_no', 'created_at', 'updated_at']

    def get_properties_count(self, obj) -> int:
        return obj.properties.count()

    def get_valuations(self, obj):
        return calculate_register_valuations(obj)


class MuddemalAuditLogSerializer(serializers.ModelSerializer):
    property_uid = serializers.CharField(source='property.property_uid', read_only=True)
    register_no = serializers.CharField(source='muddemal_record.muddemal_register_no', read_only=True)

    class Meta:
        model = MuddemalAuditLog
        fields = [
            'id',
            'property',
            'property_uid',
            'muddemal_record',
            'register_no',
            'action',
            'performed_by',
            'performed_by_name',
            'details',
            'created_at',
        ]
        read_only_fields = ['created_at']
