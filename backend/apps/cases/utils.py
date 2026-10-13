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


def enrich_preventive_case(case):
    """
    Attaches dynamic source mapping metadata and preventive tracking info to a CaseRecord.
    Fulfills 100% backend-driven source metadata requirement:
    - source_module_id
    - source_module_display_name
    - source_category_id
    - source_category_display_name
    - original_record_id
    - original_record_reference
    """
    if not case:
        return case

    extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
    cf = extra.get('commonForm', {}) if isinstance(extra.get('commonForm'), dict) else {}
    prev_form = extra.get('preventiveForm', {}) if isinstance(extra.get('preventiveForm'), dict) else {}

    # 1. Resolve source module and category
    source_module_id = case.module_key or 'preventive'
    mod_display_map = {
        'form_1_5': 'Form I to V',
        'form_6': 'Form VI',
        'preventive': 'Preventive Action',
        'tadipar': 'Tadipar',
        'theft': 'Theft',
        'hurt': 'Hurt',
        'pocso': 'POCSO',
        'ndps': 'NDPS',
        'prohibition': 'Prohibition',
        'gambling': 'Gambling',
        'accident': 'Accident',
        'missing': 'Missing',
        'kidnapping': 'Kidnapping',
        'victim': 'Victim',
    }
    source_module_display_name = mod_display_map.get(
        source_module_id.lower(),
        source_module_id.replace('_', ' ').title()
    )

    source_category_display_name = (
        case.sub_category or
        extra.get('crimeCategory') or
        prev_form.get('caseRef', {}).get('crimeCategory') or
        source_module_display_name
    )

    source_category_id = None
    try:
        link = getattr(case, 'category_links', None)
        if link and link.exists():
            source_category_id = link.first().category_id
    except Exception:
        pass

    # 2. Extract recorded preventive acts & statuses
    acts_taken = []
    # Check related PreventiveActionItems
    try:
        from apps.crimetab.models.common_form import PreventiveActionItems
        db_items = PreventiveActionItems.objects.filter(case=case)
        for it in db_items:
            if it.action_type and it.action_type not in acts_taken:
                acts_taken.append(it.action_type)
    except Exception:
        pass

    # Check extra_fields
    for k in ['preventive_action_type', 'preventiveSectionAct', 'preventiveSecAct', 'preventive_act']:
        val = extra.get(k) or cf.get(k) or prev_form.get('istegasha', {}).get(k)
        if val and str(val).strip() and str(val).strip() not in acts_taken:
            acts_taken.append(str(val).strip())

    items_list = extra.get('preventive_actions') or extra.get('preventive_action_items') or cf.get('preventive_actions') or []
    if isinstance(items_list, list):
        for it in items_list:
            if isinstance(it, dict) and it.get('action_type'):
                act_t = str(it['action_type']).strip()
                if act_t and act_t not in acts_taken:
                    acts_taken.append(act_t)

    # Has bond
    has_bond = False
    try:
        from apps.crimetab.models.common_form import PreventiveBond
        has_bond = PreventiveBond.objects.filter(case=case).exists()
    except Exception:
        pass
    if not has_bond:
        for b_key in ['bond_date', 'bondDate', 'bond_taken', 'bondTaken']:
            if extra.get(b_key) or cf.get(b_key):
                has_bond = True
                break

    # Determine action status
    raw_status = (
        extra.get('actionStatus') or
        extra.get('action_status') or
        prev_form.get('riskAndStatus', {}).get('actionStatus') or
        ''
    )
    if 'completed' in raw_status.lower():
        action_status = 'Preventive Action Completed'
    elif 'partially' in raw_status.lower() or (acts_taken and not has_bond):
        action_status = 'Partially Completed'
    elif acts_taken:
        action_status = 'Preventive Action Completed'
    else:
        action_status = 'No Preventive Action Recorded'

    metadata = {
        'source_module_id': source_module_id,
        'source_module_display_name': source_module_display_name,
        'source_category_id': source_category_id,
        'source_category_display_name': source_category_display_name,
        'original_record_id': str(case.id),
        'original_record_reference': case.case_number or case.title or f"Case #{case.id}",
        'preventive_action_status': action_status,
        'preventive_acts_taken': acts_taken,
        'has_bond': has_bond,
    }

    # Inject into extra_fields
    enriched_extra = dict(extra)
    enriched_extra['source_metadata'] = metadata
    enriched_extra['source_module_id'] = source_module_id
    enriched_extra['source_module_display_name'] = source_module_display_name
    enriched_extra['source_category_id'] = source_category_id
    enriched_category_name = source_category_display_name
    enriched_extra['source_category_display_name'] = enriched_category_name
    enriched_extra['original_record_id'] = str(case.id)
    enriched_extra['original_record_reference'] = metadata['original_record_reference']
    enriched_extra['preventive_action_status'] = action_status
    enriched_extra['preventive_acts_taken'] = acts_taken
    enriched_extra['has_bond'] = has_bond

    case.extra_fields = enriched_extra
    return case


def get_preventive_cases():
    """
    Returns cases that qualify for Preventive Action tracking.
    100% backend-driven eligibility evaluation:
    1. Direct Preventive / Istegasha cases (module_key == 'preventive' or sub_category == 'preventive')
    2. Cases with entries in preventive_action_items table
    3. Cases with entries in preventive_bond table
    4. Cases with preventive action recorded in extra_fields
    5. Cases flagged eligible for preventive monitoring across all crime categories
    """
    from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema
    from django.db.models import Q
    from apps.crimetab.models.common_form import PreventiveActionItems, PreventiveBond

    schema = get_active_tenant_schema()
    if schema and schema != 'public':
        set_tenant_schema(schema)

    # 1. Action items & bonds IDs
    item_case_ids = set(PreventiveActionItems.objects.values_list('case_id', flat=True))
    bond_case_ids = set(PreventiveBond.objects.values_list('case_id', flat=True))
    db_eligible_ids = item_case_ids.union(bond_case_ids)

    # 2. CaseRecord query
    direct_q = (
        Q(module_key__iexact='preventive') |
        Q(sub_category__iexact='preventive') |
        Q(sub_category__icontains='istegasha') |
        Q(id__in=list(db_eligible_ids)) |
        Q(extra_fields__has_key='preventiveForm') |
        Q(extra_fields__has_key='preventive_actions') |
        (Q(extra_fields__has_key='preventive_action_type') & ~Q(extra_fields__preventive_action_type='') & ~Q(extra_fields__preventive_action_type=None)) |
        Q(extra_fields__preventive_eligible=True)
    )

    queryset = CaseRecord.objects.filter(direct_q).distinct()

    if schema and schema != 'public':
        set_tenant_schema(schema)

    return queryset

