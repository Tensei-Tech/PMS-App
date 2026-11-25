from django.db import migrations

"""
Migration 0200: CCTV Checked moves after the CDR dates (data only)

In the Common Form's "CCTV and CDR Investigation" section the CCTV Checked
tick box now comes last: CDR Sent Date (710), CDR Received Date (720),
CCTV Checked (730). Saved case values are untouched (same field key).

Backwards puts CCTV Checked back first (700). Idempotent.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
KEY = 'cctv_checked'
OLD_ORDER = 700
NEW_ORDER = 730


def _set(apps, order):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=KEY,
    ).update(display_order=order)


def forwards(apps, schema_editor):
    _set(apps, NEW_ORDER)


def backwards(apps, schema_editor):
    _set(apps, OLD_ORDER)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0199_move_witness_summons_to_evidence'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
