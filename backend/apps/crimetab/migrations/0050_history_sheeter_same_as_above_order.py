from django.db import migrations

"""
Migration 0050: History Sheeter "Same As Above" field order

Moves 'Present Address Same As Above' (hs_same_as_above) from display_order 95
to 85 so it sits between Permanent Address (80) and Present Address (90).
"""

SQL_REORDER_UP = """
DO $$
BEGIN
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        UPDATE public.field_template_fields
        SET display_order = 85
        WHERE field_key = 'hs_same_as_above';
    END IF;
END $$;
"""

SQL_REORDER_DOWN = """
DO $$
BEGIN
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        UPDATE public.field_template_fields
        SET display_order = 95
        WHERE field_key = 'hs_same_as_above';
    END IF;
END $$;
"""


def _set_order(apps, schema_editor, sql, order):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(sql)
    else:
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        FieldTemplateField.objects.filter(field_key='hs_same_as_above').update(display_order=order)


def reorder_up(apps, schema_editor):
    _set_order(apps, schema_editor, SQL_REORDER_UP, 85)


def reorder_down(apps, schema_editor):
    _set_order(apps, schema_editor, SQL_REORDER_DOWN, 95)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0049_mpda_accused_tenant_tables'),
    ]

    operations = [
        migrations.RunPython(reorder_up, reverse_code=reorder_down),
    ]
