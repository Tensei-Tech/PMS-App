from django.db import migrations, models

"""
Migration 0061: Common Form additions

1. Three Yes/No fields in a new section "Investigation Steps" of the
   "Common Form Baseline Template" (shown after "All Panchnama"):
   Vehicle Log Book Entry, Witness Summons, Mobile Spot Recording.
   Options come from the existing option group 'yes_no'. Every field optional.
2. preventive_action_items.preventive_number (VARCHAR(100), NULL) in every
   tenant schema that has the table, plus the matching model field.

Idempotent. Nothing existing is changed or deleted.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
SECTION = 'Investigation Steps'
YES_NO_SOURCE = '/api/options/yes_no/'

# (field_label, field_key, display_order) — between All Panchnama (730-790) and Evidence (800)
FIELDS = [
    ('Vehicle Log Book Entry', 'vehicle_log_book_entry', 791),
    ('Witness Summons', 'witness_summons', 792),
    ('Mobile Spot Recording', 'mobile_spot_recording', 793),
]


def add_fields(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    for label, key, order in FIELDS:
        FieldTemplateField.objects.get_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': 'radio',
                'is_required': False,
                'section': SECTION,
                'display_order': order,
                'options_source': YES_NO_SOURCE,
            },
        )


def remove_fields(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key__in=[k for _, k, _ in FIELDS]
    ).delete()


def add_preventive_number_column(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build the column from the model
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'preventive_action_items'"
        )
        for (schema,) in cursor.fetchall():
            cursor.execute(
                f'ALTER TABLE "{schema}".preventive_action_items '
                'ADD COLUMN IF NOT EXISTS preventive_number VARCHAR(100)'
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0060_nc_preventive_number_label'),
    ]

    operations = [
        migrations.RunPython(add_fields, reverse_code=remove_fields),
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_preventive_number_column, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='preventiveactionitems',
                    name='preventive_number',
                    field=models.CharField(blank=True, max_length=100, null=True),
                ),
            ],
        ),
    ]
