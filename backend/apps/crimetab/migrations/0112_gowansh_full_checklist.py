from django.db import migrations

"""
Migration 0112: Gowansh (cattle / cow & other animal crime) full checklist (data only)

The existing "Gowansh Extra Fields" bundle (already linked to the Gowansh
categories) becomes the full checklist, in five sections:
    Animal Details             type (dropdown), counts, breed, sex, age, marks,
                               weight, values, photo / ownership / vet Y/N,
                               post-mortem (Done / Not Done / Required) + date
    Illegal Transport          vehicle, owner, driver, cleaner, animals
                               transported, purpose, overcrowding ... vehicle seized
    Cruelty to Animals         nature of cruelty (multi-select)
    Animal Wellness            vet examination, welfare organisation informed,
                               shifted to safe custody + date + Goshala,
                               released / handed over to owner
    Cow / Cattle Slaughter     attempted / completed, place of slaughter, 9 Y/N checks

The six old fields of 0024 (Type of Animal, Number of Animals, Estimated
Value, Vehicle Number, Seizure Location, Goshala / Custody Place) are removed
first; all their saved values were empty. Only the fields listed above are
created (Type of Animal, Number of Animals and Vehicle Number come back as new
fields under the same keys).

The bundle now stores answers as rows of case_extra_field_values
(store_values_in_table), so the multi-select keeps every choice.
New option groups: gowansh_animal_types, gowansh_postmortem_status,
gowansh_cruelty_types, gowansh_slaughter_stages, gowansh_slaughter_places.
Every field is optional. Idempotent.
"""

TEMPLATE_NAME = 'Gowansh Extra Fields'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'

ANIMAL_TYPES = 'gowansh_animal_types'
POSTMORTEM = 'gowansh_postmortem_status'
CRUELTY = 'gowansh_cruelty_types'
SLAUGHTER_STAGES = 'gowansh_slaughter_stages'
SLAUGHTER_PLACES = 'gowansh_slaughter_places'
OPTIONS = {
    ANIMAL_TYPES: ['Cow / Bull / Bullock', 'Buffalo', 'Goat', 'Sheep', 'Horse', 'Dog', 'Other'],
    POSTMORTEM: ['Done', 'Not Done', 'Required'],
    CRUELTY: ['Bleeding / Fracture / Wounds', 'Beating / Torture',
              'Improper Tying / Restraint', 'Abandonment'],
    SLAUGHTER_STAGES: ['Attempted', 'Completed'],
    SLAUGHTER_PLACES: ['Slaughterhouse', 'Private Premises', 'Open Place'],
}


def opt(group):
    return f'/api/options/{group}/'


ANIMAL = 'Animal Details'
TRANSPORT = 'Illegal Transport'
CRUELTY_SEC = 'Cruelty to Animals'
WELLNESS = 'Animal Wellness'
SLAUGHTER = 'Cow / Cattle Slaughter Case'

