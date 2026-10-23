from django.db import migrations

"""
Migration 0096: History Sheeter tab labels (data only)

- "History Sheet Open"   -> "HS Opened in Current Year" (tab now lists sheets
  opened this calendar year)
- "History Sheet Closed" -> "HS Closed in Current Year" (closed this year)
- New tabs: Total History Sheeters, Currently in Jail, Currently on Bail.
Renames apply only while the old text is unchanged; new keys are kept if present.
"""

RENAMES = [
    ('tab_open_label', 'History Sheet Open', 'HS Opened in Current Year'),
    ('tab_closed_label', 'History Sheet Closed', 'HS Closed in Current Year'),
]
NEW = [
    ('tab_total_label', 'Total History Sheeters'),
    ('tab_jail_label', 'Currently in Jail'),
    ('tab_bail_label', 'Currently on Bail'),
]


def forwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, old, new in RENAMES:
        ModuleSetting.objects.filter(module_key='history_sheeter', setting_key=key,
                                     setting_value=old).update(setting_value=new)
    for key, value in NEW:
        ModuleSetting.objects.get_or_create(
            module_key='history_sheeter', setting_key=key, defaults={'setting_value': value}
        )


def backwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, old, new in RENAMES:
        ModuleSetting.objects.filter(module_key='history_sheeter', setting_key=key,
                                     setting_value=new).update(setting_value=old)
    ModuleSetting.objects.filter(module_key='history_sheeter',
                                 setting_key__in=[k for k, _ in NEW]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0095_rti_reminder_info_given_message'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
