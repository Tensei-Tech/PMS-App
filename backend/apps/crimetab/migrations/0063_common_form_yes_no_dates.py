from django.db import migrations

"""
Migration 0063: a Date under each Common Form Yes/No field, shown only on "Yes" (data only)

- Vehicle Log Book Entry Date   (Crime Spot, after Vehicle Log Book Entry)
- Witness Summons Date          (CCTV and CDR Investigation, after Witness Summons)
- Mobile Spot Recording Date    (CCTV and CDR Investigation, after Mobile Spot Recording)

Each date uses depends_on_field_key / depends_on_value = 'Yes', so the form shows
it only when the answer is Yes. All optional. Idempotent.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
YES = 'Yes'

# (label, key, section, order, parent key)
DATE_FIELDS = [
    ('Vehicle Log Book Entry Date', 'vehicle_log_book_entry_date', 'Crime Spot', 72, 'vehicle_log_book_entry'),
    ('Witness Summons Date', 'witness_summons_date', 'CCTV and CDR Investigation', 722, 'witness_summons'),
    ('Mobile Spot Recording Date', 'mobile_spot_recording_date', 'CCTV and CDR Investigation', 724, 'mobile_spot_recording'),
]
# Mobile Spot Recording moves from 722 to 723 so each date sits right after its question
REORDER = {'mobile_spot_recording': (723, 722)}


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    for key, (new_order, _old) in REORDER.items():
        FieldTemplateField.objects.filter(template=tmpl, field_key=key).update(display_order=new_order)
    for label, key, section, order, parent in DATE_FIELDS:
        FieldTemplateField.objects.get_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': 'date',
                'is_required': False,
                'section': section,
                'display_order': order,
                'depends_on_field_key': parent,
                'depends_on_value': YES,
            },
        )


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key__in=[k for _, k, _, _, _ in DATE_FIELDS]
    ).delete()
    for key, (_new, old_order) in REORDER.items():
        FieldTemplateField.objects.filter(
            template__template_name=TEMPLATE_NAME, field_key=key
        ).update(display_order=old_order)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0062_move_common_form_yes_no_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
