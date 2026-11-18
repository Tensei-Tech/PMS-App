"""Dashboard tiles table (migration 0191) and GET /api/categories/dashboard-tiles/."""
import importlib
import json

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import DashboardTile, ModuleSetting
from apps.crimetab.services.dynamic_form_service import get_dashboard_tiles
from apps.crimetab.tests.auth_helpers import district_officer_headers

migration = importlib.import_module('apps.crimetab.migrations.0191_dashboard_tiles')


class DashboardTileSeedTests(TestCase):
    def setUp(self):
        # Start from an empty table, whatever the test database already has
        DashboardTile.objects.all().delete()
        ModuleSetting.objects.update_or_create(
            module_key='dashboard', setting_key='tools',
            defaults={'setting_value': json.dumps([
                {'module_key': 'licence', 'label': 'Licence', 'icon': 'assignment_ind_rounded',
                 'display_order': 1, 'is_active': False},
                {'module_key': 'tadipar', 'label': 'Tadipar', 'icon': 'assets/icons/tadipar.svg',
                 'icon_type': 'asset', 'category_code': 'tadipar', 'display_order': 2, 'is_active': True},
                {'module_key': 'irad', 'label': 'IRAD', 'icon': 'analytics_rounded',
                 'display_order': 3, 'is_active': False},
                {'module_key': 'dar', 'label': 'DAR/IRAD', 'icon': 'folder_rounded',
                 'display_order': 4, 'is_active': True},
            ])},
        )

    def seed(self):
        migration.seed_tiles(django_apps, None)

    def test_every_tile_but_forms_is_seeded_in_grid_order(self):
        self.seed()
        labels = list(DashboardTile.objects.order_by('display_order').values_list('label', flat=True))
        self.assertEqual(labels[:3], ['Monthly', 'Pending', 'Detected'])
        self.assertNotIn('Forms', labels)
        self.assertIn('Passport/\nPVR/Licence', labels)
        self.assertEqual(labels[-2:], ['Tadipar', 'DAR/IRAD'])

    def test_tools_come_from_the_setting_without_hidden_ones(self):
        self.seed()
        tools = DashboardTile.objects.filter(section='tools').order_by('display_order')
        self.assertEqual([t.module_key for t in tools], ['tadipar', 'dar'])
        tadipar = tools[0]
        self.assertEqual(tadipar.icon_type, 'asset')
        self.assertEqual(tadipar.category_code, 'tadipar')
        self.assertFalse(DashboardTile.objects.filter(module_key__in=['licence', 'irad']).exists())

    def test_seeding_twice_adds_nothing(self):
        self.seed()
        count = DashboardTile.objects.count()
        self.seed()
        self.assertEqual(DashboardTile.objects.count(), count)

    def test_inactive_tiles_are_not_returned(self):
        self.seed()
        DashboardTile.objects.filter(module_key='coin').update(is_active=False)
        keys = [t['module_key'] for t in get_dashboard_tiles()]
        self.assertNotIn('coin', keys)
        self.assertIn('murder', keys)

    def test_endpoint_lists_tiles_in_order(self):
        self.seed()
        response = self.client.get('/api/categories/dashboard-tiles/', **district_officer_headers())
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data[0]['label'], 'Monthly')
        self.assertEqual(
            [t['display_order'] for t in data], sorted(t['display_order'] for t in data))
