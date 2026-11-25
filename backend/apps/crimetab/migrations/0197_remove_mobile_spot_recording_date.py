from django.db import migrations

"""
Migration 0197: Mobile Spot Recording has no date (data only)

The Common Form's "Mobile Spot Recording Date" field is removed, so ticking
Mobile Spot Recording (Evidence) no longer shows a date. The tick box itself
stays. Dates already saved in case records are left as they are; they are
just no longer shown on the form.

Backwards puts the date field back as it was (Evidence, order 835, shown
while Mobile Spot Recording is ticked). Idempotent.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
KEY = 'mobile_spot_recording_date'


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=KEY).delete()


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    FieldTemplateField.objects.get_or_create(
        template=tmpl,
        field_key=KEY,
        defaults={
            'field_label': 'Mobile Spot Recording Date',
            'field_source': 'custom',
            'field_type': 'date',
            'is_required': False,
            'section': 'Evidence',
            'display_order': 835,
            'depends_on_field_key': 'mobile_spot_recording',
            'depends_on_value': None,
        },
    )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0196_complainant_occupation_after_caste'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
