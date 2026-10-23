from django.db import migrations

"""
Migration 0048: MPDA Accused Repeating Group & Public Updates

1. Replaces the 6 flat accused field definitions with 1 repeating group (mpda_accused)
   and 10 child fields (parent_field_key = 'mpda_accused'):
   - Name, Age, Gender, Mobile, Aadhaar, Address, Occupation, PAN card, Cast, Religion
   (Labels exactly as written; Gender reads /api/options/gender/).
2. Renames template section headings:
   - 'Accused Particulars' -> 'Accused detail'
   - 'Crime Statistics & Crime Chart' -> 'Crime Chart'
3. Deletes 'gang_members_max_items' setting from public.module_settings (module_key = 'mpda').

Total field definitions in MPDA Proposal Template after migration: exactly 40.
"""

SQL_MPDA_PUBLIC_UPDATES_0048_UP = """
DO $$
DECLARE
    mpda_tmpl_id BIGINT;
BEGIN
    IF to_regclass('public.field_templates') IS NOT NULL THEN
        SELECT template_id INTO mpda_tmpl_id
        FROM public.field_templates
        WHERE template_name = 'MPDA Proposal Template'
        LIMIT 1;
    END IF;

    IF mpda_tmpl_id IS NOT NULL AND to_regclass('public.field_template_fields') IS NOT NULL THEN
        -- 1. Rename existing section headings
        UPDATE public.field_template_fields
        SET section = 'Accused detail'
        WHERE template_id = mpda_tmpl_id AND section = 'Accused Particulars';

        UPDATE public.field_template_fields
        SET section = 'Crime Chart'
        WHERE template_id = mpda_tmpl_id AND section = 'Crime Statistics & Crime Chart';

        -- 2. Remove the 6 old flat accused field definitions
        DELETE FROM public.field_template_fields
        WHERE template_id = mpda_tmpl_id
          AND field_key IN (
            'mpda_accused_name',
            'mpda_accused_aadhaar',
            'mpda_accused_mobile',
            'mpda_accused_address',
            'mpda_accused_age',
            'mpda_accused_gender'
          );

        -- 3. Insert 1 repeating group and 10 child fields
        INSERT INTO public.field_template_fields
        (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, depends_on_field_key, depends_on_value, options_source, parent_field_key)
        VALUES
        (mpda_tmpl_id, 'Accused', 'mpda_accused', 'custom', 'repeating_group', FALSE, 'Accused detail', 90, NULL, NULL, NULL, NULL),
        (mpda_tmpl_id, 'Name', 'mpda_accused_name', 'custom', 'text', FALSE, 'Accused detail', 91, NULL, NULL, NULL, 'mpda_accused'),
        (mpda_tmpl_id, 'Age', 'mpda_accused_age', 'custom', 'number', FALSE, 'Accused detail', 92, NULL, NULL, NULL, 'mpda_accused'),
        (mpda_tmpl_id, 'Gender', 'mpda_accused_gender', 'custom', 'dropdown', FALSE, 'Accused detail', 93, NULL, NULL, '/api/options/gender/', 'mpda_accused'),
        (mpda_tmpl_id, 'Mobile', 'mpda_accused_mobile', 'custom', 'text', FALSE, 'Accused detail', 94, NULL, NULL, NULL, 'mpda_accused'),
        (mpda_tmpl_id, 'Aadhaar', 'mpda_accused_aadhaar', 'custom', 'text', FALSE, 'Accused detail', 95, NULL, NULL, NULL, 'mpda_accused'),
        (mpda_tmpl_id, 'Address', 'mpda_accused_address', 'custom', 'textarea', FALSE, 'Accused detail', 96, NULL, NULL, NULL, 'mpda_accused'),
        (mpda_tmpl_id, 'Occupation', 'mpda_accused_occupation', 'custom', 'text', FALSE, 'Accused detail', 97, NULL, NULL, NULL, 'mpda_accused'),
        (mpda_tmpl_id, 'PAN card', 'mpda_accused_pan', 'custom', 'text', FALSE, 'Accused detail', 98, NULL, NULL, NULL, 'mpda_accused'),
        (mpda_tmpl_id, 'Cast', 'mpda_accused_cast', 'custom', 'text', FALSE, 'Accused detail', 99, NULL, NULL, NULL, 'mpda_accused'),
        (mpda_tmpl_id, 'Religion', 'mpda_accused_religion', 'custom', 'text', FALSE, 'Accused detail', 100, NULL, NULL, NULL, 'mpda_accused')
        ON CONFLICT DO NOTHING;
    END IF;

    -- 4. Delete gang_members_max_items module setting
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        DELETE FROM public.module_settings
        WHERE module_key = 'mpda' AND setting_key IN ('gang_members_max_items', 'max_gang_members');
    END IF;
END $$;
"""


def apply_public_updates_0048(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_MPDA_PUBLIC_UPDATES_0048_UP)
    else:
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')

        tmpl = FieldTemplate.objects.filter(template_name='MPDA Proposal Template').first()
        if tmpl:
            FieldTemplateField.objects.filter(template=tmpl, section='Accused Particulars').update(section='Accused detail')
            FieldTemplateField.objects.filter(template=tmpl, section='Crime Statistics & Crime Chart').update(section='Crime Chart')

            FieldTemplateField.objects.filter(
                template=tmpl,
                field_key__in=[
                    'mpda_accused_name',
                    'mpda_accused_aadhaar',
                    'mpda_accused_mobile',
                    'mpda_accused_address',
                    'mpda_accused_age',
                    'mpda_accused_gender',
                ]
            ).delete()

            # Create repeating group
            FieldTemplateField.objects.get_or_create(
                template=tmpl,
                field_key='mpda_accused',
                defaults={
                    'field_label': 'Accused',
                    'field_source': 'custom',
                    'field_type': 'repeating_group',
                    'is_required': False,
                    'section': 'Accused detail',
                    'display_order': 90,
                }
            )

            children = [
                ('Name', 'mpda_accused_name', 'text', 91, None),
                ('Age', 'mpda_accused_age', 'number', 92, None),
                ('Gender', 'mpda_accused_gender', 'dropdown', 93, '/api/options/gender/'),
                ('Mobile', 'mpda_accused_mobile', 'text', 94, None),
                ('Aadhaar', 'mpda_accused_aadhaar', 'text', 95, None),
                ('Address', 'mpda_accused_address', 'textarea', 96, None),
                ('Occupation', 'mpda_accused_occupation', 'text', 97, None),
                ('PAN card', 'mpda_accused_pan', 'text', 98, None),
                ('Cast', 'mpda_accused_cast', 'text', 99, None),
                ('Religion', 'mpda_accused_religion', 'text', 100, None),
            ]
            for label, key, f_type, order, opt_src in children:
                FieldTemplateField.objects.get_or_create(
                    template=tmpl,
                    field_key=key,
                    defaults={
                        'field_label': label,
                        'field_source': 'custom',
                        'field_type': f_type,
                        'is_required': False,
                        'section': 'Accused detail',
                        'display_order': order,
                        'options_source': opt_src,
                        'parent_field_key': 'mpda_accused',
                    }
                )

        ModuleSetting.objects.filter(module_key='mpda', setting_key__in=['gang_members_max_items', 'max_gang_members']).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0047_mpda_tenant_updates'),
    ]

    operations = [
        migrations.RunPython(
            apply_public_updates_0048,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
