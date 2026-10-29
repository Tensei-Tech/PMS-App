import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import CaseCategory, CaseExtraFieldValue, CategoryFieldTemplate, FieldTemplate
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities

TEMPLATE = 'CBT Extra Fields'


class CbtExtraFieldTests(TestCase):
    """CBT property details come from a database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.cbt = CaseCategory.objects.filter(category_code='108').first() or \
            CaseCategory.objects.create(category_name='CBT', category_code='108')
        importlib.import_module('apps.crimetab.migrations.0150_cbt_extra_fields').forwards(django_apps, None)
        self.tmpl = FieldTemplate.objects.get(template_name=TEMPLATE)

    def test_form_definition_has_cbt_fields(self):
        self.assertTrue(CategoryFieldTemplate.objects.filter(category=self.cbt, template=self.tmpl).exists())
        fields = {f['field_key']: f for f in get_form_definition(self.cbt.category_id)['fields']}
        self.assertEqual(fields['cbt_properties']['field_type'], 'repeating_group')
        self.assertEqual(fields['cbt_property_description']['options_source'], 'words:20')
        self.assertEqual(fields['cbt_total_value']['options_source'], 'sum:cbt_properties.cbt_property_value')

    def test_values_saved_as_table_rows_and_loaded_back(self):
        values = {
            'cbt_properties': [
                {'cbt_property_description': 'Gold bangles given for safe keeping', 'cbt_property_value': '85000'},
                {'cbt_property_description': 'Cash entrusted for business', 'cbt_property_value': '40000'},
            ],
            'cbt_total_value': '125000',
        }
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='CBT_TEST_1', case_number='CR/CBT_TEST_1', title='TEST CBT', sub_category='CBT',
                module_key='form_1_5', station_name='TEST Station', extra_fields={**values, 'keep_me': 'yes'})
            _save_case_child_entities(case, {**values, 'extra_fields': {**values, 'keep_me': 'yes'}})

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows[('cbt_property_value', 1)], '40000')
            self.assertEqual(rows[('cbt_total_value', 0)], '125000')

            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertEqual(table_values_for_case(case), values)
