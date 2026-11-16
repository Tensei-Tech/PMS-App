"""
Service tab answers saved in their own tables (steps B4 - B9).

Sam/Warrant (sam_warrant_records) is the first. The app still sends the
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


def save_service_tab_tables(case, data=None, write=True):
    """Called from the case save; `data` is the request (its extra_fields win over the stored JSON)."""
    extra = (data or {}).get('extra_fields') if isinstance(data, dict) else None
    if not isinstance(extra, dict):
        extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
    return {'sam_warrant': save_sam_warrant(case, extra, write=write) is not None}


def warrant_row(case):
    try:
        return case.sam_warrant
    except Exception:  # RelatedObjectDoesNotExist: not saved yet
        return None


def overlay_service_tabs(extra, case):
    """Lay the table answers over the JSON for the app (the table wins). Changes `extra` in place."""
    row = warrant_row(case) if is_sam_warrant_case(case) else None
    if row is None:
        return extra
    for column in WARRANT_KEYS:
        value = getattr(row, column)
        if value in EMPTY:
            continue
        if isinstance(value, date):
            if _as_date(extra.get(column)) == value:
                continue  # same day: keep the app's own text (ISO date-time)
            value = value.isoformat()
        extra[column] = value
    return extra
