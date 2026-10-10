from django.db import migrations

SQL_APPLY_ACCIDENT = """
DO $$
DECLARE
    sch_rec RECORD;
    sch_name TEXT;
    grp_accident_id BIGINT;
    grp_accident_group_id BIGINT;
    grp_road_accident_id BIGINT;
    stand_accident_id BIGINT;
    stand_road_accident_id BIGINT;
    baseline_tmpl_id BIGINT;
    cat_rec RECORD;
    next_cat_id BIGINT;
BEGIN
    -- Gather all candidate schemas (public + tenant state schemas)
    FOR sch_rec IN
        SELECT DISTINCT LOWER(TRIM(schema_name)) AS sch
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'graphql', 'graphql_public', 'vault', 'supabase_functions', 'supabase_migrations', 'extensions', 'cron', 'net', '_analytics', '_realtime')
          AND schema_name NOT LIKE 'pg_temp_%'
          AND schema_name NOT LIKE 'pg_toast_%'
        UNION
        SELECT 'public' AS sch
    LOOP
        sch_name := sch_rec.sch;

        -- Check if case_categories table exists in this schema
        IF to_regclass(format('%I.case_categories', sch_name)) IS NOT NULL THEN
            
            -- Find Group 1 Accident parent category
            EXECUTE format('
                SELECT category_id, group_id
                FROM %I.case_categories
                WHERE category_name = ''Accident'' AND (group_id = 1 OR group_id IS NOT NULL) AND parent_category_id IS NULL
                ORDER BY category_id ASC
                LIMIT 1
            ', sch_name) INTO grp_accident_id, grp_accident_group_id;

            -- Find Standalone Accident parent category
            EXECUTE format('
                SELECT category_id
                FROM %I.case_categories
                WHERE category_name = ''Accident'' AND group_id IS NULL AND parent_category_id IS NULL
                ORDER BY category_id ASC
                LIMIT 1
            ', sch_name) INTO stand_accident_id;

            -- If group_id wasn't found, default to 1
            IF grp_accident_group_id IS NULL THEN
                grp_accident_group_id := 1;
            END IF;

            -- =================================================================
            -- 1. GROUP 1 ACCIDENT SUB-TREE
            -- =================================================================
            IF grp_accident_id IS NOT NULL THEN
                -- (a) Normal Accident under Group 1 Accident
                EXECUTE format('
                    SELECT 1 FROM %I.case_categories
                    WHERE category_name = ''Normal Accident'' AND parent_category_id = $1
                ', sch_name) USING grp_accident_id;
                
                IF NOT FOUND THEN
                    EXECUTE format('
                        SELECT COALESCE(MAX(category_id), 0) + 1 FROM %I.case_categories
                    ', sch_name) INTO next_cat_id;

                    EXECUTE format('
                        INSERT INTO %I.case_categories (category_id, group_id, category_name, category_code, parent_category_id, template_id, display_order, is_active, created_at)
                        VALUES ($1, $2, ''Normal Accident'', ''ACC_NORMAL'', $3, 1, 1, TRUE, CURRENT_TIMESTAMP)
                    ', sch_name) USING next_cat_id, grp_accident_group_id, grp_accident_id;
                END IF;

                -- (b) Road Accident under Group 1 Accident
                EXECUTE format('
                    SELECT 1 FROM %I.case_categories
                    WHERE category_name = ''Road Accident'' AND parent_category_id = $1
                ', sch_name) USING grp_accident_id;

                IF NOT FOUND THEN
                    EXECUTE format('
                        SELECT COALESCE(MAX(category_id), 0) + 1 FROM %I.case_categories
                    ', sch_name) INTO next_cat_id;

                    EXECUTE format('
                        INSERT INTO %I.case_categories (category_id, group_id, category_name, category_code, parent_category_id, template_id, display_order, is_active, created_at)
                        VALUES ($1, $2, ''Road Accident'', ''ACC_ROAD'', $3, 1, 2, TRUE, CURRENT_TIMESTAMP)
                    ', sch_name) USING next_cat_id, grp_accident_group_id, grp_accident_id;
                END IF;

                -- Retrieve Road Accident category_id under Group 1
                EXECUTE format('
                    SELECT category_id FROM %I.case_categories
                    WHERE category_name = ''Road Accident'' AND parent_category_id = $1
                    ORDER BY category_id ASC
                    LIMIT 1
                ', sch_name) USING grp_accident_id INTO grp_road_accident_id;

                IF grp_road_accident_id IS NOT NULL THEN
                    -- (c) Death Due to Rash Driving under Group 1 Road Accident
                    EXECUTE format('
                        SELECT 1 FROM %I.case_categories
                        WHERE category_name = ''Death Due to Rash Driving'' AND parent_category_id = $1
                    ', sch_name) USING grp_road_accident_id;

                    IF NOT FOUND THEN
                        EXECUTE format('
                            SELECT COALESCE(MAX(category_id), 0) + 1 FROM %I.case_categories
                        ', sch_name) INTO next_cat_id;

                        EXECUTE format('
                            INSERT INTO %I.case_categories (category_id, group_id, category_name, category_code, parent_category_id, template_id, display_order, is_active, created_at)
                            VALUES ($1, $2, ''Death Due to Rash Driving'', ''ACC_RASH'', $3, 1, 1, TRUE, CURRENT_TIMESTAMP)
                        ', sch_name) USING next_cat_id, grp_accident_group_id, grp_road_accident_id;
                    END IF;

                    -- (d) Other Road Accident under Group 1 Road Accident
                    EXECUTE format('
                        SELECT 1 FROM %I.case_categories
                        WHERE category_name = ''Other Road Accident'' AND parent_category_id = $1
                    ', sch_name) USING grp_road_accident_id;

                    IF NOT FOUND THEN
                        EXECUTE format('
                            SELECT COALESCE(MAX(category_id), 0) + 1 FROM %I.case_categories
                        ', sch_name) INTO next_cat_id;

                        EXECUTE format('
                            INSERT INTO %I.case_categories (category_id, group_id, category_name, category_code, parent_category_id, template_id, display_order, is_active, created_at)
                            VALUES ($1, $2, ''Other Road Accident'', ''ACC_OTHER'', $3, 1, 2, TRUE, CURRENT_TIMESTAMP)
                        ', sch_name) USING next_cat_id, grp_accident_group_id, grp_road_accident_id;
                    END IF;
                END IF;
            END IF;

            -- =================================================================
            -- 2. STANDALONE ACCIDENT SUB-TREE
            -- =================================================================
            IF stand_accident_id IS NOT NULL THEN
                -- (a) Normal Accident under Standalone Accident
                EXECUTE format('
                    SELECT 1 FROM %I.case_categories
                    WHERE category_name = ''Normal Accident'' AND parent_category_id = $1
                ', sch_name) USING stand_accident_id;

                IF NOT FOUND THEN
                    EXECUTE format('
                        SELECT COALESCE(MAX(category_id), 0) + 1 FROM %I.case_categories
                    ', sch_name) INTO next_cat_id;

                    EXECUTE format('
                        INSERT INTO %I.case_categories (category_id, group_id, category_name, category_code, parent_category_id, template_id, display_order, is_active, created_at)
                        VALUES ($1, NULL, ''Normal Accident'', ''STAND_ACC_NORMAL'', $2, NULL, 1, TRUE, CURRENT_TIMESTAMP)
                    ', sch_name) USING next_cat_id, stand_accident_id;
                END IF;

                -- (b) Road Accident under Standalone Accident
                EXECUTE format('
                    SELECT 1 FROM %I.case_categories
                    WHERE category_name = ''Road Accident'' AND parent_category_id = $1
                ', sch_name) USING stand_accident_id;

                IF NOT FOUND THEN
                    EXECUTE format('
                        SELECT COALESCE(MAX(category_id), 0) + 1 FROM %I.case_categories
                    ', sch_name) INTO next_cat_id;

                    EXECUTE format('
                        INSERT INTO %I.case_categories (category_id, group_id, category_name, category_code, parent_category_id, template_id, display_order, is_active, created_at)
                        VALUES ($1, NULL, ''Road Accident'', ''STAND_ACC_ROAD'', $2, NULL, 2, TRUE, CURRENT_TIMESTAMP)
                    ', sch_name) USING next_cat_id, stand_accident_id;
                END IF;

                -- Retrieve Road Accident category_id under Standalone
                EXECUTE format('
                    SELECT category_id FROM %I.case_categories
                    WHERE category_name = ''Road Accident'' AND parent_category_id = $1
                    ORDER BY category_id ASC
                    LIMIT 1
                ', sch_name) USING stand_accident_id INTO stand_road_accident_id;

                IF stand_road_accident_id IS NOT NULL THEN
                    -- (c) Death Due to Rash Driving under Standalone Road Accident
                    EXECUTE format('
                        SELECT 1 FROM %I.case_categories
                        WHERE category_name = ''Death Due to Rash Driving'' AND parent_category_id = $1
                    ', sch_name) USING stand_road_accident_id;

                    IF NOT FOUND THEN
                        EXECUTE format('
                            SELECT COALESCE(MAX(category_id), 0) + 1 FROM %I.case_categories
                        ', sch_name) INTO next_cat_id;

                        EXECUTE format('
                            INSERT INTO %I.case_categories (category_id, group_id, category_name, category_code, parent_category_id, template_id, display_order, is_active, created_at)
                            VALUES ($1, NULL, ''Death Due to Rash Driving'', ''STAND_ACC_RASH'', $2, NULL, 1, TRUE, CURRENT_TIMESTAMP)
                        ', sch_name) USING next_cat_id, stand_road_accident_id;
                    END IF;

                    -- (d) Other Road Accident under Standalone Road Accident
                    EXECUTE format('
                        SELECT 1 FROM %I.case_categories
                        WHERE category_name = ''Other Road Accident'' AND parent_category_id = $1
                    ', sch_name) USING stand_road_accident_id;

                    IF NOT FOUND THEN
                        EXECUTE format('
                            SELECT COALESCE(MAX(category_id), 0) + 1 FROM %I.case_categories
                        ', sch_name) INTO next_cat_id;

                        EXECUTE format('
                            INSERT INTO %I.case_categories (category_id, group_id, category_name, category_code, parent_category_id, template_id, display_order, is_active, created_at)
                            VALUES ($1, NULL, ''Other Road Accident'', ''STAND_ACC_OTHER'', $2, NULL, 2, TRUE, CURRENT_TIMESTAMP)
                        ', sch_name) USING next_cat_id, stand_road_accident_id;
                    END IF;
                END IF;
            END IF;

            -- Reset sequence if exists
            BEGIN
                EXECUTE format('
                    SELECT setval(pg_get_serial_sequence(''%I.case_categories'', ''category_id''), COALESCE(MAX(category_id), 1))
                    FROM %I.case_categories
                ', sch_name, sch_name);
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;

        END IF;

        -- =====================================================================
        -- 3. LINK "Common Form Baseline Template" IN category_field_templates
        -- =====================================================================
        IF to_regclass(format('%I.category_field_templates', sch_name)) IS NOT NULL AND
           to_regclass(format('%I.case_categories', sch_name)) IS NOT NULL THEN
            
            -- Find Baseline Template ID
            baseline_tmpl_id := NULL;
            IF to_regclass(format('%I.field_templates', sch_name)) IS NOT NULL THEN
                EXECUTE format('
                    SELECT template_id FROM %I.field_templates
                    WHERE template_name = ''Common Form Baseline Template''
                    ORDER BY template_id ASC
                    LIMIT 1
                ', sch_name) INTO baseline_tmpl_id;
            END IF;

            -- Fallback if template in public.field_templates
            IF baseline_tmpl_id IS NULL AND to_regclass('public.field_templates') IS NOT NULL THEN
                SELECT template_id INTO baseline_tmpl_id
                FROM public.field_templates
                WHERE template_name = 'Common Form Baseline Template'
                ORDER BY template_id ASC
                LIMIT 1;
            END IF;

            -- Fallback to template 1 if not found by name
            IF baseline_tmpl_id IS NULL THEN
                baseline_tmpl_id := 1;
            END IF;

            -- 3a. Link to all 19 standalone tabs (group_id IS NULL, parent_category_id IS NULL, NOT IN ('A.D.', 'Suicide', 'N.C.'))
            FOR cat_rec IN
                EXECUTE format('
                    SELECT category_id, category_name
                    FROM %I.case_categories
                    WHERE group_id IS NULL
                      AND parent_category_id IS NULL
                      AND category_name NOT IN (''A.D.'', ''Suicide'', ''N.C.'')
                ', sch_name)
            LOOP
                EXECUTE format('
                    INSERT INTO %I.category_field_templates (category_id, template_id)
                    SELECT $1, $2
                    WHERE NOT EXISTS (
                        SELECT 1 FROM %I.category_field_templates
                        WHERE category_id = $1 AND template_id = $2
                    )
                ', sch_name, sch_name) USING cat_rec.category_id, baseline_tmpl_id;
            END LOOP;

            -- 3b. Link to the 6 Accident sub-tab rows (Normal Accident, Rash Driving, Other Road Accident; Road Accident menu tab has NO Common Form link)
            FOR cat_rec IN
                EXECUTE format('
                    SELECT category_id, category_name
                    FROM %I.case_categories
                    WHERE category_name IN (''Normal Accident'', ''Death Due to Rash Driving'', ''Other Road Accident'')
                ', sch_name)
            LOOP
                EXECUTE format('
                    INSERT INTO %I.category_field_templates (category_id, template_id)
                    SELECT $1, $2
                    WHERE NOT EXISTS (
                        SELECT 1 FROM %I.category_field_templates
                        WHERE category_id = $1 AND template_id = $2
                    )
                ', sch_name, sch_name) USING cat_rec.category_id, baseline_tmpl_id;
            END LOOP;

        END IF;

    END LOOP;
END
$$;
"""

