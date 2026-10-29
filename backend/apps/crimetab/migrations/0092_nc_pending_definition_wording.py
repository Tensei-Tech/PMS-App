from django.db import migrations

"""
Migration 0092: N.C. Pending definition wording (data only)

"any other provision needs ..." -> "any other preventive needs ...".
Changes the text only where it still contains the original wording.
"""

KEY = 'pending_definition_message'
OLD = 'any other provision needs'
NEW = 'any other preventive needs'


def _swap(apps, old, new):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for s in ModuleSetting.objects.filter(module_key='nc', setting_key=KEY,
                                          setting_value__contains=old):
        s.setting_value = s.setting_value.replace(old, new)
        s.save(update_fields=['setting_value'])


def forwards(apps, schema_editor):
    _swap(apps, OLD, NEW)


def backwards(apps, schema_editor):
    _swap(apps, NEW, OLD)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0091_nc_preventive_number_order_and_designation_label'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
