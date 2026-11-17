"""
The service-tab answers kept once: in their tables, not again in the case JSON.

The app sends a service-tab record (Sam/Warrant, Passport/PVR, Licence, Tadipar
with its Crime Chart, Preventive) as one JSON document, and the same answer often
sits in two or three places of it (top level, extra_field_values,
dynamic_extra_fields, preventiveForm). Since the tables hold every answer, the
stored JSON does not need those copies.

    strip_table_copies(case, extra)  -> the JSON to store: every answer the tables
                                        rebuild exactly is taken out, and a small
                                        list (MARKER) says where it was and how it
                                        was written (date style, number as text ...)
    restore_table_copies(case, extra) -> the JSON exactly as the app sent it

Safety: an answer is only taken out when the table rebuilds it exactly, and the
whole result is checked (restore(strip(json)) == json) before anything is
stored; otherwise the JSON is stored as it is. CaseRecord restores the JSON when
it is loaded (CaseRecord.from_db), so all code and every API sees the full JSON
as before; only the stored copy is smaller.
"""
import copy
import json
import logging
import re
from datetime import date, datetime

from django.utils import timezone

from apps.crimetab import service_tab_tables as S

logger = logging.getLogger(__name__)

MARKER = '_table_copies'
VERSION = 1
CHART = '@chart'      # the Tadipar Crime Chart rows
PEOPLE = '@people'    # the Preventive accused list

EMPTY_LITERALS = ('', None, [], {})
DATE_STYLES = (
    '%Y-%m-%d', '%d/%m/%Y', '%d-%m-%Y', '%Y/%m/%d',
    '%Y-%m-%dT00:00:00.000', '%Y-%m-%dT00:00:00', '%Y-%m-%d 00:00:00', '%Y-%m-%dT00:00:00.000Z',
    '%Y-%m-%dT%H:%M:%S.%3f', '%Y-%m-%dT%H:%M:%S.%f', '%Y-%m-%dT%H:%M:%S',
    '%Y-%m-%dT%H:%M:%S.%f+05:30', '%Y-%m-%dT%H:%M:%S.%3f+05:30', '%Y-%m-%dT%H:%M:%S+05:30',
    '%Y-%m-%dT%H:%M', '%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M', '%d/%m/%Y %H:%M', '%d/%m/%Y %H:%M:%S',
)


# ------------------------------------------------------------------ where the copies are

def _flat_candidates(columns):
    """(container path, JSON key, column) for a tab whose answers sit at the top and in the form copies."""
    out = []
    for path in [()] + [(n,) for n in S.NESTED_COPIES]:
        for column, keys in columns.items():
            for key in keys:
                out.append((path, key, column))
    return out


def _keys(mapping):
    return {col: (v[0] if isinstance(v, tuple) and isinstance(v[0], tuple) else v) for col, v in mapping.items()}


def _tab_candidates():
    tadipar = {**_keys(S.TADIPAR_TEXT), **S.TADIPAR_NUMBERS, **S.TADIPAR_DATES}
    preventive = [((S.FORM_KEY, path[0]), path[1], column) for column, (path, _kind) in S.PREVENTIVE_FIELDS.items()]
    # the form also writes its sections (caseRef, istegasha ...) at the top level
    preventive += [((path[0],), path[1], column) for column, (path, _kind) in S.PREVENTIVE_FIELDS.items()]
    preventive += [(where, key, 'preventive_section_act') for where in ((), (S.FORM_KEY,))
                   for key in ('preventiveAct', 'act')]
    preventive += [(where, key, column) for where in ((), (S.FORM_KEY,))
                   for column, keys in S.PREVENTIVE_TOP.items() for key in keys]
    preventive += [((S.FORM_KEY,), 'accusedList', PEOPLE), ((), 'accusedList', PEOPLE)]
    return {
        'sam_warrant': _flat_candidates(S.WARRANT_KEYS),
        'passport_pvr': _flat_candidates({**_keys(S.PASSPORT_TEXT), **S.PASSPORT_COUNTS, **S.PASSPORT_DATES}),
        'licence': _flat_candidates({**_keys(S.LICENCE_TEXT), **S.LICENCE_DATES, **S.LICENCE_DATETIMES}),
        # the Crime Chart list first: its key is also the old text column's
        'tadipar': [(p, S.CHART_KEY, CHART) for p in [()] + [(n,) for n in S.NESTED_COPIES]] + _flat_candidates(tadipar),
        'preventive': preventive,
    }


