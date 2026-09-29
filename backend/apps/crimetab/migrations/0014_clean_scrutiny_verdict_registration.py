# Migration to clean obsolete 0001 columns in scrutiny_pipeline, final_verdict, crime_registration_info
from django.db import migrations

SQL_CLEANUP = """
DO $$
BEGIN
    -- 1. scrutiny_pipeline: drop obsolete columns and promote case_id to PK
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'scrutiny_pipeline' AND column_name = 'scrutiny_id'
    ) THEN
        ALTER TABLE scrutiny_pipeline DROP CONSTRAINT IF EXISTS scrutiny_pipeline_pkey CASCADE;
        ALTER TABLE scrutiny_pipeline DROP CONSTRAINT IF EXISTS scrutiny_pipeline_case_id_key CASCADE;
        ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS scrutiny_id;
        ALTER TABLE scrutiny_pipeline ADD PRIMARY KEY (case_id);
    END IF;
    ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS created_at;
    ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS sdpo_send_date;
    ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS sdpo_grant_date;
    ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS sdpo_remarks;
    ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS app_remarks;
    ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS dcp_send_date;
    ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS dcp_grant_date;
    ALTER TABLE scrutiny_pipeline DROP COLUMN IF EXISTS dcp_remarks;

    -- 2. final_verdict: drop obsolete columns and promote case_id to PK
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'final_verdict' AND column_name = 'verdict_id'
    ) THEN
        ALTER TABLE final_verdict DROP CONSTRAINT IF EXISTS final_verdict_pkey CASCADE;
        ALTER TABLE final_verdict DROP CONSTRAINT IF EXISTS final_verdict_case_id_key CASCADE;
        ALTER TABLE final_verdict DROP COLUMN IF EXISTS verdict_id;
        ALTER TABLE final_verdict ADD PRIMARY KEY (case_id);
    END IF;
    ALTER TABLE final_verdict DROP COLUMN IF EXISTS is_quashed;
    ALTER TABLE final_verdict DROP COLUMN IF EXISTS created_at;
    ALTER TABLE final_verdict DROP COLUMN IF EXISTS quashed_date;
    ALTER TABLE final_verdict DROP COLUMN IF EXISTS final_summary;
    ALTER TABLE final_verdict DROP COLUMN IF EXISTS verdict_status;
    ALTER TABLE final_verdict DROP COLUMN IF EXISTS verdict_date;
    ALTER TABLE final_verdict DROP COLUMN IF EXISTS sentence_details;
    ALTER TABLE final_verdict DROP COLUMN IF EXISTS person_id;

    -- 3. crime_registration_info: drop obsolete columns and promote case_id to PK
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crime_registration_info' AND column_name = 'info_id'
    ) THEN
        ALTER TABLE crime_registration_info DROP CONSTRAINT IF EXISTS crime_registration_info_pkey CASCADE;
        ALTER TABLE crime_registration_info DROP CONSTRAINT IF EXISTS crime_registration_info_case_id_key CASCADE;
        ALTER TABLE crime_registration_info DROP COLUMN IF EXISTS info_id;
        ALTER TABLE crime_registration_info ADD PRIMARY KEY (case_id);
    END IF;
    ALTER TABLE crime_registration_info DROP COLUMN IF EXISTS reg_date;
    ALTER TABLE crime_registration_info DROP COLUMN IF EXISTS fir_copy_path;
    ALTER TABLE crime_registration_info DROP COLUMN IF EXISTS brief_description;
END
$$;
"""

class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0013_clean_obsolete_0001_columns'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_CLEANUP,
            reverse_sql="",
        ),
    ]
