from django.db import migrations

"""
Migration 0202: Murder "FSL Report Received" asks for its date (data only)

Ticking FSL Report Received (Murder Section Extra Fields, "Post-Mortem & FSL")
now shows an optional date right after it, like Post-Mortem, Post-Mortem
Report and Viscera Sent to FSL already do (0198): murder_fsl_report_date,
shown while the box is ticked ("Yes|true").

Backwards removes the date field. Idempotent.
"""

TEMPLATE_NAME = 'Murder Section Extra Fields'
SECTION = 'Post-Mortem & FSL'
PARENT = 'murder_fsl_report'
KEY = 'murder_fsl_report_date'
LABEL = 'FSL Report Received Date'
ORDER = 2180
TICKED = 'Yes|true'


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    FieldTemplateField.objects.update_or_create(
        template=tmpl,
        field_key=KEY,
        defaults={
            'field_label': LABEL,
            'field_source': 'custom',
            'field_type': 'date',
            'is_required': False,
            'section': SECTION,
            'display_order': ORDER,
            'options_source': None,
            'depends_on_field_key': PARENT,
            'depends_on_value': TICKED,
        },
    )


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=KEY).delete()


class Migration(migrations.Migration):

    # Backwards deletes only the form-config row this migration adds; no case data
    reviewed_dangerous = (
        'Backwards deletes only the FSL Report Received Date form field this '
        'migration adds (form config, no case data).'
    )

    dependencies = [
        ('crimetab', '0201_fsl_report_received_label'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
