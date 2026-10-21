from django.db import migrations

"""
Migration 0090: N.C. hub list card settings (data only)

- list_serial_label: label of the running serial number on each card
- pending_definition_message: shown above the Pending tab; {date_only_provision}
  is filled from nc.date_only_provision. Existing keys are kept.
"""

SETTINGS = [
    ('list_serial_label', 'Sr. No.'),
    ('pending_definition_message',
     'Pending: an N.C. stays Pending until every Preventive row is complete. '
     'A {date_only_provision} row needs only the Date; any other provision needs the '
     'Date, Outward Number, Bond Date and Bond Cancellation Date. '
     'An N.C. with no Preventive row is also Pending.'),
]


def seed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(
            module_key='nc', setting_key=key, defaults={'setting_value': value}
        )


def unseed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='nc', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0089_rti_due_date_reminder_settings'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
