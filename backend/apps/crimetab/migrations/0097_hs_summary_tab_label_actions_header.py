from django.db import migrations

"""
Migration 0097: History Sheeter summary tab (data only)

- Summary tab label -> "Summary of History Sheeters" (only while the old text is
  unchanged). The "Total History Sheeters" tab is no longer shown; its count now
  sits on the summary tab.
- New header for the summary table's View / Edit / PDF column.
"""

OLD_LABELS = ('Summary', 'Chart')
NEW_LABEL = 'Summary of History Sheeters'
NEW = [
    ('chart_header_actions', 'Actions'),
]


def forwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='history_sheeter', setting_key='tab_chart_label',
                                 setting_value__in=OLD_LABELS).update(setting_value=NEW_LABEL)
    for key, value in NEW:
        ModuleSetting.objects.get_or_create(
            module_key='history_sheeter', setting_key=key, defaults={'setting_value': value}
        )


def backwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='history_sheeter', setting_key='tab_chart_label',
                                 setting_value=NEW_LABEL).update(setting_value='Summary')
    ModuleSetting.objects.filter(module_key='history_sheeter',
                                 setting_key__in=[k for k, _ in NEW]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0096_hs_year_jail_bail_total_tabs'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
