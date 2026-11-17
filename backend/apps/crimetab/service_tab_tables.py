"""
Service tab answers saved in their own tables (steps B4 - B9).

Sam/Warrant (sam_warrant_records), Passport / PVR (passport_pvr_records),
Licence (licence_records) and Tadipar (tadipar_records) so far. The app still sends the
answers inside extra_fields; save_service_tab_tables() copies them into the
table on every save, the case API lays the table back over the JSON for the
app, and the warrant report reads the table first. The backfill command
`backfill_service_tab_tables` copies records saved before this.
"""
import logging
from datetime import date, datetime

from django.utils import timezone

logger = logging.getLogger(__name__)

EMPTY = (None, '', [], {})

# ------------------------------------------------------------------ Sam / Warrant

# table column -> JSON keys, the app's own name first
WARRANT_KEYS = {
    'warrant_type': ('warrant_type', 'warrantType', 'process_type', 'processType'),
    'warrant_number': ('warrant_number', 'warrantNumber'),
    'accused_name': ('accused_name', 'accusedName'),
    'court_name': ('court_name', 'courtName'),
    'issue_date': ('issue_date', 'issueDate'),
    'execution_status': ('execution_status', 'executionStatus', 'service_status', 'warrant_status'),
    'notes': ('notes', 'remarks'),
}


def _first(extra, keys):
    for key in keys:
        value = extra.get(key)
        if value not in EMPTY:
            return value
    return None


def warrant_type_of(value, sub_category=''):
    """'summons' / 'bw' / 'nbw' from the app's code or a label (English or Marathi); None if unclear."""
    for text in (str(value or '').strip().lower(), str(sub_category or '').strip().lower()):
        found = _type_in(text)
        if found:
            return found
    return None


def _type_in(text):
    if not text:
        return None
    if any(k in text for k in ('nbw', 'non-bailable', 'non_bailable', 'non bailable', 'पकड')):
        return 'nbw'
    if any(k in text for k in ('bw', 'bailable', 'जमानती')):
        return 'bw'
    if any(k in text for k in ('summons', 'sam', 'समंस', 'समन्स')):
        return 'summons'
    return None


def execution_status_of(value):
    """'pending' / 'executed' / 'unserved' from the app's code or a label; None if empty."""
    text = str(value or '').strip().lower()
    if not text:
        return None
    if any(k in text for k in ('unserved', 'unexecuted', 'अदम', 'adam', 'returned', 'not served', 'untraceable')):
        return 'unserved'
    if any(k in text for k in ('executed', 'served', 'तामील', 'tamil')):
        return 'executed'
    return 'pending'


def _as_date(value):
    if value in EMPTY:
        return None
    if isinstance(value, datetime):
        return timezone.localtime(value).date() if timezone.is_aware(value) else value.date()
    if isinstance(value, date):
        return value
    text = str(value).strip()
    try:  # the app sends ISO text: 2026-11-05T00:00:00.000
        parsed = datetime.fromisoformat(text.replace('Z', '+00:00'))
        return timezone.localtime(parsed).date() if timezone.is_aware(parsed) else parsed.date()
    except ValueError:
        pass
    for fmt in ('%d/%m/%Y', '%d-%m-%Y', '%Y/%m/%d'):
        try:
            return datetime.strptime(text[:10], fmt).date()
        except ValueError:
            continue
    return None


def _as_datetime(value):
    if value in EMPTY:
        return None
    if isinstance(value, datetime):
        parsed = value
    else:
        try:
            parsed = datetime.fromisoformat(str(value).strip().replace('Z', '+00:00'))
        except ValueError:
            return None
    return parsed if timezone.is_aware(parsed) else timezone.make_aware(parsed)


def is_sam_warrant_case(case):
    return (case.module_key or '').strip().lower() == 'sam_warrant'


