import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField, OptionValue
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import save_table_values, table_values_for_case
from apps.public_master.models import StateRegistry

mig = importlib.import_module('apps.crimetab.migrations.0111_sand_theft_extra_fields')


class SandTheftExtraFieldsTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1}
        )
        self.sand = CaseCategory.objects.filter(category_code='STAND_SAND').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST Sand Theft',
                                        category_code='STAND_SAND', display_order=1)
        self.other = CaseCategory.objects.create(group=group, category_name='TEST Other',
                                                 category_code='TEST_OTHER', display_order=2)
        mig.forwards(django_apps, None)  # links the categories created above

    def _fields(self, category):
        return {f['field_key']: f for f in get_form_definition(category.pk)['fields']}

    def test_fields_show_only_for_sand_theft(self):
        fields = self._fields(self.sand)
        for _, key, *_ in mig.FIELDS:
            self.assertIn(key, fields)
            self.assertFalse(fields[key]['is_required'])
        self.assertFalse(any(k.startswith('sand_') for k in self._fields(self.other)))

    def test_lists_and_their_fields(self):
        fields = self._fields(self.sand)
        for group in ('sand_stolen_props', 'sand_recovered_props', 'sand_seized_vehicles'):
            self.assertEqual(fields[group]['field_type'], 'repeating_group')
        vehicle_kids = [k for k, f in fields.items() if f['parent_field_key'] == 'sand_seized_vehicles']
        self.assertEqual(len(vehicle_kids), 8)
        self.assertEqual(fields['sand_vehicle_photo_copy']['options_source'], mig.YES_NO)
        self.assertEqual(fields['sand_location_type_other']['depends_on_value'], 'Other')
        self.assertEqual(
            list(OptionValue.objects.filter(option_group='sand_location_types')
                 .order_by('display_order').values_list('option_value', flat=True)),
            mig.OPTIONS['sand_location_types'])

    def test_seized_vehicles_save_and_load_as_rows(self):
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True})
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='test-sand-1', module_key='crime', title='TEST Sand',
                case_number='CR/1/2026', station_name='TEST PS',
                sub_category=self.sand.category_name)
            vehicles = [
                {'sand_vehicle_name': 'Tipper', 'sand_vehicle_reg_number': 'MH-01', 'sand_vehicle_photo_copy': 'Yes'},
                {'sand_vehicle_name': 'Tractor', 'sand_vehicle_ownership_doc': 'No'},
            ]
            save_table_values(case, {'sand_seized_vehicles': vehicles, 'sand_spot_photo_taken': 'Yes'})
            loaded = table_values_for_case(case)
        self.assertEqual(loaded['sand_spot_photo_taken'], 'Yes')
        self.assertEqual([r['sand_vehicle_name'] for r in loaded['sand_seized_vehicles']], ['Tipper', 'Tractor'])
        self.assertEqual(loaded['sand_seized_vehicles'][0]['sand_vehicle_reg_number'], 'MH-01')

    def test_idempotent_and_reversible(self):
        mig.forwards(django_apps, None)
        self.assertEqual(
            FieldTemplateField.objects.filter(template__template_name=mig.TEMPLATE_NAME).count(),
            len(mig.FIELDS))
        self.assertTrue(FieldTemplate.objects.get(template_name=mig.TEMPLATE_NAME).store_values_in_table)
        mig.backwards(django_apps, None)
        self.assertFalse(FieldTemplate.objects.filter(template_name=mig.TEMPLATE_NAME).exists())
        self.assertFalse(OptionValue.objects.filter(option_group='sand_location_types').exists())
