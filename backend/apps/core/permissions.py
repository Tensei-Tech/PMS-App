import logging
from rest_framework import permissions
from apps.repositories.master_repository import RolePermissionRepository, UserRoleMappingRepository

logger = logging.getLogger(__name__)

role_perm_repo = RolePermissionRepository()
user_role_map_repo = UserRoleMappingRepository()


def check_dynamic_permission(user, permission_code: str) -> bool:
    """
    Evaluates whether a given user has a dynamic permission using RolePermissionRepository.
    No permission codes or roles are hardcoded. Modifying DB rows immediately updates access enforcement.
    """
    if not user or not getattr(user, 'is_authenticated', False):
        return False

    role_id = getattr(user, 'role_id', None) or getattr(user, 'role', None)

    # If role_id is not directly on user model, check user_role_mappings
    if not role_id:
        uid = getattr(user, 'uid', None) or getattr(user, 'id', None)
        mapping = user_role_map_repo.find_by_uid(str(uid))
        if mapping:
            role_id = mapping.role_id

    if not role_id:
        return False

    # Check repository for permission
    has_perm = role_perm_repo.has_permission(role_id, permission_code)
    logger.debug(f"[DynamicRBAC] User: {getattr(user, 'email', 'unknown')} | Role: {role_id} | Perm: {permission_code} => {has_perm}")
    return has_perm


class DynamicPermissionRequired(permissions.BasePermission):
    """
    DRF Permission class for dynamic permission enforcement.
    Usage in DRF Views:
        permission_classes = [DynamicPermissionRequired]
        required_permission = 'district:create'
    """
    def has_permission(self, request, view):
        required_perm = getattr(view, 'required_permission', None)
        if not required_perm:
            return True
        return check_dynamic_permission(request.user, required_perm)


def HasPermission(permission_code: str):
    """
    Factory helper to generate inline DRF Permission class for specific code.
    Example:
        permission_classes = [HasPermission('case:approve')]
    """
    class InlinePermission(permissions.BasePermission):
        def has_permission(self, request, view):
            return check_dynamic_permission(request.user, permission_code)

    InlinePermission.__name__ = f"HasPermission_{permission_code.replace(':', '_')}"
    return InlinePermission
