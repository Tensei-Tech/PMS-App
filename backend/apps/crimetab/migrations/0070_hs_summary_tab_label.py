from django.db import migrations

"""
Migration 0070: History Sheeter fourth tab label "Chart" -> "Summary" (data only)

Only changes the value if it is still the seeded 'Chart' (a label edited by an
admin is left alone).
"""


def forwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='history_sheeter', setting_key='tab_chart_label',
                                 setting_value='Chart').update(setting_value='Summary')


def backwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='history_sheeter', setting_key='tab_chart_label',
                                 setting_value='Summary').update(setting_value='Chart')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0069_hs_chart_tab_settings'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
