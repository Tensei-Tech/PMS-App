from django.db import migrations

"""
Migration 0178: missing primary keys, and repeated unknown accused

1. crime_case_responsibility and crime_spot had no primary key in the state
   schemas, though the models treat case_id as one (one row per case). Each
   gets PRIMARY KEY (case_id) when it has none and case_id is unique and
   filled; otherwise the table is left as it is and a notice is printed.
2. public.acts_import (an empty import table nothing uses) gets an id column
   as its primary key.
3. Saving a case added its "Unknown Accused" / unidentified rows again every
   time (one case had 4). Repeats are removed, keeping the first row, and
   only rows nothing points at (arrest, remand, discharge, preventive action,
   seizure) are removed. The save code now adds each once.
Going back changes nothing: the keys may predate this migration on a fresh
database, and the removed rows were copies.
"""

SKIP = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'vault', 'extensions',
        'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations', 'net', 'cron', 'pgbouncer',
        'pgsodium', 'pgsodium_masks')
ONE_PER_CASE = ('crime_case_responsibility', 'crime_spot')
PERSON_REFERENCES = (
    ('arrest_release_status', 'person_id'), ('discharge_status', 'person_id'),
    ('preventive_action_items', 'person_id'), ('remand_custody', 'person_id'),
    ('seizure_records', 'seized_from_person_id'),
)


def schemas_with(cursor, table):
    cursor.execute("""SELECT table_schema FROM information_schema.tables
                      WHERE table_name = %s AND NOT (table_schema = ANY(%s))""", [table, list(SKIP)])
    return [r[0] for r in cursor.fetchall()]


def has_primary_key(cursor, schema, table):
    cursor.execute("""SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
                      JOIN pg_namespace n ON n.oid = t.relnamespace
                      WHERE n.nspname = %s AND t.relname = %s AND c.contype = 'p'""", [schema, table])
    return cursor.fetchone() is not None


def has_table(cursor, schema, table):
    cursor.execute('SELECT 1 FROM information_schema.tables WHERE table_schema = %s AND table_name = %s',
                   [schema, table])
    return cursor.fetchone() is not None


def forwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        # 1. one row per case: case_id becomes the primary key
        for table in ONE_PER_CASE:
            for schema in schemas_with(cursor, table):
                if has_primary_key(cursor, schema, table):
                    continue
                cursor.execute(f'SELECT count(*) - count(DISTINCT case_id), count(*) FILTER (WHERE case_id IS NULL) '
                               f'FROM "{schema}".{table}')
                repeats, empty = cursor.fetchone()
                if repeats or empty:
                    print(f'  0178: {schema}.{table} left without a primary key '
                          f'({repeats} repeated, {empty} empty case_id)')
                    continue
                cursor.execute(f'ALTER TABLE "{schema}".{table} ADD CONSTRAINT {table}_pkey PRIMARY KEY (case_id)')

        # 2. the import table gets an id
        for schema in schemas_with(cursor, 'acts_import'):
            if not has_primary_key(cursor, schema, 'acts_import'):
                cursor.execute(f'ALTER TABLE "{schema}".acts_import ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY')

        # 3. repeated unknown / unidentified accused, nothing pointing at them
        for schema in schemas_with(cursor, 'cases_person'):
            in_use = ' AND '.join(
                f'NOT EXISTS (SELECT 1 FROM "{schema}".{t} r WHERE r.{col} = p.person_id)'
                for t, col in PERSON_REFERENCES if has_table(cursor, schema, t))
            cursor.execute(f"""
                DELETE FROM "{schema}".cases_person p
                USING "{schema}".cases_person keep
                WHERE p.role IN ('unknown_accused', 'unidentified')
                  AND keep.case_id = p.case_id AND keep.role = p.role
                  AND keep.name IS NOT DISTINCT FROM p.name
                  AND keep.approximate_age IS NOT DISTINCT FROM p.approximate_age
                  AND keep.gender IS NOT DISTINCT FROM p.gender
                  AND keep.description IS NOT DISTINCT FROM p.description
                  AND keep.person_id < p.person_id
                  {'AND ' + in_use if in_use else ''}
            """)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0177_remove_empty_accident_rows_of_other_cases'),
    ]

    operations = [
        migrations.RunPython(forwards, migrations.RunPython.noop),
    ]
