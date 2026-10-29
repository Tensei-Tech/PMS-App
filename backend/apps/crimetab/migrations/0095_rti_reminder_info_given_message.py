from django.db import migrations

"""
Migration 0095: RTI reminders stop once the Information Given date is entered
(Replied / Rejected / Transfer Date). Message shown when "Send Reminder" is
pressed for such an application. Data only; existing keys are kept.
"""

SETTINGS = [
    ('manual_reminder_info_given_message',
     'Information is already given for this RTI application, so no reminder is sent.'),
]


def seed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(
            module_key='rti', setting_key=key, defaults={'setting_value': value}
        )


def unseed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='rti', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0094_nc_provision_label_preventive'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
