from rest_framework import serializers
from apps.users.models import OfficerProfile


class OfficerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = OfficerProfile
        fields = [
            'uid',
            'name',
            'badge_number',
            'designation',
            'email',
            'phone',
            'station_name',
            'station_address',
            'station_landline',
            'govt_id',
            'photo_url',
            'id_card_url',
            'role',
            'additional_stations',
            'account_status',
            'division_name',
            'district',
            'zone',
            'station_case_view_granted',
            'is_biometric_enabled',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class OfficerStatusUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = OfficerProfile
        fields = ['account_status', 'role', 'station_case_view_granted']


class TransferRequestSerializer(serializers.ModelSerializer):
    class Meta:
        from apps.users.models import TransferRequest
        model = TransferRequest
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

