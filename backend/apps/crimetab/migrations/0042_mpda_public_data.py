from django.db import migrations

SQL_MPDA_SEED_UP = """
DO $$
DECLARE
    mpda_cat_id BIGINT;
    mpda_tmpl_id BIGINT;
BEGIN
    -- 1. Tab row in public.case_categories
    IF to_regclass('public.case_categories') IS NOT NULL THEN
        SELECT category_id INTO mpda_cat_id
        FROM public.case_categories
        WHERE category_name = 'MPDA' OR category_code = 'STAND_MPDA';

        IF mpda_cat_id IS NULL THEN
            LOCK TABLE public.case_categories IN EXCLUSIVE MODE;
            SELECT COALESCE(MAX(category_id), 0) + 1 INTO mpda_cat_id FROM public.case_categories;

            INSERT INTO public.case_categories (
                category_id, category_name, category_code, group_id, parent_category_id,
                template_id, is_active, display_order, created_at
            ) VALUES (
                mpda_cat_id, 'MPDA', 'STAND_MPDA', NULL, NULL,
                NULL, TRUE, (SELECT COALESCE(MAX(display_order), 0) + 10 FROM public.case_categories), NOW()
            );
        END IF;
    END IF;

    -- 2. Bundle "MPDA Proposal Template" in public.field_templates
    IF to_regclass('public.field_templates') IS NOT NULL THEN
        SELECT template_id INTO mpda_tmpl_id
        FROM public.field_templates
        WHERE template_name = 'MPDA Proposal Template';

        IF mpda_tmpl_id IS NULL THEN
            INSERT INTO public.field_templates (template_name, created_at)
            VALUES ('MPDA Proposal Template', NOW())
            RETURNING template_id INTO mpda_tmpl_id;
        END IF;

        -- 3. Link MPDA category to template in public.category_field_templates
        IF mpda_cat_id IS NOT NULL AND to_regclass('public.category_field_templates') IS NOT NULL THEN
            INSERT INTO public.category_field_templates (category_id, template_id)
            VALUES (mpda_cat_id, mpda_tmpl_id)
            ON CONFLICT DO NOTHING;
        END IF;

        -- 4. Create fields in public.field_template_fields for MPDA
        IF to_regclass('public.field_template_fields') IS NOT NULL THEN
            -- Proposal Information
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source, parent_field_key)
            VALUES
            (mpda_tmpl_id, 'MPDA proposal no & year', 'mpda_proposal_no_and_year', 'custom', 'text', FALSE, 'Proposal Information', 10, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'IO Name', 'mpda_io_name', 'custom', 'text', FALSE, 'Proposal Information', 20, NULL, NULL, '/api/mpda/officers/', NULL),
            (mpda_tmpl_id, 'IO Post', 'mpda_io_post', 'custom', 'text', FALSE, 'Proposal Information', 30, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'IO UID', 'mpda_io_uid', 'custom', 'text', FALSE, 'Proposal Information', 35, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Proposal Outcome', 'mpda_proposal_outcome', 'custom', 'radio', FALSE, 'Proposal Information', 40, NULL, NULL, '/api/options/mpda_outcomes/', NULL),
            (mpda_tmpl_id, 'Granted Date', 'mpda_granted_date', 'custom', 'date', FALSE, 'Proposal Information', 50, 'mpda_proposal_outcome', 'Granted', NULL, NULL),
            (mpda_tmpl_id, 'Rejected Date', 'mpda_rejected_date', 'custom', 'date', FALSE, 'Proposal Information', 60, 'mpda_proposal_outcome', 'Rejected', NULL, NULL),
            (mpda_tmpl_id, 'Detaining Authority', 'mpda_detaining_authority', 'custom', 'dropdown', FALSE, 'Proposal Information', 70, NULL, NULL, '/api/options/mpda_detaining_authorities/', NULL),
            (mpda_tmpl_id, 'Other Detaining Authority', 'mpda_detaining_authority_other', 'custom', 'text', FALSE, 'Proposal Information', 80, 'mpda_detaining_authority', 'Other', NULL, NULL),

            -- Accused Particulars
            (mpda_tmpl_id, 'Accused Name', 'mpda_accused_name', 'custom', 'text', FALSE, 'Accused Particulars', 90, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Aadhaar No.', 'mpda_accused_aadhaar', 'custom', 'text', FALSE, 'Accused Particulars', 100, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Mobile No.', 'mpda_accused_mobile', 'custom', 'text', FALSE, 'Accused Particulars', 110, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Address', 'mpda_accused_address', 'custom', 'textarea', FALSE, 'Accused Particulars', 120, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Age', 'mpda_accused_age', 'custom', 'number', FALSE, 'Accused Particulars', 130, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Gender', 'mpda_accused_gender', 'custom', 'dropdown', FALSE, 'Accused Particulars', 140, NULL, NULL, '/api/options/gender/', NULL),

            -- Gang / Group Members
            (mpda_tmpl_id, 'Gang / Group Member', 'mpda_gang_members', 'custom', 'repeating_group', FALSE, 'Gang / Group Members', 150, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Member Name', 'mpda_gang_member_name', 'custom', 'text', FALSE, 'Gang / Group Members', 151, NULL, NULL, NULL, 'mpda_gang_members'),

            -- Detention & Confirmation Details
            (mpda_tmpl_id, 'Detained', 'mpda_detained', 'custom', 'dropdown', FALSE, 'Detention & Confirmation Details', 160, NULL, NULL, '/api/options/yes_no/', NULL),
            (mpda_tmpl_id, 'Detention Date', 'mpda_detention_date', 'custom', 'date', FALSE, 'Detention & Confirmation Details', 170, 'mpda_detained', 'Yes', NULL, NULL),
            (mpda_tmpl_id, 'Detention Completion Date', 'mpda_detention_completion_date', 'custom', 'date', FALSE, 'Detention & Confirmation Details', 180, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Jail Name', 'mpda_jail_name', 'custom', 'text', FALSE, 'Detention & Confirmation Details', 190, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Transfer Jail Name', 'mpda_transfer_jail_name', 'custom', 'text', FALSE, 'Detention & Confirmation Details', 200, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Government Confirmation', 'mpda_govt_confirmation', 'custom', 'dropdown', FALSE, 'Detention & Confirmation Details', 210, NULL, NULL, '/api/options/yes_no/', NULL),
            (mpda_tmpl_id, 'Confirmation Date', 'mpda_govt_confirmation_date', 'custom', 'date', FALSE, 'Detention & Confirmation Details', 220, 'mpda_govt_confirmation', 'Yes', NULL, NULL),
            (mpda_tmpl_id, 'Detention Order Revoked', 'mpda_order_revoked', 'custom', 'dropdown', FALSE, 'Detention & Confirmation Details', 230, NULL, NULL, '/api/options/yes_no/', NULL),
            (mpda_tmpl_id, 'Revocation Date', 'mpda_order_revoked_date', 'custom', 'date', FALSE, 'Detention & Confirmation Details', 240, 'mpda_order_revoked', 'Yes', NULL, NULL),

            -- MPDA Category
            (mpda_tmpl_id, 'MPDA Category', 'mpda_category', 'custom', 'dropdown', FALSE, 'MPDA Category', 250, NULL, NULL, '/api/options/mpda_categories/', NULL),
            (mpda_tmpl_id, 'Other Category Details', 'mpda_category_other', 'custom', 'text', FALSE, 'MPDA Category', 260, 'mpda_category', 'Other', NULL, NULL),

            -- Crime Statistics & Crime Chart
            (mpda_tmpl_id, 'Total Crime', 'mpda_total_crime', 'custom', 'number', FALSE, 'Crime Statistics & Crime Chart', 270, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Serious Crimes', 'mpda_serious_crimes', 'custom', 'number', FALSE, 'Crime Statistics & Crime Chart', 280, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Crime Chart', 'mpda_crime_chart', 'custom', 'repeating_group', FALSE, 'Crime Statistics & Crime Chart', 290, NULL, NULL, NULL, NULL),
            (mpda_tmpl_id, 'Crime Type', 'mpda_crime_type', 'custom', 'dropdown', FALSE, 'Crime Statistics & Crime Chart', 291, NULL, NULL, '/api/options/mpda_crime_types/', 'mpda_crime_chart'),
            (mpda_tmpl_id, 'CR No.', 'mpda_crime_cr_no', 'custom', 'text', FALSE, 'Crime Statistics & Crime Chart', 292, NULL, NULL, NULL, 'mpda_crime_chart'),
            (mpda_tmpl_id, 'Date', 'mpda_crime_date', 'custom', 'date', FALSE, 'Crime Statistics & Crime Chart', 293, NULL, NULL, NULL, 'mpda_crime_chart'),
            (mpda_tmpl_id, 'Police Station', 'mpda_crime_police_station', 'custom', 'text', FALSE, 'Crime Statistics & Crime Chart', 294, NULL, NULL, NULL, 'mpda_crime_chart')
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- 5. Seed Option Values in public.option_values
    IF to_regclass('public.option_values') IS NOT NULL THEN
        -- Proposal Outcomes (Radio)
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES
        ('mpda_outcomes', 'Granted', 10, TRUE),
        ('mpda_outcomes', 'Rejected', 20, TRUE)
        ON CONFLICT DO NOTHING;

        -- Detaining Authorities
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES
        ('mpda_detaining_authorities', 'DM', 10, TRUE),
        ('mpda_detaining_authorities', 'CP', 20, TRUE),
        ('mpda_detaining_authorities', 'Other', 30, TRUE)
        ON CONFLICT DO NOTHING;

        -- MPDA Categories
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES
        ('mpda_categories', 'Dangerous Person', 10, TRUE),
        ('mpda_categories', 'Bootlegger', 20, TRUE),
        ('mpda_categories', 'Drug Offender', 30, TRUE),
        ('mpda_categories', 'Slumlord', 40, TRUE),
        ('mpda_categories', 'Video Pirate', 50, TRUE),
        ('mpda_categories', 'Sand Smuggler', 60, TRUE),
        ('mpda_categories', 'Black-Marketing', 70, TRUE),
        ('mpda_categories', 'Other', 80, TRUE)
        ON CONFLICT DO NOTHING;

        -- 12 MPDA Crime Types
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES
        ('mpda_crime_types', 'Crimes against the body', 10, TRUE),
        ('mpda_crime_types', 'Crimes against property', 20, TRUE),
        ('mpda_crime_types', 'Crimes against women', 30, TRUE),
        ('mpda_crime_types', 'Extortion', 40, TRUE),
        ('mpda_crime_types', 'Murder', 50, TRUE),
        ('mpda_crime_types', 'Attempted murder', 60, TRUE),
        ('mpda_crime_types', 'Robbery', 70, TRUE),
        ('mpda_crime_types', 'Assault', 80, TRUE),
        ('mpda_crime_types', 'Arms Act', 90, TRUE),
        ('mpda_crime_types', 'NDPS', 100, TRUE),
        ('mpda_crime_types', 'Prohibition', 110, TRUE),
        ('mpda_crime_types', 'Other special', 120, TRUE)
        ON CONFLICT DO NOTHING;
    END IF;

    -- 6. Seed Module Settings in public.module_settings
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES
        ('mpda', 'target_category_code', 'STAND_MPDA'),
        ('mpda', 'enforce_permissions', 'false'),
        ('mpda', 'max_gang_members', '5'),
        ('mpda', 'empty_request_message', 'Cannot save empty record. At least one field must be filled.'),
        ('mpda', 'crime_chart_group_by_field', 'mpda_crime_type'),
        ('mpda', 'card_total_label', 'Total MPDA proposal'),
        ('mpda', 'card_approved_label', 'Approved MPDA'),
        ('mpda', 'card_rejected_label', 'Rejected MPDA'),
        ('mpda', 'card_jail_label', 'Total person in jail under MPDA'),
        ('mpda', 'card_revoked_label', 'Total MPDA revoked'),
        ('mpda', 'card_released_next_month_label', 'Released in next month'),
        ('mpda', 'tab_total_label', 'Total MPDA proposal'),
        ('mpda', 'tab_approved_label', 'Approved MPDA'),
        ('mpda', 'tab_rejected_label', 'Rejected MPDA'),
        ('mpda', 'tab_jail_label', 'Total person in jail under MPDA'),
        ('mpda', 'tab_revoked_label', 'Total MPDA revoked'),
        ('mpda', 'tab_released_next_month_label', 'Released in next month'),
        ('mpda', 'btn_edit_label', 'Edit'),
        ('mpda', 'btn_view_label', 'View'),
        ('mpda', 'btn_pdf_label', 'PDF')
        ON CONFLICT DO NOTHING;

        -- Global / module date format if not present
        IF NOT EXISTS (
            SELECT 1 FROM public.module_settings 
            WHERE module_key = 'mpda' AND setting_key = 'date_format'
        ) THEN
            INSERT INTO public.module_settings (module_key, setting_key, setting_value)
            VALUES ('mpda', 'date_format', '%%d/%%m/%%Y');
        END IF;
    END IF;

    -- 7. Seed Permissions in public.permissions
    IF to_regclass('public.permissions') IS NOT NULL THEN
        INSERT INTO public.permissions (id, module, description, created_at)
        VALUES
        ('mpda:create', 'mpda', 'Create MPDA proposals', NOW()),
        ('mpda:view', 'mpda', 'View MPDA proposals', NOW()),
        ('mpda:update', 'mpda', 'Update MPDA proposals', NOW()),
        ('mpda:pdf', 'mpda', 'Generate MPDA proposal PDF', NOW())
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
"""


