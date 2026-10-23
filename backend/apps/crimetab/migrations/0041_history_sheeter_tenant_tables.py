from django.db import migrations, models
import django.db.models.deletion
import apps.crimetab.models.history_sheeter


SQL_TENANT_HS_TABLES_UP = """
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

        -- 1. Main history_sheeters table
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %%I.history_sheeters (
                id BIGSERIAL PRIMARY KEY,
                station_name VARCHAR(255) NOT NULL,
                sr_no BIGINT NOT NULL,
                name VARCHAR(255),
                alias VARCHAR(255),
                nickname VARCHAR(255),
                age INT CHECK (age IS NULL OR (age >= 1 AND age <= 120)),
                gender VARCHAR(50),
                mobile_no VARCHAR(10) CHECK (mobile_no IS NULL OR mobile_no ~ ''^[0-9]{10}$''),
                address TEXT,
                history_sheet_no VARCHAR(100),
                opening_date DATE,
                order_date DATE,
                permanent_address TEXT,
                present_address TEXT,
                same_as_above BOOLEAN DEFAULT FALSE,
                native_place VARCHAR(255),
                occupation VARCHAR(255),
                aadhaar_id_details VARCHAR(255),
                categories TEXT[],
                category_other VARCHAR(255),
                modus_operandi TEXT,
                total_cases INT,
                convicted_cases INT,
                pending_cases INT,
                acquitted_discharged_cases INT,
                whereabouts TEXT,
                last_verification_date DATE,
                verification_remarks TEXT,
                closure_date DATE,
                closure_reason VARCHAR(255),
                closure_remarks TEXT,
                currently_in_jail VARCHAR(10),
                currently_on_bail VARCHAR(10),
                created_by VARCHAR(100),
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT uq_history_sheeter_station_sr_no UNIQUE (station_name, sr_no)
            );
            CREATE INDEX IF NOT EXISTS hs_station_sr_idx ON %%I.history_sheeters (station_name, sr_no);
        ', sch_rec.sch, sch_rec.sch);

        -- 2. Related persons (associates, rivals, sureties)
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %%I.history_sheeter_related_persons (
                id BIGSERIAL PRIMARY KEY,
                history_sheeter_id BIGINT NOT NULL REFERENCES %%I.history_sheeters(id) ON DELETE CASCADE,
                person_type VARCHAR(20) NOT NULL CHECK (person_type IN (''associate'', ''rival'', ''surety'')),
                name VARCHAR(255),
                alias VARCHAR(255),
                nickname VARCHAR(255),
                age INT CHECK (age IS NULL OR (age >= 1 AND age <= 120)),
                gender VARCHAR(50),
                mobile_no VARCHAR(10) CHECK (mobile_no IS NULL OR mobile_no ~ ''^[0-9]{10}$''),
                address TEXT,
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS hs_rel_person_hs_idx ON %%I.history_sheeter_related_persons (history_sheeter_id, person_type);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch);

        -- 3. Preventive actions
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %%I.history_sheeter_preventive_actions (
                id BIGSERIAL PRIMARY KEY,
                history_sheeter_id BIGINT NOT NULL REFERENCES %%I.history_sheeters(id) ON DELETE CASCADE,
                action_type VARCHAR(100),
                action_other VARCHAR(255),
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS hs_prev_hs_idx ON %%I.history_sheeter_preventive_actions (history_sheeter_id);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch);

        -- 4. Crimes (crime chart)
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %%I.history_sheeter_crimes (
                id BIGSERIAL PRIMARY KEY,
                history_sheeter_id BIGINT NOT NULL REFERENCES %%I.history_sheeters(id) ON DELETE CASCADE,
                cr_no VARCHAR(100),
                crime_head TEXT,
                act_section TEXT,
                register_date DATE,
                police_station VARCHAR(255),
                created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            CREATE INDEX IF NOT EXISTS hs_crimes_hs_idx ON %%I.history_sheeter_crimes (history_sheeter_id);
            CREATE INDEX IF NOT EXISTS hs_crimes_reg_date_idx ON %%I.history_sheeter_crimes (register_date);
        ', sch_rec.sch, sch_rec.sch, sch_rec.sch, sch_rec.sch);
    END LOOP;
END $$;
"""


