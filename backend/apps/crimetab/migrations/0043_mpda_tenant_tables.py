from django.db import migrations, models
import django.db.models.deletion


SQL_TENANT_MPDA_TABLES_UP = """
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
    LOOP
        EXECUTE format('CREATE SCHEMA IF NOT EXISTS %%I;', sch_rec.sch);

        -- 1. Main mpda_proposals table
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %%I.mpda_proposals (
                id BIGSERIAL PRIMARY KEY,
                station_name VARCHAR(255) NOT NULL,
                proposal_no_and_year VARCHAR(100),
                accused_name VARCHAR(255),
                accused_aadhaar VARCHAR(50),
                accused_mobile VARCHAR(10) CHECK (accused_mobile IS NULL OR accused_mobile ~ ''^[0-9]{10}$''),
                accused_address TEXT,
                accused_age INT CHECK (accused_age IS NULL OR (accused_age >= 1 AND accused_age <= 120)),
                accused_gender VARCHAR(50),
                io_uid VARCHAR(100),
                io_name VARCHAR(255),
                io_post VARCHAR(100),
                proposal_outcome VARCHAR(20),
                granted_date DATE,
                rejected_date DATE,
                detaining_authority VARCHAR(50),
                detaining_authority_other VARCHAR(255),
                detained VARCHAR(10),
                detention_date DATE,
                detention_completion_date DATE,
                jail_name VARCHAR(255),
                transfer_jail_name VARCHAR(255),
                government_confirmation VARCHAR(10),
                govt_confirmation_date DATE,
                detention_order_revoked VARCHAR(10),
                order_revoked_date DATE,
                mpda_category VARCHAR(100),
                mpda_category_other VARCHAR(255),
                total_crime INT,
                serious_crimes INT,
                created_by VARCHAR(100),
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT chk_mpda_outcome_dates CHECK (
                    (proposal_outcome = ''Granted'' AND rejected_date IS NULL) OR
                    (proposal_outcome = ''Rejected'' AND granted_date IS NULL) OR
                    ((proposal_outcome IS NULL OR proposal_outcome = '''') AND granted_date IS NULL AND rejected_date IS NULL)
                )
            );
            CREATE INDEX IF NOT EXISTS mpda_station_outcome_idx ON %%I.mpda_proposals (station_name, proposal_outcome);
        ', sch_rec.sch, sch_rec.sch);

        -- 2. Repeating gang members
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %%I.mpda_gang_members (
                id BIGSERIAL PRIMARY KEY,
                proposal_id BIGINT NOT NULL REFERENCES %%I.mpda_proposals(id) ON DELETE CASCADE,
                name VARCHAR(255),
                display_order SMALLINT DEFAULT 1,
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS mpda_gang_prop_idx ON %%I.mpda_gang_members (proposal_id);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch);

        -- 3. Repeating crime chart entries
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %%I.mpda_crime_chart_entries (
                id BIGSERIAL PRIMARY KEY,
                proposal_id BIGINT NOT NULL REFERENCES %%I.mpda_proposals(id) ON DELETE CASCADE,
                crime_type VARCHAR(100),
                cr_no VARCHAR(100),
                crime_date DATE,
                police_station VARCHAR(255),
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS mpda_crime_prop_idx ON %%I.mpda_crime_chart_entries (proposal_id);
            CREATE INDEX IF NOT EXISTS mpda_crime_type_idx ON %%I.mpda_crime_chart_entries (proposal_id, crime_type);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch, sch_rec.sch);
    END LOOP;
END $$;
"""


