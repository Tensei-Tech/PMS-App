from rest_framework import serializers
from apps.crimetab.models import RTIApplication, ModuleSetting


def format_rti_serial(serial_year, serial_no):
    prefix_setting = ModuleSetting.objects.filter(module_key='rti', setting_key='serial_prefix').first()
    format_setting = ModuleSetting.objects.filter(module_key='rti', setting_key='serial_format').first()

    prefix = prefix_setting.setting_value.strip() if (prefix_setting and prefix_setting.setting_value) else 'RTI'
    fmt = format_setting.setting_value.strip() if (format_setting and format_setting.setting_value) else '{prefix}-{year}/{serial_no}'

    try:
        return fmt.format(prefix=prefix, year=serial_year, serial_no=serial_no)
    except Exception:
        return f"{prefix}-{serial_year}/{serial_no}"


def rti_outcome(instance):
    """What happened to the application: 'Replied', 'Rejected', 'Transferred', or None (pending)."""
    if instance.replied_date:
        return 'Replied'
    if instance.rejected_date or instance.rejection_reason:
        return 'Rejected'
    if instance.transferred_to and str(instance.transferred_to).strip():
        return 'Transferred'
    return None


class RTIApplicationListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for RTI paginated list views.
    """
    serial_display = serializers.SerializerMethodField()

    class Meta:
        model = RTIApplication
        fields = [
            'rti_id',
            'serial_year',
            'serial_no',
            'serial_display',
            'applicant_name',
            'received_date',
            'due_date',
            'info_type',
            'mode_of_receipt',
            'status',
            'created_at',
        ]

    def get_serial_display(self, obj):
        return format_rti_serial(obj.serial_year, obj.serial_no)


class RTIApplicationSerializer(serializers.ModelSerializer):
    """
    Full detailed serializer for RTI Application create, view, and edit.
    """
    serial_display = serializers.SerializerMethodField()

    class Meta:
        model = RTIApplication
        fields = '__all__'
        read_only_fields = ['status']


    def get_serial_display(self, obj):
        return format_rti_serial(obj.serial_year, obj.serial_no)

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        prefixed = {}
        for k, v in ret.items():
            if k not in ('rti_id', 'serial_year', 'serial_no', 'status', 'station_name'):
                prefixed[f"rti_{k}"] = v
        prefixed['rti_assigned_officer'] = instance.assigned_officer_uid
        prefixed['rti_outcome'] = rti_outcome(instance)
        ret.update(prefixed)
        return ret
