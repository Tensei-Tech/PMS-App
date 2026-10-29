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


class HurtExtraFieldTests(TestCase):
    """Hurt extra fields come from the database template; answers are rows in case_extra_field_values."""

    def setUp(self):
        self.cat = CaseCategory.objects.filter(category_code='121').first() or \
            CaseCategory.objects.create(category_name='Hurt', category_code='121')
        self.tmpl = FieldTemplate.objects.filter(template_name='Hurt Extra Fields').first()
        if not self.tmpl:
            import importlib
            mig = importlib.import_module('apps.crimetab.migrations.0140_hurt_extra_fields')
            from django.apps import apps as django_apps
            mig.forwards(django_apps, None)
            self.tmpl = FieldTemplate.objects.filter(template_name='Hurt Extra Fields').first()
        CategoryFieldTemplate.objects.get_or_create(category=self.cat, template=self.tmpl)

    def _case(self, cid):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title='TEST HURT', sub_category='Hurt',
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def _payload(self):
        values = {
            'hurt_injured_persons': [
                {
                    'hurt_injured_name': 'Anil Sharma',
                    'hurt_injured_age': '32',
                    'hurt_injured_gender': 'Male',
                    'hurt_injured_mobile': '9876543210',
                    'hurt_injured_aadhaar': '123456789012',
                    'hurt_injured_pan': 'ABCDE1234F',
                    'hurt_person_deceased': 'Yes',
                    'hurt_death_datetime': '28/10/2026 10:30',
                    'hurt_inquest_panchanama': 'Yes',
                    'hurt_inquest_datetime': '28/10/2026 12:00',
                    'hurt_exhumation_panchanama': 'No',
                    'hurt_postmortem': 'Yes',
                    'hurt_postmortem_date': '28/10/2026',
                    'hurt_postmortem_time': '14:00',
                    'hurt_pm_report_sent': 'Yes',
                    'hurt_pm_report_sent_date': '29/10/2026',
                    'hurt_pm_report_sent_time': '11:00',
                    'hurt_viscera_fsl': 'Yes',
                    'hurt_viscera_fsl_date': '30/10/2026',
                    'hurt_viscera_fsl_time': '16:00',
                    'hurt_fsl_report': 'Yes',
                    'hurt_fsl_report_date': '05/11/2026',
                    'hurt_fsl_report_time': '15:30',
                },
                {
                    'hurt_injured_name': 'Sunita Sharma',
                    'hurt_injured_age': '28',
                    'hurt_injured_gender': 'Female',
                    'hurt_injured_mobile': '9123456780',
                    'hurt_injured_aadhaar': '987654321098',
                    'hurt_injured_pan': '',
                    'hurt_person_deceased': 'No',
                },
            ],
        }
        return {**values, 'extra_fields': {**values, 'keep_me': 'yes', 'extra_field_values': dict(values)}}

    def test_form_definition_has_hurt_fields(self):
        form_def = get_form_definition(self.cat.category_id)
        keys = {f['field_key'] for f in form_def['fields']}
        expected_keys = [
            'hurt_injured_persons',
            'hurt_injured_name',
            'hurt_injured_age',
            'hurt_injured_gender',
            'hurt_injured_mobile',
            'hurt_injured_aadhaar',
            'hurt_injured_pan',
            'hurt_person_deceased',
            'hurt_death_datetime',
            'hurt_inquest_panchanama',
            'hurt_inquest_datetime',
            'hurt_exhumation_panchanama',
            'hurt_exhumation_datetime',
            'hurt_postmortem',
            'hurt_postmortem_date',
            'hurt_postmortem_time',
            'hurt_pm_report_sent',
            'hurt_pm_report_sent_date',
            'hurt_pm_report_sent_time',
            'hurt_viscera_fsl',
            'hurt_viscera_fsl_date',
            'hurt_viscera_fsl_time',
            'hurt_fsl_report',
            'hurt_fsl_report_date',
            'hurt_fsl_report_time',
        ]
        for k in expected_keys:
            self.assertIn(k, keys, f'Missing field key: {k}')

    def test_values_saved_as_table_rows_and_loaded_back(self):
        with TenantContext('maharashtra'):
            payload = self._payload()
            case = self._case('HURT_TEST_1')
            case.extra_fields = payload['extra_fields']
            case.save()
            _save_case_child_entities(case, payload)

            rows = {(v.field_def.field_key, v.row_no): v.field_value
                    for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
            # Row 0: Anil Sharma (deceased)
            self.assertEqual(rows.get(('hurt_injured_name', 0)), 'Anil Sharma')
            self.assertEqual(rows.get(('hurt_injured_age', 0)), '32')
            self.assertEqual(rows.get(('hurt_injured_gender', 0)), 'Male')
            self.assertEqual(rows.get(('hurt_injured_mobile', 0)), '9876543210')
            self.assertEqual(rows.get(('hurt_injured_aadhaar', 0)), '123456789012')
            self.assertEqual(rows.get(('hurt_injured_pan', 0)), 'ABCDE1234F')
            self.assertEqual(rows.get(('hurt_person_deceased', 0)), 'Yes')
            self.assertEqual(rows.get(('hurt_death_datetime', 0)), '28/10/2026 10:30')
            self.assertEqual(rows.get(('hurt_inquest_panchanama', 0)), 'Yes')
            self.assertEqual(rows.get(('hurt_inquest_datetime', 0)), '28/10/2026 12:00')
            self.assertEqual(rows.get(('hurt_exhumation_panchanama', 0)), 'No')
            self.assertEqual(rows.get(('hurt_postmortem', 0)), 'Yes')
            self.assertEqual(rows.get(('hurt_postmortem_date', 0)), '28/10/2026')
            self.assertEqual(rows.get(('hurt_postmortem_time', 0)), '14:00')
            self.assertEqual(rows.get(('hurt_pm_report_sent', 0)), 'Yes')
            self.assertEqual(rows.get(('hurt_pm_report_sent_date', 0)), '29/10/2026')
            self.assertEqual(rows.get(('hurt_pm_report_sent_time', 0)), '11:00')
            self.assertEqual(rows.get(('hurt_viscera_fsl', 0)), 'Yes')
            self.assertEqual(rows.get(('hurt_viscera_fsl_date', 0)), '30/10/2026')
            self.assertEqual(rows.get(('hurt_viscera_fsl_time', 0)), '16:00')
            self.assertEqual(rows.get(('hurt_fsl_report', 0)), 'Yes')
            self.assertEqual(rows.get(('hurt_fsl_report_date', 0)), '05/11/2026')
            self.assertEqual(rows.get(('hurt_fsl_report_time', 0)), '15:30')

            # Row 1: Sunita Sharma (alive)
            self.assertEqual(rows.get(('hurt_injured_name', 1)), 'Sunita Sharma')
            self.assertEqual(rows.get(('hurt_injured_age', 1)), '28')
            self.assertEqual(rows.get(('hurt_injured_gender', 1)), 'Female')
            self.assertEqual(rows.get(('hurt_injured_mobile', 1)), '9123456780')
            self.assertEqual(rows.get(('hurt_injured_aadhaar', 1)), '987654321098')
            self.assertEqual(rows.get(('hurt_person_deceased', 1)), 'No')

            # Cleared from JSON
            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            self.assertFalse({k for k in case.extra_fields if k.startswith('hurt_')})

            # Loaded back via table_values_for_case
            loaded = table_values_for_case(case)
            self.assertIn('hurt_injured_persons', loaded)
            persons = loaded['hurt_injured_persons']
            self.assertEqual(len(persons), 2)
            self.assertEqual(persons[0]['hurt_injured_name'], 'Anil Sharma')
            self.assertEqual(persons[0]['hurt_death_datetime'], '28/10/2026 10:30')
            self.assertEqual(persons[0]['hurt_pm_report_sent_time'], '11:00')
            self.assertEqual(persons[1]['hurt_injured_name'], 'Sunita Sharma')
            self.assertEqual(persons[1]['hurt_person_deceased'], 'No')
