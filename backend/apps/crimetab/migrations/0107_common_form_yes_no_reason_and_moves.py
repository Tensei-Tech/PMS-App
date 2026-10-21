from django.db import migrations

"""
Migration 0107: Common Form Yes/No fields move; Vehicle Log Book gets a Reason (data only)

- Vehicle Log Book Entry (with its Date) moves from "CCTV and CDR Investigation"
  to its own section "Vehicle Log Book", right below "All Panchnama", and gets
  a Reason (text) after its Date. Like the Date, the Reason shows only when the
  answer is "Yes" (depends_on_value = 'Yes'). Optional.
- Witness Summons stays in "CCTV and CDR Investigation", right after CDR
  Received Date, with no Date: Witness Summons Date (0063) is removed.
- Mobile Spot Recording (with its Date) moves to the end of "Evidence".

New order:
  CCTV and CDR   721 Witness Summons
  Vehicle Log Book  791 Vehicle Log Book Entry, 792 Date, 793 Reason
  Evidence       821 Mobile Spot Recording,  822 Date
Idempotent.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
CCTV = 'CCTV and CDR Investigation'
LOG_BOOK = 'Vehicle Log Book'
EVIDENCE = 'Evidence'
YES = 'Yes'

# field_key: (new section, new order, old section, old order)
MOVES = {
    'vehicle_log_book_entry': (LOG_BOOK, 791, CCTV, 721),
    'vehicle_log_book_entry_date': (LOG_BOOK, 792, CCTV, 722),
    'witness_summons': (CCTV, 721, CCTV, 723),
    'mobile_spot_recording': (EVIDENCE, 821, CCTV, 725),
    'mobile_spot_recording_date': (EVIDENCE, 822, CCTV, 726),
}

# (label, key, section, order, parent key)
REASON_FIELDS = [
    ('Vehicle Log Book Entry Reason', 'vehicle_log_book_entry_reason', LOG_BOOK, 793, 'vehicle_log_book_entry'),
]

# Removed here; recreated as 0063 made it when going backwards
WITNESS_DATE = ('Witness Summons Date', 'witness_summons_date', CCTV, 724, 'witness_summons')


def _move(apps, forward):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for key, (nsec, nord, osec, oord) in MOVES.items():
        sec, order = (nsec, nord) if forward else (osec, oord)
        FieldTemplateField.objects.filter(
            template__template_name=TEMPLATE_NAME, field_key=key
        ).update(section=sec, display_order=order)


def _create(FieldTemplateField, tmpl, field_type, label, key, section, order, parent):
    FieldTemplateField.objects.get_or_create(
        template=tmpl,
        field_key=key,
        defaults={
            'field_label': label,
            'field_source': 'custom',
            'field_type': field_type,
            'is_required': False,
            'section': section,
            'display_order': order,
            'depends_on_field_key': parent,
            'depends_on_value': YES,
        },
    )


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    _move(apps, True)
    for field in REASON_FIELDS:
        _create(FieldTemplateField, tmpl, 'text', *field)
    FieldTemplateField.objects.filter(template=tmpl, field_key=WITNESS_DATE[1]).delete()


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key__in=[k for _, k, _, _, _ in REASON_FIELDS]
    ).delete()
    _move(apps, False)
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is not None:
        _create(FieldTemplateField, tmpl, 'date', *WITNESS_DATE)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0106_mpda_proposal_year_field_type'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
