from django.db import migrations

"""
Migration 0198: Murder "Post-Mortem & FSL" Yes / No questions become checkboxes

Post-Mortem, Report, Viscera Sent to FSL and FSL Report (Murder Section Extra
Fields, radios with the Yes / No options, 0114) are now checkboxes. Ticking
one shows its date, inside the checkbox's card on the form.

- The four fields' type becomes checkbox and their Yes / No options source is
  cleared.
- Their dates show while the box is ticked: depends_on_value "Yes" becomes
  "Yes|true" ("true" right after ticking, "Yes" once saved).
- No saved answers change: this template keeps its answers as text rows and
  a ticked box is saved as "Yes", so earlier "Yes" answers show ticked and
  "No" answers unticked.
Idempotent; backwards restores the radios.
"""

TEMPLATE_NAME = 'Murder Section Extra Fields'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'
TICKED = 'Yes|true'

KEYS = [
    'murder_postmortem',
    'murder_pm_report',
    'murder_viscera_fsl',
    'murder_fsl_report',
]


def _set_fields(apps, to_checkbox):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    if to_checkbox:
        fields.filter(field_key__in=KEYS).update(field_type='checkbox', options_source=None)
        fields.filter(depends_on_field_key__in=KEYS, depends_on_value=YES).update(
            depends_on_value=TICKED)
    else:
        fields.filter(field_key__in=KEYS).update(field_type='radio', options_source=YES_NO)
        fields.filter(depends_on_field_key__in=KEYS, depends_on_value=TICKED).update(
            depends_on_value=YES)


def forwards(apps, schema_editor):
    _set_fields(apps, to_checkbox=True)


def backwards(apps, schema_editor):
    _set_fields(apps, to_checkbox=False)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0197_remove_mobile_spot_recording_date'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
