from django.db import migrations

"""
Migration 0094: N.C. Preventive row field "Provision" is labelled "Preventive"
(form, list card and View / PDF all use this label). Data only.
"""

TEMPLATE_NAME = 'NC Form'
FIELD_KEY = 'nc_prev_provision'


def _relabel(apps, old, new):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=FIELD_KEY, field_label=old
    ).update(field_label=new)


def forwards(apps, schema_editor):
    _relabel(apps, 'Provision', 'Preventive')


def backwards(apps, schema_editor):
    _relabel(apps, 'Preventive', 'Provision')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0093_nc_preventive_rule_date_and_outward'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
