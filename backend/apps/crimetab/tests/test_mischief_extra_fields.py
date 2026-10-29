from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import (
    CaseCategory,
    CaseExtraFieldValue,
    CategoryFieldTemplate,
    FieldTemplate,
)
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities


class MischiefExtraFieldTests(TestCase):
    """Mischief extra fields come from the database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.cat = CaseCategory.objects.filter(category_code='110').first() or \
            CaseCategory.objects.create(category_name='Mischief', category_code='110')
        self.tmpl = FieldTemplate.objects.filter(template_name='Mischief Extra Fields').first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0141_mischief_extra_fields')
            from django.apps import apps as django_apps
            mig.forwards(django_apps, None)
            self.tmpl = FieldTemplate.objects.filter(template_name='Mischief Extra Fields').first()
        CategoryFieldTemplate.objects.get_or_create(category=self.cat, template=self.tmpl)

    def _case(self, cid):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title='TEST MISCHIEF', sub_category='Mischief',
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def _payload(self):
        values = {
            'mischief_damaged_property': [
                {
                    'mischief_property_description': 'Front shop window glass broken',
                    'mischief_property_value': '15000',
                },
                {
                    'mischief_property_description': 'CCTV Camera smashed',
                    'mischief_property_value': '5500',
                },
            ],
            'mischief_total_value': '20500',
        }
        return {**values, 'extra_fields': {**values, 'keep_me': 'yes', 'extra_field_values': dict(values)}}

    def test_form_definition_has_mischief_fields(self):
        form_def = get_form_definition(self.cat.category_id)
        field_map = {f['field_key']: f for f in form_def['fields']}
        expected_keys = [
            'mischief_damaged_property',
            'mischief_property_description',
            'mischief_property_value',
            'mischief_total_value',
        ]
        for k in expected_keys:
            self.assertIn(k, field_map, f'Missing field key: {k}')

        # Verify auto-sum options source
        total_field = field_map['mischief_total_value']
        self.assertEqual(
            total_field['options_source'],
            'sum:mischief_damaged_property.mischief_property_value'
        )

    def test_values_saved_as_table_rows_and_loaded_back(self):
        with TenantContext('maharashtra'):
            payload = self._payload()
            case = self._case('MISCHIEF_TEST_1')
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            # Row 0: Glass
            self.assertEqual(rows.get(('mischief_property_description', 0)), 'Front shop window glass broken')
            self.assertEqual(rows.get(('mischief_property_value', 0)), '15000')

            # Row 1: CCTV
            self.assertEqual(rows.get(('mischief_property_description', 1)), 'CCTV Camera smashed')
            self.assertEqual(rows.get(('mischief_property_value', 1)), '5500')

            # Total value
            self.assertEqual(rows.get(('mischief_total_value', 0)), '20500')

            # Cleared from JSON
            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('mischief_')})

            # Loaded back via table_values_for_case
            loaded = table_values_for_case(case)
            self.assertIn('mischief_damaged_property', loaded)
            props = loaded['mischief_damaged_property']
            self.assertEqual(len(props), 2)
            self.assertEqual(props[0]['mischief_property_description'], 'Front shop window glass broken')
            self.assertEqual(props[0]['mischief_property_value'], '15000')
            self.assertEqual(props[1]['mischief_property_description'], 'CCTV Camera smashed')
            self.assertEqual(props[1]['mischief_property_value'], '5500')
            self.assertEqual(loaded['mischief_total_value'], '20500')
