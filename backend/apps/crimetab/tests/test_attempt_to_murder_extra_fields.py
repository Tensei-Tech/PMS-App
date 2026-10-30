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


class AttemptToMurderExtraFieldTests(TestCase):
    """Attempt to Murder extra fields come from the database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.cat = CaseCategory.objects.filter(category_code='102').first() or \
            CaseCategory.objects.create(category_name='Attempt to Murder', category_code='102')
        self.tmpl = FieldTemplate.objects.filter(template_name='Attempt to Murder Extra Fields').first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0142_attempt_to_murder_extra_fields')
            from django.apps import apps as django_apps
            mig.forwards(django_apps, None)
            self.tmpl = FieldTemplate.objects.filter(template_name='Attempt to Murder Extra Fields').first()
        CategoryFieldTemplate.objects.get_or_create(category=self.cat, template=self.tmpl)

    def _case(self, cid):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title='TEST ATTEMPT TO MURDER', sub_category='Attempt to Murder',
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def _payload(self):
        values = {
            'atm_same_as_complainant': 'Yes',
            'atm_injured_name': 'Vijay Patil',
            'atm_injured_age': '40',
            'atm_injured_gender': 'Male',
            'atm_injured_occupation': 'Shopkeeper',
            'atm_injured_mobile': '9876543210',
            'atm_injured_aadhaar': '112233445566',
            'atm_injured_pan': 'ABCDE9999Z',
            'atm_injured_religion': 'Hindu',
            'atm_injured_caste': 'Maratha',
            'atm_inquest_panchanama': 'Yes',
            'atm_inquest_datetime': '28/10/2026 11:30',
            'atm_exhumation_panchanama': 'No',
            'atm_postmortem': 'Yes',
            'atm_postmortem_date': '28/10/2026',
            'atm_postmortem_time': '15:00',
            'atm_pm_report_sent': 'Yes',
            'atm_pm_report_sent_date': '29/10/2026',
            'atm_pm_report_sent_time': '10:00',
            'atm_viscera_fsl': 'Yes',
            'atm_viscera_fsl_date': '30/10/2026',
            'atm_viscera_fsl_time': '12:00',
            'atm_fsl_report': 'Yes',
            'atm_fsl_report_date': '05/11/2026',
            'atm_fsl_report_time': '14:00',
        }
        return {**values, 'extra_fields': {**values, 'keep_me': 'yes', 'extra_field_values': dict(values)}}

    def test_form_definition_has_attempt_to_murder_fields(self):
        form_def = get_form_definition(self.cat.category_id)
        field_keys = {f['field_key'] for f in form_def['fields']}
        expected_keys = [
            'atm_same_as_complainant',
            'atm_injured_name',
            'atm_injured_age',
            'atm_injured_gender',
            'atm_injured_occupation',
            'atm_injured_mobile',
            'atm_injured_aadhaar',
            'atm_injured_pan',
            'atm_injured_religion',
            'atm_injured_caste',
            'atm_inquest_panchanama',
            'atm_inquest_datetime',
            'atm_exhumation_panchanama',
            'atm_exhumation_datetime',
            'atm_postmortem',
            'atm_postmortem_date',
            'atm_postmortem_time',
            'atm_pm_report_sent',
            'atm_pm_report_sent_date',
            'atm_pm_report_sent_time',
            'atm_viscera_fsl',
            'atm_viscera_fsl_date',
            'atm_viscera_fsl_time',
            'atm_fsl_report',
            'atm_fsl_report_date',
            'atm_fsl_report_time',
        ]
        for k in expected_keys:
            self.assertIn(k, field_keys, f'Missing field key: {k}')

    def test_values_saved_as_table_rows_and_loaded_back(self):
        with TenantContext('maharashtra'):
            payload = self._payload()
            case = self._case('ATM_TEST_1')
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            rows = {v.field_def.field_key: v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            self.assertEqual(rows.get('atm_same_as_complainant'), 'Yes')
            self.assertEqual(rows.get('atm_injured_name'), 'Vijay Patil')
            self.assertEqual(rows.get('atm_injured_age'), '40')
            self.assertEqual(rows.get('atm_injured_gender'), 'Male')
            self.assertEqual(rows.get('atm_injured_occupation'), 'Shopkeeper')
            self.assertEqual(rows.get('atm_injured_mobile'), '9876543210')
            self.assertEqual(rows.get('atm_injured_aadhaar'), '112233445566')
            self.assertEqual(rows.get('atm_injured_pan'), 'ABCDE9999Z')
            self.assertEqual(rows.get('atm_injured_religion'), 'Hindu')
            self.assertEqual(rows.get('atm_injured_caste'), 'Maratha')
            self.assertEqual(rows.get('atm_inquest_panchanama'), 'Yes')
            self.assertEqual(rows.get('atm_inquest_datetime'), '28/10/2026 11:30')
            self.assertEqual(rows.get('atm_exhumation_panchanama'), 'No')
            self.assertEqual(rows.get('atm_postmortem'), 'Yes')
            self.assertEqual(rows.get('atm_postmortem_date'), '28/10/2026')
            self.assertEqual(rows.get('atm_postmortem_time'), '15:00')
            self.assertEqual(rows.get('atm_pm_report_sent'), 'Yes')
            self.assertEqual(rows.get('atm_pm_report_sent_date'), '29/10/2026')
            self.assertEqual(rows.get('atm_pm_report_sent_time'), '10:00')
            self.assertEqual(rows.get('atm_viscera_fsl'), 'Yes')
            self.assertEqual(rows.get('atm_viscera_fsl_date'), '30/10/2026')
            self.assertEqual(rows.get('atm_viscera_fsl_time'), '12:00')
            self.assertEqual(rows.get('atm_fsl_report'), 'Yes')
            self.assertEqual(rows.get('atm_fsl_report_date'), '05/11/2026')
            self.assertEqual(rows.get('atm_fsl_report_time'), '14:00')

            # Cleared from JSON
            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('atm_')})

            # Loaded back via table_values_for_case
            loaded = table_values_for_case(case)
            self.assertEqual(loaded.get('atm_injured_name'), 'Vijay Patil')
            self.assertEqual(loaded.get('atm_injured_age'), '40')
            self.assertEqual(loaded.get('atm_inquest_datetime'), '28/10/2026 11:30')
            self.assertEqual(loaded.get('atm_fsl_report_time'), '14:00')
