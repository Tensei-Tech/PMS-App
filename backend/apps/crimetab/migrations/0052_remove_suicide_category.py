from django.db import migrations

"""
Migration 0052: Remove the standalone "Suicide" tab

Deletes the 'Suicide' (STAND_SUICIDE) row from public.case_categories together with
anything linked to it (template links, field overrides, tenant case_category_links).
No case records were stored under this tab when it was removed.

Reverse re-creates the bare category row (no template), as it was seeded.
"""


def remove_suicide(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    CategoryFieldOverride = apps.get_model('crimetab', 'CategoryFieldOverride')

    cats = CaseCategory.objects.filter(category_code='STAND_SUICIDE', category_name='Suicide')
    cat_ids = list(cats.values_list('category_id', flat=True))
    if not cat_ids:
        return

    CategoryFieldTemplate.objects.filter(category_id__in=cat_ids).delete()
    CategoryFieldOverride.objects.filter(category_id__in=cat_ids).delete()

    if schema_editor.connection.vendor == 'postgresql':
        with schema_editor.connection.cursor() as cursor:
            cursor.execute(
                "SELECT table_schema FROM information_schema.tables WHERE table_name = 'case_category_links'"
            )
            for (schema,) in cursor.fetchall():
                cursor.execute(
                    f'DELETE FROM "{schema}".case_category_links WHERE category_id = ANY(%s)', [cat_ids]
                )

    cats.delete()


def restore_suicide(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CaseCategory.objects.get_or_create(
        category_code='STAND_SUICIDE',
        defaults={
            'category_name': 'Suicide',
            'group': None,
            'parent_category': None,
            'template': None,
            'is_active': True,
            'display_order': 39,
        },
    )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0051_preventive_action_types_from_option_values'),
    ]

    operations = [
        migrations.RunPython(remove_suicide, reverse_code=restore_suicide),
    ]