SQL_REVERSE_ACCIDENT = """
DO $$
DECLARE
    sch_rec RECORD;
    sch_name TEXT;
    baseline_tmpl_id BIGINT;
BEGIN
    FOR sch_rec IN
        SELECT DISTINCT LOWER(TRIM(schema_name)) AS sch
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'graphql', 'graphql_public', 'vault', 'supabase_functions', 'supabase_migrations', 'extensions', 'cron', 'net', '_analytics', '_realtime')
          AND schema_name NOT LIKE 'pg_temp_%'
          AND schema_name NOT LIKE 'pg_toast_%'
        UNION
        SELECT 'public' AS sch
    LOOP
        sch_name := sch_rec.sch;

        -- Find Baseline Template ID
        baseline_tmpl_id := NULL;
        IF to_regclass(format('%I.field_templates', sch_name)) IS NOT NULL THEN
            EXECUTE format('
                SELECT template_id FROM %I.field_templates
                WHERE template_name = ''Common Form Baseline Template''
                LIMIT 1
            ', sch_name) INTO baseline_tmpl_id;
        END IF;

        IF baseline_tmpl_id IS NULL AND to_regclass('public.field_templates') IS NOT NULL THEN
            SELECT template_id INTO baseline_tmpl_id
            FROM public.field_templates
            WHERE template_name = 'Common Form Baseline Template'
            LIMIT 1;
        END IF;

        -- Remove links for accident sub-tabs from category_field_templates
        IF to_regclass(format('%I.category_field_templates', sch_name)) IS NOT NULL AND
           to_regclass(format('%I.case_categories', sch_name)) IS NOT NULL THEN
            EXECUTE format('
                DELETE FROM %I.category_field_templates
                WHERE category_id IN (
                    SELECT category_id FROM %I.case_categories
                    WHERE category_name IN (''Normal Accident'', ''Death Due to Rash Driving'', ''Other Road Accident'')
                )
            ', sch_name, sch_name);
        END IF;

        -- Remove accident subcategory rows from case_categories
        IF to_regclass(format('%I.case_categories', sch_name)) IS NOT NULL THEN
            -- Delete Level 2 (Death Due to Rash Driving, Other Road Accident)
            EXECUTE format('
                DELETE FROM %I.case_categories
                WHERE category_name IN (''Death Due to Rash Driving'', ''Other Road Accident'')
                  AND parent_category_id IN (
                      SELECT category_id FROM %I.case_categories WHERE category_name = ''Road Accident''
                  )
            ', sch_name, sch_name);

            -- Delete Level 1 (Normal Accident, Road Accident)
            EXECUTE format('
                DELETE FROM %I.case_categories
                WHERE category_name IN (''Normal Accident'', ''Road Accident'')
                  AND parent_category_id IN (
                      SELECT category_id FROM %I.case_categories WHERE category_name = ''Accident''
                  )
            ', sch_name, sch_name);
        END IF;
    END LOOP;
END
$$;
"""