# (label, key, type, section, order, options_source, depends_on (key, value) or None)
FIELDS = [
    ('Type of Animal', 'gowansh_animal_type', 'dropdown', ANIMAL, 10, opt(ANIMAL_TYPES), None),
    ('Other Animal (type name)', 'gowansh_animal_type_other', 'text', ANIMAL, 15, None, ('gowansh_animal_type', 'Other')),
    ('Number of Animals', 'gowansh_animal_count', 'number', ANIMAL, 20, None, None),
    ('Total Number of Animals', 'gowansh_animal_total_count', 'number', ANIMAL, 30, None, None),
    ('Breed / Description (if any)', 'gowansh_breed', 'text', ANIMAL, 40, None, None),
    ('Male / Female', 'gowansh_animal_gender', 'dropdown', ANIMAL, 50, opt('theft_animal_genders'), None),
    ('Approximate Age', 'gowansh_approx_age', 'text', ANIMAL, 60, None, None),
    ('Colour / Identification Mark', 'gowansh_colour_marks', 'text', ANIMAL, 70, None, None),
    ('Approximate Weight (if applicable)', 'gowansh_approx_weight', 'text', ANIMAL, 80, None, None),
    ('Approximate Value of Each Animal (₹)', 'gowansh_value_each', 'number', ANIMAL, 90, None, None),
    ('Total Value of Animals (₹)', 'gowansh_total_value', 'number', ANIMAL, 100, None, None),
    ('Photograph / Video of Animal', 'gowansh_photo_video', 'radio', ANIMAL, 110, YES_NO, None),
    ('Ownership Proof Available', 'gowansh_ownership_proof', 'radio', ANIMAL, 120, YES_NO, None),
    ('Veterinary Identification / Certification Taken', 'gowansh_vet_certification', 'radio', ANIMAL, 130, YES_NO, None),
    ('Post-Mortem', 'gowansh_postmortem', 'dropdown', ANIMAL, 140, opt(POSTMORTEM), None),
    ('Post-Mortem Date', 'gowansh_postmortem_date', 'date', ANIMAL, 150, None, ('gowansh_postmortem', 'Done')),

    ('Vehicle Number', 'gowansh_vehicle_no', 'text', TRANSPORT, 200, None, None),
    ('Vehicle Type', 'gowansh_vehicle_type', 'text', TRANSPORT, 210, None, None),
    ('Owner of Vehicle', 'gowansh_vehicle_owner', 'text', TRANSPORT, 220, None, None),
    ('Driver Name & Address', 'gowansh_driver_details', 'textarea', TRANSPORT, 230, None, None),
    ('Cleaner / Helper Name & Address', 'gowansh_cleaner_details', 'textarea', TRANSPORT, 240, None, None),
    ('Number of Animals Transported', 'gowansh_animals_transported', 'number', TRANSPORT, 250, None, None),
    ('Purpose of Transport (max 25 words)', 'gowansh_transport_purpose', 'textarea', TRANSPORT, 260, None, None),
    ('Overcrowding', 'gowansh_overcrowding', 'radio', TRANSPORT, 270, YES_NO, None),
    ('Food / Water Availability Checked', 'gowansh_food_water_checked', 'radio', TRANSPORT, 280, YES_NO, None),
    ('Injury / Ill-Treatment During Transport', 'gowansh_transport_injury', 'radio', TRANSPORT, 290, YES_NO, None),
    ('Vehicle Photographs', 'gowansh_vehicle_photos', 'radio', TRANSPORT, 300, YES_NO, None),
    ('Animals Photographed', 'gowansh_animals_photographed', 'radio', TRANSPORT, 310, YES_NO, None),
    ('Vehicle Seized', 'gowansh_vehicle_seized', 'radio', TRANSPORT, 320, YES_NO, None),

    ('Nature of Cruelty', 'gowansh_cruelty_nature', 'multi_select', CRUELTY_SEC, 400, opt(CRUELTY), None),

    ('Veterinary Examination Conducted', 'gowansh_vet_exam_conducted', 'checkbox', WELLNESS, 500, None, None),
    ('Animal Welfare Organisation / Shelter Informed', 'gowansh_welfare_informed', 'radio', WELLNESS, 510, YES_NO, None),
    ('Animal Shifted to Safe Custody', 'gowansh_safe_custody', 'radio', WELLNESS, 520, YES_NO, None),
    ('Animal Shifted to Safe Custody Date', 'gowansh_safe_custody_date', 'date', WELLNESS, 530, None, ('gowansh_safe_custody', YES)),
    ('Animal Released / Handed Over to Owner', 'gowansh_released_to_owner', 'checkbox', WELLNESS, 550, None, None),

    ('Slaughter Attempted / Completed', 'gowansh_slaughter_stage', 'radio', SLAUGHTER, 600, opt(SLAUGHTER_STAGES), None),
    ('Place of Slaughter', 'gowansh_slaughter_place', 'radio', SLAUGHTER, 610, opt(SLAUGHTER_PLACES), None),
    ('Instruments / Weapons Seized', 'gowansh_weapons_seized', 'radio', SLAUGHTER, 620, YES_NO, None),
    ('Photographs / Videography', 'gowansh_slaughter_photos', 'radio', SLAUGHTER, 630, YES_NO, None),
    ('Veterinary Examination', 'gowansh_slaughter_vet_exam', 'radio', SLAUGHTER, 640, YES_NO, None),
    ('Samples Collected', 'gowansh_samples_collected', 'radio', SLAUGHTER, 650, YES_NO, None),
    ('Sample Sent to FSL / Laboratory', 'gowansh_sample_sent_fsl', 'radio', SLAUGHTER, 660, YES_NO, None),
    ('FSL / Laboratory Report Received', 'gowansh_fsl_report_received', 'radio', SLAUGHTER, 670, YES_NO, None),
    ('Place of Slaughter Seized / Inspected', 'gowansh_slaughter_place_inspected', 'radio', SLAUGHTER, 680, YES_NO, None),
    ('Flesh / Meat Seized', 'gowansh_meat_seized', 'radio', SLAUGHTER, 690, YES_NO, None),
    ('Weight Recorded', 'gowansh_weight_recorded', 'radio', SLAUGHTER, 700, YES_NO, None),
]

# The six fields 0024 created: removed going forwards, recreated going backwards
ORIGINAL = {
    'gowansh_animal_type': ('Type of Animal', 'text', 'Animal Details', 10),
    'gowansh_animal_count': ('Number of Animals', 'number', 'Animal Details', 20),
    'gowansh_est_value': ('Estimated Value', 'number', 'Animal Details', 30),
    'gowansh_vehicle_no': ('Vehicle Number', 'text', 'Transport Details', 40),
    'gowansh_seizure_loc': ('Seizure Location', 'textarea', 'Transport Details', 50),
    'gowansh_custody_place': ('Goshala / Custody Place', 'text', 'Custody', 60),
}


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    OptionValue = apps.get_model('crimetab', 'OptionValue')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    for group, values in OPTIONS.items():
        for i, value in enumerate(values, 1):
            OptionValue.objects.get_or_create(
                option_group=group, option_value=value,
                defaults={'display_order': i * 10, 'is_active': True},
            )

    # Answers saved as rows of case_extra_field_values (services/table_field_values.py)
    FieldTemplate.objects.filter(pk=tmpl.pk).update(store_values_in_table=True)
    # Old fields out (their saved values, all empty, go with them)
    FieldTemplateField.objects.filter(template=tmpl, field_key__in=list(ORIGINAL)).delete()
    for label, key, ftype, section, order, options, depends in FIELDS:
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
                'depends_on_field_key': depends[0] if depends else None,
                'depends_on_value': depends[1] if depends else None,
            },
        )


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is not None:
        FieldTemplateField.objects.filter(template=tmpl).delete()
        for key, (label, ftype, section, order) in ORIGINAL.items():
            FieldTemplateField.objects.create(
                template=tmpl, field_key=key, field_label=label, field_source='custom',
                field_type=ftype, is_required=False, section=section, display_order=order)
        FieldTemplate.objects.filter(pk=tmpl.pk).update(store_values_in_table=False)
    OptionValue.objects.filter(option_group__in=list(OPTIONS)).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0111_sand_theft_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
