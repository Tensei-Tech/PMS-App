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


class ChainSnatchingExtraFieldTests(TestCase):
    """Chain Snatching extra questions come from the database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.cat = CaseCategory.objects.filter(category_code='118').first() or \
            CaseCategory.objects.create(category_name='Chain Snatching', category_code='118')
        self.tmpl = FieldTemplate.objects.filter(template_name='Chain Snatching Extra Fields').first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0136_chain_snatching_extra_fields')
            from django.apps import apps as django_apps
            mig.seed_snatching(django_apps, None)
            self.tmpl = FieldTemplate.objects.filter(template_name='Chain Snatching Extra Fields').first()
        CategoryFieldTemplate.objects.get_or_create(category=self.cat, template=self.tmpl)

    def _case(self, cid):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title='TEST', sub_category='Chain Snatching',
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def _payload(self):
        values = {
            'snatch_types': ['Precious Metal / Jewellery', 'Cash'],
            'snatch_gold': 'Yes',
            'snatch_silver': 'No',
            'snatch_platinum': 'No',
            'snatch_other_precious_metal': 'White Gold',
            'snatch_stolen_props': [
                {'snatch_stolen_name': 'Gold Chain 20g', 'snatch_stolen_description': '22K rope chain', 'snatch_stolen_value': '120000'},
                {'snatch_stolen_name': '', 'snatch_stolen_value': ''},  # dropped empty row
                {'snatch_stolen_name': 'Purse with Cash', 'snatch_stolen_description': 'Leather purse', 'snatch_stolen_value': '5000'},
            ],
            'snatch_recovered_props': [
                {'snatch_recovered_name': 'Gold Chain 20g', 'snatch_recovered_date': '2026-10-23', 'snatch_recovered_from': 'Ramesh Accused', 'snatch_recovered_return_to_owner': 'Yes'},
            ],
        }
        return {**values, 'extra_fields': {**values, 'keep_me': 'yes', 'extra_field_values': dict(values)}}

    def test_form_definition_has_chain_snatching_fields(self):
        keys = {f['field_key'] for f in get_form_definition(self.cat.category_id)['fields']}
        self.assertIn('snatch_types', keys)
        self.assertIn('snatch_gold', keys)
        self.assertIn('snatch_silver', keys)
        self.assertIn('snatch_platinum', keys)
        self.assertIn('snatch_other_precious_metal', keys)
        self.assertIn('snatch_ornaments', keys)
        self.assertIn('snatch_other_metals', keys)
        self.assertIn('snatch_diamond_stones', keys)
        self.assertIn('snatch_stolen_props', keys)
        self.assertIn('snatch_recovered_props', keys)
        self.assertIn('snatch_electronic_brand', keys)
        self.assertIn('snatch_cash_total', keys)

    def test_values_saved_as_table_rows_and_loaded_back(self):
        with TenantContext('maharashtra'):
            payload = self._payload()
            case = self._case('SNATCH_TEST_1')
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows.get(('snatch_gold', 0)), 'Yes')
            self.assertEqual(rows.get(('snatch_other_precious_metal', 0)), 'White Gold')
            self.assertEqual(rows.get(('snatch_stolen_name', 0)), 'Gold Chain 20g')
            self.assertEqual(rows.get(('snatch_stolen_value', 0)), '120000')
            self.assertEqual(rows.get(('snatch_stolen_name', 1)), 'Purse with Cash')
            self.assertEqual(rows.get(('snatch_stolen_value', 1)), '5000')
            self.assertEqual(rows.get(('snatch_recovered_name', 0)), 'Gold Chain 20g')

            # Cleared from JSON
            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('snatch_')})

            # Loaded back in the shape the form expects
            extra = FullCaseDetailSerializer(case).data['extra_fields']
            self.assertEqual(extra['snatch_gold'], 'Yes')
            self.assertEqual(extra['snatch_other_precious_metal'], 'White Gold')
            self.assertEqual(len(extra['snatch_stolen_props']), 2)
            self.assertEqual(extra['snatch_stolen_props'][0]['snatch_stolen_name'], 'Gold Chain 20g')
            self.assertEqual(extra['snatch_recovered_props'][0]['snatch_recovered_name'], 'Gold Chain 20g')
