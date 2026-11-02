import importlib

from django.db import migrations

"""
Migration 0163: "Normal Accident" is now called "Other Accident" (data only)

The sub-tab beside "Road Accident" under "Accident" (codes ACC_NORMAL and
STAND_ACC_NORMAL) is renamed, and in every state schema the saved cases filed
under it get the new sub category name, so they stay under the tab.

The codes and the "Normal Accident Extra Fields" template keep their names.
Idempotent; backwards restores the old name.
"""

CATEGORY_CODES = ('ACC_NORMAL', 'STAND_ACC_NORMAL')
OLD_NAME = 'Normal Accident'
NEW_NAME = 'Other Accident'

tenant_schemas = importlib.import_module(
    'apps.crimetab.migrations.0133_tenant_module_tables_and_id_sequences'
).tenant_schemas


def _rename_cases(old, new):
    from apps.cases.models import CaseRecord
    CaseRecord.objects.filter(sub_category__iexact=old).update(sub_category=new)


def _rename(apps, schema_editor, old, new):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CaseCategory.objects.filter(category_code__in=CATEGORY_CODES).update(category_name=new)

    if schema_editor.connection.vendor != 'postgresql':
        _rename_cases(old, new)
        return

    from apps.core.tenancy import TenantContext
    with schema_editor.connection.cursor() as cursor:
        schemas = tenant_schemas(cursor)
    for schema in schemas:
        with TenantContext(schema):
            _rename_cases(old, new)


def forwards(apps, schema_editor):
    _rename(apps, schema_editor, OLD_NAME, NEW_NAME)


def backwards(apps, schema_editor):
    _rename(apps, schema_editor, NEW_NAME, OLD_NAME)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0162_ad_registration_year_io_and_sdm_acp'),
        ('cases', '0006_caserecord_disposal_date'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
