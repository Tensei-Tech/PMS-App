from django.db import migrations

SQL_CREATE_TENANT_MASTER_DIVISIONS = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    -- 1. Iterate across all existing non-system, non-public schemata
    FOR sch_rec IN
        SELECT DISTINCT schema_name AS sch
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'public')
          AND schema_name NOT LIKE 'pg_temp_%'
          AND schema_name NOT LIKE 'pg_toast_%'
    LOOP
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.master_divisions (
                id BIGSERIAL PRIMARY KEY,
                state_code VARCHAR(10) NOT NULL DEFAULT ''MH'',
                state_name VARCHAR(100) NOT NULL DEFAULT ''Maharashtra'',
                name VARCHAR(128) NOT NULL,
                code VARCHAR(64),
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT %I_master_divisions_state_name_uniq UNIQUE (state_code, name)
            );
        ', sch_rec.sch, sch_rec.sch);
    END LOOP;

    -- 2. Also check public.states if registered tenant states exist
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'states'
    ) THEN
        FOR sch_rec IN EXECUTE 'SELECT DISTINCT schema_name AS sch FROM public.states WHERE schema_name IS NOT NULL AND schema_name != ''public'' AND trim(schema_name) != '''''
        LOOP
            IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = sch_rec.sch) THEN
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.master_divisions (
                        id BIGSERIAL PRIMARY KEY,
                        state_code VARCHAR(10) NOT NULL DEFAULT ''MH'',
                        state_name VARCHAR(100) NOT NULL DEFAULT ''Maharashtra'',
                        name VARCHAR(128) NOT NULL,
                        code VARCHAR(64),
                        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        CONSTRAINT %I_master_divisions_state_name_uniq UNIQUE (state_code, name)
                    );
                ', sch_rec.sch, sch_rec.sch);
            END IF;
        END LOOP;
    END IF;
END
$$;
"""

SQL_REVERSE = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    FOR sch_rec IN
        SELECT DISTINCT schema_name AS sch
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'public')
          AND schema_name NOT LIKE 'pg_temp_%'
          AND schema_name NOT LIKE 'pg_toast_%'
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I.master_divisions CASCADE;', sch_rec.sch);
    END LOOP;
END
$$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0012_drop_master_divisions_old_unused'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_CREATE_TENANT_MASTER_DIVISIONS,
            reverse_sql=SQL_REVERSE,
        ),
    ]
