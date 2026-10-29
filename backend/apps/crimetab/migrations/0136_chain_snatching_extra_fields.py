from django.db import migrations
from django.db.models import Q

"""
Migration 0136: Chain Snatching Extra Fields with Stolen Property List, Recovered Details,
Precious Metals, Other Metals, Diamonds, and Theft-like sections (Cash, Mobile, Vehicle, Spot, Investigation).

Template: "Chain Snatching Extra Fields" (store_values_in_table = True)
Linked to: Chain Snatching category (code 118, name 'Chain Snatching')

Sections:
1. Theft / Snatching Type (multi-select: Precious Metal, Other Metal, Diamond, Vehicle, Cash, Mobile, etc.)
2. A. Precious Metal / Jewellery (Gold, Silver, Platinum Y/N, Other Precious Metal name, Ornaments list, Total Value)
3. B. Other Metal (Other Metals list: Metal Type dropdown [Copper, Iron/Steel, Scrap, Brass/Bronze, Other], Name, Value, Total Value)
4. C. Diamond and Precious Stone (Diamond list: Type name, Approximate Value, Details, Total Value)
5. 4. Stolen Property List (table: Name, Description, Value, Total Value auto-summed)
6. 1. Recovered Property Details (list: Recovered Property Name from Stolen Property List rows, Date, From, Return to Owner Y/N, Who Gave It To)
7. E. Cash Snatching (Total Cash, Count of Notes)
8. F. Mobile and Electronic Instrument (Item Type, Brand, Model, Colour, IMEI 1 & 2, Serial No, SIM, Bill, Value)
9. C. Vehicle Details (Vehicle Number, Sub-type, Make/Model, Reg number, Chassis, Engine, Mark, Photo, Doc, Date)
10. Snatching Spot Details (Exact place, Location type, Photo, Video, Footprint, Fingerprint)
11. Snatching Investigation Details (Witness, Social Media, Bank, Toll Plaza, FASTag, ANPR)

Also updates Property / Theft Extra Template:
- theft_recovered_property_name options_source set to rows:theft_stolen_props.theft_stolen_name
- theft_stolen_total_value field added with sum:theft_stolen_props.theft_stolen_value
- theft_other_precious_metal field added

Idempotent.
"""

TEMPLATE_NAME = 'Chain Snatching Extra Fields'
CATEGORY_NAME = 'Chain Snatching'
CATEGORY_CODE = '118'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'

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
    'theft_electronic_item_types': [
        'Mobile Phone', 'Laptop', 'Tablet', 'TV', 'Monitor', 'Camera', 'Other Electronic',
    ],
    'theft_location_types': [
        'House', 'Shop', 'Office', 'Factory', 'Godown', 'Vehicle', 'Public Place', 'Religious Place', 'Other',
    ],
}


def _opt(group):
    return f'/api/options/{group}/'


SHOW_A = 'Precious Metal / Jewellery'
SHOW_B = 'Any Metal — Copper, Iron, Scrap'
SHOW_C = 'Diamond and Precious Stone'
SHOW_CASH = 'Cash|ATM and Banking Related'
SHOW_ELEC = 'Mobile and Electronic Instrument'
SHOW_VEH = 'Vehicle Theft'

S_TYPE = 'Theft / Snatching Type'
S_A = 'A. Precious Metal / Jewellery'
S_B = 'B. Other Metal'
S_C = 'C. Diamond and Precious Stone'
S_STOLEN = '4. Stolen Property List'
S_REC = '1. Recovered Property Details'
S_CASH = 'E. Cash Snatching'
S_ELEC = 'F. Mobile and Electronic Instrument'
S_VEH = 'C. Vehicle Details'
S_SPOT = 'Snatching Spot Details'
S_INV = 'Snatching Investigation Details'

