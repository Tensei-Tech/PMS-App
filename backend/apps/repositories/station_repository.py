from typing import List, Optional
from django.db import models
from apps.repositories.base import BaseRepository
from apps.stations.models import SuperAdmin, District, DistrictAdmin, PoliceStation


class SuperAdminRepository(BaseRepository[SuperAdmin]):
    def __init__(self):
        super().__init__(SuperAdmin)


class DistrictRepository(BaseRepository[District]):
    def __init__(self):
        super().__init__(District)

    def get_approved_districts(self) -> models.QuerySet[District]:
        return self.model.objects.filter(status='approved')


class DistrictAdminRepository(BaseRepository[DistrictAdmin]):
    def __init__(self):
        super().__init__(DistrictAdmin)


class PoliceStationRepository(BaseRepository[PoliceStation]):
    def __init__(self):
        super().__init__(PoliceStation)

    def find_by_name(self, station_name: str) -> Optional[PoliceStation]:
        return self.model.objects.filter(station_name__iexact=station_name).first()

    def get_by_district(self, district_id: str) -> models.QuerySet[PoliceStation]:
        return self.model.objects.filter(district_id=district_id)
