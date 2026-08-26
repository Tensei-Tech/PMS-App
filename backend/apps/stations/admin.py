from django.contrib import admin
from apps.stations.models import SuperAdmin, District, DistrictAdmin, PoliceStation


@admin.register(SuperAdmin)
class SuperAdminAdmin(admin.ModelAdmin):
    list_display = ('uid', 'name', 'email', 'phone', 'status', 'created_at')
    search_fields = ('uid', 'name', 'email')


@admin.register(District)
class DistrictAdminConfig(admin.ModelAdmin):
    list_display = ('district_id', 'name', 'code', 'status', 'created_at')
    list_filter = ('status',)
    search_fields = ('district_id', 'name', 'code')


@admin.register(DistrictAdmin)
class DistrictAdminUserAdmin(admin.ModelAdmin):
    list_display = ('uid', 'name', 'district', 'email', 'phone', 'badge_number', 'status')
    list_filter = ('district', 'status')
    search_fields = ('name', 'email', 'badge_number')


@admin.register(PoliceStation)
class PoliceStationAdmin(admin.ModelAdmin):
    list_display = ('station_id', 'station_name', 'district_name', 'zone', 'pi_in_charge', 'landline', 'created_at')
    list_filter = ('district_name', 'zone')
    search_fields = ('station_id', 'station_name', 'district_name', 'zone', 'pi_in_charge')
    readonly_fields = ('created_at',)
