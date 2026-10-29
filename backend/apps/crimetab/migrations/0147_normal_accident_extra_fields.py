from django.db import migrations
from django.db.models import Q

"""
Migration 0147: "Normal Accident Extra Fields" for Normal Accident (data only)

Template: "Normal Accident Extra Fields" (store_values_in_table = True)
Linked to: Normal Accident under Accident (ACC_NORMAL, STAND_ACC_NORMAL).
Road Accident keeps its own "Road Accident Extra Template".

Sections:
1. Accident & Scene Overview: Nature of Accident * (select all that apply; Other -> specify),
   Landmark *, Road / Highway Type (Other -> specify), Vehicle abandoned at spot?,
   Driver subsequently traced?
2. Vehicles Involved (repeating, Add Vehicle): Registration Number *, Vehicle Type *
   (Other -> specify), Company / Manufacturer (Other -> specify), Make / Model,
   Owner (Name, Contact, Permanent & Present Address), Driver (Name, Contact, DL No.,
   Address), Vehicle seized at spot?, Damage / Condition
3. Investigation Status Checklist: driver identity, victim identity, eye-witnesses,
   CCTV / Dashcam, alcohol / narcotics test, RTO / mechanical inspection (Yes/No);
   DAR Form and IRAD Form (Yes/No, and the date if Yes)

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Normal Accident Extra Fields'
CATEGORY_CODES = ('ACC_NORMAL', 'STAND_ACC_NORMAL')
CATEGORY_NAME = 'Normal Accident'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'
OTHER = 'Other'

OPTION_GROUPS = {
    'accident_nature': [
        'Collision', 'Pedestrian Hit', 'Overturning', 'Over Speed', 'Dangerous Overtaking',
        'Wrong Side Driving', 'Fall from Vehicle', 'Hit Stationary Vehicle', 'Head-on Collision',
        'Rear-end Collision', 'Side Impact (T-bone)', OTHER,
    ],
    'accident_road_types': [
        'National Highway (NH)', 'State Highway (SH)', 'Expressway', 'City / Municipal Road',
        'Rural / Village Road', 'Junction / Crossroad', 'Bridge / Flyover', OTHER,
    ],
    'accident_vehicle_types': [
        'Two Wheeler (Motorcycle / Scooter)', 'Four Wheeler (Car / Jeep / Taxi)',
        'Auto Rickshaw (Three Wheeler)', 'E-Rickshaw', 'Bus (Private / State Transport)',
        'Truck / Lorry / Dumper', 'Tractor / Farm Equipment', 'Container / Heavy Commercial (HCV)',
        'Tempo / Light Commercial (LCV)', 'Bicycle', OTHER,
    ],
    'accident_vehicle_companies': [
        'Maruti Suzuki', 'Hyundai', 'Tata Motors', 'Mahindra & Mahindra', 'Honda', 'Toyota', 'Kia',
        'Hero MotoCorp', 'Bajaj Auto', 'TVS Motor', 'Yamaha', 'Royal Enfield', 'Ashok Leyland',
        'Eicher Motors', 'BharatBenz', 'Force Motors', OTHER,
    ],
}


def _opt(group):
    return f'/api/options/{group}/'


SEC_SCENE = 'Accident & Scene Overview'
SEC_VEHICLES = 'Vehicles Involved'
SEC_CHECKLIST = 'Investigation Status Checklist'
VEHICLES = 'nacc_vehicles'

# (label, key, type, section, order, depends_on_key, depends_on_val, options_source, parent_field_key, required)
FIELDS = [
    # 1. Accident & Scene Overview
    ('Nature of Accident (select all that apply)', 'nacc_nature', 'multi_select', SEC_SCENE, 10,
     None, None, _opt('accident_nature'), None, True),
    ('Specify Nature of Accident', 'nacc_nature_other', 'text', SEC_SCENE, 11, 'nacc_nature', OTHER, None, None, False),
    ('Landmark', 'nacc_landmark', 'text', SEC_SCENE, 12, None, None, None, None, True),
    ('Road / Highway Type', 'nacc_road_type', 'dropdown', SEC_SCENE, 13,
     None, None, _opt('accident_road_types'), None, False),
    ('Specify Road / Highway Type', 'nacc_road_type_other', 'text', SEC_SCENE, 14,
     'nacc_road_type', OTHER, None, None, False),
    ('Vehicle abandoned at spot?', 'nacc_vehicle_abandoned', 'radio', SEC_SCENE, 15, None, None, YES_NO, None, False),
    ('Driver subsequently traced?', 'nacc_driver_traced', 'radio', SEC_SCENE, 16, None, None, YES_NO, None, False),

    # 2. Vehicles Involved (Add Vehicle)
    ('Vehicles (Add Vehicle)', VEHICLES, 'repeating_group', SEC_VEHICLES, 20, None, None, None, None, False),
    ('Vehicle Registration Number', 'nacc_vehicle_reg_number', 'text', SEC_VEHICLES, 21,
     None, None, None, VEHICLES, True),
    ('Vehicle Type', 'nacc_vehicle_type', 'dropdown', SEC_VEHICLES, 22,
     None, None, _opt('accident_vehicle_types'), VEHICLES, True),
    ('Specify Vehicle Type', 'nacc_vehicle_type_other', 'text', SEC_VEHICLES, 23,
     'nacc_vehicle_type', OTHER, None, VEHICLES, False),
    ('Company / Manufacturer', 'nacc_vehicle_company', 'dropdown', SEC_VEHICLES, 24,
     None, None, _opt('accident_vehicle_companies'), VEHICLES, False),
    ('Specify Company / Manufacturer', 'nacc_vehicle_company_other', 'text', SEC_VEHICLES, 25,
     'nacc_vehicle_company', OTHER, None, VEHICLES, False),
    ('Make / Model', 'nacc_vehicle_make_model', 'text', SEC_VEHICLES, 26, None, None, None, VEHICLES, False),
    ('Owner Full Name', 'nacc_owner_name', 'text', SEC_VEHICLES, 27, None, None, None, VEHICLES, False),
    ('Owner Contact Number', 'nacc_owner_contact', 'mobile', SEC_VEHICLES, 28, None, None, None, VEHICLES, False),
    ('Owner Permanent & Present Address', 'nacc_owner_address', 'textarea', SEC_VEHICLES, 29,
     None, None, None, VEHICLES, False),
    ('Driver Full Name', 'nacc_driver_name', 'text', SEC_VEHICLES, 30, None, None, None, VEHICLES, False),
    ('Driver Contact Number', 'nacc_driver_contact', 'mobile', SEC_VEHICLES, 31, None, None, None, VEHICLES, False),
    ('Driver Driving License (DL) No.', 'nacc_driver_dl_no', 'text', SEC_VEHICLES, 32,
     None, None, None, VEHICLES, False),
    ('Driver Address', 'nacc_driver_address', 'textarea', SEC_VEHICLES, 33, None, None, None, VEHICLES, False),
    ('Vehicle seized at scene / spot?', 'nacc_vehicle_seized', 'radio', SEC_VEHICLES, 34,
     None, None, YES_NO, VEHICLES, False),
    ('Vehicle Damage / Condition Description', 'nacc_vehicle_damage', 'textarea', SEC_VEHICLES, 35,
     None, None, None, VEHICLES, False),

    # 3. Investigation Status Checklist
    ('Identity of driver(s) established?', 'nacc_driver_identified', 'radio', SEC_CHECKLIST, 40,
     None, None, YES_NO, None, False),
    ('Identity of victim(s) established?', 'nacc_victim_identified', 'radio', SEC_CHECKLIST, 41,
     None, None, YES_NO, None, False),
    ('Eye-witnesses identified & examined?', 'nacc_eye_witnesses', 'radio', SEC_CHECKLIST, 42,
     None, None, YES_NO, None, False),
    ('CCTV / Dashcam footage available?', 'nacc_cctv_dashcam', 'radio', SEC_CHECKLIST, 43,
     None, None, YES_NO, None, False),
    ('Breathalyzer / Blood test for alcohol conducted?', 'nacc_alcohol_test', 'radio', SEC_CHECKLIST, 44,
     None, None, YES_NO, None, False),
    ('RTO / Mechanical inspection done?', 'nacc_rto_inspection', 'radio', SEC_CHECKLIST, 45,
     None, None, YES_NO, None, False),
    ('DAR Form', 'nacc_dar_form', 'radio', SEC_CHECKLIST, 46, None, None, YES_NO, None, False),
    ('DAR Form Date', 'nacc_dar_form_date', 'date', SEC_CHECKLIST, 47, 'nacc_dar_form', YES, None, None, False),
    ('IRAD Form', 'nacc_irad_form', 'radio', SEC_CHECKLIST, 48, None, None, YES_NO, None, False),
    ('IRAD Form Date', 'nacc_irad_form_date', 'date', SEC_CHECKLIST, 49, 'nacc_irad_form', YES, None, None, False),
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

    for cat in CaseCategory.objects.filter(Q(category_code__in=CATEGORY_CODES) | Q(category_name__iexact=CATEGORY_NAME)):
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
        ('crimetab', '0146_remove_riot_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
