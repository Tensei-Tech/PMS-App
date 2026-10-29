from django.db import migrations

"""
Migration 0060: N.C. Preventive Number label in English only (data only)

'Preventive Number / इस्तेगाशा नंबर' -> 'Preventive Number' for the NC Form field
nc_prev_number. Idempotent; touches only that one field.
"""

TEMPLATE_NAME = 'NC Form'
FIELD_KEY = 'nc_prev_number'
OLD_LABEL = 'Preventive Number / इस्तेगाशा नंबर'
NEW_LABEL = 'Preventive Number'


def _set(apps, label):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=FIELD_KEY
    ).update(field_label=label)


def forwards(apps, schema_editor):
    _set(apps, NEW_LABEL)


def backwards(apps, schema_editor):
    _set(apps, OLD_LABEL)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0059_nc_officer_and_designation_pickers'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
