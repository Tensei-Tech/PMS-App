from django.db import migrations, models

"""
Migration 0073: Add total_misc_crime to MPDA Proposal and FieldTemplateField.
- Adds column total_misc_crime to mpda_proposals across tenant schemas
- Inserts 'Total Miscellaneous Crime' into field_template_fields for MPDA
  (template found by name, so it also works on a new, empty database)
"""

SQL_UP = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    -- Add column total_misc_crime to mpda_proposals in tenant schemas
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
    tmpl = FieldTemplate.objects.filter(template_name='MPDA Proposal Template').first()
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

