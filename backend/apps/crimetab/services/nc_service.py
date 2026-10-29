"""
N.C. (Non-Cognizable) module: settings, validation, save, status rule, display rows.

- Form definition: public.field_templates / field_template_fields (template from
  module_settings 'template_name'); labels, option groups and headings come from there.
- Records: <state schema>.nc_records / nc_persons / nc_charges / nc_preventive_actions.
- Every text, limit and rule value comes from public.module_settings (module_key 'nc').
- Every function issues a constant number of queries (no query inside a loop).
"""
import datetime
import json
import logging
import re

from django.db import transaction
from django.db.models import Count, IntegerField, OuterRef, Q, Subquery, Value
from django.db.models.functions import Coalesce

from apps.crimetab.models import FieldTemplateField, ModuleSetting, OptionValue
from apps.crimetab.models.nc import NcCharge, NcPerson, NcPreventiveAction, NcRecord
from apps.crimetab.age_limits import MAX_AGE, MIN_AGE

logger = logging.getLogger(__name__)

MODULE_KEY = 'nc'

# ── Field key ↔ column mapping (field keys come from migration 0053) ────────────
SCALAR_COLUMNS = {
    'nc_no': 'nc_no',
    'nc_registered_date': 'registered_date',
    'nc_spot_village': 'spot_village',
    'nc_spot_area': 'spot_area',
    'nc_spot_address': 'spot_address',
    'nc_occurrence_at': 'occurrence_at',
    'nc_io_name': 'io_name',
    'nc_io_designation': 'io_designation',
    'nc_io_mobile': 'io_mobile',
    'nc_reg_name': 'reg_name',
    'nc_reg_designation': 'reg_designation',
    'nc_reg_mobile': 'reg_mobile',
    'nc_first_information': 'first_information',
    'nc_post_crime_registered': 'post_crime_registered',
    'nc_post_crime_no': 'post_crime_no',
    'nc_post_act': 'post_act',
    'nc_post_section': 'post_section',
}
MOBILE_COLUMNS = {'io_mobile', 'reg_mobile'}

PERSON_TYPE_COMPLAINANT = 'complainant'
PERSON_TYPE_NON_APPLICANT = 'non_applicant'
PERSON_GROUPS = {
    'nc_complainants': (PERSON_TYPE_COMPLAINANT, 'nc_cmp_'),
    'nc_non_applicants': (PERSON_TYPE_NON_APPLICANT, 'nc_na_'),
}
# child field suffix -> nc_persons column
PERSON_CHILD_COLUMNS = {
    'name': 'name', 'age': 'age', 'gender': 'gender', 'cast': 'caste',
    'profession': 'profession', 'mobile': 'mobile', 'address': 'address', 'aadhaar': 'aadhaar',
}

CHARGES_KEY = 'nc_charges'
CHARGE_COLUMNS = ('act_id', 'section_id', 'subsection_id', 'act_name',
                  'section_number', 'section_title', 'subsection_code')

PREVENTIVE_KEY = 'nc_preventive_actions'
PREVENTIVE_CHILD_COLUMNS = {
    'nc_prev_provision': 'provision',
    'nc_prev_date': 'action_date',
    'nc_prev_outward_no': 'outward_number',
    'nc_prev_outward_date': 'outward_date',
    'nc_prev_bond_date': 'bond_date',
    'nc_prev_bond_cancel_date': 'bond_cancellation_date',
    'nc_prev_number': 'preventive_number',
}
PREVENTIVE_PERSON_KEY = 'nc_prev_person'
PREVENTIVE_DATE_COLUMNS = {'action_date', 'outward_date', 'bond_date', 'bond_cancellation_date'}

_OPTIONS_SOURCE_RE = re.compile(r'^/api/options/([^/]+)/?$')
# Option groups served from the designations master by /api/options/<group>/
DESIGNATION_OPTION_GROUPS = {'designations', 'designation', 'posts', 'post'}


class NcValidationError(Exception):
    """Raised with a ready-to-show message (from module_settings)."""


