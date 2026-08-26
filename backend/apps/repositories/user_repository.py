from typing import List, Optional
from django.db import models
from apps.repositories.base import BaseRepository
from apps.users.models import OfficerProfile


class OfficerRepository(BaseRepository[OfficerProfile]):
    def __init__(self):
        super().__init__(OfficerProfile)

    def find_by_email(self, email: str) -> Optional[OfficerProfile]:
        return self.model.objects.filter(email__iexact=email).first()

    def find_by_uid(self, uid: str) -> Optional[OfficerProfile]:
        return self.model.objects.filter(uid=str(uid)).first()

    def get_station_officers(self, station_name: str) -> models.QuerySet[OfficerProfile]:
        return self.model.objects.filter(station_name=station_name)

    def update_account_status(self, uid: str, status: str) -> Optional[OfficerProfile]:
        profile = self.find_by_uid(uid)
        if profile:
            profile.account_status = status
            profile.save()
        return profile
