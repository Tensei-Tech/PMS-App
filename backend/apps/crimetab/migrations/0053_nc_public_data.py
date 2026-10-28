from django.db import migrations, models

"""
Migration 0053: N.C. (Non-Cognizable) module — public data only

Idempotent. Creates, in the public schema only:
  - field template "NC Form" with its own field definitions (keys prefixed nc_);
    crime spot / officer fields copy the Common Form baseline labels and types,
    but the bundle is NOT linked to the Common Form bundle
  - option groups nc_preventive_provisions and nc_yes_no (gender is reused)
  - module_settings rows for module_key 'nc' (labels, limits, messages, rules)
  - permissions nc:create / nc:view / nc:update / nc:pdf
  - the link from the existing tab row 245 (STAND_NC) to the bundle
    (category_field_templates only; the tab row itself is not modified)
  - a new field type 'charges' (state only; field_type has no DB check)

Nothing existing is updated or deleted. Reverse removes only rows created here.
"""

TEMPLATE_NAME = 'NC Form'
TARGET_CATEGORY_CODE = 'STAND_NC'

# (section, field_label, field_key, field_type, display_order, options_source,
#  parent_field_key, depends_on_field_key, depends_on_value)
NC_FIELDS = [
    ('NC No.', 'NC No.', 'nc_no', 'text', 10, None, None, None, None),

    ('Act and Section', 'Act and Section', 'nc_charges', 'charges', 20, None, None, None, None),

    ('Registered Date', 'Registered Date', 'nc_registered_date', 'date', 30, None, None, None, None),

    ('Crime Spot', 'Village / Town', 'nc_spot_village', 'text', 40, None, None, None, None),
    ('Crime Spot', 'Area Name', 'nc_spot_area', 'text', 41, None, None, None, None),
    ('Crime Spot', 'Crime Spot Full Address', 'nc_spot_address', 'textarea', 42, None, None, None, None),
    ('Crime Spot', 'Occurrence Date & Time', 'nc_occurrence_at', 'datetime', 43, None, None, None, None),

    ('Complainant', 'Complainant', 'nc_complainants', 'repeating_group', 50, None, None, None, None),
    ('Complainant', 'Name', 'nc_cmp_name', 'text', 51, None, 'nc_complainants', None, None),
    ('Complainant', 'Age', 'nc_cmp_age', 'number', 52, None, 'nc_complainants', None, None),
    ('Complainant', 'Gender', 'nc_cmp_gender', 'dropdown', 53, '/api/options/gender/', 'nc_complainants', None, None),
    ('Complainant', 'Cast', 'nc_cmp_cast', 'text', 54, None, 'nc_complainants', None, None),
    ('Complainant', 'Profession', 'nc_cmp_profession', 'text', 55, None, 'nc_complainants', None, None),
    ('Complainant', 'Mobile Number', 'nc_cmp_mobile', 'text', 56, None, 'nc_complainants', None, None),
    ('Complainant', 'Address', 'nc_cmp_address', 'textarea', 57, None, 'nc_complainants', None, None),
    ('Complainant', 'Aadhar Card Number', 'nc_cmp_aadhaar', 'text', 58, None, 'nc_complainants', None, None),

    ('Non Applicant', 'Non Applicant', 'nc_non_applicants', 'repeating_group', 60, None, None, None, None),
    ('Non Applicant', 'Name', 'nc_na_name', 'text', 61, None, 'nc_non_applicants', None, None),
    ('Non Applicant', 'Age', 'nc_na_age', 'number', 62, None, 'nc_non_applicants', None, None),
    ('Non Applicant', 'Gender', 'nc_na_gender', 'dropdown', 63, '/api/options/gender/', 'nc_non_applicants', None, None),
    ('Non Applicant', 'Cast', 'nc_na_cast', 'text', 64, None, 'nc_non_applicants', None, None),
    ('Non Applicant', 'Profession', 'nc_na_profession', 'text', 65, None, 'nc_non_applicants', None, None),
    ('Non Applicant', 'Mobile Number', 'nc_na_mobile', 'text', 66, None, 'nc_non_applicants', None, None),
    ('Non Applicant', 'Address', 'nc_na_address', 'textarea', 67, None, 'nc_non_applicants', None, None),
    ('Non Applicant', 'Aadhar Card Number', 'nc_na_aadhaar', 'text', 68, None, 'nc_non_applicants', None, None),

    ('Investigation Officer', 'IO Name', 'nc_io_name', 'text', 70, None, None, None, None),
    ('Investigation Officer', 'IO Designation', 'nc_io_designation', 'text', 71, None, None, None, None),
    ('Investigation Officer', 'Mobile Number', 'nc_io_mobile', 'text', 72, None, None, None, None),

    ('Registered By', 'Registered By Name', 'nc_reg_name', 'text', 80, None, None, None, None),
    ('Registered By', 'Registered By Designation', 'nc_reg_designation', 'text', 81, None, None, None, None),
    ('Registered By', 'Mobile Number', 'nc_reg_mobile', 'text', 82, None, None, None, None),

    ('First Information Content', 'First Information Content', 'nc_first_information', 'textarea', 90, None, None, None, None),

    ('Preventive', 'Preventive', 'nc_preventive_actions', 'repeating_group', 100, None, None, None, None),
    ('Preventive', 'Non Applicant', 'nc_prev_person', 'dropdown', 101, 'rows:nc_non_applicants.nc_na_name', 'nc_preventive_actions', None, None),
    ('Preventive', 'Provision', 'nc_prev_provision', 'dropdown', 102, '/api/options/nc_preventive_provisions/', 'nc_preventive_actions', None, None),
    ('Preventive', 'Date', 'nc_prev_date', 'date', 103, None, 'nc_preventive_actions', None, None),
    ('Preventive', 'Outward Number', 'nc_prev_outward_no', 'text', 104, None, 'nc_preventive_actions', None, None),
    ('Preventive', 'Bond Date', 'nc_prev_bond_date', 'date', 105, None, 'nc_preventive_actions', None, None),
    ('Preventive', 'Bond Cancellation Date', 'nc_prev_bond_cancel_date', 'date', 106, None, 'nc_preventive_actions', None, None),
    ('Preventive', 'Preventive Number / इस्तेगाशा नंबर', 'nc_prev_number', 'text', 107, None, 'nc_preventive_actions', None, None),

    ('Crime Registered After NC', 'Crime Registered After NC', 'nc_post_crime_registered', 'radio', 110, '/api/options/nc_yes_no/', None, None, None),
    ('Crime Registered After NC', 'Crime Number', 'nc_post_crime_no', 'text', 111, None, None, 'nc_post_crime_registered', 'Yes'),
    ('Crime Registered After NC', 'Act', 'nc_post_act', 'text', 112, None, None, 'nc_post_crime_registered', 'Yes'),
    ('Crime Registered After NC', 'Section', 'nc_post_section', 'text', 113, None, None, 'nc_post_crime_registered', 'Yes'),
]

