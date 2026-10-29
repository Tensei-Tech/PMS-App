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
