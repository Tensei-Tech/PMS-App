"""
Case and accident records are police data: never readable or writable without
login, and officers see only their own stations (district/state roles see all).
Reference data (states, options, UI config) stays public for the register screen.
"""
import jwt

from django.conf import settings
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from apps.cases.models import CaseRecord
from apps.crimetab.models.accident import RoadAccidentRecord
from apps.public_master.models import Permission, Role, RolePermission, StateRegistry
from apps.users.models import OfficerProfile


class CaseDataAccessTests(TestCase):
    def setUp(self):
        cache.clear()
        StateRegistry.objects.create(state_code='MH', state_name='Maharashtra', schema_name='maharashtra', is_active=True)
        Role.objects.get_or_create(id='officer', defaults={'name': 'Officer', 'level': 'station'})
        district_role, _ = Role.objects.get_or_create(id='district_admin', defaults={'name': 'District Admin', 'level': 'district'})
        perm, _ = Permission.objects.get_or_create(id='district:view_data', defaults={'module': 'district'})
        RolePermission.objects.get_or_create(role=district_role, permission=perm, defaults={'is_granted': True})

        self.officer_a = self._officer('off-a', 'Station A')
        self.officer_b = self._officer('off-b', 'Station B')
        self.district = self._officer('dist-1', 'District HQ', role='district_admin')

        self.case_a = CaseRecord.objects.create(id='case-a', module_key='murder', title='CASE OF A',
                                                case_number='CR/A', station_name='Station A')
        self.case_b = CaseRecord.objects.create(id='case-b', module_key='murder', title='CASE OF B',
                                                case_number='CR/B', station_name='Station B')
        self.acc_a = RoadAccidentRecord.objects.create(case_id='case-a', station_name='Station A')
        self.acc_b = RoadAccidentRecord.objects.create(case_id='case-b', station_name='Station B')

    def tearDown(self):
        cache.clear()

    def _officer(self, uid, station, role='officer'):
        return OfficerProfile.objects.create(uid=uid, email=f'{uid}@x.in', name=uid, station_name=station,
                                             role_id=role, account_status='active')

    def _client(self, officer=None):
        client = APIClient()
        headers = {'HTTP_X_STATE_CODE': 'MH'}
        if officer:
            token = jwt.encode({'uid': officer.uid, 'state_code': 'MH', 'user_type': 'officer'},
                               settings.SECRET_KEY, algorithm='HS256')
            headers['HTTP_AUTHORIZATION'] = f'Bearer {token}'
        client.credentials(**headers)
        return client

    # ── No login ─────────────────────────────────────────────────────────────
    def test_no_login_gets_nothing_even_with_state_header(self):
        anon = self._client()
        reads = [
            '/api/cases/', f'/api/cases/{self.case_a.id}/', f'/api/cases/{self.case_a.id}/pdf/',
            '/api/cases/counts/', '/api/categories/1/cases/', '/api/categories/1/counters/',
            '/api/groups/1/counters/', '/api/road-accident/', f'/api/road-accident/{self.acc_a.id}/',
        ]
        for url in reads:
            response = anon.get(url)
            self.assertEqual(response.status_code, 401, url)
            self.assertNotIn(b'CASE OF A', response.content, url)

    def test_no_login_cannot_write(self):
        anon = self._client()
        self.assertEqual(anon.post('/api/cases/', {'title': 'x', 'station_name': 'Station A'}, format='json').status_code, 401)
        self.assertEqual(anon.put(f'/api/cases/{self.case_a.id}/', {'title': 'hacked'}, format='json').status_code, 401)
        self.assertEqual(anon.post('/api/road-accident/', {'station_name': 'Station A'}, format='json').status_code, 401)
        self.assertEqual(anon.patch(f'/api/road-accident/{self.acc_a.id}/', {'station_name': 'X'}, format='json').status_code, 401)
        self.case_a.refresh_from_db()
        self.assertEqual(self.case_a.title, 'CASE OF A')

    # ── Station officer ──────────────────────────────────────────────────────
    def test_officer_lists_only_own_station(self):
        data = self._client(self.officer_a).get('/api/cases/').json()
        self.assertEqual([c['id'] for c in data['results']], ['case-a'])
        self.assertEqual(data['count'], 1)

    def test_officer_cannot_list_other_station_by_parameter(self):
        data = self._client(self.officer_a).get('/api/cases/', {'station_name': 'Station B'}).json()
        self.assertEqual(data['results'], [])

    def test_officer_cannot_open_print_or_edit_other_station_case(self):
        client = self._client(self.officer_a)
        self.assertEqual(client.get(f'/api/cases/{self.case_b.id}/').status_code, 404)
        self.assertEqual(client.get(f'/api/cases/{self.case_b.id}/pdf/').status_code, 404)
        self.assertEqual(client.put(f'/api/cases/{self.case_b.id}/', {'title': 'hacked'}, format='json').status_code, 404)
        self.case_b.refresh_from_db()
        self.assertEqual(self.case_b.title, 'CASE OF B')

    def test_officer_opens_own_case(self):
        client = self._client(self.officer_a)
        self.assertEqual(client.get(f'/api/cases/{self.case_a.id}/').status_code, 200)
        self.assertEqual(client.get(f'/api/cases/{self.case_a.id}/pdf/').status_code, 200)

    def test_additional_stations_are_visible(self):
        self.officer_a.additional_stations = ['Station B']
        self.officer_a.save()
        cache.clear()  # the auth layer caches the profile briefly
        ids = sorted(c['id'] for c in self._client(self.officer_a).get('/api/cases/').json()['results'])
        self.assertEqual(ids, ['case-a', 'case-b'])

    def test_officer_accident_records_are_station_scoped(self):
        client = self._client(self.officer_a)
        listed = client.get('/api/road-accident/').json()
        self.assertEqual({r['station_name'] for r in listed}, {'Station A'})
        self.assertEqual(client.get(f'/api/road-accident/{self.acc_b.id}/').status_code, 404)
        self.assertEqual(client.patch(f'/api/road-accident/{self.acc_b.id}/', {'station_name': 'Station A'},
                                      format='json').status_code, 404)

    # ── District role ────────────────────────────────────────────────────────
    def test_district_role_sees_every_station(self):
        client = self._client(self.district)
        ids = sorted(c['id'] for c in client.get('/api/cases/').json()['results'])
        self.assertEqual(ids, ['case-a', 'case-b'])
        self.assertEqual(client.get(f'/api/cases/{self.case_b.id}/').status_code, 200)
        self.assertEqual(client.get(f'/api/road-accident/{self.acc_b.id}/').status_code, 200)

    # ── Still public ─────────────────────────────────────────────────────────
    def test_reference_data_stays_public(self):
        anon = APIClient()
        for url in ('/api/master/states/', '/api/master/ui-config/', '/api/options/yes_no/', '/api/app-version/'):
            self.assertNotIn(anon.get(url).status_code, (401, 403), url)
