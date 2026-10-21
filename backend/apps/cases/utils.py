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


def get_license_passport_excluded_q():
    """
    Returns Q expression to match License and Passport verification records.
    """
    return (
        Q(module_key__in=['license', 'licence', 'arms_license', 'arms_licence', 'passport', 'passport_pvr_lic']) |
        Q(sub_category__icontains='license') |
        Q(sub_category__icontains='licence') |
        Q(sub_category__icontains='passport') |
        Q(category_links__category__category_code__in=['STAND_LICENSE', 'STAND_LICENCE', 'STAND_PASSPORT']) |
        Q(category_links__category__category_name__in=['License', 'Licence', 'Passport/PVR/Lic', 'Arms License']) |
        Q(title__icontains='passport') |
        Q(title__icontains='license') |
        Q(title__icontains='licence')
    )


def get_absconded_cases():
    """
    Returns absconded cases. 
    Rule: A case is considered Absconded when the Arrested Date is missing.
    Accused must be identified (not unknown/empty).
    Cases with CC ST Number are included (and will appear under Disposal as well).
    Cases without CC ST Number are included (and will appear under Pending as well).
    License and Passport cases are excluded.
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
    
    queryset = CaseRecord.objects.filter(detected_q).exclude(get_license_passport_excluded_q())
    
    # Check arrest date: if arrested date is null/missing -> absconded
    absconded_ids = []
    for case in list(queryset.only('id', 'extra_fields')):
        if not _has_arrest_date(case.extra_fields):
            absconded_ids.append(case.id)

    # Re-set schema before the final query (connection pool safety)
    if schema and schema != 'public':
        set_tenant_schema(schema)
    
    return CaseRecord.objects.filter(id__in=absconded_ids).exclude(get_license_passport_excluded_q())

def get_victim_cases():
    """
    Returns cases that fall under Victim categories.
    Modules: POCSO, Crime Against Women, Accident, Cheating/Fraud, Domestic Violence, Missing/Kidnapping.
    """
    from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema
    from django.db.models import Q
    
    schema = get_active_tenant_schema()
    if schema and schema != 'public':
        set_tenant_schema(schema)
        
    target_modules = [
        'pocso', 'crime_women', 'accident', 'cheating', '498_a_ipc', 'missing', 'kidnapping', 'victim'
    ]
    
    queryset = CaseRecord.objects.filter(
        Q(module_key__in=target_modules) |
        Q(sub_category__iexact='pocso') |
        Q(sub_category__iexact='crime against women') |
        Q(sub_category__iexact='accident') |
        Q(sub_category__iexact='cheating') |
        Q(sub_category__iexact='498 (a) ipc') |
        Q(sub_category__iexact='missing') |
        Q(sub_category__iexact='kidnapping')
    ).distinct()
    
    if schema and schema != 'public':
        set_tenant_schema(schema)
        
    return queryset


def get_undetected_excluded_crime_types_q():
    """
    Returns a Q query matching crime types that must NOT be displayed in the Undetected tab:
    - DAR (Detailed Accident Report)
    - Missing
    - RTI
    - Repeat Offender (History Sheeter)
    - Tadipar (Externment)
    - Victim
    - License / Licence / Passport / Arms License
    """
    return (
        # DAR
        Q(module_key__iexact='dar') |
        Q(sub_category__iexact='dar') |
        Q(sub_category__icontains='detailed accident') |
        Q(title__istartswith='dar ') |
        Q(title__iexact='dar') |
        # Missing
        Q(module_key__iexact='missing') |
        Q(sub_category__iexact='missing') |
        Q(category_links__category__category_code__in=['STAND_MISSING', '124']) |
        Q(category_links__category__category_name__iexact='Missing') |
        # RTI
        Q(module_key__iexact='rti') |
        Q(sub_category__iexact='rti') |
        Q(category_links__category__category_code__iexact='STAND_RTI') |
        Q(category_links__category__category_name__iexact='RTI') |
        Q(title__istartswith='rti ') |
        Q(title__iexact='rti') |
        # Repeat Offender / History Sheeter
        Q(module_key__in=[
            'repeat_offender', 'repeat-offender', 'repeat offender',
            'history_sheeter', 'history-sheeter', 'history sheeter'
        ]) |
        Q(sub_category__iexact='repeat offender') |
        Q(sub_category__iexact='repeat_offender') |
        Q(sub_category__iexact='history sheeter') |
        Q(sub_category__iexact='history_sheeter') |
        Q(category_links__category__category_code__in=['STAND_REPEAT_OFFENDER', 'STAND_HISTORY_SHEETER']) |
        Q(category_links__category__category_name__in=['Repeat Offender', 'History Sheeter']) |
        # Tadipar
        Q(module_key__iexact='tadipar') |
        Q(sub_category__iexact='tadipar') |
        Q(sub_category__icontains='externment') |
        Q(category_links__category__category_code__in=['STAND_TADIPAR', 'tadipar']) |
        Q(category_links__category__category_name__iexact='Tadipar') |
        # Victim
        Q(module_key__iexact='victim') |
        Q(sub_category__iexact='victim') |
        Q(category_links__category__category_code__iexact='STAND_VICTIM') |
        Q(category_links__category__category_name__iexact='Victim') |
        # License / Licence / Passport
        Q(module_key__in=['license', 'licence', 'arms_license', 'arms_licence', 'passport', 'passport_pvr_lic']) |
        Q(sub_category__icontains='license') |
        Q(sub_category__icontains='licence') |
        Q(sub_category__icontains='passport') |
        Q(category_links__category__category_code__in=['STAND_LICENSE', 'STAND_LICENCE', 'STAND_PASSPORT']) |
        Q(category_links__category__category_name__in=['License', 'Licence', 'Passport/PVR/Lic', 'Arms License'])
    )


def get_undetected_base_queryset(queryset=None):
    """
    Returns base queryset for Undetected cases:
    - accused is null, empty, or unknown/unidentified
    - excludes disposed/closed/resolved cases
    - excludes DAR, missing, RTI, repeat offender, tadipar, victim, license
    """
    if queryset is None:
        queryset = CaseRecord.objects.all()

    undetected_q = (
        Q(accused__isnull=True) |
        Q(accused__exact='') |
        Q(accused__iexact='unknown') |
        Q(accused__iexact='अज्ञात') |
        Q(accused__iexact='unidentified')
    )
    return queryset.filter(undetected_q).exclude(
        status__in=['Disposal', 'Disposed', 'Closed', 'Resolved']
    ).exclude(
        get_undetected_excluded_crime_types_q()
    ).distinct()

