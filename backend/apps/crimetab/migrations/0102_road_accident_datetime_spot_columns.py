from django.db import migrations

"""
Migration 0102: Road Accident — columns for "Date & Time of Accident" and
"Accident Spot / Location"

The Road Accident Extra Template (public schema) has the questions
accident_datetime and accident_spot, but road_accident_records had no column
for them, so their answers only lived in the case's extra_fields JSON. Adds
accident_datetime (TIMESTAMPTZ) and accident_spot (TEXT) in every schema that
has the table (raw SQL, like 0056 which created it). Idempotent.
"""

COLUMNS = [('accident_datetime', 'TIMESTAMPTZ'), ('accident_spot', 'TEXT')]


def add_columns(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build the table from the model
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'road_accident_records'"
        )
        for (schema,) in cursor.fetchall():
            adds = ', '.join(f'ADD COLUMN IF NOT EXISTS {col} {typ}' for col, typ in COLUMNS)
            cursor.execute(f'ALTER TABLE "{schema}".road_accident_records {adds}')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0101_theft_template_fields_in_table'),
    ]

    operations = [
        migrations.RunPython(add_columns, reverse_code=migrations.RunPython.noop),
    ]
