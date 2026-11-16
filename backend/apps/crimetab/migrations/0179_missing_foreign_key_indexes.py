from django.db import migrations

"""
Migration 0179: two foreign keys without an index

- nc_preventive_actions.person_id: only (nc_id, person_id) was indexed, so a
  lookup by person alone (deleting a person, listing their actions) scanned
  the table. New states get it from apps/crimetab/nc_schema.py.
- crime_case_acts_sections.subsection_id: the model's index was missing in the
  state schema.
CREATE INDEX IF NOT EXISTS in every schema that has the table; no data changes.
"""

INDEXES = (
    ('nc_preventive_actions', 'person_id', 'nc_prev_person_idx'),
    ('crime_case_acts_sections', 'subsection_id', 'crime_case_acts_sections_subsection_idx'),
)
SKIP = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'vault', 'extensions',
        'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations', 'net', 'cron', 'pgbouncer',
        'pgsodium', 'pgsodium_masks')


def forwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        for table, column, name in INDEXES:
            cursor.execute("""SELECT c.table_schema FROM information_schema.columns c
                              WHERE c.table_name = %s AND c.column_name = %s AND NOT (c.table_schema = ANY(%s))""",
                           [table, column, list(SKIP)])
            for (schema,) in cursor.fetchall():
                cursor.execute(f'CREATE INDEX IF NOT EXISTS {name} ON "{schema}".{table} ({column})')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0178_primary_keys_and_duplicate_unknown_accused'),
    ]

    operations = [
        migrations.RunPython(forwards, migrations.RunPython.noop),
    ]
