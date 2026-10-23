from django.db import migrations

SQL_HS_SEED_UP = """
DO $$
DECLARE
    hs_cat_id BIGINT;
    hs_tmpl_id BIGINT;
BEGIN
    -- 1. Tab row in public.case_categories
    IF to_regclass('public.case_categories') IS NOT NULL THEN
        SELECT category_id INTO hs_cat_id
        FROM public.case_categories
        WHERE category_name = 'History Sheeter' OR category_code = 'STAND_HISTORY_SHEETER';

        IF hs_cat_id IS NULL THEN
            LOCK TABLE public.case_categories IN EXCLUSIVE MODE;
            SELECT COALESCE(MAX(category_id), 0) + 1 INTO hs_cat_id FROM public.case_categories;

            INSERT INTO public.case_categories (
                category_id, category_name, category_code, group_id, parent_category_id,
                template_id, is_active, display_order, created_at
            ) VALUES (
                hs_cat_id, 'History Sheeter', 'STAND_HISTORY_SHEETER', NULL, NULL,
                NULL, TRUE, (SELECT COALESCE(MAX(display_order), 0) + 10 FROM public.case_categories), NOW()
            );
        END IF;
    END IF;

    -- 2. Bundle "History Sheeter Template" in public.field_templates
    IF to_regclass('public.field_templates') IS NOT NULL THEN
        SELECT template_id INTO hs_tmpl_id
        FROM public.field_templates
        WHERE template_name = 'History Sheeter Template';

        IF hs_tmpl_id IS NULL THEN
            INSERT INTO public.field_templates (template_name, created_at)
            VALUES ('History Sheeter Template', NOW())
            RETURNING template_id INTO hs_tmpl_id;
        END IF;

        -- 3. Link History Sheeter category to template in public.category_field_templates
        IF hs_cat_id IS NOT NULL AND to_regclass('public.category_field_templates') IS NOT NULL THEN
            INSERT INTO public.category_field_templates (category_id, template_id)
            VALUES (hs_cat_id, hs_tmpl_id)
            ON CONFLICT DO NOTHING;
        END IF;

        -- 4. Create fields in public.field_template_fields for History Sheeter
        IF to_regclass('public.field_template_fields') IS NOT NULL THEN
            -- Personal Information
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source, parent_field_key)
            VALUES
            (hs_tmpl_id, 'Name', 'hs_name', 'custom', 'text', FALSE, 'Personal Information', 10, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Alias', 'hs_alias', 'custom', 'text', FALSE, 'Personal Information', 20, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Nickname', 'hs_nickname', 'custom', 'text', FALSE, 'Personal Information', 30, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Age', 'hs_age', 'custom', 'number', FALSE, 'Personal Information', 40, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Gender', 'hs_gender', 'custom', 'dropdown', FALSE, 'Personal Information', 50, NULL, NULL, '/api/options/gender/', NULL),
            (hs_tmpl_id, 'Mobile No.', 'hs_mobile_no', 'custom', 'text', FALSE, 'Personal Information', 60, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Address', 'hs_address', 'custom', 'textarea', FALSE, 'Personal Information', 70, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Permanent Address', 'hs_permanent_address', 'custom', 'textarea', FALSE, 'Personal Information', 80, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Present Address', 'hs_present_address', 'custom', 'textarea', FALSE, 'Personal Information', 90, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Present Address Same As Above', 'hs_same_as_above', 'custom', 'checkbox', FALSE, 'Personal Information', 95, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Native Place', 'hs_native_place', 'custom', 'text', FALSE, 'Personal Information', 100, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Occupation', 'hs_occupation', 'custom', 'text', FALSE, 'Personal Information', 110, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Aadhaar / ID Details', 'hs_aadhaar_id_details', 'custom', 'text', FALSE, 'Personal Information', 120, NULL, NULL, NULL, NULL),

            -- History Sheet Details
            (hs_tmpl_id, 'History Sheet No.', 'hs_history_sheet_no', 'custom', 'text', FALSE, 'History Sheet Details', 130, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Date of Opening History Sheet', 'hs_opening_date', 'custom', 'date', FALSE, 'History Sheet Details', 140, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Order Date', 'hs_order_date', 'custom', 'date', FALSE, 'History Sheet Details', 150, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Category / Type of History Sheeter', 'hs_category_type', 'custom', 'multi_select', FALSE, 'History Sheet Details', 160, NULL, NULL, '/api/options/hs_category_types/', NULL),
            (hs_tmpl_id, 'Other Category Details', 'hs_category_type_other', 'custom', 'text', FALSE, 'History Sheet Details', 170, 'hs_category_type', 'Other', NULL, NULL),
            (hs_tmpl_id, 'Criminal Activities / Modus Operandi', 'hs_modus_operandi', 'custom', 'textarea', FALSE, 'History Sheet Details', 180, NULL, NULL, NULL, NULL),

            -- Case Statistics
            (hs_tmpl_id, 'Total Criminal Cases', 'hs_total_cases', 'custom', 'number', FALSE, 'Case Statistics', 190, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Convicted Cases', 'hs_convicted_cases', 'custom', 'number', FALSE, 'Case Statistics', 200, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Pending Cases', 'hs_pending_cases', 'custom', 'number', FALSE, 'Case Statistics', 210, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Acquitted / Discharged Cases', 'hs_acquitted_discharged_cases', 'custom', 'number', FALSE, 'Case Statistics', 220, NULL, NULL, NULL, NULL),

            -- Known Associates / Gang Members
            (hs_tmpl_id, 'Known Associates / Gang Members', 'hs_associates', 'custom', 'repeating_group', FALSE, 'Known Associates / Gang Members', 230, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Name', 'hs_assoc_name', 'custom', 'text', FALSE, 'Known Associates / Gang Members', 231, NULL, NULL, NULL, 'hs_associates'),
            (hs_tmpl_id, 'Alias', 'hs_assoc_alias', 'custom', 'text', FALSE, 'Known Associates / Gang Members', 232, NULL, NULL, NULL, 'hs_associates'),
            (hs_tmpl_id, 'Nickname', 'hs_assoc_nickname', 'custom', 'text', FALSE, 'Known Associates / Gang Members', 233, NULL, NULL, NULL, 'hs_associates'),
            (hs_tmpl_id, 'Age', 'hs_assoc_age', 'custom', 'number', FALSE, 'Known Associates / Gang Members', 234, NULL, NULL, NULL, 'hs_associates'),
            (hs_tmpl_id, 'Gender', 'hs_assoc_gender', 'custom', 'dropdown', FALSE, 'Known Associates / Gang Members', 235, NULL, NULL, '/api/options/gender/', 'hs_associates'),
            (hs_tmpl_id, 'Mobile No.', 'hs_assoc_mobile', 'custom', 'text', FALSE, 'Known Associates / Gang Members', 236, NULL, NULL, NULL, 'hs_associates'),
            (hs_tmpl_id, 'Address', 'hs_assoc_address', 'custom', 'textarea', FALSE, 'Known Associates / Gang Members', 237, NULL, NULL, NULL, 'hs_associates'),

            -- Rival / Adverse Persons
            (hs_tmpl_id, 'Rival / Adverse Persons', 'hs_rivals', 'custom', 'repeating_group', FALSE, 'Rival / Adverse Persons', 240, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Name', 'hs_rival_name', 'custom', 'text', FALSE, 'Rival / Adverse Persons', 241, NULL, NULL, NULL, 'hs_rivals'),
            (hs_tmpl_id, 'Alias', 'hs_rival_alias', 'custom', 'text', FALSE, 'Rival / Adverse Persons', 242, NULL, NULL, NULL, 'hs_rivals'),
            (hs_tmpl_id, 'Nickname', 'hs_rival_nickname', 'custom', 'text', FALSE, 'Rival / Adverse Persons', 243, NULL, NULL, NULL, 'hs_rivals'),
            (hs_tmpl_id, 'Age', 'hs_rival_age', 'custom', 'number', FALSE, 'Rival / Adverse Persons', 244, NULL, NULL, NULL, 'hs_rivals'),
            (hs_tmpl_id, 'Gender', 'hs_rival_gender', 'custom', 'dropdown', FALSE, 'Rival / Adverse Persons', 245, NULL, NULL, '/api/options/gender/', 'hs_rivals'),
            (hs_tmpl_id, 'Mobile No.', 'hs_rival_mobile', 'custom', 'text', FALSE, 'Rival / Adverse Persons', 246, NULL, NULL, NULL, 'hs_rivals'),
            (hs_tmpl_id, 'Address', 'hs_rival_address', 'custom', 'textarea', FALSE, 'Rival / Adverse Persons', 247, NULL, NULL, NULL, 'hs_rivals'),

            -- Bond / Surety Details
            (hs_tmpl_id, 'Bond / Surety Details', 'hs_sureties', 'custom', 'repeating_group', FALSE, 'Bond / Surety Details', 250, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Name', 'hs_surety_name', 'custom', 'text', FALSE, 'Bond / Surety Details', 251, NULL, NULL, NULL, 'hs_sureties'),
            (hs_tmpl_id, 'Alias', 'hs_surety_alias', 'custom', 'text', FALSE, 'Bond / Surety Details', 252, NULL, NULL, NULL, 'hs_sureties'),
            (hs_tmpl_id, 'Nickname', 'hs_surety_nickname', 'custom', 'text', FALSE, 'Bond / Surety Details', 253, NULL, NULL, NULL, 'hs_sureties'),
            (hs_tmpl_id, 'Age', 'hs_surety_age', 'custom', 'number', FALSE, 'Bond / Surety Details', 254, NULL, NULL, NULL, 'hs_sureties'),
            (hs_tmpl_id, 'Gender', 'hs_surety_gender', 'custom', 'dropdown', FALSE, 'Bond / Surety Details', 255, NULL, NULL, '/api/options/gender/', 'hs_sureties'),
            (hs_tmpl_id, 'Mobile No.', 'hs_surety_mobile', 'custom', 'text', FALSE, 'Bond / Surety Details', 256, NULL, NULL, NULL, 'hs_sureties'),
            (hs_tmpl_id, 'Address', 'hs_surety_address', 'custom', 'textarea', FALSE, 'Bond / Surety Details', 257, NULL, NULL, NULL, 'hs_sureties'),

            -- Preventive Action Taken
            (hs_tmpl_id, 'Preventive Action Taken', 'hs_preventive_actions', 'custom', 'repeating_group', FALSE, 'Preventive Action Taken', 260, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Action Taken', 'hs_preventive_action_type', 'custom', 'dropdown', FALSE, 'Preventive Action Taken', 261, NULL, NULL, '/api/options/hs_preventive_actions/', 'hs_preventive_actions'),
            (hs_tmpl_id, 'Other Preventive Action Details', 'hs_preventive_action_other', 'custom', 'text', FALSE, 'Preventive Action Taken', 262, 'hs_preventive_action_type', 'Other', NULL, 'hs_preventive_actions'),

            -- Current Whereabouts & Verification
            (hs_tmpl_id, 'Current Whereabouts', 'hs_whereabouts', 'custom', 'textarea', FALSE, 'Current Whereabouts & Verification', 270, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Last Verification Date', 'hs_last_verification_date', 'custom', 'date', FALSE, 'Current Whereabouts & Verification', 280, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Verification Remarks', 'hs_verification_remarks', 'custom', 'textarea', FALSE, 'Current Whereabouts & Verification', 290, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Currently in Jail', 'hs_currently_in_jail', 'custom', 'dropdown', FALSE, 'Current Whereabouts & Verification', 300, NULL, NULL, '/api/options/yes_no/', NULL),
            (hs_tmpl_id, 'Currently on Bail', 'hs_currently_on_bail', 'custom', 'dropdown', FALSE, 'Current Whereabouts & Verification', 310, NULL, NULL, '/api/options/yes_no/', NULL),

            -- Crime Chart
            (hs_tmpl_id, 'Crime Chart', 'hs_crime_chart', 'custom', 'repeating_group', FALSE, 'Crime Chart', 320, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'CR No.', 'hs_crime_cr_no', 'custom', 'text', FALSE, 'Crime Chart', 321, NULL, NULL, NULL, 'hs_crime_chart'),
            (hs_tmpl_id, 'Crime Head', 'hs_crime_head', 'custom', 'text', FALSE, 'Crime Chart', 322, NULL, NULL, NULL, 'hs_crime_chart'),
            (hs_tmpl_id, 'Act and Section', 'hs_crime_act_section', 'custom', 'text', FALSE, 'Crime Chart', 323, NULL, NULL, NULL, 'hs_crime_chart'),
            (hs_tmpl_id, 'Register Date', 'hs_crime_register_date', 'custom', 'date', FALSE, 'Crime Chart', 324, NULL, NULL, NULL, 'hs_crime_chart'),
            (hs_tmpl_id, 'Police Station', 'hs_crime_police_station', 'custom', 'text', FALSE, 'Crime Chart', 325, NULL, NULL, NULL, 'hs_crime_chart'),

            -- Closed Status
            (hs_tmpl_id, 'Date of Closure', 'hs_closure_date', 'custom', 'date', FALSE, 'Closed Status', 330, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Reason for Closure', 'hs_closure_reason', 'custom', 'text', FALSE, 'Closed Status', 340, NULL, NULL, NULL, NULL),
            (hs_tmpl_id, 'Remarks', 'hs_closure_remarks', 'custom', 'textarea', FALSE, 'Closed Status', 350, NULL, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- 5. Seed Option Values in public.option_values
    IF to_regclass('public.option_values') IS NOT NULL THEN
        -- Category Types
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES
        ('hs_category_types', 'Body Offender', 10, TRUE),
        ('hs_category_types', 'Property Offender', 20, TRUE),
        ('hs_category_types', 'Narcotics / NDPS', 30, TRUE),
        ('hs_category_types', 'Prohibition / Liquor', 40, TRUE),
        ('hs_category_types', 'Gambling', 50, TRUE),
        ('hs_category_types', 'Against Women', 60, TRUE),
        ('hs_category_types', 'Extortion / Threat', 70, TRUE),
        ('hs_category_types', 'Organized Crime / Gang Member', 80, TRUE),
        ('hs_category_types', 'Weapon-Related', 90, TRUE),
        ('hs_category_types', 'Cyber Crime', 100, TRUE),
        ('hs_category_types', 'Other', 110, TRUE)
        ON CONFLICT DO NOTHING;

        -- Preventive Actions (11 existing provisions + Externment, MPDA, Other)
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES
        ('hs_preventive_actions', 'Externment', 10, TRUE),
        ('hs_preventive_actions', 'MPDA', 20, TRUE),
        ('hs_preventive_actions', '107 CrPC/126 BNSS', 30, TRUE),
        ('hs_preventive_actions', '109 CrPC/128 BNSS', 40, TRUE),
        ('hs_preventive_actions', '110 CrPC/129 BNSS', 50, TRUE),
        ('hs_preventive_actions', '151(3) CrPC/170 BNSS', 60, TRUE),
        ('hs_preventive_actions', '144 CrPC/163 BNSS', 70, TRUE),
        ('hs_preventive_actions', '149 CrPC/168 BNSS', 80, TRUE),
        ('hs_preventive_actions', '55 MPA', 90, TRUE),
        ('hs_preventive_actions', '56 MPA', 100, TRUE),
        ('hs_preventive_actions', '57 MPA', 110, TRUE),
        ('hs_preventive_actions', '122 MPA', 120, TRUE),
        ('hs_preventive_actions', '93 Prohibition Act', 130, TRUE),
        ('hs_preventive_actions', 'Other', 140, TRUE)
        ON CONFLICT DO NOTHING;
    END IF;

    -- 6. Seed Module Settings in public.module_settings
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES
        ('history_sheeter', 'target_category_code', 'STAND_HISTORY_SHEETER'),
        ('history_sheeter', 'enforce_permissions', 'false'),
        ('history_sheeter', 'word_limit_modus_operandi', '25'),
        ('history_sheeter', 'word_limit_whereabouts', '25'),
        ('history_sheeter', 'empty_request_message', 'Cannot save empty record. At least one field must be filled.'),
        ('history_sheeter', 'tab_active_label', 'Active History Sheeter'),
        ('history_sheeter', 'tab_open_label', 'History Sheet Open'),
        ('history_sheeter', 'tab_closed_label', 'History Sheet Closed'),
        ('history_sheeter', 'btn_edit_label', 'Edit'),
        ('history_sheeter', 'btn_view_label', 'View'),
        ('history_sheeter', 'btn_pdf_label', 'PDF')
        ON CONFLICT DO NOTHING;

        -- Global / module date format if not present
        IF NOT EXISTS (
            SELECT 1 FROM public.module_settings 
            WHERE module_key = 'history_sheeter' AND setting_key = 'date_format'
        ) THEN
            INSERT INTO public.module_settings (module_key, setting_key, setting_value)
            VALUES ('history_sheeter', 'date_format', '%%d/%%m/%%Y');
        END IF;
    END IF;

    -- 7. Seed Permissions in public.permissions
    IF to_regclass('public.permissions') IS NOT NULL THEN
        INSERT INTO public.permissions (id, module, description, created_at)
        VALUES
        ('history_sheeter:create', 'history_sheeter', 'Create History Sheeter records', NOW()),
        ('history_sheeter:view', 'history_sheeter', 'View History Sheeter records', NOW()),
        ('history_sheeter:update', 'history_sheeter', 'Update History Sheeter records', NOW()),
        ('history_sheeter:pdf', 'history_sheeter', 'Generate History Sheeter PDF', NOW())
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;
"""


