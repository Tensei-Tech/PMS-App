"""
Safety rules for migrations on the shared database (steps E1 and E4).

E1 - rollbacks: `migrate <app> <earlier migration>` (or `zero`) runs migrations
     backwards, which can drop tables and lose data. On the shared database
     this is refused unless `--allow-rollback` is given (see the migrate command).
     A local or CI database (localhost, SQLite) is never blocked, and `--plan`
     only prints.

E4 - dangerous migrations: every migration of our apps that is not in
     migration_baseline.txt (the migrations that existed and were reviewed when
     this check came) is scanned. One that removes or renames tables or
     columns, or whose SQL / Python deletes, drops or truncates data, fails the
     check (a test, so CI fails) until it says it was reviewed:

         class Migration(migrations.Migration):
             reviewed_dangerous = 'Removes 18 empty rows; checked on a copy'

     python manage.py check_migration_safety lists what it finds.
"""
import inspect
import re
from pathlib import Path

from django.db import migrations

BASELINE_FILE = Path(__file__).with_name('migration_baseline.txt')
OUR_APPS_PREFIX = 'apps.'

LOCAL_HOSTS = ('', 'localhost', '127.0.0.1', '::1', 'postgres', 'db')

DANGEROUS_OPERATIONS = {
    migrations.DeleteModel: 'drops a table',
    migrations.RemoveField: 'drops a column',
    migrations.RenameModel: 'renames a table (old code breaks)',
    migrations.RenameField: 'renames a column (old code breaks)',
}
DANGEROUS_TEXT = re.compile(
    r'\b(DROP\s+(TABLE|COLUMN|SCHEMA|INDEX)|TRUNCATE|DELETE\s+FROM|ALTER\s+TABLE\s+\S+\s+DROP)\b|\.delete\(\)',
    re.IGNORECASE)


# ---------------------------------------------------------------- E1: rollbacks

def is_shared_database(connection):
    """True for a database other people use: PostgreSQL on a host that is not this machine."""
    if connection.vendor != 'postgresql':
        return False
    host = str(connection.settings_dict.get('HOST') or '').strip().lower()
    return host not in LOCAL_HOSTS


def rollback_plan(executor, app_label, migration_name):
    """The migrations `migrate app_label migration_name` would run backwards (empty when going forwards)."""
    if not (app_label and migration_name):
        return []
    if migration_name == 'zero':
        # every applied migration of the app would be undone
        applied = sorted(k for k in executor.loader.applied_migrations if k[0] == app_label)
        return [executor.loader.graph.nodes[k] for k in applied if k in executor.loader.graph.nodes]
    else:
        migration = executor.loader.get_migration_by_prefix(app_label, migration_name)
        targets = [(app_label, migration.name)]
    return [m for m, backwards in executor.migration_plan(targets) if backwards]


# ---------------------------------------------------------------- E4: dangerous migrations

def _key(app_label, name):
    return f'{app_label}.{name}'


def read_baseline():
    if not BASELINE_FILE.exists():
        return set()
    return {line.strip() for line in BASELINE_FILE.read_text(encoding='utf-8').splitlines()
            if line.strip() and not line.startswith('#')}


def _our_migrations(loader):
    from django.apps import apps
    ours = {a.label for a in apps.get_app_configs() if a.name.startswith(OUR_APPS_PREFIX)}
    return {key: m for key, m in loader.disk_migrations.items() if key[0] in ours}


def _text_of(op):
    if isinstance(op, migrations.RunSQL):
        sql = op.sql if isinstance(op.sql, (list, tuple)) else [op.sql]
        return ' '.join(s if isinstance(s, str) else str(s[0] if isinstance(s, (list, tuple)) else s) for s in sql)
    if isinstance(op, migrations.RunPython):
        try:
            return inspect.getsource(op.code)
        except (OSError, TypeError):
            return ''
    return ''


def _operations(ops):
    for op in ops:
        if isinstance(op, migrations.SeparateDatabaseAndState):
            yield from _operations(op.database_operations)
        else:
            yield op


def migration_problems(migration):
    """Reasons a migration is dangerous (empty when it is not)."""
    reasons = []
    for op in _operations(migration.operations):
        for kind, why in DANGEROUS_OPERATIONS.items():
            if isinstance(op, kind):
                reasons.append(f'{type(op).__name__}: {why}')
        text = _text_of(op)
        if text:
            for match in sorted({m.group(0).strip().upper() for m in DANGEROUS_TEXT.finditer(text)}):
                reasons.append(f'{type(op).__name__} contains {match}')
    return reasons


def unreviewed_dangerous_migrations(loader=None):
    """[(app.name, [reasons])] for new migrations that are dangerous and not marked reviewed."""
    if loader is None:
        from django.db.migrations.loader import MigrationLoader
        loader = MigrationLoader(None, ignore_no_migrations=True)  # files on disk only, no database
    baseline = read_baseline()
    found = []
    for (app_label, name), migration in sorted(_our_migrations(loader).items()):
        if _key(app_label, name) in baseline or getattr(migration, 'reviewed_dangerous', None):
            continue
        reasons = migration_problems(migration)
        if reasons:
            found.append((_key(app_label, name), reasons))
    return found


def write_baseline(loader):
    """Write every current migration of our apps as reviewed (done once, when this check came)."""
    keys = sorted(_key(*key) for key in _our_migrations(loader))
    BASELINE_FILE.write_text(
        '# Migrations that existed when the dangerous-migration check came (17 Nov 2026).\n'
        '# Do not add new ones here: mark a reviewed migration with reviewed_dangerous instead.\n'
        + '\n'.join(keys) + '\n', encoding='utf-8')
    return len(keys)
