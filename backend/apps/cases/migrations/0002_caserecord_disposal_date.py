from django.db import migrations, models

SQL_ADD_DISPOSAL_DATE = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    -- 1. Iterate across all existing non-system schemata
    FOR sch_rec IN
        SELECT DISTINCT schema_name AS sch
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'graphql', 'graphql_public', 'vault', 'supabase_functions', 'supabase_migrations', 'extensions', 'cron', 'net', '_analytics', '_realtime')
          AND schema_name NOT LIKE 'pg_temp_%'
          AND schema_name NOT LIKE 'pg_toast_%'
    LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = sch_rec.sch AND table_name = 'cases_caserecord'
        ) THEN
            EXECUTE format('ALTER TABLE %I.cases_caserecord ADD COLUMN IF NOT EXISTS disposal_date TIMESTAMPTZ;', sch_rec.sch);
        END IF;
    END LOOP;

    -- 2. Also check public.states if registered tenant states exist
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'states'
    ) THEN
        FOR sch_rec IN
            SELECT DISTINCT schema_name AS sch
            FROM public.states
            WHERE schema_name IS NOT NULL AND length(trim(schema_name)) > 0
        LOOP
            IF EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_schema = sch_rec.sch AND table_name = 'cases_caserecord'
            ) THEN
                EXECUTE format('ALTER TABLE %I.cases_caserecord ADD COLUMN IF NOT EXISTS disposal_date TIMESTAMPTZ;', sch_rec.sch);
            END IF;
        END LOOP;
    END IF;
END
$$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0001_initial'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AddField(
                    model_name='caserecord',
                    name='disposal_date',
                    field=models.DateTimeField(blank=True, null=True),
                ),
            ],
            database_operations=[
                migrations.RunSQL(
                    sql=SQL_ADD_DISPOSAL_DATE,
                    reverse_sql="ALTER TABLE IF EXISTS maharashtra.cases_caserecord DROP COLUMN IF EXISTS disposal_date;",
                ),
            ],
        ),
    ]
