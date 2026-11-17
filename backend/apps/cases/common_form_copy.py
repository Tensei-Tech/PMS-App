"""
The `commonForm` copy inside a case's JSON is no longer stored.

The app sends every Common Form answer twice: at the top level of
extra_fields and again inside extra_fields['commonForm']. The answers now live
in their own tables (see apps/crimetab/common_form_tables.py) and the case API
fills the form from them, so the second copy only cost space and drifted.

fold_common_form() moves what only the copy holds up to the top level and
removes the copy. CaseRecord.save() calls it, so no save path stores it again.
The save code still reads the copy from the incoming request, before this runs.

When both hold an answer, the copy's non-empty answer wins: that is what the
edit form showed and what the save code used until now. Nested dicts (template
answers in dynamic_extra_fields, ...) are merged key by key the same way.
Bookkeeping keys keep the top-level value, which is the newer one.
"""

EMPTY = (None, '', [], {})
COPY_KEYS = ('commonForm', 'common_form')
KEEP_TOP = frozenset({'id', 'lastEditedAt', 'updatedAt', 'updated_at', 'createdAt', 'created_at'})


def _merge(top, copy):
    out = dict(top)
    for key, value in copy.items():
        if key in COPY_KEYS or value in EMPTY:
            continue  # an older copy nested inside the copy, or no answer
        current = out.get(key)
        if key in KEEP_TOP and current not in EMPTY:
            continue
        if isinstance(value, dict) and isinstance(current, dict):
            out[key] = _merge(current, value)
        else:
            out[key] = value
    return out


def fold_common_form(extra):
    """extra_fields without the commonForm copy, its answers moved to the top level.
    Returns the same object when there is no copy."""
    if not isinstance(extra, dict) or not any(k in extra for k in COPY_KEYS):
        return extra
    folded = {k: v for k, v in extra.items() if k not in COPY_KEYS}
    for key in COPY_KEYS:
        if isinstance(extra.get(key), dict):
            folded = _merge(folded, extra[key])
    return folded
