from django.db import migrations

# Note: This migration is one-way.
# It brings 'Common Form Baseline Template' to its final form by setting sections,
# display orders, renaming 'Physical Description' to 'Description', and inserting missing fields.
# Reverting would discard defined section groupings and cannot restore prior unassigned states.

BASELINE_TEMPLATE_NAME = 'Common Form Baseline Template'

FINAL_BASELINE_FIELDS = [
    # 1. Crime Registration Info
    ('CR Number', 'cr_number', 'common', 'text', True, 'Crime Registration Info', 10),
    ('Registration Date & Time', 'registered_datetime', 'common', 'datetime', True, 'Crime Registration Info', 20),

    # 2. Acts & Sections Filed
    ('Acts & Sections Filed', 'charges', 'common', 'chips', False, 'Acts & Sections Filed', 30),

    # 3. Crime Spot
    ('Village / Town', 'village_town', 'common', 'text', False, 'Crime Spot', 40),
    ('Area Name', 'area_name', 'common', 'text', False, 'Crime Spot', 50),
    ('Crime Spot Full Address', 'full_address', 'common', 'textarea', False, 'Crime Spot', 60),
    ('Occurrence Date & Time', 'occurrence_datetime', 'common', 'datetime', False, 'Crime Spot', 70),

    # 4. Complainant
    ('Complainant Name', 'complainant_name', 'common', 'text', False, 'Complainant', 80),
    ('Complainant Age', 'complainant_age', 'common', 'number', False, 'Complainant', 90),
    ('Complainant Gender', 'complainant_gender', 'common', 'dropdown', False, 'Complainant', 100),
    ('Complainant Occupation', 'complainant_occupation', 'common', 'text', False, 'Complainant', 110),
    ('Complainant Mobile', 'complainant_mobile', 'common', 'text', False, 'Complainant', 120),
    ('Complainant Aadhaar', 'complainant_aadhaar', 'common', 'text', False, 'Complainant', 130),
    ('Complainant PAN', 'complainant_pan', 'common', 'text', False, 'Complainant', 140),
    ('Complainant Religion', 'complainant_religion', 'common', 'text', False, 'Complainant', 150),
    ('Complainant Caste', 'complainant_caste', 'common', 'text', False, 'Complainant', 160),
    ('Complainant Address', 'complainant_address', 'common', 'textarea', False, 'Complainant', 170),

    # 5. Accused
    ('Accused Name', 'accused_name', 'common', 'text', False, 'Accused', 180),
    ('Accused Age', 'accused_age', 'common', 'number', False, 'Accused', 190),
    ('Accused Gender', 'accused_gender', 'common', 'dropdown', False, 'Accused', 200),
    ('Accused Occupation', 'accused_occupation', 'common', 'text', False, 'Accused', 210),
    ('Accused Mobile', 'accused_mobile', 'common', 'text', False, 'Accused', 220),
    ('Accused Aadhaar', 'accused_aadhaar', 'common', 'text', False, 'Accused', 230),
    ('Accused PAN', 'accused_pan', 'common', 'text', False, 'Accused', 240),
    ('Accused Religion', 'accused_religion', 'common', 'text', False, 'Accused', 250),
    ('Accused Caste', 'accused_caste', 'common', 'text', False, 'Accused', 260),
    ('Accused Address', 'accused_address', 'common', 'textarea', False, 'Accused', 270),

    # 6. Suspected Accused
    ('Suspected Accused Name', 'suspected_accused_name', 'common', 'text', False, 'Suspected Accused', 280),
    ('Suspected Accused Age', 'suspected_accused_age', 'common', 'number', False, 'Suspected Accused', 290),
    ('Suspected Accused Gender', 'suspected_accused_gender', 'common', 'dropdown', False, 'Suspected Accused', 300),
    ('Suspected Accused Occupation', 'suspected_accused_occupation', 'common', 'text', False, 'Suspected Accused', 310),
    ('Suspected Accused Mobile', 'suspected_accused_mobile', 'common', 'text', False, 'Suspected Accused', 320),
    ('Suspected Accused Aadhaar', 'suspected_accused_aadhaar', 'common', 'text', False, 'Suspected Accused', 330),
    ('Suspected Accused PAN', 'suspected_accused_pan', 'common', 'text', False, 'Suspected Accused', 340),
    ('Suspected Accused Religion', 'suspected_accused_religion', 'common', 'text', False, 'Suspected Accused', 350),
    ('Suspected Accused Caste', 'suspected_accused_caste', 'common', 'text', False, 'Suspected Accused', 360),
    ('Suspected Accused Address', 'suspected_accused_address', 'common', 'textarea', False, 'Suspected Accused', 370),

    # 7. Unidentified Accused
    ('Approximate Age', 'approximate_age', 'common', 'text', False, 'Unidentified Accused', 380),
    ('Gender', 'unidentified_gender', 'common', 'dropdown', False, 'Unidentified Accused', 390),
    ('Skin Colour', 'skin_colour', 'common', 'text', False, 'Unidentified Accused', 400),
    ('Possible Occupation', 'possible_occupation', 'common', 'text', False, 'Unidentified Accused', 410),
    ('Identification Mark', 'identification_mark', 'common', 'textarea', False, 'Unidentified Accused', 420),
    ('Height', 'height', 'common', 'text', False, 'Unidentified Accused', 430),
    ('Address', 'unidentified_address', 'common', 'textarea', False, 'Unidentified Accused', 440),
    ('Description', 'description', 'common', 'textarea', False, 'Unidentified Accused', 450),

    # 8. Unknown Accused
    ('Unknown Accused Involved', 'is_unknown_accused', 'common', 'checkbox', False, 'Unknown Accused', 460),

    # 9. Officer
    ('IO Name', 'io_name', 'common', 'text', False, 'Officer', 470),
    ('IO Designation', 'io_designation', 'common', 'text', False, 'Officer', 480),
    ('Registered By Name', 'registered_by_name', 'common', 'text', False, 'Officer', 490),
    ('Registered By Designation', 'registered_by_designation', 'common', 'text', False, 'Officer', 500),

    # 10. Arrest
    ('Arrested Person Name', 'arrested_person_name', 'common', 'text', False, 'Arrest', 510),
    ('Arrest Date & Time', 'arrest_datetime', 'common', 'datetime', False, 'Arrest', 520),
    ('Sec 47/48 BNSS Complied', 'sec_47_48_bnss', 'common', 'checkbox', False, 'Arrest', 530),
    ('Relative / Friend Informed', 'relative_friend_name', 'common', 'text', False, 'Arrest', 540),
    ('Relative / Friend Relation', 'relative_friend_relation', 'common', 'text', False, 'Arrest', 550),
    ('Release on Notice', 'release_on_notice', 'common', 'checkbox', False, 'Arrest', 560),
    ('Release on Notice Date & Time', 'release_on_notice_datetime', 'common', 'datetime', False, 'Arrest', 570),
    ('Anticipatory Bail', 'anticipatory_bail', 'common', 'checkbox', False, 'Arrest', 580),
    ('Anticipatory Bail Date & Time', 'anticipatory_bail_datetime', 'common', 'datetime', False, 'Arrest', 590),
    ('Death of Accused', 'death_of_accused', 'common', 'checkbox', False, 'Arrest', 600),
    ('Death of Accused Date & Time', 'death_of_accused_datetime', 'common', 'datetime', False, 'Arrest', 610),

    # 11. Remand & Custody
    ('PCR (Days)', 'pcr_days', 'common', 'number', False, 'Remand & Custody', 620),
    ('MCR', 'mcr', 'common', 'checkbox', False, 'Remand & Custody', 630),
    ('PR Bond', 'pr_bond', 'common', 'checkbox', False, 'Remand & Custody', 640),
    ('PR Bond Date', 'pr_bond_date', 'common', 'date', False, 'Remand & Custody', 650),
    ('Bail', 'bail', 'common', 'checkbox', False, 'Remand & Custody', 660),
    ('Surety Name', 'surety_name', 'common', 'text', False, 'Remand & Custody', 670),
    ('Jail', 'jail', 'common', 'checkbox', False, 'Remand & Custody', 680),
    ('Jail Date', 'jail_date', 'common', 'date', False, 'Remand & Custody', 690),

    # 12. CCTV and CDR Investigation
    ('CCTV Checked', 'cctv_checked', 'common', 'checkbox', False, 'CCTV and CDR Investigation', 700),
    ('CDR Sent Date', 'cdr_sent_date', 'common', 'date', False, 'CCTV and CDR Investigation', 710),
    ('CDR Received Date', 'cdr_received_date', 'common', 'date', False, 'CCTV and CDR Investigation', 720),

    # 13. All Panchnama
    ('Spot Panchanama', 'spot_panchanama', 'common', 'checkbox', False, 'All Panchnama', 730),
    ('Seizure Panchanama', 'seizure_panchanama', 'common', 'checkbox', False, 'All Panchnama', 740),
    ('Search Panchanama', 'search_panchanama', 'common', 'checkbox', False, 'All Panchnama', 750),
    ('Personal Search Panchanama', 'personal_search_panchanama', 'common', 'checkbox', False, 'All Panchnama', 760),
    ('Memorandum Panchanama', 'memorandum_panchanama', 'common', 'checkbox', False, 'All Panchnama', 770),
    ('Identification Panchanama', 'identification_panchanama', 'common', 'checkbox', False, 'All Panchnama', 780),
    ('Identification Parade Panchanama', 'identification_parade_panchanama', 'common', 'checkbox', False, 'All Panchnama', 790),

    # 14. Evidence
    ('E-Shakshya', 'e_shakshya', 'common', 'checkbox', False, 'Evidence', 800),
    ('Fingerprint Taken', 'fingerprint_taken', 'common', 'checkbox', False, 'Evidence', 810),
    ('NAFIS Fingerprint', 'nafis_fingerprint', 'common', 'checkbox', False, 'Evidence', 820),

    # 15. Seizure Records
    ('Object Name', 'object_name', 'common', 'text', False, 'Seizure Records', 830),
    ('Seizure Description', 'seizure_description', 'common', 'textarea', False, 'Seizure Records', 840),
    ('Seizure From Whom', 'seizure_person_name', 'common', 'text', False, 'Seizure Records', 850),

    # 16. Preventive Action
    ('Preventive Action Type', 'preventive_action_type', 'common', 'dropdown', False, 'Preventive Action', 860),
    ('Preventive Action Date', 'preventive_action_date', 'common', 'date', False, 'Preventive Action', 870),
    ('Preventive Action Outward No', 'preventive_outward_no', 'common', 'text', False, 'Preventive Action', 880),
    ('Bond Date', 'bond_date', 'common', 'date', False, 'Preventive Action', 890),
    ('Bond Cancellation Date', 'bond_cancellation_date', 'common', 'date', False, 'Preventive Action', 900),

    # 17. Discharge Accused
    ('Discharged Accused', 'is_discharged', 'common', 'checkbox', False, 'Discharge Accused', 910),
    ('Discharge Date', 'discharge_date', 'common', 'date', False, 'Discharge Accused', 920),

    # 18. Scrutiny
    ('SDPO/ACP Send Date', 'sdpo_acp_send_date', 'common', 'date', False, 'Scrutiny', 930),
    ('SDPO/ACP Grant Date', 'sdpo_acp_grant_date', 'common', 'date', False, 'Scrutiny', 940),
    ('Addl SP/DCP Send Date', 'addl_sp_dcp_send_date', 'common', 'date', False, 'Scrutiny', 950),
    ('Addl SP/DCP Grant Date', 'addl_sp_dcp_grant_date', 'common', 'date', False, 'Scrutiny', 960),
    ('Addl CP Send Date', 'addl_cp_send_date', 'common', 'date', False, 'Scrutiny', 970),
    ('Addl CP Grant Date', 'addl_cp_grant_date', 'common', 'date', False, 'Scrutiny', 980),
    ('APP Send Date', 'app_send_date', 'common', 'date', False, 'Scrutiny', 990),
    ('APP Grant Date', 'app_grant_date', 'common', 'date', False, 'Scrutiny', 1000),

    # 19. Court Filing and Final Summary
    ('Charge Sheet No', 'charge_sheet_no', 'common', 'text', False, 'Court Filing and Final Summary', 1010),
    ('A Final Number', 'a_final_number', 'common', 'text', False, 'Court Filing and Final Summary', 1020),
    ('B Final Number', 'b_final_number', 'common', 'text', False, 'Court Filing and Final Summary', 1030),
    ('C Final Number', 'c_final_number', 'common', 'text', False, 'Court Filing and Final Summary', 1040),
    ('NC Final Number', 'nc_final_number', 'common', 'text', False, 'Court Filing and Final Summary', 1050),
    ('Abeted Summary No', 'abeted_summary_no', 'common', 'text', False, 'Court Filing and Final Summary', 1060),
    ('Stay by High Court Date', 'stay_by_high_court_date', 'common', 'date', False, 'Court Filing and Final Summary', 1070),
    ('Quashed by High Court Date', 'quashed_by_high_court_date', 'common', 'date', False, 'Court Filing and Final Summary', 1080),
    ('CC/ST Number', 'cc_st_number', 'common', 'text', False, 'Court Filing and Final Summary', 1090),
]


