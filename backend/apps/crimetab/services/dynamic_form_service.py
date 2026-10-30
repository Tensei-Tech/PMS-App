import json
import logging
from typing import List, Dict, Any, Optional
from django.db import transaction
from django.db.models import Q
from apps.crimetab.models.groupings import CaseCategory
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CategoryFieldOverride,
    CategoryFieldTemplate,
    SectionFieldTemplate,
)
from apps.crimetab.models.dynamic_engine import OptionValue
from apps.crimetab.models.common_form import (
    CrimeCaseActsSections,
    Act,
    ActSection,
)

logger = logging.getLogger(__name__)

PREVENTIVE_ACTION_OPTION_GROUP = 'preventive_action_types'
GENDER_OPTION_GROUP = 'gender'


def get_preventive_action_types() -> List[str]:
    """Active Common Form preventive provisions from public.option_values, in display order."""
    return list(
        OptionValue.objects.filter(option_group=PREVENTIVE_ACTION_OPTION_GROUP, is_active=True)
        .order_by('display_order', 'id')
        .values_list('option_value', flat=True)
    )


def get_option_values_by_group(option_group: str) -> List[str]:
    """Active option values for a given option_group from OptionValue table in display order."""
    if not option_group:
        return []
    return list(
        OptionValue.objects.filter(option_group=option_group, is_active=True)
        .order_by('display_order', 'id')
        .values_list('option_value', flat=True)
    )


def get_gender_choices() -> List[str]:
    """Active genders from public.option_values ('gender' group), in display order."""
    return list(
        OptionValue.objects.filter(option_group=GENDER_OPTION_GROUP, is_active=True)
        .order_by('display_order', 'id')
        .values_list('option_value', flat=True)
    )


def get_preventive_configuration() -> Dict[str, Any]:
    """
    Returns full database-backed dynamic configuration for the Preventive module.
    Pulls settings from ModuleSetting and dynamic dropdown options from OptionValue.
    """
    from apps.crimetab.models.dynamic_engine import ModuleSetting
    config = {
        "target_category_code": "STAND_PREVENTIVE",
        "template_name": "Preventive Module Configuration Template",
        "section_title": "Preventive Action",
        "section_order": 10,
        "defaults": {
            "crime_category": "",
            "act": "",
            "section": "",
            "has_preventive_no": "No",
            "case_status": "Under Investigation",
            "risk_flag": "\U0001F6A8 High Priority",
            "action_status": "\U0001F7E2 Preventive Action Completed",
            "accused_action_type": "Arrested",
            "bond_taken": "No",
            "date_default": "current_date",
            "complainant": ""
        },
        "section_titles": {
            "case_ref": "Case & Crime Reference",
            "sections": "Sections & Acts",
            "accused": "Accused Details",
            "istegasha": "Preventive / Istegasha Details",
            "risk_status": "Risk Flag & Action Status",
            "preventive_action": "Preventive Action"
        },
        "action_labels": {
            "add": "Add Preventive Case",
            "edit": "Edit",
            "view": "View",
            "pdf": "PDF"
        },
        "messages": {
            "no_station": "No valid police station assigned to the current user or session. Please select or switch to a police station before saving.",
            "empty_request": "Please enter Crime No. / FIR No. / NC No. or Preventive No."
        }
    }
    try:
        setting = ModuleSetting.objects.filter(module_key='preventive', setting_key='config').first()
        if setting and setting.setting_value:
            loaded = json.loads(setting.setting_value)
            if isinstance(loaded, dict):
                config.update(loaded)
    except Exception as e:
        logger.warning(f"[dynamic_form_service] Failed to load preventive configuration: {e}")

    # Merge dynamic option values from OptionValue table
    config['case_statuses'] = get_option_values_by_group('preventive_case_statuses') or [
        'Under Investigation', 'Chargesheeted'
    ]
    config['risk_flags'] = get_option_values_by_group('preventive_risk_flags') or [
        '\U0001F6A8 High Priority', '\U0001F6D1 Sensitive'
    ]
    config['action_statuses'] = get_option_values_by_group('preventive_action_statuses') or [
        '\U0001F7E2 Preventive Action Completed', '\U0001F7E1 Partially Completed', '\U0001F534 No Preventive Action Recorded'
    ]
    config['accused_action_types'] = get_option_values_by_group('preventive_accused_actions') or [
        'Arrested', 'Notice Issued', 'Not Arrested'
    ]
    config['yes_no_options'] = get_option_values_by_group('yes_no') or ['Yes', 'No']
    return config


