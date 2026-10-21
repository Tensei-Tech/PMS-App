from django.db import migrations

"""
Migration 0045: History Sheeter Same As Above Setting

Adds ONE public.module_settings row for module_key 'history_sheeter':
setting_key: 'copy_on_tick_rules'
setting_value: '[{"trigger_field": "hs_same_as_above", "source_field": "hs_permanent_address", "target_field": "hs_present_address"}]'

This configures the generic frontend copy-on-tick rule without hardcoding field keys in Flutter.
"""

SQL_ADD_SETTING_UP = """
DO $$
BEGIN
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES
        ('history_sheeter', 'copy_on_tick_rules', '[{"trigger_field": "hs_same_as_above", "source_field": "hs_permanent_address", "target_field": "hs_present_address"}]')
        ON CONFLICT (module_key, setting_key) DO UPDATE
        SET setting_value = EXCLUDED.setting_value;
    END IF;
END $$;
"""


def seed_same_as_above_setting(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_ADD_SETTING_UP)
    else:
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
        ModuleSetting.objects.update_or_create(
            module_key='history_sheeter',
            setting_key='copy_on_tick_rules',
            defaults={
                'setting_value': '[{"trigger_field": "hs_same_as_above", "source_field": "hs_permanent_address", "target_field": "hs_present_address"}]'
            }
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0044_phase_b_module_settings'),
    ]

    operations = [
        migrations.RunPython(
            seed_same_as_above_setting,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
