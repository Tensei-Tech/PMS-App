from typing import List, Optional
from django.db import models
from apps.repositories.base import BaseRepository
from apps.cases.models import CaseRecord


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
        if active_only:
            return qs.filter(status__in=['Open', 'Pending', 'Active'])
        return qs.filter(status__in=['Closed', 'Disposal', 'Resolved'])

    def can_officer_edit_case(self, user, case_record: CaseRecord) -> bool:
        """
        Enforces 4-tier Maharashtra Police Case Edit Scope:
        - Tier 4 & 5 (District Leadership & Master Admin) -> Full edit authority across all stations.
        - Tier 2 & 3 (Station In-Charge & Division Head) -> Edit any case in their station.
        - Tier 1 (Regular Officer) -> ONLY Own Cases (createdBy == uid OR assignedOfficerUid == uid).
        """
        role_id = getattr(user, 'role_id', 'officer')
        user_uid = str(getattr(user, 'uid', getattr(user, 'id', '')))

        if role_id in ['district_admin', 'master_admin', 'state_super_admin']:
            return True

        if role_id in ['station_admin', 'supervisor']:
            return case_record.station_name == getattr(user, 'station_name', '')

        # Regular Officer (Tier 1)
        is_creator = case_record.created_by == user_uid
        is_assigned = case_record.assigned_officer_uid == user_uid
        return is_creator or is_assigned