# ── Settings ───────────────────────────────────────────────────────────────────
class NcSettings:
    """All module_settings for 'nc' (plus 'common' fallbacks) loaded in ONE query."""

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
            logger.warning("[NC] module_settings missing: nc.%s", key)
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
            logger.warning("[NC] module_settings missing or not an integer: nc.%s", key)
            return None

    def raw(self, key):
        return self._map.get(key)


# ── Form definition ───────────────────────────────────────────────────────────
def load_field_defs(settings):
    """NC template fields from public, ordered (ONE query)."""
    tmpl_name = settings.raw('template_name')
    if not tmpl_name:
        logger.warning("[NC] module_settings missing: nc.template_name")
        return []
    return list(
        FieldTemplateField.objects.filter(template__template_name=tmpl_name)
        .order_by('display_order', 'pk')
    )


def option_group_of(field_def):
    m = _OPTIONS_SOURCE_RE.match(str(field_def.options_source or '').strip())
    return m.group(1) if m else None


def load_options(field_defs):
    """{option_group: [values]} for every option group the form uses (ONE query)."""
    groups = {g for g in (option_group_of(f) for f in field_defs) if g}
    if not groups:
        return {}
    result = {g: [] for g in groups}
    # Same sources as /api/options/<group>/: designation groups come from the
    # designations master, everything else from public.option_values.
    master_groups = {g for g in groups if g.lower() in DESIGNATION_OPTION_GROUPS}
    plain_groups = groups - master_groups
    if plain_groups:
        for group, value in (
            OptionValue.objects.filter(option_group__in=plain_groups, is_active=True)
            .order_by('display_order', 'id').values_list('option_group', 'option_value')
        ):
            result.setdefault(group, []).append(value)
    if master_groups:
        from apps.public_master.models import Designation
        names = [
            d or t for d, t in Designation.objects.filter(is_active=True)
            .order_by('rank_level', 'code').values_list('display_name', 'title')
            if (d or t)
        ]
        for g in master_groups:
            result[g] = names
    return result


# ── Status rule (ONE shared definition) ────────────────────────────────────────
# Columns a non-date-only Preventive row may be required to fill
# (which ones: module_settings nc.preventive_required_fields, comma separated)
PREVENTIVE_REQUIRABLE_COLUMNS = ('outward_number', 'bond_date', 'bond_cancellation_date')
_TEXT_REQUIRABLE_COLUMNS = {'outward_number'}


def preventive_required_columns(settings):
    """Columns (besides Provision and Date) a non-date-only row needs, from settings."""
    raw = settings.raw('preventive_required_fields')
    if raw is None:
        logger.warning("[NC] module_settings missing: nc.preventive_required_fields")
        return ()
    cols = [c.strip() for c in str(raw).split(',') if c.strip()]
    return tuple(c for c in cols if c in PREVENTIVE_REQUIRABLE_COLUMNS)


def incomplete_preventive_q(date_only_provision, required_columns):
    """
    A Preventive row is COMPLETE when it has a Provision and a Date and either
    the Provision is the date-only provision (module_settings) or every column in
    required_columns (module_settings) is filled. This Q matches the rows that
    are NOT complete.
    """
    missing_extra = Q(pk__in=[])  # matches nothing when no extra column is required
    for col in required_columns:
        missing_extra |= Q(**{f'{col}__isnull': True})
        if col in _TEXT_REQUIRABLE_COLUMNS:
            missing_extra |= Q(**{col: ''})
    not_date_only = ~Q(provision=date_only_provision) if date_only_provision else Q()
    return (
        Q(provision__isnull=True) | Q(provision='') | Q(action_date__isnull=True)
        | (not_date_only & missing_extra)
    )


def _count_rows(rows):
    """Correlated scalar COUNT subquery (never hashed: evaluated per record via the nc_id index)."""
    return Coalesce(
        Subquery(rows.order_by().values('nc_id').annotate(c=Count('id')).values('c')[:1],
                 output_field=IntegerField()),
        Value(0),
    )