def seed_hs_data(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_HS_SEED_UP)
    else:
        # Django ORM fallback for scratch SQLite test
        CaseCategory = apps.get_model('crimetab', 'CaseCategory')
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        OptionValue = apps.get_model('crimetab', 'OptionValue')
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')

        cat, _ = CaseCategory.objects.get_or_create(
            category_name='History Sheeter',
            defaults={'category_code': 'STAND_HISTORY_SHEETER', 'is_active': True, 'display_order': 600}
        )
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name='History Sheeter Template')
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)

        # Fields for History Sheeter
        hs_fields = [
            ('Name', 'hs_name', 'custom', 'text', False, 'Personal Information', 10, None, None, None, None),
            ('Alias', 'hs_alias', 'custom', 'text', False, 'Personal Information', 20, None, None, None, None),
            ('Nickname', 'hs_nickname', 'custom', 'text', False, 'Personal Information', 30, None, None, None, None),
            ('Age', 'hs_age', 'custom', 'number', False, 'Personal Information', 40, None, None, None, None),
            ('Gender', 'hs_gender', 'custom', 'dropdown', False, 'Personal Information', 50, None, None, '/api/options/gender/', None),
            ('Mobile No.', 'hs_mobile_no', 'custom', 'text', False, 'Personal Information', 60, None, None, None, None),
            ('Address', 'hs_address', 'custom', 'textarea', False, 'Personal Information', 70, None, None, None, None),
            ('Permanent Address', 'hs_permanent_address', 'custom', 'textarea', False, 'Personal Information', 80, None, None, None, None),
            ('Present Address', 'hs_present_address', 'custom', 'textarea', False, 'Personal Information', 90, None, None, None, None),
            ('Present Address Same As Above', 'hs_same_as_above', 'custom', 'checkbox', False, 'Personal Information', 95, None, None, None, None),
            ('Native Place', 'hs_native_place', 'custom', 'text', False, 'Personal Information', 100, None, None, None, None),
            ('Occupation', 'hs_occupation', 'custom', 'text', False, 'Personal Information', 110, None, None, None, None),
            ('Aadhaar / ID Details', 'hs_aadhaar_id_details', 'custom', 'text', False, 'Personal Information', 120, None, None, None, None),
            ('History Sheet No.', 'hs_history_sheet_no', 'custom', 'text', False, 'History Sheet Details', 130, None, None, None, None),
            ('Date of Opening History Sheet', 'hs_opening_date', 'custom', 'date', False, 'History Sheet Details', 140, None, None, None, None),
            ('Order Date', 'hs_order_date', 'custom', 'date', False, 'History Sheet Details', 150, None, None, None, None),
            ('Category / Type of History Sheeter', 'hs_category_type', 'custom', 'multi_select', False, 'History Sheet Details', 160, None, None, '/api/options/hs_category_types/', None),
            ('Other Category Details', 'hs_category_type_other', 'custom', 'text', False, 'History Sheet Details', 170, 'hs_category_type', 'Other', None, None),
            ('Criminal Activities / Modus Operandi', 'hs_modus_operandi', 'custom', 'textarea', False, 'History Sheet Details', 180, None, None, None, None),
            ('Total Criminal Cases', 'hs_total_cases', 'custom', 'number', False, 'Case Statistics', 190, None, None, None, None),
            ('Convicted Cases', 'hs_convicted_cases', 'custom', 'number', False, 'Case Statistics', 200, None, None, None, None),
            ('Pending Cases', 'hs_pending_cases', 'custom', 'number', False, 'Case Statistics', 210, None, None, None, None),
            ('Acquitted / Discharged Cases', 'hs_acquitted_discharged_cases', 'custom', 'number', False, 'Case Statistics', 220, None, None, None, None),
            ('Known Associates / Gang Members', 'hs_associates', 'custom', 'repeating_group', False, 'Known Associates / Gang Members', 230, None, None, None, None),
            ('Name', 'hs_assoc_name', 'custom', 'text', False, 'Known Associates / Gang Members', 231, None, None, None, 'hs_associates'),
            ('Alias', 'hs_assoc_alias', 'custom', 'text', False, 'Known Associates / Gang Members', 232, None, None, None, 'hs_associates'),
            ('Nickname', 'hs_assoc_nickname', 'custom', 'text', False, 'Known Associates / Gang Members', 233, None, None, None, 'hs_associates'),
            ('Age', 'hs_assoc_age', 'custom', 'number', False, 'Known Associates / Gang Members', 234, None, None, None, 'hs_associates'),
            ('Gender', 'hs_assoc_gender', 'custom', 'dropdown', False, 'Known Associates / Gang Members', 235, None, None, '/api/options/gender/', 'hs_associates'),
            ('Mobile No.', 'hs_assoc_mobile', 'custom', 'text', False, 'Known Associates / Gang Members', 236, None, None, None, 'hs_associates'),
            ('Address', 'hs_assoc_address', 'custom', 'textarea', False, 'Known Associates / Gang Members', 237, None, None, None, 'hs_associates'),
            ('Rival / Adverse Persons', 'hs_rivals', 'custom', 'repeating_group', False, 'Rival / Adverse Persons', 240, None, None, None, None),
            ('Name', 'hs_rival_name', 'custom', 'text', False, 'Rival / Adverse Persons', 241, None, None, None, 'hs_rivals'),
            ('Alias', 'hs_rival_alias', 'custom', 'text', False, 'Rival / Adverse Persons', 242, None, None, None, 'hs_rivals'),
            ('Nickname', 'hs_rival_nickname', 'custom', 'text', False, 'Rival / Adverse Persons', 243, None, None, None, 'hs_rivals'),
            ('Age', 'hs_rival_age', 'custom', 'number', False, 'Rival / Adverse Persons', 244, None, None, None, 'hs_rivals'),
            ('Gender', 'hs_rival_gender', 'custom', 'dropdown', False, 'Rival / Adverse Persons', 245, None, None, '/api/options/gender/', 'hs_rivals'),
            ('Mobile No.', 'hs_rival_mobile', 'custom', 'text', False, 'Rival / Adverse Persons', 246, None, None, None, 'hs_rivals'),
            ('Address', 'hs_rival_address', 'custom', 'textarea', False, 'Rival / Adverse Persons', 247, None, None, None, 'hs_rivals'),
            ('Bond / Surety Details', 'hs_sureties', 'custom', 'repeating_group', False, 'Bond / Surety Details', 250, None, None, None, None),
            ('Name', 'hs_surety_name', 'custom', 'text', False, 'Bond / Surety Details', 251, None, None, None, 'hs_sureties'),
            ('Alias', 'hs_surety_alias', 'custom', 'text', False, 'Bond / Surety Details', 252, None, None, None, 'hs_sureties'),
            ('Nickname', 'hs_surety_nickname', 'custom', 'text', False, 'Bond / Surety Details', 253, None, None, None, 'hs_sureties'),
            ('Age', 'hs_surety_age', 'custom', 'number', False, 'Bond / Surety Details', 254, None, None, None, 'hs_sureties'),
            ('Gender', 'hs_surety_gender', 'custom', 'dropdown', False, 'Bond / Surety Details', 255, None, None, '/api/options/gender/', 'hs_sureties'),
            ('Mobile No.', 'hs_surety_mobile', 'custom', 'text', False, 'Bond / Surety Details', 256, None, None, None, 'hs_sureties'),
            ('Address', 'hs_surety_address', 'custom', 'textarea', False, 'Bond / Surety Details', 257, None, None, None, 'hs_sureties'),
            ('Preventive Action Taken', 'hs_preventive_actions', 'custom', 'repeating_group', False, 'Preventive Action Taken', 260, None, None, None, None),
            ('Action Taken', 'hs_preventive_action_type', 'custom', 'dropdown', False, 'Preventive Action Taken', 261, None, None, '/api/options/hs_preventive_actions/', 'hs_preventive_actions'),
            ('Other Preventive Action Details', 'hs_preventive_action_other', 'custom', 'text', False, 'Preventive Action Taken', 262, 'hs_preventive_action_type', 'Other', None, 'hs_preventive_actions'),
            ('Current Whereabouts', 'hs_whereabouts', 'custom', 'textarea', False, 'Current Whereabouts & Verification', 270, None, None, None, None),
            ('Last Verification Date', 'hs_last_verification_date', 'custom', 'date', False, 'Current Whereabouts & Verification', 280, None, None, None, None),
            ('Verification Remarks', 'hs_verification_remarks', 'custom', 'textarea', False, 'Current Whereabouts & Verification', 290, None, None, None, None),
            ('Currently in Jail', 'hs_currently_in_jail', 'custom', 'dropdown', False, 'Current Whereabouts & Verification', 300, None, None, '/api/options/yes_no/', None),
            ('Currently on Bail', 'hs_currently_on_bail', 'custom', 'dropdown', False, 'Current Whereabouts & Verification', 310, None, None, '/api/options/yes_no/', None),
            ('Crime Chart', 'hs_crime_chart', 'custom', 'repeating_group', False, 'Crime Chart', 320, None, None, None, None),
            ('CR No.', 'hs_crime_cr_no', 'custom', 'text', False, 'Crime Chart', 321, None, None, None, 'hs_crime_chart'),
            ('Crime Head', 'hs_crime_head', 'custom', 'text', False, 'Crime Chart', 322, None, None, None, 'hs_crime_chart'),
            ('Act and Section', 'hs_crime_act_section', 'custom', 'text', False, 'Crime Chart', 323, None, None, None, 'hs_crime_chart'),
            ('Register Date', 'hs_crime_register_date', 'custom', 'date', False, 'Crime Chart', 324, None, None, None, 'hs_crime_chart'),
            ('Police Station', 'hs_crime_police_station', 'custom', 'text', False, 'Crime Chart', 325, None, None, None, 'hs_crime_chart'),
            ('Date of Closure', 'hs_closure_date', 'custom', 'date', False, 'Closed Status', 330, None, None, None, None),
            ('Reason for Closure', 'hs_closure_reason', 'custom', 'text', False, 'Closed Status', 340, None, None, None, None),
            ('Remarks', 'hs_closure_remarks', 'custom', 'textarea', False, 'Closed Status', 350, None, None, None, None),
        ]
        for flab, fkey, fsrc, ftyp, req, sec, dord, dep_k, dep_v, opt_src, p_k in hs_fields:
            FieldTemplateField.objects.get_or_create(
                template=tmpl, field_key=fkey,
                defaults={
                    'field_label': flab, 'field_source': fsrc, 'field_type': ftyp,
                    'is_required': req, 'section': sec, 'display_order': dord,
                    'depends_on_field_key': dep_k, 'depends_on_value': dep_v,
                    'options_source': opt_src, 'parent_field_key': p_k
                }
            )

        # Settings
        settings_rows = [
            ('target_category_code', 'STAND_HISTORY_SHEETER'),
            ('enforce_permissions', 'false'),
            ('word_limit_modus_operandi', '25'),
            ('word_limit_whereabouts', '25'),
            ('empty_request_message', 'Cannot save empty record. At least one field must be filled.'),
            ('tab_active_label', 'Active History Sheeter'),
            ('tab_open_label', 'History Sheet Open'),
            ('tab_closed_label', 'History Sheet Closed'),
            ('btn_edit_label', 'Edit'),
            ('btn_view_label', 'View'),
            ('btn_pdf_label', 'PDF'),
            ('date_format', '%d/%m/%Y'),
        ]
        for k, v in settings_rows:
            ModuleSetting.objects.get_or_create(module_key='history_sheeter', setting_key=k, defaults={'setting_value': v})

        # Options
        for opt, ord_val in [
            ('Body Offender', 10), ('Property Offender', 20), ('Narcotics / NDPS', 30),
            ('Prohibition / Liquor', 40), ('Gambling', 50), ('Against Women', 60),
            ('Extortion / Threat', 70), ('Organized Crime / Gang Member', 80),
            ('Weapon-Related', 90), ('Cyber Crime', 100), ('Other', 110),
        ]:
            OptionValue.objects.get_or_create(option_group='hs_category_types', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})

        for opt, ord_val in [
            ('Externment', 10), ('MPDA', 20), ('107 CrPC/126 BNSS', 30),
            ('109 CrPC/128 BNSS', 40), ('110 CrPC/129 BNSS', 50), ('151(3) CrPC/170 BNSS', 60),
            ('144 CrPC/163 BNSS', 70), ('149 CrPC/168 BNSS', 80), ('55 MPA', 90),
            ('56 MPA', 100), ('57 MPA', 110), ('122 MPA', 120), ('93 Prohibition Act', 130),
            ('Other', 140),
        ]:
            OptionValue.objects.get_or_create(option_group='hs_preventive_actions', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})

        # Permissions
        try:
            Permission = apps.get_model('public_master', 'Permission')
            for pid, desc in [
                ('history_sheeter:create', 'Create History Sheeter records'),
                ('history_sheeter:view', 'View History Sheeter records'),
                ('history_sheeter:update', 'Update History Sheeter records'),
                ('history_sheeter:pdf', 'Generate History Sheeter PDF'),
            ]:
                Permission.objects.get_or_create(id=pid, defaults={'module': 'history_sheeter', 'description': desc})
        except Exception:
            pass


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0039_add_parent_field_key_to_field_template_fields'),
    ]

    operations = [
        migrations.RunPython(
            seed_hs_data,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
