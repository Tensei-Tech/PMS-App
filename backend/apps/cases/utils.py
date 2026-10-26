from django.db.models import Value, Q
from django.db.models.functions import Coalesce, Concat
from django.db.models.fields.json import KeyTextTransform
from django.db import models
from apps.cases.models import CaseRecord
from apps.cases.constants import DISPOSAL_KEYS
IGNORED_ACCUSED_NAMES = {
    'default accused', 'unknown', 'unknown accused', 'अज्ञात',
    'unidentified', 'na', 'n/a', 'none', 'null', 'test accused',
    'suspect', 'accused', 'passport verification', ''
}

def extract_accused_names_for_case(case):
    names = set()
    # 1. CasesPerson
    if hasattr(case, 'persons'):
        for p in case.persons.all():
            if p.role in ['accused', 'suspected_accused', 'suspect'] and p.name:
                names.add(p.name.strip())
    # 2. CaseRecord.accused
    if case.accused:
        if isinstance(case.accused, str):
            names.add(case.accused.strip())
        elif isinstance(case.accused, list):
            for x in case.accused:
                if isinstance(x, dict) and x.get('name'):
                    names.add(str(x['name']).strip())
                elif isinstance(x, str):
                    names.add(x.strip())
    # 3. extra_fields & commonForm
    ef = case.extra_fields if isinstance(case.extra_fields, dict) else {}
    cf = ef.get('commonForm') if isinstance(ef, dict) and isinstance(ef.get('commonForm'), dict) else {}
    for container in [ef, cf]:
        for key in ['accused_list', 'accused', 'accused_name']:
            val = container.get(key)
            if isinstance(val, str) and val.strip():
                names.add(val.strip())
            elif isinstance(val, list):
                for x in val:
                    if isinstance(x, dict) and x.get('name'):
                        names.add(str(x['name']).strip())
                    elif isinstance(x, str) and x.strip():
                        names.add(x.strip())
    return {n for n in names if n.strip().lower() not in IGNORED_ACCUSED_NAMES and len(n.strip()) > 1}


