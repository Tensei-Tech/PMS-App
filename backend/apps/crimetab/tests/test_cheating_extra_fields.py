from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import (
    CaseCategory,
    CaseExtraFieldValue,
    CategoryFieldTemplate,
    FieldTemplate,
    FieldTemplateField,
)
from apps.crimetab.serializers import FullCaseDetailSerializer
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.views import _save_case_child_entities


class CheatingExtraFieldTests(TestCase):
    """Cheating extra fields come from the database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.cat = CaseCategory.objects.filter(category_code='109').first() or \
            CaseCategory.objects.create(category_name='Cheating', category_code='109')
        self.tmpl = FieldTemplate.objects.filter(template_name='Cheating Extra Fields').first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0137_cheating_extra_fields')
            from django.apps import apps as django_apps
            mig.forwards(django_apps, None)
            self.tmpl = FieldTemplate.objects.filter(template_name='Cheating Extra Fields').first()
        CategoryFieldTemplate.objects.get_or_create(category=self.cat, template=self.tmpl)

    def _case(self, cid):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title='TEST', sub_category='Cheating',
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def _payload(self):
        values = {
            'cheating_cash': 'Yes',
            'cheating_cash_amount': '50000',
            'cheating_online_send': 'Yes',
            'cheating_online_amount': '75000',
            'cheating_bank_withdraw': 'No',
            'cheating_bank_withdraw_amount': '',
            'cheating_total_value': '125000',
            'cheating_victim_count': '10',
            'cheating_victims': [
                {'cheating_victim_name': 'Ramesh Kumar', 'cheating_victim_age': '35', 'cheating_victim_gender': 'Male'},
                {'cheating_victim_name': 'Sita Devi', 'cheating_victim_age': '28', 'cheating_victim_gender': 'Female'},
            ],
        }
        return {**values, 'extra_fields': {**values, 'keep_me': 'yes', 'extra_field_values': dict(values)}}

    def test_form_definition_has_cheating_fields(self):
        keys = {f['field_key'] for f in get_form_definition(self.cat.category_id)['fields']}
        self.assertIn('cheating_cash', keys)
        self.assertIn('cheating_cash_amount', keys)
        self.assertIn('cheating_online_send', keys)
        self.assertIn('cheating_online_amount', keys)
        self.assertIn('cheating_bank_withdraw', keys)
        self.assertIn('cheating_bank_withdraw_amount', keys)
        self.assertIn('cheating_total_value', keys)
        self.assertIn('cheating_victim_count', keys)
        self.assertIn('cheating_victims', keys)
        self.assertIn('cheating_victim_name', keys)
        self.assertIn('cheating_victim_age', keys)
        self.assertIn('cheating_victim_gender', keys)

    def test_values_saved_as_table_rows_and_loaded_back(self):
        with TenantContext('maharashtra'):
            payload = self._payload()
            case = self._case('CHEAT_TEST_1')
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows.get(('cheating_cash', 0)), 'Yes')
            self.assertEqual(rows.get(('cheating_cash_amount', 0)), '50000')
            self.assertEqual(rows.get(('cheating_online_send', 0)), 'Yes')
            self.assertEqual(rows.get(('cheating_online_amount', 0)), '75000')
            self.assertEqual(rows.get(('cheating_bank_withdraw', 0)), 'No')
            self.assertEqual(rows.get(('cheating_total_value', 0)), '125000')
            self.assertEqual(rows.get(('cheating_victim_count', 0)), '10')
            self.assertEqual(rows.get(('cheating_victim_name', 0)), 'Ramesh Kumar')
            self.assertEqual(rows.get(('cheating_victim_age', 0)), '35')
            self.assertEqual(rows.get(('cheating_victim_gender', 0)), 'Male')
            self.assertEqual(rows.get(('cheating_victim_name', 1)), 'Sita Devi')
            self.assertEqual(rows.get(('cheating_victim_age', 1)), '28')
            self.assertEqual(rows.get(('cheating_victim_gender', 1)), 'Female')

            # Cleared from JSON
            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('cheating_')})

            # Loaded back in the shape the form expects
            from apps.crimetab.services.table_field_values import table_values_for_case
            extra = table_values_for_case(case)
            self.assertEqual(extra['cheating_cash'], 'Yes')
            self.assertEqual(extra['cheating_cash_amount'], '50000')
            self.assertEqual(extra['cheating_online_send'], 'Yes')
            self.assertEqual(extra['cheating_online_amount'], '75000')
            self.assertEqual(extra['cheating_bank_withdraw'], 'No')
            self.assertEqual(extra['cheating_total_value'], '125000')
            self.assertEqual(extra['cheating_victim_count'], '10')
            self.assertEqual(len(extra['cheating_victims']), 2)
            self.assertEqual(extra['cheating_victims'][0]['cheating_victim_name'], 'Ramesh Kumar')
            self.assertEqual(extra['cheating_victims'][1]['cheating_victim_name'], 'Sita Devi')


class CoinExtraFieldTests(TestCase):
    """Coin categories (128 and STAND_COIN) share Cheating Extra Fields."""

    def setUp(self):
        self.tmpl = FieldTemplate.objects.filter(template_name='Cheating Extra Fields').first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0137_cheating_extra_fields')
            from django.apps import apps as django_apps
            mig.forwards(django_apps, None)
            self.tmpl = FieldTemplate.objects.filter(template_name='Cheating Extra Fields').first()

        self.cat_128 = CaseCategory.objects.filter(category_code='128').first() or \
            CaseCategory.objects.create(category_name='Coin', category_code='128')
        self.cat_stand = CaseCategory.objects.filter(category_code='STAND_COIN').first() or \
            CaseCategory.objects.create(category_name='Coin', category_code='STAND_COIN')

        CategoryFieldTemplate.objects.get_or_create(category=self.cat_128, template=self.tmpl)
        CategoryFieldTemplate.objects.get_or_create(category=self.cat_stand, template=self.tmpl)

    def test_form_definition_has_coin_fields(self):
        if self.cat_128:
            keys_128 = {f['field_key'] for f in get_form_definition(self.cat_128.category_id)['fields']}
            self.assertIn('cheating_cash', keys_128)
            self.assertIn('cheating_victim_count', keys_128)
            self.assertIn('cheating_victims', keys_128)

        if self.cat_stand:
            keys_stand = {f['field_key'] for f in get_form_definition(self.cat_stand.category_id)['fields']}
            self.assertIn('cheating_cash', keys_stand)
            self.assertIn('cheating_victim_count', keys_stand)
            self.assertIn('cheating_victims', keys_stand)

    def test_coin_case_values_saved_and_loaded(self):
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='COIN_TEST_1', case_number='CR/COIN_1', title='COIN TEST', sub_category='Coin',
                module_key='form_1_5', station_name='TEST Station', extra_fields={}
            )
            payload = {
                'cheating_cash': 'Yes',
                'cheating_cash_amount': '20000',
                'cheating_online_send': 'No',
                'cheating_bank_withdraw': 'Yes',
                'cheating_bank_withdraw_amount': '30000',
                'cheating_total_value': '50000',
                'cheating_victim_count': '5',
                'cheating_victims': [
                    {'cheating_victim_name': 'Anita Roy', 'cheating_victim_age': '30', 'cheating_victim_gender': 'Female'},
                ],
            }
            payload['extra_fields'] = {**payload, 'extra_field_values': dict(payload)}
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            from apps.crimetab.services.table_field_values import table_values_for_case
            extra = table_values_for_case(case)
            self.assertEqual(extra['cheating_cash'], 'Yes')
            self.assertEqual(extra['cheating_cash_amount'], '20000')
            self.assertEqual(extra['cheating_bank_withdraw'], 'Yes')
            self.assertEqual(extra['cheating_bank_withdraw_amount'], '30000')
            self.assertEqual(extra['cheating_total_value'], '50000')
            self.assertEqual(extra['cheating_victim_count'], '5')
            self.assertEqual(len(extra['cheating_victims']), 1)
            self.assertEqual(extra['cheating_victims'][0]['cheating_victim_name'], 'Anita Roy')


class ExtortionExtraFieldTests(TestCase):
    """Extortion category (114) shares Cheating Extra Fields."""

    def setUp(self):
        self.tmpl = FieldTemplate.objects.filter(template_name='Cheating Extra Fields').first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0137_cheating_extra_fields')
            from django.apps import apps as django_apps
            mig.forwards(django_apps, None)
            self.tmpl = FieldTemplate.objects.filter(template_name='Cheating Extra Fields').first()

        self.cat_114 = CaseCategory.objects.filter(category_code='114').first() or \
            CaseCategory.objects.create(category_name='Extortion', category_code='114')

        CategoryFieldTemplate.objects.get_or_create(category=self.cat_114, template=self.tmpl)

    def test_form_definition_has_extortion_fields(self):
        keys = {f['field_key'] for f in get_form_definition(self.cat_114.category_id)['fields']}
        self.assertIn('cheating_cash', keys)
        self.assertIn('cheating_victim_count', keys)
        self.assertIn('cheating_victims', keys)

    def test_extortion_case_values_saved_and_loaded(self):
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='EXTORT_TEST_1', case_number='CR/EXTORT_1', title='EXTORT TEST', sub_category='Extortion',
                module_key='form_1_5', station_name='TEST Station', extra_fields={}
            )
            payload = {
                'cheating_cash': 'Yes',
                'cheating_cash_amount': '100000',
                'cheating_online_send': 'Yes',
                'cheating_online_amount': '50000',
                'cheating_bank_withdraw': 'No',
                'cheating_total_value': '150000',
                'cheating_victim_count': '3',
                'cheating_victims': [
                    {'cheating_victim_name': 'Vikram Singh', 'cheating_victim_age': '42', 'cheating_victim_gender': 'Male'},
                ],
            }
            payload['extra_fields'] = {**payload, 'extra_field_values': dict(payload)}
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            from apps.crimetab.services.table_field_values import table_values_for_case
            extra = table_values_for_case(case)
            self.assertEqual(extra['cheating_cash'], 'Yes')
            self.assertEqual(extra['cheating_cash_amount'], '100000')
            self.assertEqual(extra['cheating_online_send'], 'Yes')
            self.assertEqual(extra['cheating_online_amount'], '50000')
            self.assertEqual(extra['cheating_bank_withdraw'], 'No')
            self.assertEqual(extra['cheating_total_value'], '150000')
            self.assertEqual(extra['cheating_victim_count'], '3')
            self.assertEqual(len(extra['cheating_victims']), 1)
            self.assertEqual(extra['cheating_victims'][0]['cheating_victim_name'], 'Vikram Singh')


