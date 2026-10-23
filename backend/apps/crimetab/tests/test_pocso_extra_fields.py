import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField, OptionValue
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

mig = importlib.import_module('apps.crimetab.migrations.0110_pocso_extra_fields')


class PocsoExtraFieldsTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=2, defaults={'group_name': 'Part 6', 'group_code': 'VI', 'display_order': 2}
        )
        self.pocso = CaseCategory.objects.filter(category_code='STAND_POCSO').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST POCSO',
                                        category_code='STAND_POCSO', display_order=1)
        self.other = CaseCategory.objects.create(group=group, category_name='TEST Other',
                                                 category_code='TEST_OTHER', display_order=2)
        mig.forwards(django_apps, None)  # links the categories created above

    def _fields(self, category):
        return {f['field_key']: f for f in get_form_definition(category.pk)['fields']}

    def test_fields_show_only_for_pocso(self):
        fields = self._fields(self.pocso)
        for _, key, *_ in mig.FIELDS:
            self.assertIn(key, fields)
            self.assertFalse(fields[key]['is_required'])
        self.assertFalse(any(k.startswith('pocso_') for k in self._fields(self.other)))

    def test_victim_name_is_select_only_abc_list(self):
        f = self._fields(self.pocso)['pocso_victim_name']
        self.assertEqual(f['field_type'], 'dropdown')
        self.assertEqual(f['options_source'], '/api/options/pocso_victim_names/')
        names = list(OptionValue.objects.filter(option_group='pocso_victim_names')
                     .order_by('display_order').values_list('option_value', flat=True))
        self.assertEqual(names[:3], ['ABC 1', 'ABC 2', 'ABC 3'])

    def test_age_proof_options_and_kyc_types(self):
        proofs = set(OptionValue.objects.filter(option_group='pocso_age_proofs')
                     .values_list('option_value', flat=True))
        self.assertEqual(proofs, {'TC', 'Bonafide Certificate', 'Aadhaar Card', 'Ossification Test', 'Other'})
        fields = self._fields(self.pocso)
        self.assertEqual(fields['pocso_victim_mobile']['field_type'], 'mobile')
        self.assertEqual(fields['pocso_victim_aadhaar']['field_type'], 'aadhaar')

    def test_each_date_shows_only_on_yes(self):
        fields = self._fields(self.pocso)
        for key, f in fields.items():
            if key.startswith('pocso_') and key.endswith('_date'):
                parent = f['depends_on_field_key']
                self.assertEqual(key, f'{parent}_date')
                self.assertEqual(f['depends_on_value'], 'Yes')
                self.assertEqual(fields[parent]['field_type'], 'radio')

    def test_idempotent_and_reversible(self):
        mig.forwards(django_apps, None)
        qs = FieldTemplateField.objects.filter(template__template_name=mig.TEMPLATE_NAME)
        total = qs.count()  # later migrations may have added more fields to the template
        self.assertEqual(qs.filter(field_key__in=[f[1] for f in mig.FIELDS]).count(), len(mig.FIELDS))
        mig.forwards(django_apps, None)
        self.assertEqual(qs.count(), total)
        mig.backwards(django_apps, None)
        self.assertFalse(FieldTemplate.objects.filter(template_name=mig.TEMPLATE_NAME).exists())
        self.assertFalse(OptionValue.objects.filter(option_group='pocso_victim_names').exists())
