# Migration to clean up obsolete 0001 columns that violate NOT NULL constraints.
from django.db import migrations

SQL_CLEANUP = """
DO $$
BEGIN
    -- 1. Clean obsolete columns from seizure_records
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS estimated_value;
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS property_desc;
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS quantity;
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS serial_no;
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS recovery_status;
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS recovery_date;
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS custody_location;
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS other_name;
    ALTER TABLE seizure_records DROP COLUMN IF EXISTS seizure_details;

    -- 2. Clean obsolete columns from crime_registration_info
    ALTER TABLE crime_registration_info DROP COLUMN IF EXISTS cr_no;

    -- 3. Clean obsolete columns from arrest_release_status
    ALTER TABLE arrest_release_status DROP COLUMN IF EXISTS case_id;

    -- 4. Clean obsolete columns from discharge_status
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'discharge_status' AND column_name = 'discharge_id'
    ) THEN
        ALTER TABLE discharge_status DROP CONSTRAINT IF EXISTS discharge_status_pkey CASCADE;
        ALTER TABLE discharge_status DROP COLUMN IF EXISTS discharge_id;
        ALTER TABLE discharge_status ADD PRIMARY KEY (person_id);
    END IF;
    ALTER TABLE discharge_status DROP COLUMN IF EXISTS created_at;
    ALTER TABLE discharge_status DROP COLUMN IF EXISTS case_id;

    -- 5. Clean obsolete columns from crime_case_responsibility
    ALTER TABLE crime_case_responsibility DROP COLUMN IF EXISTS cctv_available;
    ALTER TABLE crime_case_responsibility DROP COLUMN IF EXISTS cctv_date_time;
    ALTER TABLE crime_case_responsibility DROP COLUMN IF EXISTS created_at;
    ALTER TABLE crime_case_responsibility DROP COLUMN IF EXISTS resp_id;

    -- 6. Clean obsolete columns from crime_spot
    ALTER TABLE crime_spot DROP COLUMN IF EXISTS created_at;
    ALTER TABLE crime_spot DROP COLUMN IF EXISTS latitude;
    ALTER TABLE crime_spot DROP COLUMN IF EXISTS longitude;
    ALTER TABLE crime_spot DROP COLUMN IF EXISTS spot_id;
END
$$;
"""

class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0012_fix_crime_case_acts_sections_pk'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_CLEANUP,
            reverse_sql="",
        ),
    ]