def warrant_values(case, extra=None):
    """The table columns for one Sam/Warrant record, from its JSON answers."""
    extra = extra if isinstance(extra, dict) else (case.extra_fields if isinstance(case.extra_fields, dict) else {})
    text = lambda col, size: (str(_first(extra, WARRANT_KEYS[col])).strip()[:size]  # noqa: E731
                              if _first(extra, WARRANT_KEYS[col]) is not None else None)
    return {
        'warrant_type': warrant_type_of(_first(extra, WARRANT_KEYS['warrant_type']), case.sub_category),
        'warrant_number': text('warrant_number', 100) or (case.case_number or '')[:100] or None,
        'accused_name': text('accused_name', 255) or (case.accused or '')[:255] or None,
        'court_name': text('court_name', 255),
        'issue_date': _as_date(_first(extra, WARRANT_KEYS['issue_date'])),
        'execution_status': execution_status_of(_first(extra, WARRANT_KEYS['execution_status'])),
        'notes': text('notes', 100000),
    }


def save_sam_warrant(case, extra=None, write=True):
    """Write the record's row; returns the values (None when the case is not a Sam/Warrant record)."""
    from apps.crimetab.models.service_tabs import SamWarrantRecord
    if not is_sam_warrant_case(case):
        return None
    values = warrant_values(case, extra)
    if write:
        SamWarrantRecord.objects.update_or_create(case=case, defaults={**values, 'updated_at': timezone.now()})
    return values


# ------------------------------------------------------------------ Passport / PVR

PASSPORT_PVR_MODULES = ('passport', 'pvr')

# table column -> JSON keys. Today each record is one batch of the day (counts);
# the applicant fields come from older single-applicant records.
PASSPORT_TEXT = {
    'file_number': (('file_number', 'fileNumber'), 100),
    'verification_status': (('verification_status', 'verificationStatus'), 50),
    'applicant_name': (('applicant_name', 'applicantName'), 255),
    'applicant_phone': (('applicant_phone', 'applicantPhone'), 20),
    'applicant_address': (('applicant_address', 'applicantAddress'), 100000),
    'verification_outcome': (('verification_outcome', 'verificationOutcome'), 100),
    'remarks': (('remarks', 'notes'), 100000),
}
PASSPORT_COUNTS = {
    'total_count': ('total_count', 'totalCount'),
    'verified_count': ('verified_count', 'verifiedCount'),
    'pending_count': ('pending_count', 'pendingCount'),
}
PASSPORT_DATES = {'verification_date': ('verification_date', 'verificationDate')}


def _count(value):
    try:
        number = int(float(str(value).strip()))
    except (TypeError, ValueError):
        return None
    return number if 0 <= number < 1_000_000 else None


def is_passport_pvr_case(case):
    return (case.module_key or '').strip().lower() in PASSPORT_PVR_MODULES


def passport_pvr_values(case, extra=None):
    extra = extra if isinstance(extra, dict) else (case.extra_fields if isinstance(case.extra_fields, dict) else {})
    values = {'kind': (case.module_key or '').strip().lower()}
    for column, (keys, size) in PASSPORT_TEXT.items():
        value = _first(extra, keys)
        values[column] = str(value).strip()[:size] if value is not None else None
    values['file_number'] = values['file_number'] or (case.case_number or '')[:100] or None
    for column, keys in PASSPORT_COUNTS.items():
        values[column] = _count(_first(extra, keys))
    for column, keys in PASSPORT_DATES.items():
        values[column] = _as_date(_first(extra, keys))
    return values


def save_passport_pvr(case, extra=None, write=True):
    from apps.crimetab.models.service_tabs import PassportPvrRecord
    if not is_passport_pvr_case(case):
        return None
    values = passport_pvr_values(case, extra)
    if write:
        PassportPvrRecord.objects.update_or_create(case=case, defaults={**values, 'updated_at': timezone.now()})
    return values


# ------------------------------------------------------------------ Licence

LICENCE_MODULES = ('licence', 'license', 'arms_licence', 'arms_license')

# table column -> (JSON keys, size)
LICENCE_TEXT = {
    'licence_number': (('licence_number', 'license_number', 'licenceNumber'), 100),
    'licence_type': (('licence_type', 'license_type', 'licenceType'), 255),
    'base_licence_type': (('base_licence_type', 'baseLicenceType'), 255),
    'other_noc_type': (('other_noc_type', 'otherNocType'), 255),
    'applicant_name': (('applicant_name', 'applicantName'), 255),
    'business_name': (('business_name', 'businessName'), 255),
    'licence_status': (('licence_status', 'license_status', 'licenceStatus'), 20),
    'remarks': (('remarks', 'notes'), 100000),
}
LICENCE_DATES = {'received_date': ('received_date', 'receivedDate')}
LICENCE_DATETIMES = {'status_updated_at': ('status_updated_at', 'statusUpdatedAt')}