# (label, key, type, section, depends_on_key, depends_on_value, options_source, parent_key)
FIELDS = [
    ('Theft / Snatching Type (select all that apply)', 'snatch_types', 'multi_select', S_TYPE, None, None, _opt('theft_types'), None),
    ('Specify Other Snatching Type (max 25 characters)', 'snatch_type_other', 'text', S_TYPE, 'snatch_types', 'Other Theft', None, None),

    ('1. Gold', 'snatch_gold', 'radio', S_A, 'snatch_types', SHOW_A, YES_NO, None),
    ('2. Silver', 'snatch_silver', 'radio', S_A, 'snatch_types', SHOW_A, YES_NO, None),
    ('3. Platinum', 'snatch_platinum', 'radio', S_A, 'snatch_types', SHOW_A, YES_NO, None),
    ('4. Other Precious Metal Name (Type)', 'snatch_other_precious_metal', 'text', S_A, 'snatch_types', SHOW_A, None, None),
    ('Ornaments', 'snatch_ornaments', 'repeating_group', S_A, 'snatch_types', SHOW_A, None, None),
    ('1. Name of Ornament', 'snatch_ornament_name', 'text', S_A, None, None, None, 'snatch_ornaments'),
    ('2. Metal of Ornament', 'snatch_ornament_metal', 'text', S_A, None, None, None, 'snatch_ornaments'),
    ('3. Value of Ornament (₹)', 'snatch_ornament_value', 'number', S_A, None, None, None, 'snatch_ornaments'),
    ('Total Value of Ornaments (₹)', 'snatch_ornaments_total_value', 'number', S_A, 'snatch_types', SHOW_A, 'sum:snatch_ornaments.snatch_ornament_value', None),

    ('Other Metals', 'snatch_other_metals', 'repeating_group', S_B, 'snatch_types', SHOW_B, None, None),
    ('Metal Type', 'snatch_metal_type', 'dropdown', S_B, None, None, _opt('theft_other_metals'), 'snatch_other_metals'),
    ('Other Metal (type name)', 'snatch_metal_other_name', 'text', S_B, 'snatch_metal_type', 'Other Metal', None, 'snatch_other_metals'),
    ('Value (₹)', 'snatch_metal_value', 'number', S_B, None, None, None, 'snatch_other_metals'),
    ('1. Total Value (₹)', 'snatch_other_metals_total_value', 'number', S_B, 'snatch_types', SHOW_B, 'sum:snatch_other_metals.snatch_metal_value', None),

    ('Diamond / Precious Stone', 'snatch_diamond_stones', 'repeating_group', S_C, 'snatch_types', SHOW_C, None, None),
    ('1. Diamond / Precious Stone (type name)', 'snatch_diamond_stone_type', 'text', S_C, None, None, None, 'snatch_diamond_stones'),
    ('2. Approximate Value (₹)', 'snatch_diamond_stone_value', 'number', S_C, None, None, None, 'snatch_diamond_stones'),
    ('3. Description / Details (optional)', 'snatch_diamond_stone_desc', 'text', S_C, None, None, None, 'snatch_diamond_stones'),
    ('Total Value of Diamond / Precious Stone (₹)', 'snatch_diamond_total_value', 'number', S_C, 'snatch_types', SHOW_C, 'sum:snatch_diamond_stones.snatch_diamond_stone_value', None),

    ('Stolen Property List', 'snatch_stolen_props', 'repeating_group', S_STOLEN, None, None, None, None),
    ('1. Name', 'snatch_stolen_name', 'text', S_STOLEN, None, None, None, 'snatch_stolen_props'),
    ('2. Description', 'snatch_stolen_description', 'text', S_STOLEN, None, None, None, 'snatch_stolen_props'),
    ('3. Value (₹)', 'snatch_stolen_value', 'number', S_STOLEN, None, None, None, 'snatch_stolen_props'),
    ('4. Total Value (₹)', 'snatch_stolen_total_value', 'number', S_STOLEN, None, None, 'sum:snatch_stolen_props.snatch_stolen_value', None),

    ('Recovered Property Details', 'snatch_recovered_props', 'repeating_group', S_REC, None, None, None, None),
    ('1. Recovered Property Name', 'snatch_recovered_name', 'dropdown', S_REC, None, None, 'rows:snatch_stolen_props.snatch_stolen_name', 'snatch_recovered_props'),
    ('2. Recovered Date', 'snatch_recovered_date', 'date', S_REC, None, None, None, 'snatch_recovered_props'),
    ('3. Recovered From', 'snatch_recovered_from', 'text', S_REC, None, None, None, 'snatch_recovered_props'),
    ('4. Return to Owner', 'snatch_recovered_return_to_owner', 'radio', S_REC, None, None, YES_NO, 'snatch_recovered_props'),
    ('5. Who Gave It To?', 'snatch_recovered_who_gave_it', 'text', S_REC, None, None, None, 'snatch_recovered_props'),

    ('1. Total Rupees or Any Currency (₹)', 'snatch_cash_total', 'number', S_CASH, 'snatch_types', SHOW_CASH, None, None),
    ('2. Count of Notes (not mandatory)', 'snatch_cash_note_count', 'text', S_CASH, 'snatch_types', SHOW_CASH, None, None),

    ('Item Type', 'snatch_electronic_item_type', 'dropdown', S_ELEC, 'snatch_types', SHOW_ELEC, _opt('theft_electronic_item_types'), None),
    ('Other Electronic (type name)', 'snatch_electronic_item_type_other', 'text', S_ELEC, 'snatch_electronic_item_type', 'Other Electronic', None, None),
    ('1. Brand / Make', 'snatch_electronic_brand', 'text', S_ELEC, 'snatch_types', SHOW_ELEC, None, None),
    ('2. Model', 'snatch_electronic_model', 'text', S_ELEC, 'snatch_types', SHOW_ELEC, None, None),
    ('3. Colour', 'snatch_electronic_color', 'text', S_ELEC, 'snatch_types', SHOW_ELEC, None, None),
    ('4. IMEI Number 1 (mobile)', 'snatch_electronic_imei1', 'text', S_ELEC, 'snatch_types', SHOW_ELEC, None, None),
    ('5. IMEI Number 2 (optional)', 'snatch_electronic_imei2', 'text', S_ELEC, 'snatch_types', SHOW_ELEC, None, None),
    ('6. Serial Number (other devices)', 'snatch_electronic_serial_no', 'text', S_ELEC, 'snatch_types', SHOW_ELEC, None, None),
    ('7. Mobile Number / SIM Operator (optional)', 'snatch_electronic_sim_operator', 'text', S_ELEC, 'snatch_types', SHOW_ELEC, None, None),
    ('8. Purchase Bill Available', 'snatch_electronic_bill_available', 'radio', S_ELEC, 'snatch_types', SHOW_ELEC, YES_NO, None),
    ('9. Approximate Value (₹)', 'snatch_electronic_approx_value', 'number', S_ELEC, 'snatch_types', SHOW_ELEC, None, None),

    ('1. Vehicle Number', 'snatch_vehicle_number', 'text', S_VEH, 'snatch_types', SHOW_VEH, None, None),
    ('2. Vehicle Sub-Type', 'snatch_vehicle_sub_type', 'dropdown', S_VEH, 'snatch_types', SHOW_VEH, _opt('theft_vehicle_sub_types'), None),
    ('3. Vehicle Make / Model', 'snatch_vehicle_make_model', 'text', S_VEH, 'snatch_types', SHOW_VEH, None, None),
    ('4. Registration Number', 'snatch_vehicle_reg_number', 'text', S_VEH, 'snatch_types', SHOW_VEH, None, None),
    ('5. Chassis Number (optional)', 'snatch_vehicle_chassis_number', 'text', S_VEH, 'snatch_types', SHOW_VEH, None, None),
    ('6. Engine Number (optional)', 'snatch_vehicle_engine_number', 'text', S_VEH, 'snatch_types', SHOW_VEH, None, None),
    ('7. Unique Identification Mark', 'snatch_vehicle_unique_mark', 'text', S_VEH, 'snatch_types', SHOW_VEH, None, None),
    ('8. Photo', 'snatch_vehicle_photo', 'radio', S_VEH, 'snatch_types', SHOW_VEH, YES_NO, None),
    ('9. Ownership Document', 'snatch_vehicle_ownership_doc', 'radio', S_VEH, 'snatch_types', SHOW_VEH, YES_NO, None),
    ('10. Purchase Date', 'snatch_vehicle_purchase_date', 'date', S_VEH, 'snatch_types', SHOW_VEH, None, None),

    ('1. Exact Place of Snatching', 'snatch_exact_place', 'textarea', S_SPOT, None, None, None, None),
    ('2. Type of Location', 'snatch_location_type', 'dropdown', S_SPOT, None, None, _opt('theft_location_types'), None),
    ('Other Location (max 25 characters)', 'snatch_location_type_other', 'text', S_SPOT, 'snatch_location_type', 'Other', None, None),
    ('3. Spot Photo Taken', 'snatch_spot_photo_taken', 'radio', S_SPOT, None, None, YES_NO, None),
    ('4. Spot Video Taken', 'snatch_spot_video_taken', 'radio', S_SPOT, None, None, YES_NO, None),
    ('5. Footprint Found', 'snatch_footprint_found', 'radio', S_SPOT, None, None, YES_NO, None),
    ('6. Fingerprint Found', 'snatch_fingerprint_found', 'radio', S_SPOT, None, None, YES_NO, None),

    ('1. Witness Examined', 'snatch_witness_examined', 'radio', S_INV, None, None, YES_NO, None),
    ('2. Social Media Checked', 'snatch_social_media_checked', 'radio', S_INV, None, None, YES_NO, None),
    ('3. Bank Account Checked', 'snatch_bank_account_checked', 'radio', S_INV, None, None, YES_NO, None),
    ('4. Toll Plaza Data Checked', 'snatch_toll_plaza_checked', 'radio', S_INV, None, None, YES_NO, None),
    ('5. FASTag Data Checked', 'snatch_fastag_checked', 'radio', S_INV, None, None, YES_NO, None),
    ('6. ANPR Data Checked', 'snatch_anpr_checked', 'radio', S_INV, None, None, YES_NO, None),
]

