from django.db import migrations
from django.db.models import Q

"""
Migration 0143: "Robbery / Dacoity Extra Fields" for Robbery and Dacoity (data only)

Template: "Robbery / Dacoity Extra Fields" (store_values_in_table = True)
Linked to: Robbery (code 104) and Dacoity (code 103)

Sections:
1. Stolen Property List (repeating: Name of Property *, Description / Markings, Estimated Value)
2. Type of Property Stolen (checkboxes; "Other" asks for the type)
3. Jewellery & Precious Metal Details (shown for Precious Metal / Jewellery, Any Metal,
   Diamond and Precious Stone): Gold / Silver / Platinum Yes/No, Other Metal Name,
   Ornaments (Name *, Metal * dropdown, Value *), Total Value (auto-sum)
4. Vehicle Details (shown for Vehicle): Type of Vehicle, Engine *, Chassis *,
   Registration *, Unique Mark, Photo Yes/No, Ownership Document Yes/No
5. Cash Details (shown for Cash): Total Rupees or Any Currency *, Count of Notes
6. Recovered Property List (repeating: Name of Property *, Description / Markings, Estimated Value)
7. Injured Person Details (repeating): Name, Age, Gender, Mobile, Aadhaar, PAN,
   Person Died? -> Date & Time of Death, Inquest Panchanama -> Date & Time,
   Exhumation Panchanama -> Date & Time
8. Deceased Person Details (repeating): Name, Age, Gender, Occupation, Mobile, Aadhaar,
   PAN, Religion, Caste, Address, Postmortem -> Date, Time, Report Sent -> Date, Time,
   Viscera Sent to FSL -> Date, Time, FSL Report -> Date, Time

Option names carry no commas: a condition on a checkbox list can split a stored
value at commas, so "Precious Metal, Jewellery" would never match.

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Robbery / Dacoity Extra Fields'
CATEGORY_NAMES = ('Robbery', 'Dacoity')
CATEGORY_CODES = ('104', '103')
YES_NO = '/api/options/yes_no/'
GENDER = '/api/options/gender/'
YES = 'Yes'

OPTION_GROUPS = {
    'robbery_property_types': [
        'Precious Metal / Jewellery', 'Any Metal (Copper / Iron / Scrap)', 'Diamond and Precious Stone',
        'Vehicle', 'Cattle / Animal', 'Cash', 'ATM and Banking Related',
        'Mobile and Electronic Instrument', 'Metal Wire / Cable', 'Agricultural Produce',
        'House / Building Materials', 'Factory / Godown', 'Religious / Antique Property', 'Other',
    ],
    'robbery_ornament_metals': [
        'Gold', 'Silver', 'Platinum', 'Diamond / Precious Stone', 'Copper', 'Iron / Steel',
        'Scrap Metal', 'Brass / Bronze', 'Other',
    ],
    'robbery_vehicle_types': [
        'Two Wheeler (Motorcycle / Scooter / Moped)', 'Four Wheeler (Car / Jeep / SUV / Taxi)',
        'Three Wheeler (Auto Rickshaw / E-Rickshaw)', 'Bicycle',
        'Commercial / Heavy Vehicle / Truck / Bus', 'Other Vehicle',
    ],
}


def _opt(group):
    return f'/api/options/{group}/'


SHOW_JEWELLERY = 'Precious Metal / Jewellery|Any Metal (Copper / Iron / Scrap)|Diamond and Precious Stone'
SHOW_VEHICLE = 'Vehicle'
SHOW_CASH = 'Cash'

SEC_STOLEN = 'Stolen Property List'
SEC_TYPE = 'Type of Property Stolen'
SEC_JEWEL = 'Jewellery & Precious Metal Details'
SEC_VEHICLE = 'Vehicle Details'
SEC_CASH = 'Cash Details'
SEC_RECOVERED = 'Recovered Property List'
SEC_INJURED = 'Injured Person Details'
SEC_DECEASED = 'Deceased Person Details'

STOLEN = 'rd_stolen_props'
ORNAMENTS = 'rd_ornaments'
RECOVERED = 'rd_recovered_props'
INJURED = 'rd_injured_persons'
DECEASED = 'rd_deceased_persons'

# (label, key, type, section, order, depends_on_key, depends_on_val, options_source, parent_field_key, required)
FIELDS = [
    # 1. Stolen Property List
    ('Stolen Property', STOLEN, 'repeating_group', SEC_STOLEN, 10, None, None, None, None, False),
    ('1. Name of Property', 'rd_stolen_name', 'text', SEC_STOLEN, 11, None, None, None, STOLEN, True),
    ('2. Description / Markings', 'rd_stolen_description', 'text', SEC_STOLEN, 12, None, None, None, STOLEN, False),
    ('3. Estimated Value (₹)', 'rd_stolen_value', 'number', SEC_STOLEN, 13, None, None, None, STOLEN, False),

    # 2. Type of Property Stolen
    ('Type of Property Stolen (select all that apply)', 'rd_property_types', 'multi_select', SEC_TYPE, 20,
     None, None, _opt('robbery_property_types'), None, False),
    ('Other Property Type (type)', 'rd_property_type_other', 'text', SEC_TYPE, 21,
     'rd_property_types', 'Other', None, None, False),

    # 3. Jewellery & Precious Metal Details
    ('Gold', 'rd_gold', 'radio', SEC_JEWEL, 30, 'rd_property_types', SHOW_JEWELLERY, YES_NO, None, False),
    ('Silver', 'rd_silver', 'radio', SEC_JEWEL, 31, 'rd_property_types', SHOW_JEWELLERY, YES_NO, None, False),
    ('Platinum', 'rd_platinum', 'radio', SEC_JEWEL, 32, 'rd_property_types', SHOW_JEWELLERY, YES_NO, None, False),
    ('Other Metal Name (type)', 'rd_other_metal_name', 'text', SEC_JEWEL, 33,
     'rd_property_types', SHOW_JEWELLERY, None, None, False),
    ('Ornaments & Items Breakdown', ORNAMENTS, 'repeating_group', SEC_JEWEL, 34,
     'rd_property_types', SHOW_JEWELLERY, None, None, False),
    ('1. Name of Ornament', 'rd_ornament_name', 'text', SEC_JEWEL, 35, None, None, None, ORNAMENTS, True),
    ('2. Metal of Ornament', 'rd_ornament_metal', 'dropdown', SEC_JEWEL, 36,
     None, None, _opt('robbery_ornament_metals'), ORNAMENTS, True),
    ('Other Metal (type)', 'rd_ornament_metal_other', 'text', SEC_JEWEL, 37,
     'rd_ornament_metal', 'Other', None, ORNAMENTS, False),
    ('3. Value of Ornament (₹)', 'rd_ornament_value', 'number', SEC_JEWEL, 38, None, None, None, ORNAMENTS, True),
    ('Total Value (₹)', 'rd_ornaments_total_value', 'number', SEC_JEWEL, 39,
     'rd_property_types', SHOW_JEWELLERY, f'sum:{ORNAMENTS}.rd_ornament_value', None, False),

    # 4. Vehicle Details
    ('Type of Vehicle', 'rd_vehicle_type', 'dropdown', SEC_VEHICLE, 40,
     'rd_property_types', SHOW_VEHICLE, _opt('robbery_vehicle_types'), None, False),
    ('1. Engine Number', 'rd_vehicle_engine_number', 'text', SEC_VEHICLE, 41,
     'rd_property_types', SHOW_VEHICLE, None, None, True),
    ('2. Chassis Number', 'rd_vehicle_chassis_number', 'text', SEC_VEHICLE, 42,
     'rd_property_types', SHOW_VEHICLE, None, None, True),
    ('3. Registration Number', 'rd_vehicle_reg_number', 'text', SEC_VEHICLE, 43,
     'rd_property_types', SHOW_VEHICLE, None, None, True),
    ('4. Unique Identification Mark', 'rd_vehicle_unique_mark', 'text', SEC_VEHICLE, 44,
     'rd_property_types', SHOW_VEHICLE, None, None, False),
    ('Photo (vehicle photograph available?)', 'rd_vehicle_photo', 'radio', SEC_VEHICLE, 45,
     'rd_property_types', SHOW_VEHICLE, YES_NO, None, False),
    ('Ownership Document (RC / Insurance verified?)', 'rd_vehicle_ownership_doc', 'radio', SEC_VEHICLE, 46,
     'rd_property_types', SHOW_VEHICLE, YES_NO, None, False),

    # 5. Cash Details
    ('1. Total Rupees or Any Currency (e.g. ₹50,000 / USD 500)', 'rd_cash_total', 'text', SEC_CASH, 50,
     'rd_property_types', SHOW_CASH, None, None, True),
    ('2. Count of Notes (e.g. 500 × 80 notes, 200 × 50 notes)', 'rd_cash_note_count', 'text', SEC_CASH, 51,
     'rd_property_types', SHOW_CASH, None, None, False),

    # 6. Recovered Property List
    ('Recovered Property', RECOVERED, 'repeating_group', SEC_RECOVERED, 60, None, None, None, None, False),
    ('1. Name of Property', 'rd_recovered_name', 'text', SEC_RECOVERED, 61, None, None, None, RECOVERED, True),
    ('2. Description / Markings', 'rd_recovered_description', 'text', SEC_RECOVERED, 62,
     None, None, None, RECOVERED, False),
    ('3. Estimated Value (₹)', 'rd_recovered_value', 'number', SEC_RECOVERED, 63, None, None, None, RECOVERED, False),

    # 7. Injured Person Details
    ('Injured Persons', INJURED, 'repeating_group', SEC_INJURED, 70, None, None, None, None, False),
    ('Name', 'rd_injured_name', 'text', SEC_INJURED, 71, None, None, None, INJURED, False),
    ('Age', 'rd_injured_age', 'number', SEC_INJURED, 72, None, None, 'digits:3', INJURED, False),
    ('Gender', 'rd_injured_gender', 'dropdown', SEC_INJURED, 73, None, None, GENDER, INJURED, False),
    ('Mobile', 'rd_injured_mobile', 'mobile', SEC_INJURED, 74, None, None, None, INJURED, False),
    ('Aadhaar', 'rd_injured_aadhaar', 'aadhaar', SEC_INJURED, 75, None, None, None, INJURED, False),
    ('PAN', 'rd_injured_pan', 'text', SEC_INJURED, 76, None, None, None, INJURED, False),
    ('Person Died?', 'rd_injured_died', 'radio', SEC_INJURED, 77, None, None, YES_NO, INJURED, False),
    ('Date & Time of Death', 'rd_injured_death_datetime', 'datetime', SEC_INJURED, 78,
     'rd_injured_died', YES, None, INJURED, False),
    ('Inquest Panchanama', 'rd_injured_inquest', 'radio', SEC_INJURED, 79,
     'rd_injured_died', YES, YES_NO, INJURED, False),
    ('Inquest Panchanama Date & Time', 'rd_injured_inquest_datetime', 'datetime', SEC_INJURED, 80,
     'rd_injured_inquest', YES, None, INJURED, False),
    ('Exhumation Panchanama', 'rd_injured_exhumation', 'radio', SEC_INJURED, 81,
     'rd_injured_died', YES, YES_NO, INJURED, False),
    ('Exhumation Panchanama Date & Time', 'rd_injured_exhumation_datetime', 'datetime', SEC_INJURED, 82,
     'rd_injured_exhumation', YES, None, INJURED, False),

    # 8. Deceased Person Details
    ('Deceased Persons', DECEASED, 'repeating_group', SEC_DECEASED, 90, None, None, None, None, False),
    ('Name', 'rd_deceased_name', 'text', SEC_DECEASED, 91, None, None, None, DECEASED, False),
    ('Age', 'rd_deceased_age', 'number', SEC_DECEASED, 92, None, None, 'digits:3', DECEASED, False),
    ('Gender', 'rd_deceased_gender', 'dropdown', SEC_DECEASED, 93, None, None, GENDER, DECEASED, False),
    ('Occupation', 'rd_deceased_occupation', 'text', SEC_DECEASED, 94, None, None, None, DECEASED, False),
    ('Mobile', 'rd_deceased_mobile', 'mobile', SEC_DECEASED, 95, None, None, None, DECEASED, False),
    ('Aadhaar', 'rd_deceased_aadhaar', 'aadhaar', SEC_DECEASED, 96, None, None, None, DECEASED, False),
    ('PAN', 'rd_deceased_pan', 'text', SEC_DECEASED, 97, None, None, None, DECEASED, False),
    ('Religion', 'rd_deceased_religion', 'text', SEC_DECEASED, 98, None, None, None, DECEASED, False),
    ('Caste', 'rd_deceased_caste', 'text', SEC_DECEASED, 99, None, None, None, DECEASED, False),
    ('Address', 'rd_deceased_address', 'textarea', SEC_DECEASED, 100, None, None, None, DECEASED, False),
    ('Postmortem', 'rd_postmortem', 'radio', SEC_DECEASED, 101, None, None, YES_NO, DECEASED, False),
    ('Postmortem Date', 'rd_postmortem_date', 'date', SEC_DECEASED, 102, 'rd_postmortem', YES, None, DECEASED, False),
    ('Postmortem Time', 'rd_postmortem_time', 'time', SEC_DECEASED, 103, 'rd_postmortem', YES, None, DECEASED, False),
    ('Postmortem Report Sent', 'rd_pm_report_sent', 'radio', SEC_DECEASED, 104,
     'rd_postmortem', YES, YES_NO, DECEASED, False),
    ('Report Sent Date', 'rd_pm_report_sent_date', 'date', SEC_DECEASED, 105,
     'rd_pm_report_sent', YES, None, DECEASED, False),
    ('Report Sent Time', 'rd_pm_report_sent_time', 'time', SEC_DECEASED, 106,
     'rd_pm_report_sent', YES, None, DECEASED, False),
    ('Viscera Sent to FSL', 'rd_viscera_fsl', 'radio', SEC_DECEASED, 107,
     'rd_postmortem', YES, YES_NO, DECEASED, False),
    ('Viscera Sent Date', 'rd_viscera_fsl_date', 'date', SEC_DECEASED, 108,
     'rd_viscera_fsl', YES, None, DECEASED, False),
    ('Viscera Sent Time', 'rd_viscera_fsl_time', 'time', SEC_DECEASED, 109,
     'rd_viscera_fsl', YES, None, DECEASED, False),
    ('FSL Report', 'rd_fsl_report', 'radio', SEC_DECEASED, 110,
     'rd_viscera_fsl', YES, YES_NO, DECEASED, False),
    ('FSL Report Date', 'rd_fsl_report_date', 'date', SEC_DECEASED, 111,
     'rd_fsl_report', YES, None, DECEASED, False),
    ('FSL Report Time', 'rd_fsl_report_time', 'time', SEC_DECEASED, 112,
     'rd_fsl_report', YES, None, DECEASED, False),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')

    for group, values in OPTION_GROUPS.items():
        for i, value in enumerate(values, 1):
            OptionValue.objects.get_or_create(
                option_group=group, option_value=value,
                defaults={'display_order': i * 10, 'is_active': True},
            )

    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True}
    )
    for label, key, ftype, section, order, parent_k, parent_v, opt_src, grp, required in FIELDS:
        FieldTemplateField.objects.update_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': required,
                'section': section,
                'display_order': order,
                'options_source': opt_src,
                'depends_on_field_key': parent_k,
                'depends_on_value': parent_v,
                'parent_field_key': grp or '',
            },
        )

    name_q = Q()
    for name in CATEGORY_NAMES:
        name_q |= Q(category_name__iexact=name)
    for cat in CaseCategory.objects.filter(Q(category_code__in=CATEGORY_CODES) | name_q):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if not tmpl:
        return
    CategoryFieldTemplate.objects.filter(template=tmpl).delete()
    FieldTemplateField.objects.filter(template=tmpl).delete()
    tmpl.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0142_attempt_to_murder_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
