from django.db import migrations

"""
Migration 0170: Common Form mobile numbers are checked (data only)

Complainant, Accused and Suspected Accused Mobile were plain text fields. They
are now 'mobile' fields: digits only and, when filled, exactly 10 digits.
They stay optional (is_required is unchanged), so an empty number is fine.
(The app's Accused / Suspected Accused person cards check the same rule.)
Idempotent; backwards makes them text fields again.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
KEYS = [
    'complainant_mobile',
    'accused_mobile',
    'suspected_accused_mobile',
]


def _set_type(apps, field_type):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key__in=KEYS,
    ).update(field_type=field_type)


def forwards(apps, schema_editor):
    _set_type(apps, 'mobile')


def backwards(apps, schema_editor):
    _set_type(apps, 'text')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0169_common_form_yes_no_to_checkboxes'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
