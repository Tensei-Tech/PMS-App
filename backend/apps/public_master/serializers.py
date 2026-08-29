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


import json
from apps.public_master.models import Designation

class DesignationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Designation
        fields = [
            'code', 'title', 'display_name', 'rank_level', 'role_type',
            'allowed_categories', 'allowed_admin_roles',
            'required_hierarchy_level', 'approving_authority',
            'implied_unit_type', 'is_active',
            'can_approve_transfers', 'can_manage_all_cases',
            'is_state_admin_allowed', 'is_district_admin_allowed',
            'is_division_admin_allowed', 'is_station_admin_allowed'
        ]

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        for field in ['allowed_categories', 'allowed_admin_roles']:
            val = ret.get(field)
            if isinstance(val, str):
                try:
                    val = json.loads(val)
                except Exception:
                    val = []
            if not isinstance(val, list):
                val = [val] if val else []
            ret[field] = val
        return ret


class AppAnnouncementSerializer(serializers.ModelSerializer):
    class Meta:
        from apps.public_master.models import AppAnnouncement
        model = AppAnnouncement
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']



