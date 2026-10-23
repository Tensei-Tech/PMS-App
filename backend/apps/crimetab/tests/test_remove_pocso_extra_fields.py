import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, OptionValue
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

caw = importlib.import_module('apps.crimetab.migrations.0115_crime_against_women_extra_fields')
pocso = importlib.import_module('apps.crimetab.migrations.0110_pocso_extra_fields')
mig = importlib.import_module('apps.crimetab.migrations.0117_remove_pocso_extra_fields')


class RemovePocsoExtraFieldsTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=2, defaults={'group_name': 'Part 6', 'group_code': 'VI', 'display_order': 2}
        )
        self.pocso = CaseCategory.objects.filter(category_code='STAND_POCSO').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST POCSO',
                                        category_code='STAND_POCSO', display_order=1)
        caw.forwards(django_apps, None)
        pocso.forwards(django_apps, None)

    def _keys(self):
        return {f['field_key'] for f in get_form_definition(self.pocso.pk)['fields']}

    def test_removes_bundle_links_and_options(self):
        self.assertTrue(any(k.startswith('pocso_') for k in self._keys()))
        mig.forwards(django_apps, None)
        self.assertFalse(any(k.startswith('pocso_') for k in self._keys()))
        self.assertFalse(FieldTemplate.objects.filter(template_name=mig.TEMPLATE_NAME).exists())
        self.assertFalse(OptionValue.objects.filter(option_group__in=mig.OPTION_GROUPS).exists())
        # Crime Against Women still uses the relation list
        self.assertTrue(OptionValue.objects.filter(option_group='victim_accused_relations').exists())
        mig.forwards(django_apps, None)  # idempotent

    def test_backwards_rebuilds_bundle(self):
        mig.forwards(django_apps, None)
        mig.backwards(django_apps, None)
        keys = self._keys()
        self.assertIn('pocso_victim_name', keys)
        self.assertIn('pocso_relation_to_accused', keys)
        self.assertNotIn('pocso_sec_82_83_action', keys)
