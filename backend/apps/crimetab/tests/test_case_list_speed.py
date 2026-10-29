"""
Case lists (Form I-V and every category tab) must not make one query per row,
must not send the rows twice, and must keep the road accident data merged in.
"""
import jwt

from django.conf import settings
from django.core.cache import cache
from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.accident import RoadAccidentRecord
from apps.public_master.models import Role, StateRegistry
from apps.users.models import OfficerProfile

STATION = 'Station A'


class CaseListSpeedTests(TestCase):
    def setUp(self):
        cache.clear()
        StateRegistry.objects.create(state_code='MH', state_name='Maharashtra', schema_name='maharashtra', is_active=True)
        Role.objects.get_or_create(id='officer', defaults={'name': 'Officer', 'level': 'station'})
        OfficerProfile.objects.create(uid='speed-1', email='speed@x.in', name='S', station_name=STATION,
                                      role_id='officer', account_status='active')
        token = jwt.encode({'uid': 'speed-1', 'state_code': 'MH', 'user_type': 'officer'},
                           settings.SECRET_KEY, algorithm='HS256')
        self.client = APIClient()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}', HTTP_X_STATE_CODE='MH')
        self.created = 0

    def tearDown(self):
        cache.clear()

    def _add_cases(self, n, with_accident=True):
        # Each request resets search_path to public afterwards, so tenant tables
        # (cases, road_accident_records) must be written inside the state schema
        # every time, not only at the start of the test (matters on PostgreSQL).
        with TenantContext('maharashtra'):
            for _ in range(n):
                self.created += 1
                case = CaseRecord.objects.create(id=f'speed-{self.created}', module_key='murder',
                                                 title=f'Case {self.created}', case_number=f'CR/{self.created}',
                                                 station_name=STATION, extra_fields={'k': 'v'})
                if with_accident:
                    RoadAccidentRecord.objects.create(case_id=case.id, station_name=STATION)

    def _data_queries(self, url):
        cache.clear()  # measure the database work, not the response cache
        with CaptureQueriesContext(connection) as ctx:
            response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        sql = [q['sql'] for q in ctx.captured_queries if not q['sql'].lstrip().upper().startswith('SET ')]
        return response, sql

    def test_query_count_does_not_grow_with_rows(self):
        self._add_cases(3)
        _, few = self._data_queries('/api/cases/')
        self._add_cases(9)
        response, many = self._data_queries('/api/cases/')
        self.assertEqual(len(response.json()['results']), 12)
        self.assertEqual(len(few), len(many), many)

    def test_rows_are_sent_once(self):
        self._add_cases(2)
        body = self.client.get('/api/cases/').json()
        self.assertEqual(set(body), {'count', 'results'})
        self.assertEqual(body['count'], 2)

    def test_accident_data_is_still_merged_into_rows(self):
        self._add_cases(1, with_accident=True)
        self._add_cases(1, with_accident=False)
        rows = {r['id']: r for r in self.client.get('/api/cases/').json()['results']}
        with_acc, without_acc = rows['speed-1'], rows['speed-2']
        self.assertIn('road_accident', with_acc)
        for key in ('acc_vehicles', 'vehicles', 'acc_injured', 'injured', 'acc_deceased', 'deceased'):
            self.assertIn(key, with_acc['extra_fields'])
        self.assertEqual(with_acc['extra_fields']['k'], 'v')
        self.assertNotIn('road_accident', without_acc)
        self.assertEqual(without_acc['extra_fields'], {'k': 'v'})

    def test_first_accident_record_wins_as_before(self):
        self._add_cases(1, with_accident=False)
        with TenantContext('maharashtra'):
            RoadAccidentRecord.objects.create(case_id='speed-1', station_name=STATION, accident_spot='FIRST')
            RoadAccidentRecord.objects.create(case_id='speed-1', station_name=STATION, accident_spot='SECOND')
        row = self.client.get('/api/cases/').json()['results'][0]
        self.assertEqual(row['road_accident']['accident_spot'], 'FIRST')