OPTIONS = [
    ('nc_preventive_provisions', [
        '107 CrPC/126 BNSS', '109 CrPC/128 BNSS', '110 CrPC/129 BNSS', '151(3) CrPC/170 BNSS',
        '144 CrPC/163 BNSS', '149 CrPC/168 BNSS', '55 MPA', '56 MPA', '57 MPA', '122 MPA',
        '93 Prohibition Act',
    ]),
    ('nc_yes_no', ['Yes', 'No']),
]

SETTINGS = [
    ('target_category_code', TARGET_CATEGORY_CODE),
    ('template_name', TEMPLATE_NAME),
    ('enforce_permissions', 'false'),
    ('page_size', '20'),
    ('counts_cache_timeout', '45'),
    ('first_information_max_length', '50'),
    ('date_only_provision', '149 CrPC/168 BNSS'),
    ('aadhaar_length', '12'),
    ('aadhaar_visible_digits', '4'),
    ('aadhaar_mask_char', 'X'),
    ('yes_value', 'Yes'),
    ('date_format', '%d/%m/%Y'),
    ('datetime_format', '%d/%m/%Y %H:%M'),
    ('tab_total_label', 'Total cases'),
    ('tab_pending_label', 'Pending'),
    ('tab_disposal_label', 'Disposal'),
    ('add_button_label', 'Add N.C.'),
    ('btn_edit_label', 'Edit'),
    ('btn_view_label', 'View'),
    ('btn_pdf_label', 'PDF'),
    ('search_placeholder', 'Search N.C. by NC No., name or crime spot...'),
    ('empty_list_message', 'No N.C. records found.'),
    ('empty_request_message', 'Cannot save an empty N.C. At least one field must be filled.'),
    ('not_found_message', 'N.C. record not found.'),
    ('missing_state_message', 'State code could not be resolved from authenticated user credentials.'),
    ('no_station_message', 'User does not belong to a valid police station.'),
    ('first_information_too_long_message', 'First Information Content cannot be longer than {limit} characters.'),
    ('invalid_age_message', 'Age must be between 1 and 120.'),
    ('invalid_mobile_message', 'Mobile number must be exactly 10 digits.'),
    ('invalid_aadhaar_message', 'Aadhar card number must be exactly {length} digits.'),
    ('invalid_date_message', 'Invalid date: {value}. Use DD/MM/YYYY.'),
    ('invalid_option_message', 'Invalid value for {field}: {value}.'),
    ('invalid_preventive_person_message', 'A Preventive row can only name a Non Applicant of this N.C.'),
    ('save_success_message', 'N.C. saved successfully.'),
    ('update_success_message', 'N.C. updated successfully.'),
    ('pdf_failed_message', 'Failed to generate PDF. Please try again.'),
    ('pdf_subtitle', 'NON-COGNIZABLE OFFENCE (N.C.) REPORT'),
    ('pdf_filename_prefix', 'NC'),
    ('pdf_department_suffix', 'DEPARTMENT'),
    ('pdf_police_department_suffix', 'POLICE DEPARTMENT'),
    ('pdf_fallback_title', 'POLICE DEPARTMENT'),
    ('pdf_no_rows_message', 'None recorded.'),
]

