from django.db import migrations, models
import django.db.models.deletion

"""
Migration 0049: MPDA Accused Tenant Tables & Data Migration

1. Creates table <schema>.mpda_accused_persons in active tenant schemas:
   - id BIGSERIAL PRIMARY KEY
   - proposal_id FK to mpda_proposals(id) ON DELETE CASCADE
   - display_order SMALLINT DEFAULT 1
   - name VARCHAR(255)
   - age INT CHECK (age IS NULL OR (age >= 1 AND age <= 120))
   - gender VARCHAR(50)
   - occupation VARCHAR(255)
   - mobile VARCHAR(10) CHECK (mobile IS NULL OR mobile = '' OR mobile ~ '^[0-9]{10}$')
   - aadhaar VARCHAR(50)
   - pan VARCHAR(50)
   - cast VARCHAR(100)
   - religion VARCHAR(100)
   - address TEXT
   - created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
2. Copies existing single-accused records from mpda_proposals idempotently into mpda_accused_persons.
"""

SQL_MPDA_TENANT_ACCUSED_0049_UP = """
DO $$
DECLARE
    sch_rec RECORD;
BEGIN
    FOR sch_rec IN
        SELECT DISTINCT schema_name AS sch
        FROM public.states
        WHERE is_active = TRUE
          AND schema_name NOT IN ('public', 'information_schema', 'pg_catalog')
    LOOP
        IF to_regclass(format('%%s.mpda_proposals', sch_rec.sch)) IS NOT NULL THEN
            -- 1. Create table mpda_accused_persons
            EXECUTE format('
                CREATE TABLE IF NOT EXISTS %%I.mpda_accused_persons (
                    id BIGSERIAL PRIMARY KEY,
                    proposal_id BIGINT NOT NULL REFERENCES %%I.mpda_proposals(id) ON DELETE CASCADE,
                    display_order SMALLINT DEFAULT 1,
                    name VARCHAR(255),
                    age INT CHECK (age IS NULL OR (age >= 1 AND age <= 120)),
                    gender VARCHAR(50),
                    occupation VARCHAR(255),
                    mobile VARCHAR(10) CHECK (mobile IS NULL OR mobile = '''' OR mobile ~ ''^[0-9]{10}$''),
                    aadhaar VARCHAR(50),
                    pan VARCHAR(50),
                    "cast" VARCHAR(100),
                    religion VARCHAR(100),
                    address TEXT,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
                );
                CREATE INDEX IF NOT EXISTS mpda_accused_prop_idx ON %%I.mpda_accused_persons (proposal_id);
            ', sch_rec.sch, sch_rec.sch, sch_rec.sch);

            -- 2. Idempotently copy existing single accused data into new table
            EXECUTE format('
                INSERT INTO %%I.mpda_accused_persons (
                    proposal_id, display_order, name, age, gender, mobile, aadhaar, address
                )
                SELECT
                    p.id, 1, p.accused_name, p.accused_age, p.accused_gender, p.accused_mobile, p.accused_aadhaar, p.accused_address
                FROM %%I.mpda_proposals p
                WHERE (
                    p.accused_name IS NOT NULL OR
                    p.accused_aadhaar IS NOT NULL OR
                    p.accused_mobile IS NOT NULL OR
                    p.accused_address IS NOT NULL OR
                    p.accused_age IS NOT NULL OR
                    p.accused_gender IS NOT NULL
                )
                AND NOT EXISTS (
                    SELECT 1 FROM %%I.mpda_accused_persons a WHERE a.proposal_id = p.id
                );
            ', sch_rec.sch, sch_rec.sch, sch_rec.sch);
        END IF;
    END LOOP;
END $$;
"""


def apply_tenant_accused_0049(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_MPDA_TENANT_ACCUSED_0049_UP)
    else:
        # SQLite fallback for test execution
        with schema_editor.connection.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS mpda_accused_persons (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    proposal_id BIGINT NOT NULL REFERENCES mpda_proposals(id) ON DELETE CASCADE,
                    display_order SMALLINT DEFAULT 1,
                    name VARCHAR(255),
                    age INT,
                    gender VARCHAR(50),
                    occupation VARCHAR(255),
                    mobile VARCHAR(10),
                    aadhaar VARCHAR(50),
                    pan VARCHAR(50),
                    "cast" VARCHAR(100),
                    religion VARCHAR(100),
                    address TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0048_mpda_accused_repeating_group_public'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(
                    apply_tenant_accused_0049,
                    reverse_code=migrations.RunPython.noop,
                ),
            ],
            state_operations=[
                migrations.CreateModel(
                    name='MpdaAccusedPerson',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('display_order', models.SmallIntegerField(default=1)),
                        ('name', models.CharField(blank=True, max_length=255, null=True)),
                        ('age', models.IntegerField(blank=True, null=True)),
                        ('gender', models.CharField(blank=True, max_length=50, null=True)),
                        ('occupation', models.CharField(blank=True, max_length=255, null=True)),
                        ('mobile', models.CharField(blank=True, max_length=10, null=True)),
                        ('aadhaar', models.CharField(blank=True, max_length=50, null=True)),
                        ('pan', models.CharField(blank=True, max_length=50, null=True)),
                        ('cast', models.CharField(blank=True, max_length=100, null=True)),
                        ('religion', models.CharField(blank=True, max_length=100, null=True)),
                        ('address', models.TextField(blank=True, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('proposal', models.ForeignKey(db_column='proposal_id', on_delete=django.db.models.deletion.CASCADE, related_name='accused_persons', to='crimetab.mpdaproposal')),
                    ],
                    options={
                        'verbose_name': 'MPDA Accused Person',
                        'verbose_name_plural': 'MPDA Accused Persons',
                        'db_table': 'mpda_accused_persons',
                        'ordering': ['display_order', 'id'],
                    },
                ),
            ],
        ),
    ]
