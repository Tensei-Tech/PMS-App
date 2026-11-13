"""
Which cases are Road Accident cases, for the DAR and IRAD tabs.

A case belongs when it is in one of the tabs that use the "Road Accident Extra
Template" form (Road Accident, Death Due to Rash Driving, Other Road Accident,
in "1 to 5" and standalone).

This replaced matching on words ("accident", "road", "rash") and on JSON key
names (acc_dar, ...), which pulled in Other Accident (not a road accident)
and a Murder case whose Common Form used the acc_ prefix for accused fields.
"""
from typing import Optional

from django.db.models import Q

ROAD_ACCIDENT_TEMPLATE = 'Road Accident Extra Template'
# The Road Accident sub-tabs by name, also used when the categories are not
# loaded (fresh database, tests). Exact names only: "Other Accident" is not here.
ROAD_ACCIDENT_TAB_NAMES = ('Road Accident', 'Death Due to Rash Driving', 'Other Road Accident')


def road_accident_categories():
    """(ids, codes, names) of the tabs that use the Road Accident form."""
    from apps.crimetab.models.groupings import CaseCategory
    cats = CaseCategory.objects.filter(
        Q(category_template_mappings__template__template_name=ROAD_ACCIDENT_TEMPLATE)
        | Q(template__template_name=ROAD_ACCIDENT_TEMPLATE)
    ).distinct()
    ids, codes, names = set(), set(), set()
    for cat_id, code, name in cats.values_list('category_id', 'category_code', 'category_name'):
        ids.add(cat_id)
        if code:
            codes.add(code)
        if name:
            names.add(name)
    return ids, codes, names


def road_accident_case_q() -> Q:
    """Cases in a Road Accident tab. Having a road_accident_records row is not
    enough: older saves created empty rows for other cases."""
    ids, _codes, names = road_accident_categories()
    q = Q(module_key__iexact='road_accident')
    if ids:
        q |= Q(category_links__category_id__in=ids)
    for name in set(names) | set(ROAD_ACCIDENT_TAB_NAMES):
        q |= Q(sub_category__iexact=name)
    return q


def is_road_accident_case(case) -> bool:
    """The same rule as road_accident_case_q, for one saved case."""
    _ids, _codes, names = road_accident_categories()
    tabs = {n.lower() for n in set(names) | set(ROAD_ACCIDENT_TAB_NAMES)}
    if (case.module_key or '').lower() == 'road_accident' or (case.sub_category or '').strip().lower() in tabs:
        return True
    if case.pk and _ids:
        return case.category_links.filter(category_id__in=_ids).exists()
    return False


def with_table_answers(case, keys) -> dict:
    """
    The case's JSON with the road_accident_records answers laid over it, so the
    Filled / Pending rules read the table first and old JSON-only cases still work.
    `keys` maps a JSON key to (record attribute, is_date).
    """
    extra = dict(case.extra_fields) if isinstance(case.extra_fields, dict) else {}
    record = _record(case)
    if record is None:
        return extra
    for json_key, (attr, is_date) in keys.items():
        value = getattr(record, attr, None)
        if value in (None, ''):
            continue
        extra[json_key] = value.strftime('%d/%m/%Y') if is_date else value
    return extra


def _record(case) -> Optional[object]:
    try:
        return case.road_accident
    except Exception:  # RelatedObjectDoesNotExist: no row for this case
        return None
