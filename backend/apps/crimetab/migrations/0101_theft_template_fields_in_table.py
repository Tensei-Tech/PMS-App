from django.db import migrations, models

"""
Migration 0101: Theft extra fields from the database, values stored in a table

Public schema (form definition):
1. field_templates.store_values_in_table: when true, the values of that
   template's fields are saved as rows in <tenant>.case_extra_field_values
   (not in the case's extra_fields JSON).
2. "Property / Theft Extra Template" gets every Theft question (theft type,
   stolen property list, sections A-I, spot, investigation, recovered
   property) as field_template_fields rows; its dropdown lists go into
   option_values; it is linked to every "Theft" tab in category_field_templates
   and flagged store_values_in_table.

Tenant schemas (actual data):
3. case_extra_field_values gets row_no (repeating-list row / multi-select
   position; 0 for a single value) and the unique key becomes
   (case_id, field_def_id, row_no).

Idempotent: existing rows are kept, missing ones are added.
"""

TEMPLATE_NAME = 'Property / Theft Extra Template'
CATEGORY_NAME = 'Theft'
YES_NO = '/api/options/yes_no/'

OPTION_GROUPS = {
    'theft_types': [
        'Precious Metal / Jewellery', 'Any Metal — Copper, Iron, Scrap', 'Diamond and Precious Stone',
        'Vehicle Theft', 'Cattle / Animal Theft', 'Cash', 'ATM and Banking Related',
        'Mobile and Electronic Instrument', 'Metal Wire / Cable Theft', 'Agricultural Produce Theft',
        'House / Building Materials', 'Factory / Godown Theft', 'Religious / Idol / Antique Theft',
        'Petrol, Diesel / Fuel Theft', 'Document Theft', 'Sand / Mineral Theft', 'Other Theft',
    ],
    'theft_other_metals': ['Copper', 'Iron / Steel', 'Scrap Metal', 'Brass / Bronze', 'Other Metal'],
    'theft_vehicle_sub_types': [
        'Two Wheeler', 'Four Wheeler', 'Three Wheeler', 'Bicycle',
        'Commercial / Heavy Vehicle / Truck / Bus', 'Other Vehicle',
    ],
    'theft_animal_types': ['Cow / Bull / Bullock', 'Buffalo / Goat', 'Sheep / Horse', 'Dog', 'Other'],
    'theft_animal_genders': ['Male', 'Female', 'Both'],
    'theft_electronic_item_types': [
        'Mobile Phone', 'Laptop', 'Tablet', 'TV', 'Monitor', 'Camera', 'Other Electronic',
    ],
    'theft_cable_types': ['Copper', 'Aluminium', 'Electric Cable', 'Telecom / Optical Cable', 'Other'],
    'theft_cable_owner_types': ['Individual', 'MSEB', 'Telecom Company', 'Other'],
    'theft_cable_locations': ['Pole', 'Transformer', 'Line', 'Farm', 'Other'],
    'theft_agri_units': ['Kg', 'Quintal', 'Bags', 'Other'],
    'theft_agri_crop_states': ['Standing Crop', 'Stored Produce'],
    'theft_building_materials': [
        'Cement', 'Steel / Iron Rods', 'Bricks / Sand', 'Pipes / Fittings', 'Wood / Doors / Windows', 'Other',
    ],
    'theft_location_types': [
        'House', 'Shop', 'Office', 'Factory', 'Godown', 'Vehicle', 'Public Place', 'Religious Place', 'Other',
    ],
}


def _opt(group):
    return f'/api/options/{group}/'


# Theft type(s) that open each stolen-property section ('|' = any of them)
SHOW_A = 'Precious Metal / Jewellery|Any Metal — Copper, Iron, Scrap'
SHOW_E = 'Cash|ATM and Banking Related'
SHOW_I = 'House / Building Materials|Factory / Godown Theft'

S_TYPE = 'Theft Type'
S_STOLEN = 'Stolen Property Details'
S_A = 'A. Metal and Precious Metal / Jewellery'
S_B = 'B. Diamond and Precious Stone'
S_C = 'C. Vehicle Theft'
S_D = 'D. Cattle / Animal Theft'
S_E = 'E. Cash Theft'
S_F = 'F. Mobile and Electronic Instrument'
S_G = 'G. Metal Wire / Cable Theft'
S_H = 'H. Agricultural Produce Theft'
S_I = 'I. House / Building Materials'
S_SPOT = 'Theft Spot Details'
S_INV = 'Theft Investigation Details'
S_REC = 'Recovered Property Details'