def with_status(queryset, settings):
    """
    Annotate the shared status: prev_total = number of Preventive rows,
    prev_incomplete = number of rows that are NOT complete.
    Disposal = prev_total > 0 AND prev_incomplete = 0 (every row complete);
    Pending = every other N.C. Used by the list, the counts, the view and the PDF.
    """
    date_only = settings.raw('date_only_provision')
    if not date_only:
        logger.warning("[NC] module_settings missing: nc.date_only_provision")
    rows = NcPreventiveAction.objects.filter(nc=OuterRef('pk'))
    return queryset.annotate(
        prev_total=_count_rows(rows),
        prev_incomplete=_count_rows(rows.filter(
            incomplete_preventive_q(date_only, preventive_required_columns(settings)))),
    )


def disposal_q():
    return Q(prev_total__gt=0, prev_incomplete=0)


def pending_q():
    # Written positively (not ~disposal_q) so the planner keeps per-row index lookups
    return Q(prev_total=0) | Q(prev_incomplete__gt=0)


def is_disposal(obj):
    """Status of a record annotated by with_status()."""
    return bool(obj.prev_total and not obj.prev_incomplete)


def disposal_map(record_ids, settings):
    """{id: is_disposal} for a page of records, using the same expression (ONE query)."""
    if not record_ids:
        return {}
    rows = with_status(NcRecord.objects.filter(id__in=record_ids), settings).values_list(
        'id', 'prev_total', 'prev_incomplete'
    )
    return {rid: bool(total and not bad) for rid, total, bad in rows}


def row_is_complete(row, date_only_provision, required_columns):
    """Python mirror of incomplete_preventive_q for one in-memory row (no query)."""
    if not (row.provision or '').strip() or row.action_date is None:
        return False
    if date_only_provision and row.provision == date_only_provision:
        return True
    for col in required_columns:
        val = getattr(row, col)
        if val is None or (col in _TEXT_REQUIRABLE_COLUMNS and not str(val).strip()):
            return False
    return True


# ── Parsing helpers ────────────────────────────────────────────────────────────
def _blank(v):
    return v is None or (isinstance(v, str) and not v.strip()) or (isinstance(v, (list, dict)) and not v)


def _clean_str(v):
    if v is None:
        return None
    s = str(v).strip()
    return s or None


def _as_list(v):
    if v is None or v == '':
        return []
    if isinstance(v, str):
        try:
            v = json.loads(v)
        except ValueError:
            return []
    if isinstance(v, dict):
        v = [v]
    return [r for r in v if isinstance(r, dict)] if isinstance(v, list) else []


def _parse_date(value, settings, label):
    s = _clean_str(value)
    if s is None:
        return None
    fmt = settings.raw('date_format')
    for f in [x for x in (fmt, '%Y-%m-%d') if x]:
        try:
            return datetime.datetime.strptime(s[:10] if f == '%Y-%m-%d' else s, f).date()
        except ValueError:
            continue
    raise NcValidationError(settings.text('invalid_date_message', value=s, field=label))


def _parse_datetime(value, settings, label):
    s = _clean_str(value)
    if s is None:
        return None
    from django.utils import timezone
    fmt = settings.raw('datetime_format')
    candidates = []
    if fmt:
        try:
            candidates.append(datetime.datetime.strptime(s, fmt))
        except ValueError:
            pass
    if not candidates:
        try:
            candidates.append(datetime.datetime.fromisoformat(s.replace('Z', '+00:00')))
        except ValueError:
            raise NcValidationError(settings.text('invalid_date_message', value=s, field=label))
    dt = candidates[0]
    return timezone.make_aware(dt) if timezone.is_naive(dt) else dt


def _check_mobile(value, settings):
    s = _clean_str(value)
    if s is None:
        return None
    if not re.fullmatch(r'\d{10}', s):
        raise NcValidationError(settings.text('invalid_mobile_message', value=s))
    return s


