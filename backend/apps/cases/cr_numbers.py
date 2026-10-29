"""
A CR number may be used only once per tab (a case's sub-category, e.g.
Murder or Attempt to Murder; its module when it has no sub-category) within a
police station. Another station, or another tab, may use the same number.

CR numbers are typed in different ways ("12", "CR 12", "cr/12"), so they are
compared without spaces, case and a leading "CR" with its separator.
"""
import re

_SPACES = re.compile(r'\s+')
_CR_PREFIX = re.compile(r'^CR[/\-_.:]?')


def normalize_cr(value) -> str:
    text = _SPACES.sub('', str(value or '')).upper()
    return _CR_PREFIX.sub('', text) or text


def case_tab(sub_category, module_key) -> str:
    """The tab a case belongs to, lower-cased."""
    return (sub_category or '').strip().lower() or (module_key or '').strip().lower()


def duplicate_cr_message(case_number, sub_category, module_key, station_name, exclude_id=None):
    """The error to show when another case of the station's tab has this CR number, else None."""
    if not find_duplicate_cr(case_number, sub_category, module_key, station_name, exclude_id=exclude_id):
        return None
    tab = (sub_category or module_key or 'this tab').strip()
    return f'CR number {str(case_number).strip()} is already used in {tab}. Enter a different CR number.'


def find_duplicate_cr(case_number, sub_category, module_key, station_name, exclude_id=None):
    """The other case of the same station and tab with this CR number, or None."""
    from django.db.models import Q
    from apps.cases.models import CaseRecord

    cr = normalize_cr(case_number)
    if not cr:
        return None
    sub = (sub_category or '').strip()
    if sub:
        qs = CaseRecord.objects.filter(sub_category__iexact=sub)
    else:
        qs = CaseRecord.objects.filter(Q(sub_category__isnull=True) | Q(sub_category=''),
                                       module_key__iexact=(module_key or '').strip())
    qs = qs.filter(station_name__iexact=(station_name or '').strip())
    if exclude_id is not None:
        qs = qs.exclude(pk=exclude_id)
    for other in qs.filter(case_number__icontains=cr).only('id', 'case_number', 'station_name'):
        if normalize_cr(other.case_number) == cr:
            return other
    return None
