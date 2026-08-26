from typing import Optional
from django.db import models
from apps.repositories.base import BaseRepository
from apps.stations.models import PoliceStation


class PoliceStationRepository(BaseRepository[PoliceStation]):
    def __init__(self):
        super().__init__(PoliceStation)

    def find_by_name(self, station_name: str) -> Optional[PoliceStation]:
        return self.model.objects.filter(station_name__iexact=station_name).first()

    def get_by_district(self, district_id: str) -> models.QuerySet[PoliceStation]:
        return self.model.objects.filter(district_id=district_id)
