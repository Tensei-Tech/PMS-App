import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import CategoryFieldTemplate, FieldTemplate
from apps.crimetab.models.groupings import CaseCategory

mig = importlib.import_module('apps.crimetab.migrations.0121_ad_suicide_and_other_subtabs')


class AdSubtabsTests(TestCase):
    def setUp(self):
        self.ad = CaseCategory.objects.filter(category_code='STAND_AD').first() or \
            CaseCategory.objects.create(category_name='A.D.', category_code='STAND_AD', display_order=40)
        FieldTemplate.objects.get_or_create(template_name=mig.COMMON)
        mig.forwards(django_apps, None)

    def test_two_children_under_ad_with_common_form(self):
        kids = list(CaseCategory.objects.filter(parent_category=self.ad).order_by('display_order')
                    .values_list('category_name', 'category_code'))
        self.assertEqual(kids, [('Suicide', 'STAND_AD_SUICIDE'), ('Other', 'STAND_AD_OTHER')])
        for code in ('STAND_AD_SUICIDE', 'STAND_AD_OTHER'):
            self.assertTrue(CategoryFieldTemplate.objects.filter(
                category__category_code=code, template__template_name=mig.COMMON).exists())
        mig.forwards(django_apps, None)  # idempotent
        self.assertEqual(CaseCategory.objects.filter(parent_category=self.ad).count(), 2)

    def test_backwards_removes_children(self):
        mig.backwards(django_apps, None)
        self.assertFalse(CaseCategory.objects.filter(parent_category=self.ad).exists())
        self.assertTrue(CaseCategory.objects.filter(pk=self.ad.pk).exists())
