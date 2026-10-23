from django.db import migrations

"""
Migration 0123: NC Form - label 'Cast' -> 'Caste'

Complainant and non applicant rows. Field keys stay the same.
"""

TEMPLATE_NAME = 'NC Form'
CASTE_KEYS = ('nc_cmp_cast', 'nc_na_cast')


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME,
        field_key__in=CASTE_KEYS,
        field_label='Cast',
    ).update(field_label='Caste')


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME,
        field_key__in=CASTE_KEYS,
        field_label='Caste',
    ).update(field_label='Cast')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0122_nc_single_complainant_and_mobile_type'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
