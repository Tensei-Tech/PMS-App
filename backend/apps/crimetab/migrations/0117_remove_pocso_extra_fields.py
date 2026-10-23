import importlib

from django.db import migrations

"""
Migration 0117: remove "POCSO Extra Fields" (data only)

POCSO goes back to the Common Form only (which, since 0116, already carries the
every-crime vehicle entry and Section 82, 83 checks). Deletes the bundle of
0110 / 0116, its category links and its option groups pocso_victim_names and
pocso_age_proofs (victim_accused_relations stays: Crime Against Women uses it).
No POCSO case had a saved value in these fields. Going backwards rebuilds the
bundle as 0110 + 0116 left it. Idempotent.
"""

TEMPLATE_NAME = 'POCSO Extra Fields'
OPTION_GROUPS = ('pocso_victim_names', 'pocso_age_proofs')


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is not None:
        CategoryFieldTemplate.objects.filter(template=tmpl).delete()
        FieldTemplateField.objects.filter(template=tmpl).delete()
        tmpl.delete()
    OptionValue.objects.filter(option_group__in=OPTION_GROUPS).delete()


def backwards(apps, schema_editor):
    pocso = importlib.import_module('apps.crimetab.migrations.0110_pocso_extra_fields')
    every = importlib.import_module('apps.crimetab.migrations.0116_every_crime_vehicle_and_absconding_fields')
    pocso.forwards(apps, schema_editor)
    every.forwards(apps, schema_editor)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0116_every_crime_vehicle_and_absconding_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
