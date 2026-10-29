from django.db import migrations

"""
Migration 0133: tenant module tables and id sequences (fresh databases)

1. The RTI / History Sheeter / MPDA / N.C. tenant migrations only create their
   tables in tenant schemas that are already registered. On a fresh database
   (CI, a new AWS server) no state is registered yet, so the 'maharashtra'
   schema ended up without them. This creates any missing ones in every tenant
   schema, with the same DDL used when a state is provisioned. Existing tables
   are left alone (CREATE TABLE IF NOT EXISTS).

2. Several data migrations insert rows with explicit ids (e.g. case_categories),
   which leaves the id sequence behind and makes the next normal insert fail with
   a duplicate key. Every sequence of a table in public or a state schema is moved
   up to the highest id in its table; a sequence is never moved down. Other
   schemas (Supabase's auth, storage, ...) are not touched.

3. field_templates.store_values_in_table (added by 0101 through Django) gets a
   database default of FALSE, so raw-SQL seeds that do not name it still work.

PostgreSQL only; nothing to undo.
"""

SYSTEM_SCHEMAS = (
    'public', 'information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime',
    'graphql', 'graphql_public', 'vault', 'supabase_functions', 'supabase_migrations',
    'extensions', 'cron', 'net', '_analytics', '_realtime', 'pgbouncer',
)

# Run with one parameter (%s): the schemas whose sequences are synced (public +
# state schemas). format() placeholders are written %%I / %%L for that reason.
SQL_SYNC_SEQUENCES = """
DO $$
DECLARE
    r RECORD;
    max_id BIGINT;
BEGIN
    FOR r IN
        SELECT seq_ns.nspname AS seq_schema, seq.relname AS seq_name,
               tbl_ns.nspname AS tbl_schema, tbl.relname AS tbl_name, att.attname AS col_name
        FROM pg_class seq
        JOIN pg_namespace seq_ns ON seq_ns.oid = seq.relnamespace
        JOIN pg_depend dep ON dep.objid = seq.oid AND dep.deptype IN ('a', 'i')
        JOIN pg_class tbl ON tbl.oid = dep.refobjid
        JOIN pg_namespace tbl_ns ON tbl_ns.oid = tbl.relnamespace
        JOIN pg_attribute att ON att.attrelid = tbl.oid AND att.attnum = dep.refobjsubid
        WHERE seq.relkind = 'S'
          AND tbl_ns.nspname = ANY(%s)
    LOOP
        EXECUTE format('SELECT MAX(%%I) FROM %%I.%%I', r.col_name, r.tbl_schema, r.tbl_name) INTO max_id;
        IF max_id IS NOT NULL THEN
            EXECUTE format(
                'SELECT setval(%%L, GREATEST(%%s, (SELECT last_value FROM %%I.%%I)))',
                quote_ident(r.seq_schema) || '.' || quote_ident(r.seq_name), max_id, r.seq_schema, r.seq_name
            );
        END IF;
    END LOOP;
END $$;
"""


def tenant_schemas(cursor):
    cursor.execute(
        """
        SELECT DISTINCT table_schema FROM information_schema.tables
        WHERE table_name IN ('users_officerprofile', 'road_accident_records')
        UNION
        SELECT schema_name FROM public.states WHERE is_active = TRUE AND schema_name IS NOT NULL
        """
    )
    names = {row[0] for row in cursor.fetchall()}
    return sorted(n for n in names if n and n not in SYSTEM_SCHEMAS and not n.startswith('pg_'))


def forwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    from apps.core.tenancy import create_module_tables
    with schema_editor.connection.cursor() as cursor:
        for schema in tenant_schemas(cursor):
            cursor.execute(f'CREATE SCHEMA IF NOT EXISTS "{schema}";')
            create_module_tables(cursor, schema)
        cursor.execute(SQL_SYNC_SEQUENCES, [['public'] + tenant_schemas(cursor)])
        cursor.execute(
            'ALTER TABLE public.field_templates ALTER COLUMN store_values_in_table SET DEFAULT FALSE'
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0132_surety_relation_options'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=migrations.RunPython.noop),
    ]
