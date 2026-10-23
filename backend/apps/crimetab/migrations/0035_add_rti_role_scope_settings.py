from django.db import migrations

# Note: Migration is one-way.
SQL_SEED_ROLE_SCOPE_SETTINGS = """
DO $$
BEGIN
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES 
            ('rti', 'scope_station_roles', 'officer,station_admin,station_head'),
            ('rti', 'scope_division_roles', 'division_admin,supervisor'),
            ('rti', 'scope_district_roles', 'district_admin'),
            ('rti', 'scope_state_roles', 'state_super_admin'),
            ('rti', 'no_station_message', 'No police station assigned to the logged-in user.'),
            ('rti', 'no_division_message', 'No division assigned to the logged-in user.'),
            ('rti', 'no_district_message', 'No district assigned to the logged-in user.'),
            ('rti', 'no_scope_message', 'User role does not have an officer assignment scope configured.'),
            ('rti', 'officer_out_of_scope_message', 'Assigned officer does not belong to your unit scope.')
        ON CONFLICT (module_key, setting_key) DO NOTHING;
    END IF;
END $$;
"""

SETTINGS_DATA = [
    ('scope_station_roles', 'officer,station_admin,station_head'),
    ('scope_division_roles', 'division_admin,supervisor'),
    ('scope_district_roles', 'district_admin'),
    ('scope_state_roles', 'state_super_admin'),
    ('no_station_message', 'No police station assigned to the logged-in user.'),
    ('no_division_message', 'No division assigned to the logged-in user.'),
    ('no_district_message', 'No district assigned to the logged-in user.'),
    ('no_scope_message', 'User role does not have an officer assignment scope configured.'),
    ('officer_out_of_scope_message', 'Assigned officer does not belong to your unit scope.'),
]


def seed_role_scope_settings(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_SEED_ROLE_SCOPE_SETTINGS)
    else:
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
        for key, val in SETTINGS_DATA:
            ModuleSetting.objects.get_or_create(
                module_key='rti',
                setting_key=key,
                defaults={'setting_value': val}
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0034_add_rti_no_station_message_setting'),
    ]

    operations = [
        migrations.RunPython(
            seed_role_scope_settings,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
