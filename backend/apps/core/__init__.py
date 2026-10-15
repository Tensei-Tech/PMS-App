import logging
from django.db.backends.utils import CursorWrapper as _OriginalCursorWrapper

_logger = logging.getLogger(__name__)

_original_execute = _OriginalCursorWrapper.execute

def _guarded_execute(self, sql, params=None):
    """Execute raw SQL safely across PostgreSQL and SQLite backends.
    Only skips PostgreSQL-specific session statements (like SET search_path)
    when running on a non-PostgreSQL backend like SQLite.
    """
    if getattr(self, "db", None) and getattr(self.db, "vendor", None) != "postgresql":
        sql_str = str(sql).strip().upper()
        if sql_str.startswith(("SET SEARCH_PATH", "SHOW SEARCH_PATH")):
            return None
    return _original_execute(self, sql, params)


# Monkey‑patch the execute method globally for all cursors
_OriginalCursorWrapper.execute = _guarded_execute

