from django.db import migrations

"""
Migration 0067: History Sheeter "Action Taken" becomes a multi-select (data only)

Field hs_preventive_action_type (History Sheeter Template) changes from
'dropdown' to 'multi_select', so several preventive actions can be ticked in
one entry. The API saves one preventive row per ticked action. Same options
(/api/options/hs_preventive_actions/). Idempotent.
"""

TEMPLATE_NAME = 'History Sheeter Template'
FIELD_KEY = 'hs_preventive_action_type'


def _set(apps, field_type):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=FIELD_KEY
    ).update(field_type=field_type)


def forwards(apps, schema_editor):
    _set(apps, 'multi_select')


def backwards(apps, schema_editor):
    _set(apps, 'dropdown')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0066_standalone_tabs_without_form'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
