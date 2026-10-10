from django.db import migrations

# Note: Migration is one-way.
SQL_SEED_NO_STATION_MESSAGE = """
DO $$
BEGIN
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES ('rti', 'no_station_message', 'No police station assigned to the logged-in user.')
        ON CONFLICT (module_key, setting_key) DO NOTHING;
    END IF;
END $$;
"""


def seed_no_station_message(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_SEED_NO_STATION_MESSAGE)
    else:
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
        ModuleSetting.objects.get_or_create(
            module_key='rti',
            setting_key='no_station_message',
            defaults={'setting_value': 'No police station assigned to the logged-in user.'}
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0033_alter_rtiapplication_status'),
    ]

    operations = [
        migrations.RunPython(
            seed_no_station_message,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