def is_licence_case(case):
    return (case.module_key or '').strip().lower() in LICENCE_MODULES


def licence_values(case, extra=None):
    extra = extra if isinstance(extra, dict) else (case.extra_fields if isinstance(case.extra_fields, dict) else {})
    values = {}
    for column, (keys, size) in LICENCE_TEXT.items():
        value = _first(extra, keys)
        values[column] = str(value).strip()[:size] if value is not None else None
    values['licence_number'] = values['licence_number'] or (case.case_number or '')[:100] or None
    for column, keys in LICENCE_DATES.items():
        values[column] = _as_date(_first(extra, keys))
    for column, keys in LICENCE_DATETIMES.items():
        values[column] = _as_datetime(_first(extra, keys))
    return values


def save_licence(case, extra=None, write=True):
    from apps.crimetab.models.service_tabs import LicenceRecord
    if not is_licence_case(case):
        return None
    values = licence_values(case, extra)
    if write:
        LicenceRecord.objects.update_or_create(case=case, defaults={**values, 'updated_at': timezone.now()})
    return values


# ------------------------------------------------------------------ Tadipar

TADIPAR_MODULES = ('tadipar',)

# table column -> (form keys, size). The app shows Act / Section / Subsection and the
# Crime Chart as text boxes, so they are kept as the text typed.
TADIPAR_TEXT = {
    'externed_name': (('externed_name', 'externedName', 'name'), 255),
    'alias': (('alias',), 255),
    'nickname': (('nickname',), 255),
    'gender': (('gender',), 20),
    'mo_no': (('mo_no', 'mobile_no', 'mobile'), 15),
    'address': (('address',), 100000),
    'order_number': (('order_number', 'orderNumber'), 100),
    'act_id': (('act_id',), 255),
    'section_id': (('section_id',), 255),
    'subsection_id': (('subsection_id',), 255),
    'act_section': (('act_section',), 100000),
    'current_address': (('current_address', 'currentAddress'), 100000),
    'prohibited_areas': (('prohibited_areas',), 255),
    'crime_chart_entries': (('crime_chart_entries',), 100000),
}
TADIPAR_NUMBERS = {'sr_no': ('sr_no', 'srNo'), 'age': ('age',)}
TADIPAR_DATES = {
    'order_date': ('order_date', 'orderDate'),
    'period_from': ('period_from', 'periodFrom'),
    'period_to': ('period_to', 'periodTo'),
    'revoked_date': ('revoked_date', 'revokedDate'),
}


def is_tadipar_case(case):
    return (case.module_key or '').strip().lower() in TADIPAR_MODULES


def _text_of(value):
    if value in EMPTY:
        return None
    if isinstance(value, (list, tuple)):
        return ', '.join(str(v).strip() for v in value if v not in EMPTY) or None
    if isinstance(value, dict):
        return None
    return str(value).strip() or None


def tadipar_values(case, extra=None):
    """Answers from the request / JSON top level first, then the dynamic form copies."""
    extra = extra if isinstance(extra, dict) else (case.extra_fields if isinstance(case.extra_fields, dict) else {})
    sources = [extra] + [extra[n] for n in NESTED_COPIES if isinstance(extra.get(n), dict)]

    def pick(keys):
        for src in sources:
            value = _first(src, keys)
            if value is not None:
                return value
        return None

    values = {}
    for column, (keys, size) in TADIPAR_TEXT.items():
        raw = pick(keys)
        if isinstance(raw, (list, dict)) and column == 'crime_chart_entries':
            values[column] = None
            continue
        text = _text_of(raw)
        values[column] = text[:size] if text else None
    for column, keys in TADIPAR_NUMBERS.items():
        values[column] = _count(pick(keys))
    if values['age'] is not None and not 0 < values['age'] < 130:
        values['age'] = None
    for column, keys in TADIPAR_DATES.items():
        values[column] = _as_date(pick(keys))
    return values


CHART_KEY = 'crime_chart_entries'


