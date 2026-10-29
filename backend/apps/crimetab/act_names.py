"""
One act per law, whatever name a script or file uses for it.

data/acts/act_aliases.xlsx (ALIAS | ACT) maps the short or old names ('BNS',
'BNS 2023', 'Bharatiya Nyaya Sanhita 2023' ...) to the act's official name, the
name `manage.py import_acts` stores. Seed scripts call get_act() so they reuse
that act instead of creating a second one.
"""
import logging
import re
from functools import lru_cache
from pathlib import Path

from django.conf import settings
from django.db.models import Max

logger = logging.getLogger(__name__)

ALIASES_FILE = Path(settings.BASE_DIR) / 'data' / 'acts' / 'act_aliases.xlsx'


def _norm(value):
    return re.sub(r'[^a-z0-9]', '', str(value or '').lower())


@lru_cache(maxsize=1)
def _aliases():
    """{alias lowercased: official name} from the alias file ({} if unreadable)."""
    try:
        import openpyxl
        wb = openpyxl.load_workbook(ALIASES_FILE, read_only=True, data_only=True)
    except Exception as e:  # missing file or openpyxl: names are used as given
        logger.warning("[acts] alias file not read (%s): %s", ALIASES_FILE, e)
        return {}
    out, cols = {}, None
    for row in wb.worksheets[0].iter_rows(values_only=True, max_col=10):
        values = [str(v).strip() if v is not None else '' for v in row]
        if cols is None:
            heads = [_norm(v) for v in values]
            if 'alias' in heads and 'act' in heads:
                cols = (heads.index('alias'), heads.index('act'))
            continue
        alias, act = values[cols[0]], values[cols[1]]
        if alias and act:
            out[alias.lower()] = act
    wb.close()
    return out


def official_act_name(name):
    name = str(name or '').strip()
    return _aliases().get(name.lower(), name)


def get_act(name):
    """The act for `name` (alias-resolved, matched ignoring case); created only if missing."""
    from apps.crimetab.models.common_form import Act

    official = official_act_name(name)
    act = Act.objects.filter(act_name__iexact=official).order_by('act_id').first()
    if act is None:
        order = (Act.objects.aggregate(m=Max('display_order'))['m'] or 0) + 10
        act = Act.objects.create(act_name=official, display_order=order)
    return act
