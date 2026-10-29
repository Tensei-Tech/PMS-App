from django.db import migrations

"""
Migration 0093: N.C. Preventive completeness rule (data only)

- New setting preventive_required_fields: the columns a Preventive row with any
  provision OTHER than the date-only provision must fill (besides Provision and
  Date). Set to 'outward_number': Bond Date and Bond Cancellation Date are no
  longer needed for Disposal. Allowed columns: outward_number, bond_date,
  bond_cancellation_date (comma separated).
- Pending definition text updated to match (and the leading "A " removed).
"""

KEY_TEXT = 'pending_definition_message'
OLD_TEXT = ('A {date_only_provision} row needs only the Date; any other preventive needs the '
            'Date, Outward Number, Bond Date and Bond Cancellation Date.')
NEW_TEXT = ('{date_only_provision} row needs only the Date; any other preventive needs the '
            'Date and Outward Number.')


def forwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.get_or_create(
        module_key='nc', setting_key='preventive_required_fields',
        defaults={'setting_value': 'outward_number'},
    )
    for s in ModuleSetting.objects.filter(module_key='nc', setting_key=KEY_TEXT,
                                          setting_value__contains=OLD_TEXT):
        s.setting_value = s.setting_value.replace(OLD_TEXT, NEW_TEXT)
        s.save(update_fields=['setting_value'])


def backwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='nc', setting_key='preventive_required_fields').delete()
    for s in ModuleSetting.objects.filter(module_key='nc', setting_key=KEY_TEXT,
                                          setting_value__contains=NEW_TEXT):
        s.setting_value = s.setting_value.replace(NEW_TEXT, OLD_TEXT)
        s.save(update_fields=['setting_value'])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0092_nc_pending_definition_wording'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
