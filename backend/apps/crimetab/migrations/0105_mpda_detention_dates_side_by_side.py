from django.db import migrations

"""
Migration 0105: MPDA Detention Start and End Date side by side

The form lays fields out two per line in display_order. Jail Name moves up
next to Detained (160 -> 165), so Detention Start Date and Detention End Date
share one line:
    Detained            | Jail Name
    Detention Start Date| Detention End Date
"""

TEMPLATE_NAME = 'MPDA Proposal Template'
KEY = 'mpda_jail_name'
OLD_ORDER, NEW_ORDER = 190, 165


def _move(apps, frm, to):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=KEY, display_order=frm
    ).update(display_order=to)


def forwards(apps, schema_editor):
    _move(apps, OLD_ORDER, NEW_ORDER)


def backwards(apps, schema_editor):
    _move(apps, NEW_ORDER, OLD_ORDER)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0104_mpda_mobile_aadhaar_types_and_caste_label'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
