from django.db import migrations

"""
Migration 0109: "Vehicle Theft Extra Fields" for Two/Four Wheeler Theft (data only)

- New bundle "Vehicle Theft Extra Fields" with one section "D. Vehicle Theft":
    1. Vehicle Number
    2. Vehicle Sub-Type (dropdown, existing options group theft_vehicle_sub_types:
       Two Wheeler, Four Wheeler, Three Wheeler, Bicycle,
       Commercial / Heavy Vehicle / Truck / Bus, Other Vehicle)
    3. Vehicle Make / Model
    4. Driving Licence Number
    5. Driving Licence Class / Category
    6. Driving Licence Validity (optional)
    7. Registration Certificate (RC) Number
    8. Chassis Number (optional)
    9. Engine Number (optional)
- Linked (category_field_templates) only to the Two/Four Wheeler Theft
  categories (codes '123' and 'STAND_VEHICLE'). All fields optional.
Values are stored as rows of case_extra_field_values (store_values_in_table). Idempotent.
"""

TEMPLATE_NAME = 'Vehicle Theft Extra Fields'
CATEGORY_CODES = ('123', 'STAND_VEHICLE')
SECTION = 'D. Vehicle Theft'
SUB_TYPES = '/api/options/theft_vehicle_sub_types/'

# (label, key, type, order, options_source)
FIELDS = [
    ('1. Vehicle Number', 'vt_vehicle_number', 'text', 10, None),
    ('2. Vehicle Sub-Type', 'vt_vehicle_sub_type', 'dropdown', 20, SUB_TYPES),
    ('3. Vehicle Make / Model', 'vt_vehicle_make_model', 'text', 30, None),
    ('4. Driving Licence Number', 'vt_dl_number', 'text', 40, None),
    ('5. Driving Licence Class / Category', 'vt_dl_class', 'text', 50, None),
    ('6. Driving Licence Validity (optional)', 'vt_dl_validity', 'date', 60, None),
    ('7. Registration Certificate (RC) Number', 'vt_rc_number', 'text', 70, None),
    ('8. Chassis Number (optional)', 'vt_chassis_number', 'text', 80, None),
    ('9. Engine Number (optional)', 'vt_engine_number', 'text', 90, None),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    # Answers saved as rows of case_extra_field_values (services/table_field_values.py)
    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True})
    for label, key, ftype, order, options in FIELDS:
        FieldTemplateField.objects.get_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': SECTION,
                'display_order': order,
                'options_source': options,
            },
        )
    for cat in CaseCategory.objects.filter(category_code__in=CATEGORY_CODES):
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
        ('crimetab', '0108_mv_act_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
