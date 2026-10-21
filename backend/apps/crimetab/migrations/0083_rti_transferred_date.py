from django.db import migrations, models

"""
Migration 0083: RTI "Transfer Date"

1. RTI Form field "Transfer Date" (rti_transferred_date, optional), right after
   "Transfer To", shown only when Outcome = Transferred.
2. rti_applications gets transferred_date DATE in every schema that has the table.

Idempotent. Existing applications start with the column empty.
"""

TEMPLATE_NAME = 'RTI Form'
FIELD_KEY = 'rti_transferred_date'


def add_field(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    transfer_to = FieldTemplateField.objects.filter(template=tmpl, field_key='rti_transferred_to').first()
    FieldTemplateField.objects.get_or_create(
        template=tmpl,
        field_key=FIELD_KEY,
        defaults={
            'field_label': 'Transfer Date',
            'field_source': transfer_to.field_source if transfer_to else 'custom',
            'field_type': 'date',
            'is_required': False,
            'section': transfer_to.section if transfer_to else None,
            'display_order': (transfer_to.display_order + 5) if transfer_to else 175,
            'depends_on_field_key': transfer_to.depends_on_field_key if transfer_to else 'rti_outcome',
            'depends_on_value': transfer_to.depends_on_value if transfer_to else 'Transferred',
        },
    )


def remove_field(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME, field_key=FIELD_KEY).delete()


def add_column(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build the column from the model
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'rti_applications'"
        )
        for (schema,) in cursor.fetchall():
            cursor.execute(
                f'ALTER TABLE "{schema}".rti_applications ADD COLUMN IF NOT EXISTS transferred_date DATE'
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0082_rti_rename_outcome_section'),
    ]

    operations = [
        migrations.RunPython(add_field, reverse_code=remove_field),
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_column, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(model_name='rtiapplication', name='transferred_date',
                                    field=models.DateField(blank=True, null=True)),
            ],
        ),
    ]
