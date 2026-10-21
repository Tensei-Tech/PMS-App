"""
A.D. (Accidental Death) module service.

- Cases: <state schema>.cases_caserecord rows with module_key 'ad'; the sub-tab
  (Suicide / Other ...) is sub_category = the child category's name. Answers are
  the form's field keys in extra_fields. Status (Pending / Disposal) is set by
  CaseRecord.save() (apps.cases.models.is_ad_case_disposed).
- Form: the field template named by module_settings ad.template_name.
- Sub-tabs: active child categories of ad.target_category_code.
- Every label, message and the list card layout come from module_settings 'ad'.
"""
import logging
import re

from apps.crimetab.models import CaseCategory, FieldTemplateField, ModuleSetting

logger = logging.getLogger(__name__)

MODULE_KEY = 'ad'
STATUS_DISPOSAL = 'Disposal'
# Panchanama checkboxes keep their date and time under '<field_key>_date'
CHECKBOX_DATE_SUFFIX = '_date'


class AdValidationError(Exception):
    pass


class AdSettings:
    """All module_settings for 'ad' (plus 'common' fallbacks) loaded in ONE query."""

    def __init__(self):
        rows = ModuleSetting.objects.filter(module_key__in=[MODULE_KEY, 'common']).values_list(
            'module_key', 'setting_key', 'setting_value'
        )
        common, own = {}, {}
        for mk, key, val in rows:
            (own if mk == MODULE_KEY else common)[key] = val
        self._map = {**common, **own}

    def text(self, key, **fmt):
        val = self._map.get(key)
        if val is None:
            logger.warning("[AD] module_settings missing: ad.%s", key)
            return ''
        val = str(val)
        if fmt:
            try:
                return val.format(**fmt)
            except (KeyError, IndexError, ValueError):
                return val
        return val

    def int(self, key):
        raw = self._map.get(key)
        try:
            return int(str(raw).strip())
        except (TypeError, ValueError):
            logger.warning("[AD] module_settings missing or not an integer: ad.%s", key)
            return None

    def raw(self, key):
        return self._map.get(key)


# ── Sub-tabs and form definition ─────────────────────────────────────────────
def sub_categories(settings):
    """[{'code', 'name', 'id'}] of the A.D. tab's active children, in display order."""
    parent_code = settings.raw('target_category_code')
    if not parent_code:
        return []
    rows = (CaseCategory.objects
            .filter(parent_category__category_code=parent_code, is_active=True)
            .order_by('display_order', 'category_id')
            .values('category_code', 'category_name', 'category_id'))
    return [{'code': r['category_code'], 'name': r['category_name'], 'id': r['category_id']}
            for r in rows if r['category_code']]


def find_sub_category(settings, code):
    code = str(code or '').strip().upper()
    for c in sub_categories(settings):
        if c['code'].upper() == code:
            return c
    return None


def load_field_defs(settings):
    """A.D. template fields, ordered (ONE query)."""
    tmpl_name = settings.raw('template_name')
    if not tmpl_name:
        logger.warning("[AD] module_settings missing: ad.template_name")
        return []
    return list(
        FieldTemplateField.objects.filter(template__template_name=tmpl_name)
        .order_by('display_order', 'pk')
    )


# ── Values ───────────────────────────────────────────────────────────────────
def _blank(v):
    return v is None or (isinstance(v, str) and not v.strip()) or v == [] or v == {}


