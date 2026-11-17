import json
from datetime import datetime

from django.db import migrations, models

"""
Migration 0190: Sam/Warrant issue_date, Licence received_date and Passport/PVR
verification_date keep the time

The app sends both as date and time ("2026-11-05T16:24:41.282"); the tables
kept only the day, so the time existed only in the case JSON. Both columns
become timestamp with time zone in every schema that has the table (a day
becomes midnight India time), and the time is copied back from the JSON. Step 1
of removing the service-tab JSON copies: afterwards the tables hold every answer.
"""

SKIP = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'vault', 'extensions',
        'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations', 'net', 'cron', 'pgbouncer',
        'pgsodium', 'pgsodium_masks')

# table, column, JSON keys the save reads (top level, first non-empty wins)
COLUMNS = (
    ('sam_warrant_records', 'issue_date', ('issue_date', 'issueDate')),
    ('licence_records', 'received_date', ('received_date', 'receivedDate')),
    ('passport_pvr_records', 'verification_date', ('verification_date', 'verificationDate')),
)


def _moment(text):
    """The app's ISO text with its time (India time when it has no zone); None otherwise."""
    text = str(text or '').strip()
    if not text:
        return None
    try:
        parsed = datetime.fromisoformat(text.replace('Z', '+00:00'))
    except ValueError:
        return None  # a day alone (05/11/2026) is already midnight from the ALTER
    if parsed.tzinfo is None:
        from zoneinfo import ZoneInfo
        parsed = parsed.replace(tzinfo=ZoneInfo('Asia/Kolkata'))
    return parsed


def forwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        for table, column, keys in COLUMNS:
            cursor.execute("""SELECT c.table_schema, c.data_type FROM information_schema.columns c
                              WHERE c.table_name = %s AND c.column_name = %s
                                AND NOT (c.table_schema = ANY(%s))""", [table, column, list(SKIP)])
            for schema, data_type in cursor.fetchall():
                if data_type == 'date':
                    cursor.execute(f'ALTER TABLE "{schema}".{table} ALTER COLUMN {column} TYPE timestamp with time zone '
                                   f"USING ({column}::timestamp AT TIME ZONE 'Asia/Kolkata')")
                cursor.execute(f'''SELECT r.case_id, c.extra_fields FROM "{schema}".{table} r
                                   JOIN "{schema}".cases_caserecord c ON c.id = r.case_id''')
                fixed = 0
                for case_id, extra in cursor.fetchall():
                    if isinstance(extra, (str, bytes)):
                        extra = json.loads(extra)  # the driver gives jsonb as text
                    extra = extra if isinstance(extra, dict) else {}
                    raw = next((extra[k] for k in keys if extra.get(k) not in (None, '')), None)
                    moment = _moment(raw)
                    if moment is not None:
                        cursor.execute(f'UPDATE "{schema}".{table} SET {column} = %s WHERE case_id = %s '
                                       f'AND {column} IS DISTINCT FROM %s', [moment, case_id, moment])
                        fixed += cursor.rowcount
                if fixed:
                    print(f'  0190: {schema}.{table}: time added to {fixed} {column} value(s)')


def backwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        for table, column, _keys in COLUMNS:
            cursor.execute("""SELECT table_schema FROM information_schema.columns
                              WHERE table_name = %s AND column_name = %s AND data_type <> 'date'
                                AND NOT (table_schema = ANY(%s))""", [table, column, list(SKIP)])
            for (schema,) in cursor.fetchall():
                cursor.execute(f'ALTER TABLE "{schema}".{table} ALTER COLUMN {column} TYPE date '
                               f"USING (({column} AT TIME ZONE 'Asia/Kolkata')::date)")


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0189_part6_cases_module_and_mpda_short_year'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AlterField(model_name='samwarrantrecord', name='issue_date',
                                      field=models.DateTimeField(blank=True, null=True)),
                migrations.AlterField(model_name='licencerecord', name='received_date',
                                      field=models.DateTimeField(blank=True, null=True)),
                migrations.AlterField(model_name='passportpvrrecord', name='verification_date',
                                      field=models.DateTimeField(blank=True, null=True)),
            ],
            database_operations=[migrations.RunPython(forwards, backwards)],
        ),
    ]
