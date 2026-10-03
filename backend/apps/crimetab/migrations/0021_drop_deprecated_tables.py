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
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'graphql', 'graphql_public', 'vault', 'supabase_functions', 'supabase_migrations', 'extensions', 'cron', 'net', '_analytics', '_realtime')
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
    """
    Destructive cleanup migration: Drops deprecated legacy tables across all PostgreSQL schemas.
    
    NOTE ON REVERSIBILITY:
    This migration is intentionally ONE-WAY (reverse_sql="").
    The dropped tables (court_filing, recovered_property, stolen_property, technical_custody,
    preventive_actions, procedural_details, case_transfers, district_admins, super_admins,
    users_notificationrecord, users_transferrequest) represent obsolete legacy prototypes
    and duplicate tables that have been fully replaced by canonical shared models in the `public`
    schema or standardized tenant models (e.g., cases_caserecord, preventive_action_items,
    districts, stations_policestation). Rolling backward should NOT restore deprecated tables.
    """

    dependencies = [
        ('crimetab', '0020_preventiveactionitems_bond_cancellation_date_and_more'),
        ('stations', '0002_district_superadmin_policestation_district_name_and_more'),
        ('users', '0008_officerprofile_is_biometric_enabled'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_DROP_DEPRECATED_TABLES,
            reverse_sql="",  # Intentionally no-op: one-way legacy cleanup
        ),
    ]
