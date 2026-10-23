from django.db import migrations

"""
Migration 0108: "MV Act Extra Fields" for crimes registered under the M.V. Act (data only)

- New bundle "MV Act Extra Fields" in field_templates with the MV Act checklist,
  in four sections (shown after the Common Form sections):
    MV Act - Vehicle & Driver          vehicle, owner, driver, driving licence
    MV Act - Vehicle Documents         RC, chassis/engine, insurance, PUC, permit, fitness
    MV Act - Offence Details           defects, speed, drunken driving, overloading,
                                       weighment, helmet/belt, traffic signal
    MV Act - Seizure & Licence Action  vehicle seized/released, licence seized/suspended
- Linked (category_field_templates) only to the M.V Act categories (codes '608'
  and 'STAND_MV_ACT'), so the fields show only for MV Act crimes.
- Yes/No questions are radios on /api/options/yes_no/. A detail that belongs to
  a Yes (licence details, breath reading, fitness validity, seized / released
  date) shows only when the answer is "Yes". Every field is optional.
Values are stored as rows of case_extra_field_values (store_values_in_table). Idempotent.
"""

TEMPLATE_NAME = 'MV Act Extra Fields'
MV_CATEGORY_CODES = ('608', 'STAND_MV_ACT')
YES_NO = '/api/options/yes_no/'
YES = 'Yes'

VEHICLE = 'MV Act - Vehicle & Driver'
DOCS = 'MV Act - Vehicle Documents'
OFFENCE = 'MV Act - Offence Details'
ACTION = 'MV Act - Seizure & Licence Action'

# (label, key, type, section, order, depends_on_key)
FIELDS = [
    ('Vehicle Number', 'mv_vehicle_number', 'text', VEHICLE, 10, None),
    ('Vehicle Type', 'mv_vehicle_type', 'text', VEHICLE, 20, None),
    ('Vehicle Make / Model', 'mv_vehicle_make_model', 'text', VEHICLE, 30, None),
    ('Vehicle Owner Name & Details', 'mv_owner_details', 'textarea', VEHICLE, 40, None),
    ('Driver Name & Details', 'mv_driver_details', 'textarea', VEHICLE, 50, None),
    ('Has Driving Licence', 'mv_has_driving_licence', 'radio', VEHICLE, 60, None),
    ('Driving Licence Number', 'mv_dl_number', 'text', VEHICLE, 70, 'mv_has_driving_licence'),
    ('Driving Licence Class / Category', 'mv_dl_class', 'text', VEHICLE, 80, 'mv_has_driving_licence'),
    ('Driving Licence Validity', 'mv_dl_validity', 'date', VEHICLE, 90, 'mv_has_driving_licence'),

    ('Registration Certificate (RC) Number', 'mv_rc_number', 'text', DOCS, 110, None),
    ('RC Valid / Registration Status', 'mv_rc_valid', 'radio', DOCS, 120, None),
    ('Chassis Number', 'mv_chassis_number', 'text', DOCS, 130, None),
    ('Engine Number', 'mv_engine_number', 'text', DOCS, 140, None),
    ('Insurance Policy Number', 'mv_insurance_number', 'text', DOCS, 150, None),
    ('Insurance Valid', 'mv_insurance_valid', 'radio', DOCS, 160, None),
    ('PUC Certificate Number', 'mv_puc_number', 'text', DOCS, 170, None),
    ('PUC Valid', 'mv_puc_valid', 'radio', DOCS, 180, None),
    ('Permit Number (if applicable)', 'mv_permit_number', 'text', DOCS, 190, None),
    ('Permit Valid', 'mv_permit_valid', 'radio', DOCS, 200, None),
    ('Fitness Certificate (if applicable)', 'mv_fitness_certificate', 'radio', DOCS, 210, None),
    ('Fitness Valid', 'mv_fitness_valid', 'radio', DOCS, 220, 'mv_fitness_certificate'),

    ('Vehicle Condition / Defect Details (if applicable)', 'mv_vehicle_defects', 'textarea', OFFENCE, 310, None),
    ('Speed / Speed Limit Details (if applicable)', 'mv_speed_details', 'text', OFFENCE, 320, None),
    ('Breath Analyser Test (if applicable)', 'mv_breath_test', 'radio', OFFENCE, 330, None),
    ('Breath Analyser Reading', 'mv_breath_reading', 'text', OFFENCE, 340, 'mv_breath_test'),
    ('Medical Examination for Drunken Driving', 'mv_medical_exam', 'radio', OFFENCE, 350, None),
    ('Blood / Other Sample', 'mv_blood_sample', 'radio', OFFENCE, 360, None),
    ('Overloading Details (if applicable)', 'mv_overloading_details', 'textarea', OFFENCE, 370, None),
    ('Number of Passengers (if applicable)', 'mv_passenger_count', 'number', OFFENCE, 380, None),
    ('Permissible Passenger Capacity (if applicable)', 'mv_passenger_capacity', 'number', OFFENCE, 390, None),
    ('Weighment / Weight Certificate Taken (if applicable)', 'mv_weighment_taken', 'radio', OFFENCE, 400, None),
    ('Helmet Violation (if applicable)', 'mv_helmet_violation', 'radio', OFFENCE, 410, None),
    ('Safety Belt Violation (if applicable)', 'mv_seat_belt_violation', 'radio', OFFENCE, 420, None),
    ('Traffic Signal / Traffic Sign Violation', 'mv_traffic_signal_violation', 'radio', OFFENCE, 430, None),

    ('Vehicle Seized', 'mv_vehicle_seized', 'radio', ACTION, 510, None),
    ('Vehicle Seized Date', 'mv_vehicle_seized_date', 'date', ACTION, 520, 'mv_vehicle_seized'),
    ('Vehicle Released', 'mv_vehicle_released', 'radio', ACTION, 530, None),
    ('Vehicle Released Date', 'mv_vehicle_released_date', 'date', ACTION, 540, 'mv_vehicle_released'),
    ('Driving Licence Seized', 'mv_dl_seized', 'radio', ACTION, 550, None),
    ('Driving Licence Suspended', 'mv_dl_suspended', 'radio', ACTION, 560, None),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    # Answers saved as rows of case_extra_field_values (services/table_field_values.py)
    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True})
    for label, key, ftype, section, order, parent in FIELDS:
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
                'depends_on_field_key': parent,
                'depends_on_value': YES if parent else None,
                'options_source': YES_NO if ftype == 'radio' else None,
            },
        )
    for cat in CaseCategory.objects.filter(category_code__in=MV_CATEGORY_CODES):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    CategoryFieldTemplate.objects.filter(template=tmpl).delete()
    FieldTemplateField.objects.filter(template=tmpl).delete()
    tmpl.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0107_common_form_yes_no_reason_and_moves'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
