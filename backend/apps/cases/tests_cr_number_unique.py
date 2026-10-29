"""
A CR number may be used only once per tab (sub-category) of a station;
another station or another tab may reuse it.
"""
import jwt

from django.conf import settings
from django.core.cache import cache
from django.test import SimpleTestCase, TestCase
from rest_framework.test import APIClient

from apps.cases.cr_numbers import case_tab, normalize_cr
from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.public_master.models import Role, StateRegistry
from apps.users.models import OfficerProfile


class NormalizeCrTests(SimpleTestCase):
    def test_spaces_case_and_cr_prefix_are_ignored(self):
        for value in ('12', ' 12 ', 'CR 12', 'cr/12', 'CR-12', 'Cr12'):
            self.assertEqual(normalize_cr(value), '12', value)
        self.assertEqual(normalize_cr('CR/A6799B'), 'A6799B')
        self.assertNotEqual(normalize_cr('12'), normalize_cr('121'))
        self.assertEqual(normalize_cr(''), '')

    def test_tab_is_sub_category_else_module(self):
        self.assertEqual(case_tab(' Murder ', 'form_1_5'), 'murder')
        self.assertEqual(case_tab('', 'passport'), 'passport')


class CrNumberUniquePerTabTests(TestCase):
    def setUp(self):
        cache.clear()
        StateRegistry.objects.create(state_code='MH', state_name='Maharashtra', schema_name='maharashtra', is_active=True)
        Role.objects.get_or_create(id='officer', defaults={'name': 'officer', 'level': 'station'})
        self.officer_a = self._officer('off-a', 'Station A')
        self.officer_b = self._officer('off-b', 'Station B')

    def tearDown(self):
        cache.clear()

    def _officer(self, uid, station):
        return OfficerProfile.objects.create(uid=uid, email=f'{uid}@x.in', name=uid, station_name=station,
                                             role_id='officer', account_status='active')

    def _client(self, officer):
        client = APIClient()
        token = jwt.encode({'uid': officer.uid, 'state_code': 'MH', 'user_type': 'officer'},
                           settings.SECRET_KEY, algorithm='HS256')
        client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}', HTTP_X_STATE_CODE='MH')
        return client

    def _create(self, officer, cid, cr, sub='Murder', station=None):
        return self._client(officer).post('/api/cases/', {
            'id': cid, 'case_number': cr, 'title': cid, 'module_key': 'form_1_5', 'sub_category': sub,
            'station_name': station or officer.station_name,
        }, format='json')

    def test_same_cr_in_same_tab_is_refused(self):
        self.assertEqual(self._create(self.officer_a, 'm1', '12').status_code, 201)
        response = self._create(self.officer_a, 'm2', 'CR 12')
        self.assertEqual(response.status_code, 400, response.content)
        self.assertIn('already used in Murder', str(response.json()['case_number']))
        with TenantContext('maharashtra'):
            self.assertFalse(CaseRecord.objects.filter(pk='m2').exists())

    def test_other_station_may_reuse_the_cr(self):
        self.assertEqual(self._create(self.officer_a, 'm1', '12').status_code, 201)
        self.assertEqual(self._create(self.officer_b, 'm2', '12').status_code, 201)

    def test_other_tab_may_reuse_the_cr(self):
        self.assertEqual(self._create(self.officer_a, 'm1', '12').status_code, 201)
        self.assertEqual(self._create(self.officer_a, 'a1', '12', sub='Attempt to Murder').status_code, 201)

    def test_edit_keeps_or_changes_cr(self):
        self.assertEqual(self._create(self.officer_a, 'm1', '12').status_code, 201)
        self.assertEqual(self._create(self.officer_a, 'm2', '13').status_code, 201)
        client = self._client(self.officer_a)
        # Keeping its own CR, or other fields, is fine
        self.assertEqual(client.put('/api/cases/m2/', {'title': 'EDITED'}, format='json').status_code, 200)
        self.assertEqual(client.put('/api/cases/m2/', {'case_number': '13'}, format='json').status_code, 200)
        # Changing it to a CR used by another case in the tab is refused
        response = client.put('/api/cases/m2/', {'case_number': '12'}, format='json')
        self.assertEqual(response.status_code, 400, response.content)
        with TenantContext('maharashtra'):
            self.assertEqual(CaseRecord.objects.get(pk='m2').case_number, '13')

    def test_older_duplicates_stay_editable(self):
        with TenantContext('maharashtra'):
            for cid in ('d1', 'd2'):
                CaseRecord.objects.create(id=cid, module_key='form_1_5', sub_category='Murder', title=cid,
                                          case_number='99', station_name='Station A', created_by='off-a')
        response = self._client(self.officer_a).put('/api/cases/d2/', {'title': 'STILL EDITABLE'}, format='json')
        self.assertEqual(response.status_code, 200, response.content)
