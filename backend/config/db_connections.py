"""
How long Django keeps a database connection open for reuse (CONN_MAX_AGE).

Opening a connection to Supabase costs several network round trips (TCP, TLS,
login); with CONN_MAX_AGE=0 every request paid that. Reuse is safe on the
session pooler (port 5432) or a direct connection, where a client keeps its
own server session. On the transaction pooler (port 6543) consecutive queries
can land on different server sessions, so a SET search_path made for one
tenant could apply to another tenant's queries: reuse is forced off there.
"""
import os
import sys

DEFAULT_CONN_MAX_AGE = 60
TRANSACTION_POOLER_PORT = '6543'


def conn_max_age_for(port, env=None):
    """Seconds to keep a connection open, from DB_CONN_MAX_AGE (default 60)."""
    env = os.environ if env is None else env
    raw = str(env.get('DB_CONN_MAX_AGE', DEFAULT_CONN_MAX_AGE)).strip()
    try:
        age = max(int(raw), 0)
    except ValueError:
        sys.stderr.write(f"DB_CONN_MAX_AGE={raw!r} is not a whole number; using {DEFAULT_CONN_MAX_AGE}\n")
        age = DEFAULT_CONN_MAX_AGE
    if age and str(port).strip() == TRANSACTION_POOLER_PORT:
        sys.stderr.write(
            "Database port 6543 is Supabase's transaction pooler; connection reuse is "
            "turned off to keep tenant search_path isolated. Use the session pooler "
            "(port 5432) for faster requests.\n"
        )
        return 0
    return age


def apply_conn_max_age(databases, env=None):
    """Set CONN_MAX_AGE on every PostgreSQL database in a DATABASES dict."""
    for db in databases.values():
        if db.get('ENGINE') == 'django.db.backends.postgresql':
            db['CONN_MAX_AGE'] = conn_max_age_for(db.get('PORT'), env)
    return databases
