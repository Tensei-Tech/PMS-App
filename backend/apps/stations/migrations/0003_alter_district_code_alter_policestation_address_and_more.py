from django.db import migrations, models

SQL_ALTER_NULLABLE = """
DO $$
DECLARE
    target_schemas TEXT[] := ARRAY['maharashtra', 'bihar', 'manipur', 'public'];
    s TEXT;
BEGIN
    FOREACH s IN ARRAY target_schemas
    LOOP
        -- 1. districts table: make code nullable
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = s AND table_name = 'districts'
        ) THEN
            EXECUTE format('ALTER TABLE %I.districts ALTER COLUMN code DROP NOT NULL;', s);
        END IF;

        -- 2. stations_policestation table: make address, landline, district_name, zone, pi_in_charge nullable
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = s AND table_name = 'stations_policestation'
        ) THEN
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN address DROP NOT NULL;', s);
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN landline DROP NOT NULL;', s);
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN district_name DROP NOT NULL;', s);
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN zone DROP NOT NULL;', s);
            EXECUTE format('ALTER TABLE %I.stations_policestation ALTER COLUMN pi_in_charge DROP NOT NULL;', s);
        END IF;
    END LOOP;
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
