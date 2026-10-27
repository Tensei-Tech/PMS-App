"""
Officers edit only their own cases (created by them, or assigned to them as IO)
and delete only cases they created. Station heads and above edit any case of
their stations but, like everyone, delete only their own.
"""
import jwt

from django.conf import settings
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from apps.cases.models import CaseRecord
from apps.crimetab.models.accident import RoadAccidentRecord
from apps.public_master.models import Role, StateRegistry
from apps.users.models import OfficerProfile


class OwnCaseEditDeleteTests(TestCase):
    def setUp(self):
        cache.clear()
        StateRegistry.objects.create(state_code='MH', state_name='Maharashtra', schema_name='maharashtra', is_active=True)
        for rid in ['officer', 'station_head']:
            Role.objects.get_or_create(id=rid, defaults={'name': rid, 'level': 'station'})

        self.owner = self._officer('owner', 'Station A')
        self.io = self._officer('io', 'Station A')
        self.colleague = self._officer('colleague', 'Station A')
        self.head = self._officer('head', 'Station A', role='station_head')
        self.outsider = self._officer('outsider', 'Station B')

        self.case = CaseRecord.objects.create(id='case-own', module_key='murder', title='OWNER CASE',
                                              case_number='CR/1', station_name='Station A',
                                              created_by='owner', assigned_officer_uid='io')
        RoadAccidentRecord.objects.create(case_id='case-own', station_name='Station A')

    def tearDown(self):
        cache.clear()

    def _officer(self, uid, station, role='officer'):
        return OfficerProfile.objects.create(uid=uid, email=f'{uid}@x.in', name=uid, station_name=station,
                                             role_id=role, account_status='active')

    def _client(self, officer):
        client = APIClient()
        token = jwt.encode({'uid': officer.uid, 'state_code': 'MH', 'user_type': 'officer'},
                           settings.SECRET_KEY, algorithm='HS256')
        client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}', HTTP_X_STATE_CODE='MH')
        return client

    def _edit(self, officer, title):
        return self._client(officer).put('/api/cases/case-own/', {'title': title}, format='json')

    def _title(self):
        return CaseRecord.objects.get(pk='case-own').title

    def test_creator_and_io_edit(self):
        self.assertEqual(self._edit(self.owner, 'BY OWNER').status_code, 200)
        self.assertEqual(self._edit(self.io, 'BY IO').status_code, 200)
        self.assertEqual(self._title(), 'BY IO')

    def test_colleague_cannot_edit(self):
        response = self._edit(self.colleague, 'BY COLLEAGUE')
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self._title(), 'OWNER CASE')

    def test_station_head_edits_any_station_case(self):
        self.assertEqual(self._edit(self.head, 'BY HEAD').status_code, 200)

    def test_other_station_sees_nothing(self):
        self.assertEqual(self._edit(self.outsider, 'X').status_code, 404)
        self.assertEqual(self._client(self.outsider).delete('/api/cases/case-own/').status_code, 404)

    def test_colleague_cannot_edit_accident_details(self):
        acc = RoadAccidentRecord.objects.get(case_id='case-own')
        response = self._client(self.colleague).patch(f'/api/road-accident/{acc.id}/', {'station_name': 'Station A'},
                                                      format='json')
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self._client(self.owner).patch(f'/api/road-accident/{acc.id}/', {'station_name': 'Station A'},
                                                        format='json').status_code, 200)

    def test_only_creator_deletes(self):
        for officer in (self.colleague, self.io, self.head):
            self.assertEqual(self._client(officer).delete('/api/cases/case-own/').status_code, 403, officer.uid)
        self.assertTrue(CaseRecord.objects.filter(pk='case-own').exists())

        self.assertEqual(self._client(self.owner).delete('/api/cases/case-own/').status_code, 204)
        self.assertFalse(CaseRecord.objects.filter(pk='case-own').exists())
        self.assertFalse(RoadAccidentRecord.objects.filter(case_id='case-own').exists())

    def test_creator_comes_from_login(self):
        response = self._client(self.colleague).post('/api/cases/', {
            'id': 'case-new', 'case_number': 'CR/2', 'title': 'NEW', 'station_name': 'Station A',
            'created_by': 'owner',
        }, format='json')
        self.assertEqual(response.status_code, 201, response.content)
        self.assertEqual(CaseRecord.objects.get(pk='case-new').created_by, 'colleague')
