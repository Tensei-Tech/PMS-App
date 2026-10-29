from django.db import migrations, models

"""
Migration 0068: History Sheeter Crime Chart — Act, Section and Subsection from the Acts master

1. Field hs_crime_act_section (History Sheeter Template) becomes the 'charges'
   picker (Act / Section / Subsection dropdowns from /api/acts/,
   /api/act-sections/, /api/act-subsections/), one charge per Crime Chart row.
2. history_sheeter_crimes gets act_id, section_id, subsection_id (BIGINT, no FK)
   and act_name, section_number, section_title, subsection_code (TEXT copies) in
   every schema that has the table. act_section stays and holds the combined text.

Idempotent. Existing rows are unchanged (their act_section text is kept).
"""

TEMPLATE_NAME = 'History Sheeter Template'
FIELD_KEY = 'hs_crime_act_section'
NEW = ('charges', 'Act / Section / Subsection')
OLD = ('text', 'Act and Section')

COLUMNS = [
    ('act_id', 'BIGINT'), ('section_id', 'BIGINT'), ('subsection_id', 'BIGINT'),
    ('act_name', 'TEXT'), ('section_number', 'TEXT'), ('section_title', 'TEXT'),
    ('subsection_code', 'TEXT'),
]


def _set_field(apps, field_type, label):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=FIELD_KEY
    ).update(field_type=field_type, field_label=label)


def forwards(apps, schema_editor):
    _set_field(apps, *NEW)


def backwards(apps, schema_editor):
    _set_field(apps, *OLD)


def add_columns(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build the columns from the model
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'history_sheeter_crimes'"
        )
        for (schema,) in cursor.fetchall():
            adds = ', '.join(f'ADD COLUMN IF NOT EXISTS {col} {typ}' for col, typ in COLUMNS)
            cursor.execute(f'ALTER TABLE "{schema}".history_sheeter_crimes {adds}')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0067_hs_preventive_action_multi_select'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_columns, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(model_name='historysheetercrime', name='act_id',
                                    field=models.BigIntegerField(blank=True, null=True)),
                migrations.AddField(model_name='historysheetercrime', name='section_id',
                                    field=models.BigIntegerField(blank=True, null=True)),
                migrations.AddField(model_name='historysheetercrime', name='subsection_id',
                                    field=models.BigIntegerField(blank=True, null=True)),
                migrations.AddField(model_name='historysheetercrime', name='act_name',
                                    field=models.TextField(blank=True, null=True)),
                migrations.AddField(model_name='historysheetercrime', name='section_number',
                                    field=models.TextField(blank=True, null=True)),
                migrations.AddField(model_name='historysheetercrime', name='section_title',
                                    field=models.TextField(blank=True, null=True)),
                migrations.AddField(model_name='historysheetercrime', name='subsection_code',
                                    field=models.TextField(blank=True, null=True)),
            ],
        ),
    ]
