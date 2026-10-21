from django.db import migrations, models


def add_column_if_not_exists(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        with schema_editor.connection.cursor() as cursor:
            cursor.execute("""
                DO $$
                BEGIN
                    IF EXISTS (
                        SELECT 1 FROM information_schema.tables 
                        WHERE table_schema = 'public' AND table_name = 'field_template_fields'
                    ) THEN
                        ALTER TABLE public.field_template_fields 
                        ADD COLUMN IF NOT EXISTS parent_field_key character varying(50) NULL;
                    END IF;
                END $$;
            """)
    else:
        # On SQLite test runners, field is created via schema_editor.create_model
        pass


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0038_add_multiselect_and_repeating_group_field_types'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(
                    add_column_if_not_exists,
                    reverse_code=migrations.RunPython.noop,
                ),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='fieldtemplatefield',
                    name='parent_field_key',
                    field=models.CharField(blank=True, max_length=50, null=True),
                ),
            ],
        ),
    ]
