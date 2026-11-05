from django.db import migrations

"""
Migration 0165: the A.D. "Unknown Deceased" list opens inside "Deceased Details"

Choosing Identity = Known shows the "Deceased" list in the same card as the
Identity question, but Unknown showed its "Unknown Deceased" list (0161) in a
separate "Unknown Deceased Details" card. The list and its fields now sit in
"Deceased Details" too, so both choices open the same way.

Only the section name changes: keys, order, conditions and saved answers stay.
Named 0165 because the shared database already has a 0164 from another branch.
Idempotent; backwards puts them back in "Unknown Deceased Details".
"""

TEMPLATE_NAME = 'AD Form Fields'
OLD_SECTION = 'Unknown Deceased Details'
NEW_SECTION = 'Deceased Details'


def _move(apps, old, new):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, section=old,
    ).update(section=new)


def forwards(apps, schema_editor):
    _move(apps, OLD_SECTION, NEW_SECTION)


def backwards(apps, schema_editor):
    # Only the unknown deceased list and its fields go back
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    fields.filter(field_key='ad_unknown_deceased').update(section=OLD_SECTION)
    fields.filter(parent_field_key='ad_unknown_deceased').update(section=OLD_SECTION)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0163_rename_normal_accident_to_other_accident'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
