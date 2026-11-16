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
    crime_spot                 village / town, area, address, occurrence date-time
    crime_registration_info    registration date-time
    final_verdict              charge sheet, CC/ST and final numbers, High Court dates
    cases_person               the complainant and the accused (added or filled in, never deleted)

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
        for key in ('cctv_technical', 'forensics', 'case_forensics', 'investigationNotes', 'crime_spot',
                    'final_verdict', 'court_filing', 'courtFiling'):
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
    people_added, people_updated = save_people(case, sources, write=write)
    return {
        'charges': charges_saved,
        'charges_skipped': charges_skipped,
        'crime_spot': save_crime_spot(case, sources, write=write),
        'registration': save_registration(case, sources, write=write),
        'final_verdict': save_final_verdict(case, sources, write=write),
        'people_added': people_added,
        'people_updated': people_updated,
        'cctv': save_cctv(case, sources, write=write),
        'forensics': save_forensics(case, sources, write=write),
        'panchanama': save_panchanama(case, sources, write=write),
    }


# ------------------------------------------------------------------ place, complainant, accused

def _parse_dt_value(value):
    from apps.crimetab.views import _parse_dt as parse
    return parse(value) if value not in EMPTY else None


# final_verdict column -> form keys (flat key first, then older names)
FINAL_VERDICT_TEXT = {
    'charge_sheet_no': ('charge_sheet_no', 'chargeSheetNumber'),
    'cc_st_number': ('cc_st_number', 'ccStNumber', 'ccStNo'),
    'a_final_number': ('a_final_number', 'aFinalNo', 'aFinalNumber'),
    'b_final_number': ('b_final_number', 'bFinalNo', 'bFinalNumber'),
    'c_final_number': ('c_final_number', 'cFinalNo', 'cFinalNumber'),
    'nc_final_number': ('nc_final_number', 'ncFinalNo', 'ncFinalNumber'),
    'abeted_summary_no': ('abeted_summary_no', 'abatedSummaryNo', 'abetedSummaryNumber'),
}
FINAL_VERDICT_DATES = {
    'stay_by_high_court_date': ('stay_by_high_court_date', 'stayHighCourtDate'),
    'quashed_by_high_court_date': ('quashed_by_high_court_date', 'quashedHighCourt'),
}


def save_final_verdict(case, sources, write=True):
    """final_verdict (charge sheet, CC/ST, A/B/C/NC final, abated summary, High Court dates)."""
    from apps.crimetab.models.common_form import FinalVerdict
    values = {}
    for column, keys in FINAL_VERDICT_TEXT.items():
        value = first(sources, *keys)
        values[column] = str(value).strip()[:50] if value not in EMPTY else None
    for column, keys in FINAL_VERDICT_DATES.items():
        values[column] = as_date(first(sources, *keys))
    if all(v in EMPTY for v in values.values()):
        return False
    if write:
        FinalVerdict.objects.update_or_create(case=case, defaults=values)
    return True


def save_registration(case, sources, write=True):
    """crime_registration_info.registered_datetime from the form's own field."""
    from apps.crimetab.models.common_form import CrimeRegistrationInfo
    dt = _parse_dt_value(first(sources, 'registered_datetime', 'regDate'))
    if dt is None:
        return False
    if write:
        updated = CrimeRegistrationInfo.objects.filter(case=case).update(registered_datetime=dt)
        if not updated:
            CrimeRegistrationInfo.objects.create(case=case, cr_number=(case.case_number or '')[:30] or None,
                                                 registered_datetime=dt)
    return True


def save_crime_spot(case, sources, write=True):
    """crime_spot from the flat keys the app sends (older names still accepted)."""
    from apps.crimetab.models.common_form import CrimeSpot
    values = {
        'village_town': first(sources, 'village_town', 'spotVillage'),
        'area_name': first(sources, 'area_name', 'spotArea'),
        'full_address': first(sources, 'full_address', 'spotAddress', 'location'),
        'occurrence_datetime': _parse_dt_value(
            first(sources, 'occurrence_datetime', 'occurrenceDateTime', 'incident_date')),
    }
    if all(v in EMPTY for v in values.values()):
        return False
    for key in ('village_town', 'area_name'):
        if values[key] is not None:
            values[key] = str(values[key]).strip()[:255]
    if write:
        CrimeSpot.objects.update_or_create(case=case, defaults=values)
    return True


def _digits(value):
    return ''.join(ch for ch in str(value or '') if ch.isdigit())