def _check_age(value, settings):
    s = _clean_str(value)
    if s is None:
        return None
    try:
        age = int(float(s))
    except ValueError:
        raise NcValidationError(settings.text('invalid_age_message', value=s))
    if age < MIN_AGE or age > MAX_AGE:
        raise NcValidationError(settings.text('invalid_age_message', value=s))
    return age


def _check_aadhaar(value, settings):
    s = _clean_str(value)
    if s is None:
        return None
    s = re.sub(r'\s+', '', s)
    length = settings.int('aadhaar_length')
    if not s.isdigit() or (length and len(s) != length):
        raise NcValidationError(settings.text('invalid_aadhaar_message', length=length or '', value=s))
    return s


def _check_option(value, field_def, options, settings):
    s = _clean_str(value)
    if s is None or field_def is None:
        return s
    group = option_group_of(field_def)
    if group is None:
        return s
    allowed = options.get(group, [])
    for opt in allowed:
        if opt.lower() == s.lower():
            return opt
    raise NcValidationError(settings.text('invalid_option_message', field=field_def.field_label, value=s))


def mask_aadhaar(value, settings):
    """Aadhaar masking rule from module_settings (visible trailing digits + mask char)."""
    s = _clean_str(value)
    if s is None:
        return ''
    visible = settings.int('aadhaar_visible_digits')
    mask_char = settings.raw('aadhaar_mask_char') or ''
    if visible is None:
        return ''
    keep = s[-visible:] if visible > 0 else ''
    return (mask_char * (len(s) - len(keep))) + keep


# ── Payload → validated plan ────────────────────────────────────────────────────
class NcPlan:
    """Validated, normalised N.C. ready to save (no DB access)."""

    def __init__(self):
        self.scalars = {}
        self.persons = []        # dicts with person_type + columns
        self.charges = []        # dicts of CHARGE_COLUMNS
        self.preventive = []     # dicts of columns + 'person_name'


def _normalise_payload(data):
    """Accept field keys with or without the nc_ prefix (both are emitted by the engine)."""
    out = {}
    for k, v in (data or {}).items():
        key = str(k)
        if not key.startswith('nc_') and f'nc_{key}' in SCALAR_COLUMNS:
            key = f'nc_{key}'
        out[key] = v
    return out


