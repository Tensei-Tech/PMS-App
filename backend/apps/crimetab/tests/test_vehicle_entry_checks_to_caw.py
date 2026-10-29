import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import CategoryFieldTemplate, FieldTemplate
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

caw = importlib.import_module('apps.crimetab.migrations.0115_crime_against_women_extra_fields')
every = importlib.import_module('apps.crimetab.migrations.0116_every_crime_vehicle_and_absconding_fields')
mig = importlib.import_module('apps.crimetab.migrations.0118_vehicle_entry_checks_to_crime_against_women')

COMMON_KEYS = {c for _, c, _, _, _ in mig.CHECKS}
CAW_KEYS = {k for _, _, _, k, _ in mig.CHECKS}


class VehicleEntryChecksToCawTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1}
        )
        common, _ = FieldTemplate.objects.get_or_create(template_name=mig.COMMON)
        self.women = CaseCategory.objects.filter(category_code='STAND_WOMEN').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST Crime Against Women',
                                        category_code='STAND_WOMEN', display_order=1)
        self.other = CaseCategory.objects.create(group=group, category_name='TEST Other',
                                                 category_code='TEST_OTHER', display_order=2)
        for cat in (self.women, self.other):
            CategoryFieldTemplate.objects.get_or_create(category=cat, template=common)
        caw.forwards(django_apps, None)
        every.forwards(django_apps, None)  # the checks in the Common Form, as 0116 left them
        mig.forwards(django_apps, None)

    def _keys(self, category):
        return {f['field_key'] for f in get_form_definition(category.pk)['fields']}

    def test_only_crime_against_women_shows_the_checks(self):
        self.assertTrue(CAW_KEYS <= self._keys(self.women))
        self.assertFalse(COMMON_KEYS & self._keys(self.women))
        self.assertFalse((CAW_KEYS | COMMON_KEYS) & self._keys(self.other))
        # The Section 82, 83 check stays in the Common Form
        self.assertIn('accused_sec_82_83_action', self._keys(self.other))
        mig.forwards(django_apps, None)  # idempotent

    def test_backwards_puts_them_back_in_common_form(self):
        mig.backwards(django_apps, None)
        self.assertTrue(COMMON_KEYS <= self._keys(self.other))
        self.assertFalse(CAW_KEYS & self._keys(self.women))
