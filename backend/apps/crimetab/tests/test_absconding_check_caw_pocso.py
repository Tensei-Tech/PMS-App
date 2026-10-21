import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import CategoryFieldTemplate, FieldTemplate
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

caw = importlib.import_module('apps.crimetab.migrations.0115_crime_against_women_extra_fields')
every = importlib.import_module('apps.crimetab.migrations.0116_every_crime_vehicle_and_absconding_fields')
pocso = importlib.import_module('apps.crimetab.migrations.0119_pocso_extra_fields_again')
mig = importlib.import_module('apps.crimetab.migrations.0120_absconding_check_caw_and_pocso_only')


class AbscondingCheckTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1}
        )
        common, _ = FieldTemplate.objects.get_or_create(template_name=mig.COMMON)

        def cat(code, name):
            c = CaseCategory.objects.filter(category_code=code).first() or \
                CaseCategory.objects.create(group=group, category_name=name, category_code=code, display_order=1)
            CategoryFieldTemplate.objects.get_or_create(category=c, template=common)
            return c

        self.women = cat('STAND_WOMEN', 'TEST Crime Against Women')
        self.pocso = cat('STAND_POCSO', 'TEST POCSO')
        self.theft = cat('TEST_THEFT', 'TEST Theft')
        caw.forwards(django_apps, None)
        pocso.forwards(django_apps, None)
        every.forwards(django_apps, None)  # the check in the Common Form, as 0116 left it
        mig.forwards(django_apps, None)

    def _keys(self, category):
        return {f['field_key'] for f in get_form_definition(category.pk)['fields']}

    def test_only_crime_against_women_and_pocso_show_it(self):
        self.assertIn('caw_sec_82_83_action', self._keys(self.women))
        self.assertIn('caw_sec_82_83_action_date', self._keys(self.women))
        self.assertIn('pocso_sec_82_83_action', self._keys(self.pocso))
        theft = self._keys(self.theft)
        self.assertFalse({'accused_sec_82_83_action', 'caw_sec_82_83_action',
                          'pocso_sec_82_83_action'} & theft)
        mig.forwards(django_apps, None)  # idempotent

    def test_date_shows_on_yes(self):
        fields = {f['field_key']: f for f in get_form_definition(self.women.pk)['fields']}
        date = fields['caw_sec_82_83_action_date']
        self.assertEqual((date['depends_on_field_key'], date['depends_on_value']),
                         ('caw_sec_82_83_action', 'Yes'))

    def test_backwards_puts_it_back_in_common_form(self):
        mig.backwards(django_apps, None)
        self.assertIn('accused_sec_82_83_action', self._keys(self.theft))
        self.assertNotIn('caw_sec_82_83_action', self._keys(self.women))