def build_plan(data, settings, field_defs, options):
    """Validate a full N.C. state; raise NcValidationError with a settings message."""
    data = _normalise_payload(data)
    defs = {f.field_key: f for f in field_defs}
    plan = NcPlan()

    for key, col in SCALAR_COLUMNS.items():
        val = data.get(key)
        fdef = defs.get(key)
        label = fdef.field_label if fdef else key
        if fdef is not None and fdef.field_type == 'date':
            plan.scalars[col] = _parse_date(val, settings, label)
        elif fdef is not None and fdef.field_type == 'datetime':
            plan.scalars[col] = _parse_datetime(val, settings, label)
        elif col in MOBILE_COLUMNS:
            plan.scalars[col] = _check_mobile(val, settings)
        elif fdef is not None and option_group_of(fdef):
            plan.scalars[col] = _check_option(val, fdef, options, settings)
        else:
            plan.scalars[col] = _clean_str(val)

    # First information content length (limit from module_settings)
    fic = plan.scalars.get('first_information')
    limit = settings.int('first_information_max_length')
    if fic and limit and len(fic) > limit:
        raise NcValidationError(settings.text('first_information_too_long_message', limit=limit))

    # Crime registered after NC: dependent fields only when the answer is the yes value
    yes_value = settings.raw('yes_value')
    if (plan.scalars.get('post_crime_registered') or '') != (yes_value or object()):
        for col in ('post_crime_no', 'post_act', 'post_section'):
            plan.scalars[col] = None

    # Persons
    for group_key, (ptype, prefix) in PERSON_GROUPS.items():
        for order, row in enumerate(_as_list(data.get(group_key)), 1):
            person = {'person_type': ptype, 'display_order': order}
            for suffix, col in PERSON_CHILD_COLUMNS.items():
                raw_val = row.get(f'{prefix}{suffix}', row.get(col))
                fdef = defs.get(f'{prefix}{suffix}')
                if col == 'age':
                    person[col] = _check_age(raw_val, settings)
                elif col == 'mobile':
                    person[col] = _check_mobile(raw_val, settings)
                elif col == 'aadhaar':
                    person[col] = _check_aadhaar(raw_val, settings)
                elif fdef is not None and option_group_of(fdef):
                    person[col] = _check_option(raw_val, fdef, options, settings)
                else:
                    person[col] = _clean_str(raw_val)
            if any(person[c] is not None for c in PERSON_CHILD_COLUMNS.values()):
                plan.persons.append(person)

    # Charges (text copies; ids kept without FK)
    for order, row in enumerate(_as_list(data.get(CHARGES_KEY)), 1):
        charge = {'display_order': order}
        for col in CHARGE_COLUMNS:
            v = row.get(col)
            if col.endswith('_id'):
                try:
                    charge[col] = int(v) if v not in (None, '') else None
                except (TypeError, ValueError):
                    charge[col] = None
            else:
                charge[col] = _clean_str(v)
        if any(charge[c] is not None for c in CHARGE_COLUMNS):
            plan.charges.append(charge)

    # Preventive rows
    na_names = {
        (p['name'] or '').strip().lower()
        for p in plan.persons if p['person_type'] == PERSON_TYPE_NON_APPLICANT and p.get('name')
    }
    for order, row in enumerate(_as_list(data.get(PREVENTIVE_KEY)), 1):
        prev = {'display_order': order}
        for key, col in PREVENTIVE_CHILD_COLUMNS.items():
            raw_val = row.get(key, row.get(col))
            fdef = defs.get(key)
            label = fdef.field_label if fdef else key
            if col in PREVENTIVE_DATE_COLUMNS:
                prev[col] = _parse_date(raw_val, settings, label)
            elif fdef is not None and option_group_of(fdef):
                prev[col] = _check_option(raw_val, fdef, options, settings)
            else:
                prev[col] = _clean_str(raw_val)
        person_name = _clean_str(row.get(PREVENTIVE_PERSON_KEY, row.get('person_name')))
        if person_name and person_name.lower() not in na_names:
            raise NcValidationError(settings.text('invalid_preventive_person_message'))
        prev['person_name'] = person_name
        if person_name or any(prev[c] is not None for c in PREVENTIVE_CHILD_COLUMNS.values()):
            plan.preventive.append(prev)

    if not any(v is not None for v in plan.scalars.values()) and not (
        plan.persons or plan.charges or plan.preventive
    ):
        raise NcValidationError(settings.text('empty_request_message'))
    return plan


# ── Save (ONE transaction, one insert per table) ────────────────────────────────
def save_plan(plan, station_name, created_by=None, record=None):
    """Create (record=None) or replace an N.C. and all its child rows atomically."""
    with transaction.atomic():
        if record is None:
            record = NcRecord.objects.create(station_name=station_name, created_by=created_by, **plan.scalars)
        else:
            for col, val in plan.scalars.items():
                setattr(record, col, val)
            record.save()
            # Child rows are replaced; preventive rows cascade with persons
            NcPreventiveAction.objects.filter(nc=record).delete()
            NcPerson.objects.filter(nc=record).delete()
            NcCharge.objects.filter(nc=record).delete()

        persons = NcPerson.objects.bulk_create([NcPerson(nc=record, **p) for p in plan.persons])
        if plan.charges:
            NcCharge.objects.bulk_create([NcCharge(nc=record, **c) for c in plan.charges])

        if plan.preventive:
            by_name = {}
            for p in persons:
                if p.person_type == PERSON_TYPE_NON_APPLICANT and p.name:
                    by_name.setdefault(p.name.strip().lower(), p)
            rows = []
            for prev in plan.preventive:
                name = (prev.pop('person_name') or '').strip().lower()
                rows.append(NcPreventiveAction(nc=record, person=by_name.get(name), **prev))
            NcPreventiveAction.objects.bulk_create(rows)
    return record


