"""
Security fixes: public sign-up, approvals jurisdiction, master tables
(states, roles, permissions, role-permissions, announcements) and the state logo.
"""
import uuid

import jwt
from django.conf import settings
from django.core.cache import cache
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from apps.public_master.models import AppAnnouncement, MasterUser, Permission, Role, RolePermission, StateRegistry
from apps.users.models import OfficerProfile


def _officer(role_id='officer', station='Shivajinagar Police Station', district='Pune',
             division='Pune Division', status_='active', uid=None):
    uid = uid or f'u-{uuid.uuid4().hex[:8]}'
    return OfficerProfile.objects.create(
        uid=uid, email=f'{uid}@mh.gov.in', name=uid, role_id=role_id,
        station_name=station, district=district, division_name=division,
        account_status=status_,
    )


def _officer_headers(officer, state_code='MH'):
    token = jwt.encode({'uid': officer.uid, 'state_code': state_code, 'user_type': 'officer'},
                       settings.SECRET_KEY, algorithm='HS256')
    return {'HTTP_AUTHORIZATION': f'Bearer {token}', 'HTTP_X_STATE_CODE': state_code}


def _master_headers():
    master = MasterUser(email=f'm-{uuid.uuid4().hex[:6]}@pms.gov.in', full_name='Master')
    master.set_password('MasterPass123!')
    master.save()
    token = jwt.encode({'uid': str(master.id), 'state_code': 'GLOBAL', 'user_type': 'master'},
                       settings.SECRET_KEY, algorithm='HS256')
    return {'HTTP_AUTHORIZATION': f'Bearer {token}'}


class SecurityTestBase(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.state, _ = StateRegistry.objects.get_or_create(
            state_code='MH', defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True})
        for rid in ['officer', 'station_head', 'district_admin', 'state_admin', 'master_admin']:
            Role.objects.get_or_create(id=rid, defaults={'name': rid, 'level': 'station'})


class PublicRegistrationTests(SecurityTestBase):
    def _register(self, headers=None, **extra):
        body = {
            'email': f'r-{uuid.uuid4().hex[:6]}@mh.gov.in', 'password': 'Password123!',
            'full_name': 'New Officer', 'role_id': 'officer', 'state_code': 'MH',
            'station_name': 'Shivajinagar Police Station', 'district': 'Pune', 'designation': 'PI',
        }
        body.update(extra)
        return body['email'], self.client.post('/api/auth/register/', body, format='json', **(headers or {}))

    def test_anonymous_cannot_register_master_admin(self):
        email, res = self._register(role_id='master_admin')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertNotIn('tokens', res.data)
        self.assertFalse(MasterUser.objects.filter(email=email).exists())

    def test_client_account_status_is_ignored(self):
        email, res = self._register(account_status='active')
        self.assertEqual(res.status_code, status.HTTP_202_ACCEPTED)
        self.assertEqual(OfficerProfile.objects.get(email=email).account_status, 'pending_approval')

    def test_anonymous_cannot_register_state_admin(self):
        _, res = self._register(role_id='state_admin')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_master_admin_onboards_state_admin_active(self):
        email, res = self._register(headers=_master_headers(), role_id='state_admin')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)
        self.assertEqual(OfficerProfile.objects.get(email=email).account_status, 'active')

    def test_admin_created_accounts_wait_for_approval(self):
        # Only a Master Admin's accounts start active; everyone else's wait in
        # Pending Approvals for an admin above them in that area.
        admin = _officer('district_admin', station='', district='Pune')
        for district in ('Pune', 'Nagpur'):
            email, res = self._register(headers=_officer_headers(admin), district=district)
            self.assertEqual(res.status_code, status.HTTP_202_ACCEPTED, res.data)
            self.assertEqual(OfficerProfile.objects.get(email=email).account_status, 'pending_approval')


class ApprovalJurisdictionTests(SecurityTestBase):
    def _approve(self, caller, target):
        return self.client.post(f'/api/auth/users/{target.uid}/approve-registration/',
                                {'action': 'approve'}, format='json', **_officer_headers(caller))

    def _status(self, target):
        return OfficerProfile.objects.get(uid=target.uid).account_status

    def test_officer_cannot_approve_colleague(self):
        caller, target = _officer(), _officer(status_='pending_approval')
        self.assertEqual(self._approve(caller, target).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self._status(target), 'pending_approval')

    def test_station_head_approves_own_station_only(self):
        head = _officer('station_head')
        same = _officer(status_='pending_approval')
        other = _officer(station='Kothrud Police Station', status_='pending_approval')
        other_district = _officer(district='Satara', status_='pending_approval')
        self.assertEqual(self._approve(head, same).status_code, status.HTTP_200_OK)
        self.assertEqual(self._status(same), 'active')
        self.assertEqual(self._approve(head, other).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self._approve(head, other_district).status_code, status.HTTP_403_FORBIDDEN)

    def test_station_head_cannot_approve_higher_role(self):
        head = _officer('station_head')
        target = _officer('district_admin', status_='pending_approval')
        self.assertEqual(self._approve(head, target).status_code, status.HTTP_403_FORBIDDEN)

    def test_designation_text_grants_nothing(self):
        caller = _officer()
        caller.designation = 'DGP'
        caller.save()
        target = _officer(district='Nagpur', status_='pending_approval')
        self.assertEqual(self._approve(caller, target).status_code, status.HTTP_403_FORBIDDEN)

    def test_district_admin_approves_own_district_only(self):
        admin = _officer('district_admin', station='')
        inside = _officer(station='Kothrud Police Station', status_='pending_approval')
        outside = _officer(district='Nagpur', status_='pending_approval')
        self.assertEqual(self._approve(admin, inside).status_code, status.HTTP_200_OK)
        self.assertEqual(self._approve(admin, outside).status_code, status.HTTP_403_FORBIDDEN)

    def test_pending_list_is_scoped(self):
        _officer(status_='pending_approval', uid='p-same')
        _officer(station='Kothrud Police Station', status_='pending_approval', uid='p-other')
        officer, head = _officer(), _officer('station_head')

        res = self.client.get('/api/auth/notifications/pending-approvals/', **_officer_headers(officer))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(self._uids(res), set())

        res = self.client.get('/api/auth/notifications/pending-approvals/', **_officer_headers(head))
        self.assertEqual(self._uids(res), {'p-same'})

    @staticmethod
    def _uids(res):
        items = res.data if isinstance(res.data, list) else res.data.get('results', res.data.get('data', []))
        return {i['registration_uid'] for i in items}


