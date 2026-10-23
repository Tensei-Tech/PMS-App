from django.db import migrations, models

"""
Migration 0098: MPDA Crime Chart — Act, Section and Subsection from the Acts master

1. MPDA Proposal Template gets field mpda_crime_act_section (the 'charges'
   picker: Act / Section / Subsection dropdowns from /api/acts/,
   /api/act-sections/, /api/act-subsections/) in every Crime Chart row, after
   Police Station.
2. mpda_crime_chart_entries gets act_id, section_id, subsection_id (BIGINT, no FK)
   and act_name, section_number, section_title, subsection_code, act_section
   (TEXT copies; act_section is the combined text) in every schema that has the
   table.

Idempotent. Existing rows are unchanged.
"""

TEMPLATE_NAME = 'MPDA Proposal Template'
FIELD_KEY = 'mpda_crime_act_section'
PARENT_KEY = 'mpda_crime_chart'

COLUMNS = [
    ('act_id', 'BIGINT'), ('section_id', 'BIGINT'), ('subsection_id', 'BIGINT'),
    ('act_name', 'TEXT'), ('section_number', 'TEXT'), ('section_title', 'TEXT'),
    ('subsection_code', 'TEXT'), ('act_section', 'TEXT'),
]


def add_field(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    # Same section as the other Crime Chart columns, placed after the last one
    siblings = FieldTemplateField.objects.filter(template=tmpl, parent_field_key=PARENT_KEY)
    last = siblings.exclude(field_key=FIELD_KEY).order_by('-display_order').first()
    FieldTemplateField.objects.get_or_create(
        template=tmpl,
        field_key=FIELD_KEY,
        defaults={
            'field_label': 'Act / Section / Subsection',
            'field_source': 'custom',
            'field_type': 'charges',
            'is_required': False,
            'section': last.section if last else 'Crime Chart',
            'display_order': (last.display_order + 1) if last else 295,
            'parent_field_key': PARENT_KEY,
        },
    )


def remove_field(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=FIELD_KEY
    ).delete()


def add_columns(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build the columns from the model
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'mpda_crime_chart_entries'"
        )
        for (schema,) in cursor.fetchall():
            adds = ', '.join(f'ADD COLUMN IF NOT EXISTS {col} {typ}' for col, typ in COLUMNS)
            cursor.execute(f'ALTER TABLE "{schema}".mpda_crime_chart_entries {adds}')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0097_hs_summary_tab_label_actions_header'),
    ]

    operations = [
        migrations.RunPython(add_field, reverse_code=remove_field),
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_columns, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(model_name='mpdacrimechartentry', name='act_id',
                                    field=models.BigIntegerField(blank=True, null=True)),
                migrations.AddField(model_name='mpdacrimechartentry', name='section_id',
                                    field=models.BigIntegerField(blank=True, null=True)),
                migrations.AddField(model_name='mpdacrimechartentry', name='subsection_id',
                                    field=models.BigIntegerField(blank=True, null=True)),
                migrations.AddField(model_name='mpdacrimechartentry', name='act_name',
                                    field=models.TextField(blank=True, null=True)),
                migrations.AddField(model_name='mpdacrimechartentry', name='section_number',
                                    field=models.TextField(blank=True, null=True)),
                migrations.AddField(model_name='mpdacrimechartentry', name='section_title',
                                    field=models.TextField(blank=True, null=True)),
                migrations.AddField(model_name='mpdacrimechartentry', name='subsection_code',
                                    field=models.TextField(blank=True, null=True)),
                migrations.AddField(model_name='mpdacrimechartentry', name='act_section',
                                    field=models.TextField(blank=True, null=True)),
            ],
        ),
    ]
