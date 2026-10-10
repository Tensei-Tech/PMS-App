from django.db import migrations

# Note: Migration is one-way.
SQL_SEED_TARGET_CATEGORY_CODE = """
DO $$
BEGIN
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES ('rti', 'target_category_code', 'STAND_RTI')
        ON CONFLICT (module_key, setting_key) DO NOTHING;
    END IF;
END $$;
"""


def seed_target_category_code(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_SEED_TARGET_CATEGORY_CODE)
    else:
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
        ModuleSetting.objects.get_or_create(
            module_key='rti',
            setting_key='target_category_code',
            defaults={'setting_value': 'STAND_RTI'}
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0031_add_rti_enforce_permissions_setting'),
    ]

    operations = [
        migrations.RunPython(
            seed_target_category_code,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