class MasterTablesTests(SecurityTestBase):
    def setUp(self):
        super().setUp()
        self.officer = _officer()
        self.state_admin = _officer('state_admin', station='', district='')
        Permission.objects.get_or_create(id='state:view_all', defaults={'module': 'state'})

    def test_officer_cannot_grant_own_role_permissions(self):
        res = self.client.post('/api/master/role-permissions/',
                               {'role': 'officer', 'permission': 'state:view_all', 'is_granted': True},
                               format='json', **_officer_headers(self.officer))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertFalse(RolePermission.objects.filter(role_id='officer', permission_id='state:view_all').exists())

    def test_master_can_grant_role_permissions(self):
        res = self.client.post('/api/master/role-permissions/',
                               {'role': 'officer', 'permission': 'state:view_all', 'is_granted': True},
                               format='json', **_master_headers())
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)

    def test_officer_reads_but_cannot_write_roles_and_permissions(self):
        headers = _officer_headers(self.officer)
        self.assertEqual(self.client.get('/api/master/roles/', **headers).status_code, status.HTTP_200_OK)
        self.assertEqual(self.client.post('/api/master/roles/', {'id': 'boss', 'name': 'Boss', 'level': 'global'},
                                          format='json', **headers).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.post('/api/master/permissions/', {'id': 'x:y', 'module': 'x'},
                                          format='json', **headers).status_code, status.HTTP_403_FORBIDDEN)

    def test_officer_cannot_edit_state(self):
        res = self.client.patch('/api/master/states/MH/', {'state_name': 'HACKED'},
                                format='json', **_officer_headers(self.officer))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.state.refresh_from_db()
        self.assertEqual(self.state.state_name, 'Maharashtra')

    def test_state_admin_changes_only_own_logo(self):
        headers = _officer_headers(self.state_admin)
        res = self.client.patch('/api/master/states/MH/', {'department_logo_url': 'https://cdn.example/mh.png'},
                                format='json', **headers)
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        self.assertEqual(res.data['department_logo_url'], 'https://cdn.example/mh.png')

        res = self.client.patch('/api/master/states/MH/', {'is_active': False}, format='json', **headers)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_officer_cannot_create_or_delete_state(self):
        headers = _officer_headers(self.officer)
        res = self.client.post('/api/master/states/', {'state_code': 'XX', 'state_name': 'X', 'schema_name': 'xx'},
                               format='json', **headers)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.delete('/api/master/states/MH/', **headers).status_code, status.HTTP_403_FORBIDDEN)

    def test_master_edits_state(self):
        res = self.client.patch('/api/master/states/MH/', {'state_name': 'Maharashtra State'},
                                format='json', **_master_headers())
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)

    def test_announcements_writes_need_state_admin(self):
        body = {'title': 'Fake', 'description': 'Fake bulletin'}
        self.assertIn(self.client.post('/api/master/announcements/', body, format='json').status_code,
                      (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN))
        self.assertEqual(self.client.post('/api/master/announcements/', body, format='json',
                                          **_officer_headers(self.officer)).status_code, status.HTTP_403_FORBIDDEN)
        self.assertFalse(AppAnnouncement.objects.filter(title='Fake').exists())
        self.assertEqual(self.client.get('/api/master/announcements/').status_code, status.HTTP_200_OK)
        res = self.client.post('/api/master/announcements/', body, format='json', **_officer_headers(self.state_admin))
        self.assertNotIn(res.status_code, (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN))


class StateLogoTests(SecurityTestBase):
    def test_logo_in_states_api_and_login(self):
        self.state.department_logo_url = 'https://cdn.example/mh.png'
        self.state.save()

        res = self.client.get('/api/master/states/MH/')
        self.assertEqual(res.data['department_logo_url'], 'https://cdn.example/mh.png')

        officer = _officer()
        officer.set_password('Password123!')
        officer.save()
        res = self.client.post('/api/auth/login/', {'email': officer.email, 'password': 'Password123!',
                                                    'state_code': 'MH'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK, res.data)
        self.assertEqual(res.data['user']['department_logo_url'], 'https://cdn.example/mh.png')
