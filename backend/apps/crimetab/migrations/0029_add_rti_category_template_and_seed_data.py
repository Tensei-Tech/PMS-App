from django.db import migrations

# Note: This migration is one-way.
SQL_RTI_SEED_UP = """
DO $$
DECLARE
    rti_cat_id BIGINT;
    rti_tmpl_id BIGINT;
BEGIN
    -- 1. Tab row in public.case_categories
    IF to_regclass('public.case_categories') IS NOT NULL THEN
        SELECT category_id INTO rti_cat_id
        FROM public.case_categories
        WHERE category_name = 'RTI' OR category_code = 'STAND_RTI';

        IF rti_cat_id IS NULL THEN
            LOCK TABLE public.case_categories IN EXCLUSIVE MODE;
            SELECT COALESCE(MAX(category_id), 0) + 1 INTO rti_cat_id FROM public.case_categories;
            
            INSERT INTO public.case_categories (
                category_id, category_name, category_code, group_id, parent_category_id,
                template_id, is_active, display_order, created_at
            ) VALUES (
                rti_cat_id, 'RTI', 'STAND_RTI', NULL, NULL,
                NULL, TRUE, (SELECT COALESCE(MAX(display_order), 0) + 10 FROM public.case_categories), NOW()
            );
        END IF;
    END IF;

    -- 2. Bundle "RTI Form" in public.field_templates
    IF to_regclass('public.field_templates') IS NOT NULL THEN
        SELECT template_id INTO rti_tmpl_id
        FROM public.field_templates
        WHERE template_name = 'RTI Form';

        IF rti_tmpl_id IS NULL THEN
            INSERT INTO public.field_templates (template_name, created_at)
            VALUES ('RTI Form', NOW())
            RETURNING template_id INTO rti_tmpl_id;
        END IF;

        -- 3. Link RTI category to "RTI Form" template ONLY in public.category_field_templates
        IF rti_cat_id IS NOT NULL AND to_regclass('public.category_field_templates') IS NOT NULL THEN
            INSERT INTO public.category_field_templates (category_id, template_id)
            VALUES (rti_cat_id, rti_tmpl_id)
            ON CONFLICT DO NOTHING;
        END IF;

        -- 4. Create fields in public.field_template_fields for "RTI Form" template
        IF to_regclass('public.field_template_fields') IS NOT NULL THEN
            -- Section: Application Details
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Received Date', 'rti_received_date', 'custom', 'date', FALSE, 'Application Details', 10, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Due Date', 'rti_due_date', 'custom', 'date', FALSE, 'Application Details', 20, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Mode of Receipt', 'rti_mode_of_receipt', 'custom', 'dropdown', FALSE, 'Application Details', 30, NULL, NULL, '/api/options/rti_mode_of_receipt/')
            ON CONFLICT DO NOTHING;

            -- Section: Application Details
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Applicant Name', 'rti_applicant_name', 'custom', 'text', FALSE, 'Application Details', 40, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Age', 'rti_applicant_age', 'custom', 'number', FALSE, 'Application Details', 50, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Mobile No.', 'rti_mobile_no', 'custom', 'text', FALSE, 'Application Details', 60, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Address', 'rti_address', 'custom', 'textarea', FALSE, 'Application Details', 70, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'E-mail', 'rti_email', 'custom', 'text', FALSE, 'Application Details', 80, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'BPL', 'rti_is_bpl', 'custom', 'radio', FALSE, 'Application Details', 90, NULL, NULL, '/api/options/yes_no/')
            ON CONFLICT DO NOTHING;

            -- Section: Information Requested
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Type of Info', 'rti_info_type', 'custom', 'dropdown', FALSE, 'Information Requested', 100, NULL, NULL, '/api/options/rti_info_type/')
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Other (specify)', 'rti_info_type_other', 'custom', 'text', FALSE, 'Information Requested', 110, 'rti_info_type', 'Other', NULL)
            ON CONFLICT DO NOTHING;

            -- Section: Assigned Officer
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Assigned Officer', 'rti_assigned_officer', 'custom', 'dropdown', FALSE, 'Assigned Officer', 120, NULL, NULL, '/api/rti/officers/')
            ON CONFLICT DO NOTHING;

            -- Section: Outcome
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Outcome', 'rti_outcome', 'custom', 'radio', FALSE, 'Outcome', 130, NULL, NULL, '/api/options/rti_outcome/')
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Replied Date', 'rti_replied_date', 'custom', 'date', FALSE, 'Outcome', 140, 'rti_outcome', 'Replied', NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Rejected Date', 'rti_rejected_date', 'custom', 'date', FALSE, 'Outcome', 150, 'rti_outcome', 'Rejected', NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Reason for Rejection', 'rti_rejection_reason', 'custom', 'textarea', FALSE, 'Outcome', 160, 'rti_outcome', 'Rejected', NULL)
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Transfer To', 'rti_transferred_to', 'custom', 'textarea', FALSE, 'Outcome', 170, 'rti_outcome', 'Transferred', NULL)
            ON CONFLICT DO NOTHING;

            -- Section: Remark
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Remark', 'rti_remark', 'custom', 'textarea', FALSE, 'Remark', 180, NULL, NULL, NULL)
            ON CONFLICT DO NOTHING;

            -- Section: Appeal
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Appealed', 'rti_appealed', 'custom', 'radio', FALSE, 'Appeal', 190, NULL, NULL, '/api/options/yes_no/')
            ON CONFLICT DO NOTHING;

            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source)
            VALUES (rti_tmpl_id, 'Appeal Date', 'rti_appeal_date', 'custom', 'date', FALSE, 'Appeal', 200, 'rti_appealed', 'Yes', NULL)
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- 5. Seed public.option_values rows
    IF to_regclass('public.option_values') IS NOT NULL THEN
        -- rti_mode_of_receipt
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES ('rti_mode_of_receipt', 'Online', 10, TRUE),
               ('rti_mode_of_receipt', 'Post', 20, TRUE),
               ('rti_mode_of_receipt', 'In person', 30, TRUE),
               ('rti_mode_of_receipt', 'Email', 40, TRUE)
        ON CONFLICT (option_group, option_value) DO NOTHING;

        -- rti_info_type
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES ('rti_info_type', 'Crime record', 10, TRUE),
               ('rti_info_type', 'Personal', 20, TRUE),
               ('rti_info_type', 'Missing', 30, TRUE),
               ('rti_info_type', 'Accident record', 40, TRUE),
               ('rti_info_type', 'Other', 50, TRUE)
        ON CONFLICT (option_group, option_value) DO NOTHING;

        -- rti_outcome
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES ('rti_outcome', 'Replied', 10, TRUE),
               ('rti_outcome', 'Rejected', 20, TRUE),
               ('rti_outcome', 'Transferred', 30, TRUE)
        ON CONFLICT (option_group, option_value) DO NOTHING;

        -- yes_no
        INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
        VALUES ('yes_no', 'Yes', 10, TRUE),
               ('yes_no', 'No', 20, TRUE)
        ON CONFLICT (option_group, option_value) DO NOTHING;
    END IF;

    -- 6. Seed public.module_settings rows
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES ('rti', 'due_days', '30'),
               ('rti', 'max_words_reason', '20'),
               ('rti', 'max_words_transfer', '20'),
               ('rti', 'max_words_remark', '20'),
               ('rti', 'max_chars_info_other', '20'),
               ('rti', 'page_size', '20'),
               ('rti', 'status_pending_label', 'Pending'),
               ('rti', 'status_disposal_label', 'Disposal'),
               ('rti', 'tab_total_label', 'Total'),
               ('rti', 'tab_pending_label', 'Pending'),
               ('rti', 'tab_disposal_label', 'Disposal'),
               ('rti', 'action_edit_label', 'Edit'),
               ('rti', 'action_view_label', 'View'),
               ('rti', 'action_pdf_label', 'PDF'),
               ('rti', 'add_button_label', 'Add RTI Application'),
               ('rti', 'serial_label', 'Sr. No.'),
               ('rti', 'empty_list_message', 'No RTI applications found'),
               ('common', 'no_form_message', 'No form configured for this tab')
        ON CONFLICT (module_key, setting_key) DO NOTHING;
    END IF;

    -- 7. Seed permissions in public.permissions (if permissions table exists)
    IF to_regclass('public.permissions') IS NOT NULL THEN
        INSERT INTO public.permissions (id, module, description, created_at)
        VALUES ('rti:create', 'rti', 'Create RTI Application', NOW()),
               ('rti:view', 'rti', 'View RTI Application', NOW()),
               ('rti:update', 'rti', 'Update RTI Application', NOW()),
               ('rti:pdf', 'rti', 'Generate RTI PDF', NOW())
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;
"""


