from django.db.models import Value, Q
from django.db.models.functions import Coalesce, Concat
from django.db.models.fields.json import KeyTextTransform
from django.db import models
from apps.cases.models import CaseRecord
from apps.cases.constants import DISPOSAL_KEYS

def get_cases_by_status(tab: str):
    """
    Returns cases strictly based on their persisted status field.
    The CaseRecord.save() method handles updating this status based on extra_fields.
    """
    queryset = CaseRecord.objects.all()
    
    if tab.lower() == 'disposal':
        return queryset.filter(status__iexact='Disposal')
    elif tab.lower() == 'pending':
        # "Pending" includes anything that is not Disposal, Closed, or Resolved
        return queryset.exclude(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])
    elif tab.lower() == 'detected':
        return queryset.filter(status__iexact='Detected')
    elif tab.lower() == 'arrested':
        return queryset.filter(
            Q(module_key__iexact='arrested') |
            Q(persons__arrest_status__arrest_datetime__isnull=False) |
            (Q(extra_fields__has_key='arrest_records') & ~Q(extra_fields__arrest_records=[]) & ~Q(extra_fields__arrest_records=None)) |
            (Q(extra_fields__has_key='arrest_datetime') & ~Q(extra_fields__arrest_datetime='') & ~Q(extra_fields__arrest_datetime=None)) |
            (Q(extra_fields__has_key='arrested_person_name') & ~Q(extra_fields__arrested_person_name='') & ~Q(extra_fields__arrested_person_name=None)) |
            (Q(extra_fields__has_key='arrests') & ~Q(extra_fields__arrests=[]) & ~Q(extra_fields__arrests=None))
        ).distinct()
        
    return queryset


def _has_arrest_date(extra: dict) -> bool:
    """
    Returns True if an arrest date is recorded in any of the common arrest fields.
    If no arrest date exists (or is null/empty), returns False.
    """
    if not isinstance(extra, dict):
        return False

    cf = extra.get('commonForm', {})
    if not isinstance(cf, dict):
        cf = {}

    # 1. Direct arrest datetime fields on commonForm or extra_fields
    for field in ['arrest_datetime', 'arrest_date', 'arrestDt', 'arrest_date_time']:
        val = str(cf.get(field, '') or extra.get(field, '')).strip()
        if val and val.lower() not in ['null', 'none', '']:
            return True

    # 2. Check lists of arrest records (arrestRelease, arrest_records, arrests)
    for list_key in ['arrestRelease', 'arrest_records', 'arrests']:
        records = cf.get(list_key, []) or extra.get(list_key, [])
        if isinstance(records, list):
            for row in records:
                if isinstance(row, dict):
                    for field in ['arrestDt', 'arrest_datetime', 'arrest_date', 'date']:
                        dt_val = str(row.get(field, '')).strip()
                        if dt_val and dt_val.lower() not in ['null', 'none', '']:
                            return True
    return False


def get_absconded_cases():
    """
    Returns absconded cases. 
    Rule: A case is considered Absconded when the Arrested Date is missing.
    Accused must be identified (not unknown/empty).
    Cases with CC ST Number are included (and will appear under Disposal as well).
    Cases without CC ST Number are included (and will appear under Pending as well).
    """
    from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema
    
    # Ensure we're querying the correct tenant schema
    schema = get_active_tenant_schema()
    if schema and schema != 'public':
        set_tenant_schema(schema)
    
    detected_q = (
        Q(accused__isnull=False) &
        ~Q(accused__exact='') &
        ~Q(accused__iexact='unknown') &
        ~Q(accused__iexact='अज्ञात') &
        ~Q(accused__iexact='unidentified')
    )
    
    queryset = CaseRecord.objects.filter(detected_q)
    
    # Check arrest date: if arrested date is null/missing -> absconded
    absconded_ids = []
    for case in list(queryset.only('id', 'extra_fields')):
        if not _has_arrest_date(case.extra_fields):
            absconded_ids.append(case.id)

    # Re-set schema before the final query (connection pool safety)
    if schema and schema != 'public':
        set_tenant_schema(schema)
    
    return CaseRecord.objects.filter(id__in=absconded_ids)
