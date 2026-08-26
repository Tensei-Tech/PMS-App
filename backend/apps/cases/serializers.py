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
