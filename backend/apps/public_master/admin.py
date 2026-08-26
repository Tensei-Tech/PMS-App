from django.contrib import admin
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission, UserRoleMapping


@admin.register(MasterUser)
class MasterUserAdmin(admin.ModelAdmin):
    list_display = ('id', 'email', 'full_name', 'phone', 'is_active', 'created_at')
    search_fields = ('email', 'full_name', 'phone')


@admin.register(StateRegistry)
class StateRegistryAdmin(admin.ModelAdmin):
    list_display = ('state_code', 'state_name', 'schema_name', 'is_active', 'created_at')
    search_fields = ('state_code', 'state_name', 'schema_name')


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'level', 'description', 'created_at')
    list_filter = ('level',)
    search_fields = ('id', 'name')


@admin.register(Permission)
class PermissionAdmin(admin.ModelAdmin):
    list_display = ('id', 'module', 'description', 'created_at')
    list_filter = ('module',)
    search_fields = ('id', 'module', 'description')


@admin.register(RolePermission)
class RolePermissionAdmin(admin.ModelAdmin):
    list_display = ('role', 'permission', 'is_granted', 'created_at')
    list_filter = ('role', 'is_granted', 'permission__module')
    search_fields = ('role__name', 'permission__id')


@admin.register(UserRoleMapping)
class UserRoleMappingAdmin(admin.ModelAdmin):
    list_display = ('uid', 'email', 'role', 'state', 'district_id', 'station_id', 'created_at')
    list_filter = ('role', 'state')
    search_fields = ('uid', 'email')
