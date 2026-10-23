from django.db import migrations

"""
Migration 0065: remove the standalone "ST Drugs" tab (STAND_ST_DRUGS)

ST Drugs stays only under Part 6 (category code '601', group 2), which is not
touched. The standalone row had no cases and no case links; its template link
is removed with it. Existing ST Drugs cases are saved under form_1_5 / form_6
with sub_category 'ST Drugs' and keep showing under Part 6.

Reverse re-creates the standalone row and its link to the Common Form baseline.
"""

STANDALONE_CODE = 'STAND_ST_DRUGS'
BASELINE_TEMPLATE = 'Common Form Baseline Template'


def remove_standalone(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    CategoryFieldOverride = apps.get_model('crimetab', 'CategoryFieldOverride')

    cats = CaseCategory.objects.filter(category_code=STANDALONE_CODE, group__isnull=True)
    ids = list(cats.values_list('category_id', flat=True))
    if not ids:
        return
    CategoryFieldTemplate.objects.filter(category_id__in=ids).delete()
    CategoryFieldOverride.objects.filter(category_id__in=ids).delete()
    if schema_editor.connection.vendor == 'postgresql':
        with schema_editor.connection.cursor() as cursor:
            cursor.execute(
                "SELECT table_schema FROM information_schema.tables WHERE table_name = 'case_category_links'"
            )
            for (schema,) in cursor.fetchall():
                cursor.execute(
                    f'DELETE FROM "{schema}".case_category_links WHERE category_id = ANY(%s)', [ids]
                )
    cats.delete()


def restore_standalone(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    cat, _ = CaseCategory.objects.get_or_create(
        category_code=STANDALONE_CODE,
        defaults={'category_name': 'ST Drugs', 'group': None, 'parent_category': None,
                  'template': None, 'is_active': True, 'display_order': 51},
    )
    tmpl = FieldTemplate.objects.filter(template_name=BASELINE_TEMPLATE).first()
    if tmpl is not None:
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0064_move_vehicle_log_book_to_cctv'),
    ]

    operations = [
        migrations.RunPython(remove_standalone, reverse_code=restore_standalone),
    ]
