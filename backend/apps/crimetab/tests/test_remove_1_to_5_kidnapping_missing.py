import importlib

from django.apps import apps as django_apps
from django.db import connection
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.crimetab.models import CaseCategory, CaseCategoryLink

mig = importlib.import_module('apps.crimetab.migrations.0154_remove_1_to_5_kidnapping_missing')


class _Editor:
    connection = connection


class Remove1To5KidnappingMissingTests(TestCase):
    """The 1-to-5 Kidnapping and Missing sub-tabs and their cases are removed; standalone ones stay."""

    def setUp(self):
        def cat(code, name):
            return CaseCategory.objects.filter(category_code=code).first() or \
                CaseCategory.objects.create(category_name=name, category_code=code)
        self.kid = cat('120', 'Kidnapping')
        self.missing = cat('124', 'Missing')
        self.stand_kid = cat('STAND_KIDNAP', 'Kidnapping')
        self.theft = cat('TEST_THEFT', 'Theft')

        def case(cid, sub, module, link=None):
            c = CaseRecord.objects.create(id=cid, case_number=f'CR/{cid}', title='T', sub_category=sub,
                                          module_key=module, station_name='S', extra_fields={})
            if link:
                CaseCategoryLink.objects.create(case=c, category=link, is_primary=True)
            return c
        case('K1', 'Kidnapping', 'form_1_5')
        case('M1', 'Missing', 'form_1_5', link=self.missing)
        case('M2', 'missing', 'other_module', link=self.missing)   # linked to the sub-tab
        case('SK1', 'Kidnapping', 'kid', link=self.stand_kid)       # standalone: stays
        case('T1', 'Theft', 'form_1_5', link=self.theft)            # other type: stays

    def test_removes_sub_tabs_and_their_cases_only(self):
        mig.forwards(django_apps, _Editor())
        self.assertFalse(CaseCategory.objects.filter(category_code__in=('120', '124')).exists())
        self.assertTrue(CaseCategory.objects.filter(category_code='STAND_KIDNAP').exists())
        self.assertEqual(set(CaseRecord.objects.values_list('id', flat=True)), {'SK1', 'T1'})
        self.assertTrue(CaseCategoryLink.objects.filter(case_id='SK1').exists())

    def test_running_twice_is_harmless(self):
        mig.forwards(django_apps, _Editor())
        mig.forwards(django_apps, _Editor())
        self.assertEqual(set(CaseRecord.objects.values_list('id', flat=True)), {'SK1', 'T1'})
