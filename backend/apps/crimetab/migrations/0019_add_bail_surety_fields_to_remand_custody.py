from django.db import migrations, models


def update_db_schemas_and_templates(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        # 1. Update public.field_template_fields for Remand & Custody Bail Surety
        cursor.execute("SELECT 1 FROM public.field_templates WHERE template_id = 1;")
        if cursor.fetchone():
            template_fields = [
                ('Surety Age', 'surety_age', 'number', 632),
                ('Surety Gender', 'surety_gender', 'gender_toggle', 634),
                ('Surety Occupation', 'surety_occupation', 'text', 635),
                ('Surety Mobile No.', 'surety_mobile', 'text', 636),
                ('Surety Aadhaar No.', 'surety_aadhaar', 'text', 637),
                ('Surety PAN No.', 'surety_pan', 'text', 638),
                ('Surety Address', 'surety_address', 'textarea', 639),
                ('Relation with Accused', 'surety_relation', 'dropdown', 639),
            ]
            for label, key, ftype, order in template_fields:
                cursor.execute(
                    "SELECT field_def_id FROM public.field_template_fields WHERE template_id = 1 AND field_key = %s;",
                    [key]
                )
                if not cursor.fetchone():
                    cursor.execute(
                        """
                        INSERT INTO public.field_template_fields 
                        (template_id, field_label, field_key, field_source, field_type, is_required, display_order, section)
                        VALUES (1, %s, %s, 'common', %s, false, %s, 'Remand & Custody');
                        """,
                        [label, key, ftype, order]
                    )

        # 2. Multi-schema column sync for remand_custody
        for schema in ['public', 'maharashtra', 'manipur', 'bihar']:
            cursor.execute("SELECT 1 FROM information_schema.schemata WHERE schema_name = %s;", [schema])
            if not cursor.fetchone():
                continue
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS surety_age integer;")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS surety_gender character varying(20) DEFAULT 'Male';")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS surety_occupation character varying(150);")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS surety_mobile character varying(20);")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS surety_aadhaar character varying(20);")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS surety_pan character varying(20);")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS surety_address text;")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS surety_relation character varying(50);")


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0018_update_preventive_unique_constraint'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(
                    update_db_schemas_and_templates,
                    reverse_code=migrations.RunPython.noop
                ),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='remandcustody',
                    name='surety_age',
                    field=models.IntegerField(blank=True, null=True),
                ),
                migrations.AddField(
                    model_name='remandcustody',
                    name='surety_gender',
                    field=models.CharField(blank=True, default='Male', max_length=20, null=True),
                ),
                migrations.AddField(
                    model_name='remandcustody',
                    name='surety_occupation',
                    field=models.CharField(blank=True, max_length=150, null=True),
                ),
                migrations.AddField(
                    model_name='remandcustody',
                    name='surety_mobile',
                    field=models.CharField(blank=True, max_length=20, null=True),
                ),
                migrations.AddField(
                    model_name='remandcustody',
                    name='surety_aadhaar',
                    field=models.CharField(blank=True, max_length=20, null=True),
                ),
                migrations.AddField(
                    model_name='remandcustody',
                    name='surety_pan',
                    field=models.CharField(blank=True, max_length=20, null=True),
                ),
                migrations.AddField(
                    model_name='remandcustody',
                    name='surety_address',
                    field=models.TextField(blank=True, null=True),
                ),
                migrations.AddField(
                    model_name='remandcustody',
                    name='surety_relation',
                    field=models.CharField(blank=True, max_length=50, null=True),
                ),
            ]
        ),
    ]
