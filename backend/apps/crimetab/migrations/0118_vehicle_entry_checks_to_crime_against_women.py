from django.db import migrations

"""
Migration 0118: SD / case diary vehicle entry checks only for Crime Against Women (data only)

0116 put "Government Vehicle Used: SD Entry of Vehicle Number and Time" and
"Case Diary Vehicle Entry" in the Common Form, so every crime tab showed them.
They belong to Crime Against Women only: removed from the Common Form (no case
had a value in them) and added to "Crime Against Women Extra Fields" in a new
section "CAW - Government Vehicle Use". The Common Form keeps its own Vehicle
Log Book Entry and the Section 82, 83 check. Idempotent.
"""

COMMON = 'Common Form Baseline Template'
CAW = 'Crime Against Women Extra Fields'
YES_NO = '/api/options/yes_no/'
CAW_SECTION = 'CAW - Government Vehicle Use'

# (label, common key, common order, caw key, caw order)
CHECKS = [
    ('Government Vehicle Used: SD Entry of Vehicle Number and Time',
     'govt_vehicle_sd_entry', 794, 'caw_govt_vehicle_sd_entry', 810),
    ('Case Diary Vehicle Entry',
     'case_diary_vehicle_entry', 795, 'caw_case_diary_vehicle_entry', 820),
]


def _create(FieldTemplateField, tmpl, label, key, section, order):
    FieldTemplateField.objects.get_or_create(
        template=tmpl, field_key=key,
        defaults={'field_label': label, 'field_source': 'custom', 'field_type': 'radio',
                  'is_required': False, 'section': section, 'display_order': order,
                  'options_source': YES_NO},
    )


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=COMMON, field_key__in=[c for _, c, _, _, _ in CHECKS]
    ).delete()
    caw = FieldTemplate.objects.filter(template_name=CAW).first()
    if caw is None:
        return
    for label, _, _, key, order in CHECKS:
        _create(FieldTemplateField, caw, label, key, CAW_SECTION, order)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=CAW, field_key__in=[k for _, _, _, k, _ in CHECKS]
    ).delete()
    common = FieldTemplate.objects.filter(template_name=COMMON).first()
    if common is None:
        return
    for label, key, order, _, _ in CHECKS:
        _create(FieldTemplateField, common, label, key, 'Vehicle Log Book', order)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0117_remove_pocso_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
