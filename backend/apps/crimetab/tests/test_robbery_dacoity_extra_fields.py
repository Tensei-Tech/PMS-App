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

TEMPLATE = 'Robbery / Dacoity Extra Fields'


class RobberyDacoityExtraFieldTests(TestCase):
    """Robbery and Dacoity extra fields come from one database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.robbery = CaseCategory.objects.filter(category_code='104').first() or \
            CaseCategory.objects.create(category_name='Robbery', category_code='104')
        self.dacoity = CaseCategory.objects.filter(category_code='103').first() or \
            CaseCategory.objects.create(category_name='Dacoity', category_code='103')
        self.tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE).first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0143_robbery_dacoity_extra_fields')
            from django.apps import apps as django_apps
            mig.forwards(django_apps, None)
            self.tmpl = FieldTemplate.objects.get(template_name=TEMPLATE)
        for cat in (self.robbery, self.dacoity):
            CategoryFieldTemplate.objects.get_or_create(category=cat, template=self.tmpl)

    def _case(self, cid, sub_category):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title=f'TEST {sub_category.upper()}', sub_category=sub_category,
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def _payload(self):
        values = {
            'rd_stolen_props': [
                {'rd_stolen_name': 'Gold Chain', 'rd_stolen_description': '22 carat, 20 g', 'rd_stolen_value': '120000'},
                {'rd_stolen_name': 'Motorcycle', 'rd_stolen_value': '65000'},
            ],
            'rd_property_types': ['Precious Metal / Jewellery', 'Vehicle', 'Cash'],
            'rd_gold': 'Yes',
            'rd_silver': 'No',
            'rd_ornaments': [
                {'rd_ornament_name': 'Chain', 'rd_ornament_metal': 'Gold', 'rd_ornament_value': '120000'},
                {'rd_ornament_name': 'Anklet', 'rd_ornament_metal': 'Other',
                 'rd_ornament_metal_other': 'White Gold', 'rd_ornament_value': '30000'},
            ],
            'rd_ornaments_total_value': '150000',
            'rd_vehicle_type': 'Two Wheeler (Motorcycle / Scooter / Moped)',
            'rd_vehicle_engine_number': 'ENG123',
            'rd_vehicle_chassis_number': 'CHS456',
            'rd_vehicle_reg_number': 'MH31AB1234',
            'rd_vehicle_photo': 'Yes',
            'rd_cash_total': '₹50,000',
            'rd_cash_note_count': '500 × 100 notes',
            'rd_recovered_props': [
                {'rd_recovered_name': 'Motorcycle', 'rd_recovered_value': '65000'},
            ],
            'rd_injured_persons': [
                {'rd_injured_name': 'Ramesh Patil', 'rd_injured_age': '45', 'rd_injured_gender': 'Male',
                 'rd_injured_died': 'Yes', 'rd_injured_death_datetime': '28/10/2026 22:15',
                 'rd_injured_inquest': 'Yes', 'rd_injured_inquest_datetime': '29/10/2026 09:00',
                 'rd_injured_exhumation': 'No'},
                {'rd_injured_name': 'Suman Patil', 'rd_injured_age': '40', 'rd_injured_gender': 'Female',
                 'rd_injured_died': 'No'},
            ],
            'rd_deceased_persons': [
                {'rd_deceased_name': 'Ramesh Patil', 'rd_deceased_occupation': 'Shopkeeper',
                 'rd_deceased_address': 'Main Road, Wardha', 'rd_postmortem': 'Yes',
                 'rd_postmortem_date': '29/10/2026', 'rd_postmortem_time': '11:30',
                 'rd_viscera_fsl': 'Yes', 'rd_viscera_fsl_date': '30/10/2026', 'rd_viscera_fsl_time': '10:00',
                 'rd_fsl_report': 'No'},
            ],
        }
        return {**values, 'extra_fields': {**values, 'keep_me': 'yes', 'extra_field_values': dict(values)}}

    def test_form_definition_has_fields_for_robbery_and_dacoity(self):
        for cat in (self.robbery, self.dacoity):
            fields = {f['field_key']: f for f in get_form_definition(cat.category_id)['fields']}
            for key in ('rd_stolen_props', 'rd_property_types', 'rd_ornaments', 'rd_ornaments_total_value',
                        'rd_vehicle_engine_number', 'rd_cash_total', 'rd_recovered_props',
                        'rd_injured_persons', 'rd_injured_death_datetime', 'rd_deceased_persons',
                        'rd_postmortem_date', 'rd_fsl_report_time'):
                self.assertIn(key, fields, f'{cat.category_name}: missing {key}')
            # The starred fields of the request are required, the rest optional.
            required = {k for k, f in fields.items() if k.startswith('rd_') and f['is_required']}
            self.assertEqual(required, {
                'rd_stolen_name', 'rd_ornament_name', 'rd_ornament_metal', 'rd_ornament_value',
                'rd_vehicle_engine_number', 'rd_vehicle_chassis_number', 'rd_vehicle_reg_number',
                'rd_cash_total', 'rd_recovered_name'})

    def test_conditions_match_property_type_options(self):
        # Every value a section waits for is an option of the checkbox list,
        # and no option has a comma (a stored list can be split at commas).
        options = set(OptionValue.objects.filter(option_group='robbery_property_types')
                      .values_list('option_value', flat=True))
        self.assertEqual(len(options), 14)
        self.assertFalse([o for o in options if ',' in o])
        waits = self.tmpl.fields.filter(depends_on_field_key='rd_property_types')
        for f in waits:
            for value in f.depends_on_value.split('|'):
                self.assertIn(value, options, f'{f.field_key} waits for unknown option {value!r}')

    def test_values_saved_as_table_rows_and_loaded_back(self):
        with TenantContext('maharashtra'):
            payload = self._payload()
            case = self._case('ROB_TEST_1', 'Robbery')
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows[('rd_stolen_name', 1)], 'Motorcycle')
            self.assertEqual(rows[('rd_property_types', 2)], 'Cash')
            self.assertEqual(rows[('rd_ornament_metal_other', 1)], 'White Gold')
            self.assertEqual(rows[('rd_ornaments_total_value', 0)], '150000')
            self.assertEqual(rows[('rd_vehicle_reg_number', 0)], 'MH31AB1234')
            self.assertEqual(rows[('rd_cash_total', 0)], '₹50,000')
            self.assertEqual(rows[('rd_recovered_name', 0)], 'Motorcycle')
            self.assertEqual(rows[('rd_injured_death_datetime', 0)], '28/10/2026 22:15')
            self.assertEqual(rows[('rd_injured_died', 1)], 'No')
            self.assertEqual(rows[('rd_deceased_address', 0)], 'Main Road, Wardha')
            self.assertEqual(rows[('rd_viscera_fsl_time', 0)], '10:00')

            # Moved out of the JSON; other keys kept.
            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('rd_')})

            loaded = table_values_for_case(case)
            self.assertEqual(loaded['rd_property_types'], ['Precious Metal / Jewellery', 'Vehicle', 'Cash'])
            self.assertEqual([p['rd_injured_name'] for p in loaded['rd_injured_persons']],
                             ['Ramesh Patil', 'Suman Patil'])
            self.assertEqual(loaded['rd_ornaments'][1]['rd_ornament_value'], '30000')
            self.assertEqual(loaded['rd_deceased_persons'][0]['rd_postmortem_time'], '11:30')

    def test_dacoity_case_saved_too(self):
        with TenantContext('maharashtra'):
            values = {'rd_stolen_props': [{'rd_stolen_name': 'Cash Box', 'rd_stolen_value': '10000'}],
                      'rd_property_types': ['Cash'], 'rd_cash_total': '₹10,000'}
            case = self._case('DAC_TEST_1', 'Dacoity')
            case.extra_fields = {**values}
            case.save()
            _save_case_child_entities(case, {**values, 'extra_fields': dict(values)})
            loaded = table_values_for_case(case)
            self.assertEqual(loaded['rd_stolen_props'][0]['rd_stolen_name'], 'Cash Box')
            self.assertEqual(loaded['rd_cash_total'], '₹10,000')
