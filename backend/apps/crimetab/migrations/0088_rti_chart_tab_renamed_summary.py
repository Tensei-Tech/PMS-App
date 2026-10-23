from django.db import migrations

"""
Migration 0088: RTI fourth tab label "Chart" -> "Summary" (data only).
Changes the value only if it is still the original "Chart".
"""

KEY = 'tab_chart_label'


def rename(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='rti', setting_key=KEY, setting_value='Chart').update(
        setting_value='Summary')


def restore(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='rti', setting_key=KEY, setting_value='Summary').update(
        setting_value='Chart')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0087_rti_chart_person_column'),
    ]

    operations = [
        migrations.RunPython(rename, reverse_code=restore),
    ]