def clean_person(raw):
    """A person dict from the form, cut to what cases_person can hold; None without a name."""
    def get(*keys):
        for key in keys:
            value = raw.get(key)
            if value not in EMPTY:
                return value
        return None

    name = str(get('name', 'accusedName', 'person_name') or '').strip()
    if not name:
        return None
    age = _digits(get('age'))
    mobile = _digits(get('mobile', 'mobile_no', 'mobile_number'))
    aadhaar = _digits(get('aadhaar', 'aadhar', 'aadhaar_number', 'aadhar_number', 'aadhaar_no'))
    pan = ''.join(str(get('pan', 'pan_number', 'pan_no') or '').split()).upper()

    def text(value, limit):
        return str(value).strip()[:limit] if value not in EMPTY else None

    return {
        'name': name[:150],
        'age': int(age) if age and 0 < int(age) < 1000 else None,
        'gender': text(get('gender'), 10),
        'occupation': text(get('occupation', 'occ'), 100),
        'mobile': mobile if len(mobile) == 10 else None,
        'aadhaar': aadhaar if len(aadhaar) == 12 else None,
        'pan': pan if len(pan) == 10 and pan.isalnum() else None,
        'religion': text(get('religion'), 50),
        'caste': text(get('caste', 'cast'), 50),
        'address': text(get('address'), 10000),
    }


def _flat_person(sources, prefix):
    """complainant_name, complainant_age, ... -> one person dict."""
    fields = ('name', 'age', 'gender', 'occupation', 'mobile', 'aadhaar', 'pan', 'religion', 'caste', 'address')
    return {f: first(sources, f'{prefix}_{f}') for f in fields}


def people_from(sources):
    """[(role, person), ...] for the complainant and the accused named in the form."""
    found = []
    complainant = clean_person(_flat_person(sources, 'complainant'))
    if not complainant:
        nested = first(sources, 'complainant')
        complainant = clean_person(nested) if isinstance(nested, dict) else None
    if complainant:
        found.append(('complainant', complainant))

    accused = []
    for key in ('accused', 'accused_list', 'accusedDetails'):
        # The request's own `accused` is the case's plain-text field; take the
        # first source where the key holds a non-empty list of people
        value = next((s[key] for s in sources if isinstance(s.get(key), list) and s[key]), [])
        accused += [clean_person(a) for a in value if isinstance(a, dict)]
    single = clean_person(_flat_person(sources, 'accused'))
    if single:
        accused.append(single)
    seen = set()
    for person in accused:
        if person and person['name'].lower() not in seen:
            seen.add(person['name'].lower())
            found.append(('accused', person))
    return found


def save_people(case, sources, write=True):
    """
    Add the complainant and accused to cases_person, or fill in details of a person
    already saved with the same name and role. Nobody is deleted here: arrests,
    remand and seizures point at these rows.
    """
    from apps.crimetab.models.common_form import CasesPerson
    added = updated = 0
    for role, person in people_from(sources):
        existing = CasesPerson.objects.filter(case=case, role=role, name__iexact=person['name']).first()
        if existing:
            changes = {k: v for k, v in person.items() if v is not None and getattr(existing, k) in (None, '')}
            if changes:
                updated += 1
                if write:
                    CasesPerson.objects.filter(pk=existing.pk).update(**changes)
        else:
            added += 1
            if write:
                CasesPerson.objects.create(case=case, role=role, **person)
    return added, updated


# ------------------------------------------------------------------ reading back for the form
#
# The case API and the case PDF fill the Common Form from these tables, so the
# JSON copy is no longer the source (a step towards removing the commonForm copy).
# Values come out in the shapes the app saves: ticks as true / false, dates as
# dd/mm/yyyy, date-times as "dd/mm/yyyy HH:MM" in India time, and charges as
# [{act, act_id, section, section_id, ...}] holding ids.

PERSON_FIELDS = ('name', 'age', 'gender', 'occupation', 'mobile', 'aadhaar', 'pan', 'religion', 'caste',
                 'address', 'medical')


def _one(case, attr):
    try:
        return getattr(case, attr)
    except Exception:  # RelatedObjectDoesNotExist: no row for this case
        return None


def _fmt_date(value):
    return value.strftime('%d/%m/%Y') if value else None


def _fmt_dt(value):
    if not value:
        return None
    from django.utils import timezone
    if timezone.is_aware(value):
        value = timezone.localtime(value)
    return value.strftime('%d/%m/%Y %H:%M')


def _person_dict(p):
    out = {f: getattr(p, f, None) for f in PERSON_FIELDS}
    out['age'] = str(out['age']) if out['age'] is not None else None
    out['role'] = p.role
    return {k: v for k, v in out.items() if v not in EMPTY}


