from django.db import migrations

"""
Migration 0062: move the three Common Form Yes/No fields (data only)

- Vehicle Log Book Entry  -> section "Crime Spot" (after its fields, 40-70)
- Witness Summons          -> section "CCTV and CDR Investigation" (after 700-720)
- Mobile Spot Recording    -> section "CCTV and CDR Investigation"

The temporary section "Investigation Steps" (0061) is left empty.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'

# field_key: (new section, new order, old section, old order)
MOVES = {
    'vehicle_log_book_entry': ('Crime Spot', 71, 'Investigation Steps', 791),
    'witness_summons': ('CCTV and CDR Investigation', 721, 'Investigation Steps', 792),
    'mobile_spot_recording': ('CCTV and CDR Investigation', 722, 'Investigation Steps', 793),
}


def _move(apps, forward):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for key, (nsec, nord, osec, oord) in MOVES.items():
        sec, order = (nsec, nord) if forward else (osec, oord)
        FieldTemplateField.objects.filter(
            template__template_name=TEMPLATE_NAME, field_key=key
        ).update(section=sec, display_order=order)


def forwards(apps, schema_editor):
    _move(apps, True)


def backwards(apps, schema_editor):
    _move(apps, False)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0061_common_form_investigation_steps_and_preventive_number'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
