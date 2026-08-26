from typing import Optional
from django.db import models
from apps.repositories.base import BaseRepository
from apps.stations.models import SuperAdmin, District, DistrictAdmin


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
