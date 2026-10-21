import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import (
    CategoryFieldTemplate, FieldTemplate, FieldTemplateField, OptionValue,
)
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

caw = importlib.import_module('apps.crimetab.migrations.0115_crime_against_women_extra_fields')
every = importlib.import_module('apps.crimetab.migrations.0116_every_crime_vehicle_and_absconding_fields')
pocso = importlib.import_module('apps.crimetab.migrations.0110_pocso_extra_fields')


def _options(group):
    return list(OptionValue.objects.filter(option_group=group)
                .order_by('display_order').values_list('option_value', flat=True))


class CrimeAgainstWomenExtraFieldsTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1}
        )
        self.women = CaseCategory.objects.filter(category_code='STAND_WOMEN').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST Crime Against Women',
                                        category_code='STAND_WOMEN', display_order=1)
        self.other = CaseCategory.objects.create(group=group, category_name='TEST Other',
                                                 category_code='TEST_OTHER', display_order=2)
        caw.forwards(django_apps, None)

    def _fields(self, category):
        return {f['field_key']: f for f in get_form_definition(category.pk)['fields']}

    def test_fields_show_only_for_crime_against_women(self):
        fields = self._fields(self.women)
        for _, key, *_ in caw.FIELDS:
            self.assertIn(key, fields)
            self.assertFalse(fields[key]['is_required'])
        self.assertFalse(any(k.startswith('caw_') for k in self._fields(self.other)))

    def test_victim_name_select_only_and_option_lists(self):
        fields = self._fields(self.women)
        self.assertEqual(fields['caw_victim_name']['field_type'], 'dropdown')
        self.assertEqual(_options('caw_victim_names')[:3], ['ABC 1', 'ABC 2', 'ABC 3'])
        self.assertEqual(_options('yes_no_na'), ['Yes', 'No', 'Not Applicable'])
        self.assertIn('X (formerly Twitter)', _options('caw_digital_evidence_types'))
        self.assertEqual(_options('caw_document_types')[-1], 'Other')
        self.assertEqual(fields['caw_victim_mobile']['field_type'], 'mobile')
        self.assertEqual(fields['caw_victim_aadhaar']['field_type'], 'aadhaar')

    def test_follow_up_fields_show_on_yes_or_other(self):
        fields = self._fields(self.women)
        on = {k: (f['depends_on_field_key'], f['depends_on_value']) for k, f in fields.items()}
        self.assertEqual(on['caw_victim_fsl_sent'], ('caw_victim_dna', 'Yes'))
        self.assertEqual(on['caw_accused_fsl_report'], ('caw_accused_dna', 'Yes'))
        self.assertEqual(on['caw_viscera_fsl_sent'], ('caw_postmortem', 'Yes'))
        self.assertEqual(on['caw_digital_evidence_types'], ('caw_digital_evidence', 'Yes'))
        self.assertEqual(on['caw_digital_evidence_other'], ('caw_digital_evidence_types', 'Other'))
        self.assertEqual(on['caw_documents'], ('caw_documentary_evidence', 'Yes'))
        self.assertEqual(on['caw_chemical_recovered'], ('caw_acid_attack', 'Yes'))
        self.assertEqual(fields['caw_documents']['field_type'], 'repeating_group')
        self.assertEqual(fields['caw_document_type']['parent_field_key'], 'caw_documents')
        self.assertEqual(fields['caw_digital_evidence_types']['field_type'], 'multi_select')

    def test_idempotent_and_reversible(self):
        caw.forwards(django_apps, None)
        qs = FieldTemplateField.objects.filter(template__template_name=caw.TEMPLATE_NAME)
        self.assertEqual(qs.count(), len(caw.FIELDS))
        caw.backwards(django_apps, None)
        self.assertFalse(FieldTemplate.objects.filter(template_name=caw.TEMPLATE_NAME).exists())
        self.assertFalse(OptionValue.objects.filter(option_group='caw_victim_names').exists())


class EveryCrimeChecksTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=2, defaults={'group_name': 'Part 6', 'group_code': 'VI', 'display_order': 2}
        )
        self.common, _ = FieldTemplate.objects.get_or_create(template_name=every.COMMON)
        self.any_crime = CaseCategory.objects.create(group=group, category_name='TEST Any Crime',
                                                     category_code='TEST_ANY', display_order=1)
        CategoryFieldTemplate.objects.get_or_create(category=self.any_crime, template=self.common)
        self.pocso = CaseCategory.objects.filter(category_code='STAND_POCSO').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST POCSO',
                                        category_code='STAND_POCSO', display_order=2)
        CategoryFieldTemplate.objects.get_or_create(category=self.pocso, template=self.common)
        caw.forwards(django_apps, None)     # relation options
        pocso.forwards(django_apps, None)   # POCSO bundle as 0110 left it
        every.forwards(django_apps, None)

    def _keys(self, category):
        return {f['field_key'] for f in get_form_definition(category.pk)['fields']}

    def test_every_crime_gets_vehicle_and_absconding_checks(self):
        keys = self._keys(self.any_crime)
        for key in ('govt_vehicle_sd_entry', 'case_diary_vehicle_entry',
                    'accused_sec_82_83_action', 'accused_sec_82_83_action_date'):
            self.assertIn(key, keys)

    def test_pocso_drops_duplicates_and_gets_relation(self):
        keys = self._keys(self.pocso)
        self.assertFalse({k for _, k, *_ in every.POCSO_REMOVED} & keys)
        self.assertIn('pocso_relation_to_accused', keys)
        self.assertIn('govt_vehicle_sd_entry', keys)  # from the Common Form instead

    def test_backwards_restores_pocso_fields(self):
        every.backwards(django_apps, None)
        keys = self._keys(self.pocso)
        self.assertTrue({k for _, k, *_ in every.POCSO_REMOVED} <= keys)
        self.assertNotIn('govt_vehicle_sd_entry', keys)
        self.assertNotIn('pocso_relation_to_accused', keys)