def _fetch_field_template_fields(qs):
    try:
        return list(qs)
    except Exception:
        # Schema backward compatibility if depends_on_field_key, depends_on_value, options_source columns are not yet applied to database
        return list(qs.defer('depends_on_field_key', 'depends_on_value', 'options_source'))


def _safe_get_attr(obj, attr_name):
    try:
        return getattr(obj, attr_name, None)
    except Exception:
        return None


def get_dashboard_tools(tenant_schema: Optional[str] = None) -> List[Dict[str, Any]]:
    """
    Retrieves dynamic dashboard tools metadata from ModuleSetting.
    Includes module key, display name, icon/asset reference, color, category, and display order.
    Ensures zero frontend hardcoded entries for tools like Tadipar.
    """
    from apps.crimetab.models.dynamic_engine import ModuleSetting
    try:
        setting = ModuleSetting.objects.filter(module_key='dashboard', setting_key='tools').first()
        if setting and setting.setting_value:
            tools = json.loads(setting.setting_value)
            if isinstance(tools, list):
                return sorted(
                    [t for t in tools if t.get('is_active', True)],
                    key=lambda x: x.get('display_order', 0)
                )
    except Exception as e:
        logger.debug(f"[dynamic_form_service] Failed to load dashboard tools from ModuleSetting: {e}")
    return []


def auto_assign_category_sequences(category, extra_fields: dict, station_name: Optional[str] = None) -> dict:
    """
    Generic configuration-driven sequence auto-numbering.
    Inspects all templates linked to the category via CategoryFieldTemplate and category.template.
    For each field with auto_generate=True or options_source.startswith('auto:'),
    generates the next sequential number atomically (safely serialized) and populates extra_fields.
    Zero module-specific or hardcoded name checks.
    """
    if not category or not isinstance(extra_fields, dict):
        return extra_fields

    from apps.crimetab.models.dynamic_engine import CategoryFieldTemplate, FieldTemplateField

    template_ids = list(CategoryFieldTemplate.objects.filter(
        category=category
    ).values_list('template_id', flat=True))
    if not template_ids and category.template_id:
        template_ids = [category.template_id]

    if not template_ids:
        return extra_fields

    fields = FieldTemplateField.objects.filter(template_id__in=template_ids)
    for f in fields:
        f_config = getattr(f, 'field_config', None) or {}
        opt_source = getattr(f, 'options_source', None) or ''
        is_auto = (
            (isinstance(f_config, dict) and f_config.get('auto_generate') is True) or
            opt_source.startswith('auto:')
        )
        if is_auto:
            assigned_seq = get_next_category_sequence(
                category,
                field_key=f.field_key,
                station_name=station_name,
                increment=True
            )
            assigned_str = str(assigned_seq)
            extra_fields[f.field_key] = assigned_str
            for nest_key in ('commonForm', 'extra_field_values', 'dynamic_extra_fields'):
                if nest_key in extra_fields and isinstance(extra_fields[nest_key], dict):
                    extra_fields[nest_key][f.field_key] = assigned_str

    return extra_fields