CANDIDATES = _tab_candidates()


def tab_of(case):
    for tab, (is_tab, _save, _rel, _keys) in S.TABS.items():
        if is_tab(case):
            return tab
    return None


def _container(extra, path, create=False):
    node = extra
    for key in path:
        nxt = node.get(key) if isinstance(node, dict) else None
        if not isinstance(nxt, dict):
            if not create:
                return None
            nxt = {}
            node[key] = nxt
        node = nxt
    return node if isinstance(node, dict) else None


# ------------------------------------------------------------------ table values

def table_values(case, tab):
    """{column: value} of the case's row for this tab, read fresh (None when there is no row)."""
    from apps.crimetab.models.common_form import PreventiveActionItems
    from apps.crimetab.models.service_tabs import (
        LicenceRecord, PassportPvrRecord, PreventiveRecord, SamWarrantRecord, TadiparCrimeChartEntry, TadiparRecord)
    model = {'sam_warrant': SamWarrantRecord, 'passport_pvr': PassportPvrRecord, 'licence': LicenceRecord,
             'tadipar': TadiparRecord, 'preventive': PreventiveRecord}[tab]
    row = model.objects.filter(case_id=case.pk).first()
    if row is None:
        return None
    values = {f.name: getattr(row, f.attname) for f in model._meta.concrete_fields}
    values['_choices'] = {f.name: dict(f.choices) for f in model._meta.concrete_fields if f.choices}
    if tab == 'tadipar':
        values[CHART] = S.chart_answer_from_rows(TadiparCrimeChartEntry.objects.filter(record_id=case.pk))
    if tab == 'preventive':
        items = list(PreventiveActionItems.objects.filter(case_id=case.pk).order_by('pk'))
        values[PEOPLE] = S.preventive_document(row, items).get('accusedList') or []
    return values


# ------------------------------------------------------------------ writing a value the way the JSON had it

def _same(a, b):
    return json.dumps(a, sort_keys=True, default=str) == json.dumps(b, sort_keys=True, default=str)


def _strftime(value, fmt):
    if isinstance(value, datetime):
        value = timezone.localtime(value) if timezone.is_aware(value) else value
    elif not isinstance(value, date):
        return None
    if '%3f' in fmt:
        fmt = fmt.replace('%3f', f'{value.microsecond // 1000:03d}' if isinstance(value, datetime) else '000')
    return value.strftime(fmt)


def render(value, style, choices=None):
    """The table value written in the JSON's style."""
    if style.startswith('lit:'):
        return json.loads(style[4:])
    if value in (None, ''):
        return None
    if style == 'raw':
        return value
    if style == 'str':
        return str(value)
    if style == 'label':
        return (choices or {}).get(value) if isinstance(value, str) else None
    if style == 'yes_no':
        return 'Yes' if value else 'No'
    if style == 'yes_no_lower':
        return 'yes' if value else 'no'
    if style == 'json':
        if not isinstance(value, str):
            return None
        try:
            return json.loads(value)
        except (TypeError, ValueError):
            return None
    if style.startswith('d:'):
        return _strftime(value, style[2:])
    return None


def style_for(value, original, choices=None):
    """A style that writes `value` exactly as `original`, or None."""
    if any(_same(original, e) and type(original) is type(e) for e in EMPTY_LITERALS):
        return 'lit:' + json.dumps(original)
    if value in (None, ''):
        return None
    styles = ['raw', 'str', 'label', 'json']
    if isinstance(value, bool):
        styles = ['raw', 'yes_no', 'yes_no_lower']
    elif isinstance(value, (date, datetime)):
        styles = ['d:' + f for f in DATE_STYLES]
    for style in styles:
        out = render(value, style, choices)
        if out is not None and type(out) is type(original) and _same(out, original):
            return style
    return None


# ------------------------------------------------------------------ strip / restore
#
# The marker is kept short: {'v': 1, 't': tab,
#   'k': {container: 'key,key,...'  (or '=<other container>' for the same list)},
#   's': {'<container>>key': style}  (only when not the usual: '' for an empty
#                                      answer, the table value as it is otherwise)}
# Container '' is the top level, 'a/b' is extra_fields['a']['b'].