def get_repeat_offender_map(station_names=None):
    from collections import defaultdict
    qs = CaseRecord.objects.all()
    if station_names:
        qs = qs.filter(station_name__in=station_names)
        
    name_to_cases = defaultdict(dict)  # name_lower -> {case_id: cr_number}
    name_display = {}

    for c in qs.prefetch_related('persons'):
        cr = (c.case_number or '').strip()
        if not cr or cr in ['—', '-']:
            continue
        names = extract_accused_names_for_case(c)
        for n in names:
            nl = n.lower()
            name_to_cases[nl][c.id] = cr
            if nl not in name_display or (name_display[nl].islower() and not n.islower()):
                name_display[nl] = n.title() if (n.islower() or n.isupper()) else n

    repeat_accused = {nl: cdict for nl, cdict in name_to_cases.items() if len(set(cdict.values())) > 1}

    repeat_case_ids = set()
    case_to_info = {}

    for nl, cdict in repeat_accused.items():
        disp_name = name_display.get(nl, nl.title())
        all_crs = set(cdict.values())
        for cid, cr in cdict.items():
            repeat_case_ids.add(cid)
            other_crs = sorted([other for other in all_crs if other != cr])
            case_to_info[cid] = {
                'accused_name': disp_name,
                'other_crs': other_crs,
                'multiple_cr': ', '.join(other_crs) if other_crs else '-'
            }

    return repeat_case_ids, case_to_info


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
        # Exclude administrative service modules and missing reports (which are tracked as Traced/Untraced)
        return queryset.filter(status__iexact='Detected').exclude(
            Q(module_key__in=['passport', 'licence', 'application', 'missing']) |
            Q(sub_category__iexact='missing')
        )
    elif tab.lower() == 'arrested':
        return queryset.filter(
            Q(module_key__iexact='arrested') |
            Q(persons__arrest_status__arrest_datetime__isnull=False) |
            (Q(extra_fields__has_key='arrest_records') & ~Q(extra_fields__arrest_records=[]) & ~Q(extra_fields__arrest_records=None)) |
            (Q(extra_fields__has_key='arrest_datetime') & ~Q(extra_fields__arrest_datetime='') & ~Q(extra_fields__arrest_datetime=None)) |
            (Q(extra_fields__has_key='arrested_person_name') & ~Q(extra_fields__arrested_person_name='') & ~Q(extra_fields__arrested_person_name=None)) |
            (Q(extra_fields__has_key='arrests') & ~Q(extra_fields__arrests=[]) & ~Q(extra_fields__arrests=None))
        ).distinct()
    elif tab.lower() in ['repeat_offender', 'repeat offender']:
        repeat_case_ids, _ = get_repeat_offender_map()
        return queryset.filter(id__in=repeat_case_ids).distinct()
    elif tab.lower() == 'juvenile':
        from datetime import datetime
        
        def _is_juvenile_dob(dob_str: str) -> bool:
            if not dob_str: return False
            try:
                dob_str = str(dob_str).strip()
                if '/' in dob_str:
                    parts = dob_str.split('/')
                    if len(parts) != 3: return False
                    if len(parts[0]) == 4:
                        dt = datetime(int(parts[0]), int(parts[1]), int(parts[2]))
                    else:
                        dt = datetime(int(parts[2]), int(parts[1]), int(parts[0]))
                elif '-' in dob_str:
                    parts = dob_str.split('-')
                    if len(parts) != 3: return False
                    if len(parts[0]) == 4:
                        dt = datetime(int(parts[0]), int(parts[1]), int(parts[2]))
                    else:
                        dt = datetime(int(parts[2]), int(parts[1]), int(parts[0]))
                else:
                    return False
                
                now = datetime.now()
                try:
                    eighteen_years_ago = now.replace(year=now.year - 18, hour=0, minute=0, second=0, microsecond=0)
                except ValueError:
                    # Handle Feb 29 leap year edge case
                    eighteen_years_ago = now.replace(year=now.year - 18, month=2, day=28, hour=0, minute=0, second=0, microsecond=0)
                
                # If they were born *after* eighteen_years_ago, they are still under 18
                return dt > eighteen_years_ago
            except Exception:
                return False

        # 1. Base QuerySet based strictly on age < 18
        base_qs = queryset.filter(
            persons__role__in=['accused', 'suspected_accused', 'unidentified_accused', 'unknown_accused'],
            persons__age__lt=18,
            persons__age__gt=0
        ).values_list('id', flat=True)
        
        juvenile_ids = set(base_qs)
        
        def _check_age_val(val):
            if not val: return False
            if str(val).isdigit() and 0 < int(val) < 18: return True
            return _is_juvenile_dob(str(val))

        # 2. Check JSON extra_fields for age/dob < 18 for remaining cases
        for case in queryset.exclude(id__in=juvenile_ids).only('id', 'extra_fields'):
            extra = case.extra_fields
            if not isinstance(extra, dict): continue
            
            is_juv = False
            
            # top-level accused age fields
            if any(_check_age_val(extra.get(k)) for k in ['accused_age', 'suspected_accused_age', 'juvenileAge', 'juvenile_age']):
                is_juv = True
            
            if not is_juv:
                lists_to_check = [
                    extra.get('accusedDetails', []),
                    extra.get('accused_list', []),
                    extra.get('suspected_accused_list', []),
                    extra.get('unidentified_accused_list', []),
                ]
                cf = extra.get('commonForm', {})
                if isinstance(cf, dict):
                    lists_to_check.append(cf.get('accusedDetails', []))
                    lists_to_check.append(cf.get('accused_list', []))
                    if any(_check_age_val(cf.get(k)) for k in ['accused_age', 'suspected_accused_age', 'juvenileAge', 'juvenile_age']):
                        is_juv = True
                    
                if not is_juv:
                    for lst in lists_to_check:
                        if not isinstance(lst, list): continue
                        for item in lst:
                            if isinstance(item, dict):
                                if (
                                    _check_age_val(item.get('age')) or
                                    _check_age_val(item.get('accused_age')) or
                                    _check_age_val(item.get('ua_age')) or
                                    _check_age_val(item.get('dob'))
                                ):
                                    is_juv = True
                                    break
                        if is_juv: break

            if is_juv:
                juvenile_ids.add(case.id)
                
        return CaseRecord.objects.filter(id__in=juvenile_ids).distinct()
    elif tab.lower() in ['nafis', 'nafis_pending']:
        return queryset.filter(
            # Forensics relational table checks
            Q(forensics__nafis_fingerprint__isnull=False) |
            Q(forensics__fingerprint_taken__isnull=False) |
            # Direct extra_fields keys
            Q(extra_fields__has_key='nafis_fingerprint') |
            Q(extra_fields__has_key='nafisFingerprint') |
            Q(extra_fields__has_key='fingerprintVal') |
            Q(extra_fields__has_key='fingerprint_taken') |
            # Investigation notes nested keys
            Q(extra_fields__investigationNotes__has_key='nafisFingerprint') |
            Q(extra_fields__investigationNotes__has_key='fingerprintVal') |
            Q(extra_fields__investigation_notes__has_key='nafis_fingerprint') |
            Q(extra_fields__investigation_notes__has_key='fingerprint_taken') |
            # Common form nested keys
            Q(extra_fields__commonForm__investigationNotes__has_key='nafisFingerprint') |
            Q(extra_fields__commonForm__investigationNotes__has_key='fingerprintVal')
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
