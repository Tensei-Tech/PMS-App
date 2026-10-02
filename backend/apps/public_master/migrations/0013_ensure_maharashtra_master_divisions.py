from django.db import migrations

SQL_CREATE_MAHARASHTRA_MASTER_DIVISIONS = """
DO $$
DECLARE
    target_schemas TEXT[] := ARRAY['maharashtra', 'manipur', 'bihar'];
    s TEXT;
BEGIN
    FOREACH s IN ARRAY target_schemas
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = s) THEN
            EXECUTE format('
                CREATE TABLE IF NOT EXISTS %I.master_divisions (
                    id BIGSERIAL PRIMARY KEY,
                    state_code VARCHAR(10) NOT NULL DEFAULT ''MH'',
                    state_name VARCHAR(100) NOT NULL DEFAULT ''Maharashtra'',
                    name VARCHAR(128) NOT NULL,
                    code VARCHAR(64),
                    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT %I_master_divisions_state_name_uniq UNIQUE (state_code, name)
                );
            ', s, s);
        END IF;
    END LOOP;
END
$$;
"""

SQL_REVERSE = """
DO $$
DECLARE
    target_schemas TEXT[] := ARRAY['maharashtra', 'manipur', 'bihar'];
    s TEXT;
BEGIN
    FOREACH s IN ARRAY target_schemas
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = s) THEN
            EXECUTE format('DROP TABLE IF EXISTS %I.master_divisions CASCADE;', s);
        END IF;
    END LOOP;
END
$$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0012_drop_master_divisions_old_unused'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_CREATE_MAHARASHTRA_MASTER_DIVISIONS,
            reverse_sql=SQL_REVERSE,
        ),
    ]
