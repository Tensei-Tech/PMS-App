from django.db import migrations

"""
Migration 0046: MPDA Public Updates

Updates public schema configurations for MPDA:
1. Removes mpda_io_uid field template definition.
2. Splits mpda_proposal_no_and_year into mpda_proposal_no (text) and mpda_proposal_year (text).
3. Changes mpda_io_post to a dropdown backed by '/api/options/designations/'.
4. Updates mpda_crime_chart repeating group options_source to '/api/options/mpda_crime_types/'.
5. Seeds module setting crime_chart_group_by_field = 'mpda_crime_type' (ON CONFLICT DO NOTHING).

Idempotent and safe to run twice.
"""

SQL_MPDA_PUBLIC_UPDATES_UP = """
DO $$
DECLARE
    mpda_tmpl_id BIGINT;
BEGIN
    -- 1. Remove mpda_io_uid field definition
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        DELETE FROM public.field_template_fields WHERE field_key = 'mpda_io_uid';
    END IF;

    -- 2. Retrieve template ID for MPDA Proposal Template
    IF to_regclass('public.field_templates') IS NOT NULL THEN
        SELECT template_id INTO mpda_tmpl_id
        FROM public.field_templates
        WHERE template_name = 'MPDA Proposal Template'
        LIMIT 1;
    END IF;

    -- 3. Replace mpda_proposal_no_and_year with mpda_proposal_no and mpda_proposal_year
    IF to_regclass('public.field_template_fields') IS NOT NULL AND mpda_tmpl_id IS NOT NULL THEN
        DELETE FROM public.field_template_fields WHERE field_key = 'mpda_proposal_no_and_year';

        INSERT INTO public.field_template_fields
        (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source, parent_field_key)
        VALUES
        (mpda_tmpl_id, 'MPDA Proposal No.', 'mpda_proposal_no', 'custom', 'text', FALSE, 'Proposal Information', 10, NULL, NULL, NULL, NULL),
        (mpda_tmpl_id, 'MPDA Proposal Year', 'mpda_proposal_year', 'custom', 'text', FALSE, 'Proposal Information', 15, NULL, NULL, NULL, NULL)
        ON CONFLICT DO NOTHING;

        -- 4. Update mpda_io_post to dropdown backed by designations endpoint
        UPDATE public.field_template_fields
        SET field_type = 'dropdown',
            options_source = '/api/options/designations/'
        WHERE field_key = 'mpda_io_post';

        -- 5. Update mpda_crime_chart repeating group options source
        UPDATE public.field_template_fields
        SET options_source = '/api/options/mpda_crime_types/'
        WHERE field_key = 'mpda_crime_chart';
    END IF;

    -- 6. Ensure crime_chart_group_by_field module setting exists
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES ('mpda', 'crime_chart_group_by_field', 'mpda_crime_type')
        ON CONFLICT (module_key, setting_key) DO NOTHING;
    END IF;
END $$;
"""


def apply_mpda_public_updates(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_MPDA_PUBLIC_UPDATES_UP)
    else:
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')

        # 1. Delete mpda_io_uid
        FieldTemplateField.objects.filter(field_key='mpda_io_uid').delete()

        # 2. Split proposal no & year
        FieldTemplateField.objects.filter(field_key='mpda_proposal_no_and_year').delete()

        tmpl = FieldTemplate.objects.filter(template_name='MPDA Proposal Template').first()
        if tmpl:
            FieldTemplateField.objects.get_or_create(
                template=tmpl,
                field_key='mpda_proposal_no',
                defaults={
                    'field_label': 'MPDA Proposal No.',
                    'field_source': 'custom',
                    'field_type': 'text',
                    'is_required': False,
                    'section': 'Proposal Information',
                    'display_order': 10,
                }
            )
            FieldTemplateField.objects.get_or_create(
                template=tmpl,
                field_key='mpda_proposal_year',
                defaults={
                    'field_label': 'MPDA Proposal Year',
                    'field_source': 'custom',
                    'field_type': 'text',
                    'is_required': False,
                    'section': 'Proposal Information',
                    'display_order': 15,
                }
            )

        # 3. Update mpda_io_post to dropdown
        FieldTemplateField.objects.filter(field_key='mpda_io_post').update(
            field_type='dropdown',
            options_source='/api/options/designations/'
        )

        # 4. Update mpda_crime_chart options source
        FieldTemplateField.objects.filter(field_key='mpda_crime_chart').update(
            options_source='/api/options/mpda_crime_types/'
        )

        # 5. Seed module setting
        ModuleSetting.objects.get_or_create(
            module_key='mpda',
            setting_key='crime_chart_group_by_field',
            defaults={'setting_value': 'mpda_crime_type'}
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0045_history_sheeter_same_as_above_setting'),
    ]

    operations = [
        migrations.RunPython(
            apply_mpda_public_updates,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
