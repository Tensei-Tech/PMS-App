"""
Common Form answers saved into their own tables.

The app sends the Common Form as flat keys (`cctv_checked`, `nafis_fingerprint`,
`spot_panchanama`, `charges`: [{act_id, section_id, section_number, ...}], ...),
and the same keys are kept in the case's JSON (top level and again inside
`commonForm`). The older save code only read older names (`cctvChecked`,
`investigationNotes`, `proceduralChecks`, ...), so these four tables stayed
empty or wrong:

    crime_case_acts_sections   charges (Act / Section / Subsection)
    cctv_technical             CCTV checked, CDR sent / received
    case_forensics             e-Sakshya, fingerprint, NAFIS (+ their dates)
    procedural_checklist       the seven panchanama ticks

save_common_form_tables() fills them from a save request; it is also used by the
`backfill_common_form_tables` command for cases saved before this fix.

Where one answer appears in several places, the first non-empty value wins, in
this order: the request itself, the case JSON's top level, then `commonForm`
(which can hold an older, emptier copy).
"""
import logging
from datetime import date, datetime

from django.db.models import Q

logger = logging.getLogger(__name__)

EMPTY = (None, '', [], {})

# Form key -> procedural_checklist.item_name
PANCHANAMA_ITEMS = {
    'spot_panchanama': 'Spot Panchanama',
    'seizure_panchanama': 'Seizure Panchanama',
    'search_panchanama': 'Search Panchanama',
    'personal_search_panchanama': 'Personal Search Panchanama',
    'memorandum_panchanama': 'Memorandum Panchanama',
    'identification_panchanama': 'Identification Panchanama',
    'identification_parade_panchanama': 'Identification Parade Panchanama',
}

# case_forensics column -> (form keys for the tick, form keys for its date)
FORENSIC_FIELDS = {
    'e_shakshya': (('e_shakshya', 'eshakshValue'), ('e_shakshya_date',)),
    'fingerprint_taken': (('fingerprint_taken', 'fingerprintVal'), ('fingerprint_taken_date',)),
    'nafis_fingerprint': (('nafis_fingerprint', 'nafisFingerprint'), ('nafis_fingerprint_date',)),
}


# ------------------------------------------------------------------ reading

def sources_from(data=None, extra=None):
    """Dicts to read answers from, most reliable first."""
    data = data if isinstance(data, dict) else {}
    if extra is None:
        extra = data.get('extra_fields')
    extra = extra if isinstance(extra, dict) else {}
    common = extra.get('commonForm') if isinstance(extra.get('commonForm'), dict) else {}
    nested = []
    for src in (data, extra, common):
        for key in ('cctv_technical', 'forensics', 'case_forensics', 'investigationNotes'):
            if isinstance(src.get(key), dict):
                nested.append(src[key])
    return [data, extra, common, *nested]


def first(sources, *keys):
    """First non-empty value of any of `keys`, searching `sources` in order."""
    for src in sources:
        for key in keys:
            value = src.get(key)
            if value not in EMPTY:
                return value
    return None


def has_any(sources, *keys):
    return any(key in src for src in sources for key in keys)


def as_bool(value):
    """'Yes' / True / 'true' / 1 -> True, 'No' / False / 0 -> False, else None."""
    if isinstance(value, bool):
        return value
    if value is None:
        return None
    text = str(value).strip().lower()
    if text in ('yes', 'true', '1', 'y', 'checked'):
        return True
    if text in ('no', 'false', '0', 'n', 'unchecked'):
        return False
    return None


def as_date(value):
    if value in EMPTY:
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    text = str(value).strip()[:10]
    for fmt in ('%d/%m/%Y', '%Y-%m-%d', '%d-%m-%Y', '%Y/%m/%d'):
        try:
            return datetime.strptime(text, fmt).date()
        except ValueError:
            continue
    return None


# ------------------------------------------------------------------ charges

def _int(value):
    try:
        return int(str(value).strip())
    except (TypeError, ValueError):
        return None


def resolve_act(charge):
    """The Act a charge names: by id if it still exists, else by name. Never a guess."""
    from apps.crimetab.models.common_form import Act
    for key in ('act_id', 'act'):
        act_id = _int(charge.get(key))
        if act_id is not None:
            act = Act.objects.filter(act_id=act_id).first()
            if act:
                return act
    for key in ('act_name', 'act'):
        name = str(charge.get(key) or '').strip()
        if not name or name.isdigit():
            continue
        act = (Act.objects.filter(act_name__iexact=name).first()
               or Act.objects.filter(act_name__icontains=f'({name})').first()
               or Act.objects.filter(act_name__icontains=name).first())
        if act:
            return act
    return None


def resolve_section(act, charge):
    """The Section under `act`: by id if it belongs to the act, else by its number."""
    from apps.crimetab.models.common_form import ActSection
    for key in ('section_id', 'section'):
        sec_id = _int(charge.get(key))
        if sec_id is not None:
            section = ActSection.objects.filter(section_id=sec_id, act=act).first()
            if section:
                return section
    for key in ('section_number', 'section'):
        number = str(charge.get(key) or '').strip()
        if number and not (key == 'section' and charge.get('section_number')):
            section = ActSection.objects.filter(act=act, section_number__iexact=number).first()
            if section:
                return section
    return None


def resolve_subsection(section, charge):
    from apps.crimetab.models.common_form import ActSubsection
    if section is None:
        return None
    for key in ('subsection_id', 'subsection'):
        sub_id = _int(charge.get(key))
        if sub_id is not None:
            sub = ActSubsection.objects.filter(subsection_id=sub_id, section=section).first()
            if sub:
                return sub
    code = str(charge.get('subsection_code') or '').strip()
    if code:
        return ActSubsection.objects.filter(section=section, subsection_code__iexact=code).first()
    return None