def common_form_values(case):
    """
    The Common Form answers held in the tables, as {form key: value}. Keys with
    nothing in the tables are left out, so the JSON value (if any) still shows.
    """
    values = {}

    reg = _one(case, 'registration_info')
    if reg is not None:
        values['registered_datetime'] = _fmt_dt(reg.registered_datetime)

    spot = _one(case, 'spot')
    if spot is not None:
        values.update({'village_town': spot.village_town, 'area_name': spot.area_name,
                       'full_address': spot.full_address,
                       'occurrence_datetime': _fmt_dt(spot.occurrence_datetime)})

    cctv = _one(case, 'cctv_technical')
    if cctv is not None:
        values.update({'cctv_checked': cctv.cctv_checked, 'cdr_sent_date': _fmt_date(cctv.cdr_sent_date),
                       'cdr_received_date': _fmt_date(cctv.cdr_received_date)})

    forensics = _one(case, 'forensics')
    if forensics is not None:
        for column in FORENSIC_FIELDS:
            values[column] = getattr(forensics, column)
            values[f'{column}_date'] = _fmt_date(getattr(forensics, f'{column}_date'))

    ticked = {row.item_name for row in case.procedural_checklists.all() if row.is_checked}
    if ticked:  # unticked items have no row; with no row at all the JSON answers stay
        for key, item_name in PANCHANAMA_ITEMS.items():
            values[key] = item_name in ticked

    verdict = _one(case, 'final_verdict')
    if verdict is not None:
        for column in FINAL_VERDICT_TEXT:
            values[column] = getattr(verdict, column)
        for column in FINAL_VERDICT_DATES:
            values[column] = _fmt_date(getattr(verdict, column))

    persons = list(case.persons.all())
    complainant = next((p for p in persons if p.role == 'complainant'), None)
    if complainant is not None:
        for field, value in _person_dict(complainant).items():
            if field != 'role':
                values[f'complainant_{field}'] = value
    accused = [_person_dict(p) for p in persons if p.role == 'accused' and p.name]
    if accused:
        values['accused'] = accused

    charges = []
    for ch in case.charges.select_related('act', 'section', 'subsection').all():
        sub = ch.subsection
        charges.append({
            'act': ch.act_id, 'act_id': ch.act_id, 'act_name': ch.act.act_name if ch.act_id else None,
            'section': ch.section_id, 'section_id': ch.section_id,
            'section_number': ch.section.section_number if ch.section_id else None,
            'section_title': ch.section.section_title if ch.section_id else None,
            'subsection': sub.pk if sub else None, 'subsection_id': sub.pk if sub else None,
            'subsection_code': sub.subsection_code if sub else None,
        })
    if charges:
        values['charges'] = charges

    return {k: v for k, v in values.items() if v not in EMPTY}


def _same_text(table_value, json_value):
    """Same answer; a table text cut to its column size still matches the longer JSON text."""
    a, b = str(table_value).strip(), str(json_value).strip()
    return a == b or (len(a) >= 50 and b.startswith(a))


def _merge_charges(table_charges, json_charges):
    """Table charges, keeping the act name the app saved for the same section (e.g. "BNS")."""
    saved = {}
    for ch in json_charges if isinstance(json_charges, list) else []:
        if isinstance(ch, dict) and ch.get('section_id') and ch.get('act_name'):
            saved[str(ch['section_id'])] = ch['act_name']
    return [dict(ch, act_name=saved.get(str(ch['section_id']), ch['act_name'])) for ch in table_charges]


def _merge_accused(table_people, json_people):
    """
    The accused from the JSON list, each field it leaves empty filled from the
    table; people only in the table are added. Fields with no table column
    (medical date, ...) are kept from the JSON.
    """
    by_name = {p['name'].strip().lower(): p for p in table_people}
    merged, used = [], set()
    for person in json_people if isinstance(json_people, list) else []:
        if not isinstance(person, dict):
            continue
        key = str(person.get('name') or '').strip().lower()
        table = by_name.get(key)
        if table is None:
            merged.append(person)
            continue
        used.add(key)
        merged.append({**person, **{k: v for k, v in table.items() if k != 'role' and person.get(k) in EMPTY}})
    merged += [p for k, p in by_name.items() if k not in used]
    return merged


def overlay_common_form(extra, case):
    """
    Lay the table values over the case JSON (top level and, when present, the
    commonForm copy) for the form and the PDF. The table wins; keys and list
    fields the tables cannot hold stay as they are. Changes `extra` in place.
    """
    table = common_form_values(case)
    if not table:
        return extra
    # With these left blank, the save code put the case's incident date into the
    # tables; that guess must not show in the form as if it had been entered
    guesses = set()
    if isinstance(case.incident_date, datetime):
        guesses |= {_fmt_dt(case.incident_date), _fmt_dt(case.incident_date)[:10] + ' 00:00'}
    for key in ('incident_date', 'incidentDate', 'incident_datetime'):
        if extra.get(key) not in EMPTY:
            text = str(extra[key]).strip()
            guesses |= {text, text[:10] + ' 00:00'}
    targets = [extra]
    if isinstance(extra.get('commonForm'), dict):
        targets.append(extra['commonForm'])
    for target in targets:
        for key, value in table.items():
            current = target.get(key)
            if key == 'charges':
                target[key] = _merge_charges(value, current)
            elif key == 'accused':
                target[key] = _merge_accused(value, current)
            elif current in EMPTY and (value is False or (
                    key in GUESSED_TIMES and value in guesses
                    and first(sources_from(extra=extra), *GUESSED_TIMES[key]) in EMPTY)):
                continue  # nothing to add: an unticked box, or the incident-date guess
            elif isinstance(value, str) and current not in EMPTY and (
                    _same_text(value, current) or value == f'{str(current).strip()} 00:00'):
                continue  # same answer: keep the app's own spelling, full length, date only
            else:
                target[key] = value
    return extra


# form key -> every name the app has used for it
GUESSED_TIMES = {
    'registered_datetime': ('registered_datetime', 'regDate'),
    'occurrence_datetime': ('occurrence_datetime', 'occurrenceDateTime'),
}
