from django.db import migrations

"""
Migration 0071: Rename field_label for 'mpda_io_post' to 'Designation'
in field_template_fields (MPDA Proposal Template).
"""

SQL_UP = """
DO $$
BEGIN
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        UPDATE public.field_template_fields
        SET field_label = 'Designation'
        WHERE field_key = 'mpda_io_post';
    END IF;
END $$;
"""

SQL_DOWN = """
DO $$
BEGIN
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        UPDATE public.field_template_fields
        SET field_label = 'IO Post'
        WHERE field_key = 'mpda_io_post';
    END IF;
END $$;
"""


def rename_io_post(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_UP)
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(field_key='mpda_io_post').update(field_label='Designation')


def unrename_io_post(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_DOWN)
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(field_key='mpda_io_post').update(field_label='IO Post')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0070_hs_summary_tab_label'),
    ]

    operations = [
        migrations.RunPython(rename_io_post, reverse_code=unrename_io_post),
    ]
