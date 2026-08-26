from django.contrib import admin
from apps.users.models import OfficerProfile


@admin.register(OfficerProfile)
class OfficerProfileAdmin(admin.ModelAdmin):
    list_display = ('uid', 'name', 'badge_number', 'designation', 'station_name', 'role_id', 'account_status', 'created_at')
    list_filter = ('role_id', 'account_status', 'district', 'station_name')
    search_fields = ('uid', 'name', 'badge_number', 'email', 'phone', 'station_name', 'govt_id')
    readonly_fields = ('created_at', 'updated_at')
