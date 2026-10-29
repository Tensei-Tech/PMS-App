import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import CaseCategory, CaseExtraFieldValue, CategoryFieldTemplate, FieldTemplate
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities

TEMPLATE = 'Prohibition Extra Fields'


class ProhibitionExtraFieldTests(TestCase):
    """Prohibition liquor seizure fields come from a database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.prohibition = CaseCategory.objects.filter(category_code='602').first() or \
            CaseCategory.objects.create(category_name='Prohibition', category_code='602')
        importlib.import_module('apps.crimetab.migrations.0148_prohibition_extra_fields').forwards(django_apps, None)
        self.tmpl = FieldTemplate.objects.get(template_name=TEMPLATE)

    def test_form_definition_has_prohibition_fields(self):
        self.assertTrue(CategoryFieldTemplate.objects.filter(category=self.prohibition, template=self.tmpl).exists())
        keys = {f['field_key'] for f in get_form_definition(self.prohibition.category_id)['fields']}
        for prefix in ('proh_homemade', 'proh_country', 'proh_foreign'):
            for suffix in ('sample_taken', 'unit', 'quantity', 'destroyed_date'):
                self.assertIn(f'{prefix}_{suffix}', keys)
        self.assertTrue({'proh_liquor_types', 'proh_section_93', 'proh_section_93_date'} <= keys)

    def test_each_liquor_shows_its_own_questions(self):
        expected = {'proh_homemade': 'Homemade Liquor', 'proh_country': 'Country Liquor (Desi Daru)',
                    'proh_foreign': 'Foreign Liquor'}
        for prefix, liquor in expected.items():
            for f in self.tmpl.fields.filter(field_key__startswith=prefix):
                self.assertEqual((f.depends_on_field_key, f.depends_on_value), ('proh_liquor_types', liquor), f.field_key)
        self.assertEqual(self.tmpl.fields.get(field_key='proh_section_93_date').depends_on_value, 'Yes')

    def test_values_saved_as_table_rows_and_loaded_back(self):
        values = {
            'proh_liquor_types': ['Country Liquor (Desi Daru)', 'Foreign Liquor'],
            'proh_country_sample_taken': 'Yes', 'proh_country_unit': 'Liter', 'proh_country_quantity': '12',
            'proh_country_destroyed_date': '30/10/2026',
            'proh_foreign_sample_taken': 'No', 'proh_foreign_unit': 'ml', 'proh_foreign_quantity': '750',
            'proh_section_93': 'Yes', 'proh_section_93_date': '29/10/2026',
        }
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='PROH_TEST_1', case_number='CR/PROH_TEST_1', title='TEST PROHIBITION', sub_category='Prohibition',
                module_key='form_1_5', station_name='TEST Station', extra_fields={**values, 'keep_me': 'yes'})
            _save_case_child_entities(case, {**values, 'extra_fields': {**values, 'keep_me': 'yes'}})

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows[('proh_liquor_types', 1)], 'Foreign Liquor')
            self.assertEqual(rows[('proh_country_unit', 0)], 'Liter')
            self.assertEqual(rows[('proh_foreign_quantity', 0)], '750')

            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertEqual(table_values_for_case(case), values)
