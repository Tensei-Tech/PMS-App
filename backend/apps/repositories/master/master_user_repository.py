from typing import Optional
from apps.repositories.base import BaseRepository
from apps.public_master.models import MasterUser


class MasterUserRepository(BaseRepository[MasterUser]):
    def __init__(self):
        super().__init__(MasterUser)

    def find_by_email(self, email: str) -> Optional[MasterUser]:
        return self.model.objects.filter(email__iexact=email, is_active=True).first()
