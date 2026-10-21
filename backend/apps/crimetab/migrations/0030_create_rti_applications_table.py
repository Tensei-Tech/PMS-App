from django.db import migrations, models


# Note: Migration is one-way.
SQL_TENANT_RTI_TABLE_UP = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    -- Discover all state tenant schemas that contain tenant tables (e.g. users_officerprofile)
    FOR sch_rec IN
        SELECT DISTINCT table_schema AS sch
        FROM information_schema.tables
        WHERE table_name = 'users_officerprofile'
          AND table_schema NOT IN ('public', 'information_schema', 'pg_catalog')
    LOOP
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.rti_applications (
                rti_id BIGSERIAL PRIMARY KEY,
                station_name VARCHAR(255) NOT NULL,
                serial_year SMALLINT NOT NULL,
                serial_no INTEGER NOT NULL,
                applicant_name VARCHAR(255) NOT NULL,
                applicant_age SMALLINT CHECK (applicant_age BETWEEN 1 AND 120),
                mobile_no VARCHAR(10) CHECK (mobile_no ~ ''^[0-9]{10}$''),
                address TEXT NOT NULL,
                email VARCHAR(254),
                received_date DATE NOT NULL,
                due_date DATE NOT NULL,
                replied_date DATE,
                rejected_date DATE,
                rejection_reason TEXT,
                transferred_to TEXT,
                info_type VARCHAR(50) NOT NULL,
                info_type_other VARCHAR(50),
                assigned_officer_uid VARCHAR(128),
                assigned_officer_name VARCHAR(255),
                assigned_officer_designation VARCHAR(128),
                mode_of_receipt VARCHAR(50) NOT NULL,
                is_bpl BOOLEAN NOT NULL DEFAULT FALSE,
                remark TEXT,
                appealed BOOLEAN NOT NULL DEFAULT FALSE,
                appeal_date DATE,
                status VARCHAR(10) GENERATED ALWAYS AS (
                    CASE WHEN replied_date IS NOT NULL OR rejected_date IS NOT NULL
                         OR length(trim(coalesce(transferred_to,''''))) > 0
                    THEN ''Disposal'' ELSE ''Pending'' END) STORED,
                created_by VARCHAR(128),
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                CONSTRAINT rti_serial_unique UNIQUE (station_name, serial_year, serial_no),
                CONSTRAINT rti_due_after_received CHECK (due_date >= received_date),
                CONSTRAINT rti_one_outcome CHECK (
                    (CASE WHEN replied_date IS NOT NULL THEN 1 ELSE 0 END
                   + CASE WHEN rejected_date IS NOT NULL THEN 1 ELSE 0 END
                   + CASE WHEN length(trim(coalesce(transferred_to,''''))) > 0 THEN 1 ELSE 0 END) <= 1),
                CONSTRAINT rti_reject_reason CHECK (
                    (rejected_date IS NULL AND rejection_reason IS NULL)
                 OR (rejected_date IS NOT NULL AND length(trim(coalesce(rejection_reason,''''))) > 0)),
                CONSTRAINT rti_appeal_rule CHECK (
                    (appealed AND appeal_date IS NOT NULL) OR (NOT appealed AND appeal_date IS NULL))
            );
            CREATE INDEX IF NOT EXISTS rti_station_status_idx
                ON %I.rti_applications (station_name, status);
        ', sch_rec.sch, sch_rec.sch);
    END LOOP;
END $$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0029_add_rti_category_template_and_seed_data'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunSQL(
                    sql=SQL_TENANT_RTI_TABLE_UP,
                    reverse_sql=""
                )
            ],
            state_operations=[
                migrations.CreateModel(
                    name='RTIApplication',
                    fields=[
                        ('rti_id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('station_name', models.CharField(max_length=255)),
                        ('serial_year', models.SmallIntegerField()),
                        ('serial_no', models.IntegerField()),
                        ('applicant_name', models.CharField(max_length=255)),
                        ('applicant_age', models.SmallIntegerField(blank=True, null=True)),
                        ('mobile_no', models.CharField(blank=True, max_length=10, null=True)),
                        ('address', models.TextField()),
                        ('email', models.EmailField(blank=True, max_length=254, null=True)),
                        ('received_date', models.DateField()),
                        ('due_date', models.DateField()),
                        ('replied_date', models.DateField(blank=True, null=True)),
                        ('rejected_date', models.DateField(blank=True, null=True)),
                        ('rejection_reason', models.TextField(blank=True, null=True)),
                        ('transferred_to', models.TextField(blank=True, null=True)),
                        ('info_type', models.CharField(max_length=50)),
                        ('info_type_other', models.CharField(blank=True, max_length=50, null=True)),
                        ('assigned_officer_uid', models.CharField(blank=True, max_length=128, null=True)),
                        ('assigned_officer_name', models.CharField(blank=True, max_length=255, null=True)),
                        ('assigned_officer_designation', models.CharField(blank=True, max_length=128, null=True)),
                        ('mode_of_receipt', models.CharField(max_length=50)),
                        ('is_bpl', models.BooleanField(default=False)),
                        ('remark', models.TextField(blank=True, null=True)),
                        ('appealed', models.BooleanField(default=False)),
                        ('appeal_date', models.DateField(blank=True, null=True)),
                        ('status', models.CharField(editable=False, max_length=10)),
                        ('created_by', models.CharField(blank=True, max_length=128, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('updated_at', models.DateTimeField(auto_now=True)),
                    ],
                    options={
                        'verbose_name': 'RTI Application',
                        'verbose_name_plural': 'RTI Applications',
                        'db_table': 'rti_applications',
                        'ordering': ['-created_at'],
                        'unique_together': {('station_name', 'serial_year', 'serial_no')},
                    },
                ),
            ]
        ),
    ]
