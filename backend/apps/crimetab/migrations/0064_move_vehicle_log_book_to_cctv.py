from django.db import migrations

"""
Migration 0064: Vehicle Log Book Entry (and its date) moves to "CCTV and CDR Investigation"

Data only. New order of the section's added fields:
  721 Vehicle Log Book Entry, 722 its Date,
  723 Witness Summons,        724 its Date,
  725 Mobile Spot Recording,  726 its Date
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
CCTV = 'CCTV and CDR Investigation'
CRIME_SPOT = 'Crime Spot'

# field_key: (new section, new order, old section, old order)
MOVES = {
    'vehicle_log_book_entry': (CCTV, 721, CRIME_SPOT, 71),
    'vehicle_log_book_entry_date': (CCTV, 722, CRIME_SPOT, 72),
    'witness_summons': (CCTV, 723, CCTV, 721),
    'witness_summons_date': (CCTV, 724, CCTV, 722),
    'mobile_spot_recording': (CCTV, 725, CCTV, 723),
    'mobile_spot_recording_date': (CCTV, 726, CCTV, 724),
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
        ('crimetab', '0063_common_form_yes_no_dates'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