GENDER_FIELD_KEYS = {
    'complainant_gender',
    'accused_gender',
    'suspected_accused_gender',
    'unidentified_gender',
}
GENDER_OPTIONS_SOURCE = '/api/options/gender/'


def finalize_baseline_template(apps, schema_editor):
    """
    Idempotently sets sections, missing fields, order, and label updates
    for 'Common Form Baseline Template' matching strictly by template name and field_key.
    Seeds option_values for gender and sets options_source for gender fields.
    Never matches by id. Safe to run multiple times.
    """
    connection = schema_editor.connection
    if connection.vendor == 'postgresql':
        with connection.cursor() as cursor:
            # 1. Seed public.option_values directly with 'gender'
            cursor.execute("""
                INSERT INTO public.option_values (option_group, option_value, display_order, is_active)
                VALUES ('gender', 'Male', 10, TRUE),
                       ('gender', 'Female', 20, TRUE),
                       ('gender', 'Other', 30, TRUE)
                ON CONFLICT (option_group, option_value) DO NOTHING;
            """)

            # 2. Directly update/insert in public.field_templates and public.field_template_fields
            cursor.execute("""
                SELECT template_id 
                FROM public.field_templates 
                WHERE template_name = %s
            """, [BASELINE_TEMPLATE_NAME])
            template_rows = cursor.fetchall()
            for (t_id,) in template_rows:
                for label, key, src, ftype, req, section, order in FINAL_BASELINE_FIELDS:
                    opt_src = GENDER_OPTIONS_SOURCE if key in GENDER_FIELD_KEYS else None
                    cursor.execute("""
                        SELECT field_def_id FROM public.field_template_fields 
                        WHERE template_id = %s AND field_key = %s
                    """, [t_id, key])
                    existing_field = cursor.fetchone()
                    if existing_field:
                        cursor.execute("""
                            UPDATE public.field_template_fields
                            SET field_label = %s,
                                field_source = %s,
                                field_type = %s,
                                is_required = %s,
                                section = %s,
                                display_order = %s,
                                options_source = %s
                            WHERE field_def_id = %s
                        """, [label, src, ftype, req, section, order, opt_src, existing_field[0]])
                    else:
                        cursor.execute("""
                            INSERT INTO public.field_template_fields
                            (template_id, field_label, field_key, field_source, field_type, is_required, section, display_order, options_source)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, [t_id, label, key, src, ftype, req, section, order, opt_src])
    else:
        # Django ORM fallback for SQLite / test environments
        if 'option_values' in connection.introspection.table_names():
            OptionValue = apps.get_model('crimetab', 'OptionValue')
            for val, order in [('Male', 10), ('Female', 20), ('Other', 30)]:
                OptionValue.objects.get_or_create(
                    option_group='gender',
                    option_value=val,
                    defaults={'display_order': order, 'is_active': True}
                )

        FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')

        baseline_templates = FieldTemplate.objects.filter(template_name=BASELINE_TEMPLATE_NAME)
        for tmpl in baseline_templates:
            for label, key, src, ftype, req, section, order in FINAL_BASELINE_FIELDS:
                opt_src = GENDER_OPTIONS_SOURCE if key in GENDER_FIELD_KEYS else None
                field_obj = FieldTemplateField.objects.filter(
                    template=tmpl,
                    field_key=key
                ).first()

                if field_obj:
                    field_obj.field_label = label
                    field_obj.field_source = src
                    field_obj.field_type = ftype
                    field_obj.is_required = req
                    field_obj.section = section
                    field_obj.display_order = order
                    field_obj.options_source = opt_src
                    field_obj.save()
                else:
                    FieldTemplateField.objects.create(
                        template=tmpl,
                        field_label=label,
                        field_key=key,
                        field_source=src,
                        field_type=ftype,
                        is_required=req,
                        section=section,
                        display_order=order,
                        options_source=opt_src,
                    )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0036_make_rti_fields_optional_and_add_empty_message'),
    ]

    operations = [
        migrations.RunPython(
            finalize_baseline_template,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
