import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import CategoryFieldTemplate, FieldTemplate, OptionValue
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

every = importlib.import_module('apps.crimetab.migrations.0116_every_crime_vehicle_and_absconding_fields')
mig = importlib.import_module('apps.crimetab.migrations.0119_pocso_extra_fields_again')


class PocsoExtraFieldsAgainTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=2, defaults={'group_name': 'Part 6', 'group_code': 'VI', 'display_order': 2}
        )
        common, _ = FieldTemplate.objects.get_or_create(template_name=every.COMMON)
        self.pocso = CaseCategory.objects.filter(category_code='STAND_POCSO').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST POCSO',
                                        category_code='STAND_POCSO', display_order=1)
        self.other = CaseCategory.objects.create(group=group, category_name='TEST Other',
                                                 category_code='TEST_OTHER', display_order=2)
        CategoryFieldTemplate.objects.get_or_create(category=self.pocso, template=common)
        every.forwards(django_apps, None)  # Common Form Sec 82, 83 check
        mig.forwards(django_apps, None)

    def _fields(self, category):
        return {f['field_key']: f for f in get_form_definition(category.pk)['fields']}

    def test_pocso_list_fields_present(self):
        fields = self._fields(self.pocso)
        for key in ('pocso_victim_name', 'pocso_victim_age', 'pocso_victim_aadhaar', 'pocso_age_proof',
                    'pocso_age_proof_other', 'pocso_victim_medical_date', 'pocso_statement_by_lady_officer',
                    'pocso_164_statement_date', 'pocso_counselling_date', 'pocso_victim_dna_date',
                    'pocso_victim_fsl_report_date', 'pocso_accused_fsl_sent_date',
                    'pocso_govt_vehicle_sd_entry', 'pocso_case_diary_vehicle_entry'):
            self.assertIn(key, fields)
        self.assertEqual(fields['pocso_victim_name']['field_type'], 'dropdown')
        self.assertEqual(fields['pocso_age_proof_other']['depends_on_value'], 'Other')
        self.assertTrue(OptionValue.objects.filter(option_group='pocso_victim_names',
                                                   option_value='ABC 1').exists())
        self.assertFalse(any(k.startswith('pocso_') for k in self._fields(self.other)))

    def test_no_duplicate_of_common_form_checks(self):
        keys = set(self._fields(self.pocso))
        self.assertIn('accused_sec_82_83_action', keys)  # from the Common Form
        self.assertFalse(set(mig.DROPPED) & keys)
        mig.forwards(django_apps, None)  # idempotent
        self.assertFalse(set(mig.DROPPED) & set(self._fields(self.pocso)))

    def test_backwards_removes_bundle(self):
        mig.backwards(django_apps, None)
        self.assertFalse(any(k.startswith('pocso_') for k in self._fields(self.pocso)))
        self.assertFalse(FieldTemplate.objects.filter(template_name=mig.TEMPLATE_NAME).exists())
