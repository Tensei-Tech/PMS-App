import json
from django.db import migrations

"""
Migration 0190: hide the separate "Licence" dashboard tile.

Licence is already reachable as a tab inside the "Passport/PVR/Licence" tile,
so the standalone Licence tool tile (seeded by migration 0136) is a duplicate.
This only marks that entry inactive in the dashboard tools setting; the Licence
module, its data and the Passport/PVR/Licence tile are untouched.
"""


def _set_licence_active(apps, active):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    setting = ModuleSetting.objects.filter(
        module_key='dashboard', setting_key='tools'
    ).first()
    if setting is None:
        return
    try:
        tools = json.loads(setting.setting_value or '[]')
    except (TypeError, ValueError):
        return
    if not isinstance(tools, list):
        return

    changed = False
    for tool in tools:
        if isinstance(tool, dict) and tool.get('module_key') == 'licence':
            if tool.get('is_active') != active:
                tool['is_active'] = active
                changed = True

    if changed:
        setting.setting_value = json.dumps(tools)
        setting.save(update_fields=['setting_value'])


def forwards(apps, schema_editor):
    _set_licence_active(apps, False)


def backwards(apps, schema_editor):
    _set_licence_active(apps, True)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0189_part6_cases_module_and_mpda_short_year'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