# ── Loading children for many records (one query per child table) ───────────────
def load_children(record_ids):
    """{nc_id: {'persons': [...], 'charges': [...], 'preventive': [...]}} in 3 queries."""
    out = {rid: {'persons': [], 'charges': [], 'preventive': []} for rid in record_ids}
    if not record_ids:
        return out
    for p in NcPerson.objects.filter(nc_id__in=record_ids).order_by('nc_id', 'person_type', 'display_order', 'id'):
        out[p.nc_id]['persons'].append(p)
    for c in NcCharge.objects.filter(nc_id__in=record_ids).order_by('nc_id', 'display_order', 'id'):
        out[c.nc_id]['charges'].append(c)
    for a in NcPreventiveAction.objects.filter(nc_id__in=record_ids).order_by('nc_id', 'display_order', 'id'):
        out[a.nc_id]['preventive'].append(a)
    return out


# ── Record → form data (for edit) ───────────────────────────────────────────────
def _fmt_date(d, settings):
    if not d:
        return ''
    fmt = settings.raw('date_format')
    return d.strftime(fmt) if fmt else d.isoformat()


def _fmt_datetime(dt, settings):
    if not dt:
        return ''
    from django.utils import timezone
    fmt = settings.raw('datetime_format')
    local = timezone.localtime(dt) if timezone.is_aware(dt) else dt
    return local.strftime(fmt) if fmt else local.isoformat()


def record_form_data(record, children, settings):
    """Values keyed by the form's field keys, so the engine can prefill an edit."""
    data = {'id': record.id}
    for key, col in SCALAR_COLUMNS.items():
        val = getattr(record, col)
        if col == 'registered_date':
            val = _fmt_date(val, settings)
        elif col == 'occurrence_at':
            val = _fmt_datetime(val, settings)
        data[key] = val if val is not None else ''

    persons_by_id = {}
    for group_key, (ptype, prefix) in PERSON_GROUPS.items():
        rows = []
        for p in children['persons']:
            if p.person_type != ptype:
                continue
            persons_by_id[p.id] = p
            rows.append({
                f'{prefix}{suffix}': ('' if getattr(p, col) is None else str(getattr(p, col)))
                for suffix, col in PERSON_CHILD_COLUMNS.items()
            })
        data[group_key] = rows

    data[CHARGES_KEY] = [
        {col: getattr(c, col) for col in CHARGE_COLUMNS} for c in children['charges']
    ]

    prev_rows = []
    for a in children['preventive']:
        row = {}
        for key, col in PREVENTIVE_CHILD_COLUMNS.items():
            v = getattr(a, col)
            row[key] = _fmt_date(v, settings) if col in PREVENTIVE_DATE_COLUMNS else (v or '')
        person = persons_by_id.get(a.person_id)
        row[PREVENTIVE_PERSON_KEY] = person.name if person and person.name else ''
        prev_rows.append(row)
    data[PREVENTIVE_KEY] = prev_rows
    return data


# ── Ordered display rows (shared by View and PDF) ───────────────────────────────
def build_display_sections(record, children, field_defs, settings):
    """
    Ordered sections in template order. Each section is either
      {'title', 'kind': 'fields', 'rows': [(label, value), ...]} or
      {'title', 'kind': 'table', 'headers': [...], 'rows': [[...], ...]}.
    Aadhaar is masked; hidden dependent fields are skipped.
    """
    form = record_form_data(record, children, settings)
    defs_by_parent = {}
    for f in field_defs:
        if f.parent_field_key:
            defs_by_parent.setdefault(f.parent_field_key, []).append(f)

    sections, index = [], {}

    def section(title, kind):
        key = (title, kind)
        if key not in index:
            index[key] = {'title': title, 'kind': kind, 'rows': []}
            sections.append(index[key])
        return index[key]

    for f in field_defs:
        if f.parent_field_key:
            continue
        title = f.section or f.field_label
        if f.field_type == 'repeating_group':
            kids = defs_by_parent.get(f.field_key, [])
            sec = section(f.field_label, 'table')
            sec['headers'] = [k.field_label for k in kids]
            for row in form.get(f.field_key, []):
                sec['rows'].append([
                    mask_aadhaar(row.get(k.field_key), settings) if k.field_key.endswith('_aadhaar')
                    else (row.get(k.field_key) or '')
                    for k in kids
                ])
        elif f.field_type == 'charges':
            sec = section(f.field_label, 'table')
            labels = [settings.text('charge_act_label'), settings.text('charge_section_label'),
                      settings.text('charge_subsection_label')]
            sec['headers'] = labels
            for c in children['charges']:
                section_txt = ' '.join(x for x in (c.section_number, c.section_title) if x)
                sec['rows'].append([c.act_name or '', section_txt, c.subsection_code or ''])
        else:
            if f.depends_on_field_key:
                parent_val = str(form.get(f.depends_on_field_key) or '')
                if parent_val.lower() != str(f.depends_on_value or '').lower():
                    continue
            section(title, 'fields')['rows'].append((f.field_label, form.get(f.field_key) or ''))
    return sections


