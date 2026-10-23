from django.db import migrations, models


SQL_IDEMPOTENT_UP = """
DO $$
BEGIN
    -- 1. Ensure columns exist on field_template_fields
    IF to_regclass('public.field_template_fields') IS NOT NULL THEN
        ALTER TABLE public.field_template_fields ADD COLUMN IF NOT EXISTS depends_on_field_key VARCHAR(50);
        ALTER TABLE public.field_template_fields ADD COLUMN IF NOT EXISTS depends_on_value VARCHAR(100);
        ALTER TABLE public.field_template_fields ADD COLUMN IF NOT EXISTS options_source VARCHAR(255);
    END IF;

    -- 2. Ensure public.option_values table exists
    CREATE TABLE IF NOT EXISTS public.option_values (
        id BIGSERIAL PRIMARY KEY,
        option_group VARCHAR(50) NOT NULL,
        option_value VARCHAR(100) NOT NULL,
        display_order INT NOT NULL DEFAULT 0,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        CONSTRAINT option_values_option_group_option_value_uniq UNIQUE (option_group, option_value)
    );

    -- Create index on option_group if not exists
    CREATE INDEX IF NOT EXISTS option_values_group_idx ON public.option_values (option_group);
END $$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0026_remove_general_crime_baseline_template'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunSQL(
                    sql=SQL_IDEMPOTENT_UP,
                    reverse_sql=""
                )
            ],
            state_operations=[
                migrations.CreateModel(
                    name='OptionValue',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('option_group', models.CharField(max_length=50)),
                        ('option_value', models.CharField(max_length=100)),
                        ('display_order', models.IntegerField(default=0)),
                        ('is_active', models.BooleanField(default=True)),
                    ],
                    options={
                        'verbose_name': 'Option Value',
                        'verbose_name_plural': 'Option Values',
                        'db_table': 'option_values',
                        'ordering': ['display_order', 'id'],
                        'unique_together': {('option_group', 'option_value')},
                    },
                ),
                migrations.AddField(
                    model_name='fieldtemplatefield',
                    name='depends_on_field_key',
                    field=models.CharField(blank=True, max_length=50, null=True),
                ),
                migrations.AddField(
                    model_name='fieldtemplatefield',
                    name='depends_on_value',
                    field=models.CharField(blank=True, max_length=100, null=True),
                ),
                migrations.AddField(
                    model_name='fieldtemplatefield',
                    name='options_source',
                    field=models.CharField(blank=True, max_length=255, null=True),
                ),
                migrations.AlterField(
                    model_name='fieldtemplatefield',
                    name='field_type',
                    field=models.CharField(
                        choices=[
                            ('text', 'Text Field'),
                            ('textarea', 'Multi-line Text Area'),
                            ('number', 'Numeric Field'),
                            ('date', 'Date Picker'),
                            ('datetime', 'Date-Time Picker'),
                            ('dropdown', 'Dropdown Select'),
                            ('checkbox', 'Checkbox Toggle'),
                            ('radio', 'Radio Button Group'),
                            ('chips', 'Chips Selector'),
                            ('file', 'File Upload'),
                        ],
                        default='text',
                        max_length=20,
                    ),
                ),
            ]
        ),
    ]
