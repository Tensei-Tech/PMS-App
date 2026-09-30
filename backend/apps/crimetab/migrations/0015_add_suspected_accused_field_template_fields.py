from django.db import migrations


def add_suspected_accused_fields(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SELECT 1 FROM public.field_templates WHERE template_id = 1;")
        if not cursor.fetchone():
            return

        cursor.execute(
            "SELECT 1 FROM public.field_template_fields WHERE template_id = 1 AND field_key = 'suspected_accused_name';"
        )
        if cursor.fetchone():
            return

        # 1. Shift display_order >= 290 by 100 in template 1
        cursor.execute(
            "UPDATE public.field_template_fields SET display_order = display_order + 100 WHERE template_id = 1 AND display_order >= 290;"
        )

        # 2. Insert the 10 Suspected Accused fields
        fields = [
            ('Name', 'suspected_accused_name', 'common', 'text', False, 290, 'Suspected Accused'),
            ('Age', 'suspected_accused_age', 'common', 'number', False, 300, 'Suspected Accused'),
            ('Gender', 'suspected_accused_gender', 'common', 'gender_toggle', False, 310, 'Suspected Accused'),
            ('Occupation', 'suspected_accused_occupation', 'common', 'text', False, 320, 'Suspected Accused'),
            ('Mobile Number', 'suspected_accused_mobile', 'common', 'text', False, 330, 'Suspected Accused'),
            ('Aadhar Number', 'suspected_accused_aadhaar', 'common', 'text', False, 340, 'Suspected Accused'),
            ('PAN Number', 'suspected_accused_pan', 'common', 'text', False, 350, 'Suspected Accused'),
            ('Religion', 'suspected_accused_religion', 'common', 'text', False, 360, 'Suspected Accused'),
            ('Caste', 'suspected_accused_caste', 'common', 'text', False, 370, 'Suspected Accused'),
            ('Address', 'suspected_accused_address', 'common', 'textarea', False, 380, 'Suspected Accused'),
        ]
        for field in fields:
            cursor.execute(
                """
                INSERT INTO public.field_template_fields 
                (template_id, field_label, field_key, field_source, field_type, is_required, display_order, section)
                VALUES (1, %s, %s, %s, %s, %s, %s, %s);
                """,
                field
            )


def remove_suspected_accused_fields(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "DELETE FROM public.field_template_fields WHERE template_id = 1 AND section = 'Suspected Accused';"
        )
        cursor.execute(
            "UPDATE public.field_template_fields SET display_order = display_order - 100 WHERE template_id = 1 AND display_order >= 390;"
        )


class Migration(migrations.Migration):
    dependencies = [
        ('crimetab', '0014_clean_scrutiny_verdict_registration'),
    ]

    operations = [
        migrations.RunPython(add_suspected_accused_fields, remove_suspected_accused_fields),
    ]
