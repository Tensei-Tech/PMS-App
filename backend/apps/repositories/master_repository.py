from typing import List, Optional
from apps.repositories.base import BaseRepository
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission, UserRoleMapping


class MasterUserRepository(BaseRepository[MasterUser]):
    def __init__(self):
        super().__init__(MasterUser)

    def find_by_email(self, email: str) -> Optional[MasterUser]:
        return self.model.objects.filter(email__iexact=email, is_active=True).first()


class StateRegistryRepository(BaseRepository[StateRegistry]):
    def __init__(self):
        super().__init__(StateRegistry)

    def find_by_code(self, state_code: str) -> Optional[StateRegistry]:
        return self.model.objects.filter(state_code__iexact=state_code, is_active=True).first()


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
        """Fetch granted permission string codes dynamically from public.role_permissions."""
        return list(
            self.model.objects.filter(role_id=role_id, is_granted=True)
            .values_list('permission_id', flat=True)
        )

    def has_permission(self, role_id: str, permission_code: str) -> bool:
        """Check if role_id has a specific granted permission code in DB."""
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
