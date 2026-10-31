"""
Which cases belong to a category group ("1 to 5" = group 1, "Part 6" = group 2).

Built only from the database (case_categories), not from hard-coded module
lists: a case is in the group when
- its module_key is the group's own module ('form_1_5' / 'form_6'), or the
  code or name (as a key: "Attempt to Murder" -> 'attempt_to_murder') of one
  of the group's categories, or
- its sub_category is the name of one of the group's categories, or
- it is linked (case_category_links) to one of the group's categories.
"""
import re

from django.db.models import Q

from apps.crimetab.models.groupings import CaseCategory

# group_id -> the group's own module key
GROUP_MODULE_KEYS = {1: 'form_1_5', 2: 'form_6'}


def _as_key(text):
    return re.sub(r'[^a-z0-9]+', '_', (text or '').lower()).strip('_')


def group_case_q(group_id):
    """Q() over CaseRecord for the cases of category group `group_id`."""
    keys = {GROUP_MODULE_KEYS[group_id]}
    q = Q(category_links__category__group_id=group_id)
    for name, code in CaseCategory.objects.filter(group_id=group_id).values_list(
            'category_name', 'category_code'):
        if name:
            keys.add(_as_key(name))
            q |= Q(sub_category__iexact=name)
        if code:
            keys.add(code.lower().strip())
    return q | Q(module_key__in=sorted(keys))


def get_preventive_eligible_categories_qs():
    """
    Find active CaseCategory records in the database where preventive action applies:
    1) Have is_active=True
    2) Linked to templates that contain preventive action fields
       (e.g., Common Form Baseline Template, NC Form, History Sheeter Template, Preventive Template)
       OR have category_code/category_name matching 'preventive'/'STAND_PREVENTIVE'.
    """
    from apps.crimetab.models import FieldTemplateField

    prev_template_ids = set(
        FieldTemplateField.objects.filter(
            Q(field_key__icontains='preventive') | Q(field_label__icontains='preventive')
        ).values_list('template_id', flat=True)
    )

    eligible_cats = CaseCategory.objects.filter(is_active=True).filter(
        Q(category_template_mappings__template_id__in=prev_template_ids) |
        Q(template_id__in=prev_template_ids) |
        Q(category_code__iexact='STAND_PREVENTIVE') |
        Q(category_name__iexact='Preventive')
    ).distinct()
    return eligible_cats


def preventive_case_q():
    """
    Q() over CaseRecord for the Preventive tab.
    Ensures that ONLY:
    - Standalone preventive cases
    - Cases from active, present crime categories in the database where preventive action applies
      AND that have preventive action recorded
    will show in the Preventive tab.
    """
    from apps.crimetab.models.common_form import PreventiveActionItems

    # 1. Base standalone preventive criteria
    q_standalone = (
        Q(module_key__iexact='preventive') |
        Q(sub_category__iexact='preventive') |
        Q(category_links__category__category_code__iexact='STAND_PREVENTIVE') |
        Q(category_links__category__category_name__iexact='preventive') |
        Q(category_links__category__category_code__iexact='preventive') |
        Q(extra_fields__has_key='preventiveForm')
    )

    eligible_cats = get_preventive_eligible_categories_qs()
    cat_names = set()
    cat_codes = set()
    cat_keys = set()

    for name, code in eligible_cats.values_list('category_name', 'category_code'):
        if name:
            cat_names.add(name)
            cat_keys.add(_as_key(name))
        if code:
            cat_codes.add(code)
            cat_codes.add(code.lower().strip())

    # Dynamically match active, present crime categories
    q_eligible_crime = (
        Q(category_links__category__in=eligible_cats) |
        Q(sub_category__in=cat_names) |
        Q(module_key__in=cat_codes | cat_keys) |
        (Q(module_key__in=['form_1_5', 'form_6']) & Q(sub_category__in=cat_names))
    )

    p_case_ids = list(PreventiveActionItems.objects.values_list('case_id', flat=True))
    q_crime_prev = Q(id__in=p_case_ids) & q_eligible_crime

    return q_standalone | q_crime_prev

