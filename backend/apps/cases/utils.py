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
        return queryset.filter(status__iexact='Pending')
    elif tab.lower() == 'detected':
        return queryset.filter(status__iexact='Detected')
        
    return queryset


def get_absconded_cases():
    """
    Returns absconded cases. 
    A case is absconded if it is a detected case (has accused), is not disposed, 
    and the accused has not been arrested (no arrestDt in extra_fields).
    
    Logic: arrested date is null → case is absconded.
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
    
    queryset = CaseRecord.objects.filter(detected_q).exclude(
        status__in=['Disposal', 'Disposed', 'Closed', 'Resolved']
    )
    
    # Fetch all matching cases and filter by arrest date in Python
    # Use list() to force evaluation in a single DB round-trip
    absconded_ids = []
    for case in list(queryset.only('id', 'extra_fields')):
        extra = case.extra_fields
        if isinstance(extra, dict):
            cf = extra.get('commonForm', {})
            if isinstance(cf, dict):
                ar = cf.get('arrestRelease', [])
                if isinstance(ar, list) and len(ar) > 0:
                    has_arrest = any(
                        str(row.get('arrestDt', '')).strip()
                        for row in ar if isinstance(row, dict)
                    )
                    if not has_arrest:
                        absconded_ids.append(case.id)
                else:
                    # No arrestRelease data → no arrest → absconded
                    absconded_ids.append(case.id)
            else:
                # No commonForm → no arrest info → absconded
                absconded_ids.append(case.id)
        else:
            # No extra_fields → no arrest info → absconded
            absconded_ids.append(case.id)

    # Re-set schema before the final query (connection pool safety)
    if schema and schema != 'public':
        set_tenant_schema(schema)
    
    return CaseRecord.objects.filter(id__in=absconded_ids)
