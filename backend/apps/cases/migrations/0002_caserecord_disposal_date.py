from django.db import migrations, models

SQL_ADD_DISPOSAL_DATE = """
DO $$
DECLARE
    target_schemas TEXT[] := ARRAY['maharashtra', 'manipur', 'bihar', 'public'];
    s TEXT;
BEGIN
    FOREACH s IN ARRAY target_schemas
    LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = s AND table_name = 'cases_caserecord'
        ) THEN
            EXECUTE format('ALTER TABLE %I.cases_caserecord ADD COLUMN IF NOT EXISTS disposal_date TIMESTAMPTZ;', s);
        END IF;
    END LOOP;
END
$$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0001_initial'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AddField(
                    model_name='caserecord',
                    name='disposal_date',
                    field=models.DateTimeField(blank=True, null=True),
                ),
            ],
            database_operations=[
                migrations.RunSQL(
                    sql=SQL_ADD_DISPOSAL_DATE,
                    reverse_sql="ALTER TABLE IF EXISTS maharashtra.cases_caserecord DROP COLUMN IF EXISTS disposal_date;",
                ),
            ],
        ),
    ]
