from django.db import migrations, models

"""
Migration 0134: Accused - Medical (Yes / No) and Medical Date

Two nullable columns on cases_person. The table lives in a state schema on a
running database (e.g. maharashtra) and in public on a fresh one, so the columns
are added in every schema that has it. Idempotent (ADD COLUMN IF NOT EXISTS).
"""


def add_columns(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SELECT table_schema FROM information_schema.tables WHERE table_name = 'cases_person'")
        for (schema,) in cursor.fetchall():
            cursor.execute(
                f'ALTER TABLE "{schema}".cases_person '
                'ADD COLUMN IF NOT EXISTS medical VARCHAR(10), '
                'ADD COLUMN IF NOT EXISTS medical_date DATE'
            )


def drop_columns(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SELECT table_schema FROM information_schema.tables WHERE table_name = 'cases_person'")
        for (schema,) in cursor.fetchall():
            cursor.execute(
                f'ALTER TABLE "{schema}".cases_person '
                'DROP COLUMN IF EXISTS medical, DROP COLUMN IF EXISTS medical_date'
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0133_tenant_module_tables_and_id_sequences'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[migrations.RunPython(add_columns, reverse_code=drop_columns)],
            state_operations=[
                migrations.AddField(
                    model_name='casesperson',
                    name='medical',
                    field=models.CharField(blank=True, max_length=10, null=True),
                ),
                migrations.AddField(
                    model_name='casesperson',
                    name='medical_date',
                    field=models.DateField(blank=True, null=True),
                ),
            ],
        ),
    ]