def _clean_str(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _is_ticked(v):
    if isinstance(v, bool):
        return v
    return str(v or '').strip().lower() in ('true', '1', 'yes')


def _as_list(v):
    if isinstance(v, (list, tuple)):
        return [str(x).strip() for x in v if str(x).strip()]
    s = str(v or '').strip()
    if s.startswith('[') and s.endswith(']'):
        s = s[1:-1]
    return [p.strip() for p in s.split(',') if p.strip()]


def _check_mobile(value, settings):
    s = _clean_str(value)
    if s is None:
        return None
    if not re.fullmatch(r'\d{10}', s):
        raise AdValidationError(settings.text('invalid_mobile_message', value=s))
    return s


def _check_aadhaar(value, settings):
    s = _clean_str(value)
    if s is None:
        return None
    s = re.sub(r'\s+', '', s)
    length = settings.int('aadhaar_length')
    if not s.isdigit() or (length and len(s) != length):
        raise AdValidationError(settings.text('invalid_aadhaar_message', length=length or '', value=s))
    return s


def _clean_value(f, raw, settings):
    if f.field_type == 'checkbox':
        return True if _is_ticked(raw) else None
    if f.field_type == 'multi_select':
        return _as_list(raw) or None
    if f.field_type == 'mobile':
        return _check_mobile(raw, settings)
    if f.field_type == 'aadhaar':
        return _check_aadhaar(raw, settings)
    return _clean_str(raw)


def is_visible(f, values, defs_by_key, _seen=None):
    """Same rule as the form: a dependent field shows only while its parent (itself
    visible) has the given value; with no value given, while the parent is set."""
    parent_key = (f.depends_on_field_key or '').strip()
    if not parent_key:
        return True
    seen = _seen or set()
    if f.field_key in seen:
        return False
    seen.add(f.field_key)
    parent = defs_by_key.get(parent_key)
    if parent is not None and not is_visible(parent, values, defs_by_key, seen):
        return False
    raw = values.get(parent_key)
    if _blank(raw):
        return False
    targets = {t.strip().lower() for t in str(f.depends_on_value or '').split('|') if t.strip()}
    if not targets:
        return str(raw).strip().lower() not in ('false', '0')
    current = raw if isinstance(raw, list) else _as_list(raw) if isinstance(raw, str) and ',' in raw else [raw]
    return any(str(c).strip().lower() in targets for c in current)


def clean_form_data(data, field_defs, settings):
    """
    The request's answers keyed by the form's field keys: unknown keys dropped,
    hidden dependent fields dropped, mobile / Aadhaar checked, list rows cleaned.
    Raises AdValidationError.
    """
    data = data if isinstance(data, dict) else {}
    defs_by_key = {f.field_key: f for f in field_defs}
    children = {}
    for f in field_defs:
        if f.parent_field_key:
            children.setdefault(f.parent_field_key, []).append(f)

    values = {}
    for f in field_defs:
        if f.parent_field_key:
            continue
        raw = data.get(f.field_key)
        if f.field_type == 'repeating_group':
            rows = []
            for row in raw if isinstance(raw, list) else []:
                if not isinstance(row, dict):
                    continue
                clean_row = {}
                for k in children.get(f.field_key, []):
                    v = _clean_value(k, row.get(k.field_key), settings)
                    if not _blank(v):
                        clean_row[k.field_key] = v
                if clean_row:
                    rows.append(clean_row)
            if rows:
                values[f.field_key] = rows
            continue
        v = _clean_value(f, raw, settings)
        if not _blank(v):
            values[f.field_key] = v
            if f.field_type == 'checkbox':
                dt = _clean_str(data.get(f.field_key + CHECKBOX_DATE_SUFFIX))
                if dt:
                    values[f.field_key + CHECKBOX_DATE_SUFFIX] = dt

    # Drop answers of fields that are hidden by their dependency
    for f in field_defs:
        if f.parent_field_key or f.field_key not in values:
            continue
        if not is_visible(f, values, defs_by_key):
            values.pop(f.field_key, None)
            values.pop(f.field_key + CHECKBOX_DATE_SUFFIX, None)
    return values


def record_form_data(record, field_defs):
    """Stored answers keyed by the form's field keys (prefills an edit)."""
    extra = record.extra_fields if isinstance(record.extra_fields, dict) else {}
    out = {}
    for f in field_defs:
        if f.parent_field_key:
            continue
        for key in (f.field_key, f.field_key + CHECKBOX_DATE_SUFFIX):
            if key in extra and not _blank(extra[key]):
                out[key] = extra[key]
    return out


def is_disposal(record):
    return str(record.status or '').strip().lower() == STATUS_DISPOSAL.lower()


def record_status_label(disposal, settings):
    return settings.text('tab_disposal_label') if disposal else settings.text('tab_pending_label')


# ── Display (View, PDF, list card) ───────────────────────────────────────────
def mask_aadhaar(value, settings):
    s = re.sub(r'\s+', '', str(value or ''))
    if not s:
        return ''
    visible = settings.int('aadhaar_visible_digits') or 0
    mask = settings.raw('aadhaar_mask_char') or 'X'
    if len(s) <= visible:
        return s
    return mask * (len(s) - visible) + s[-visible:] if visible else mask * len(s)


def display_value(f, values, settings):
    """Text shown for one (non-list) field's answer."""
    raw = values.get(f.field_key)
    if _blank(raw):
        return ''
    if f.field_type == 'checkbox':
        if not _is_ticked(raw):
            return ''
        when = _clean_str(values.get(f.field_key + CHECKBOX_DATE_SUFFIX))
        yes = settings.text('yes_value')
        return f'{yes} ({when})' if when else yes
    if f.field_type == 'aadhaar':
        return mask_aadhaar(raw, settings)
    if isinstance(raw, list):
        return ', '.join(str(x) for x in raw)
    return str(raw)


def build_display_sections(values, field_defs, settings):
    """
    Ordered sections in template order:
      {'title', 'kind': 'fields', 'rows': [(label, value), ...]} or
      {'title', 'kind': 'table', 'headers': [...], 'rows': [[...], ...]}.
    Hidden dependent fields and empty answers are skipped; Aadhaar is masked.
    """
    defs_by_key = {f.field_key: f for f in field_defs}
    children = {}
    for f in field_defs:
        if f.parent_field_key:
            children.setdefault(f.parent_field_key, []).append(f)

    sections, index = [], {}

    def section(title, kind):
        key = (title, kind)
        if key not in index:
            index[key] = {'title': title, 'kind': kind, 'rows': []}
            sections.append(index[key])
        return index[key]

    for f in field_defs:
        if f.parent_field_key or not is_visible(f, values, defs_by_key):
            continue
        if f.field_type == 'repeating_group':
            rows = values.get(f.field_key) or []
            if not rows:
                continue
            kids = children.get(f.field_key, [])
            sec = section(f.field_label, 'table')
            sec['headers'] = [k.field_label for k in kids]
            for row in rows:
                sec['rows'].append([display_value(k, row, settings) for k in kids])
            continue
        text = display_value(f, values, settings)
        if text:
            section(f.section or f.field_label, 'fields')['rows'].append((f.field_label, text))
    return sections


def _card_entry(spec, values, defs_by_key):
    """'key' or 'group.child' -> (label, value)."""
    group_key, _, child_key = spec.partition('.')
    if child_key:
        group, child = defs_by_key.get(group_key), defs_by_key.get(child_key)
        if group is None or child is None:
            return None
        names = [str(r.get(child_key)) for r in values.get(group_key) or [] if not _blank(r.get(child_key))]
        return f'{group.field_label} {child.field_label}', ', '.join(names)
    f = defs_by_key.get(spec)
    if f is None:
        return None
    return f.field_label, values.get(spec)


def build_list_card(values, field_defs, settings):
    """
    Card boxes from module_settings ad.list_card_fields: comma separated boxes,
    each 'key' or 'group.child'; keys joined with '+' share one box
    ('A / B' label, each value on its own line).
    """
    defs_by_key = {f.field_key: f for f in field_defs}
    rows = []
    for box in str(settings.raw('list_card_fields') or '').split(','):
        labels, texts = [], []
        for spec in (s.strip() for s in box.split('+')):
            if not spec:
                continue
            entry = _card_entry(spec, values, defs_by_key)
            if entry is None:
                continue
            label, _ = entry
            f = defs_by_key.get(spec)
            text = display_value(f, values, settings) if f is not None else entry[1]
            labels.append(label)
            if text:
                texts.append(text)
        if labels:
            rows.append([' / '.join(labels), '\n'.join(texts)])
    return rows
