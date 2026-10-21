from django.db import migrations

# Note: This migration is one-way.
SQL_SEED_SETTINGS = """
DO $$
BEGIN
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES 
            ('rti', 'enforce_permissions', 'false'),
            ('rti', 'serial_prefix', 'RTI'),
            ('rti', 'serial_format', '{prefix}-{year}/{serial_no}'),
            ('rti', 'pdf_subtitle', 'RTI Application Report')
        ON CONFLICT (module_key, setting_key) DO NOTHING;
    END IF;
END $$;
"""


def seed_enforce_permissions(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_SEED_SETTINGS)
    else:
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
        defaults_list = [
            ('enforce_permissions', 'false'),
            ('serial_prefix', 'RTI'),
            ('serial_format', '{prefix}-{year}/{serial_no}'),
            ('pdf_subtitle', 'RTI Application Report'),
        ]
        for key, val in defaults_list:
            ModuleSetting.objects.get_or_create(
                module_key='rti',
                setting_key=key,
                defaults={'setting_value': val}
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0030_create_rti_applications_table'),
    ]

    operations = [
        migrations.RunPython(
            seed_enforce_permissions,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