def get_next_category_sequence(
    category,
    field_key: str = 'sr_no',
    station_name: Optional[str] = None,
    increment: bool = False
) -> int:
    """
    Computes or increments the next sequence number for a category's auto-generated field.
    Purely database-backed: checks ModuleSetting counter, CaseRecord extra_fields, and CaseExtraFieldValue.
    When increment=True, atomically increments and persists the new counter in ModuleSetting.
    """
    from apps.cases.models import CaseRecord
    from apps.crimetab.models.dynamic_engine import ModuleSetting, CaseExtraFieldValue

    cat_code = (getattr(category, 'category_code', None) or '').strip().lower() if hasattr(category, 'category_code') else str(category).strip().lower()
    cat_id = getattr(category, 'category_id', None)
    cat_name = getattr(category, 'category_name', '')

    setting_key = f"last_seq_{field_key}"
    station_setting_key = None
    if station_name and str(station_name).strip():
        clean_st = str(station_name).strip().replace(' ', '_').lower()
        station_setting_key = f"last_seq_{field_key}_{clean_st}"

    max_val = 0

    # 1. Check ModuleSetting sequence counter
    try:
        keys_to_check = [k for k in [station_setting_key, setting_key] if k]
        for k in keys_to_check:
            setting = ModuleSetting.objects.filter(module_key=cat_code or 'crimetab', setting_key=k).first()
            if setting and setting.setting_value and str(setting.setting_value).strip().isdigit():
                max_val = max(max_val, int(str(setting.setting_value).strip()))
    except Exception as e:
        logger.debug(f"[dynamic_form_service] ModuleSetting query failed: {e}")

    # 2. Query existing cases in the active tenant
    try:
        cat_q = Q()
        if cat_id:
            cat_q |= Q(category_links__category_id=cat_id)
        if cat_code:
            cat_q |= Q(module_key__iexact=cat_code)
        if cat_name:
            cat_q |= Q(sub_category__iexact=cat_name)

        cases_qs = CaseRecord.objects.filter(cat_q)
        if station_name and str(station_name).strip():
            station_filtered = cases_qs.filter(station_name__iexact=station_name)
            if station_filtered.exists():
                cases_qs = station_filtered

        # 2. Check CaseRecord extra_fields
        for c in cases_qs:
            ef = c.extra_fields if isinstance(c.extra_fields, dict) else {}
            val = (
                ef.get(field_key) or
                (ef.get('commonForm') or {}).get(field_key) or
                (ef.get('extra_field_values') or {}).get(field_key) or
                (ef.get('dynamic_extra_fields') or {}).get(field_key)
            )
            if val is not None:
                val_str = str(val).strip()
                if val_str.isdigit():
                    max_val = max(max_val, int(val_str))

        # 3. Check CaseExtraFieldValue table
        efvs = CaseExtraFieldValue.objects.filter(case__in=cases_qs, field_def__field_key=field_key)
        for efv in efvs:
            if efv.field_value and str(efv.field_value).strip().isdigit():
                max_val = max(max_val, int(str(efv.field_value).strip()))
    except Exception as e:
        logger.debug(f"[dynamic_form_service] Case query skipped or failed: {e}")

    next_num = max_val + 1

    if increment:
        try:
            with transaction.atomic():
                keys_to_update = [setting_key]
                if station_setting_key:
                    keys_to_update.append(station_setting_key)

                for k in keys_to_update:
                    obj = ModuleSetting.objects.select_for_update().filter(
                        module_key=cat_code or 'crimetab',
                        setting_key=k,
                    ).first()
                    if obj:
                        curr_val = int(str(obj.setting_value).strip()) if obj.setting_value and str(obj.setting_value).strip().isdigit() else 0
                        if next_num > curr_val:
                            obj.setting_value = str(next_num)
                            obj.save(update_fields=['setting_value'])
                    else:
                        ModuleSetting.objects.create(
                            module_key=cat_code or 'crimetab',
                            setting_key=k,
                            setting_value=str(next_num),
                        )
        except Exception as e:
            logger.debug(f"[dynamic_form_service] atomic update of ModuleSetting failed: {e}")
            ModuleSetting.objects.update_or_create(
                module_key=cat_code or 'crimetab',
                setting_key=setting_key,
                defaults={'setting_value': str(next_num)}
            )
            if station_setting_key:
                ModuleSetting.objects.update_or_create(
                    module_key=cat_code or 'crimetab',
                    setting_key=station_setting_key,
                    defaults={'setting_value': str(next_num)}
                )

    return next_num


