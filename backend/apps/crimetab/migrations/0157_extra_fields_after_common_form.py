from django.db import migrations

"""
Migration 0157: The new extra-field templates come after the common form (data only)

The form sorts the fields of all linked templates together by display_order.
The common form uses 10-1090; these templates used numbers in the same range,
so their sections showed in between the common form's. Like Chain Snatching,
Theft and Kidnapping / Missing (0156), they now start at 2000 and keep their
own order. Non-Applicant Details starts at 3000 so it follows the Hurt fields
on Assault on Public Servant, which has both.

The older Gowansh, MV Act, POCSO, Sand Theft, Vehicle Theft and Road Accident
templates are left as they are.

Idempotent: only fields still below 2000 move.
"""

THRESHOLD = 2000
OFFSETS = {
    'Murder Section Extra Fields': 2000,
    'Crime Against Women Extra Fields': 2000,
    'Cheating Extra Fields': 2000,
    'Hurt Extra Fields': 2000,
    'Mischief Extra Fields': 2000,
    'Attempt to Murder Extra Fields': 2000,
    'Robbery / Dacoity Extra Fields': 2000,
    'Non-Applicant Details': 3000,
    'Normal Accident Extra Fields': 2000,
    'Prohibition Extra Fields': 2000,
    'Gambling Extra Fields': 2000,
    'CBT Extra Fields': 2000,
    'HBT Extra Fields': 2000,
}


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for name, offset in OFFSETS.items():
        for f in FieldTemplateField.objects.filter(template__template_name=name, display_order__lt=THRESHOLD):
            f.display_order += offset
            f.save(update_fields=['display_order'])


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for name, offset in OFFSETS.items():
        for f in FieldTemplateField.objects.filter(template__template_name=name, display_order__gte=offset):
            f.display_order -= offset
            f.save(update_fields=['display_order'])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0156_kidnapping_missing_fields_after_common_form'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
