from django.db import migrations

SQL_DROP_DEPRECATED_TABLES = """
DO $$
DECLARE
    target_tables TEXT[] := ARRAY[
        'court_filing',
        'recovered_property',
        'stolen_property',
        'technical_custody',
        'preventive_actions',
        'procedural_details',
        'case_transfers',
        'district_admins',
        'super_admins',
        'users_notificationrecord',
        'users_transferrequest'
    ];
    sch_rec RECORD;
    t TEXT;
BEGIN
    -- 1. Loop through all non-system schemas and safely drop each deprecated table if present
    FOR sch_rec IN
        SELECT DISTINCT schema_name AS sch
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
          AND schema_name NOT LIKE 'pg_temp_%'
          AND schema_name NOT LIKE 'pg_toast_%'
    LOOP
        FOREACH t IN ARRAY target_tables
        LOOP
            EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE;', sch_rec.sch, t);
        END LOOP;
    END LOOP;

    -- 2. Direct drop in current search_path as fallback
    FOREACH t IN ARRAY target_tables
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE;', t);
    END LOOP;
END
$$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0020_preventiveactionitems_bond_cancellation_date_and_more'),
        ('stations', '0002_district_superadmin_policestation_district_name_and_more'),
        ('users', '0008_officerprofile_is_biometric_enabled'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_DROP_DEPRECATED_TABLES,
            reverse_sql="",
        ),
    ]
