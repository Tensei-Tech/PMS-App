"""
Service tab answers saved in their own tables (steps B4 - B9).

Sam/Warrant (sam_warrant_records) and Passport / PVR (passport_pvr_records)
so far. The app still sends the
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


# ------------------------------------------------------------------ all service tabs

# tab -> (is it this tab, save, related name, JSON keys laid back for the app)
TABS = {
    'sam_warrant': (is_sam_warrant_case, save_sam_warrant, 'sam_warrant', tuple(WARRANT_KEYS)),
    'passport_pvr': (is_passport_pvr_case, save_passport_pvr, 'passport_pvr',
                     tuple(PASSPORT_TEXT) + tuple(PASSPORT_COUNTS) + tuple(PASSPORT_DATES)),
}


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


def lay_row_over(extra, row, keys):
    """The row answers over the JSON (the table wins). Changes `extra` in place."""
    for column in keys:
        value = getattr(row, column)
        if value in EMPTY:
            continue
        if isinstance(value, date):
            if _as_date(extra.get(column)) == value:
                continue  # same day: keep the app's own text (ISO date-time)
            value = value.isoformat()
        extra[column] = value
    return extra


def overlay_service_tabs(extra, case, row=None):
    """For one case (detail API); `row` saves the query when the caller already has it."""
    for is_tab, _save, related_name, keys in TABS.values():
        if is_tab(case):
            row = row if row is not None else _row(case, related_name)
            if row is not None:
                lay_row_over(extra, row, keys)
            break
    return extra


def service_rows_by_case(records):
    """{case id: row} for a page of cases, one query per tab (case list API)."""
    from apps.crimetab.models.service_tabs import PassportPvrRecord, SamWarrantRecord
    models = {'sam_warrant': SamWarrantRecord, 'passport_pvr': PassportPvrRecord}
    rows = {}
    for tab, (is_tab, _save, _rel, _keys) in TABS.items():
        ids = [r.pk for r in records if is_tab(r)]
        if ids:
            rows.update({row.case_id: row for row in models[tab].objects.filter(case_id__in=ids)})
    return rows