def apply_accident_subcategories(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor == 'postgresql':
        with connection.cursor() as cursor:
            cursor.execute(SQL_APPLY_ACCIDENT)
    else:
        CaseCategory = apps.get_model('crimetab', 'CaseCategory')
        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

        baseline_tmpl = FieldTemplate.objects.filter(
            template_name='Common Form Baseline Template'
        ).first()

        # 1. Group 1 Accident
        grp_accident = CaseCategory.objects.filter(
            category_name='Accident',
            parent_category__isnull=True
        ).filter(group__isnull=False).first()

        if grp_accident:
            grp = grp_accident.group
            # Normal Accident
            CaseCategory.objects.get_or_create(
                category_name='Normal Accident',
                parent_category=grp_accident,
                defaults={
                    'category_code': 'ACC_NORMAL',
                    'group': grp,
                    'template': baseline_tmpl,
                    'display_order': 1,
                    'is_active': True,
                }
            )
            # Road Accident
            road_acc, _ = CaseCategory.objects.get_or_create(
                category_name='Road Accident',
                parent_category=grp_accident,
                defaults={
                    'category_code': 'ACC_ROAD',
                    'group': grp,
                    'template': baseline_tmpl,
                    'display_order': 2,
                    'is_active': True,
                }
            )
            # Death Due to Rash Driving
            CaseCategory.objects.get_or_create(
                category_name='Death Due to Rash Driving',
                parent_category=road_acc,
                defaults={
                    'category_code': 'ACC_RASH',
                    'group': grp,
                    'template': baseline_tmpl,
                    'display_order': 1,
                    'is_active': True,
                }
            )
            # Other Road Accident
            CaseCategory.objects.get_or_create(
                category_name='Other Road Accident',
                parent_category=road_acc,
                defaults={
                    'category_code': 'ACC_OTHER',
                    'group': grp,
                    'template': baseline_tmpl,
                    'display_order': 2,
                    'is_active': True,
                }
            )

        # 2. Standalone Accident
        stand_accident = CaseCategory.objects.filter(
            category_name='Accident',
            group__isnull=True,
            parent_category__isnull=True
        ).first()

        if stand_accident:
            # Normal Accident
            CaseCategory.objects.get_or_create(
                category_name='Normal Accident',
                parent_category=stand_accident,
                defaults={
                    'category_code': 'STAND_ACC_NORMAL',
                    'group': None,
                    'template': None,
                    'display_order': 1,
                    'is_active': True,
                }
            )
            # Road Accident
            road_acc_s, _ = CaseCategory.objects.get_or_create(
                category_name='Road Accident',
                parent_category=stand_accident,
                defaults={
                    'category_code': 'STAND_ACC_ROAD',
                    'group': None,
                    'template': None,
                    'display_order': 2,
                    'is_active': True,
                }
            )
            # Death Due to Rash Driving
            CaseCategory.objects.get_or_create(
                category_name='Death Due to Rash Driving',
                parent_category=road_acc_s,
                defaults={
                    'category_code': 'STAND_ACC_RASH',
                    'group': None,
                    'template': None,
                    'display_order': 1,
                    'is_active': True,
                }
            )
            # Other Road Accident
            CaseCategory.objects.get_or_create(
                category_name='Other Road Accident',
                parent_category=road_acc_s,
                defaults={
                    'category_code': 'STAND_ACC_OTHER',
                    'group': None,
                    'template': None,
                    'display_order': 2,
                    'is_active': True,
                }
            )

        # 3. Link template to standalone tabs (except A.D., Suicide, N.C.)
        if baseline_tmpl:
            standalone_tabs = CaseCategory.objects.filter(
                group__isnull=True,
                parent_category__isnull=True
            ).exclude(category_name__in=['A.D.', 'Suicide', 'N.C.'])
            for cat in standalone_tabs:
                CategoryFieldTemplate.objects.get_or_create(
                    category=cat,
                    template=baseline_tmpl
                )

            # Link template to the 6 Accident sub-tabs (Road Accident menu tab has NO Common Form link)
            accident_subtabs = CaseCategory.objects.filter(
                category_name__in=[
                    'Normal Accident',
                    'Death Due to Rash Driving',
                    'Other Road Accident'
                ]
            )
            for cat in accident_subtabs:
                CategoryFieldTemplate.objects.get_or_create(
                    category=cat,
                    template=baseline_tmpl
                )


def reverse_accident_subcategories(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor == 'postgresql':
        with connection.cursor() as cursor:
            cursor.execute(SQL_REVERSE_ACCIDENT)
    else:
        CaseCategory = apps.get_model('crimetab', 'CaseCategory')
        CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

        # Remove links from category_field_templates
        accident_subtabs = CaseCategory.objects.filter(
            category_name__in=[
                'Normal Accident',
                'Death Due to Rash Driving',
                'Other Road Accident'
            ]
        )
        CategoryFieldTemplate.objects.filter(category__in=accident_subtabs).delete()

        # Delete subcategories in child-first order
        CaseCategory.objects.filter(
            category_name__in=['Death Due to Rash Driving', 'Other Road Accident'],
            parent_category__category_name='Road Accident'
        ).delete()
        CaseCategory.objects.filter(
            category_name__in=['Normal Accident', 'Road Accident'],
            parent_category__category_name='Accident'
        ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0024_rename_gowans_to_gowansh_and_add_extra_fields'),
    ]

    operations = [
        migrations.RunPython(
            apply_accident_subcategories,
            reverse_code=reverse_accident_subcategories,
        ),
    ]
