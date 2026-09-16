from typing import List, Optional
from django.db import models
from apps.repositories.base import BaseRepository
from apps.cases.models import CaseRecord, is_ad_case_disposed


class CaseRepository(BaseRepository[CaseRecord]):
    def __init__(self):
        super().__init__(CaseRecord)

    def get_cases_for_station(self, station_name: str) -> models.QuerySet[CaseRecord]:
        """Fetch all case records for a specific police station."""
        return self.model.objects.filter(station_name=station_name)

    def get_cases_for_stations(self, station_names: List[str]) -> models.QuerySet[CaseRecord]:
        """Fetch case records across multiple police stations."""
        return self.model.objects.filter(station_name__in=station_names)

    def get_assigned_cases_for_officer(self, officer_uid: str, active_only: bool = True) -> models.QuerySet[CaseRecord]:
        """Fetch cases assigned to an officer as Investigating Officer."""
        qs = self.model.objects.filter(assigned_officer_uid=officer_uid)
        disposed_ids = [c.id for c in qs if c.status in ['Closed', 'Disposal', 'Resolved', 'Disposed'] or is_ad_case_disposed(c)]
        if active_only:
            return qs.filter(status__in=['Open', 'Pending', 'Active']).exclude(id__in=disposed_ids)
        return qs.filter(models.Q(id__in=disposed_ids) | models.Q(status__in=['Closed', 'Disposal', 'Resolved', 'Disposed']))

    def can_officer_edit_case(self, user, case_record: CaseRecord) -> bool:
        if not user or not getattr(user, 'is_authenticated', False):
            return False

        if getattr(user, 'is_superuser', False) or getattr(user, 'is_staff', False):
            return True

        role_id = getattr(user, 'role_id', 'officer')
        if role_id in ['district_admin', 'master_admin', 'state_super_admin', 'admin']:
            return True

        if role_id in ['station_admin', 'supervisor']:
            user_stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
            if not case_record.station_name or case_record.station_name in user_stations:
                return True

        user_uid = str(getattr(user, 'uid', getattr(user, 'id', '')))
        is_creator = not case_record.created_by or str(case_record.created_by) == user_uid
        is_assigned = not case_record.assigned_officer_uid or str(case_record.assigned_officer_uid) == user_uid
        user_stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
        is_same_station = not case_record.station_name or case_record.station_name in user_stations

        if is_creator or is_assigned or is_same_station:
            return True

        return True
