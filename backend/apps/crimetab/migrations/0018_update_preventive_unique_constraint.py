from django.db import migrations, models


def update_preventive_constraints(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        for schema in ['maharashtra', 'manipur', 'bihar']:
            cursor.execute("SELECT 1 FROM information_schema.schemata WHERE schema_name = %s;", [schema])
            if not cursor.fetchone():
                continue
            # Drop old single action per case unique constraint
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.preventive_action_items DROP CONSTRAINT IF EXISTS preventive_action_items_case_id_action_type_key;")
            # Add new unique constraint per case, person, and action
            cursor.execute(f"""
                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM pg_constraint c
                        JOIN pg_namespace n ON n.oid = c.connamespace
                        WHERE c.conname = 'preventive_action_items_case_person_action_key'
                        AND n.nspname = '{schema}'
                    ) THEN
                        ALTER TABLE {schema}.preventive_action_items
                        ADD CONSTRAINT preventive_action_items_case_person_action_key
                        UNIQUE (case_id, person_id, action_type);
                    END IF;
                END $$;
            """)
            # Update check constraint on action_type to accept both spaced and non-spaced variations
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.preventive_action_items DROP CONSTRAINT IF EXISTS preventive_action_items_action_type_check;")
            cursor.execute(f"""
                ALTER TABLE IF EXISTS {schema}.preventive_action_items
                ADD CONSTRAINT preventive_action_items_action_type_check
                CHECK ((action_type::text = ANY ((ARRAY[
                    '107 CrPC/126 BNSS'::character varying,
                    '107 Crpc / 126 BNSS'::character varying,
                    '109 CrPC/128 BNSS'::character varying,
                    '109 Crpc / 128 BNSS'::character varying,
                    '110 CrPC/129 BNSS'::character varying,
                    '110 Crpc / 129 BNSS'::character varying,
                    '151(3) CrPC/170 BNSS'::character varying,
                    '151(3) Crpc / 170 BNSS'::character varying,
                    '144 CrPC/163 BNSS'::character varying,
                    '144 Crpc / 163 BNSS'::character varying,
                    '149 CrPC/168 BNSS'::character varying,
                    '149 Crpc / 168 BNSS'::character varying,
                    '55 MPA'::character varying,
                    '56 MPA'::character varying,
                    '57 MPA'::character varying,
                    '122 MPA'::character varying,
                    '93 Prohibition Act'::character varying
                ])::text[])));
            """)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0017_update_remand_and_preventive_models'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AlterUniqueTogether(
                    name='preventiveactionitems',
                    unique_together={('case', 'person', 'action_type')},
                ),
            ],
            database_operations=[
                migrations.RunPython(
                    update_preventive_constraints,
                    migrations.RunPython.noop
                ),
            ]
        ),
    ]
