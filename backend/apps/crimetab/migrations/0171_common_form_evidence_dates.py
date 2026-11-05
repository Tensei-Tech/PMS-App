from django.db import migrations

"""
Migration 0171: Common Form Evidence checkboxes ask for their date (data only)

Ticking E-Shakshya, Fingerprint Taken or NAFIS Fingerprint now shows a date
field right after it, like Mobile Spot Recording already does:
  e_shakshya_date, fingerprint_taken_date, nafis_fingerprint_date
They are optional. Mobile Spot Recording and its date move to the end of the
section so each date sits after its own checkbox.
Idempotent; backwards removes the three dates and restores the old order.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
SECTION = 'Evidence'

# (checkbox key, date label, checkbox order, date order)
DATES = [
    ('e_shakshya', 'E-Shakshya Date', 800, 805),
    ('fingerprint_taken', 'Fingerprint Taken Date', 810, 815),
    ('nafis_fingerprint', 'NAFIS Fingerprint Date', 820, 825),
]
# Mobile Spot Recording: (key, old order, new order)
MOVED = [
    ('mobile_spot_recording', 821, 830),
    ('mobile_spot_recording_date', 822, 835),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    for key, label, _, order in DATES:
        FieldTemplateField.objects.update_or_create(
            template=tmpl, field_key=key + '_date',
            defaults={
                'field_label': label, 'field_source': 'common', 'field_type': 'date',
                'is_required': False, 'section': SECTION, 'display_order': order,
                'options_source': None, 'parent_field_key': None,
                # Shown while the checkbox is ticked
                'depends_on_field_key': key, 'depends_on_value': None,
            },
        )
    for key, _, new in MOVED:
        FieldTemplateField.objects.filter(template=tmpl, field_key=key).update(display_order=new)


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    fields.filter(field_key__in=[key + '_date' for key, *_ in DATES]).delete()
    for key, old, _ in MOVED:
        fields.filter(field_key=key).update(display_order=old)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0170_common_form_mobile_numbers'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
