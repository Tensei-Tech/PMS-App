import importlib

from django.db import migrations
from django.db.models import Q

"""
Migration 0154: Remove the Kidnapping and Missing sub-tabs from "1 to 5" (data only)

1. In every state schema, deletes the cases filed under those sub-tabs
   (module_key 'form_1_5' with sub category Kidnapping / Missing, or linked to
   either sub-tab) together with everything that belongs to them (Django's
   delete cascade, as when a case is deleted in the app).
2. Deletes the two categories: Kidnapping (code 120) and Missing (code 124),
   with their template links.

The standalone Kidnapping (STAND_KIDNAP) and Missing (STAND_MISSING) tabs,
their cases and the "Kidnapping / Missing Extra Fields" template stay.

Permanent: there is nothing to restore on reverse.
"""

CATEGORY_CODES = ('120', '124')
SUB_CATEGORIES = ('Kidnapping', 'Missing')
MODULE_KEY = 'form_1_5'

tenant_schemas = importlib.import_module(
    'apps.crimetab.migrations.0133_tenant_module_tables_and_id_sequences'
).tenant_schemas


def cases_to_delete(category_ids):
    """The 1-to-5 Kidnapping / Missing cases in the current schema."""
    from apps.cases.models import CaseRecord

    by_name = Q()
    for name in SUB_CATEGORIES:
        by_name |= Q(sub_category__iexact=name)
    return CaseRecord.objects.filter(
        (Q(module_key=MODULE_KEY) & by_name) | Q(category_links__category_id__in=category_ids)
    ).distinct()


def _delete_cases(category_ids):
    ids = list(cases_to_delete(category_ids).values_list('pk', flat=True))
    if ids:
        from apps.cases.models import CaseRecord
        CaseRecord.objects.filter(pk__in=ids).delete()


def forwards(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    categories = CaseCategory.objects.filter(category_code__in=CATEGORY_CODES)
    category_ids = list(categories.values_list('pk', flat=True))

    if schema_editor.connection.vendor != 'postgresql':
        _delete_cases(category_ids)
        categories.delete()
        return

    from apps.core.tenancy import TenantContext
    with schema_editor.connection.cursor() as cursor:
        schemas = tenant_schemas(cursor)
    for schema in schemas:
        with TenantContext(schema):
            _delete_cases(category_ids)

    # Case links live in the state schemas (gone with their cases), so the
    # categories are deleted without Django's collector, which would look for
    # case_category_links in public.
    if category_ids:
        with schema_editor.connection.cursor() as cursor:
            cursor.execute('DELETE FROM public.category_field_templates WHERE category_id = ANY(%s)', [category_ids])
            cursor.execute('DELETE FROM public.category_field_overrides WHERE category_id = ANY(%s)', [category_ids])
            cursor.execute('DELETE FROM public.case_categories WHERE category_id = ANY(%s)', [category_ids])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0153_hbt_extra_fields'),
        ('cases', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=migrations.RunPython.noop),
    ]