FIRST_ORDER = 2000


def seed_snatching(apps, schema_editor):
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

    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME,
        defaults={'store_values_in_table': True},
    )

    for i, (label, key, ftype, section, dep_key, dep_val, opts, parent) in enumerate(FIELDS):
        FieldTemplateField.objects.update_or_create(
            template=tmpl, field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': section,
                'display_order': FIRST_ORDER + i,
                'depends_on_field_key': dep_key,
                'depends_on_value': dep_val,
                'options_source': opts,
                'parent_field_key': parent,
            },
        )

    # Link to Chain Snatching categories (code 118 or name contains 'Chain Snatching')
    cats = list(CaseCategory.objects.filter(
        Q(category_code=CATEGORY_CODE) | Q(category_name__iexact=CATEGORY_NAME)
    ))
    for cat in cats:
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)

    # Also update Property / Theft Extra Template fields to support rows: source and auto-sum
    theft_tmpl = FieldTemplate.objects.filter(template_name='Property / Theft Extra Template').first()
    if theft_tmpl:
        # Recovered Property Name as dropdown selecting from stolen list
        FieldTemplateField.objects.filter(
            template=theft_tmpl, field_key='theft_recovered_property_name'
        ).update(
            field_type='dropdown',
            options_source='rows:theft_stolen_props.theft_stolen_name',
        )
        # Total Value of Stolen Property
        FieldTemplateField.objects.get_or_create(
            template=theft_tmpl, field_key='theft_stolen_total_value',
            defaults={
                'field_label': 'Total Value (₹)',
                'field_source': 'custom',
                'field_type': 'number',
                'is_required': False,
                'section': 'Stolen Property Details',
                'display_order': 2005,
                'options_source': 'sum:theft_stolen_props.theft_stolen_value',
            },
        )
        # Other precious metal name
        FieldTemplateField.objects.get_or_create(
            template=theft_tmpl, field_key='theft_other_precious_metal',
            defaults={
                'field_label': 'Other Precious Metal Name (Type)',
                'field_source': 'custom',
                'field_type': 'text',
                'is_required': False,
                'section': 'A. Metal and Precious Metal / Jewellery',
                'display_order': 2008,
                'depends_on_field_key': 'theft_types',
                'depends_on_value': 'Precious Metal / Jewellery|Any Metal — Copper, Iron, Scrap',
            },
        )


def unseed_snatching(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl:
        CategoryFieldTemplate.objects.filter(template=tmpl).delete()
        FieldTemplateField.objects.filter(template=tmpl).delete()
        tmpl.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0135_transgender_and_three_digit_ages'),
    ]

    operations = [
        migrations.RunPython(seed_snatching, reverse_code=unseed_snatching),
    ]
