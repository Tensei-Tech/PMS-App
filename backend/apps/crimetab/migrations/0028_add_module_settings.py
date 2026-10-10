from django.db import migrations, models


SQL_IDEMPOTENT_UP = """
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS public.module_settings (
        id BIGSERIAL PRIMARY KEY,
        module_key VARCHAR(50) NOT NULL,
        setting_key VARCHAR(100) NOT NULL,
        setting_value TEXT,
        CONSTRAINT module_settings_module_key_setting_key_uniq UNIQUE (module_key, setting_key)
    );

    CREATE INDEX IF NOT EXISTS module_settings_key_idx ON public.module_settings (module_key);
END $$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0027_add_dynamic_engine_conditional_fields_and_option_values'),
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
                    name='ModuleSetting',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('module_key', models.CharField(max_length=50)),
                        ('setting_key', models.CharField(max_length=100)),
                        ('setting_value', models.TextField(blank=True, null=True)),
                    ],
                    options={
                        'verbose_name': 'Module Setting',
                        'verbose_name_plural': 'Module Settings',
                        'db_table': 'module_settings',
                        'unique_together': {('module_key', 'setting_key')},
                    },
                ),
            ]
        ),
    ]
