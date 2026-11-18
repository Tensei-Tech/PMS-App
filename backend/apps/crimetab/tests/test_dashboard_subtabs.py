"""Dashboard sub-tabs table (migration 0192) and GET /api/categories/dashboard-subtabs/."""
import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import DashboardSubtab
from apps.crimetab.services.dynamic_form_service import get_dashboard_subtabs
from apps.crimetab.tests.auth_helpers import district_officer_headers

migration = importlib.import_module('apps.crimetab.migrations.0192_dashboard_subtabs')


class DashboardSubtabSeedTests(TestCase):
    def setUp(self):
        DashboardSubtab.objects.all().delete()
        migration.seed_subtabs(django_apps, None)

    def labels(self, parent_key):
        return list(DashboardSubtab.objects.filter(parent_key=parent_key)
                    .order_by('display_order').values_list('label', flat=True))

    def test_sub_tabs_of_every_tile_are_seeded_in_order(self):
        self.assertEqual(self.labels('murder'), ['Murder', 'Attempt to Murder'])
        self.assertEqual(self.labels('dacoity'), ['Dacoity', 'Robbery'])
        self.assertEqual(self.labels('cheating'), ['Cheating', 'CBT'])
        self.assertEqual(self.labels('passport'), ['Passport', 'PVR', 'Licence'])
        self.assertEqual(self.labels('nafis'), ['NAFIS', 'Fingerprint'])
        self.assertEqual(self.labels('dar'), ['DAR', 'IRAD'])
        self.assertEqual(self.labels('disposal'), ['Form 1 to 5', 'Form 6'])

    def test_category_sub_tabs_open_1_to_5_and_modules_open_their_screen(self):
        self.assertEqual(
            set(DashboardSubtab.objects.filter(parent_key='murder').values_list('screen_key', flat=True)),
            {'category'})
        self.assertEqual(
            DashboardSubtab.objects.get(parent_key='passport', label='Licence').screen_key, 'licence')

    def test_seeding_twice_adds_nothing(self):
        count = DashboardSubtab.objects.count()
        migration.seed_subtabs(django_apps, None)
        self.assertEqual(DashboardSubtab.objects.count(), count)

    def test_inactive_sub_tabs_are_not_returned(self):
        DashboardSubtab.objects.filter(parent_key='passport', label='PVR').update(is_active=False)
        passport = [t['label'] for t in get_dashboard_subtabs() if t['parent_key'] == 'passport']
        self.assertEqual(passport, ['Passport', 'Licence'])

    def test_endpoint_lists_sub_tabs(self):
        response = self.client.get('/api/categories/dashboard-subtabs/', **district_officer_headers())
        self.assertEqual(response.status_code, 200)
        murder = [t['label'] for t in response.json() if t['parent_key'] == 'murder']
        self.assertEqual(murder, ['Murder', 'Attempt to Murder'])
