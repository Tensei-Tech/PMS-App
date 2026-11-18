"""Tabs linked to their case category (migration 0195) and sent with it by the API."""
import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import DashboardSubtab, DashboardTile, Form6Tab, Form15Tab
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import (
    get_dashboard_subtabs,
    get_dashboard_tiles,
    get_form_tabs,
)

migration = importlib.import_module('apps.crimetab.migrations.0195_tab_category_links_and_labels')


class TabCategoryLinkTests(TestCase):
    def setUp(self):
        for model in (DashboardTile, DashboardSubtab, Form15Tab, Form6Tab):
            model.objects.all().delete()
        CaseCategory.objects.update(is_active=False)
        g1, _ = CaseCategoryGroup.objects.get_or_create(group_id=1, defaults={'group_name': '1 to 5'})
        g2, _ = CaseCategoryGroup.objects.get_or_create(group_id=2, defaults={'group_name': 'Part 6'})

        def cat(name, code, group=None, order=0):
            return CaseCategory.objects.create(category_name=name, category_code=code, group=group,
                                               display_order=order, is_active=True)

        self.rti = cat('RTI', 'STAND_RTI', order=1)
        self.murder = cat('Murder', '101', g1, 2)
        self.wheeler = cat('Two/Four Wheeler Theft', '123', g1, 3)
        self.pocso = cat('POCSO', '604', g2, 4)

    def test_rows_are_linked_the_way_the_app_found_them(self):
        DashboardTile.objects.create(label='RTI', module_key='application', category_code='STAND_RTI',
                                     section='special')
        DashboardTile.objects.create(label='Two/Four\nWheeler Theft', module_key='two_four_wheeler',
                                     section='cases')
        DashboardTile.objects.create(label='Monthly', module_key='monthly', section='stats')
        DashboardSubtab.objects.create(parent_key='murder', label='Murder', screen_key='category')
        DashboardSubtab.objects.create(parent_key='passport', label='Passport', screen_key='passport')
        Form15Tab.objects.create(tab_name='Murder', category_code='101')
        Form15Tab.objects.create(tab_name='Missing')  # no such category
        Form6Tab.objects.create(tab_name='P.O.C.S.O')  # spelled differently

        migration.link_categories(django_apps, None)

        tile = lambda key: DashboardTile.objects.get(module_key=key).category_id  # noqa: E731
        self.assertEqual(tile('application'), self.rti.category_id)
        self.assertEqual(tile('two_four_wheeler'), self.wheeler.category_id)
        self.assertIsNone(tile('monthly'))  # statistics tiles are not one category
        self.assertEqual(DashboardSubtab.objects.get(label='Murder').category_id, self.murder.category_id)
        self.assertIsNone(DashboardSubtab.objects.get(label='Passport').category_id)
        self.assertEqual(Form15Tab.objects.get(tab_name='Murder').category_id, self.murder.category_id)
        self.assertIsNone(Form15Tab.objects.get(tab_name='Missing').category_id)
        self.assertEqual(Form6Tab.objects.get(tab_name='P.O.C.S.O').category_id, self.pocso.category_id)

    def test_api_sends_the_category_and_labels(self):
        Form15Tab.objects.create(tab_name='Killings', category=self.murder, label_mr='खून')
        DashboardTile.objects.create(label='RTI', module_key='application', category=self.rti,
                                     section='special', label_hi='सूचना')
        DashboardSubtab.objects.create(parent_key='murder', label='Murder', category=self.murder)

        tab = get_form_tabs('1_5')[0]
        self.assertEqual((tab['tab_name'], tab['category_name'], tab['label_mr']),
                         ('Killings', 'Murder', 'खून'))
        tile = get_dashboard_tiles()[0]
        self.assertEqual((tile['category_id'], tile['category_name'], tile['label_hi']),
                         (self.rti.category_id, 'RTI', 'सूचना'))
        self.assertEqual(get_dashboard_subtabs()[0]['category_name'], 'Murder')

    def test_deleting_a_category_only_clears_the_link(self):
        tab = Form15Tab.objects.create(tab_name='Murder', category=self.murder)
        self.murder.delete()
        tab.refresh_from_db()
        self.assertIsNone(tab.category_id)
