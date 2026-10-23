from django.db import migrations, models

"""
Migration 0047: MPDA Tenant Updates

Applies tenant schema modifications for MPDA across active states only:
1. Adds nullable columns proposal_no VARCHAR(50) and proposal_year VARCHAR(10) to mpda_proposals.
   (Retains existing proposal_no_and_year and io_uid columns without dropping).
2. Drops and recreates constraint chk_mpda_outcome_dates to allow Granted/Rejected with NULL dates,
   while strictly forbidding both dates at once and forbidding dates that do not match the outcome.

Idempotent and safe to run twice.
"""

SQL_MPDA_TENANT_UPDATES_UP = """
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
            -- 1. Add proposal_no and proposal_year columns if not present
            EXECUTE format('
                ALTER TABLE %%I.mpda_proposals ADD COLUMN IF NOT EXISTS proposal_no VARCHAR(50);
                ALTER TABLE %%I.mpda_proposals ADD COLUMN IF NOT EXISTS proposal_year VARCHAR(10);
            ', sch_rec.sch, sch_rec.sch);

            -- 2. Drop and re-add chk_mpda_outcome_dates constraint
            EXECUTE format('
                ALTER TABLE %%I.mpda_proposals DROP CONSTRAINT IF EXISTS chk_mpda_outcome_dates;
                ALTER TABLE %%I.mpda_proposals ADD CONSTRAINT chk_mpda_outcome_dates CHECK (
                    NOT (granted_date IS NOT NULL AND rejected_date IS NOT NULL)
                    AND
                    (
                        (proposal_outcome = ''Granted'' AND rejected_date IS NULL) OR
                        (proposal_outcome = ''Rejected'' AND granted_date IS NULL) OR
                        ((proposal_outcome IS NULL OR proposal_outcome = '''') AND granted_date IS NULL AND rejected_date IS NULL)
                    )
                );
            ', sch_rec.sch, sch_rec.sch);
        END IF;
    END LOOP;
END $$;
"""


def apply_mpda_tenant_updates(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(SQL_MPDA_TENANT_UPDATES_UP)
    else:
        # SQLite fallback for test suite
        with schema_editor.connection.cursor() as cursor:
            cursor.execute("PRAGMA table_info(mpda_proposals);")
            cols = [row[1] for row in cursor.fetchall()]
            if 'proposal_no' not in cols:
                cursor.execute("ALTER TABLE mpda_proposals ADD COLUMN proposal_no VARCHAR(50);")
            if 'proposal_year' not in cols:
                cursor.execute("ALTER TABLE mpda_proposals ADD COLUMN proposal_year VARCHAR(10);")


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0046_mpda_public_updates'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(
                    apply_mpda_tenant_updates,
                    reverse_code=migrations.RunPython.noop,
                ),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='mpdaproposal',
                    name='proposal_no',
                    field=models.CharField(blank=True, db_column='proposal_no', max_length=50, null=True),
                ),
                migrations.AddField(
                    model_name='mpdaproposal',
                    name='proposal_year',
                    field=models.CharField(blank=True, db_column='proposal_year', max_length=10, null=True),
                ),
            ],
        ),
    ]
