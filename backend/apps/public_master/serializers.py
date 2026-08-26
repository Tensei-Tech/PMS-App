from rest_framework import serializers
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission, UserRoleMapping


class MasterUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = MasterUser
        fields = ['id', 'email', 'full_name', 'phone', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']


class StateRegistrySerializer(serializers.ModelSerializer):
    class Meta:
        model = StateRegistry
        fields = ['state_code', 'state_name', 'schema_name', 'is_active', 'created_at']


class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = ['id', 'name', 'level', 'description', 'created_at']


class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permission
        fields = ['id', 'module', 'description', 'created_at']


class RolePermissionSerializer(serializers.ModelSerializer):
    role_name = serializers.ReadOnlyField(source='role.name')
    permission_module = serializers.ReadOnlyField(source='permission.module')

    class Meta:
        model = RolePermission
        fields = ['id', 'role', 'role_name', 'permission', 'permission_module', 'is_granted', 'created_at']


class UserRoleMappingSerializer(serializers.ModelSerializer):
    role_name = serializers.ReadOnlyField(source='role.name')

    class Meta:
        model = UserRoleMapping
        fields = ['uid', 'email', 'role', 'role_name', 'state', 'district_id', 'station_id', 'created_at']
