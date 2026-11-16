from django.db.models import Value, Q
from django.db.models.functions import Coalesce, Concat
from django.db.models.fields.json import KeyTextTransform
from django.db import models
from apps.cases.models import CaseRecord
from apps.cases.constants import DISPOSAL_KEYS
IGNORED_ACCUSED_NAMES = {
    'default accused', 'unknown', 'unknown accused', 'अज्ञात',
    'unidentified', 'na', 'n/a', 'none', 'null', 'test accused',
    'suspect', 'accused', 'passport verification', '',
    # placeholders the forms use for a non-person party
    'business / entity', 'business', 'entity', 'company', 'firm', 'other', 'others',
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


def _accused_ages_for_case(case):
    """{name_lower: age or None} of a case's accused (persons table, then the case JSON)."""
    ages = {}

    def put(name, age):
        name = (name or '').strip()
        if not name or name.lower() in IGNORED_ACCUSED_NAMES or len(name) < 2:
            return
        digits = ''.join(ch for ch in str(age or '') if ch.isdigit())
        value = int(digits) if digits and 0 < int(digits) < 120 else None
        key = name.lower()
        if ages.get(key) is None:
            ages[key] = value

    for p in case.persons.all():
        if p.role in ('accused', 'suspected_accused', 'suspect'):
            put(p.name, p.age)
    ef = case.extra_fields if isinstance(case.extra_fields, dict) else {}
    cf = ef.get('commonForm') if isinstance(ef.get('commonForm'), dict) else {}
    for container in (ef, cf):
        for key in ('accused_list', 'accused'):
            val = container.get(key)
            if isinstance(val, list):
                for x in val:
                    if isinstance(x, dict):
                        put(x.get('name'), x.get('age'))
        if isinstance(container.get('accused_name'), str):
            put(container['accused_name'], container.get('accused_age'))
    for name in extract_accused_names_for_case(case):
        put(name, None)
    return ages


def _same_person(age_a, age_b):
    """Same name is the same person unless both ages are known and more than 2 years apart."""
    return age_a is None or age_b is None or abs(age_a - age_b) <= 2


def get_repeat_offender_map(station_names=None):
    """
    Accused who appear in more than one case (different CR numbers). Same name
    (ignoring case) and, where both ages are known, ages within 2 years;
    placeholder names such as "Business / Entity" are ignored.
    """
    from collections import defaultdict
    qs = CaseRecord.objects.all()
    if station_names:
        qs = qs.filter(station_name__in=station_names)

    by_name = defaultdict(list)  # name_lower -> [(case_id, cr, age)]
    name_display = {}
    for c in qs.prefetch_related('persons'):
        cr = (c.case_number or '').strip()
        if not cr or cr in ['—', '-']:
            continue
        for nl, age in _accused_ages_for_case(c).items():
            by_name[nl].append((c.id, cr, age))
            name_display.setdefault(nl, nl.title())

    repeat_case_ids = set()
    case_to_info = {}
    for nl, entries in by_name.items():
        for cid, cr, age in entries:
            others = sorted({o_cr for o_id, o_cr, o_age in entries
                             if o_cr != cr and _same_person(age, o_age)})
            if not others:
                continue
            repeat_case_ids.add(cid)
            case_to_info[cid] = {
                'accused_name': name_display[nl],
                'other_crs': others,
                'multiple_cr': ', '.join(others),
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
        return queryset.exclude(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved']).filter(crime_case_q())
    elif tab.lower() == 'detected':
        # Exclude administrative service modules and missing reports (which are tracked as Traced/Untraced)
        return queryset.filter(status__iexact='Detected').filter(crime_case_q()).exclude(
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
        return queryset.filter(crime_case_q()).filter(
            Q(forensics__isnull=False) |
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
    
    # Accused named in the persons table or the case's accused text; crime cases only;
    # anyone arrested in the arrest table is not absconding
    queryset = (CaseRecord.objects.filter(accused_known_q()).filter(crime_case_q())
                .exclude(get_license_passport_excluded_q())
                .exclude(id__in=arrested_in_table_case_ids())
                .exclude(module_key__in=['ad', 'preventive']))
    
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
    
    # The same groups as sub-tabs: crimes saved from "1 to 5" carry module
    # form_1_5, so their sub-tab name is what says they have a victim
    victim_tabs = [
        'pocso', 'crime against women', 'rape', 'molestation', '498 (a) ipc',
        'cheating', 'missing', 'kidnapping', 'kidnapping/missing',
        'accident', 'road accident', 'other road accident', 'death due to rash driving', 'other accident',
    ]
    tab_q = Q(pk__in=[])
    for tab in victim_tabs:
        tab_q |= Q(sub_category__iexact=tab)
    queryset = CaseRecord.objects.filter(
        Q(module_key__in=target_modules) | tab_q
    ).filter(crime_case_q()).distinct()
    
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

    # Nobody named in the persons table or the accused text, and not marked
    # Detected, so a case is never in both Detected and Undetected
    return queryset.exclude(accused_known_q()).filter(crime_case_q()).exclude(
        status__in=['Disposal', 'Disposed', 'Closed', 'Resolved', 'Detected']
    ).exclude(
        # accidental death and preventive records have no accused to trace
        module_key__in=['ad', 'preventive']
    ).exclude(
        get_undetected_excluded_crime_types_q()
    ).distinct()



# ---------------------------------------------------------------------------
# Shared rules for the fetching tabs (Pending, Detected, Undetected, Absconded,
# NAFIS): crime cases only, one meaning of "accused known", arrests from the
# arrest table as well as the case JSON.
# ---------------------------------------------------------------------------

# Service records kept in the case table but not crimes: passport / PVR /
# licence verification, summons / warrant, externment, RTI applications.
NON_CRIME_MODULES = (
    'passport', 'pvr', 'licence', 'license', 'arms_license', 'arms_licence', 'passport_pvr_lic',
    'sam_warrant', 'tadipar', 'application', 'rti',
)


def crime_case_q():
    """Q() keeping crime cases and leaving out service records."""
    return ~(
        Q(module_key__in=NON_CRIME_MODULES)
        | Q(sub_category__icontains='passport')
        | Q(sub_category__icontains='licence')
        | Q(sub_category__icontains='license')
        | Q(sub_category__iexact='sam/warrant')
        | Q(sub_category__iexact='tadipar')
    )


def accused_known_text_q():
    """The case's own `accused` text names someone."""
    return (
        Q(accused__isnull=False) & ~Q(accused__exact='') & ~Q(accused__iexact='unknown')
        & ~Q(accused__iexact='अज्ञात') & ~Q(accused__iexact='unidentified')
    )


def named_accused_case_ids():
    """Cases with a named accused or suspected accused in the persons table."""
    from apps.crimetab.models.common_form import CasesPerson
    qs = CasesPerson.objects.filter(role__in=['accused', 'suspected_accused']).exclude(name__isnull=True)
    for ignored in IGNORED_ACCUSED_NAMES:
        qs = qs.exclude(name__iexact=ignored)
    return qs.values('case_id')


def accused_known_q():
    """One meaning of "accused known" for every tab: persons table or the case's accused text."""
    return accused_known_text_q() | Q(id__in=named_accused_case_ids())


def arrested_in_table_case_ids():
    return CaseRecord.objects.filter(persons__arrest_status__arrest_datetime__isnull=False).values('id')
