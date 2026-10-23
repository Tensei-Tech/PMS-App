from django.db import migrations

"""
Migration 0113: remove the old Murder extra fields (data only)

Deletes the six fields of "Murder Section Extra Fields": Deceased Name, Deceased
Age, Deceased Gender, Inquest Panchanama Details, Post-Mortem Report Date,
Cause of Death. Their case_extra_field_values rows (all empty) go with them.
The template and its link to the Murder category stay, so new Murder fields can
be added to it later. Text already saved under these keys in a case's
extra_fields JSON is left as it is (just no longer shown). Idempotent.
"""

TEMPLATE_NAME = 'Murder Section Extra Fields'

# (label, key, type, order): recreated as they were when going backwards
OLD_FIELDS = [
    ('Deceased Name', 'deceased_name', 'text', 1000),
    ('Deceased Age', 'deceased_age', 'number', 1010),
    ('Deceased Gender', 'deceased_gender', 'dropdown', 1020),
    ('Inquest Panchanama Details', 'inquest_panchanama', 'textarea', 1030),
    ('Post-Mortem Report Date', 'pm_report_date', 'date', 1040),
    ('Cause of Death', 'cause_of_death', 'textarea', 1050),
]


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key__in=[k for _, k, _, _ in OLD_FIELDS]
    ).delete()


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    for label, key, ftype, order in OLD_FIELDS:
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key=key,
            defaults={'field_label': label, 'field_source': 'custom', 'field_type': ftype,
                      'is_required': False, 'display_order': order},
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0112_gowansh_full_checklist'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
