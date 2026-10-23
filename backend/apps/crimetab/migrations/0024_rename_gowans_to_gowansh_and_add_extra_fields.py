from django.db import migrations

SQL_APPLY_GOWANSH = """
DO $$
DECLARE
    sch_rec RECORD;
    gowansh_tmpl_id BIGINT;
    cat_rec RECORD;
BEGIN
    -- 1. Rename 'Gowans' to 'Gowansh' in public.case_categories
    IF to_regclass('public.case_categories') IS NOT NULL THEN
        UPDATE public.case_categories
        SET category_name = 'Gowansh'
        WHERE category_name = 'Gowans';
    ELSIF to_regclass('case_categories') IS NOT NULL THEN
        UPDATE case_categories
        SET category_name = 'Gowansh'
        WHERE category_name = 'Gowans';
    END IF;

    -- 2. Update text name in tenant tables (cases_caserecord.sub_category) dynamically
    IF to_regclass('public.states') IS NOT NULL THEN
        FOR sch_rec IN
            EXECUTE 'SELECT DISTINCT LOWER(TRIM(schema_name)) AS sch FROM public.states WHERE schema_name IS NOT NULL AND TRIM(schema_name) != '''' UNION SELECT ''public'' AS sch'
        LOOP
            IF to_regclass(format('%I.cases_caserecord', sch_rec.sch)) IS NOT NULL THEN
                EXECUTE format('
                    UPDATE %I.cases_caserecord
                    SET sub_category = ''Gowansh''
                    WHERE sub_category = ''Gowans'' OR sub_category = ''gowans'';
                ', sch_rec.sch);
            END IF;
        END LOOP;
    ELSIF to_regclass('public.public_master_stateregistry') IS NOT NULL THEN
        FOR sch_rec IN
            EXECUTE 'SELECT DISTINCT LOWER(TRIM(schema_name)) AS sch FROM public.public_master_stateregistry WHERE schema_name IS NOT NULL AND TRIM(schema_name) != '''' UNION SELECT ''public'' AS sch'
        LOOP
            IF to_regclass(format('%I.cases_caserecord', sch_rec.sch)) IS NOT NULL THEN
                EXECUTE format('
                    UPDATE %I.cases_caserecord
                    SET sub_category = ''Gowansh''
                    WHERE sub_category = ''Gowans'' OR sub_category = ''gowans'';
                ', sch_rec.sch);
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
            IF to_regclass(format('%I.cases_caserecord', sch_rec.sch)) IS NOT NULL THEN
                EXECUTE format('
                    UPDATE %I.cases_caserecord
                    SET sub_category = ''Gowansh''
                    WHERE sub_category = ''Gowans'' OR sub_category = ''gowans'';
                ', sch_rec.sch);
            END IF;
        END LOOP;
    END IF;

    -- Direct fallback in search_path
    IF to_regclass('cases_caserecord') IS NOT NULL THEN
        UPDATE cases_caserecord
        SET sub_category = 'Gowansh'
        WHERE sub_category = 'Gowans' OR sub_category = 'gowans';
    END IF;

    -- 3. Create bundle "Gowansh Extra Fields" in public.field_templates if it does not exist
    IF to_regclass('public.field_templates') IS NOT NULL THEN
        INSERT INTO public.field_templates (template_name, created_at)
        SELECT 'Gowansh Extra Fields', CURRENT_TIMESTAMP
        WHERE NOT EXISTS (
            SELECT 1 FROM public.field_templates WHERE template_name = 'Gowansh Extra Fields'
        );
        SELECT template_id INTO gowansh_tmpl_id FROM public.field_templates WHERE template_name = 'Gowansh Extra Fields' LIMIT 1;
    ELSIF to_regclass('field_templates') IS NOT NULL THEN
        INSERT INTO field_templates (template_name, created_at)
        SELECT 'Gowansh Extra Fields', CURRENT_TIMESTAMP
        WHERE NOT EXISTS (
            SELECT 1 FROM field_templates WHERE template_name = 'Gowansh Extra Fields'
        );
        SELECT template_id INTO gowansh_tmpl_id FROM field_templates WHERE template_name = 'Gowansh Extra Fields' LIMIT 1;
    END IF;

    -- 4. Insert the 6 fields into field_template_fields if missing
    IF gowansh_tmpl_id IS NOT NULL AND to_regclass('public.field_template_fields') IS NOT NULL THEN
        -- Animal Details: Type of Animal
        IF NOT EXISTS (SELECT 1 FROM public.field_template_fields WHERE template_id = gowansh_tmpl_id AND field_key = 'gowansh_animal_type') THEN
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order)
            VALUES (gowansh_tmpl_id, 'Type of Animal', 'gowansh_animal_type', 'custom', 'text', FALSE, 'Animal Details', 10);
        END IF;

        -- Animal Details: Number of Animals
        IF NOT EXISTS (SELECT 1 FROM public.field_template_fields WHERE template_id = gowansh_tmpl_id AND field_key = 'gowansh_animal_count') THEN
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order)
            VALUES (gowansh_tmpl_id, 'Number of Animals', 'gowansh_animal_count', 'custom', 'number', FALSE, 'Animal Details', 20);
        END IF;

        -- Animal Details: Estimated Value
        IF NOT EXISTS (SELECT 1 FROM public.field_template_fields WHERE template_id = gowansh_tmpl_id AND field_key = 'gowansh_est_value') THEN
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order)
            VALUES (gowansh_tmpl_id, 'Estimated Value', 'gowansh_est_value', 'custom', 'number', FALSE, 'Animal Details', 30);
        END IF;

        -- Transport Details: Vehicle Number
        IF NOT EXISTS (SELECT 1 FROM public.field_template_fields WHERE template_id = gowansh_tmpl_id AND field_key = 'gowansh_vehicle_no') THEN
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order)
            VALUES (gowansh_tmpl_id, 'Vehicle Number', 'gowansh_vehicle_no', 'custom', 'text', FALSE, 'Transport Details', 40);
        END IF;

        -- Transport Details: Seizure Location
        IF NOT EXISTS (SELECT 1 FROM public.field_template_fields WHERE template_id = gowansh_tmpl_id AND field_key = 'gowansh_seizure_loc') THEN
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order)
            VALUES (gowansh_tmpl_id, 'Seizure Location', 'gowansh_seizure_loc', 'custom', 'textarea', FALSE, 'Transport Details', 50);
        END IF;

        -- Custody: Goshala / Custody Place
        IF NOT EXISTS (SELECT 1 FROM public.field_template_fields WHERE template_id = gowansh_tmpl_id AND field_key = 'gowansh_custody_place') THEN
            INSERT INTO public.field_template_fields (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order)
            VALUES (gowansh_tmpl_id, 'Goshala / Custody Place', 'gowansh_custody_place', 'custom', 'text', FALSE, 'Custody', 60);
        END IF;
    END IF;

    -- 5. Link the bundle to every category named 'Gowansh' in public.category_field_templates if the link does not exist
    IF gowansh_tmpl_id IS NOT NULL AND to_regclass('public.category_field_templates') IS NOT NULL AND to_regclass('public.case_categories') IS NOT NULL THEN
        FOR cat_rec IN
            SELECT category_id FROM public.case_categories WHERE category_name = 'Gowansh'
        LOOP
            IF NOT EXISTS (SELECT 1 FROM public.category_field_templates WHERE category_id = cat_rec.category_id AND template_id = gowansh_tmpl_id) THEN
                INSERT INTO public.category_field_templates (category_id, template_id)
                VALUES (cat_rec.category_id, gowansh_tmpl_id);
            END IF;
        END LOOP;
    ELSIF gowansh_tmpl_id IS NOT NULL AND to_regclass('category_field_templates') IS NOT NULL AND to_regclass('case_categories') IS NOT NULL THEN
        FOR cat_rec IN
            SELECT category_id FROM case_categories WHERE category_name = 'Gowansh'
        LOOP
            IF NOT EXISTS (SELECT 1 FROM category_field_templates WHERE category_id = cat_rec.category_id AND template_id = gowansh_tmpl_id) THEN
                INSERT INTO category_field_templates (category_id, template_id)
                VALUES (cat_rec.category_id, gowansh_tmpl_id);
            END IF;
        END LOOP;
    END IF;
END
$$;
"""