def create_tenant_hs_tables(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_TENANT_HS_TABLES_UP)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0040_history_sheeter_public_data'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(
                    create_tenant_hs_tables,
                    reverse_code=migrations.RunPython.noop,
                )
            ],
            state_operations=[
                migrations.CreateModel(
                    name='HistorySheeter',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('station_name', models.CharField(max_length=255)),
                        ('sr_no', models.BigIntegerField()),
                        ('name', models.CharField(blank=True, max_length=255, null=True)),
                        ('alias', models.CharField(blank=True, max_length=255, null=True)),
                        ('nickname', models.CharField(blank=True, max_length=255, null=True)),
                        ('age', models.IntegerField(blank=True, null=True)),
                        ('gender', models.CharField(blank=True, max_length=50, null=True)),
                        ('mobile_no', models.CharField(blank=True, max_length=10, null=True)),
                        ('address', models.TextField(blank=True, null=True)),
                        ('history_sheet_no', models.CharField(blank=True, max_length=100, null=True)),
                        ('opening_date', models.DateField(blank=True, null=True)),
                        ('order_date', models.DateField(blank=True, null=True)),
                        ('permanent_address', models.TextField(blank=True, null=True)),
                        ('present_address', models.TextField(blank=True, null=True)),
                        ('same_as_above', models.BooleanField(default=False)),
                        ('native_place', models.CharField(blank=True, max_length=255, null=True)),
                        ('occupation', models.CharField(blank=True, max_length=255, null=True)),
                        ('aadhaar_id_details', models.CharField(blank=True, max_length=255, null=True)),
                        ('categories', apps.crimetab.models.history_sheeter.SafeArrayField(base_field=models.CharField(max_length=100), blank=True, default=list, null=True, size=None)),
                        ('category_other', models.CharField(blank=True, max_length=255, null=True)),
                        ('modus_operandi', models.TextField(blank=True, null=True)),
                        ('total_cases', models.IntegerField(blank=True, null=True)),
                        ('convicted_cases', models.IntegerField(blank=True, null=True)),
                        ('pending_cases', models.IntegerField(blank=True, null=True)),
                        ('acquitted_discharged_cases', models.IntegerField(blank=True, null=True)),
                        ('whereabouts', models.TextField(blank=True, null=True)),
                        ('last_verification_date', models.DateField(blank=True, null=True)),
                        ('verification_remarks', models.TextField(blank=True, null=True)),
                        ('closure_date', models.DateField(blank=True, null=True)),
                        ('closure_reason', models.CharField(blank=True, max_length=255, null=True)),
                        ('closure_remarks', models.TextField(blank=True, null=True)),
                        ('currently_in_jail', models.CharField(blank=True, max_length=10, null=True)),
                        ('currently_on_bail', models.CharField(blank=True, max_length=10, null=True)),
                        ('created_by', models.CharField(blank=True, max_length=100, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('updated_at', models.DateTimeField(auto_now=True)),
                    ],
                    options={
                        'verbose_name': 'History Sheeter',
                        'verbose_name_plural': 'History Sheeters',
                        'db_table': 'history_sheeters',
                        'ordering': ['sr_no'],
                        'unique_together': {('station_name', 'sr_no')},
                    },
                ),
                migrations.CreateModel(
                    name='HistorySheeterRelatedPerson',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('person_type', models.CharField(max_length=20)),
                        ('name', models.CharField(blank=True, max_length=255, null=True)),
                        ('alias', models.CharField(blank=True, max_length=255, null=True)),
                        ('nickname', models.CharField(blank=True, max_length=255, null=True)),
                        ('age', models.IntegerField(blank=True, null=True)),
                        ('gender', models.CharField(blank=True, max_length=50, null=True)),
                        ('mobile_no', models.CharField(blank=True, max_length=10, null=True)),
                        ('address', models.TextField(blank=True, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('history_sheeter', models.ForeignKey(db_column='history_sheeter_id', on_delete=django.db.models.deletion.CASCADE, related_name='related_persons', to='crimetab.historysheeter')),
                    ],
                    options={
                        'verbose_name': 'History Sheeter Related Person',
                        'verbose_name_plural': 'History Sheeter Related Persons',
                        'db_table': 'history_sheeter_related_persons',
                    },
                ),
                migrations.CreateModel(
                    name='HistorySheeterPreventiveAction',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('action_type', models.CharField(blank=True, max_length=100, null=True)),
                        ('action_other', models.CharField(blank=True, max_length=255, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('history_sheeter', models.ForeignKey(db_column='history_sheeter_id', on_delete=django.db.models.deletion.CASCADE, related_name='preventive_actions', to='crimetab.historysheeter')),
                    ],
                    options={
                        'verbose_name': 'History Sheeter Preventive Action',
                        'verbose_name_plural': 'History Sheeter Preventive Actions',
                        'db_table': 'history_sheeter_preventive_actions',
                    },
                ),
                migrations.CreateModel(
                    name='HistorySheeterCrime',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('cr_no', models.CharField(blank=True, max_length=100, null=True)),
                        ('crime_head', models.TextField(blank=True, null=True)),
                        ('act_section', models.TextField(blank=True, null=True)),
                        ('register_date', models.DateField(blank=True, null=True)),
                        ('police_station', models.CharField(blank=True, max_length=255, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('history_sheeter', models.ForeignKey(db_column='history_sheeter_id', on_delete=django.db.models.deletion.CASCADE, related_name='crimes', to='crimetab.historysheeter')),
                    ],
                    options={
                        'verbose_name': 'History Sheeter Crime',
                        'verbose_name_plural': 'History Sheeter Crimes',
                        'db_table': 'history_sheeter_crimes',
                        'ordering': ['-register_date'],
                    },
                ),
            ],
        ),
    ]