# ── List card (Total / Pending / Disposal tabs) ─────────────────────────────────
# Preventive fields shown on the card, in display order; keys grouped in one
# tuple share a single box (labels: field_template_fields)
LIST_CARD_PREVENTIVE_KEYS = (
    ('nc_prev_provision', 'nc_prev_number'),
    ('nc_prev_outward_no', 'nc_prev_date'),
    ('nc_prev_bond_date',),
)


def _merged(labels, values):
    """One card box for several fields: 'A / B' label, each value on its own line."""
    return (' / '.join(l for l in labels if l),
            '\n'.join(v for v in values if v))


def build_list_card(record, children, field_defs, settings):
    """
    Card rows for one N.C. in the hub list: NC No., Act / Section, Complainant,
    Non applicant, Investigation officer, then every Preventive row
    (Preventive / Number, Outward No. / Date, Bond Date).
    Labels come from the NC form's field labels / module_settings; no query.
    """
    by_key = {f.field_key: f for f in field_defs}

    def label(key):
        f = by_key.get(key)
        return f.field_label if f else ''

    def section_label(key):
        f = by_key.get(key)
        return (f.section or f.field_label) if f else ''

    def names(person_type):
        return ', '.join(p.name for p in children['persons']
                         if p.person_type == person_type and p.name)

    # Act with its sections, e.g. "BNS 115, 352; BNSS 126"
    sections_by_act = {}
    for c in children['charges']:
        if c.act_name or c.section_number:
            secs = sections_by_act.setdefault(c.act_name or '', [])
            if c.section_number:
                secs.append(c.section_number)
    act_section = '; '.join(
        ' '.join(x for x in (act, ', '.join(secs)) if x)
        for act, secs in sections_by_act.items()
    )
    officer = ', '.join(x for x in (record.io_name, record.io_designation) if x)

    rows = [
        (label('nc_no'), record.nc_no or ''),
        _merged([settings.text('charge_act_label'), settings.text('charge_section_label')],
                [act_section]),
        (label('nc_complainants'), names(PERSON_TYPE_COMPLAINANT)),
        (label('nc_non_applicants'), names(PERSON_TYPE_NON_APPLICANT)),
        (section_label('nc_io_name'), officer),
    ]

    preventive_rows = []
    for a in children['preventive']:
        row = []
        for keys in LIST_CARD_PREVENTIVE_KEYS:
            vals = []
            for key in keys:
                col = PREVENTIVE_CHILD_COLUMNS[key]
                val = getattr(a, col)
                vals.append(_fmt_date(val, settings) if col in PREVENTIVE_DATE_COLUMNS else (val or ''))
            row.append(list(_merged([label(k) for k in keys], vals)))
        preventive_rows.append(row)

    return {
        'card_rows': [[lbl, val] for lbl, val in rows],
        'preventive_label': label(PREVENTIVE_KEY),
        'preventive_rows': preventive_rows,
    }


def record_status_label(is_disposal, settings):
    return settings.text('tab_disposal_label') if is_disposal else settings.text('tab_pending_label')
