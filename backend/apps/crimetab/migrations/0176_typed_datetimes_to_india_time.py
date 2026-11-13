import datetime
import json

from django.db import migrations

"""
Migration 0176: typed date-times saved before the timezone fix, moved to Indian time

Until now settings.TIME_ZONE was UTC, so a time typed in the app ("07/10/2026
20:41", Indian time) was stored as 20:41 UTC, 5 h 30 min late. From this
release TIME_ZONE is Asia/Kolkata and new values are stored correctly. This
corrects the values already stored, once:

1. Columns only ever filled from typed text: moved back 5 h 30 min.
     road_accident_records.accident_datetime
     arrest_release_status.arrest_datetime / release_on_notice_datetime /
                           anticipatory_bail_datetime / death_of_accused_datetime
     procedural_checklist.event_datetime
     nc_records.occurrence_at
2. Columns that also hold real timestamps (copied from the case's creation
   time): recalculated only where the case JSON still has the typed text, as
   Indian time; other rows are left alone.
     crime_spot.occurrence_datetime        <- occurrence_datetime
     crime_registration_info.registered_datetime <- registered_datetime / regDate

cases_caserecord.incident_date and disposal_date are real timestamps and are not
changed. Every state schema that has the tables is corrected; a fresh database
has no rows, so nothing happens there.
"""

SHIFT = "INTERVAL '5 hours 30 minutes'"
SHIFT_COLUMNS = {
    'road_accident_records': ['accident_datetime'],
    'arrest_release_status': ['arrest_datetime', 'release_on_notice_datetime',
                              'anticipatory_bail_datetime', 'death_of_accused_datetime'],
    'procedural_checklist': ['event_datetime'],
    'nc_records': ['occurrence_at'],
}
RETYPE = {
    # table: (column, JSON keys holding the typed text)
    'crime_spot': ('occurrence_datetime', ('occurrence_datetime',)),
    'crime_registration_info': ('registered_datetime', ('registered_datetime', 'regDate')),
}
SKIP_SCHEMAS = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'vault',
                'extensions', 'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations',
                'net', 'cron', 'pgbouncer', 'pgsodium', 'pgsodium_masks')
FORMATS = ('%d/%m/%Y %H:%M', '%d/%m/%Y %H:%M:%S', '%d/%m/%Y %I:%M %p', '%d/%m/%Y', '%d-%m-%Y %H:%M',
           '%d-%m-%Y %H:%M:%S', '%d-%m-%Y', '%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M', '%Y-%m-%d')
IST = datetime.timezone(datetime.timedelta(hours=5, minutes=30))


def schemas_with(cursor, table):
    cursor.execute("""SELECT table_schema FROM information_schema.tables
                      WHERE table_name = %s AND NOT (table_schema = ANY(%s))""", [table, list(SKIP_SCHEMAS)])
    return [r[0] for r in cursor.fetchall()]


def has_column(cursor, schema, table, column):
    cursor.execute("""SELECT 1 FROM information_schema.columns
                      WHERE table_schema = %s AND table_name = %s AND column_name = %s""", [schema, table, column])
    return cursor.fetchone() is not None


def typed_text(extra, keys):
    """The typed value, top level first, then inside commonForm."""
    if isinstance(extra, str):
        try:
            extra = json.loads(extra)
        except ValueError:
            return None
    if not isinstance(extra, dict):
        return None
    common = extra.get('commonForm') if isinstance(extra.get('commonForm'), dict) else {}
    for src in (extra, common):
        for key in keys:
            value = src.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
    return None


def as_local(text, tz):
    """Typed text without a timezone, read in `tz`. ISO text with an offset is left out."""
    for fmt in FORMATS:
        try:
            return datetime.datetime.strptime(text, fmt).replace(tzinfo=tz)
        except ValueError:
            continue
    return None


def run(schema_editor, direction, tz):
    if schema_editor.connection.vendor != 'postgresql':
        return
    sign = '-' if direction == 'forwards' else '+'
    with schema_editor.connection.cursor() as cursor:
        for table, columns in SHIFT_COLUMNS.items():
            for schema in schemas_with(cursor, table):
                for column in columns:
                    if has_column(cursor, schema, table, column):
                        cursor.execute(f'UPDATE "{schema}".{table} SET {column} = {column} {sign} {SHIFT} '
                                       f'WHERE {column} IS NOT NULL')
        for table, (column, keys) in RETYPE.items():
            for schema in schemas_with(cursor, table):
                # the cases table the state reads: its own, else public's (fresh migrate)
                cursor.execute("""SELECT 1 FROM information_schema.tables
                                  WHERE table_schema = %s AND table_name = 'cases_caserecord'""", [schema])
                cases = f'"{schema}".cases_caserecord' if cursor.fetchone() else 'public.cases_caserecord'
                cursor.execute(f'SELECT t.case_id, c.extra_fields FROM "{schema}".{table} t '
                               f'JOIN {cases} c ON c.id = t.case_id')
                for case_id, extra in cursor.fetchall():
                    text = typed_text(extra, keys)
                    value = as_local(text, tz) if text else None
                    if value is not None:
                        cursor.execute(f'UPDATE "{schema}".{table} SET {column} = %s WHERE case_id = %s',
                                       [value, case_id])


def forwards(apps, schema_editor):
    run(schema_editor, 'forwards', IST)


def backwards(apps, schema_editor):
    run(schema_editor, 'backwards', datetime.timezone.utc)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0175_case_forensics_dates'),
    ]

    operations = [
        migrations.RunPython(forwards, backwards),
    ]
