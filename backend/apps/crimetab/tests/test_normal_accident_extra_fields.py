import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import (
    CaseCategory,
    CaseExtraFieldValue,
    CategoryFieldTemplate,
    FieldTemplate,
    OptionValue,
)
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities

TEMPLATE = 'Normal Accident Extra Fields'


class NormalAccidentExtraFieldTests(TestCase):
    """Normal Accident extra fields come from a database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.normal = CaseCategory.objects.filter(category_code='ACC_NORMAL').first() or \
            CaseCategory.objects.create(category_name='Normal Accident', category_code='ACC_NORMAL')
        self.road = CaseCategory.objects.filter(category_code='ACC_ROAD').first() or \
            CaseCategory.objects.create(category_name='Road Accident', category_code='ACC_ROAD')
        importlib.import_module('apps.crimetab.migrations.0147_normal_accident_extra_fields').forwards(django_apps, None)
        self.tmpl = FieldTemplate.objects.get(template_name=TEMPLATE)

    def _case(self, cid):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title='TEST NORMAL ACCIDENT', sub_category='Normal Accident',
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def test_only_normal_accident_gets_the_fields(self):
        self.assertTrue(CategoryFieldTemplate.objects.filter(category=self.normal, template=self.tmpl).exists())
        self.assertFalse(CategoryFieldTemplate.objects.filter(category=self.road, template=self.tmpl).exists())
        fields = {f['field_key']: f for f in get_form_definition(self.normal.category_id)['fields']}
        for key in ('nacc_nature', 'nacc_landmark', 'nacc_road_type', 'nacc_vehicles', 'nacc_vehicle_reg_number',
                    'nacc_owner_name', 'nacc_driver_dl_no', 'nacc_vehicle_damage', 'nacc_rto_inspection',
                    'nacc_dar_form_date', 'nacc_irad_form_date'):
            self.assertIn(key, fields, f'missing {key}')
        required = {k for k, f in fields.items() if k.startswith('nacc_') and f['is_required']}
        self.assertEqual(required, {'nacc_nature', 'nacc_landmark', 'nacc_vehicle_reg_number', 'nacc_vehicle_type'})

    def test_options_and_other_conditions(self):
        counts = {g: OptionValue.objects.filter(option_group=g).count() for g in (
            'accident_nature', 'accident_road_types', 'accident_vehicle_types', 'accident_vehicle_companies')}
        self.assertEqual(counts, {'accident_nature': 12, 'accident_road_types': 8,
                                  'accident_vehicle_types': 11, 'accident_vehicle_companies': 17})
        # No option has a comma (a stored list can be split at commas).
        self.assertFalse(OptionValue.objects.filter(option_group__startswith='accident_', option_value__contains=','))
        for other in ('nacc_nature_other', 'nacc_road_type_other', 'nacc_vehicle_type_other', 'nacc_vehicle_company_other'):
            self.assertEqual(self.tmpl.fields.get(field_key=other).depends_on_value, 'Other')

    def test_values_saved_as_table_rows_and_loaded_back(self):
        values = {
            'nacc_nature': ['Over Speed', 'Head-on Collision'],
            'nacc_landmark': 'Near Bajaj Chowk',
            'nacc_road_type': 'State Highway (SH)',
            'nacc_vehicle_abandoned': 'No',
            'nacc_vehicles': [
                {'nacc_vehicle_reg_number': 'MH32AB1234', 'nacc_vehicle_type': 'Four Wheeler (Car / Jeep / Taxi)',
                 'nacc_vehicle_company': 'Tata Motors', 'nacc_vehicle_make_model': 'Nexon',
                 'nacc_owner_name': 'Vijay Deshmukh', 'nacc_driver_name': 'Sachin Rao',
                 'nacc_driver_dl_no': 'MH3220190012345', 'nacc_vehicle_seized': 'Yes',
                 'nacc_vehicle_damage': 'Front bumper broken'},
                {'nacc_vehicle_reg_number': 'MH32CD5678', 'nacc_vehicle_type': 'Other',
                 'nacc_vehicle_type_other': 'Ambulance', 'nacc_vehicle_company': 'Force Motors'},
            ],
            'nacc_cctv_dashcam': 'Yes',
            'nacc_dar_form': 'Yes', 'nacc_dar_form_date': '29/10/2026',
            'nacc_irad_form': 'No',
        }
        with TenantContext('maharashtra'):
            case = self._case('NACC_TEST_1')
            case.extra_fields = {**values, 'keep_me': 'yes'}
            case.save()
            _save_case_child_entities(case, {**values, 'extra_fields': {**values, 'keep_me': 'yes'}})

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows[('nacc_nature', 1)], 'Head-on Collision')
            self.assertEqual(rows[('nacc_vehicle_reg_number', 1)], 'MH32CD5678')
            self.assertEqual(rows[('nacc_vehicle_type_other', 1)], 'Ambulance')
            self.assertEqual(rows[('nacc_dar_form_date', 0)], '29/10/2026')

            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('nacc_')})
            self.assertEqual(table_values_for_case(case), values)
