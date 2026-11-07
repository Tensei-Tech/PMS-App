import json
from django.db import migrations

"""
Migration 0160: restore the combined dashboard tiles.

Commit 725b933 merged the DAR and IRAD tiles into one "DAR/IRAD" tile (it opens
DAR and IRAD tabs) and renamed NAFIS to "NAFIS/Fingerprint". Migration 0136 then
seeded the database-driven dashboard tools with the older separate names, and
the app now builds its tiles from that list, so DAR and IRAD showed separately
again. This edits only those three entries in the dashboard tools setting.
"""

# module_key -> changes applied going forwards / restored going backwards
FORWARD = {
    'dar': {'label': 'DAR/IRAD'},
    'irad': {'is_active': False},
    'nafis': {'label': 'NAFIS/Fingerprint'},
}
BACKWARD = {
    'dar': {'label': 'DAR'},
    'irad': {'is_active': True},
    'nafis': {'label': 'NAFIS'},
}


def _apply(apps, changes):
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
        if not isinstance(tool, dict):
            continue
        update = changes.get(tool.get('module_key'))
        if update:
            for key, value in update.items():
                if tool.get(key) != value:
                    tool[key] = value
                    changed = True

    if changed:
        setting.setting_value = json.dumps(tools)
        setting.save(update_fields=['setting_value'])


def forwards(apps, schema_editor):
    _apply(apps, FORWARD)


def backwards(apps, schema_editor):
    _apply(apps, BACKWARD)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0159_merge_20261030_1604'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
