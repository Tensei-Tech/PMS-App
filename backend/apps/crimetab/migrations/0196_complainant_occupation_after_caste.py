from django.db import migrations

"""
Migration 0196: Complainant Occupation moves after Caste (data only)

The Complainant card now reads Name, Age, Gender, Mobile, Aadhaar, PAN,
Religion, Caste, Occupation, Address. Only Occupation's display_order
changes: it goes just after Caste. Backwards puts it back just before Mobile.
Idempotent.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'


def _fields(apps):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    rows = FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME,
        field_key__in=['complainant_occupation', 'complainant_mobile',
                       'complainant_caste'],
    )
    return {f.field_key: f for f in rows}


def _move(apps, anchor_key, offset):
    by_key = _fields(apps)
    occ = by_key.get('complainant_occupation')
    anchor = by_key.get(anchor_key)
    if occ is None or anchor is None:
        return
    # Orders are spaced by 10, so +/- 5 sits between two neighbours
    occ.display_order = anchor.display_order + offset
    occ.save(update_fields=['display_order'])


def forwards(apps, schema_editor):
    _move(apps, 'complainant_caste', 5)


def backwards(apps, schema_editor):
    _move(apps, 'complainant_mobile', -5)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0195_tab_category_links_and_labels'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
