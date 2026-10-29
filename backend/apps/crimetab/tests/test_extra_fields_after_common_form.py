import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models import CaseCategory, CategoryFieldTemplate, FieldTemplate
from apps.crimetab.services.dynamic_form_service import get_form_definition

after = importlib.import_module('apps.crimetab.migrations.0157_extra_fields_after_common_form')
hurt = importlib.import_module('apps.crimetab.migrations.0140_hurt_extra_fields')
assault = importlib.import_module('apps.crimetab.migrations.0145_assault_riot_extra_fields')
robbery = importlib.import_module('apps.crimetab.migrations.0143_robbery_dacoity_extra_fields')

BASELINE = 'Common Form Baseline Template'


class ExtraFieldsAfterCommonFormTests(TestCase):
    """Each new extra-field template is listed after the whole common form, in its own order."""

    def setUp(self):
        self.baseline, _ = FieldTemplate.objects.get_or_create(template_name=BASELINE)
        self.baseline.fields.get_or_create(field_key='test_common_last', defaults={
            'field_label': 'Common last', 'field_type': 'text', 'display_order': 1090})
        self.assault = CaseCategory.objects.filter(category_code='111').first() or \
            CaseCategory.objects.create(category_name='Assault on Public Servant', category_code='111')
        self.robbery = CaseCategory.objects.filter(category_code='104').first() or \
            CaseCategory.objects.create(category_name='Robbery', category_code='104')
        for mig in (hurt, assault, robbery):
            mig.forwards(django_apps, None)
        # Put every template back below 2000 first, as on a database where 0157 has not run.
        after.backwards(django_apps, None)
        for cat in (self.assault, self.robbery):
            CategoryFieldTemplate.objects.get_or_create(category=cat, template=self.baseline)
        after.forwards(django_apps, None)

    def _keys(self, cat):
        return [f['field_key'] for f in get_form_definition(cat.category_id)['fields']]

    def test_robbery_fields_follow_the_common_form_in_order(self):
        keys = self._keys(self.robbery)
        rd = [k for k in keys if k.startswith('rd_')]
        self.assertGreater(keys.index(rd[0]), keys.index('test_common_last'))
        self.assertEqual(rd[0], 'rd_stolen_props')
        self.assertEqual(rd[-1], 'rd_fsl_report_time')

    def test_assault_shows_common_form_then_injured_then_non_applicants(self):
        keys = self._keys(self.assault)
        common = keys.index('test_common_last')
        hurt_keys = [i for i, k in enumerate(keys) if k.startswith('hurt_')]
        na_keys = [i for i, k in enumerate(keys) if k.startswith('non_applicant')]
        self.assertTrue(common < min(hurt_keys) and max(hurt_keys) < min(na_keys))

    def test_running_twice_moves_once(self):
        after.forwards(django_apps, None)
        for name, offset in (('Hurt Extra Fields', 2000), ('Non-Applicant Details', 3000)):
            orders = list(FieldTemplate.objects.get(template_name=name).fields.values_list('display_order', flat=True))
            self.assertEqual(min(orders), offset + 10, name)
