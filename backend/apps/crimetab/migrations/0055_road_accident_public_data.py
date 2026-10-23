from django.db import migrations


SQL_ROAD_ACCIDENT_PUBLIC_UP = """
DO $$
DECLARE
    tmpl_id BIGINT;
    base_tmpl_id BIGINT;
    cat_rec RECORD;
    sch_rec RECORD;
    field_order INT := 100;
BEGIN
    -- 1. Create or retrieve "Road Accident Extra Template" in public.field_templates
    SELECT template_id INTO tmpl_id
    FROM public.field_templates
    WHERE template_name = 'Road Accident Extra Template'
    LIMIT 1;

    IF tmpl_id IS NULL THEN
        INSERT INTO public.field_templates (template_name, created_at)
        VALUES ('Road Accident Extra Template', CURRENT_TIMESTAMP)
        RETURNING template_id INTO tmpl_id;
    END IF;

    -- Also retrieve Common Form Baseline Template
    SELECT template_id INTO base_tmpl_id
    FROM public.field_templates
    WHERE template_name = 'Common Form Baseline Template'
    LIMIT 1;

    -- 2. Populate Option Values for Dropdowns in public.option_values
    -- (a) Nature of accident options
    INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
    VALUES
        ('nature_of_accident', 'Collision', 1, TRUE),
        ('nature_of_accident', 'Pedestrian hit', 2, TRUE),
        ('nature_of_accident', 'Overturning', 3, TRUE),
        ('nature_of_accident', 'Over speed', 4, TRUE),
        ('nature_of_accident', 'Dangerous overtaking', 5, TRUE),
        ('nature_of_accident', 'Wrong side driving', 6, TRUE),
        ('nature_of_accident', 'Fall', 7, TRUE),
        ('nature_of_accident', 'Stationary vehicle', 8, TRUE),
        ('nature_of_accident', 'Other', 9, TRUE)
    ON CONFLICT (option_group, option_value) DO UPDATE
    SET display_order = EXCLUDED.display_order, is_active = TRUE;

    -- (b) Vehicle Company Names
    INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
    VALUES
        ('accident_vehicle_company', 'Maruti Suzuki', 1, TRUE),
        ('accident_vehicle_company', 'Tata Motors', 2, TRUE),
        ('accident_vehicle_company', 'Hyundai', 3, TRUE),
        ('accident_vehicle_company', 'Mahindra', 4, TRUE),
        ('accident_vehicle_company', 'Honda', 5, TRUE),
        ('accident_vehicle_company', 'Toyota', 6, TRUE),
        ('accident_vehicle_company', 'Kia', 7, TRUE),
        ('accident_vehicle_company', 'Bajaj', 8, TRUE),
        ('accident_vehicle_company', 'Hero', 9, TRUE),
        ('accident_vehicle_company', 'TVS', 10, TRUE),
        ('accident_vehicle_company', 'Yamaha', 11, TRUE),
        ('accident_vehicle_company', 'Royal Enfield', 12, TRUE),
        ('accident_vehicle_company', 'Ashok Leyland', 13, TRUE),
        ('accident_vehicle_company', 'Eicher', 14, TRUE),
        ('accident_vehicle_company', 'BharatBenz', 15, TRUE),
        ('accident_vehicle_company', 'Other', 16, TRUE)
    ON CONFLICT (option_group, option_value) DO UPDATE
    SET display_order = EXCLUDED.display_order, is_active = TRUE;

    -- 3. Clear existing fields for this template to ensure clean idempotency
    DELETE FROM public.field_template_fields WHERE template_id = tmpl_id;

    -- 4. Insert Field Template Fields under public.field_template_fields

    -- -------------------------------------------------------------
    -- SECTION 1: Accident Details
    -- -------------------------------------------------------------
    INSERT INTO public.field_template_fields
        (field_label, field_key, field_source, field_type, is_required, section, display_order, template_id, depends_on_field_key, depends_on_value, options_source, parent_field_key)
    VALUES
        ('Nature of Accident', 'acc_nature_of_accident', 'custom', 'dropdown', FALSE, 'Accident Details', 101, tmpl_id, NULL, NULL, '/api/options/nature_of_accident/', NULL),
        ('Nature of Accident (Other Details)', 'acc_nature_of_accident_other', 'custom', 'text', FALSE, 'Accident Details', 102, tmpl_id, 'acc_nature_of_accident', 'Other', NULL, NULL),
        ('Vehicle Abandoned (Y/N)', 'acc_vehicle_abandoned', 'custom', 'dropdown', FALSE, 'Accident Details', 103, tmpl_id, NULL, NULL, '/api/options/yes_no/', NULL),
        ('Driver Subsequently Traced (Y/N)', 'acc_driver_subsequently_traced', 'custom', 'dropdown', FALSE, 'Accident Details', 104, tmpl_id, NULL, NULL, '/api/options/yes_no/', NULL);

    -- -------------------------------------------------------------
    -- SECTION 2: Vehicles Involved (Repeating Group: "Add another all vehicle")
    -- -------------------------------------------------------------
    INSERT INTO public.field_template_fields
        (field_label, field_key, field_source, field_type, is_required, section, display_order, template_id, depends_on_field_key, depends_on_value, options_source, parent_field_key)
    VALUES
        ('Vehicles Involved', 'acc_vehicles', 'custom', 'repeating_group', FALSE, 'Vehicles Involved', 110, tmpl_id, NULL, NULL, NULL, NULL),
        ('Vehicle Number', 'acc_veh_number', 'custom', 'text', FALSE, 'Vehicles Involved', 111, tmpl_id, NULL, NULL, NULL, 'acc_vehicles'),
        ('Vehicle Name', 'acc_veh_name', 'custom', 'text', FALSE, 'Vehicles Involved', 112, tmpl_id, NULL, NULL, NULL, 'acc_vehicles'),
        ('Company Name', 'acc_veh_company', 'custom', 'dropdown', FALSE, 'Vehicles Involved', 113, tmpl_id, NULL, NULL, '/api/options/accident_vehicle_company/', 'acc_vehicles'),
        ('Company Name (Other Details)', 'acc_veh_company_other', 'custom', 'text', FALSE, 'Vehicles Involved', 114, tmpl_id, 'acc_veh_company', 'Other', NULL, 'acc_vehicles'),
        ('Model', 'acc_veh_model', 'custom', 'text', FALSE, 'Vehicles Involved', 115, tmpl_id, NULL, NULL, NULL, 'acc_vehicles'),
        ('Owner Name & Address', 'acc_veh_owner_details', 'custom', 'textarea', FALSE, 'Vehicles Involved', 116, tmpl_id, NULL, NULL, NULL, 'acc_vehicles'),
        ('Driver Name & Address', 'acc_veh_driver_details', 'custom', 'textarea', FALSE, 'Vehicles Involved', 117, tmpl_id, NULL, NULL, NULL, 'acc_vehicles');

    -- -------------------------------------------------------------
    -- SECTION 3: Injured Persons (Repeating Group)
    -- -------------------------------------------------------------
    INSERT INTO public.field_template_fields
        (field_label, field_key, field_source, field_type, is_required, section, display_order, template_id, depends_on_field_key, depends_on_value, options_source, parent_field_key)
    VALUES
        ('Injured Persons', 'acc_injured', 'custom', 'repeating_group', FALSE, 'Injured Persons', 120, tmpl_id, NULL, NULL, NULL, NULL),
        ('Name of Injured', 'acc_inj_name', 'custom', 'text', FALSE, 'Injured Persons', 121, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('Age', 'acc_inj_age', 'custom', 'number', FALSE, 'Injured Persons', 122, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('Gender', 'acc_inj_gender', 'custom', 'dropdown', FALSE, 'Injured Persons', 123, tmpl_id, NULL, NULL, '/api/options/gender/', 'acc_injured'),
        ('Address', 'acc_inj_address', 'custom', 'textarea', FALSE, 'Injured Persons', 124, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('Occupation', 'acc_inj_occupation', 'custom', 'text', FALSE, 'Injured Persons', 125, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('Mobile No.', 'acc_inj_mobile', 'custom', 'text', FALSE, 'Injured Persons', 126, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('Aadhaar Card', 'acc_inj_aadhaar', 'custom', 'text', FALSE, 'Injured Persons', 127, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('PAN Card', 'acc_inj_pan', 'custom', 'text', FALSE, 'Injured Persons', 128, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('Caste', 'acc_inj_caste', 'custom', 'text', FALSE, 'Injured Persons', 129, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('Religion', 'acc_inj_religion', 'custom', 'text', FALSE, 'Injured Persons', 130, tmpl_id, NULL, NULL, NULL, 'acc_injured'),
        ('Death (Y/N)', 'acc_inj_death', 'custom', 'dropdown', FALSE, 'Injured Persons', 131, tmpl_id, NULL, NULL, '/api/options/yes_no/', 'acc_injured'),
        ('Date of Death', 'acc_inj_death_date', 'custom', 'date', FALSE, 'Injured Persons', 132, tmpl_id, 'acc_inj_death', 'Yes', NULL, 'acc_injured');

    -- -------------------------------------------------------------
    -- SECTION 4: Deceased Persons (Repeating Group)
    -- -------------------------------------------------------------
    INSERT INTO public.field_template_fields
        (field_label, field_key, field_source, field_type, is_required, section, display_order, template_id, depends_on_field_key, depends_on_value, options_source, parent_field_key)
    VALUES
        ('Deceased Persons', 'acc_deceased', 'custom', 'repeating_group', FALSE, 'Deceased Persons', 140, tmpl_id, NULL, NULL, NULL, NULL),
        ('Name of Deceased', 'acc_dec_name', 'custom', 'text', FALSE, 'Deceased Persons', 141, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('Age', 'acc_dec_age', 'custom', 'number', FALSE, 'Deceased Persons', 142, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('Gender', 'acc_dec_gender', 'custom', 'dropdown', FALSE, 'Deceased Persons', 143, tmpl_id, NULL, NULL, '/api/options/gender/', 'acc_deceased'),
        ('Address', 'acc_dec_address', 'custom', 'textarea', FALSE, 'Deceased Persons', 144, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('Occupation', 'acc_dec_occupation', 'custom', 'text', FALSE, 'Deceased Persons', 145, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('Mobile No.', 'acc_dec_mobile', 'custom', 'text', FALSE, 'Deceased Persons', 146, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('Aadhaar Card', 'acc_dec_aadhaar', 'custom', 'text', FALSE, 'Deceased Persons', 147, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('PAN Card', 'acc_dec_pan', 'custom', 'text', FALSE, 'Deceased Persons', 148, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('Caste', 'acc_dec_caste', 'custom', 'text', FALSE, 'Deceased Persons', 149, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('Religion', 'acc_dec_religion', 'custom', 'text', FALSE, 'Deceased Persons', 150, tmpl_id, NULL, NULL, NULL, 'acc_deceased'),
        ('Post-Mortem (PM) (Y/N)', 'acc_dec_post_mortem', 'custom', 'dropdown', FALSE, 'Deceased Persons', 151, tmpl_id, NULL, NULL, '/api/options/yes_no/', 'acc_deceased'),
        ('PM Report Received (Y/N)', 'acc_dec_pm_report_received', 'custom', 'dropdown', FALSE, 'Deceased Persons', 152, tmpl_id, 'acc_dec_post_mortem', 'Yes', '/api/options/yes_no/', 'acc_deceased'),
        ('Viscera Sent to FSL (Y/N)', 'acc_dec_viscera_sent_fsl', 'custom', 'dropdown', FALSE, 'Deceased Persons', 153, tmpl_id, 'acc_dec_post_mortem', 'Yes', '/api/options/yes_no/', 'acc_deceased'),
        ('FSL Report Received (Y/N)', 'acc_dec_fsl_report_received', 'custom', 'dropdown', FALSE, 'Deceased Persons', 154, tmpl_id, 'acc_dec_post_mortem', 'Yes', '/api/options/yes_no/', 'acc_deceased');

    -- -------------------------------------------------------------
    -- SECTION 5: Investigation & Compliance
    -- -------------------------------------------------------------
    INSERT INTO public.field_template_fields
        (field_label, field_key, field_source, field_type, is_required, section, display_order, template_id, depends_on_field_key, depends_on_value, options_source, parent_field_key)
    VALUES
        ('Identity of Victim(s) Established (Y/N)', 'acc_victim_identity_established', 'custom', 'dropdown', FALSE, 'Investigation & Compliance', 160, tmpl_id, NULL, NULL, '/api/options/yes_no/', NULL),
        ('Eye Witnesses Identity Established (Y/N)', 'acc_eyewitnesses_identity', 'custom', 'dropdown', FALSE, 'Investigation & Compliance', 161, tmpl_id, NULL, NULL, '/api/options/yes_no/', NULL),
        ('IRAD (Integrated Road Accident Database) (Y/N)', 'acc_irad', 'custom', 'dropdown', FALSE, 'Investigation & Compliance', 162, tmpl_id, NULL, NULL, '/api/options/yes_no/', NULL),
        ('IRAD Date', 'acc_irad_date', 'custom', 'date', FALSE, 'Investigation & Compliance', 163, tmpl_id, 'acc_irad', 'Yes', NULL, NULL),
        ('DAR (Detailed Accident Report) (Y/N)', 'acc_dar', 'custom', 'dropdown', FALSE, 'Investigation & Compliance', 164, tmpl_id, NULL, NULL, '/api/options/yes_no/', NULL),
        ('DAR Date', 'acc_dar_date', 'custom', 'date', FALSE, 'Investigation & Compliance', 165, tmpl_id, 'acc_dar', 'Yes', NULL, NULL);

    -- 5. Link "Road Accident Extra Template" in public.category_field_templates
    -- To all Road Accident categories:
    --   - ACC_ROAD, STAND_ACC_ROAD (Road Accident)
    --   - ACC_RASH, STAND_ACC_RASH (Death Due to Rash Driving)
    --   - ACC_OTHER, STAND_ACC_OTHER (Other Road Accident / Normal Road)
    FOR cat_rec IN
        SELECT category_id, category_code, category_name
        FROM public.case_categories
        WHERE category_code IN ('ACC_ROAD', 'ACC_RASH', 'ACC_OTHER', 'STAND_ACC_ROAD', 'STAND_ACC_RASH', 'STAND_ACC_OTHER')
           OR category_name IN ('Road Accident', 'Death Due to Rash Driving', 'Other Road Accident')
    LOOP
        -- (a) Ensure Common Form Baseline Template is linked
        IF base_tmpl_id IS NOT NULL THEN
            INSERT INTO public.category_field_templates (category_id, template_id)
            VALUES (cat_rec.category_id, base_tmpl_id)
            ON CONFLICT (category_id, template_id) DO NOTHING;
        END IF;

        -- (b) Link Road Accident Extra Template
        INSERT INTO public.category_field_templates (category_id, template_id)
        VALUES (cat_rec.category_id, tmpl_id)
        ON CONFLICT (category_id, template_id) DO NOTHING;
    END LOOP;

    -- 6. Also sync links in tenant schemas (e.g. maharashtra) if category_field_templates exists there
    FOR sch_rec IN
        SELECT DISTINCT table_schema AS sch
        FROM information_schema.tables
        WHERE table_name = 'category_field_templates'
          AND table_schema NOT IN ('public', 'information_schema', 'pg_catalog')
    LOOP
        FOR cat_rec IN
            EXECUTE format('
                SELECT category_id, category_code, category_name
                FROM %I.case_categories
                WHERE category_code IN (''ACC_ROAD'', ''ACC_RASH'', ''ACC_OTHER'', ''STAND_ACC_ROAD'', ''STAND_ACC_RASH'', ''STAND_ACC_OTHER'')
                   OR category_name IN (''Road Accident'', ''Death Due to Rash Driving'', ''Other Road Accident'')
            ', sch_rec.sch)
        LOOP
            IF base_tmpl_id IS NOT NULL THEN
                EXECUTE format('
                    INSERT INTO %I.category_field_templates (category_id, template_id)
                    VALUES ($1, $2)
                    ON CONFLICT (category_id, template_id) DO NOTHING
                ', sch_rec.sch) USING cat_rec.category_id, base_tmpl_id;
            END IF;

            EXECUTE format('
                INSERT INTO %I.category_field_templates (category_id, template_id)
                VALUES ($1, $2)
                ON CONFLICT (category_id, template_id) DO NOTHING
            ', sch_rec.sch) USING cat_rec.category_id, tmpl_id;
        END LOOP;
    END LOOP;

END $$;
"""


SQL_ROAD_ACCIDENT_PUBLIC_DOWN = """
DO $$
DECLARE
    tmpl_id BIGINT;
BEGIN
    SELECT template_id INTO tmpl_id
    FROM public.field_templates
    WHERE template_name = 'Road Accident Extra Template'
    LIMIT 1;

    IF tmpl_id IS NOT NULL THEN
        DELETE FROM public.category_field_templates WHERE template_id = tmpl_id;
        DELETE FROM public.field_template_fields WHERE template_id = tmpl_id;
        DELETE FROM public.field_templates WHERE template_id = tmpl_id;
    END IF;
END $$;
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0054_nc_tenant_tables'),
    ]

    operations = [
        migrations.RunSQL(
            sql=SQL_ROAD_ACCIDENT_PUBLIC_UP,
            reverse_sql=SQL_ROAD_ACCIDENT_PUBLIC_DOWN,
        ),
    ]
