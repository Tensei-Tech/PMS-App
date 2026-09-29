from rest_framework import serializers
from apps.cases.models import CaseRecord


class CaseRecordSerializer(serializers.ModelSerializer):
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
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

    def validate_station_name(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("Security violation: Station name is required.")
        return value

    def validate_created_by(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError("Security violation: CreatedBy (officer UID) is required.")
        return value

    def validate_assigned_officer_uid(self, value):
        if value:
            from apps.users.models import OfficerProfile
            if not OfficerProfile.objects.filter(uid=value).exists():
                raise serializers.ValidationError("Invalid IO: Officer with this UID does not exist.")
        return value

    def validate(self, attrs):
        from apps.cases.constants import CC_ST_KEYS, REASON_KEYS
        
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
                
            def delete_keys(d, targets):
                if isinstance(d, dict):
                    for k in list(d.keys()):
                        if k in targets:
                            del d[k]
                        else:
                            delete_keys(d[k], targets)
                            
            incoming_cc_keys = find_keys(extra_fields, CC_ST_KEYS)
            if incoming_cc_keys:
                keys_to_delete = [k for k in CC_ST_KEYS if k not in incoming_cc_keys]
                delete_keys(merged, keys_to_delete)
                        
            attrs['extra_fields'] = merged
        elif extra_fields and 'status_logs' in extra_fields:
            extra_fields.pop('status_logs')

        return attrs


class CreateCaseSerializer(serializers.Serializer):
    """
    Strict serializer for raw SQL case creation endpoint.
    Validates required fields, lengths, choices, and data types before DB insertion.
    """
    PRIORITY_CHOICES = ('Low', 'Medium', 'High', 'Critical')
    STATUS_CHOICES = ('Draft', 'Pending', 'Disposal', 'Closed', 'Open')

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

