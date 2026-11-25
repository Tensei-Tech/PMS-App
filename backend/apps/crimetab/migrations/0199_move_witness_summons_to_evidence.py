from django.db import migrations

"""
Migration 0199: Witness Summons moves to Evidence (data only)

The Common Form's Witness Summons tick box moves from "CCTV and CDR
Investigation" to the end of "Evidence", after Mobile Spot Recording (830).
Its date field, if a template still has one, moves with it. Saved case values
are untouched (same field keys).

Backwards puts it back in "CCTV and CDR Investigation" at order 723
(date 724), where 0107 left it. Idempotent.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
CCTV = 'CCTV and CDR Investigation'
EVIDENCE = 'Evidence'

# key: (old section, old order, new section, new order)
MOVES = {
    'witness_summons': (CCTV, 723, EVIDENCE, 840),
    'witness_summons_date': (CCTV, 724, EVIDENCE, 845),
}


def _move(apps, to_new):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    for key, (old_sec, old_order, new_sec, new_order) in MOVES.items():
        section, order = (new_sec, new_order) if to_new else (old_sec, old_order)
        fields.filter(field_key=key).update(section=section, display_order=order)


def forwards(apps, schema_editor):
    _move(apps, to_new=True)


def backwards(apps, schema_editor):
    _move(apps, to_new=False)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0198_murder_post_mortem_checkboxes'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
