"""
The Monthly comparison and a category's sub-tabs must not make one database
query per case or per sub-category: the live server took 10 s (146 queries)
and 2.8 s (38 queries) for them.
"""
from datetime import datetime, timezone

from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from apps.cases.comparative_service import MonthlyCrimeComparativeService
from apps.cases.models import CaseRecord
from apps.crimetab.models import CaseCategory, CaseCategoryLink
from apps.crimetab.services.counter_service import (
    CategoryIndex,
    get_descendant_category_ids,
    get_twin_category_ids,
)


def _queries(fn):
    with CaptureQueriesContext(connection) as ctx:
        result = fn()
    return len(ctx), result


class ComparativeQueryCountTests(TestCase):
    def setUp(self):
        self.murder = CaseCategory.objects.create(category_name='QC Murder', category_code='QC_MURDER')
        self.n = 0

    def _add_cases(self, count):
        for _ in range(count):
            self.n += 1
            case = CaseRecord.objects.create(
                id=f'QC{self.n}', case_number=f'CR/QC{self.n}', title='T', sub_category='QC Murder',
                module_key='form_1_5', station_name='QC Station', extra_fields={},
                incident_date=datetime(2026, 10, 5, tzinfo=timezone.utc))
            CaseCategoryLink.objects.create(case=case, category=self.murder, is_primary=True)

    def test_queries_do_not_grow_with_cases(self):
        service = MonthlyCrimeComparativeService(station_name='QC Station')
        self._add_cases(2)
        service.get_comparative_statement(year=2026, month=10)  # warm caches
        few, _ = _queries(lambda: service.get_comparative_statement(year=2026, month=10))
        self._add_cases(20)
        many, _ = _queries(lambda: service.get_comparative_statement(year=2026, month=10))
        self.assertEqual(many, few)


class CategoryTreeTests(TestCase):
    def setUp(self):
        self.accident = CaseCategory.objects.create(category_name='QC Accident', category_code='QC_ACC')
        self.twin = CaseCategory.objects.create(category_name='qc accident ', category_code='QC_ACC_STAND')
        self.road = CaseCategory.objects.create(category_name='QC Road', category_code='QC_ROAD',
                                                parent_category=self.accident)
        self.rash = CaseCategory.objects.create(category_name='QC Rash', category_code='QC_RASH',
                                                parent_category=self.road)
        self.twin_child = CaseCategory.objects.create(category_name='QC Normal', category_code='QC_NORMAL',
                                                      parent_category=self.twin)
        self.inactive = CaseCategory.objects.create(category_name='QC Old', category_code='QC_OLD',
                                                    parent_category=self.accident, is_active=False)

    def test_twins_and_descendants(self):
        self.assertEqual(set(get_twin_category_ids(self.accident.pk)), {self.accident.pk, self.twin.pk})
        self.assertEqual(
            set(get_descendant_category_ids(self.accident.pk)),
            {self.accident.pk, self.twin.pk, self.road.pk, self.rash.pk, self.twin_child.pk})
        # One index answers repeated questions without new queries
        index = CategoryIndex()
        n, _ = _queries(lambda: [get_descendant_category_ids(c, index)
                                 for c in (self.accident.pk, self.road.pk, self.rash.pk)])
        self.assertEqual(n, 0)

    def test_children_endpoint_queries_do_not_grow_with_sub_categories(self):
        client = APIClient()
        url = f'/api/categories/{self.accident.pk}/children/'
        client.get(url)  # warm caches
        few, resp = _queries(lambda: client.get(url))
        self.assertEqual(resp.status_code, 200)
        for i in range(10):
            CaseCategory.objects.create(category_name=f'QC Extra {i}', category_code=f'QC_X{i}',
                                        parent_category=self.accident)
        many, resp = _queries(lambda: client.get(url))
        names = {c['category_name'] for c in resp.json()}
        self.assertIn('QC Extra 9', names)
        self.assertIn('QC Normal', names)  # a twin's child is listed too
        road = next(c for c in resp.json() if c['category_name'] == 'QC Road')
        self.assertTrue(road['has_children'])
        # One counter query per sub-tab is left; the tree walk itself adds none.
        self.assertLessEqual(many - few, 10)