def get_form_definition(
    category_id: int,
    case_id: Optional[str] = None,
    charged_section_ids: Optional[List[int]] = None,
    station_name: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Core Dynamic Field Engine: Reshapes ONE form based on two triggers:
    Trigger A: ALL templates linked to this category in CategoryFieldTemplate (baseline + tab-specific extra templates).
    Trigger B: Section(s) currently charged in 'Acts & Sections Filed' unlocking extra templates.
    """
    category = CaseCategory.objects.filter(pk=category_id).first()
    if not category:
        return {'category_id': category_id, 'fields': [], 'error': 'Category not found'}

    fields: List[FieldTemplateField] = []

    # 1. Trigger A: ALL templates linked to this category (not just one)
    template_ids = list(CategoryFieldTemplate.objects.filter(
        category_id=category_id
    ).values_list('template_id', flat=True))

    # Backward compatibility fallback if category_field_templates has no rows yet
    if not template_ids and category.template_id:
        template_ids = [category.template_id]

    templates = list(FieldTemplate.objects.filter(template_id__in=template_ids))
    has_common_form_baseline = any(t.template_name == 'Common Form Baseline Template' for t in templates)
    has_linked_bundle = len(template_ids) > 0

    if template_ids:
        cat_fields = _fetch_field_template_fields(FieldTemplateField.objects.filter(template_id__in=template_ids))
        fields.extend(cat_fields)

    # 2. Trigger A Override: Apply per-category visibility overrides
    overrides = {
        o.field_key: o.is_visible
        for o in CategoryFieldOverride.objects.filter(category_id=category_id)
    }
    fields = [f for f in fields if overrides.get(f.field_key, True)]

    # 3. Trigger B: Layer in extra fields from charged sections
    section_ids_to_check = set()
    if charged_section_ids:
        raw_items = [str(s).strip() for s in charged_section_ids if s]
        numeric_ids = [int(s) for s in raw_items if s.isdigit()]
        matched_by_num = list(
            ActSection.objects.filter(
                Q(section_id__in=numeric_ids) | Q(section_number__in=raw_items)
            ).values_list('section_id', flat=True)
        )
        section_ids_to_check.update(matched_by_num)
        section_ids_to_check.update(numeric_ids)

    if case_id:
        try:
            case_charged_ids = CrimeCaseActsSections.objects.filter(
                case_id=case_id
            ).values_list('section_id', flat=True)
            section_ids_to_check.update(list(case_charged_ids))
        except Exception as e:
            logger.warning(f"[dynamic_form_service] Failed to query CrimeCaseActsSections for case {case_id}: {e}")

    if template_ids and section_ids_to_check:
        extra_template_ids = SectionFieldTemplate.objects.filter(
            section_id__in=section_ids_to_check
        ).values_list('template_id', flat=True)

        for t_id in extra_template_ids:
            extra_fields = _fetch_field_template_fields(FieldTemplateField.objects.filter(template_id=t_id))
            fields.extend(extra_fields)

    # 4. De-duplicate by field_key, preserving highest priority display_order
    seen = set()
    ordered_fields = []
    next_sequences = {}
    cat_code = (getattr(category, 'category_code', None) or '').strip().lower()
    for f in sorted(fields, key=lambda x: x.display_order):
        if f.field_key not in seen:
            seen.add(f.field_key)
            f_config = _safe_get_attr(f, 'field_config') or {}
            opt_source = _safe_get_attr(f, 'options_source') or ''

            # Field is auto-generated if options_source is auto:... or field_config has auto_generate
            is_auto = (
                (isinstance(f_config, dict) and f_config.get('auto_generate') is True) or
                opt_source.startswith('auto:')
            )
            is_ro = (
                (isinstance(f_config, dict) and f_config.get('read_only') is True) or
                is_auto
            )

            default_val = None
            if is_auto:
                next_seq = get_next_category_sequence(category, field_key=f.field_key, station_name=station_name, increment=False)
                next_sequences[f.field_key] = next_seq
                if not case_id:
                    default_val = str(next_seq)
            elif isinstance(f_config, dict) and ('default_value' in f_config or 'default' in f_config):
                raw_default = f_config.get('default_value') if 'default_value' in f_config else f_config.get('default')
                default_val = str(raw_default) if raw_default is not None else None

            if opt_source and isinstance(f_config, dict) and not f_config.get('options'):
                dyn_opts = get_option_values_by_group(opt_source)
                if dyn_opts:
                    f_config = dict(f_config)
                    f_config['options'] = dyn_opts

            ordered_fields.append({
                'field_def_id': f.field_def_id,
                'field_label': f.field_label,
                'field_key': f.field_key,
                'field_source': f.field_source,
                'field_type': f.field_type,
                'is_required': f.is_required,
                'section': getattr(f, 'section', None),
                'display_order': f.display_order,
                'depends_on_field_key': _safe_get_attr(f, 'depends_on_field_key'),
                'depends_on_value': _safe_get_attr(f, 'depends_on_value'),
                'options_source': opt_source or None,
                'parent_field_key': _safe_get_attr(f, 'parent_field_key'),
                'field_config': f_config if isinstance(f_config, dict) else {},
                'is_auto_generated': is_auto,
                'is_readonly': is_ro,
                'default_value': default_val,
            })

    # 5. Master Acts & Sections
    acts_dict = {}
    for act in Act.objects.prefetch_related('sections').all():
        key = 'BNS' if ('Bharatiya Nyaya' in act.act_name or 'BNS' in act.act_name) else act.act_name
        sections_list = [
            {
                'val': s.section_number,
                'label': f"{s.section_number} - {s.section_title}",
                'title': s.section_title,
                'cat': key
            }
            for s in act.sections.all().order_by('section_number')
        ]
        acts_dict[key] = {
            'act_id': act.act_id,
            'label': act.act_name,
            'hint': 'Applies to offences on or after 1 July 2024.' if key == 'BNS' else '',
            'sections': sections_list
        }

    statutory_fallbacks = {
        'POCSO': {
            'label': 'POCSO Act, 2012',
            'hint': 'Victim must be under 18 years.',
            'sections': [
                {'val': '3', 'label': '3 - Penetrative Sexual Assault', 'cat': 'POCSO'},
                {'val': '4', 'label': '4 - Punishment for Penetrative Sexual Assault', 'cat': 'POCSO'},
                {'val': '5', 'label': '5 - Aggravated Penetrative Sexual Assault', 'cat': 'POCSO'},
                {'val': '6', 'label': '6 - Punishment for Aggravated Penetrative Sexual Assault', 'cat': 'POCSO'},
                {'val': '7', 'label': '7 - Sexual Assault', 'cat': 'POCSO'},
                {'val': '8', 'label': '8 - Punishment for Sexual Assault', 'cat': 'POCSO'},
                {'val': '9', 'label': '9 - Aggravated Sexual Assault', 'cat': 'POCSO'},
                {'val': '10', 'label': '10 - Punishment for Aggravated Sexual Assault', 'cat': 'POCSO'},
                {'val': '11', 'label': '11 - Sexual Harassment', 'cat': 'POCSO'},
                {'val': '12', 'label': '12 - Punishment for Sexual Harassment', 'cat': 'POCSO'},
            ]
        },
        'ARMS': {
            'label': 'Arms Act, 1959',
            'hint': 'Possession/manufacture/use of arms & ammunition.',
            'sections': [
                {'val': '3', 'label': '3 - Licence for acquisition and possession of firearms', 'cat': 'ARMS'},
                {'val': '4', 'label': '4 - Licence for acquisition and possession of other arms', 'cat': 'ARMS'},
                {'val': '25', 'label': '25 - Unlawful Possession of Arms', 'cat': 'ARMS'},
                {'val': '27', 'label': '27 - Punishment for using arms', 'cat': 'ARMS'},
            ]
        },
        'NDPS': {
            'label': 'NDPS Act, 1985',
            'hint': 'Narcotics/drugs/psychotropic substances.',
            'sections': [
                {'val': '8', 'label': '8 - Prohibition on production/sale/possession', 'cat': 'NDPS'},
                {'val': '20', 'label': '20 - Offences relating to Cannabis', 'cat': 'NDPS'},
                {'val': '21', 'label': '21 - Offences relating to manufactured drugs', 'cat': 'NDPS'},
                {'val': '22', 'label': '22 - Offences relating to psychotropic substances', 'cat': 'NDPS'},
            ]
        },
        'MCOCA': {
            'label': 'MCOCA, 1999',
            'hint': 'Requires SP-level sanction to invoke.',
            'sections': [
                {'val': '3(1)(i)', 'label': '3(1)(i) - Organised Crime causing death', 'cat': 'MCOCA'},
                {'val': '3(2)', 'label': '3(2) - Abetment/Conspiracy', 'cat': 'MCOCA'},
            ]
        },
        'MPDA': {
            'label': 'MPDA, 1981',
            'hint': 'Preventive Detention order.',
            'sections': [
                {'val': '3(1)', 'label': '3(1) - Detention of dangerous person', 'cat': 'MPDA'},
            ]
        },
        'IT': {
            'label': 'IT Act, 2000',
            'hint': 'Apply for cyber crimes and electronic fraud.',
            'sections': [
                {'val': '66', 'label': '66 - Computer Related Offences', 'cat': 'IT'},
                {'val': '66C', 'label': '66C - Identity Theft', 'cat': 'IT'},
                {'val': '66D', 'label': '66D - Cheating by personation using computer', 'cat': 'IT'},
                {'val': '67', 'label': '67 - Publishing obscene material electronically', 'cat': 'IT'},
            ]
        },
        'SC_ST': {
            'label': 'SC/ST (PoA) Act, 1989',
            'hint': 'Atrocity cases involving SC/ST victims.',
            'sections': [
                {'val': '3(1)(r)', 'label': '3(1)(r) - Intentional insult/intimidation', 'cat': 'SC_ST'},
                {'val': '3(2)(v)', 'label': '3(2)(v) - Murder/attempt on SC/ST member', 'cat': 'SC_ST'},
            ]
        },
    }
    for k, v in statutory_fallbacks.items():
        if k not in acts_dict:
            acts_dict[k] = v

    preventive_choices = get_preventive_action_types() if has_linked_bundle else []
    gender_choices = get_gender_choices() if has_linked_bundle else []
    procedural_map = {
        'chkPanchSpot': 'Spot Panchanama',
        'chkSeizurePanch': 'Seizure Panchanama',
        'chkSearch': 'Search Panchanama',
        'chkPersSearch': 'Personal Search Panchanama',
        'chkMemo': 'Memorandum Panchanama',
        'chkIdent': 'Identification Panchanama',
        'chkIdParade': 'Identification Parade Panchanama',
    }

    preventive_cfg = None
    if cat_code in ('preventive', 'stand_preventive') or category.category_id == 274 or has_linked_bundle:
        preventive_cfg = get_preventive_configuration()

    return {
        'category_id': category.category_id,
        'category_name': category.category_name,
        'category_code': category.category_code,
        'group_id': category.group_id,
        'has_linked_bundle': has_linked_bundle,
        'has_common_form_baseline': has_common_form_baseline,
        'template_names': [t.template_name for t in templates],
        'fields_count': len(ordered_fields),
        'fields': ordered_fields,
        'acts_sections': acts_dict if has_linked_bundle else {},
        'preventive_items': preventive_choices if has_linked_bundle else [],
        'genders': gender_choices if has_linked_bundle else [],
        'procedural_items': procedural_map if has_linked_bundle else {},
        'next_sequences': next_sequences,
        'preventive_config': preventive_cfg,
    }

