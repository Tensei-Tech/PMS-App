from django.db import migrations

"""
Migration 0177: remove empty road_accident_records rows of non-accident cases

Saving any case whose form had an acc_-prefixed key (the Common Form's accused
fields) or a generic deceased / injured / vehicles list created a
road_accident_records row, even for Tadipar, Murder or Rape cases. Those rows
hold no answer at all. The save code no longer creates them (see
_save_road_accident_child_entities); this removes the ones already there.

A row is removed only when ALL of these hold:
- every answer column is empty and it has no vehicle / injured / deceased row,
- its case is not in a Road Accident tab (Road Accident, Death Due to Rash
  Driving, Other Road Accident) and is not module road_accident.
Shared database when written: 18 rows (Tadipar 14, Rape 3, Murder 1). Not
reversible: the rows held nothing.
"""

ROAD_TABS = ('road accident', 'death due to rash driving', 'other road accident')
ANSWER_COLUMNS = ('nature_of_accident', 'nature_of_accident_other', 'vehicle_abandoned',
                  'driver_subsequently_traced', 'victim_identity_established', 'eye_witnesses_identity',
                  'irad', 'irad_date', 'dar', 'dar_date', 'accident_datetime', 'accident_spot')
SKIP_SCHEMAS = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'vault',
                'extensions', 'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations',
                'net', 'cron', 'pgbouncer', 'pgsodium', 'pgsodium_masks')


def forwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("""SELECT table_schema FROM information_schema.tables
                          WHERE table_name = 'road_accident_records' AND NOT (table_schema = ANY(%s))""",
                       [list(SKIP_SCHEMAS)])
        for (schema,) in cursor.fetchall():
            cursor.execute("""SELECT 1 FROM information_schema.tables
                              WHERE table_schema = %s AND table_name = 'cases_caserecord'""", [schema])
            cases = f'"{schema}".cases_caserecord' if cursor.fetchone() else 'public.cases_caserecord'
            empty = ' AND '.join(f"(r.{c} IS NULL OR r.{c}::text = '')" for c in ANSWER_COLUMNS)
            children = ' AND '.join(
                f'NOT EXISTS (SELECT 1 FROM "{schema}".{t} x WHERE x.accident_record_id = r.id)'
                for t in ('road_accident_vehicles', 'road_accident_injured', 'road_accident_deceased'))
            cursor.execute(f"""
                DELETE FROM "{schema}".road_accident_records r
                USING {cases} c
                WHERE c.id = r.case_id
                  AND {empty} AND {children}
                  AND lower(coalesce(c.module_key, '')) <> 'road_accident'
                  AND NOT (lower(trim(coalesce(c.sub_category, ''))) = ANY(%s))
            """, [list(ROAD_TABS)])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0176_typed_datetimes_to_india_time'),
    ]

    operations = [
        migrations.RunPython(forwards, migrations.RunPython.noop),
    ]
