from django.db import migrations

# Note: This migration is one-way.
SQL_REMOVE_GENERAL_CRIME_BASELINE_TEMPLATE = """
DO $$
DECLARE
    tmpl_ids BIGINT[];
BEGIN
    -- 1. Find matching template_ids in public.field_templates
    IF to_regclass('public.field_templates') IS NOT NULL THEN
        SELECT ARRAY_AGG(template_id) INTO tmpl_ids
        FROM public.field_templates
        WHERE template_name = 'General Crime Baseline Template';
    END IF;

    IF tmpl_ids IS NOT NULL AND array_length(tmpl_ids, 1) > 0 THEN
        -- 2. Unlink case_categories.template_id
        IF to_regclass('public.case_categories') IS NOT NULL THEN
            UPDATE public.case_categories
            SET template_id = NULL
            WHERE template_id = ANY(tmpl_ids);
        END IF;

        -- 3. Delete from public.category_field_templates
        IF to_regclass('public.category_field_templates') IS NOT NULL THEN
            DELETE FROM public.category_field_templates
            WHERE template_id = ANY(tmpl_ids);
        END IF;

        -- 4. Delete from public.section_field_templates
        IF to_regclass('public.section_field_templates') IS NOT NULL THEN
            DELETE FROM public.section_field_templates
            WHERE template_id = ANY(tmpl_ids);
        END IF;

        -- 5. Delete from public.field_template_fields
        IF to_regclass('public.field_template_fields') IS NOT NULL THEN
            DELETE FROM public.field_template_fields
            WHERE template_id = ANY(tmpl_ids);
        END IF;

        -- 6. Delete from public.field_templates
        IF to_regclass('public.field_templates') IS NOT NULL THEN
            DELETE FROM public.field_templates
            WHERE template_name = 'General Crime Baseline Template';
        END IF;
    END IF;
END $$;
"""


def remove_general_crime_baseline_template(apps, schema_editor):
    """
    Idempotently unlinks and removes 'General Crime Baseline Template'
    and any template_id references in case_categories, category_field_templates,
    section_field_templates, and field_template_fields.

    Note: This migration is one-way.
    """
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_REMOVE_GENERAL_CRIME_BASELINE_TEMPLATE)
    else:
        # Django ORM fallback for SQLite / test environments
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        CaseCategory = apps.get_model('crimetab', 'CaseCategory')
        CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
        SectionFieldTemplate = apps.get_model('crimetab', 'SectionFieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')

        templates = FieldTemplate.objects.filter(template_name='General Crime Baseline Template')
        for tmpl in templates:
            CaseCategory.objects.filter(template=tmpl).update(template=None)
            CategoryFieldTemplate.objects.filter(template=tmpl).delete()
            SectionFieldTemplate.objects.filter(template=tmpl).delete()
            FieldTemplateField.objects.filter(template=tmpl).delete()
            tmpl.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0025_accident_subcategories_and_template_links'),
    ]

    operations = [
        migrations.RunPython(
            remove_general_crime_baseline_template,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