SQL_REVERSE_GOWANSH = """
DO $$
DECLARE
    sch_rec RECORD;
    gowansh_tmpl_id BIGINT;
BEGIN
    -- 1. Find template
    IF to_regclass('public.field_templates') IS NOT NULL THEN
        SELECT template_id INTO gowansh_tmpl_id FROM public.field_templates WHERE template_name = 'Gowansh Extra Fields' LIMIT 1;
    ELSIF to_regclass('field_templates') IS NOT NULL THEN
        SELECT template_id INTO gowansh_tmpl_id FROM field_templates WHERE template_name = 'Gowansh Extra Fields' LIMIT 1;
    END IF;

    IF gowansh_tmpl_id IS NOT NULL THEN
        -- Remove links
        IF to_regclass('public.category_field_templates') IS NOT NULL THEN
            DELETE FROM public.category_field_templates WHERE template_id = gowansh_tmpl_id;
        ELSIF to_regclass('category_field_templates') IS NOT NULL THEN
            DELETE FROM category_field_templates WHERE template_id = gowansh_tmpl_id;
        END IF;

        -- Remove fields
        IF to_regclass('public.field_template_fields') IS NOT NULL THEN
            DELETE FROM public.field_template_fields WHERE template_id = gowansh_tmpl_id;
        ELSIF to_regclass('field_template_fields') IS NOT NULL THEN
            DELETE FROM field_template_fields WHERE template_id = gowansh_tmpl_id;
        END IF;

        -- Remove template
        IF to_regclass('public.field_templates') IS NOT NULL THEN
            DELETE FROM public.field_templates WHERE template_id = gowansh_tmpl_id;
        ELSIF to_regclass('field_templates') IS NOT NULL THEN
            DELETE FROM field_templates WHERE template_id = gowansh_tmpl_id;
        END IF;
    END IF;

    -- 2. Rename back to Gowans in case_categories
    IF to_regclass('public.case_categories') IS NOT NULL THEN
        UPDATE public.case_categories
        SET category_name = 'Gowans'
        WHERE category_name = 'Gowansh';
    ELSIF to_regclass('case_categories') IS NOT NULL THEN
        UPDATE case_categories
        SET category_name = 'Gowans'
        WHERE category_name = 'Gowansh';
    END IF;

    -- 3. Rename in tenant tables
    IF to_regclass('public.states') IS NOT NULL THEN
        FOR sch_rec IN
            EXECUTE 'SELECT DISTINCT LOWER(TRIM(schema_name)) AS sch FROM public.states WHERE schema_name IS NOT NULL AND TRIM(schema_name) != '''' UNION SELECT ''public'' AS sch'
        LOOP
            IF to_regclass(format('%I.cases_caserecord', sch_rec.sch)) IS NOT NULL THEN
                EXECUTE format('
                    UPDATE %I.cases_caserecord
                    SET sub_category = ''Gowans''
                    WHERE sub_category = ''Gowansh'';
                ', sch_rec.sch);
            END IF;
        END LOOP;
    END IF;
END
$$;
"""


