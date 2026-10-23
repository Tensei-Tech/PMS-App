from django.db import migrations

"""
Migration 0044: Phase B Module Settings

Seeds runtime settings for History Sheeter and MPDA backend modules:
1. history_sheeter:
   - max_serial_retries ('5'): Maximum retry attempts for auto-incrementing station serial number
   - active_period_months ('12'): Active status lookback window (12 months back from today)
   - counts_cache_timeout ('45'): Cache TTL (seconds) for aggregate tab counts
2. mpda:
   - counts_cache_timeout ('45'): Cache TTL (seconds) for aggregate proposal counts
   - scope_station_roles ('officer,station_admin,station_head')
   - scope_division_roles ('division_admin,supervisor')
   - scope_district_roles ('district_admin')
   - scope_state_roles ('state_super_admin')
   - Unit scope error messages matching RTI
"""

SQL_ADD_SETTING_UP = """
DO $$
BEGIN
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        -- 1. History Sheeter settings
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES
        ('history_sheeter', 'max_serial_retries', '5'),
        ('history_sheeter', 'active_period_months', '12'),
        ('history_sheeter', 'counts_cache_timeout', '45'),
        ('history_sheeter', 'template_name', 'History Sheeter Template'),
        ('history_sheeter', 'module_name', 'History Sheeter'),
        ('history_sheeter', 'pdf_subtitle', 'History Sheeter Docket'),
        ('history_sheeter', 'pdf_filename_prefix', 'HistorySheeter'),
        ('history_sheeter', 'pdf_department_suffix', 'DEPARTMENT'),
        ('history_sheeter', 'pdf_police_department_suffix', 'POLICE DEPARTMENT'),
        ('history_sheeter', 'pdf_fallback_title', 'POLICE DEPARTMENT'),
        ('history_sheeter', 'missing_state_message', 'State code could not be resolved from authenticated user credentials.'),
        ('history_sheeter', 'not_found_message', 'History Sheeter not found.'),
        ('history_sheeter', 'btn_add_label', 'Add History Sheeter'),
        ('history_sheeter', 'search_placeholder', 'Search History Sheeter...')
        ON CONFLICT DO NOTHING;

        -- 2. MPDA role scope hierarchy settings & cache timeout (reusing RTI officer rules)
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES
        ('mpda', 'counts_cache_timeout', '45'),
        ('mpda', 'template_name', 'MPDA Proposal Template'),
        ('mpda', 'module_name', 'MPDA'),
        ('mpda', 'pdf_subtitle', 'MPDA Proposal Docket'),
        ('mpda', 'pdf_filename_prefix', 'MPDA'),
        ('mpda', 'pdf_department_suffix', 'DEPARTMENT'),
        ('mpda', 'pdf_police_department_suffix', 'POLICE DEPARTMENT'),
        ('mpda', 'pdf_fallback_title', 'POLICE DEPARTMENT'),
        ('mpda', 'missing_state_message', 'State code could not be resolved from authenticated user credentials.'),
        ('mpda', 'not_found_message', 'MPDA proposal not found.'),
        ('mpda', 'scope_station_roles', 'officer,station_admin,station_head'),
        ('mpda', 'scope_division_roles', 'division_admin,supervisor'),
        ('mpda', 'scope_district_roles', 'district_admin'),
        ('mpda', 'scope_state_roles', 'state_super_admin'),
        ('mpda', 'no_station_message', 'No police station assigned to the logged-in user.'),
        ('mpda', 'no_division_message', 'No division assigned to the logged-in user.'),
        ('mpda', 'no_district_message', 'No district assigned to the logged-in user.'),
        ('mpda', 'no_scope_message', 'User role does not have an officer assignment scope configured.'),
        ('mpda', 'officer_out_of_scope_message', 'Assigned officer does not belong to your unit scope.'),
        ('mpda', 'btn_add_label', 'Add MPDA Proposal'),
        ('mpda', 'search_placeholder', 'Search MPDA Proposal...')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
"""


def seed_phase_b_settings(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_ADD_SETTING_UP)
    else:
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
        settings = [
            ('history_sheeter', 'max_serial_retries', '5'),
            ('history_sheeter', 'active_period_months', '12'),
            ('history_sheeter', 'counts_cache_timeout', '45'),
            ('history_sheeter', 'template_name', 'History Sheeter Template'),
            ('history_sheeter', 'module_name', 'History Sheeter'),
            ('history_sheeter', 'pdf_subtitle', 'History Sheeter Docket'),
            ('history_sheeter', 'pdf_filename_prefix', 'HistorySheeter'),
            ('history_sheeter', 'pdf_department_suffix', 'DEPARTMENT'),
            ('history_sheeter', 'pdf_police_department_suffix', 'POLICE DEPARTMENT'),
            ('history_sheeter', 'pdf_fallback_title', 'POLICE DEPARTMENT'),
            ('history_sheeter', 'missing_state_message', 'State code could not be resolved from authenticated user credentials.'),
            ('history_sheeter', 'not_found_message', 'History Sheeter not found.'),
            ('history_sheeter', 'btn_add_label', 'Add History Sheeter'),
            ('history_sheeter', 'search_placeholder', 'Search History Sheeter...'),
            ('mpda', 'counts_cache_timeout', '45'),
            ('mpda', 'template_name', 'MPDA Proposal Template'),
            ('mpda', 'module_name', 'MPDA'),
            ('mpda', 'pdf_subtitle', 'MPDA Proposal Docket'),
            ('mpda', 'pdf_filename_prefix', 'MPDA'),
            ('mpda', 'pdf_department_suffix', 'DEPARTMENT'),
            ('mpda', 'pdf_police_department_suffix', 'POLICE DEPARTMENT'),
            ('mpda', 'pdf_fallback_title', 'POLICE DEPARTMENT'),
            ('mpda', 'missing_state_message', 'State code could not be resolved from authenticated user credentials.'),
            ('mpda', 'not_found_message', 'MPDA proposal not found.'),
            ('mpda', 'scope_station_roles', 'officer,station_admin,station_head'),
            ('mpda', 'scope_division_roles', 'division_admin,supervisor'),
            ('mpda', 'scope_district_roles', 'district_admin'),
            ('mpda', 'scope_state_roles', 'state_super_admin'),
            ('mpda', 'no_station_message', 'No police station assigned to the logged-in user.'),
            ('mpda', 'no_division_message', 'No division assigned to the logged-in user.'),
            ('mpda', 'no_district_message', 'No district assigned to the logged-in user.'),
            ('mpda', 'no_scope_message', 'User role does not have an officer assignment scope configured.'),
            ('mpda', 'officer_out_of_scope_message', 'Assigned officer does not belong to your unit scope.'),
            ('mpda', 'btn_add_label', 'Add MPDA Proposal'),
            ('mpda', 'search_placeholder', 'Search MPDA Proposal...'),
        ]
        for mk, sk, sv in settings:
            ModuleSetting.objects.get_or_create(
                module_key=mk,
                setting_key=sk,
                defaults={'setting_value': sv}
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0043_mpda_tenant_tables'),
    ]

    operations = [
        migrations.RunPython(
            seed_phase_b_settings,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
