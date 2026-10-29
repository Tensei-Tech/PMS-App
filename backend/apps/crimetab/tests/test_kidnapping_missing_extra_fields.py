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

TEMPLATE = 'Kidnapping / Missing Extra Fields'


class KidnappingMissingExtraFieldTests(TestCase):
    """Kidnapping and Missing extra fields come from one database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.kidnapping = CaseCategory.objects.filter(category_code='120').first() or \
            CaseCategory.objects.create(category_name='Kidnapping', category_code='120')
        self.missing = CaseCategory.objects.filter(category_code='124').first() or \
            CaseCategory.objects.create(category_name='Missing', category_code='124')
        self.tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE).first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0144_kidnapping_missing_extra_fields')
            from django.apps import apps as django_apps
            mig.forwards(django_apps, None)
            self.tmpl = FieldTemplate.objects.get(template_name=TEMPLATE)
        for cat in (self.kidnapping, self.missing):
            CategoryFieldTemplate.objects.get_or_create(category=cat, template=self.tmpl)

    def _case(self, cid, sub_category):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title=f'TEST {sub_category.upper()}', sub_category=sub_category,
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def test_form_definition_has_fields_for_kidnapping_and_missing(self):
        for cat in (self.kidnapping, self.missing):
            keys = {f['field_key'] for f in get_form_definition(cat.category_id)['fields']}
            for key in ('kdn_person_name', 'kdn_person_address', 'kdn_found_datetime', 'kdn_found_sd_no',
                        'kdn_person_statement', 'kdn_custody_to', 'kdn_parent_name', 'kdn_bnss_statement_date',
                        'kdn_cwc_statement', 'kdn_medical_statement', 'kdn_in_camera_statement', 'kdn_ca_sent_date'):
                self.assertIn(key, keys, f'{cat.category_name}: missing {key}')

    def test_custody_options_and_conditions(self):
        options = list(OptionValue.objects.filter(option_group='kidnap_custody_to')
                       .order_by('display_order').values_list('option_value', flat=True))
        self.assertEqual(options, ['Parents (KYC)', 'Relative', 'Shelter Home'])
        parent_fields = self.tmpl.fields.filter(depends_on_field_key='kdn_custody_to')
        self.assertEqual({f.depends_on_value for f in parent_fields}, {'Parents (KYC)'})
        # Each statement date waits for its own Yes.
        for radio in ('kdn_bnss_statement', 'kdn_cwc_statement', 'kdn_medical_statement',
                      'kdn_in_camera_statement', 'kdn_ca_sent'):
            date = self.tmpl.fields.get(field_key=f'{radio}_date')
            self.assertEqual((date.depends_on_field_key, date.depends_on_value, date.field_type), (radio, 'Yes', 'date'))

    def test_values_saved_as_table_rows_and_loaded_back(self):
        values = {
            'kdn_person_name': 'Priya Shinde', 'kdn_person_age': '14', 'kdn_person_gender': 'Female',
            'kdn_person_caste': 'Maratha', 'kdn_person_address': 'Ward 5, Wardha', 'kdn_person_mobile': '9876543210',
            'kdn_found_datetime': '28/10/2026 18:30', 'kdn_found_sd_no': 'SD-112/2026', 'kdn_person_statement': 'Yes',
            'kdn_custody_to': 'Parents (KYC)', 'kdn_parent_name': 'Sunil Shinde', 'kdn_parent_relation': 'Father',
            'kdn_bnss_statement': 'Yes', 'kdn_bnss_statement_date': '29/10/2026',
            'kdn_cwc_statement': 'No', 'kdn_ca_sent': 'Yes', 'kdn_ca_sent_date': '30/10/2026',
        }
        with TenantContext('maharashtra'):
            case = self._case('KID_TEST_1', 'Kidnapping')
            case.extra_fields = {**values, 'keep_me': 'yes'}
            case.save()
            _save_case_child_entities(case, {**values, 'extra_fields': {**values, 'keep_me': 'yes'}})

            rows = {v.field_def.field_key: v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows, values)

            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('kdn_')})
            self.assertEqual(table_values_for_case(case), values)

    def test_missing_case_saved_too(self):
        values = {'kdn_person_name': 'Rahul Kale', 'kdn_found_datetime': '27/10/2026 09:00',
                  'kdn_custody_to': 'Shelter Home', 'kdn_medical_statement': 'Yes',
                  'kdn_medical_statement_date': '27/10/2026'}
        with TenantContext('maharashtra'):
            case = self._case('MIS_TEST_1', 'Missing')
            case.extra_fields = dict(values)
            case.save()
            _save_case_child_entities(case, {**values, 'extra_fields': dict(values)})
            self.assertEqual(table_values_for_case(case), values)
