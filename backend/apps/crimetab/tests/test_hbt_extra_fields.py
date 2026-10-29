import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import CaseCategory, CaseExtraFieldValue, CategoryFieldTemplate, FieldTemplate, OptionValue
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities

TEMPLATE = 'HBT Extra Fields'


class HbtExtraFieldTests(TestCase):
    """HBT theft type, stolen and recovered property come from a database template; answers are table rows."""

    def setUp(self):
        self.hbt = CaseCategory.objects.filter(category_code='105').first() or \
            CaseCategory.objects.create(category_name='HBT', category_code='105')
        importlib.import_module('apps.crimetab.migrations.0153_hbt_extra_fields').forwards(django_apps, None)
        self.tmpl = FieldTemplate.objects.get(template_name=TEMPLATE)

    def test_form_definition_has_hbt_fields(self):
        self.assertTrue(CategoryFieldTemplate.objects.filter(category=self.hbt, template=self.tmpl).exists())
        fields = {f['field_key']: f for f in get_form_definition(self.hbt.category_id)['fields']}
        self.assertEqual(fields['hbt_theft_types']['field_type'], 'multi_select')
        self.assertEqual(fields['hbt_stolen_total_value']['options_source'], 'sum:hbt_stolen_props.hbt_stolen_value')
        required = {k for k, f in fields.items() if k.startswith('hbt_') and f['is_required']}
        self.assertEqual(required, {'hbt_stolen_name', 'hbt_stolen_value', 'hbt_recovered_name',
                                    'hbt_recovered_datetime', 'hbt_recovered_from'})

    def test_theft_types_have_no_commas(self):
        options = list(OptionValue.objects.filter(option_group='hbt_theft_types').values_list('option_value', flat=True))
        self.assertEqual(len(options), 10)
        self.assertFalse([o for o in options if ',' in o])

    def test_values_saved_as_table_rows_and_loaded_back(self):
        values = {
            'hbt_theft_types': ['Precious Metal / Jewellery', 'Cash'],
            'hbt_stolen_props': [
                {'hbt_stolen_name': 'Gold Necklace', 'hbt_stolen_description': '25 g', 'hbt_stolen_value': '150000'},
                {'hbt_stolen_name': 'Cash', 'hbt_stolen_value': '20000'},
            ],
            'hbt_stolen_total_value': '170000',
            'hbt_recovered_props': [
                {'hbt_recovered_name': 'Gold Necklace', 'hbt_recovered_datetime': '29/10/2026 16:00',
                 'hbt_recovered_from': 'Accused Ravi', 'hbt_recovered_value': '150000',
                 'hbt_recovered_return_to_owner': 'Yes', 'hbt_recovered_given_to': 'Complainant Asha'},
            ],
        }
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='HBT_TEST_1', case_number='CR/HBT_TEST_1', title='TEST HBT', sub_category='HBT',
                module_key='form_1_5', station_name='TEST Station', extra_fields={**values, 'keep_me': 'yes'})
            _save_case_child_entities(case, {**values, 'extra_fields': {**values, 'keep_me': 'yes'}})

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows[('hbt_theft_types', 1)], 'Cash')
            self.assertEqual(rows[('hbt_stolen_name', 1)], 'Cash')
            self.assertEqual(rows[('hbt_recovered_return_to_owner', 0)], 'Yes')

            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertEqual(table_values_for_case(case), values)
