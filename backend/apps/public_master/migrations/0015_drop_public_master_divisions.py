from django.db import migrations

SQL_MIGRATE_AND_DROP_PUBLIC_MASTER_DIVISIONS = """
DO $$
DECLARE
    state_rec RECORD;
    clean_schema TEXT;
BEGIN
    -- 1. Ensure any data in public.master_divisions is migrated to corresponding tenant schemas before dropping
    IF to_regclass('public.master_divisions') IS NOT NULL AND to_regclass('public.states') IS NOT NULL THEN
        FOR state_rec IN 
            SELECT state_code, state_name, schema_name 
            FROM public.states 
            WHERE schema_name IS NOT NULL AND TRIM(schema_name) != '' AND TRIM(schema_name) != 'public'
        LOOP
            clean_schema := LOWER(TRIM(state_rec.schema_name));
            
            -- If tenant schema and tenant master_divisions exist, copy missing records
            IF EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_schema = clean_schema AND table_name = 'master_divisions'
            ) THEN
                EXECUTE format('
                    INSERT INTO %I.master_divisions (state_code, state_name, name, code, created_at)
                    SELECT 
                        COALESCE(pmd.state_code, %L),
                        COALESCE(pmd.state_name, %L),
                        pmd.name,
                        pmd.code,
                        COALESCE(pmd.created_at, CURRENT_TIMESTAMP)
                    FROM public.master_divisions pmd
                    WHERE LOWER(TRIM(pmd.state_code)) = LOWER(TRIM(%L))
                    ON CONFLICT (state_code, name) DO NOTHING;
                ', clean_schema, state_rec.state_code, state_rec.state_name, state_rec.state_code);
            END IF;
        END LOOP;
    END IF;

    -- 2. Drop the redundant public table safely
    DROP TABLE IF EXISTS public.master_divisions CASCADE;
END
$$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0014_alter_masterdivision_options'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_MIGRATE_AND_DROP_PUBLIC_MASTER_DIVISIONS,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
