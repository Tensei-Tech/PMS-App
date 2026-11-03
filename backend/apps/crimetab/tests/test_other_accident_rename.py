import importlib

from django.apps import apps as django_apps
from django.db import connection
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategory

mig = importlib.import_module('apps.crimetab.migrations.0163_rename_normal_accident_to_other_accident')


class _SchemaEditor:
    connection = connection


class OtherAccidentRenameTests(TestCase):
    """Migration 0163: Normal Accident is renamed Other Accident."""

    def setUp(self):
        for code in mig.CATEGORY_CODES:
            CaseCategory.objects.filter(category_code=code).delete()
            CaseCategory.objects.create(category_name=mig.OLD_NAME, category_code=code)
        self.road = CaseCategory.objects.create(category_name='Road Accident', category_code='TEST_ACC_ROAD')
        self.case = CaseRecord.objects.create(
            id='test-oacc-1', case_number='CR/1', title='TEST', sub_category=mig.OLD_NAME,
            module_key='form_1_5', extra_fields={})
        self.road_case = CaseRecord.objects.create(
            id='test-oacc-2', case_number='CR/2', title='TEST', sub_category='Road Accident',
            module_key='form_1_5', extra_fields={})

    def names(self):
        return set(CaseCategory.objects.filter(category_code__in=mig.CATEGORY_CODES)
                   .values_list('category_name', flat=True))

    def test_renames_tab_and_its_cases_only(self):
        mig.forwards(django_apps, _SchemaEditor())
        self.assertEqual(self.names(), {mig.NEW_NAME})
        self.case.refresh_from_db()
        self.road_case.refresh_from_db()
        self.road.refresh_from_db()
        self.assertEqual(self.case.sub_category, mig.NEW_NAME)
        self.assertEqual(self.road_case.sub_category, 'Road Accident')
        self.assertEqual(self.road.category_name, 'Road Accident')

    def test_idempotent_and_backwards(self):
        mig.forwards(django_apps, _SchemaEditor())
        mig.forwards(django_apps, _SchemaEditor())
        self.assertEqual(self.names(), {mig.NEW_NAME})
        mig.backwards(django_apps, _SchemaEditor())
        self.assertEqual(self.names(), {mig.OLD_NAME})
        self.case.refresh_from_db()
        self.assertEqual(self.case.sub_category, mig.OLD_NAME)
