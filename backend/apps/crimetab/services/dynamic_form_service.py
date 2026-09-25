import logging
from typing import List, Dict, Any, Optional
from django.db.models import Q
from apps.crimetab.models.groupings import CaseCategory
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CategoryFieldOverride,
    CategoryFieldTemplate,
    SectionFieldTemplate,
)
from apps.crimetab.models.common_form import (
    CrimeCaseActsSections,
    Act,
    ActSection,
    PreventiveActionItems,
)

logger = logging.getLogger(__name__)


def get_form_definition(
    category_id: int,
    case_id: Optional[str] = None,
    charged_section_ids: Optional[List[int]] = None,
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

    if template_ids:
        cat_fields = FieldTemplateField.objects.filter(template_id__in=template_ids)
        fields.extend(list(cat_fields))

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
        case_charged_ids = CrimeCaseActsSections.objects.filter(
            case_id=case_id
        ).values_list('section_id', flat=True)
        section_ids_to_check.update(list(case_charged_ids))

    if section_ids_to_check:
        extra_template_ids = SectionFieldTemplate.objects.filter(
            section_id__in=section_ids_to_check
        ).values_list('template_id', flat=True)

        for t_id in extra_template_ids:
            extra_fields = FieldTemplateField.objects.filter(template_id=t_id)
            fields.extend(list(extra_fields))

    # 4. De-duplicate by field_key, preserving highest priority display_order
    seen = set()
    ordered_fields = []
    for f in sorted(fields, key=lambda x: x.display_order):
        if f.field_key not in seen:
            seen.add(f.field_key)
            ordered_fields.append({
                'field_def_id': f.field_def_id,
                'field_label': f.field_label,
                'field_key': f.field_key,
                'field_source': f.field_source,
                'field_type': f.field_type,
                'is_required': f.is_required,
                'display_order': f.display_order,
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

    preventive_choices = [c[0] for c in PreventiveActionItems.ACTION_TYPE_CHOICES]
    gender_choices = ['Male', 'Female', 'Other']
    procedural_map = {
        'chkPanchSpot': 'Spot Panchanama',
        'chkSeizurePanch': 'Seizure Panchanama',
        'chkSearch': 'Search Panchanama',
        'chkPersSearch': 'Personal Search Panchanama',
        'chkMemo': 'Memorandum Panchanama',
        'chkIdent': 'Identification Panchanama',
        'chkIdParade': 'Identification Parade Panchanama',
    }

    return {
        'category_id': category.category_id,
        'category_name': category.category_name,
        'category_code': category.category_code,
        'group_id': category.group_id,
        'fields_count': len(ordered_fields),
        'fields': ordered_fields,
        'acts_sections': acts_dict,
        'preventive_items': preventive_choices,
        'genders': gender_choices,
        'procedural_items': procedural_map,
    }