def _chart_answer(extra):
    """The Crime Chart answer: (found, value), top level first, then the dynamic form copies."""
    for src in [extra] + [extra[n] for n in NESTED_COPIES if isinstance(extra.get(n), dict)]:
        if CHART_KEY in src and src[CHART_KEY] not in (None, ''):
            return True, src[CHART_KEY]
    return False, None


def _id(value):
    number = _count(value)
    return number if number else None


def chart_rows(case, rows):
    """Unsaved TadiparCrimeChartEntry rows from the app's list; Act / Section names are copied
    so a row stays readable if the Acts master is imported again."""
    from apps.crimetab.models.common_form import Act, ActSection
    from apps.crimetab.models.service_tabs import TadiparCrimeChartEntry
    from apps.stations.models import PoliceStation
    clean = [r for r in rows if isinstance(r, dict) and any(v not in EMPTY for v in r.values())]
    act_ids = {_id(r.get('act_id')) for r in clean} - {None}
    section_ids = {_id(r.get('section_id')) for r in clean} - {None}
    station_ids = {_id(r.get('police_station_id')) for r in clean} - {None}
    acts = dict(Act.objects.filter(act_id__in=act_ids).values_list('act_id', 'act_name')) if act_ids else {}
    sections = (dict(ActSection.objects.filter(section_id__in=section_ids).values_list('section_id', 'section_number'))
                if section_ids else {})
    stations = {}
    if station_ids:
        try:
            stations = dict(PoliceStation.objects.filter(pk__in=station_ids).values_list('pk', 'station_name'))
        except Exception:  # stations table not reachable here: names stay empty
            stations = {}
    out = []
    for row_no, r in enumerate(clean):
        act, section, station = _id(r.get('act_id')), _id(r.get('section_id')), _id(r.get('police_station_id'))
        out.append(TadiparCrimeChartEntry(
            record_id=case.pk, row_no=row_no,
            cr_number=_text_of(r.get('cr_number'))[:100] if _text_of(r.get('cr_number')) else None,
            crime_head=_text_of(r.get('crime_head')),
            act_id=act, act_name=acts.get(act), section_id=section, section_number=sections.get(section),
            register_date=_as_date(r.get('register_date')),
            police_station_id=station, police_station_name=stations.get(station),
        ))
    return out


def save_tadipar(case, extra=None, write=True):
    from apps.crimetab.models.service_tabs import TadiparCrimeChartEntry, TadiparRecord
    if not is_tadipar_case(case):
        return None
    extra = extra if isinstance(extra, dict) else (case.extra_fields if isinstance(case.extra_fields, dict) else {})
    values = tadipar_values(case, extra)
    found, chart = _chart_answer(extra)
    if isinstance(chart, list):
        values[CHART_KEY] = None  # rows go to their own table; the column keeps typed text only
    if write:
        TadiparRecord.objects.update_or_create(case=case, defaults={**values, 'updated_at': timezone.now()})
        if isinstance(chart, list):
            TadiparCrimeChartEntry.objects.filter(record_id=case.pk).delete()
            TadiparCrimeChartEntry.objects.bulk_create(chart_rows(case, chart))
    return values


# ------------------------------------------------------------------ all service tabs

# tab -> (is it this tab, save, related name, JSON keys laid back for the app)
TABS = {
    'sam_warrant': (is_sam_warrant_case, save_sam_warrant, 'sam_warrant', tuple(WARRANT_KEYS)),
    'passport_pvr': (is_passport_pvr_case, save_passport_pvr, 'passport_pvr',
                     tuple(PASSPORT_TEXT) + tuple(PASSPORT_COUNTS) + tuple(PASSPORT_DATES)),
    'licence': (is_licence_case, save_licence, 'licence',
                tuple(LICENCE_TEXT) + tuple(LICENCE_DATES) + tuple(LICENCE_DATETIMES)),
    'tadipar': (is_tadipar_case, save_tadipar, 'tadipar',
                tuple(TADIPAR_TEXT) + tuple(TADIPAR_NUMBERS) + tuple(TADIPAR_DATES)),
}

# related name -> date format the tab writes in its JSON (default: ISO)
DATE_FORMATS = {'tadipar': '%d/%m/%Y'}