BLANK = 'lit:""'
SAFE_KEY = re.compile(r'^[^,>/=]+$')


# how each tab's form writes a date: dd/mm/yyyy, or ISO text with milliseconds
USUAL_DATE = {'tadipar': 'd:%d/%m/%Y', 'preventive': 'd:%d/%m/%Y'}
ISO_MS = 'd:%Y-%m-%dT%H:%M:%S.%3f'


def _usual_style(value, tab):
    """The style most answers have, so the marker only lists the others."""
    if value in (None, ''):
        return BLANK
    if isinstance(value, bool):
        return 'yes_no'
    if isinstance(value, int):
        return 'str'  # the forms send numbers as text
    if isinstance(value, (date, datetime)):
        return USUAL_DATE.get(tab, ISO_MS)
    return 'raw'


def _column_of(tab):
    """{(container path, key): column}: the first column a JSON key belongs to."""
    out = {}
    for path, key, column in CANDIDATES[tab]:
        out.setdefault((path, key), column)
    return out


COLUMN_OF = {tab: _column_of(tab) for tab in CANDIDATES}


def _entries(marker):
    """[(path, key, style)] from the marker."""
    lists = marker.get('k') or {}
    styles = marker.get('s') or {}
    out = []
    for where, keys in lists.items():
        while isinstance(keys, str) and keys.startswith('='):
            keys = lists.get(keys[1:], '')
        path = tuple(where.split('/')) if where else ()
        for key in (keys.split(',') if keys else []):
            out.append((path, key, styles.get(f'{where}>{key}')))
    return out


def restore_table_copies(case, extra, values=None):
    """The JSON as the app sent it (`extra` is not changed)."""
    if not isinstance(extra, dict) or MARKER not in extra:
        return extra
    out = copy.deepcopy(extra)
    marker = out.pop(MARKER)
    if not isinstance(marker, dict):
        return out
    tab = marker.get('t') or tab_of(case)
    if tab not in COLUMN_OF:
        return out
    if values is None:
        values = table_values(case, tab) or {}
    choices = values.get('_choices', {})
    for path, key, style in _entries(marker):
        column = COLUMN_OF[tab].get((path, key))
        value = values.get(column)
        target = _container(out, path, create=True)
        target[key] = render(value, style or _usual_style(value, tab), choices.get(column))
    return out


def strip_table_copies(case, extra, values=None):
    """The JSON to store: (stored JSON, number of answers taken out). Nothing is taken out
    unless the tables rebuild the whole document exactly."""
    if not isinstance(extra, dict) or MARKER in extra:
        return extra, 0
    tab = tab_of(case)
    if tab is None:
        return extra, 0
    if values is None:
        values = table_values(case, tab)
    if not values:
        return extra, 0
    choices = values.get('_choices', {})
    stripped = copy.deepcopy(extra)
    lists, styles, count = {}, {}, 0
    for (path, key), column in COLUMN_OF[tab].items():
        target = _container(stripped, path)
        if target is None or key not in target or not SAFE_KEY.match(key):
            continue
        value = values.get(column)
        style = style_for(value, target[key], choices.get(column))
        if style is None:
            continue
        where = '/'.join(path)
        del target[key]
        lists.setdefault(where, []).append(key)
        if style != _usual_style(value, tab):
            styles[f'{where}>{key}'] = style
        count += 1
    if not count:
        return extra, 0
    marker_lists, seen = {}, {}
    for where, keys in lists.items():
        text = ','.join(keys)
        marker_lists[where] = '=' + seen[text] if text in seen else text
        seen.setdefault(text, where)
    stripped[MARKER] = {'v': VERSION, 't': tab, 'k': marker_lists, **({'s': styles} if styles else {})}
    if not _same(restore_table_copies(case, stripped, values), extra):
        logger.warning('table copies: case %s does not rebuild exactly; JSON kept as it is', case.pk)
        return extra, 0
    return stripped, count


def restore_on_load(case):
    """CaseRecord.from_db: put the answers back so every reader sees the full JSON."""
    extra = case.__dict__.get('extra_fields')
    if isinstance(extra, dict) and MARKER in extra:
        try:
            case.__dict__['extra_fields'] = restore_table_copies(case, extra)
        except Exception:  # never break a case load: the stored JSON is still valid
            logger.exception('table copies: could not restore case %s', case.pk)

