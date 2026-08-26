from typing import Optional
from apps.repositories.base import BaseRepository
from apps.public_master.models import StateRegistry


class StateRegistryRepository(BaseRepository[StateRegistry]):
    def __init__(self):
        super().__init__(StateRegistry)

    def find_by_code(self, state_code: str) -> Optional[StateRegistry]:
        return self.model.objects.filter(state_code__iexact=state_code, is_active=True).first()