def seed_mpda_data(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_MPDA_SEED_UP)
    else:
        # Django ORM fallback for scratch SQLite test
        CaseCategory = apps.get_model('crimetab', 'CaseCategory')
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        OptionValue = apps.get_model('crimetab', 'OptionValue')
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')

        cat, _ = CaseCategory.objects.get_or_create(
            category_name='MPDA',
            defaults={'category_code': 'STAND_MPDA', 'is_active': True, 'display_order': 610}
        )
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name='MPDA Proposal Template')
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)

        # Fields for MPDA
        mpda_fields = [
            ('MPDA proposal no & year', 'mpda_proposal_no_and_year', 'custom', 'text', False, 'Proposal Information', 10, None, None, None, None),
            ('IO Name', 'mpda_io_name', 'custom', 'text', False, 'Proposal Information', 20, None, None, '/api/mpda/officers/', None),
            ('IO Post', 'mpda_io_post', 'custom', 'text', False, 'Proposal Information', 30, None, None, None, None),
            ('IO UID', 'mpda_io_uid', 'custom', 'text', False, 'Proposal Information', 35, None, None, None, None),
            ('Proposal Outcome', 'mpda_proposal_outcome', 'custom', 'radio', False, 'Proposal Information', 40, None, None, '/api/options/mpda_outcomes/', None),
            ('Granted Date', 'mpda_granted_date', 'custom', 'date', False, 'Proposal Information', 50, 'mpda_proposal_outcome', 'Granted', None, None),
            ('Rejected Date', 'mpda_rejected_date', 'custom', 'date', False, 'Proposal Information', 60, 'mpda_proposal_outcome', 'Rejected', None, None),
            ('Detaining Authority', 'mpda_detaining_authority', 'custom', 'dropdown', False, 'Proposal Information', 70, None, None, '/api/options/mpda_detaining_authorities/', None),
            ('Other Detaining Authority', 'mpda_detaining_authority_other', 'custom', 'text', False, 'Proposal Information', 80, 'mpda_detaining_authority', 'Other', None, None),
            ('Accused Name', 'mpda_accused_name', 'custom', 'text', False, 'Accused Particulars', 90, None, None, None, None),
            ('Aadhaar No.', 'mpda_accused_aadhaar', 'custom', 'text', False, 'Accused Particulars', 100, None, None, None, None),
            ('Mobile No.', 'mpda_accused_mobile', 'custom', 'text', False, 'Accused Particulars', 110, None, None, None, None),
            ('Address', 'mpda_accused_address', 'custom', 'textarea', False, 'Accused Particulars', 120, None, None, None, None),
            ('Age', 'mpda_accused_age', 'custom', 'number', False, 'Accused Particulars', 130, None, None, None, None),
            ('Gender', 'mpda_accused_gender', 'custom', 'dropdown', False, 'Accused Particulars', 140, None, None, '/api/options/gender/', None),
            ('Gang / Group Member', 'mpda_gang_members', 'custom', 'repeating_group', False, 'Gang / Group Members', 150, None, None, None, None),
            ('Member Name', 'mpda_gang_member_name', 'custom', 'text', False, 'Gang / Group Members', 151, None, None, None, 'mpda_gang_members'),
            ('Detained', 'mpda_detained', 'custom', 'dropdown', False, 'Detention & Confirmation Details', 160, None, None, '/api/options/yes_no/', None),
            ('Detention Date', 'mpda_detention_date', 'custom', 'date', False, 'Detention & Confirmation Details', 170, 'mpda_detained', 'Yes', None, None),
            ('Detention Completion Date', 'mpda_detention_completion_date', 'custom', 'date', False, 'Detention & Confirmation Details', 180, None, None, None, None),
            ('Jail Name', 'mpda_jail_name', 'custom', 'text', False, 'Detention & Confirmation Details', 190, None, None, None, None),
            ('Transfer Jail Name', 'mpda_transfer_jail_name', 'custom', 'text', False, 'Detention & Confirmation Details', 200, None, None, None, None),
            ('Government Confirmation', 'mpda_govt_confirmation', 'custom', 'dropdown', False, 'Detention & Confirmation Details', 210, None, None, '/api/options/yes_no/', None),
            ('Confirmation Date', 'mpda_govt_confirmation_date', 'custom', 'date', False, 'Detention & Confirmation Details', 220, 'mpda_govt_confirmation', 'Yes', None, None),
            ('Detention Order Revoked', 'mpda_order_revoked', 'custom', 'dropdown', False, 'Detention & Confirmation Details', 230, None, None, '/api/options/yes_no/', None),
            ('Revocation Date', 'mpda_order_revoked_date', 'custom', 'date', False, 'Detention & Confirmation Details', 240, 'mpda_order_revoked', 'Yes', None, None),
            ('MPDA Category', 'mpda_category', 'custom', 'dropdown', False, 'MPDA Category', 250, None, None, '/api/options/mpda_categories/', None),
            ('Other Category Details', 'mpda_category_other', 'custom', 'text', False, 'MPDA Category', 260, 'mpda_category', 'Other', None, None),
            ('Total Crime', 'mpda_total_crime', 'custom', 'number', False, 'Crime Statistics & Crime Chart', 270, None, None, None, None),
            ('Serious Crimes', 'mpda_serious_crimes', 'custom', 'number', False, 'Crime Statistics & Crime Chart', 280, None, None, None, None),
            ('Crime Chart', 'mpda_crime_chart', 'custom', 'repeating_group', False, 'Crime Statistics & Crime Chart', 290, None, None, None, None),
            ('Crime Type', 'mpda_crime_type', 'custom', 'dropdown', False, 'Crime Statistics & Crime Chart', 291, None, None, '/api/options/mpda_crime_types/', 'mpda_crime_chart'),
            ('CR No.', 'mpda_crime_cr_no', 'custom', 'text', False, 'Crime Statistics & Crime Chart', 292, None, None, None, 'mpda_crime_chart'),
            ('Date', 'mpda_crime_date', 'custom', 'date', False, 'Crime Statistics & Crime Chart', 293, None, None, None, 'mpda_crime_chart'),
            ('Police Station', 'mpda_crime_police_station', 'custom', 'text', False, 'Crime Statistics & Crime Chart', 294, None, None, None, 'mpda_crime_chart'),
        ]
        for flab, fkey, fsrc, ftyp, req, sec, dord, dep_k, dep_v, opt_src, p_k in mpda_fields:
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
            ('target_category_code', 'STAND_MPDA'),
            ('enforce_permissions', 'false'),
            ('max_gang_members', '5'),
            ('empty_request_message', 'Cannot save empty record. At least one field must be filled.'),
            ('crime_chart_group_by_field', 'mpda_crime_type'),
            ('card_total_label', 'Total MPDA proposal'),
            ('card_approved_label', 'Approved MPDA'),
            ('card_rejected_label', 'Rejected MPDA'),
            ('card_jail_label', 'Total person in jail under MPDA'),
            ('card_revoked_label', 'Total MPDA revoked'),
            ('card_released_next_month_label', 'Released in next month'),
            ('tab_total_label', 'Total MPDA proposal'),
            ('tab_approved_label', 'Approved MPDA'),
            ('tab_rejected_label', 'Rejected MPDA'),
            ('tab_jail_label', 'Total person in jail under MPDA'),
            ('tab_revoked_label', 'Total MPDA revoked'),
            ('tab_released_next_month_label', 'Released in next month'),
            ('btn_edit_label', 'Edit'),
            ('btn_view_label', 'View'),
            ('btn_pdf_label', 'PDF'),
            ('date_format', '%d/%m/%Y'),
        ]
        for k, v in settings_rows:
            ModuleSetting.objects.get_or_create(module_key='mpda', setting_key=k, defaults={'setting_value': v})

        # Options
        for opt, ord_val in [('Granted', 10), ('Rejected', 20)]:
            OptionValue.objects.get_or_create(option_group='mpda_outcomes', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})

        for opt, ord_val in [('DM', 10), ('CP', 20), ('Other', 30)]:
            OptionValue.objects.get_or_create(option_group='mpda_detaining_authorities', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})

        for opt, ord_val in [
            ('Dangerous Person', 10), ('Bootlegger', 20), ('Drug Offender', 30),
            ('Slumlord', 40), ('Video Pirate', 50), ('Sand Smuggler', 60),
            ('Black-Marketing', 70), ('Other', 80),
        ]:
            OptionValue.objects.get_or_create(option_group='mpda_categories', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})

        for opt, ord_val in [
            ('Crimes against the body', 10), ('Crimes against property', 20),
            ('Crimes against women', 30), ('Extortion', 40), ('Murder', 50),
            ('Attempted murder', 60), ('Robbery', 70), ('Assault', 80),
            ('Arms Act', 90), ('NDPS', 100), ('Prohibition', 110),
            ('Other special', 120),
        ]:
            OptionValue.objects.get_or_create(option_group='mpda_crime_types', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})

        # Permissions
        try:
            Permission = apps.get_model('public_master', 'Permission')
            for pid, desc in [
                ('mpda:create', 'Create MPDA proposals'),
                ('mpda:view', 'View MPDA proposals'),
                ('mpda:update', 'Update MPDA proposals'),
                ('mpda:pdf', 'Generate MPDA proposal PDF'),
            ]:
                Permission.objects.get_or_create(id=pid, defaults={'module': 'mpda', 'description': desc})
        except Exception:
            pass


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0041_history_sheeter_tenant_tables'),
    ]

    operations = [
        migrations.RunPython(
            seed_mpda_data,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