PERMISSIONS = [
    ('nc:create', 'Create N.C. records'),
    ('nc:view', 'View N.C. records'),
    ('nc:update', 'Update N.C. records'),
    ('nc:pdf', 'Generate N.C. PDF'),
]


def seed_nc_public(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')

    tmpl, _ = FieldTemplate.objects.get_or_create(template_name=TEMPLATE_NAME)

    for (section, label, key, ftype, order, opts, parent, dep_key, dep_val) in NC_FIELDS:
        FieldTemplateField.objects.get_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': section,
                'display_order': order,
                'options_source': opts,
                'parent_field_key': parent,
                'depends_on_field_key': dep_key,
                'depends_on_value': dep_val,
            },
        )

    for group, values in OPTIONS:
        for idx, value in enumerate(values, 1):
            OptionValue.objects.get_or_create(
                option_group=group,
                option_value=value,
                defaults={'display_order': idx * 10, 'is_active': True},
            )

    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(
            module_key='nc', setting_key=key, defaults={'setting_value': value}
        )

    # Existing tab row 245 / STAND_NC: link only, never create or modify it
    cat = CaseCategory.objects.filter(category_code=TARGET_CATEGORY_CODE).first()
    if cat is not None:
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)

    try:
        Permission = apps.get_model('public_master', 'Permission')
    except LookupError:
        Permission = None
    if Permission is not None:
        for pid, desc in PERMISSIONS:
            Permission.objects.get_or_create(id=pid, defaults={'module': 'nc', 'description': desc})


def unseed_nc_public(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')

    # Fields and category links cascade with the template
    FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).delete()
    OptionValue.objects.filter(option_group__in=[g for g, _ in OPTIONS]).delete()
    ModuleSetting.objects.filter(module_key='nc').delete()
    try:
        Permission = apps.get_model('public_master', 'Permission')
        Permission.objects.filter(id__in=[p for p, _ in PERMISSIONS]).delete()
    except LookupError:
        pass


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0052_remove_suicide_category'),
        # Pinned: '__latest__' moved with every new public_master migration and
        # made this already-applied migration depend on an unapplied one
        # (InconsistentMigrationHistory on deploy).
        ('public_master', '0016_dynamicuiconfig'),
    ]

    operations = [
        migrations.AlterField(
            model_name='fieldtemplatefield',
            name='field_type',
            field=models.CharField(
                choices=[
                    ('text', 'Text Field'),
                    ('textarea', 'Multi-line Text Area'),
                    ('number', 'Numeric Field'),
                    ('date', 'Date Picker'),
                    ('datetime', 'Date-Time Picker'),
                    ('dropdown', 'Dropdown Select'),
                    ('checkbox', 'Checkbox Toggle'),
                    ('radio', 'Radio Button Group'),
                    ('chips', 'Chips Selector'),
                    ('file', 'File Upload'),
                    ('multi_select', 'Multi-Select Dropdown'),
                    ('repeating_group', 'Repeating Group'),
                    ('charges', 'Act & Section Picker'),
                ],
                default='text',
                max_length=20,
            ),
        ),
        migrations.RunPython(seed_nc_public, reverse_code=unseed_nc_public),
    ]
