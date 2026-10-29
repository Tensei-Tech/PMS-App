from django.db import migrations

"""
Migration 0156: Kidnapping / Missing extra fields come after the common form (data only)

The form sorts the fields of all linked templates together by display_order.
The common form uses 10-1090 and the "Kidnapping / Missing Extra Fields" (0144)
used 10-49, so its sections showed in between the common form's. Like the
Chain Snatching and Theft templates, they now start at 2000 (2010-2049), after
the whole common form, keeping their own order.

Idempotent: only fields still below 2000 move.
"""

TEMPLATE_NAME = 'Kidnapping / Missing Extra Fields'
OFFSET = 2000


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for f in FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME, display_order__lt=OFFSET):
        f.display_order += OFFSET
        f.save(update_fields=['display_order'])


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for f in FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME, display_order__gte=OFFSET):
        f.display_order -= OFFSET
        f.save(update_fields=['display_order'])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0155_kidnapping_missing_1_to_5_tab'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
