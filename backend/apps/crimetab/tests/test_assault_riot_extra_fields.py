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
)
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities


class AssaultRiotExtraFieldTests(TestCase):
    """Assault on Public Servant gets the Hurt injured-person list and up to 3 non-applicants; Riot does not (0146)."""

    def setUp(self):
        self.assault = CaseCategory.objects.filter(category_code='111').first() or \
            CaseCategory.objects.create(category_name='Assault on Public Servant', category_code='111')
        self.riot = CaseCategory.objects.filter(category_code='106').first() or \
            CaseCategory.objects.create(category_name='Riot', category_code='106')
        if not FieldTemplate.objects.filter(template_name='Hurt Extra Fields').exists():
            importlib.import_module('apps.crimetab.migrations.0140_hurt_extra_fields').forwards(django_apps, None)
        importlib.import_module('apps.crimetab.migrations.0145_assault_riot_extra_fields').forwards(django_apps, None)
        importlib.import_module('apps.crimetab.migrations.0146_remove_riot_extra_fields').forwards(django_apps, None)

    def _case(self, cid, sub_category):
        return CaseRecord.objects.create(
            id=cid, case_number=f'CR/{cid}', title=f'TEST {sub_category.upper()}', sub_category=sub_category,
            module_key='form_1_5', station_name='TEST Station', extra_fields={}
        )

    def test_riot_has_neither_template(self):
        linked = set(CategoryFieldTemplate.objects.filter(category=self.riot)
                     .values_list('template__template_name', flat=True))
        self.assertFalse({'Hurt Extra Fields', 'Non-Applicant Details'} & linked)
        keys = {f['field_key'] for f in get_form_definition(self.riot.category_id)['fields']}
        self.assertFalse({k for k in keys if k.startswith(('hurt_', 'non_applicant'))})

    def test_both_templates_linked_to_assault(self):
        for cat in (self.assault,):
            linked = set(CategoryFieldTemplate.objects.filter(category=cat)
                         .values_list('template__template_name', flat=True))
            self.assertTrue({'Hurt Extra Fields', 'Non-Applicant Details'} <= linked, cat.category_name)
            fields = {f['field_key']: f for f in get_form_definition(cat.category_id)['fields']}
            for key in ('hurt_injured_persons', 'hurt_injured_pan', 'hurt_death_datetime', 'hurt_fsl_report_time',
                        'non_applicants', 'non_applicant_name', 'non_applicant_caste', 'non_applicant_aadhaar'):
                self.assertIn(key, fields, f'{cat.category_name}: missing {key}')
            # At most three non-applicants.
            self.assertEqual(fields['non_applicants']['options_source'], 'max:3')

    def test_values_saved_as_table_rows_and_loaded_back(self):
        values = {
            'hurt_injured_persons': [
                {'hurt_injured_name': 'Constable Patil', 'hurt_injured_age': '38', 'hurt_injured_gender': 'Male',
                 'hurt_person_deceased': 'No'},
            ],
            'non_applicants': [
                {'non_applicant_name': 'Ravi Jadhav', 'non_applicant_age': '29', 'non_applicant_gender': 'Male',
                 'non_applicant_caste': 'OBC', 'non_applicant_occupation': 'Driver',
                 'non_applicant_mobile': '9822012345', 'non_applicant_address': 'Station Road, Wardha',
                 'non_applicant_aadhaar': '123412341234'},
                {'non_applicant_name': 'Amit More', 'non_applicant_age': '31'},
            ],
        }
        for cid, sub in (('ASL_TEST_1', 'Assault on Public Servant'),):
            with TenantContext('maharashtra'):
                case = self._case(cid, sub)
                case.extra_fields = {**values, 'keep_me': 'yes'}
                case.save()
                _save_case_child_entities(case, {**values, 'extra_fields': {**values, 'keep_me': 'yes'}})

                rows = {(v.field_def.field_key, v.row_no): v.field_value
                        for v in CaseExtraFieldValue.objects.filter(case=case).select_related('field_def')}
                self.assertEqual(rows[('hurt_injured_name', 0)], 'Constable Patil')
                self.assertEqual(rows[('non_applicant_occupation', 0)], 'Driver')
                self.assertEqual(rows[('non_applicant_name', 1)], 'Amit More')

                case.refresh_from_db()
                self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
                self.assertEqual(table_values_for_case(case), values, sub)