# (label, key, type, section, depends_on_key, depends_on_value, options_source, parent_key)
FIELDS = [
    ('Theft Type (select all that apply)', 'theft_types', 'multi_select', S_TYPE, None, None, _opt('theft_types'), None),
    ('Specify Other Theft Type (max 25 characters)', 'theft_type_other', 'text', S_TYPE, 'theft_types', 'Other Theft', None, None),

    ('Stolen Property', 'theft_stolen_props', 'repeating_group', S_STOLEN, None, None, None, None),
    ('Name of Stolen Property', 'theft_stolen_name', 'text', S_STOLEN, None, None, None, 'theft_stolen_props'),
    ('Description', 'theft_stolen_description', 'text', S_STOLEN, None, None, None, 'theft_stolen_props'),
    ('Value (₹)', 'theft_stolen_value', 'number', S_STOLEN, None, None, None, 'theft_stolen_props'),

    ('1. Gold', 'theft_gold', 'radio', S_A, 'theft_types', SHOW_A, YES_NO, None),
    ('2. Silver', 'theft_silver', 'radio', S_A, 'theft_types', SHOW_A, YES_NO, None),
    ('3. Platinum', 'theft_platinum', 'radio', S_A, 'theft_types', SHOW_A, YES_NO, None),
    ('Ornaments', 'theft_ornaments', 'repeating_group', S_A, 'theft_types', SHOW_A, None, None),
    ('Name of Ornament', 'theft_ornament_name', 'text', S_A, None, None, None, 'theft_ornaments'),
    ('Metal of Ornament', 'theft_ornament_metal', 'text', S_A, None, None, None, 'theft_ornaments'),
    ('Value of Ornament (₹)', 'theft_ornament_value', 'number', S_A, None, None, None, 'theft_ornaments'),
    ('Other Metals', 'theft_other_metals', 'multi_select', S_A, 'theft_types', SHOW_A, _opt('theft_other_metals'), None),
    ('Other Metal (type name)', 'theft_other_metal_name', 'text', S_A, 'theft_other_metals', 'Other Metal', None, None),

    ('1. Diamond / Precious Stone (type name)', 'theft_diamond_stone_type', 'text', S_B, 'theft_types', 'Diamond and Precious Stone', None, None),
    ('2. Approximate Value (₹)', 'theft_diamond_stone_value', 'number', S_B, 'theft_types', 'Diamond and Precious Stone', None, None),

    ('1. Vehicle Number', 'theft_vehicle_number', 'text', S_C, 'theft_types', 'Vehicle Theft', None, None),
    ('2. Vehicle Sub-Type', 'theft_vehicle_sub_type', 'dropdown', S_C, 'theft_types', 'Vehicle Theft', _opt('theft_vehicle_sub_types'), None),
    ('3. Vehicle Make / Model', 'theft_vehicle_make_model', 'text', S_C, 'theft_types', 'Vehicle Theft', None, None),
    ('4. Registration Number', 'theft_vehicle_reg_number', 'text', S_C, 'theft_types', 'Vehicle Theft', None, None),
    ('5. Chassis Number (optional)', 'theft_vehicle_chassis_number', 'text', S_C, 'theft_types', 'Vehicle Theft', None, None),
    ('6. Engine Number (optional)', 'theft_vehicle_engine_number', 'text', S_C, 'theft_types', 'Vehicle Theft', None, None),
    ('7. Unique Identification Mark', 'theft_vehicle_unique_mark', 'text', S_C, 'theft_types', 'Vehicle Theft', None, None),
    ('8. Photo', 'theft_vehicle_photo', 'radio', S_C, 'theft_types', 'Vehicle Theft', YES_NO, None),
    ('9. Ownership Document', 'theft_vehicle_ownership_doc', 'radio', S_C, 'theft_types', 'Vehicle Theft', YES_NO, None),
    ('10. Purchase Date', 'theft_vehicle_purchase_date', 'date', S_C, 'theft_types', 'Vehicle Theft', None, None),

    ('1. Animal Details', 'theft_animal_details', 'textarea', S_D, 'theft_types', 'Cattle / Animal Theft', None, None),
    ('2. Type of Animal', 'theft_animal_type', 'dropdown', S_D, 'theft_types', 'Cattle / Animal Theft', _opt('theft_animal_types'), None),
    ('Other Animal Type (type name)', 'theft_animal_type_other', 'text', S_D, 'theft_animal_type', 'Other', None, None),
    ('3. Number of Animals', 'theft_animal_count', 'number', S_D, 'theft_types', 'Cattle / Animal Theft', None, None),
    ('4. Total Number of Animals', 'theft_animal_total_count', 'number', S_D, 'theft_types', 'Cattle / Animal Theft', None, None),
    ('5. Breed / Description (if any)', 'theft_animal_breed', 'text', S_D, 'theft_types', 'Cattle / Animal Theft', None, None),
    ('6. Male / Female', 'theft_animal_gender', 'dropdown', S_D, 'theft_types', 'Cattle / Animal Theft', _opt('theft_animal_genders'), None),
    ('7. Approximate Age', 'theft_animal_age', 'text', S_D, 'theft_types', 'Cattle / Animal Theft', None, None),
    ('8. Colour / Identification Marks', 'theft_animal_color_marks', 'text', S_D, 'theft_types', 'Cattle / Animal Theft', None, None),
    ('9. Approximate Weight (if applicable)', 'theft_animal_weight', 'text', S_D, 'theft_types', 'Cattle / Animal Theft', None, None),
    ('10. Total Value of Animals (₹)', 'theft_animal_total_value', 'number', S_D, 'theft_types', 'Cattle / Animal Theft', None, None),
    ('11. Photograph / Video of Animal', 'theft_animal_photo_video', 'radio', S_D, 'theft_types', 'Cattle / Animal Theft', YES_NO, None),
    ('12. Ownership Proof Available', 'theft_animal_ownership_proof', 'radio', S_D, 'theft_types', 'Cattle / Animal Theft', YES_NO, None),
    ('13. Veterinary Certificate Taken', 'theft_animal_vet_certificate', 'radio', S_D, 'theft_types', 'Cattle / Animal Theft', YES_NO, None),

    ('1. Total Rupees or Any Currency (₹)', 'theft_cash_total', 'number', S_E, 'theft_types', SHOW_E, None, None),
    ('2. Count of Notes (not mandatory)', 'theft_cash_note_count', 'text', S_E, 'theft_types', SHOW_E, None, None),

    ('Item Type', 'theft_electronic_item_type', 'dropdown', S_F, 'theft_types', 'Mobile and Electronic Instrument', _opt('theft_electronic_item_types'), None),
    ('Other Electronic (type name)', 'theft_electronic_item_type_other', 'text', S_F, 'theft_electronic_item_type', 'Other Electronic', None, None),
    ('1. Brand / Make', 'theft_electronic_brand', 'text', S_F, 'theft_types', 'Mobile and Electronic Instrument', None, None),
    ('2. Model', 'theft_electronic_model', 'text', S_F, 'theft_types', 'Mobile and Electronic Instrument', None, None),
    ('3. Colour', 'theft_electronic_color', 'text', S_F, 'theft_types', 'Mobile and Electronic Instrument', None, None),
    ('4. IMEI Number 1 (mobile)', 'theft_electronic_imei1', 'text', S_F, 'theft_types', 'Mobile and Electronic Instrument', None, None),
    ('5. IMEI Number 2 (optional)', 'theft_electronic_imei2', 'text', S_F, 'theft_types', 'Mobile and Electronic Instrument', None, None),
    ('6. Serial Number (other devices)', 'theft_electronic_serial_no', 'text', S_F, 'theft_types', 'Mobile and Electronic Instrument', None, None),
    ('7. Mobile Number / SIM Operator (optional)', 'theft_electronic_sim_operator', 'text', S_F, 'theft_types', 'Mobile and Electronic Instrument', None, None),
    ('8. Purchase Bill Available', 'theft_electronic_bill_available', 'radio', S_F, 'theft_types', 'Mobile and Electronic Instrument', YES_NO, None),
    ('9. Approximate Value (₹)', 'theft_electronic_approx_value', 'number', S_F, 'theft_types', 'Mobile and Electronic Instrument', None, None),

    ('Wire / Cable Type', 'theft_cable_type', 'dropdown', S_G, 'theft_types', 'Metal Wire / Cable Theft', _opt('theft_cable_types'), None),
    ('Other Wire / Cable (type name)', 'theft_cable_type_other', 'text', S_G, 'theft_cable_type', 'Other', None, None),
    ('1. Length (Meters)', 'theft_cable_length', 'number', S_G, 'theft_types', 'Metal Wire / Cable Theft', None, None),
    ('2. Approximate Weight (kg) (optional)', 'theft_cable_weight', 'number', S_G, 'theft_types', 'Metal Wire / Cable Theft', None, None),
    ('3. Owner Type', 'theft_cable_owner_type', 'dropdown', S_G, 'theft_types', 'Metal Wire / Cable Theft', _opt('theft_cable_owner_types'), None),
    ('Other Owner Type', 'theft_cable_owner_type_other', 'text', S_G, 'theft_cable_owner_type', 'Other', None, None),
    ('4. Location', 'theft_cable_location', 'dropdown', S_G, 'theft_types', 'Metal Wire / Cable Theft', _opt('theft_cable_locations'), None),
    ('Other Location (type name)', 'theft_cable_location_other', 'text', S_G, 'theft_cable_location', 'Other', None, None),
    ('5. Approximate Value (₹)', 'theft_cable_approx_value', 'number', S_G, 'theft_types', 'Metal Wire / Cable Theft', None, None),

    ('1. Produce / Crop Name', 'theft_agri_crop_name', 'text', S_H, 'theft_types', 'Agricultural Produce Theft', None, None),
    ('2. Quantity', 'theft_agri_quantity', 'number', S_H, 'theft_types', 'Agricultural Produce Theft', None, None),
    ('3. Unit', 'theft_agri_unit', 'dropdown', S_H, 'theft_types', 'Agricultural Produce Theft', _opt('theft_agri_units'), None),
    ('4. Approximate Rate (₹) (optional)', 'theft_agri_rate', 'number', S_H, 'theft_types', 'Agricultural Produce Theft', None, None),
    ('5. Total Value (₹)', 'theft_agri_total_value', 'number', S_H, 'theft_types', 'Agricultural Produce Theft', None, None),
    ('6. Standing Crop / Stored Produce', 'theft_agri_crop_state', 'dropdown', S_H, 'theft_types', 'Agricultural Produce Theft', _opt('theft_agri_crop_states'), None),
    ('7. Farm Equipment', 'theft_agri_farm_equipment', 'radio', S_H, 'theft_types', 'Agricultural Produce Theft', YES_NO, None),

    ('Building Materials', 'theft_building_materials', 'multi_select', S_I, 'theft_types', SHOW_I, _opt('theft_building_materials'), None),
    ('Other Material (type name)', 'theft_building_material_other', 'text', S_I, 'theft_building_materials', 'Other', None, None),
    ('1. Quantity', 'theft_building_quantity', 'number', S_I, 'theft_types', SHOW_I, None, None),
    ('2. Unit', 'theft_building_unit', 'text', S_I, 'theft_types', SHOW_I, None, None),
    ('3. Total Value (₹)', 'theft_building_total_value', 'number', S_I, 'theft_types', SHOW_I, None, None),

    ('1. Exact Place of Theft', 'theft_exact_place', 'textarea', S_SPOT, None, None, None, None),
    ('2. Type of Location', 'theft_location_type', 'dropdown', S_SPOT, None, None, _opt('theft_location_types'), None),
    ('Other Location (max 25 characters)', 'theft_location_type_other', 'text', S_SPOT, 'theft_location_type', 'Other', None, None),
    ('3. Spot Photo Taken', 'theft_spot_photo_taken', 'radio', S_SPOT, None, None, YES_NO, None),
    ('4. Spot Video Taken', 'theft_spot_video_taken', 'radio', S_SPOT, None, None, YES_NO, None),
    ('5. Footprint Found', 'theft_footprint_found', 'radio', S_SPOT, None, None, YES_NO, None),
    ('6. Fingerprint Found', 'theft_fingerprint_found', 'radio', S_SPOT, None, None, YES_NO, None),

    ('1. Witness Examined', 'theft_witness_examined', 'radio', S_INV, None, None, YES_NO, None),
    ('2. Social Media Checked', 'theft_social_media_checked', 'radio', S_INV, None, None, YES_NO, None),
    ('3. Bank Account Checked', 'theft_bank_account_checked', 'radio', S_INV, None, None, YES_NO, None),
    ('4. Toll Plaza Data Checked', 'theft_toll_plaza_checked', 'radio', S_INV, None, None, YES_NO, None),
    ('5. FASTag Data Checked', 'theft_fastag_checked', 'radio', S_INV, None, None, YES_NO, None),
    ('6. ANPR Data Checked', 'theft_anpr_checked', 'radio', S_INV, None, None, YES_NO, None),

    ('1. Recovered Property Name', 'theft_recovered_property_name', 'text', S_REC, None, None, None, None),
    ('2. Recovered Date', 'theft_recovered_date', 'date', S_REC, None, None, None, None),
    ('3. Recovered From', 'theft_recovered_from', 'text', S_REC, None, None, None, None),
    ('4. Return to Owner', 'theft_return_to_owner', 'radio', S_REC, None, None, YES_NO, None),
    ('5. Who Gave It To?', 'theft_who_gave_it', 'text', S_REC, None, None, None, None),
]

