"""
Values of template fields kept in a table instead of JSON.

A template flagged `field_templates.store_values_in_table` (public schema) has
its answers saved as rows of `<tenant>.case_extra_field_values`:

- a single value            -> one row, row_no 0
- a multi-select           -> one row per chosen option, row_no 0, 1, 2 ...
- a repeating list (group) -> one row per child field per list row, row_no =
                              list row index; the group itself has no row

On save the same keys are removed from the case's `extra_fields` JSON. On read
they are put back into the API response, so the dynamic form fills itself
without knowing where they are stored.
"""
import logging

from apps.crimetab.models import (
    CaseCategory,
    CaseExtraFieldValue,
    CategoryFieldTemplate,
    FieldTemplateField,
)

logger = logging.getLogger(__name__)

# Nested JSON containers the forms also copy field values into
_NESTED_KEYS = ('extra_field_values', 'dynamic_extra_fields', 'commonForm')


def table_fields_for_case(case):
    """FieldTemplateField rows (store_values_in_table templates) of the case's tabs."""
    cat_ids = set()
    try:
        cat_ids.update(case.category_links.values_list('category_id', flat=True))
    except Exception:
        pass
    sub = (case.sub_category or '').strip()
    if sub:
        cat_ids.update(CaseCategory.objects.filter(category_name__iexact=sub)
                       .values_list('category_id', flat=True))
    if not cat_ids:
        return []
    template_ids = CategoryFieldTemplate.objects.filter(
        category_id__in=cat_ids, template__store_values_in_table=True,
    ).values_list('template_id', flat=True)
    return list(FieldTemplateField.objects.filter(template_id__in=list(template_ids))
                .order_by('display_order', 'field_def_id'))


def _text(value):
    if value is None:
        return ''
    if isinstance(value, bool):
        return 'Yes' if value else 'No'
    return str(value).strip()


def _as_list(value):
    if isinstance(value, (list, tuple, set)):
        return [v for v in value]
    text = _text(value)
    if text.startswith('[') and text.endswith(']'):
        text = text[1:-1]
    return [p.strip() for p in text.split(',')] if text else []


def _payload_sources(data):
    """Places the forms put field values in, most specific first."""
    extra = data.get('extra_fields') if isinstance(data.get('extra_fields'), dict) else {}
    sources = [data, extra]
    for container in (data, extra):
        for key in _NESTED_KEYS:
            if isinstance(container.get(key), dict):
                sources.append(container[key])
    return sources


def save_table_values(case, data):
    """
    Writes the table-stored template fields of `data` (the case save payload)
    into case_extra_field_values and removes them from case.extra_fields.
    Returns the set of field keys handled (so other savers can skip them).
    """
    fields = table_fields_for_case(case)
    if not fields:
        return set()
    keys = {f.field_key for f in fields}
    sources = _payload_sources(data if isinstance(data, dict) else {})

    def lookup(key):
        """(found, value): a list or non-empty value wins over an empty one."""
        found, empty = False, None
        for src in sources:
            if key in src:
                value = src[key]
                if isinstance(value, list) or _text(value):
                    return True, value
                found, empty = True, value
        return found, empty

    children = {}
    for f in fields:
        if f.parent_field_key:
            children.setdefault(f.parent_field_key, []).append(f)

    rows, touched = [], []
    for f in fields:
        if f.parent_field_key:
            continue
        found, value = lookup(f.field_key)
        if not found:
            continue
        touched.append(f)
        if f.field_type == 'repeating_group':
            kids = children.get(f.field_key, [])
            touched.extend(kids)
            list_rows = value if isinstance(value, list) else []
            row_no = 0
            for item in list_rows:
                if not isinstance(item, dict):
                    continue
                cells = [(k, _text(item.get(k.field_key))) for k in kids]
                if not any(v for _, v in cells):
                    continue  # empty list row
                rows.extend(CaseExtraFieldValue(case=case, field_def=k, row_no=row_no, field_value=v)
                            for k, v in cells if v)
                row_no += 1
        elif f.field_type == 'multi_select':
            chosen = [_text(v) for v in _as_list(value) if _text(v)]
            rows.extend(CaseExtraFieldValue(case=case, field_def=f, row_no=i, field_value=v)
                        for i, v in enumerate(chosen))
        else:
            text = _text(value)
            if text:
                rows.append(CaseExtraFieldValue(case=case, field_def=f, row_no=0, field_value=text))

    if touched:
        CaseExtraFieldValue.objects.filter(case=case, field_def__in=touched).delete()
        CaseExtraFieldValue.objects.bulk_create(rows)

    strip_keys_from_json(case, keys)
    return keys


def strip_keys_from_json(case, keys):
    extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
    changed = False
    for container in [extra] + [extra[k] for k in _NESTED_KEYS if isinstance(extra.get(k), dict)]:
        for key in keys & set(container):
            container.pop(key, None)
            changed = True
    if changed:
        case.extra_fields = extra
        type(case).objects.filter(pk=case.pk).update(extra_fields=extra)


def table_values_for_case(case, values=None):
    """
    {field_key: value} of the case's table-stored fields, shaped like the form
    sends them: text, a list for a multi-select, a list of row dicts for a
    repeating list. `values` may be pre-fetched CaseExtraFieldValue rows.
    """
    fields = table_fields_for_case(case)
    if not fields:
        return {}
    by_id = {f.field_def_id: f for f in fields}
    if values is None:
        values = CaseExtraFieldValue.objects.filter(case=case, field_def_id__in=list(by_id))
    out, groups = {}, {}
    for v in sorted(values, key=lambda x: (x.field_def_id, x.row_no)):
        f = by_id.get(v.field_def_id)
        if f is None:
            continue
        if f.parent_field_key:
            group_rows = groups.setdefault(f.parent_field_key, {})
            group_rows.setdefault(v.row_no, {})[f.field_key] = v.field_value or ''
        elif f.field_type == 'multi_select':
            out.setdefault(f.field_key, []).append(v.field_value or '')
        else:
            out[f.field_key] = v.field_value or ''
    for group_key, group_rows in groups.items():
        out[group_key] = [group_rows[i] for i in sorted(group_rows)]
    return out
