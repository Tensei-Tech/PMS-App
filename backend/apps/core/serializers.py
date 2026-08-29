from rest_framework import serializers
from apps.core.models import AuditLog, SosAlert


class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = '__all__'
        read_only_fields = ['created_at']


class SosAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = SosAlert
        fields = '__all__'
        read_only_fields = ['created_at']
