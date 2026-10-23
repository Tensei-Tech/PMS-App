from django.db import migrations

"""
Migration 0072: Rename field_label for 'mpda_serious_crimes' to 'Total Serious Crime'
in field_template_fields (MPDA Proposal Template).
"""

SQL_UP = """
DO $$
BEGIN
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        UPDATE public.field_template_fields
        SET field_label = 'Total Serious Crime'
        WHERE field_key = 'mpda_serious_crimes';
    END IF;
END $$;
"""

SQL_DOWN = """
DO $$
BEGIN
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        UPDATE public.field_template_fields
        SET field_label = 'Serious Crimes'
        WHERE field_key = 'mpda_serious_crimes';
    END IF;
END $$;
"""


def rename_serious_crimes(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_UP)
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(field_key='mpda_serious_crimes').update(field_label='Total Serious Crime')


def unrename_serious_crimes(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_DOWN)
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(field_key='mpda_serious_crimes').update(field_label='Serious Crimes')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0071_rename_mpda_io_post_to_designation'),
    ]

    operations = [
        migrations.RunPython(rename_serious_crimes, reverse_code=unrename_serious_crimes),
    ]
