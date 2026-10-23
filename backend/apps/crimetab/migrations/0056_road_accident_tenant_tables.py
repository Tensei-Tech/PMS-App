from django.db import migrations


SQL_ROAD_ACCIDENT_TENANT_UP = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    FOR sch_rec IN
        SELECT DISTINCT table_schema AS sch
        FROM information_schema.tables
        WHERE table_name = 'users_officerprofile'
          AND table_schema NOT IN ('public', 'information_schema', 'pg_catalog')
        UNION
        SELECT DISTINCT schema_name AS sch
        FROM public.states
        WHERE is_active = TRUE
          AND schema_name NOT IN ('public', 'information_schema', 'pg_catalog')
        UNION
        SELECT 'maharashtra' AS sch
    LOOP
        EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I;', sch_rec.sch);

        -- 1. Main road_accident_records table
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.road_accident_records (
                id BIGSERIAL PRIMARY KEY,
                case_id VARCHAR(128),
                station_id BIGINT,
                station_name VARCHAR(255),
                nature_of_accident VARCHAR(100),
                nature_of_accident_other VARCHAR(255),
                vehicle_abandoned VARCHAR(10),
                driver_subsequently_traced VARCHAR(10),
                victim_identity_established VARCHAR(10),
                eye_witnesses_identity VARCHAR(10),
                irad VARCHAR(10),
                irad_date DATE,
                dar VARCHAR(10),
                dar_date DATE,
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS road_acc_case_idx ON %I.road_accident_records (case_id);
            CREATE INDEX IF NOT EXISTS road_acc_station_idx ON %I.road_accident_records (station_name);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch);

        -- 2. Vehicles involved in the accident (Repeating group)
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.road_accident_vehicles (
                id BIGSERIAL PRIMARY KEY,
                accident_record_id BIGINT NOT NULL REFERENCES %I.road_accident_records(id) ON DELETE CASCADE,
                case_id VARCHAR(128),
                display_order SMALLINT DEFAULT 1,
                vehicle_number VARCHAR(100),
                vehicle_name VARCHAR(100),
                company_name VARCHAR(100),
                company_name_other VARCHAR(100),
                model VARCHAR(100),
                owner_name_address TEXT,
                driver_name_address TEXT,
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS road_acc_veh_rec_idx ON %I.road_accident_vehicles (accident_record_id);
            CREATE INDEX IF NOT EXISTS road_acc_veh_case_idx ON %I.road_accident_vehicles (case_id);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch, sch_rec.sch);

        -- 3. Injured persons (Repeating group)
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.road_accident_injured (
                id BIGSERIAL PRIMARY KEY,
                accident_record_id BIGINT NOT NULL REFERENCES %I.road_accident_records(id) ON DELETE CASCADE,
                case_id VARCHAR(128),
                display_order SMALLINT DEFAULT 1,
                name VARCHAR(255),
                age INT,
                gender VARCHAR(50),
                address TEXT,
                occupation VARCHAR(255),
                mobile_no VARCHAR(20),
                aadhaar_card VARCHAR(50),
                pan_card VARCHAR(50),
                caste VARCHAR(100),
                religion VARCHAR(100),
                death VARCHAR(10),
                death_date DATE,
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS road_acc_inj_rec_idx ON %I.road_accident_injured (accident_record_id);
            CREATE INDEX IF NOT EXISTS road_acc_inj_case_idx ON %I.road_accident_injured (case_id);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch, sch_rec.sch);

        -- 4. Deceased persons (Repeating group)
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.road_accident_deceased (
                id BIGSERIAL PRIMARY KEY,
                accident_record_id BIGINT NOT NULL REFERENCES %I.road_accident_records(id) ON DELETE CASCADE,
                case_id VARCHAR(128),
                display_order SMALLINT DEFAULT 1,
                name VARCHAR(255),
                age INT,
                gender VARCHAR(50),
                address TEXT,
                occupation VARCHAR(255),
                mobile_no VARCHAR(20),
                aadhaar_card VARCHAR(50),
                pan_card VARCHAR(50),
                caste VARCHAR(100),
                religion VARCHAR(100),
                post_mortem VARCHAR(10),
                pm_report_received VARCHAR(10),
                viscera_sent_fsl VARCHAR(10),
                fsl_report_received VARCHAR(10),
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS road_acc_dec_rec_idx ON %I.road_accident_deceased (accident_record_id);
            CREATE INDEX IF NOT EXISTS road_acc_dec_case_idx ON %I.road_accident_deceased (case_id);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch, sch_rec.sch);
    END LOOP;
END $$;
"""


SQL_ROAD_ACCIDENT_TENANT_DOWN = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    FOR sch_rec IN
        SELECT DISTINCT table_schema AS sch
        FROM information_schema.tables
        WHERE table_name = 'road_accident_records'
          AND table_schema NOT IN ('public', 'information_schema', 'pg_catalog')
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I.road_accident_deceased CASCADE;', sch_rec.sch);
        EXECUTE format('DROP TABLE IF EXISTS %I.road_accident_injured CASCADE;', sch_rec.sch);
        EXECUTE format('DROP TABLE IF EXISTS %I.road_accident_vehicles CASCADE;', sch_rec.sch);
        EXECUTE format('DROP TABLE IF EXISTS %I.road_accident_records CASCADE;', sch_rec.sch);
    END LOOP;
END $$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0055_road_accident_public_data'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_ROAD_ACCIDENT_TENANT_UP,
            reverse_sql=SQL_ROAD_ACCIDENT_TENANT_DOWN,
        ),
    ]
