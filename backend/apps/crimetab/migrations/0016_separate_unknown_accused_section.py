from django.db import migrations


def separate_unknown_accused(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SELECT 1 FROM public.field_templates WHERE template_id = 1;")
        if not cursor.fetchone():
            return

        # Check if is_unknown_accused exists in template 1
        cursor.execute(
            "SELECT field_def_id FROM public.field_template_fields WHERE template_id = 1 AND field_key = 'is_unknown_accused';"
        )
        row = cursor.fetchone()
        if row:
            cursor.execute(
                """
                UPDATE public.field_template_fields
                SET section = 'Unknown Accused',
                    field_label = 'Unknown Accused Involved (✓) / अज्ञात आरोपी',
                    display_order = 445
                WHERE template_id = 1 AND field_key = 'is_unknown_accused';
                """
            )
        else:
            cursor.execute(
                """
                INSERT INTO public.field_template_fields 
                (template_id, field_label, field_key, field_source, field_type, is_required, display_order, section)
                VALUES (1, 'Unknown Accused Involved (✓) / अज्ञात आरोपी', 'is_unknown_accused', 'common', 'checkbox', false, 445, 'Unknown Accused');
                """
            )


def revert_unknown_accused(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            """
            UPDATE public.field_template_fields
            SET section = 'Unidentified Accused',
                field_label = 'Unknown Accused Involved',
                display_order = 30
            WHERE template_id = 1 AND field_key = 'is_unknown_accused';
            """
        )


class Migration(migrations.Migration):
    dependencies = [
        ('crimetab', '0015_add_suspected_accused_field_template_fields'),
    ]

    operations = [
        migrations.RunPython(separate_unknown_accused, revert_unknown_accused),
    ]
