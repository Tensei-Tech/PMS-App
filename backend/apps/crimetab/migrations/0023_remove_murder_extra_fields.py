from django.db import migrations

SQL_REMOVE_MURDER_EXTRA_FIELDS = """
DO $$
DECLARE
    target_keys TEXT[] := ARRAY[
        'deceased_name',
        'deceased_age',
        'deceased_gender',
        'inquest_panchanama',
        'pm_report_date',
        'cause_of_death'
    ];
    sch_rec RECORD;
BEGIN
    -- 1. Delete rows from case_extra_field_values in every tenant schema dynamically (where table exists)
    IF to_regclass('public.states') IS NOT NULL THEN
        FOR sch_rec IN
            EXECUTE 'SELECT DISTINCT LOWER(TRIM(schema_name)) AS sch FROM public.states WHERE schema_name IS NOT NULL AND TRIM(schema_name) != '''' UNION SELECT ''public'' AS sch'
        LOOP
            IF to_regclass(format('%I.case_extra_field_values', sch_rec.sch)) IS NOT NULL 
               AND to_regclass('public.field_template_fields') IS NOT NULL 
               AND to_regclass('public.field_templates') IS NOT NULL THEN
                EXECUTE format('
                    DELETE FROM %I.case_extra_field_values
                    WHERE field_def_id IN (
                        SELECT ftf.field_def_id
                        FROM public.field_template_fields ftf
                        JOIN public.field_templates ft ON ft.template_id = ftf.template_id
                        WHERE ft.template_name = ''Murder Section Extra Fields''
                          AND ftf.field_key = ANY($1)
                    );
                ', sch_rec.sch) USING target_keys;
            END IF;
        END LOOP;
    ELSIF to_regclass('public.public_master_stateregistry') IS NOT NULL THEN
        FOR sch_rec IN
            EXECUTE 'SELECT DISTINCT LOWER(TRIM(schema_name)) AS sch FROM public.public_master_stateregistry WHERE schema_name IS NOT NULL AND TRIM(schema_name) != '''' UNION SELECT ''public'' AS sch'
        LOOP
            IF to_regclass(format('%I.case_extra_field_values', sch_rec.sch)) IS NOT NULL 
               AND to_regclass('public.field_template_fields') IS NOT NULL 
               AND to_regclass('public.field_templates') IS NOT NULL THEN
                EXECUTE format('
                    DELETE FROM %I.case_extra_field_values
                    WHERE field_def_id IN (
                        SELECT ftf.field_def_id
                        FROM public.field_template_fields ftf
                        JOIN public.field_templates ft ON ft.template_id = ftf.template_id
                        WHERE ft.template_name = ''Murder Section Extra Fields''
                          AND ftf.field_key = ANY($1)
                    );
                ', sch_rec.sch) USING target_keys;
            END IF;
        END LOOP;
    ELSE
        FOR sch_rec IN
            SELECT schema_name AS sch
            FROM information_schema.schemata
            WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'graphql', 'graphql_public', 'vault', 'supabase_functions', 'supabase_migrations', 'extensions', 'cron', 'net', '_analytics', '_realtime')
              AND schema_name NOT LIKE 'pg_temp_%'
              AND schema_name NOT LIKE 'pg_toast_%'
        LOOP
            IF to_regclass(format('%I.case_extra_field_values', sch_rec.sch)) IS NOT NULL 
               AND to_regclass('public.field_template_fields') IS NOT NULL 
               AND to_regclass('public.field_templates') IS NOT NULL THEN
                EXECUTE format('
                    DELETE FROM %I.case_extra_field_values
                    WHERE field_def_id IN (
                        SELECT ftf.field_def_id
                        FROM public.field_template_fields ftf
                        JOIN public.field_templates ft ON ft.template_id = ftf.template_id
                        WHERE ft.template_name = ''Murder Section Extra Fields''
                          AND ftf.field_key = ANY($1)
                    );
                ', sch_rec.sch) USING target_keys;
            END IF;
        END LOOP;
    END IF;

    -- Direct cleanup in current search_path / public if table exists
    IF to_regclass('case_extra_field_values') IS NOT NULL 
       AND to_regclass('field_template_fields') IS NOT NULL 
       AND to_regclass('field_templates') IS NOT NULL THEN
        DELETE FROM case_extra_field_values
        WHERE field_def_id IN (
            SELECT ftf.field_def_id
            FROM field_template_fields ftf
            JOIN field_templates ft ON ft.template_id = ftf.template_id
            WHERE ft.template_name = 'Murder Section Extra Fields'
              AND ftf.field_key = ANY(target_keys)
        );
    END IF;

    -- 2. Delete field_template_fields rows for the template named 'Murder Section Extra Fields'
    IF to_regclass('public.field_template_fields') IS NOT NULL AND to_regclass('public.field_templates') IS NOT NULL THEN
        DELETE FROM public.field_template_fields
        WHERE template_id IN (
            SELECT template_id FROM public.field_templates WHERE template_name = 'Murder Section Extra Fields'
        )
        AND field_key = ANY(target_keys);
    ELSIF to_regclass('field_template_fields') IS NOT NULL AND to_regclass('field_templates') IS NOT NULL THEN
        DELETE FROM field_template_fields
        WHERE template_id IN (
            SELECT template_id FROM field_templates WHERE template_name = 'Murder Section Extra Fields'
        )
        AND field_key = ANY(target_keys);
    END IF;
END
$$;
"""


def remove_murder_extra_fields(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor == 'postgresql':
        with connection.cursor() as cursor:
            cursor.execute(SQL_REMOVE_MURDER_EXTRA_FIELDS)
    else:
        # SQLite / in-memory test runner execution
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        CaseExtraFieldValue = apps.get_model('crimetab', 'CaseExtraFieldValue')

        target_keys = [
            'deceased_name',
            'deceased_age',
            'deceased_gender',
            'inquest_panchanama',
            'pm_report_date',
            'cause_of_death',
        ]

        tmpl = FieldTemplate.objects.filter(template_name='Murder Section Extra Fields').first()
        if tmpl:
            fields_to_delete = FieldTemplateField.objects.filter(template=tmpl, field_key__in=target_keys)
            CaseExtraFieldValue.objects.filter(field_def__in=fields_to_delete).delete()
            fields_to_delete.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0022_merge_20261005_1303'),
    ]

    operations = [
        migrations.RunPython(
            remove_murder_extra_fields,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