def create_tenant_mpda_tables(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_TENANT_MPDA_TABLES_UP)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0042_mpda_public_data'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(
                    create_tenant_mpda_tables,
                    reverse_code=migrations.RunPython.noop,
                )
            ],
            state_operations=[
                migrations.CreateModel(
                    name='MpdaProposal',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('station_name', models.CharField(max_length=255)),
                        ('proposal_no_and_year', models.CharField(blank=True, max_length=100, null=True)),
                        ('accused_name', models.CharField(blank=True, max_length=255, null=True)),
                        ('accused_aadhaar', models.CharField(blank=True, max_length=50, null=True)),
                        ('accused_mobile', models.CharField(blank=True, max_length=10, null=True)),
                        ('accused_address', models.TextField(blank=True, null=True)),
                        ('accused_age', models.IntegerField(blank=True, null=True)),
                        ('accused_gender', models.CharField(blank=True, max_length=50, null=True)),
                        ('io_uid', models.CharField(blank=True, max_length=100, null=True)),
                        ('io_name', models.CharField(blank=True, max_length=255, null=True)),
                        ('io_post', models.CharField(blank=True, max_length=100, null=True)),
                        ('proposal_outcome', models.CharField(blank=True, max_length=20, null=True)),
                        ('granted_date', models.DateField(blank=True, null=True)),
                        ('rejected_date', models.DateField(blank=True, null=True)),
                        ('detaining_authority', models.CharField(blank=True, max_length=50, null=True)),
                        ('detaining_authority_other', models.CharField(blank=True, max_length=255, null=True)),
                        ('detained', models.CharField(blank=True, max_length=10, null=True)),
                        ('detention_date', models.DateField(blank=True, null=True)),
                        ('detention_completion_date', models.DateField(blank=True, null=True)),
                        ('jail_name', models.CharField(blank=True, max_length=255, null=True)),
                        ('transfer_jail_name', models.CharField(blank=True, max_length=255, null=True)),
                        ('government_confirmation', models.CharField(blank=True, max_length=10, null=True)),
                        ('govt_confirmation_date', models.DateField(blank=True, null=True)),
                        ('detention_order_revoked', models.CharField(blank=True, max_length=10, null=True)),
                        ('order_revoked_date', models.DateField(blank=True, null=True)),
                        ('mpda_category', models.CharField(blank=True, max_length=100, null=True)),
                        ('mpda_category_other', models.CharField(blank=True, max_length=255, null=True)),
                        ('total_crime', models.IntegerField(blank=True, null=True)),
                        ('serious_crimes', models.IntegerField(blank=True, null=True)),
                        ('created_by', models.CharField(blank=True, max_length=100, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('updated_at', models.DateTimeField(auto_now=True)),
                    ],
                    options={
                        'verbose_name': 'MPDA Proposal',
                        'verbose_name_plural': 'MPDA Proposals',
                        'db_table': 'mpda_proposals',
                        'ordering': ['-created_at'],
                    },
                ),
                migrations.CreateModel(
                    name='MpdaGangMember',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('name', models.CharField(blank=True, max_length=255, null=True)),
                        ('display_order', models.SmallIntegerField(default=1)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('proposal', models.ForeignKey(db_column='proposal_id', on_delete=django.db.models.deletion.CASCADE, related_name='gang_members', to='crimetab.mpdaproposal')),
                    ],
                    options={
                        'verbose_name': 'MPDA Gang Member',
                        'verbose_name_plural': 'MPDA Gang Members',
                        'db_table': 'mpda_gang_members',
                        'ordering': ['display_order'],
                    },
                ),
                migrations.CreateModel(
                    name='MpdaCrimeChartEntry',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('crime_type', models.CharField(blank=True, max_length=100, null=True)),
                        ('cr_no', models.CharField(blank=True, max_length=100, null=True)),
                        ('crime_date', models.DateField(blank=True, null=True)),
                        ('police_station', models.CharField(blank=True, max_length=255, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('proposal', models.ForeignKey(db_column='proposal_id', on_delete=django.db.models.deletion.CASCADE, related_name='crime_chart_entries', to='crimetab.mpdaproposal')),
                    ],
                    options={
                        'verbose_name': 'MPDA Crime Chart Entry',
                        'verbose_name_plural': 'MPDA Crime Chart Entries',
                        'db_table': 'mpda_crime_chart_entries',
                        'ordering': ['-crime_date'],
                    },
                ),
            ],
        ),
    ]