def save_service_tab_tables(case, data=None, write=True):
    """Called from the case save; `data` is the request (its extra_fields win over the stored JSON)."""
    extra = (data or {}).get('extra_fields') if isinstance(data, dict) else None
    if not isinstance(extra, dict):
        extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
    return {tab: save(case, extra, write=write) is not None for tab, (_is, save, _rel, _keys) in TABS.items()}


def _row(case, related_name):
    try:
        return getattr(case, related_name)
    except Exception:  # RelatedObjectDoesNotExist: not saved yet
        return None


def warrant_row(case):
    return _row(case, 'sam_warrant')


# JSON containers the dynamic form also copies its answers into
NESTED_COPIES = ('extra_field_values', 'dynamic_extra_fields')


def _shaped(value, current, date_format):
    """A table value written the way the JSON holds it; None when the JSON already says the same."""
    if isinstance(value, datetime):
        if _as_datetime(current) == value:
            return None  # same moment: keep the app's own text
        return timezone.localtime(value).isoformat()
    if isinstance(value, date):
        if _as_date(current) == value:
            return None  # same day: keep the app's own text
        if '/' in str(current or '') or (current in EMPTY and date_format):
            return value.strftime(date_format or '%d/%m/%Y')
        return value.isoformat()
    if isinstance(value, int) and not isinstance(value, bool) and isinstance(current, str):
        return None if current.strip() == str(value) else str(value)  # numbers the app keeps as text
    if isinstance(value, str) and isinstance(current, int) and not isinstance(current, bool):
        return None if value.strip() == str(current) else value  # an id the app sends as a number
    return None if current == value else value


def lay_row_over(extra, row, keys, date_format=None):
    """The row answers over the JSON (the table wins), also inside the dynamic form copies
    for answers they already hold. Changes `extra` in place."""
    targets = [extra] + [extra[n] for n in NESTED_COPIES if isinstance(extra.get(n), dict)]
    for column in keys:
        value = getattr(row, column)
        if value in EMPTY:
            continue
        for target in targets:
            if target is not extra and column not in target:
                continue
            shaped = _shaped(value, target.get(column), date_format)
            if shaped is not None:
                target[column] = shaped
    return extra


def chart_answer_from_rows(entries):
    """The Crime Chart as the app sends it: a list of row dicts, dates dd/mm/yyyy, ids as numbers."""
    out = []
    for e in sorted(entries, key=lambda x: x.row_no):
        row = {'cr_number': e.cr_number, 'crime_head': e.crime_head, 'act_id': e.act_id,
               'section_id': e.section_id,
               'register_date': e.register_date.strftime('%d/%m/%Y') if e.register_date else None,
               'police_station_id': e.police_station_id}
        out.append({k: v for k, v in row.items() if v not in EMPTY})
    return out


def _lay_chart_over(extra, record):
    entries = list(record.crime_chart.all())
    if not entries:
        return
    answer = chart_answer_from_rows(entries)
    for target in [extra] + [extra[n] for n in NESTED_COPIES if isinstance(extra.get(n), dict)]:
        if target is extra or CHART_KEY in target:
            target[CHART_KEY] = answer


def overlay_service_tabs(extra, case, row=None):
    """For one case (detail API); `row` saves the query when the caller already has it."""
    for is_tab, _save, related_name, keys in TABS.values():
        if is_tab(case):
            row = row if row is not None else _row(case, related_name)
            if row is not None:
                lay_row_over(extra, row, keys, DATE_FORMATS.get(related_name))
                if related_name == 'tadipar':
                    _lay_chart_over(extra, row)
            break
    return extra


def service_rows_by_case(records):
    """{case id: row} for a page of cases, one query per tab (case list API)."""
    from apps.crimetab.models.service_tabs import (
        LicenceRecord, PassportPvrRecord, SamWarrantRecord, TadiparRecord)
    models = {'sam_warrant': SamWarrantRecord, 'passport_pvr': PassportPvrRecord, 'licence': LicenceRecord,
              'tadipar': TadiparRecord}
    rows = {}
    for tab, (is_tab, _save, _rel, _keys) in TABS.items():
        ids = [r.pk for r in records if is_tab(r)]
        if ids:
            qs = models[tab].objects.filter(case_id__in=ids)
            if tab == 'tadipar':
                qs = qs.prefetch_related('crime_chart')
            rows.update({row.case_id: row for row in qs})
    return rows