FIRST_ORDER = 2000  # after the baseline form's questions


def seed(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    OptionValue = apps.get_model('crimetab', 'OptionValue')

    for group, values in OPTION_GROUPS.items():
        for i, value in enumerate(values, 1):
            OptionValue.objects.get_or_create(
                option_group=group, option_value=value,
                defaults={'display_order': i * 10, 'is_active': True},
            )

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first() \
        or FieldTemplate.objects.create(template_name=TEMPLATE_NAME)
    tmpl.store_values_in_table = True
    tmpl.save(update_fields=['store_values_in_table'])

    for i, (label, key, ftype, section, dep_key, dep_val, opts, parent) in enumerate(FIELDS):
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key=key,
            defaults={
                'field_label': label, 'field_source': 'custom', 'field_type': ftype,
                'is_required': False, 'section': section, 'display_order': FIRST_ORDER + i,
                'depends_on_field_key': dep_key, 'depends_on_value': dep_val,
                'options_source': opts, 'parent_field_key': parent,
            },
        )

    for cat in CaseCategory.objects.filter(category_name__iexact=CATEGORY_NAME):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def unseed(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl:
        CategoryFieldTemplate.objects.filter(template=tmpl).delete()
        FieldTemplateField.objects.filter(template=tmpl, field_key__in=[f[1] for f in FIELDS]).delete()
    OptionValue.objects.filter(option_group__in=list(OPTION_GROUPS)).delete()


def add_row_no(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build the table from the model
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'case_extra_field_values'"
        )
        for (schema,) in cursor.fetchall():
            table = f'"{schema}".case_extra_field_values'
            cursor.execute(f'ALTER TABLE {table} ADD COLUMN IF NOT EXISTS row_no INTEGER NOT NULL DEFAULT 0')
            # Old unique key (case_id, field_def_id) -> (case_id, field_def_id, row_no)
            cursor.execute(
                """SELECT c.conname FROM pg_constraint c
                   JOIN pg_class t ON t.oid = c.conrelid JOIN pg_namespace n ON n.oid = t.relnamespace
                   WHERE n.nspname = %s AND t.relname = 'case_extra_field_values' AND c.contype = 'u'""",
                [schema],
            )
            for (name,) in cursor.fetchall():
                cursor.execute(f'ALTER TABLE {table} DROP CONSTRAINT IF EXISTS "{name}"')
            cursor.execute(
                f'ALTER TABLE {table} ADD CONSTRAINT case_extra_field_values_case_field_row_uniq '
                f'UNIQUE (case_id, field_def_id, row_no)'
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0100_mpda_reminder_schedule_and_remind_io'),
    ]

    operations = [
        migrations.AddField(
            model_name='fieldtemplate',
            name='store_values_in_table',
            field=models.BooleanField(default=False),
        ),
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_row_no, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='caseextrafieldvalue',
                    name='row_no',
                    field=models.IntegerField(default=0),
                ),
                migrations.AlterUniqueTogether(
                    name='caseextrafieldvalue',
                    unique_together={('case', 'field_def', 'row_no')},
                ),
            ],
        ),
        migrations.RunPython(seed, reverse_code=unseed),
    ]
