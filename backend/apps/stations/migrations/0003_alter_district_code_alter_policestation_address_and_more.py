from django.db import migrations, models

SQL_ALTER_NULLABLE = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    FOR sch_rec IN
        SELECT DISTINCT schema_name AS sch
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'graphql', 'graphql_public', 'vault', 'supabase_functions', 'supabase_migrations', 'extensions', 'cron', 'net', '_analytics', '_realtime')
          AND schema_name NOT LIKE 'pg_temp_%'
          AND schema_name NOT LIKE 'pg_toast_%'
    LOOP
        -- 1. districts table: make code nullable
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = sch_rec.sch AND table_name = 'districts'
        ) THEN
            EXECUTE format('ALTER TABLE %I.districts ALTER COLUMN code DROP NOT NULL;', sch_rec.sch);
        END IF;

        -- 2. stations_policestation table: make address, landline, district_name, zone, pi_in_charge nullable
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = sch_rec.sch AND table_name = 'stations_policestation'
        ) THEN
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN address DROP NOT NULL;', sch_rec.sch);
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN landline DROP NOT NULL;', sch_rec.sch);
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN district_name DROP NOT NULL;', sch_rec.sch);
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN zone DROP NOT NULL;', sch_rec.sch);
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN pi_in_charge DROP NOT NULL;', sch_rec.sch);
        END IF;
    END LOOP;

    -- Also check public.states if registered tenant states exist
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
                WHERE table_schema = sch_rec.sch AND table_name = 'districts'
            ) THEN
                EXECUTE format('ALTER TABLE %I.districts ALTER COLUMN code DROP NOT NULL;', sch_rec.sch);
            END IF;

            IF EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_schema = sch_rec.sch AND table_name = 'stations_policestation'
            ) THEN
                EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN address DROP NOT NULL;', sch_rec.sch);
                EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN landline DROP NOT NULL;', sch_rec.sch);
                EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN district_name DROP NOT NULL;', sch_rec.sch);
                EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN zone DROP NOT NULL;', sch_rec.sch);
                EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN pi_in_charge DROP NOT NULL;', sch_rec.sch);
            END IF;
        END LOOP;
    END IF;
END
$$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('stations', '0002_district_superadmin_policestation_district_name_and_more'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AlterField(
                    model_name='district',
                    name='code',
                    field=models.CharField(blank=True, max_length=32, null=True),
                ),
                migrations.AlterField(
                    model_name='policestation',
                    name='address',
                    field=models.TextField(blank=True, null=True),
                ),
                migrations.AlterField(
                    model_name='policestation',
                    name='district_name',
                    field=models.CharField(blank=True, max_length=128, null=True),
                ),
                migrations.AlterField(
                    model_name='policestation',
                    name='landline',
                    field=models.CharField(blank=True, max_length=32, null=True),
                ),
                migrations.AlterField(
                    model_name='policestation',
                    name='pi_in_charge',
                    field=models.CharField(blank=True, max_length=255, null=True),
                ),
                migrations.AlterField(
                    model_name='policestation',
                    name='zone',
                    field=models.CharField(blank=True, max_length=128, null=True),
                ),
            ],
            database_operations=[
                migrations.RunSQL(
                    sql=SQL_ALTER_NULLABLE,
                    reverse_sql=migrations.RunSQL.noop,
                ),
            ],
        ),
    ]
