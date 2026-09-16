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

