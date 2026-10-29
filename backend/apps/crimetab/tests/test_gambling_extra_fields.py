import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import CaseCategory, CaseExtraFieldValue, CategoryFieldTemplate, FieldTemplate, OptionValue
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities

TEMPLATE = 'Gambling Extra Fields'


class GamblingExtraFieldTests(TestCase):
    """Gambling search-warrant fields come from a database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.gambling = CaseCategory.objects.filter(category_code='603').first() or \
            CaseCategory.objects.create(category_name='Gambling', category_code='603')
        importlib.import_module('apps.crimetab.migrations.0149_gambling_extra_fields').forwards(django_apps, None)
        self.tmpl = FieldTemplate.objects.get(template_name=TEMPLATE)

    def test_form_definition_has_gambling_fields(self):
        self.assertTrue(CategoryFieldTemplate.objects.filter(category=self.gambling, template=self.tmpl).exists())
        keys = {f['field_key'] for f in get_form_definition(self.gambling.category_id)['fields']}
        for key in ('gmb_warrant_type', 'gmb_warrant_issued_by_name', 'gmb_warrant_issued_by_designation',
                    'gmb_spot_type', 'gmb_owner_name', 'gmb_owner_pan', 'gmb_owner_address',
                    'gmb_search_place_address', 'gmb_electricity_bill_taken', 'gmb_water_bill_taken',
                    'gmb_address_proof_details'):
            self.assertIn(key, keys)

    def test_choice_lists(self):
        def options(group):
            return list(OptionValue.objects.filter(option_group=group).order_by('display_order')
                        .values_list('option_value', flat=True))
        self.assertEqual(options('gambling_warrant_types'), ['Search Warrant'])
        self.assertEqual(options('gambling_warrant_issuers'), ['SDPO', 'ACP'])
        self.assertEqual(options('gambling_spot_types'), ['Close', 'Open'])

    def test_values_saved_as_table_rows_and_loaded_back(self):
        values = {
            'gmb_warrant_type': 'Search Warrant', 'gmb_warrant_issued_by_name': 'R. Kulkarni',
            'gmb_warrant_issued_by_designation': 'SDPO', 'gmb_spot_type': 'Close',
            'gmb_owner_name': 'Mahesh Gawande', 'gmb_owner_age': '47', 'gmb_owner_gender': 'Male',
            'gmb_owner_address': 'Gandhi Nagar, Wardha',
            'gmb_search_place_address': 'Shed behind Gandhi Nagar market',
            'gmb_electricity_bill_taken': 'Yes', 'gmb_water_bill_taken': 'No',
        }
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='GMB_TEST_1', case_number='CR/GMB_TEST_1', title='TEST GAMBLING', sub_category='Gambling',
                module_key='form_1_5', station_name='TEST Station', extra_fields={**values, 'keep_me': 'yes'})
            _save_case_child_entities(case, {**values, 'extra_fields': {**values, 'keep_me': 'yes'}})

            rows = {v.field_def.field_key: v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows, values)

            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertEqual(table_values_for_case(case), values)
