from django.db import migrations

"""
Migration 0078: MPDA Crime Chart order: Miscellaneous, Serious, then Total

Total Crime is calculated from the two fields before it, so it comes last.
Uses the same three slots (270 / 280 / 285), so nothing else moves.
"""

TEMPLATE_NAME = 'MPDA Proposal Template'
NEW_ORDER = {
    'mpda_total_misc_crime': 270,
    'mpda_serious_crimes': 280,
    'mpda_total_crime': 285,
}
OLD_ORDER = {
    'mpda_total_crime': 270,
    'mpda_serious_crimes': 280,
    'mpda_total_misc_crime': 285,
}


def _apply(order):
    def run(apps, schema_editor):
        FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
        for key, pos in order.items():
            FieldTemplateField.objects.filter(
                template__template_name=TEMPLATE_NAME, field_key=key
            ).update(display_order=pos)
    return run


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0077_mpda_total_crime_sum'),
    ]

    operations = [
        migrations.RunPython(_apply(NEW_ORDER), reverse_code=_apply(OLD_ORDER)),
    ]