def _charge_list(raw):
    """Charges as a list of dicts; the old {key: {act, sections: [...]}} shape is flattened."""
    if isinstance(raw, list):
        return [c for c in raw if isinstance(c, dict)]
    if isinstance(raw, dict):
        out = []
        for ch in raw.values():
            if not isinstance(ch, dict):
                continue
            sections = ch.get('sections') or []
            if isinstance(sections, str):
                sections = [sections]
            for number in sections:
                out.append({'act': ch.get('act') or ch.get('act_name'), 'section_number': str(number)})
        return out
    return []


def save_charges(case, sources, write=True, keep_when_empty=False):
    """
    Rewrite the case's charges when the save carries them. Returns (saved, skipped).
    A charge whose Act or Section cannot be found is skipped and logged, never guessed.
    """
    from apps.crimetab.models.common_form import CrimeCaseActsSections
    if not has_any(sources, 'charges', 'acts_sections'):
        return 0, 0
    raw = first(sources, 'charges', 'acts_sections')
    charges = _charge_list(raw)
    saved = skipped = 0
    seen = set()
    rows = []
    for ch in charges:
        if all(v in EMPTY for v in ch.values()):
            continue  # an empty row the form leaves behind
        act = resolve_act(ch)
        section = resolve_section(act, ch) if act else None
        if not section:
            skipped += 1
            logger.warning(f'[CommonForm] case {case.pk}: charge not found in Acts master: {ch}')
            continue
        sub = resolve_subsection(section, ch)
        key = (act.pk, section.pk, sub.pk if sub else None)
        if key in seen:
            continue
        seen.add(key)
        rows.append(CrimeCaseActsSections(case=case, act=act, section=section, subsection=sub))
        saved += 1
    if write and (rows or not keep_when_empty):
        CrimeCaseActsSections.objects.filter(case=case).delete()
        CrimeCaseActsSections.objects.bulk_create(rows)
    return saved, skipped


# ------------------------------------------------------------------ CCTV, forensics, panchanama

def save_cctv(case, sources, write=True):
    from apps.crimetab.models.common_form import CctvTechnical
    checked = as_bool(first(sources, 'cctv_checked', 'cctvChecked'))
    sent = as_date(first(sources, 'cdr_sent_date', 'cdrSent'))
    received = as_date(first(sources, 'cdr_received_date', 'cdrRecv'))
    if checked is None and not sent and not received:
        return False
    if write:
        CctvTechnical.objects.update_or_create(case=case, defaults={
            'cctv_checked': checked, 'cdr_sent_date': sent, 'cdr_received_date': received,
        })
    return True


def save_forensics(case, sources, write=True):
    from apps.crimetab.models.common_form import CaseForensics
    values = {}
    for column, (tick_keys, date_keys) in FORENSIC_FIELDS.items():
        values[column] = as_bool(first(sources, *tick_keys))
        values[f'{column}_date'] = as_date(first(sources, *date_keys))
    if all(v is None for v in values.values()):
        return False
    if write:
        CaseForensics.objects.update_or_create(case=case, defaults=values)
    return True


def _parse_dt(value):
    from apps.crimetab.views import _parse_dt as parse
    return parse(value)


def save_panchanama(case, sources, write=True):
    """One procedural_checklist row per ticked panchanama; unticked ones are removed."""
    from apps.crimetab.models.common_form import ProceduralChecklist

    # Older shapes, still accepted: a list of {item_name, is_checked, event_datetime},
    # or proceduralChecks {name: bool} with proceduralDates {name: datetime}
    items = first(sources, 'procedural_checklists')
    if isinstance(items, list) and write:
        ProceduralChecklist.objects.filter(case=case).delete()
        for item in items:
            if isinstance(item, dict) and item.get('item_name'):
                ProceduralChecklist.objects.create(
                    case=case, item_name=item['item_name'], is_checked=bool(item.get('is_checked', False)),
                    event_datetime=_parse_dt(item.get('event_datetime')))
        return sum(1 for i in items if isinstance(i, dict) and i.get('is_checked'))
    checks = first(sources, 'proceduralChecks')
    if isinstance(checks, dict) and write:
        dates = first(sources, 'proceduralDates') or {}
        ProceduralChecklist.objects.filter(case=case).delete()
        for name, on in checks.items():
            if on:
                ProceduralChecklist.objects.create(case=case, item_name=name, is_checked=True,
                                                   event_datetime=_parse_dt(dates.get(name)))
        return sum(1 for on in checks.values() if on)

    if not has_any(sources, *PANCHANAMA_ITEMS):
        return 0
    ticked = 0
    for key, item_name in PANCHANAMA_ITEMS.items():
        if not has_any(sources, key):
            continue
        if as_bool(first(sources, key)):
            if write:
                ProceduralChecklist.objects.update_or_create(
                    case=case, item_name=item_name, defaults={'is_checked': True})
            ticked += 1
        elif write:
            ProceduralChecklist.objects.filter(case=case, item_name=item_name).delete()
    return ticked


def save_common_form_tables(case, data=None, extra=None, write=True, keep_charges_when_empty=False):
    """
    Fill all four tables for one case and return what was (or, with write=False,
    would be) written. write=False never touches the database.
    """
    sources = sources_from(data, extra)
    charges_saved, charges_skipped = save_charges(
        case, sources, write=write, keep_when_empty=keep_charges_when_empty)
    return {
        'charges': charges_saved,
        'charges_skipped': charges_skipped,
        'cctv': save_cctv(case, sources, write=write),
        'forensics': save_forensics(case, sources, write=write),
        'panchanama': save_panchanama(case, sources, write=write),
    }
