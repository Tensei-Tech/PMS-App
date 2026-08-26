from django.contrib import admin
from apps.cases.models import CaseRecord


@admin.register(CaseRecord)
class CaseRecordAdmin(admin.ModelAdmin):
    list_display = ('id', 'case_number', 'module_key', 'title', 'station_name', 'status', 'priority', 'assigned_officer', 'created_at')
    list_filter = ('module_key', 'status', 'priority', 'station_name')
    search_fields = ('id', 'case_number', 'title', 'complainant', 'accused', 'station_name', 'created_by')
    readonly_fields = ('created_at', 'updated_at')