def apply_gowansh_migration(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor == 'postgresql':
        with connection.cursor() as cursor:
            cursor.execute(SQL_APPLY_GOWANSH)
    else:
        # SQLite / in-memory test runner execution
        CaseCategory = apps.get_model('crimetab', 'CaseCategory')
        CaseRecord = apps.get_model('cases', 'CaseRecord')
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

        # 1. Rename categories
        CaseCategory.objects.filter(category_name='Gowans').update(category_name='Gowansh')

        # 2. Rename in CaseRecord
        CaseRecord.objects.filter(sub_category__iexact='gowans').update(sub_category='Gowansh')

        # 3. Create bundle
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name='Gowansh Extra Fields')

        # 4. Insert fields
        fields_data = [
            ('Type of Animal', 'gowansh_animal_type', 'custom', 'text', False, 'Animal Details', 10),
            ('Number of Animals', 'gowansh_animal_count', 'custom', 'number', False, 'Animal Details', 20),
            ('Estimated Value', 'gowansh_est_value', 'custom', 'number', False, 'Animal Details', 30),
            ('Vehicle Number', 'gowansh_vehicle_no', 'custom', 'text', False, 'Transport Details', 40),
            ('Seizure Location', 'gowansh_seizure_loc', 'custom', 'textarea', False, 'Transport Details', 50),
            ('Goshala / Custody Place', 'gowansh_custody_place', 'custom', 'text', False, 'Custody', 60),
        ]
        for label, key, src, ftype, req, section, order in fields_data:
            FieldTemplateField.objects.get_or_create(
                template=tmpl,
                field_key=key,
                defaults={
                    'field_label': label,
                    'field_source': src,
                    'field_type': ftype,
                    'is_required': req,
                    'section': section,
                    'display_order': order,
                }
            )

        # 5. Link bundle to all categories named 'Gowansh'
        for cat in CaseCategory.objects.filter(category_name='Gowansh'):
            CategoryFieldTemplate.objects.get_or_create(
                category=cat,
                template=tmpl
            )


def reverse_gowansh_migration(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor == 'postgresql':
        with connection.cursor() as cursor:
            cursor.execute(SQL_REVERSE_GOWANSH)
    else:
        CaseCategory = apps.get_model('crimetab', 'CaseCategory')
        CaseRecord = apps.get_model('cases', 'CaseRecord')
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

        tmpl = FieldTemplate.objects.filter(template_name='Gowansh Extra Fields').first()
        if tmpl:
            CategoryFieldTemplate.objects.filter(template=tmpl).delete()
            tmpl.fields.all().delete()
            tmpl.delete()

        CaseCategory.objects.filter(category_name='Gowansh').update(category_name='Gowans')
        CaseRecord.objects.filter(sub_category='Gowansh').update(sub_category='Gowans')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0023_remove_murder_extra_fields'),
    ]

    operations = [
        migrations.RunPython(
            apply_gowansh_migration,
            reverse_code=reverse_gowansh_migration,
        ),
    ]
