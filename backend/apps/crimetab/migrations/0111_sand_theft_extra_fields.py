from django.db import migrations

"""
Migration 0111: "Sand Theft Extra Fields" for Sand Theft (data only)

- New bundle "Sand Theft Extra Fields" (store_values_in_table: answers saved as
  rows of case_extra_field_values), linked (category_field_templates) only to
  the Sand Theft categories (codes '122' and 'STAND_SAND'). Sections:
    1. Stolen Property                    A. Stolen Properties (list: name,
                                          description, value), B. Recovered
                                          Properties (list: name, date, from,
                                          returned to owner, given to)
    2. Seized Vehicle                     list: vehicle name, engine, chassis,
                                          registration, mark, purchase date,
                                          photo copy, ownership document
    3. Spot Type                          exact place, type of location (+ Other)
    4. Spot Investigation Details         spot photo / video, footprint, fingerprint
    5. Investigation Verification Checks  witness, social media, bank, toll plaza,
                                          FASTag, ANPR
  The list fields follow the Theft template's Stolen / Recovered Property
  fields (the request did not name them).
- Option group sand_location_types: River Bed / Sand Ghat, Mine / Quarry,
  Road / Highway, Vehicle, Godown / Stockyard, Public Place, Other.
- Yes/No questions are radios on /api/options/yes_no/. Every field optional.
Idempotent.
"""

TEMPLATE_NAME = 'Sand Theft Extra Fields'
CATEGORY_CODES = ('122', 'STAND_SAND')
YES_NO = '/api/options/yes_no/'

LOCATION_TYPES = 'sand_location_types'
OPTIONS = {
    LOCATION_TYPES: ['River Bed / Sand Ghat', 'Mine / Quarry', 'Road / Highway', 'Vehicle',
                     'Godown / Stockyard', 'Public Place', 'Other'],
}

PROPERTY = '1. Stolen Property'
VEHICLE = '2. Seized Vehicle'
SPOT = '3. Spot Type'
SPOT_INV = '4. Spot Investigation Details'
CHECKS = '5. Investigation Verification Checks'

# (label, key, type, section, order, options_source, parent_field_key, depends_on)
# depends_on: (field_key, value) or None
FIELDS = [
    ('A. Stolen Properties', 'sand_stolen_props', 'repeating_group', PROPERTY, 10, None, None, None),
    ('Name of Stolen Property', 'sand_stolen_name', 'text', PROPERTY, 11, None, 'sand_stolen_props', None),
    ('Description', 'sand_stolen_description', 'text', PROPERTY, 12, None, 'sand_stolen_props', None),
    ('Value (₹)', 'sand_stolen_value', 'number', PROPERTY, 13, None, 'sand_stolen_props', None),

    ('B. Recovered Properties', 'sand_recovered_props', 'repeating_group', PROPERTY, 20, None, None, None),
    ('Recovered Property Name', 'sand_recovered_name', 'text', PROPERTY, 21, None, 'sand_recovered_props', None),
    ('Recovered Date', 'sand_recovered_date', 'date', PROPERTY, 22, None, 'sand_recovered_props', None),
    ('Recovered From', 'sand_recovered_from', 'text', PROPERTY, 23, None, 'sand_recovered_props', None),
    ('Return to Owner', 'sand_recovered_returned', 'radio', PROPERTY, 24, YES_NO, 'sand_recovered_props', None),
    ('Who Gave It To?', 'sand_recovered_given_to', 'text', PROPERTY, 25, None, 'sand_recovered_props', None),

    ('Seized Vehicle', 'sand_seized_vehicles', 'repeating_group', VEHICLE, 100, None, None, None),
    ('Vehicle Name (e.g. Tipper, Tractor, Truck, Excavator)', 'sand_vehicle_name', 'text', VEHICLE, 101, None, 'sand_seized_vehicles', None),
    ('Engine Number', 'sand_vehicle_engine_number', 'text', VEHICLE, 102, None, 'sand_seized_vehicles', None),
    ('Chassis Number', 'sand_vehicle_chassis_number', 'text', VEHICLE, 103, None, 'sand_seized_vehicles', None),
    ('Registration Number', 'sand_vehicle_reg_number', 'text', VEHICLE, 104, None, 'sand_seized_vehicles', None),
    ('Unique Identification Mark', 'sand_vehicle_unique_mark', 'text', VEHICLE, 105, None, 'sand_seized_vehicles', None),
    ('Purchase Date', 'sand_vehicle_purchase_date', 'date', VEHICLE, 106, None, 'sand_seized_vehicles', None),
    ('Photo Copy', 'sand_vehicle_photo_copy', 'radio', VEHICLE, 107, YES_NO, 'sand_seized_vehicles', None),
    ('Ownership Document', 'sand_vehicle_ownership_doc', 'radio', VEHICLE, 108, YES_NO, 'sand_seized_vehicles', None),

    ('A. Exact Place of Sand Theft (e.g. River Bed, Ghat, Road)', 'sand_exact_place', 'textarea', SPOT, 200, None, None, None),
    ('B. Type of Location', 'sand_location_type', 'dropdown', SPOT, 210, f'/api/options/{LOCATION_TYPES}/', None, None),
    ('Other Location', 'sand_location_type_other', 'text', SPOT, 220, None, None, ('sand_location_type', 'Other')),

    ('1. Spot Photo Taken', 'sand_spot_photo_taken', 'radio', SPOT_INV, 300, YES_NO, None, None),
    ('2. Spot Video Taken', 'sand_spot_video_taken', 'radio', SPOT_INV, 310, YES_NO, None, None),
    ('3. Footprint Found', 'sand_footprint_found', 'radio', SPOT_INV, 320, YES_NO, None, None),
    ('4. Fingerprint Found', 'sand_fingerprint_found', 'radio', SPOT_INV, 330, YES_NO, None, None),

    ('1. Witness Examined', 'sand_witness_examined', 'radio', CHECKS, 400, YES_NO, None, None),
    ('2. Social Media Checked', 'sand_social_media_checked', 'radio', CHECKS, 410, YES_NO, None, None),
    ('3. Bank Account Checked', 'sand_bank_account_checked', 'radio', CHECKS, 420, YES_NO, None, None),
    ('4. Toll Plaza Data Checked', 'sand_toll_plaza_checked', 'radio', CHECKS, 430, YES_NO, None, None),
    ('5. FASTag Data Checked', 'sand_fastag_checked', 'radio', CHECKS, 440, YES_NO, None, None),
    ('6. ANPR Data Checked', 'sand_anpr_checked', 'radio', CHECKS, 450, YES_NO, None, None),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')

    for group, values in OPTIONS.items():
        for i, value in enumerate(values, 1):
            OptionValue.objects.get_or_create(
                option_group=group, option_value=value,
                defaults={'display_order': i * 10, 'is_active': True},
            )

    # Answers saved as rows of case_extra_field_values (services/table_field_values.py)
    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True})
    for label, key, ftype, section, order, options, parent, depends in FIELDS:
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
                'options_source': options,
                'parent_field_key': parent,
                'depends_on_field_key': depends[0] if depends else None,
                'depends_on_value': depends[1] if depends else None,
            },
        )
    for cat in CaseCategory.objects.filter(category_code__in=CATEGORY_CODES):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is not None:
        CategoryFieldTemplate.objects.filter(template=tmpl).delete()
        FieldTemplateField.objects.filter(template=tmpl).delete()
        tmpl.delete()
    OptionValue.objects.filter(option_group__in=list(OPTIONS)).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0110_pocso_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
