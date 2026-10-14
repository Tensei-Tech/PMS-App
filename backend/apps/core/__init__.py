import logging
from django.db.backends.utils import CursorWrapper as _OriginalCursorWrapper

_logger = logging.getLogger(__name__)

_original_execute = _OriginalCursorWrapper.execute

def _guarded_execute(self, sql, params=None):
    """Execute raw SQL only on PostgreSQL backend; skip otherwise.
    This prevents OperationalError on SQLite when PostgreSQL‑specific statements
    like SET search_path or queries against information_schema are executed.
    """
    if getattr(self, "db", None) and getattr(self.db, "vendor", None) == "postgresql":
        return _original_execute(self, sql, params)
    _logger.debug("Skipping PostgreSQL-specific SQL on %s backend", getattr(self.db, "vendor", "unknown"))
    return None

# Monkey‑patch the execute method globally for all cursors
_OriginalCursorWrapper.execute = _guarded_execute

