from typing import List, Optional
from apps.repositories.base import BaseRepository
from apps.public_master.models import Role, Permission, RolePermission, UserRoleMapping


class RoleRepository(BaseRepository[Role]):
    def __init__(self):
        super().__init__(Role)


class PermissionRepository(BaseRepository[Permission]):
    def __init__(self):
        super().__init__(Permission)


class RolePermissionRepository(BaseRepository[RolePermission]):
    def __init__(self):
        super().__init__(RolePermission)

    def get_granted_permission_codes(self, role_id: str) -> List[str]:
        """Fetch granted permission string codes for a specific role."""
        if role_id == 'master_admin':
            return list(Permission.objects.values_list('id', flat=True))

        return list(
            self.model.objects.filter(role_id=role_id, is_granted=True)
            .values_list('permission_id', flat=True)
        )

    def has_permission(self, role_id: str, permission_code: str) -> bool:
        """Check if role_id has a specific granted permission code."""
        if role_id in ['master_admin', 'state_super_admin']:
            return True
        return self.model.objects.filter(
            role_id=role_id,
            permission_id=permission_code,
            is_granted=True
        ).exists()


class UserRoleMappingRepository(BaseRepository[UserRoleMapping]):
    def __init__(self):
        super().__init__(UserRoleMapping)

    def find_by_uid(self, uid: str) -> Optional[UserRoleMapping]:
        return self.model.objects.filter(uid=str(uid)).first()
