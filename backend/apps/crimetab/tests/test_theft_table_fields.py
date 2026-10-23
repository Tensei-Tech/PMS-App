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


class TheftTableFieldTests(TestCase):
    """Theft questions come from the public template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.cat = CaseCategory.objects.create(category_name='Theft', category_code='TEST_THEFT')
        self.other_cat = CaseCategory.objects.create(category_name='Two/Four Wheeler Theft',
                                                     category_code='TEST_VEH_THEFT')
        tmpl = FieldTemplate.objects.create(template_name='TEST Theft Extra', store_values_in_table=True)
        CategoryFieldTemplate.objects.create(category=self.cat, template=tmpl)
        for i, (key, ftype, parent) in enumerate([
            ('theft_types', 'multi_select', None),
            ('theft_vehicle_number', 'text', None),
            ('theft_stolen_props', 'repeating_group', None),
            ('theft_stolen_name', 'text', 'theft_stolen_props'),
            ('theft_stolen_value', 'number', 'theft_stolen_props'),
            ('theft_gold', 'radio', None),
        ]):
            FieldTemplateField.objects.create(
                template=tmpl, field_key=key, field_label=key, field_source='custom',
                field_type=ftype, display_order=2000 + i, parent_field_key=parent)

    def _case(self, cid, sub='Theft'):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title='TEST', sub_category=sub,
            module_key='form_1_5', station_name='TEST Station', extra_fields={})

    def _payload(self):
        values = {
            'theft_types': ['Vehicle Theft', 'Cash'],
            'theft_vehicle_number': 'MH-12-AB-1234',
            'theft_stolen_props': [
                {'theft_stolen_name': 'Bike', 'theft_stolen_value': '50000'},
                {'theft_stolen_name': '', 'theft_stolen_value': ''},   # empty row: dropped
                {'theft_stolen_name': 'Helmet', 'theft_stolen_value': '1500'},
            ],
            'theft_gold': 'No',
        }
        # The dynamic form sends values at the top level and inside extra_fields
        return {**values, 'extra_fields': {**values, 'keep_me': 'yes',
                                           'extra_field_values': dict(values)}}

    def test_form_definition_comes_from_the_public_template(self):
        keys = {f['field_key'] for f in get_form_definition(self.cat.category_id)['fields']}
        self.assertTrue({'theft_types', 'theft_stolen_props', 'theft_stolen_name'} <= keys)
        # Only the Theft tab gets them
        other = {f['field_key'] for f in get_form_definition(self.other_cat.category_id)['fields']}
        self.assertFalse(other & keys)

    def test_values_saved_as_rows_not_json_and_loaded_back(self):
        with TenantContext('maharashtra'):
            payload = self._payload()
            case = self._case('THEFT_TEST_1')
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows, {
                ('theft_types', 0): 'Vehicle Theft',
                ('theft_types', 1): 'Cash',
                ('theft_vehicle_number', 0): 'MH-12-AB-1234',
                ('theft_stolen_name', 0): 'Bike',
                ('theft_stolen_value', 0): '50000',
                ('theft_stolen_name', 1): 'Helmet',
                ('theft_stolen_value', 1): '1500',
                ('theft_gold', 0): 'No',
            })

            # Nothing of the theft section is left in the JSON
            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('theft_')})
            self.assertFalse({k for k in case.extra_fields['extra_field_values'] if k.startswith('theft_')})

            # Read back in the shape the form sends
            extra = FullCaseDetailSerializer(case).data['extra_fields']
            self.assertEqual(extra['theft_types'], ['Vehicle Theft', 'Cash'])
            self.assertEqual(extra['theft_vehicle_number'], 'MH-12-AB-1234')
            self.assertEqual(extra['theft_stolen_props'], [
                {'theft_stolen_name': 'Bike', 'theft_stolen_value': '50000'},
                {'theft_stolen_name': 'Helmet', 'theft_stolen_value': '1500'},
            ])

            # Editing replaces the rows (a cleared value disappears)
            _save_case_child_entities(case, {'theft_types': ['Cash'], 'theft_vehicle_number': '',
                                             'theft_stolen_props': []})
            extra = FullCaseDetailSerializer(case).data['extra_fields']
            self.assertEqual(extra['theft_types'], ['Cash'])
            self.assertNotIn('theft_vehicle_number', extra)
            self.assertNotIn('theft_stolen_props', extra)
            self.assertEqual(extra['theft_gold'], 'No')   # not sent: kept

    def test_other_tabs_keep_their_json(self):
        with TenantContext('maharashtra'):
            payload = self._payload()
            case = self._case('THEFT_TEST_2', sub='Two/Four Wheeler Theft')
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)
            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('theft_vehicle_number'), 'MH-12-AB-1234')
            self.assertFalse(CaseExtraFieldValue.objects.filter(case=case, row_no__gt=0).exists())
