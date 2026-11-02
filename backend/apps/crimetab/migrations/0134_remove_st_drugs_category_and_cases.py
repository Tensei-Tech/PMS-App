from django.db import migrations

"""
Migration 0134: remove "ST Drugs" category completely from the system,
clean up any associated CategoryFieldTemplate, CategoryFieldOverride,
CaseCategoryLink, and remove obsolete test cases filed under ST Drugs.
"""


def remove_st_drugs(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    CategoryFieldOverride = apps.get_model('crimetab', 'CategoryFieldOverride')
    CaseRecord = apps.get_model('cases', 'CaseRecord')
    PreventiveActionItems = apps.get_model('crimetab', 'PreventiveActionItems')

    # 1. Clean up ST Drugs categories
    cats = CaseCategory.objects.filter(category_code__in=['601', 'STAND_ST_DRUGS']) | CaseCategory.objects.filter(category_name__iexact='ST Drugs')
    cat_ids = list(cats.values_list('category_id', flat=True))

    if cat_ids:
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

    # 2. Clean up dummy test cases filed under ST Drugs
    st_cases = CaseRecord.objects.filter(sub_category__iexact='ST Drugs') | CaseRecord.objects.filter(title__icontains='ST Drugs')
    case_ids = list(st_cases.values_list('id', flat=True))
    if case_ids:
        PreventiveActionItems.objects.filter(case_id__in=case_ids).delete()
        st_cases.delete()


def noop_reverse(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0133_tenant_module_tables_and_id_sequences'),
    ]

    operations = [
        migrations.RunPython(remove_st_drugs, noop_reverse),
    ]
