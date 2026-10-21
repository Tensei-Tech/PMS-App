from django.db import migrations, models

"""
Migration 0073: Add total_misc_crime to MPDA Proposal and FieldTemplateField.
- Adds column total_misc_crime to mpda_proposals across tenant schemas
- Inserts 'Total Miscellaneous Crime' into field_template_fields for MPDA
"""

SQL_UP = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    -- 1. Insert into public.field_template_fields
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        INSERT INTO public.field_template_fields (
            template_id, field_label, field_key, field_source, field_type,
            is_required, section, display_order, depends_on_field_key,
            depends_on_value, options_source, parent_field_key
        )
        SELECT 45, 'Total Miscellaneous Crime', 'mpda_total_misc_crime', 'custom', 'number',
               FALSE, 'Crime Chart', 285, NULL, NULL, NULL, NULL
        WHERE NOT EXISTS (
            SELECT 1 FROM public.field_template_fields
            WHERE template_id = 45 AND field_key = 'mpda_total_misc_crime'
        );
    END IF;

    -- 2. Add column total_misc_crime to mpda_proposals in tenant schemas
    FOR sch_rec IN
        SELECT DISTINCT table_schema AS sch
        FROM information_schema.tables
        WHERE table_name = 'mpda_proposals'
          AND table_schema NOT IN ('public', 'information_schema', 'pg_catalog')
    LOOP
        EXECUTE format('
            ALTER TABLE %I.mpda_proposals
            ADD COLUMN IF NOT EXISTS total_misc_crime INT;
        ', sch_rec.sch);
    END LOOP;
END $$;
""".replace('%I', '%%I')

SQL_DOWN = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        DELETE FROM public.field_template_fields
        WHERE field_key = 'mpda_total_misc_crime' AND template_id = 45;
    END IF;

    FOR sch_rec IN
        SELECT DISTINCT table_schema AS sch
        FROM information_schema.tables
        WHERE table_name = 'mpda_proposals'
          AND table_schema NOT IN ('public', 'information_schema', 'pg_catalog')
    LOOP
        EXECUTE format('
            ALTER TABLE %I.mpda_proposals
            DROP COLUMN IF EXISTS total_misc_crime;
        ', sch_rec.sch);
    END LOOP;
END $$;
""".replace('%I', '%%I')


def forwards_func(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_UP)
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    tmpl = FieldTemplate.objects.filter(pk=45).first() or FieldTemplate.objects.filter(template_name='MPDA Proposal Template').first()
    if tmpl:
        FieldTemplateField.objects.get_or_create(
            template=tmpl,
            field_key='mpda_total_misc_crime',
            defaults={
                'field_label': 'Total Miscellaneous Crime',
                'field_source': 'custom',
                'field_type': 'number',
                'is_required': False,
                'section': 'Crime Chart',
                'display_order': 285,
            }
        )


def backwards_func(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_DOWN)
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(field_key='mpda_total_misc_crime').delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0072_rename_serious_crimes_to_total_serious_crime'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(forwards_func, reverse_code=backwards_func),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='mpdaproposal',
                    name='total_misc_crime',
                    field=models.IntegerField(blank=True, null=True),
                ),
            ],
        ),
    ]