def seed_rti_data(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_RTI_SEED_UP)
    else:
        # Django ORM fallback for SQLite scratch test
        CaseCategory = apps.get_model('crimetab', 'CaseCategory')
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        OptionValue = apps.get_model('crimetab', 'OptionValue')
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')

        # 1. Tab row
        cat, _ = CaseCategory.objects.get_or_create(
            category_name='RTI',
            defaults={'category_code': 'STAND_RTI', 'is_active': True, 'display_order': 500}
        )

        # 2. Bundle "RTI Form"
        tmpl, _ = FieldTemplate.objects.get_or_create(
            template_name='RTI Form'
        )

        # 3. Link
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)

        # 4. Fields
        field_defs = [
            ('rti_received_date', 'Received Date', 'date', False, 'Application Details', 10, None, None, None),
            ('rti_due_date', 'Due Date', 'date', False, 'Application Details', 20, None, None, None),
            ('rti_mode_of_receipt', 'Mode of Receipt', 'dropdown', False, 'Application Details', 30, None, None, '/api/options/rti_mode_of_receipt/'),
            ('rti_applicant_name', 'Applicant Name', 'text', False, 'Application Details', 40, None, None, None),
            ('rti_applicant_age', 'Age', 'number', False, 'Application Details', 50, None, None, None),
            ('rti_mobile_no', 'Mobile No.', 'text', False, 'Application Details', 60, None, None, None),
            ('rti_address', 'Address', 'textarea', False, 'Application Details', 70, None, None, None),
            ('rti_email', 'E-mail', 'text', False, 'Application Details', 80, None, None, None),
            ('rti_is_bpl', 'BPL', 'radio', False, 'Application Details', 90, None, None, '/api/options/yes_no/'),
            ('rti_info_type', 'Type of Info', 'dropdown', False, 'Information Requested', 100, None, None, '/api/options/rti_info_type/'),
            ('rti_info_type_other', 'Other (specify)', 'text', False, 'Information Requested', 110, 'rti_info_type', 'Other', None),
            ('rti_assigned_officer', 'Assigned Officer', 'dropdown', False, 'Assigned Officer', 120, None, None, '/api/rti/officers/'),
            ('rti_outcome', 'Outcome', 'radio', False, 'Outcome', 130, None, None, '/api/options/rti_outcome/'),
            ('rti_replied_date', 'Replied Date', 'date', False, 'Outcome', 140, 'rti_outcome', 'Replied', None),
            ('rti_rejected_date', 'Rejected Date', 'date', False, 'Outcome', 150, 'rti_outcome', 'Rejected', None),
            ('rti_rejection_reason', 'Reason for Rejection', 'textarea', False, 'Outcome', 160, 'rti_outcome', 'Rejected', None),
            ('rti_transferred_to', 'Transfer To', 'textarea', False, 'Outcome', 170, 'rti_outcome', 'Transferred', None),
            ('rti_remark', 'Remark', 'textarea', False, 'Remark', 180, None, None, None),
            ('rti_appealed', 'Appealed', 'radio', False, 'Appeal', 190, None, None, '/api/options/yes_no/'),
            ('rti_appeal_date', 'Appeal Date', 'date', False, 'Appeal', 200, 'rti_appealed', 'Yes', None),
        ]

        for key, label, f_type, req, sec, order, dep_k, dep_v, opt_src in field_defs:
            FieldTemplateField.objects.get_or_create(
                template=tmpl,
                field_key=key,
                defaults={
                    'field_label': label,
                    'field_source': 'custom',
                    'field_type': f_type,
                    'is_required': req,
                    'section': sec,
                    'display_order': order,
                    'depends_on_field_key': dep_k,
                    'depends_on_value': dep_v,
                    'options_source': opt_src,
                }
            )

        # 5. Option values
        option_rows = [
            ('rti_mode_of_receipt', 'Online', 10),
            ('rti_mode_of_receipt', 'Post', 20),
            ('rti_mode_of_receipt', 'In person', 30),
            ('rti_mode_of_receipt', 'Email', 40),
            ('rti_info_type', 'Crime record', 10),
            ('rti_info_type', 'Personal', 20),
            ('rti_info_type', 'Missing', 30),
            ('rti_info_type', 'Accident record', 40),
            ('rti_info_type', 'Other', 50),
            ('rti_outcome', 'Replied', 10),
            ('rti_outcome', 'Rejected', 20),
            ('rti_outcome', 'Transferred', 30),
            ('yes_no', 'Yes', 10),
            ('yes_no', 'No', 20),
        ]
        for grp, val, order in option_rows:
            OptionValue.objects.get_or_create(
                option_group=grp,
                option_value=val,
                defaults={'display_order': order, 'is_active': True}
            )

        # 6. Module settings
        settings_rows = [
            ('rti', 'due_days', '30'),
            ('rti', 'max_words_reason', '20'),
            ('rti', 'max_words_transfer', '20'),
            ('rti', 'max_words_remark', '20'),
            ('rti', 'max_chars_info_other', '20'),
            ('rti', 'page_size', '20'),
            ('rti', 'status_pending_label', 'Pending'),
            ('rti', 'status_disposal_label', 'Disposal'),
            ('rti', 'tab_total_label', 'Total'),
            ('rti', 'tab_pending_label', 'Pending'),
            ('rti', 'tab_disposal_label', 'Disposal'),
            ('rti', 'action_edit_label', 'Edit'),
            ('rti', 'action_view_label', 'View'),
            ('rti', 'action_pdf_label', 'PDF'),
            ('rti', 'add_button_label', 'Add RTI Application'),
            ('rti', 'serial_label', 'Sr. No.'),
            ('rti', 'empty_list_message', 'No RTI applications found'),
            ('common', 'no_form_message', 'No form configured for this tab'),
        ]
        for m_key, s_key, s_val in settings_rows:
            ModuleSetting.objects.get_or_create(
                module_key=m_key,
                setting_key=s_key,
                defaults={'setting_value': s_val}
            )

        # 7. Permissions
        Permission = apps.get_model('public_master', 'Permission')
        perm_rows = [
            ('rti:create', 'rti', 'Create RTI Application'),
            ('rti:view', 'rti', 'View RTI Application'),
            ('rti:update', 'rti', 'Update RTI Application'),
            ('rti:pdf', 'rti', 'Generate RTI PDF'),
        ]
        for p_id, p_mod, p_desc in perm_rows:
            Permission.objects.get_or_create(
                id=p_id,
                defaults={'module': p_mod, 'description': p_desc}
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0028_add_module_settings'),
    ]

    operations = [
        migrations.RunPython(
            seed_rti_data,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
