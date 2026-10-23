from django.db import migrations, models

# SQL to drop NOT NULL from the 6 RTI columns in every tenant schema dynamically,
# look up the actual due-date constraint in pg_constraint by table and definition,
# drop all old/duplicate due-date constraints and add exactly one NULL-safe rti_due_after_received constraint,
# and seed the empty application message setting.
SQL_DROP_NOT_NULL_AND_ADD_SETTING = """
DO $$
DECLARE
    r RECORD;
    con_rec RECORD;
    col_name TEXT;
    target_cols TEXT[] := ARRAY['applicant_name', 'address', 'received_date', 'due_date', 'info_type', 'mode_of_receipt'];
    target_conname TEXT := 'rti_due_after_received';
BEGIN
    -- 1. Dynamic discovery: Iterate over all tables named 'rti_applications'
    FOR r IN (
        SELECT table_schema, table_name 
        FROM information_schema.tables 
        WHERE table_name = 'rti_applications'
          AND table_schema NOT IN ('information_schema', 'pg_catalog')
    ) LOOP
        -- Drop NOT NULL from exactly the 6 columns
        FOREACH col_name IN ARRAY target_cols LOOP
            EXECUTE format('ALTER TABLE %%I.%%I ALTER COLUMN %%I DROP NOT NULL;', r.table_schema, r.table_name, col_name);
        END LOOP;

        -- Look up in pg_constraint by table and definition, and drop every existing due-date check constraint
        FOR con_rec IN (
            SELECT con.conname
            FROM pg_constraint con
            JOIN pg_class rel ON rel.oid = con.conrelid
            JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
            WHERE nsp.nspname = r.table_schema
              AND rel.relname = r.table_name
              AND con.contype = 'c'
              AND (
                  pg_get_constraintdef(con.oid) ILIKE '%%due_date%%received_date%%'
                  OR con.conname = target_conname
                  OR con.conname LIKE '%%rti_due_after_received%%'
              )
        ) LOOP
            EXECUTE format('ALTER TABLE %%I.%%I DROP CONSTRAINT %%I;', r.table_schema, r.table_name, con_rec.conname);
        END LOOP;

        -- Add one NULL-safe version with the same name as before (rti_due_after_received)
        EXECUTE format('ALTER TABLE %%I.%%I ADD CONSTRAINT %%I CHECK (due_date IS NULL OR received_date IS NULL OR due_date >= received_date);', 
                       r.table_schema, r.table_name, target_conname);
    END LOOP;

    -- 2. Add module_setting for empty_application_message
    IF to_regclass('public.module_settings') IS NOT NULL THEN
        INSERT INTO public.module_settings (module_key, setting_key, setting_value)
        VALUES ('rti', 'empty_application_message', 'At least one form field must be provided to submit an RTI application.')
        ON CONFLICT (module_key, setting_key) DO NOTHING;
    END IF;
END $$;
"""


def apply_rti_nullable_and_setting(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_DROP_NOT_NULL_AND_ADD_SETTING)
    else:
        ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
        ModuleSetting.objects.get_or_create(
            module_key='rti',
            setting_key='empty_application_message',
            defaults={'setting_value': 'At least one form field must be provided to submit an RTI application.'}
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0035_add_rti_role_scope_settings'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[],
            state_operations=[
                migrations.AlterField(
                    model_name='rtiapplication',
                    name='applicant_name',
                    field=models.CharField(blank=True, max_length=255, null=True),
                ),
                migrations.AlterField(
                    model_name='rtiapplication',
                    name='address',
                    field=models.TextField(blank=True, null=True),
                ),
                migrations.AlterField(
                    model_name='rtiapplication',
                    name='received_date',
                    field=models.DateField(blank=True, null=True),
                ),
                migrations.AlterField(
                    model_name='rtiapplication',
                    name='due_date',
                    field=models.DateField(blank=True, null=True),
                ),
                migrations.AlterField(
                    model_name='rtiapplication',
                    name='info_type',
                    field=models.CharField(blank=True, max_length=50, null=True),
                ),
                migrations.AlterField(
                    model_name='rtiapplication',
                    name='mode_of_receipt',
                    field=models.CharField(blank=True, max_length=50, null=True),
                ),
            ],
        ),
        migrations.RunPython(
            apply_rti_nullable_and_setting,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
