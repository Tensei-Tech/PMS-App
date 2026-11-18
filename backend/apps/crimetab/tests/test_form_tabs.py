"""Tables form_1_5_tabs / form_6_tabs (migration 0193) and their endpoints."""
import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import Form15Tab, Form6Tab
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_tabs
from apps.crimetab.tests.auth_helpers import district_officer_headers

migration = importlib.import_module('apps.crimetab.migrations.0193_form_1_5_and_form_6_tabs')


class FormTabsTests(TestCase):
    def setUp(self):
        Form15Tab.objects.all().delete()
        Form6Tab.objects.all().delete()

    def names(self, model):
        return list(model.objects.order_by('display_order').values_list('tab_name', flat=True))

    def test_tabs_are_copied_from_the_groups_in_order(self):
        g1, _ = CaseCategoryGroup.objects.get_or_create(group_id=1, defaults={'group_name': '1 to 5'})
        g2, _ = CaseCategoryGroup.objects.get_or_create(group_id=2, defaults={'group_name': 'Part 6'})
        CaseCategory.objects.filter(group__in=[g1, g2]).update(is_active=False)
        for order, name in [(2, 'Attempt to Murder'), (1, 'Murder'), (3, 'POCSO'), (4, 'Missing')]:
            CaseCategory.objects.create(category_name=name, category_code=f'T{order}',
                                        group=g1, display_order=order, is_active=True)
        CaseCategory.objects.create(category_name='NDPS', category_code='T9',
                                    group=g2, display_order=1, is_active=True)

        migration.seed_tabs(django_apps, None)

        # POCSO and Missing were hidden from "1 to 5", so they get no tab there
        self.assertEqual(self.names(Form15Tab), ['Murder', 'Attempt to Murder'])
        self.assertEqual(Form15Tab.objects.get(tab_name='Murder').category_code, 'T1')
        self.assertEqual(self.names(Form6Tab), ['NDPS'])

    def test_built_in_names_when_the_groups_are_empty(self):
        CaseCategory.objects.filter(group_id__in=[1, 2]).update(is_active=False)
        migration.seed_tabs(django_apps, None)
        self.assertEqual(self.names(Form15Tab), migration.DEFAULT_FORM_1_5)
        self.assertEqual(self.names(Form6Tab), migration.DEFAULT_FORM_6)

    def test_seeding_twice_adds_nothing(self):
        migration.seed_tabs(django_apps, None)
        counts = (Form15Tab.objects.count(), Form6Tab.objects.count())
        migration.seed_tabs(django_apps, None)
        self.assertEqual((Form15Tab.objects.count(), Form6Tab.objects.count()), counts)

    def test_inactive_tabs_are_not_returned(self):
        Form15Tab.objects.create(tab_name='Murder', display_order=10)
        Form15Tab.objects.create(tab_name='Riot', display_order=20, is_active=False)
        self.assertEqual([t['tab_name'] for t in get_form_tabs('1_5')], ['Murder'])
        self.assertEqual(get_form_tabs('unknown'), [])

    def test_endpoints(self):
        Form15Tab.objects.create(tab_name='Theft', display_order=20)
        Form15Tab.objects.create(tab_name='Murder', display_order=10)
        Form6Tab.objects.create(tab_name='POCSO', display_order=10)
        headers = district_officer_headers()
        r15 = self.client.get('/api/categories/form-1-5-tabs/', **headers)
        r6 = self.client.get('/api/categories/form-6-tabs/', **headers)
        self.assertEqual([t['tab_name'] for t in r15.json()], ['Murder', 'Theft'])
        self.assertEqual([t['tab_name'] for t in r6.json()], ['POCSO'])
