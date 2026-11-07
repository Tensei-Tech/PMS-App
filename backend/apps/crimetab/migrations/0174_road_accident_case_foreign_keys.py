import django.db.models.deletion
from django.db import migrations, models

"""
Migration 0174: road accident rows linked to their case by a real foreign key

`case_id` on road_accident_records / _vehicles / _injured / _deceased was plain
text: the database did not check that the case exists, deleting a case left the
accident rows behind, and one case could get two accident records.

In every state schema that has the tables, this:
1. clears `case_id` where it is empty or names no existing case (none on the
   shared database when this was written), so the foreign keys can be added;
2. stops with a clear error if one case has two accident records (none either);
3. adds FOREIGN KEY (case_id) -> cases_caserecord(id) ON DELETE CASCADE on all
   four tables, and UNIQUE (case_id) on road_accident_records (one per case),
   replacing its plain case_id index.

The column keeps its name and type, so `case_id` in code and the API is
unchanged. Idempotent; backwards removes the constraints again.
"""

TABLES = ('road_accident_records', 'road_accident_vehicles', 'road_accident_injured', 'road_accident_deceased')
SYSTEM_SCHEMAS = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime',
                  'vault', 'extensions', 'graphql', 'graphql_public', 'supabase_functions',
                  'supabase_migrations', 'net', 'cron', 'pgbouncer', 'pgsodium', 'pgsodium_masks')


def fk_name(table):
    return f'{table}_case_id_fk'


UNIQUE_NAME = 'road_accident_records_case_id_uniq'


def schemas_with_tables(cursor):
    """State schemas holding both the accident and the case tables."""
    cursor.execute("""
        SELECT table_schema FROM information_schema.tables
        WHERE table_name IN ('road_accident_records', 'cases_caserecord')
          AND NOT (table_schema = ANY(%s))
        GROUP BY table_schema HAVING COUNT(DISTINCT table_name) = 2
        ORDER BY table_schema
    """, [list(SYSTEM_SCHEMAS)])
    return [r[0] for r in cursor.fetchall()]


def has_table(cursor, schema, table):
    cursor.execute("SELECT 1 FROM information_schema.tables WHERE table_schema=%s AND table_name=%s",
                   [schema, table])
    return cursor.fetchone() is not None


def has_constraint(cursor, schema, table, name):
    cursor.execute("""
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname=%s AND t.relname=%s AND c.conname=%s
    """, [schema, table, name])
    return cursor.fetchone() is not None


def forwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # tests build these tables straight from the models
    with schema_editor.connection.cursor() as cursor:
        for schema in schemas_with_tables(cursor):
            cases = f'"{schema}".cases_caserecord'
            tables = [t for t in TABLES if has_table(cursor, schema, t)]

            # 1. ids that point nowhere cannot carry a foreign key
            for table in tables:
                cursor.execute(f"""
                    UPDATE "{schema}".{table} x SET case_id = NULL
                    WHERE x.case_id IS NOT NULL
                      AND NOT EXISTS (SELECT 1 FROM {cases} c WHERE c.id = x.case_id)
                """)

            # 2. one accident record per case
            cursor.execute(f"""
                SELECT case_id, COUNT(*) FROM "{schema}".road_accident_records
                WHERE case_id IS NOT NULL GROUP BY case_id HAVING COUNT(*) > 1
            """)
            duplicates = cursor.fetchall()
            if duplicates:
                raise RuntimeError(
                    f'{schema}.road_accident_records has more than one record for these cases: '
                    f'{duplicates}. Merge or delete the extra rows, then run migrate again.'
                )

            # 3. constraints
            for table in tables:
                if not has_constraint(cursor, schema, table, fk_name(table)):
                    cursor.execute(f"""
                        ALTER TABLE "{schema}".{table} ADD CONSTRAINT {fk_name(table)}
                        FOREIGN KEY (case_id) REFERENCES {cases}(id)
                        ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
                    """)
            if not has_constraint(cursor, schema, 'road_accident_records', UNIQUE_NAME):
                cursor.execute(f'ALTER TABLE "{schema}".road_accident_records '
                               f'ADD CONSTRAINT {UNIQUE_NAME} UNIQUE (case_id)')
            # the unique constraint's index replaces the plain one from 0056
            cursor.execute(f'DROP INDEX IF EXISTS "{schema}".road_acc_case_idx')


def backwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        for schema in schemas_with_tables(cursor):
            for table in TABLES:
                if has_table(cursor, schema, table):
                    cursor.execute(f'ALTER TABLE "{schema}".{table} DROP CONSTRAINT IF EXISTS {fk_name(table)}')
            cursor.execute(f'ALTER TABLE "{schema}".road_accident_records DROP CONSTRAINT IF EXISTS {UNIQUE_NAME}')
            cursor.execute(f'CREATE INDEX IF NOT EXISTS road_acc_case_idx '
                           f'ON "{schema}".road_accident_records (case_id)')


def child_case_field():
    return models.ForeignKey(
        blank=True, null=True, db_column='case_id', related_name='+',
        on_delete=django.db.models.deletion.CASCADE, to='cases.caserecord',
    )


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0006_caserecord_disposal_date'),
        ('crimetab', '0173_ad_deceased_person_list'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            # Tables live only in state schemas, so the SQL is run per schema above
            database_operations=[migrations.RunPython(forwards, backwards)],
            state_operations=[
                migrations.RemoveField(model_name='roadaccidentrecord', name='case_id'),
                migrations.AddField(
                    model_name='roadaccidentrecord',
                    name='case',
                    field=models.OneToOneField(
                        blank=True, null=True, db_column='case_id', related_name='road_accident',
                        on_delete=django.db.models.deletion.CASCADE, to='cases.caserecord',
                    ),
                ),
                migrations.RemoveField(model_name='roadaccidentvehicle', name='case_id'),
                migrations.AddField(model_name='roadaccidentvehicle', name='case', field=child_case_field()),
                migrations.RemoveField(model_name='roadaccidentinjured', name='case_id'),
                migrations.AddField(model_name='roadaccidentinjured', name='case', field=child_case_field()),
                migrations.RemoveField(model_name='roadaccidentdeceased', name='case_id'),
                migrations.AddField(model_name='roadaccidentdeceased', name='case', field=child_case_field()),
            ],
        ),
    ]
