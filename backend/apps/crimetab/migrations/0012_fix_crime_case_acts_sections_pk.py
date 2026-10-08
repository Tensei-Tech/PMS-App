
# Migration to fix crime_case_acts_sections primary key.
#
# Background:
#   0001_initial created crime_case_acts_sections with 'id' as the BigAutoField PK.
#   0004's SeparateDatabaseAndState used CREATE TABLE IF NOT EXISTS (no-op on existing
#   tables), so the DB never got 'charge_id'. Django's migration state believed the PK
#   was renamed, but the actual column remained 'id'. This caused a fresh test-DB run to
#   fail with "column crime_case_acts_sections.charge_id does not exist".
#
# Fix: idempotent SQL that adds charge_id if missing, promotes it to PK, and drops id.
from django.db import migrations

SQL_FIX = """
DO $$
BEGIN
    -- Step 1: If 'id' column exists but 'charge_id' does not, add charge_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crime_case_acts_sections' AND column_name = 'id'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crime_case_acts_sections' AND column_name = 'charge_id'
    ) THEN
        -- Add charge_id as a regular bigint, populate from sequence, then promote to PK
        ALTER TABLE crime_case_acts_sections ADD COLUMN charge_id BIGSERIAL;
        -- Drop old PK constraint
        ALTER TABLE crime_case_acts_sections DROP CONSTRAINT IF EXISTS crime_case_acts_sections_pkey;
        -- Make charge_id the new PK
        ALTER TABLE crime_case_acts_sections ADD PRIMARY KEY (charge_id);
        -- Remove old id column
        ALTER TABLE crime_case_acts_sections DROP COLUMN id;
    END IF;

    -- Step 2: If neither exists, table is somehow broken — add charge_id as PK
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crime_case_acts_sections' AND column_name = 'charge_id'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crime_case_acts_sections' AND column_name = 'id'
    ) THEN
        ALTER TABLE crime_case_acts_sections ADD COLUMN charge_id BIGSERIAL PRIMARY KEY;
    END IF;

    -- Step 3: Ensure the is_major column is gone (0004 state op removed it)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crime_case_acts_sections' AND column_name = 'is_major'
    ) THEN
        ALTER TABLE crime_case_acts_sections DROP COLUMN is_major;
    END IF;

    -- Step 4: Ensure subsection_id exists (0001 didn't create it; 0004 raw SQL was a no-op)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crime_case_acts_sections' AND column_name = 'subsection_id'
    ) THEN
        -- Only add FK if act_subsections table exists
        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_name = 'act_subsections'
        ) THEN
            ALTER TABLE crime_case_acts_sections
                ADD COLUMN subsection_id BIGINT REFERENCES act_subsections(subsection_id) ON DELETE SET NULL;
        ELSE
            ALTER TABLE crime_case_acts_sections ADD COLUMN subsection_id BIGINT;
        END IF;
    END IF;
END
$$;
"""

SQL_REVERSE = """
-- Reverse: rename charge_id back to id (best-effort)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'crime_case_acts_sections' AND column_name = 'charge_id'
    ) THEN
        ALTER TABLE crime_case_acts_sections RENAME COLUMN charge_id TO id;
    END IF;
END
$$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0011_sync_all_missing_db_columns'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_FIX,
            reverse_sql=SQL_REVERSE,
        ),
    ]
