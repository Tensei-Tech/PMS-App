# Generated migration to sync all database columns
from django.db import migrations

SQL_SYNC_COLUMNS = """
ALTER TABLE crime_registration_info ADD COLUMN IF NOT EXISTS cr_number VARCHAR(30);
ALTER TABLE crime_registration_info ADD COLUMN IF NOT EXISTS is_unknown_accused BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE crime_registration_info ADD COLUMN IF NOT EXISTS registered_datetime TIMESTAMPTZ;

ALTER TABLE cases_person ADD COLUMN IF NOT EXISTS approximate_age VARCHAR(20);
ALTER TABLE cases_person ADD COLUMN IF NOT EXISTS skin_colour VARCHAR(50);
ALTER TABLE cases_person ADD COLUMN IF NOT EXISTS possible_occupation VARCHAR(100);
ALTER TABLE cases_person ADD COLUMN IF NOT EXISTS identification_mark TEXT;
ALTER TABLE cases_person ADD COLUMN IF NOT EXISTS height VARCHAR(20);
ALTER TABLE cases_person ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE cases_person ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE seizure_records ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
ALTER TABLE seizure_records ADD COLUMN IF NOT EXISTS name VARCHAR(150);
ALTER TABLE seizure_records ADD COLUMN IF NOT EXISTS object_name VARCHAR(255);
ALTER TABLE seizure_records ADD COLUMN IF NOT EXISTS seized_from_person_id BIGINT;

ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS relative_friend_name VARCHAR(150);
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS relative_friend_relation VARCHAR(50);
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS release_on_notice BOOLEAN;
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS release_on_notice_datetime TIMESTAMPTZ;
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS sec_47_48_bnss BOOLEAN;
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS anticipatory_bail BOOLEAN;
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS anticipatory_bail_datetime TIMESTAMPTZ;
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS arrest_datetime TIMESTAMPTZ;
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS death_of_accused BOOLEAN;
ALTER TABLE arrest_release_status ADD COLUMN IF NOT EXISTS death_of_accused_datetime TIMESTAMPTZ;

ALTER TABLE acts ADD COLUMN IF NOT EXISTS display_order INT;
ALTER TABLE act_sections ADD COLUMN IF NOT EXISTS section_title VARCHAR(255) DEFAULT '';
ALTER TABLE crime_spot ADD COLUMN IF NOT EXISTS occurrence_datetime TIMESTAMPTZ;

ALTER TABLE discharge_status ADD COLUMN IF NOT EXISTS discharge_date DATE;
ALTER TABLE discharge_status ADD COLUMN IF NOT EXISTS discharge_reason TEXT;

ALTER TABLE field_template_fields ADD COLUMN IF NOT EXISTS section VARCHAR(100);
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0010_dischargestatus_discharge_date_and_more'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_SYNC_COLUMNS,
            reverse_sql="",
        ),
    ]
