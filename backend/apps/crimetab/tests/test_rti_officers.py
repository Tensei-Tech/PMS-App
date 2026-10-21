import json
import jwt
from django.conf import settings
from django.core.cache import cache
from django.db import connection
from rest_framework.test import APITestCase
from rest_framework import status

from apps.core.tenancy import TenantContext
from apps.public_master.models import StateRegistry
from apps.users.models import OfficerProfile
from apps.crimetab.models import OptionValue, ModuleSetting


class RTIOfficersEndpointTestCase(APITestCase):
    """
    Test suite for GET /api/rti/officers/ and RTI Assigned Officer assignment.
    Verifies:
    1. Station roles (officer, station_admin, station_head) see only their station officers.
    2. Division roles (division_admin, supervisor) see only their division officers.
    3. District roles (district_admin) see only their district officers.
    4. State admin (state_super_admin) sees all active officers in the state schema.
    5. A user lacking the unit ID for their role gets an empty list and dynamic module_setting message.
    6. master_admin and unconfigured roles get empty list and no_scope_message.
    7. Inactive officers never appear.
    8. A blank station_id never matches when user has station_id.
    9. Saving application with officer outside user's unit scope returns 400.
    10. Dynamic module_settings changes adjust scopes with no code changes.
    """

    def setUp(self):
        cache.clear()
        from django.db import connection
        if connection.connection and hasattr(connection.connection, 'closed') and connection.connection.closed:
            connection.connect()

        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )

        self.tenant_mh = TenantContext('maharashtra')
        self.tenant_mh.__enter__()

        # Seed ModuleSettings
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='enforce_permissions',
            defaults={'setting_value': 'false'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='scope_station_roles',
            defaults={'setting_value': 'officer,station_admin,station_head'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='scope_division_roles',
            defaults={'setting_value': 'division_admin,supervisor'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='scope_district_roles',
            defaults={'setting_value': 'district_admin'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='scope_state_roles',
            defaults={'setting_value': 'state_super_admin'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='no_station_message',
            defaults={'setting_value': 'No police station assigned to the logged-in user.'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='no_division_message',
            defaults={'setting_value': 'No division assigned to the logged-in user.'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='no_district_message',
            defaults={'setting_value': 'No district assigned to the logged-in user.'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='no_scope_message',
            defaults={'setting_value': 'User role does not have an officer assignment scope configured.'}
        )
        ModuleSetting.objects.update_or_create(
            module_key='rti',
            setting_key='officer_out_of_scope_message',
            defaults={'setting_value': 'Assigned officer does not belong to your unit scope.'}
        )

        # 1. Station A: Chhatrapati Police Station (Division: DIV_PUNE, District: DIST_PUNE)
        self.officer_a1 = OfficerProfile.objects.create(
            uid='sa_mh_chhatrapati_1',
            email='ramesh@mh.gov.in',
            name='Ramesh Kulkarni',
            designation='PI',
            station_name='Chhatrapati Police Station',
            station_id='ST_CHH_101',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='active',
            role_id='officer'
        )
        self.officer_a2 = OfficerProfile.objects.create(
            uid='sa_mh_chhatrapati_2',
            email='ganesh@mh.gov.in',
            name='Ganesh Shinde',
            designation='',  # Empty designation
            station_name='Chhatrapati Police Station',
            station_id='ST_CHH_101',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='active',
            role_id='station_admin'
        )
        self.officer_a3_no_id = OfficerProfile.objects.create(
            uid='sa_mh_chhatrapati_3',
            email='anand@mh.gov.in',
            name='Anand Rao',
            designation='PSI',
            station_name='Chhatrapati Police Station',
            station_id=None,  # Fallback to station_name
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='active',
            role_id='station_head'
        )
        self.officer_a_inactive1 = OfficerProfile.objects.create(
            uid='sa_mh_chhatrapati_archived',
            email='archived@mh.gov.in',
            name='Archived Officer',
            designation='PSI',
            station_name='Chhatrapati Police Station',
            station_id='ST_CHH_101',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='archived',
            role_id='officer'
        )
        self.officer_a_inactive2 = OfficerProfile.objects.create(
            uid='sa_mh_chhatrapati_pending',
            email='pending@mh.gov.in',
            name='Pending Officer',
            designation='Constable',
            station_name='Chhatrapati Police Station',
            station_id='ST_CHH_101',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='pending_approval',
            role_id='officer'
        )

        # 2. Station B: Sadar Police Station (Division: DIV_PUNE, District: DIST_PUNE)
        self.officer_b1 = OfficerProfile.objects.create(
            uid='sa_mh_sadar_1',
            email='suresh@mh.gov.in',
            name='Suresh Deshmukh',
            designation='API',
            station_name='Sadar Police Station',
            station_id='ST_SAD_202',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='active',
            role_id='officer'
        )

        # 3. Station C: Thane Central Police Station (Division: DIV_THANE, District: DIST_THANE)
        self.officer_c1 = OfficerProfile.objects.create(
            uid='sa_mh_thane_1',
            email='thane_pi@mh.gov.in',
            name='Vikas Patil',
            designation='PI',
            station_name='Thane Central Police Station',
            station_id='ST_THANE_303',
            division_id='DIV_THANE',
            district_id='DIST_THANE',
            account_status='active',
            role_id='officer'
        )

        # 4. Division Admin (Division: DIV_PUNE)
        self.division_admin = OfficerProfile.objects.create(
            uid='sa_mh_div_admin',
            email='div_admin@mh.gov.in',
            name='ACP Pune Division',
            designation='ACP',
            station_name='',
            station_id='',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='active',
            role_id='division_admin'
        )

        # 5. District Admin (District: DIST_PUNE)
        self.district_admin = OfficerProfile.objects.create(
            uid='sa_mh_dist_admin',
            email='dist_admin@mh.gov.in',
            name='DCP Pune District',
            designation='DCP',
            station_name='',
            station_id='',
            division_id='',
            district_id='DIST_PUNE',
            account_status='active',
            role_id='district_admin'
        )

        # 6. State Super Admin with station on profile (HQ)
        self.state_admin_with_station = OfficerProfile.objects.create(
            uid='sa_mh_state_admin_hq',
            email='dgp@mh.gov.in',
            name='DGP Maharashtra',
            designation='DGP',
            station_name='State HQ Police Station',
            station_id='ST_STATE_HQ',
            division_id='',
            district_id='',
            account_status='active',
            role_id='state_super_admin'
        )

        # 7. State Super Admin without station
        self.state_admin_no_station = OfficerProfile.objects.create(
            uid='sa_mh_state_admin_no_st',
            email='adgp@mh.gov.in',
            name='ADGP Crime',
            designation='ADGP',
            station_name='',
            station_id='',
            division_id='',
            district_id='',
            account_status='active',
            role_id='state_super_admin'
        )

        # 8. User with No Station (Officer role)
        self.user_no_station = OfficerProfile.objects.create(
            uid='sa_mh_hq_no_station',
            email='officer_no_st@mh.gov.in',
            name='Unassigned Officer',
            designation='Inspector',
            station_name='',
            station_id='',
            account_status='active',
            role_id='officer'
        )

        # 9. Division Admin missing division_id
        self.div_admin_no_div = OfficerProfile.objects.create(
            uid='sa_mh_div_admin_no_id',
            email='div_missing@mh.gov.in',
            name='Unassigned Div Admin',
            designation='ACP',
            station_name='',
            station_id='',
            division_id='',
            district_id='',
            account_status='active',
            role_id='division_admin'
        )

        # 10. District Admin missing district_id
        self.dist_admin_no_dist = OfficerProfile.objects.create(
            uid='sa_mh_dist_admin_no_id',
            email='dist_missing@mh.gov.in',
            name='Unassigned Dist Admin',
            designation='DCP',
            station_name='',
            station_id='',
            division_id='',
            district_id='',
            account_status='active',
            role_id='district_admin'
        )

        # 11. Unconfigured role / Master Admin
        self.master_user = OfficerProfile.objects.create(
            uid='sa_mh_master_admin',
            email='master@mh.gov.in',
            name='Master Admin User',
            designation='Admin',
            station_name='',
            station_id='',
            division_id='',
            district_id='',
            account_status='active',
            role_id='master_admin'
        )

        # Seed required options for form submission test
        OptionValue.objects.get_or_create(option_group='rti_mode_of_receipt', option_value='Online')
        OptionValue.objects.get_or_create(option_group='rti_info_type', option_value='Crime record')

    def tearDown(self):
        cache.clear()
        self.tenant_mh.__exit__(None, None, None)

    def _auth_headers(self, officer, state_code='MH'):
        payload = {'uid': officer.uid, 'state_code': state_code, 'user_type': 'officer'}
        token = jwt.encode(payload, settings.SECRET_KEY, algorithm='HS256')
        return {'HTTP_AUTHORIZATION': f'Bearer {token}', 'HTTP_X_STATE_CODE': state_code}

    def test_station_roles_see_only_active_officers_of_their_station(self):
        """
        Station roles (officer, station_admin, station_head) see only active officers of their own station.
        """
        # 1. Logged in as officer (ST_CHH_101)
        headers = self._auth_headers(self.officer_a1)
        resp = self.client.get('/api/rti/officers/', **headers)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        officers = resp.json()
        uids = [o['uid'] for o in officers]

        self.assertIn('sa_mh_chhatrapati_1', uids)
        self.assertIn('sa_mh_chhatrapati_2', uids)
        # Blank station_id officer must NOT appear when user has station_id
        self.assertNotIn('sa_mh_chhatrapati_3', uids)
        # Inactive officers must NOT appear
        self.assertNotIn('sa_mh_chhatrapati_archived', uids)
        self.assertNotIn('sa_mh_chhatrapati_pending', uids)
        # Other station officers must NOT appear
        self.assertNotIn('sa_mh_sadar_1', uids)
        self.assertNotIn('sa_mh_thane_1', uids)
        self.assertEqual(len(officers), 2)

        # Verify backend formatted label: "Name, Designation"
        o1 = next(o for o in officers if o['uid'] == 'sa_mh_chhatrapati_1')
        self.assertEqual(o1['label'], 'Ramesh Kulkarni, PI')
        o2 = next(o for o in officers if o['uid'] == 'sa_mh_chhatrapati_2')
        self.assertEqual(o2['label'], 'Ganesh Shinde')

    def test_blank_station_id_exclusion_when_user_has_station_id(self):
        """
        When user has a station_id, match officers by station_id ONLY.
        An officer with blank/None station_id and same station_name must NOT appear.
        """
        headers = self._auth_headers(self.officer_a1)
        resp = self.client.get('/api/rti/officers/', **headers)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        uids = [o['uid'] for o in resp.json()]
        self.assertNotIn('sa_mh_chhatrapati_3', uids)

    def test_station_roles_fallback_to_trimmed_name_only_when_user_lacks_station_id(self):
        """
        When user has no station_id, fallback to trimmed, case-folded station_name.
        """
        self.officer_a1.station_id = None
        self.officer_a1.station_name = '  chhatrapati police station  '
        self.officer_a1.save()

        headers = self._auth_headers(self.officer_a1)
        resp = self.client.get('/api/rti/officers/', **headers)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        uids = [o['uid'] for o in resp.json()]
        self.assertIn('sa_mh_chhatrapati_1', uids)
        self.assertIn('sa_mh_chhatrapati_2', uids)
        self.assertIn('sa_mh_chhatrapati_3', uids)

    def test_division_roles_see_only_officers_of_their_division(self):
        """
        Division roles (division_admin, supervisor) see all active officers across stations in their division.
        """
        headers = self._auth_headers(self.division_admin)
        resp = self.client.get('/api/rti/officers/', **headers)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        uids = [o['uid'] for o in resp.json()]

        # Pune division contains Chhatrapati and Sadar stations + Div Admin
        self.assertIn('sa_mh_chhatrapati_1', uids)
        self.assertIn('sa_mh_chhatrapati_2', uids)
        self.assertIn('sa_mh_chhatrapati_3', uids)
        self.assertIn('sa_mh_sadar_1', uids)
        self.assertIn('sa_mh_div_admin', uids)

        # Thane station is in DIV_THANE -> MUST NOT appear
        self.assertNotIn('sa_mh_thane_1', uids)
        # Inactive officers must NOT appear
        self.assertNotIn('sa_mh_chhatrapati_archived', uids)

    def test_district_roles_see_only_officers_of_their_district(self):
        """
        District roles (district_admin) see all active officers across their district.
        """
        headers = self._auth_headers(self.district_admin)
        resp = self.client.get('/api/rti/officers/', **headers)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        uids = [o['uid'] for o in resp.json()]

        # Pune district contains Chhatrapati and Sadar stations + Dist Admin
        self.assertIn('sa_mh_chhatrapati_1', uids)
        self.assertIn('sa_mh_chhatrapati_2', uids)
        self.assertIn('sa_mh_chhatrapati_3', uids)
        self.assertIn('sa_mh_sadar_1', uids)
        self.assertIn('sa_mh_dist_admin', uids)

        # Thane station is in DIST_THANE -> MUST NOT appear
        self.assertNotIn('sa_mh_thane_1', uids)

    def test_state_admin_sees_all_active_officers_in_state_schema(self):
        """
        STATE ADMIN (state_super_admin): sees every active officer in the state schema.
        Ignores station on profile (e.g. State HQ) or absence of station.
        """
        # 1. State admin with station on profile (HQ)
        headers_hq = self._auth_headers(self.state_admin_with_station)
        resp_hq = self.client.get('/api/rti/officers/', **headers_hq)
        self.assertEqual(resp_hq.status_code, status.HTTP_200_OK)
        uids_hq = [o['uid'] for o in resp_hq.json()]

        self.assertIn('sa_mh_chhatrapati_1', uids_hq)
        self.assertIn('sa_mh_sadar_1', uids_hq)
        self.assertIn('sa_mh_thane_1', uids_hq)
        self.assertIn('sa_mh_state_admin_hq', uids_hq)
        self.assertIn('sa_mh_state_admin_no_st', uids_hq)
        # Inactive officers never appear
        self.assertNotIn('sa_mh_chhatrapati_archived', uids_hq)

        # 2. State admin without station on profile
        headers_no_st = self._auth_headers(self.state_admin_no_station)
        resp_no_st = self.client.get('/api/rti/officers/', **headers_no_st)
        self.assertEqual(resp_no_st.status_code, status.HTTP_200_OK)
        uids_no_st = [o['uid'] for o in resp_no_st.json()]
        self.assertEqual(set(uids_hq), set(uids_no_st))

    def test_user_lacking_id_for_their_role_returns_empty_list_and_message(self):
        """
        If user profile lacks the unit ID required by its role, return empty list and module_settings message.
        """
        # 1. Officer with no station
        resp1 = self.client.get('/api/rti/officers/', **self._auth_headers(self.user_no_station))
        self.assertEqual(resp1.status_code, status.HTTP_200_OK)
        self.assertEqual(resp1.json().get('results'), [])
        self.assertEqual(resp1.json().get('message'), 'No police station assigned to the logged-in user.')

        # 2. Division admin with no division_id
        resp2 = self.client.get('/api/rti/officers/', **self._auth_headers(self.div_admin_no_div))
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        self.assertEqual(resp2.json().get('results'), [])
        self.assertEqual(resp2.json().get('message'), 'No division assigned to the logged-in user.')

        # 3. District admin with no district_id
        resp3 = self.client.get('/api/rti/officers/', **self._auth_headers(self.dist_admin_no_dist))
        self.assertEqual(resp3.status_code, status.HTTP_200_OK)
        self.assertEqual(resp3.json().get('results'), [])
        self.assertEqual(resp3.json().get('message'), 'No district assigned to the logged-in user.')

    def test_master_admin_and_unconfigured_roles_return_empty_list_and_message(self):
        """
        master_admin or any unconfigured role gets empty list and no_scope_message.
        """
        resp = self.client.get('/api/rti/officers/', **self._auth_headers(self.master_user))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.json().get('results'), [])
        self.assertEqual(resp.json().get('message'), 'User role does not have an officer assignment scope configured.')

    def test_saving_application_with_officer_outside_scope_returns_400(self):
        """
        Saving (POST or PATCH) an application with an officer outside user's role scope returns 400.
        """
        headers_station = self._auth_headers(self.officer_a1)

        # 1. Station user attempts to assign officer from Station B (Sadar)
        payload_post = {
            'received_date': '2026-10-01',
            'mode_of_receipt': 'Online',
            'applicant_name': 'Out of Scope Test',
            'address': 'Pune',
            'info_type': 'Crime record',
            'assigned_officer_uid': self.officer_b1.uid,
        }
        res_post = self.client.post('/api/rti/', data=json.dumps(payload_post), content_type='application/json', **headers_station)
        self.assertEqual(res_post.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Assigned officer does not belong to your unit scope.', res_post.json().get('error', ''))

        # Create valid application in Station A
        payload_valid = {
            'received_date': '2026-10-01',
            'mode_of_receipt': 'Online',
            'applicant_name': 'Valid Citizen',
            'address': 'Pune',
            'info_type': 'Crime record',
            'assigned_officer_uid': self.officer_a1.uid,
        }
        valid_post = self.client.post('/api/rti/', data=json.dumps(payload_valid), content_type='application/json', **headers_station)
        self.assertEqual(valid_post.status_code, status.HTTP_201_CREATED)
        rti_id = valid_post.json()['rti_id']

        # 2. Station user attempts to PATCH with officer from Thane (Station C)
        patch_payload = {'assigned_officer_uid': self.officer_c1.uid}
        res_patch = self.client.patch(f'/api/rti/{rti_id}/', data=json.dumps(patch_payload), content_type='application/json', **headers_station)
        self.assertEqual(res_patch.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Assigned officer does not belong to your unit scope.', res_patch.json().get('error', ''))

    def test_dynamic_module_settings_scope_reconfiguration(self):
        """
        Modifying scope_* in module_settings dynamically alters role scope without code change.
        """
        # Reconfigure 'supervisor' to be station scope instead of division scope
        ModuleSetting.objects.filter(module_key='rti', setting_key='scope_division_roles').update(setting_value='division_admin')
        ModuleSetting.objects.filter(module_key='rti', setting_key='scope_station_roles').update(setting_value='officer,station_admin,station_head,supervisor')

        supervisor = OfficerProfile.objects.create(
            uid='sa_mh_supervisor_1',
            email='sup@mh.gov.in',
            name='Station Supervisor',
            designation='Inspector',
            station_name='Chhatrapati Police Station',
            station_id='ST_CHH_101',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='active',
            role_id='supervisor'
        )

        headers = self._auth_headers(supervisor)
        resp = self.client.get('/api/rti/officers/', **headers)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        uids = [o['uid'] for o in resp.json()]

        # Because supervisor is now configured as a station role, it sees ONLY ST_CHH_101 officers
        self.assertIn('sa_mh_chhatrapati_1', uids)
        self.assertNotIn('sa_mh_sadar_1', uids)  # Sadar was visible under division scope, but now excluded!

    def test_two_stations_with_same_name_but_different_station_id_never_mix(self):
        """
        Two stations with the same name (e.g. 'City Police Station') but different station_id never mix.
        """
        st1_officer = OfficerProfile.objects.create(
            uid='sa_city_north_1',
            email='north@city.gov.in',
            name='North Officer',
            designation='PI',
            station_name='City Police Station',
            station_id='ST_CITY_NORTH',
            account_status='active',
            role_id='officer'
        )
        st2_officer = OfficerProfile.objects.create(
            uid='sa_city_south_1',
            email='south@city.gov.in',
            name='South Officer',
            designation='PI',
            station_name='City Police Station',
            station_id='ST_CITY_SOUTH',
            account_status='active',
            role_id='officer'
        )

        headers_north = self._auth_headers(st1_officer)
        resp_north = self.client.get('/api/rti/officers/', **headers_north)
        self.assertEqual(resp_north.status_code, status.HTTP_200_OK)
        uids_north = [o['uid'] for o in resp_north.json()]

        self.assertIn('sa_city_north_1', uids_north)
        self.assertNotIn('sa_city_south_1', uids_north)

        headers_south = self._auth_headers(st2_officer)
        resp_south = self.client.get('/api/rti/officers/', **headers_south)
        self.assertEqual(resp_south.status_code, status.HTTP_200_OK)
        uids_south = [o['uid'] for o in resp_south.json()]

        self.assertIn('sa_city_south_1', uids_south)
        self.assertNotIn('sa_city_north_1', uids_south)

    def test_deactivated_officers_of_other_states_never_appear(self):
        """
        Officers with account_status='deactivated' (e.g., switched-off officers from Gujarat or Goa)
        must NEVER appear in any scope, including state admin.
        """
        OfficerProfile.objects.create(
            uid='sa_gujarat_1',
            email='gujarat_1@police.gov.in',
            name='Gujarat Deactivated Officer',
            designation='PI',
            station_name='Chhatrapati Police Station',
            station_id='ST_CHH_101',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='deactivated',
            role_id='officer'
        )
        OfficerProfile.objects.create(
            uid='sa_goa_1',
            email='goa_1@police.gov.in',
            name='Goa Deactivated Officer',
            designation='PSI',
            station_name='Chhatrapati Police Station',
            station_id='ST_CHH_101',
            division_id='DIV_PUNE',
            district_id='DIST_PUNE',
            account_status='deactivated',
            role_id='officer'
        )

        # 1. Check from station role
        resp_st = self.client.get('/api/rti/officers/', **self._auth_headers(self.officer_a1))
        self.assertEqual(resp_st.status_code, status.HTTP_200_OK)
        uids_st = [o['uid'] for o in resp_st.json()]
        self.assertNotIn('sa_gujarat_1', uids_st)
        self.assertNotIn('sa_goa_1', uids_st)

        # 2. Check from state admin role
        resp_state = self.client.get('/api/rti/officers/', **self._auth_headers(self.state_admin_no_station))
        self.assertEqual(resp_state.status_code, status.HTTP_200_OK)
        uids_state = [o['uid'] for o in resp_state.json()]
        self.assertNotIn('sa_gujarat_1', uids_state)
        self.assertNotIn('sa_goa_1', uids_state)

    def test_unit_matching_by_text_columns_when_ids_are_blank(self):
        """
        When division_id, district_id, station_id are blank on officers and users,
        matching operates cleanly on trimmed, case-folded text columns (division_name, district, station_name).
        """
        # Active officer with blank IDs but valid text units
        officer_text = OfficerProfile.objects.create(
            uid='sa_mh_text_unit_1',
            email='text_unit@mh.gov.in',
            name='Text Unit Officer',
            designation='PI',
            station_name='Kothrud Police Station',
            station_id=None,
            division_name='Western Division',
            division_id=None,
            district='Pune City',
            district_id=None,
            account_status='active',
            role_id='officer'
        )

        # 1. Division Admin with blank division_id and matching division_name
        div_user = OfficerProfile.objects.create(
            uid='sa_mh_div_text_admin',
            email='div_text@mh.gov.in',
            name='Western Division Admin',
            designation='ACP',
            station_name='',
            station_id='',
            division_name='  western division  ',
            division_id=None,
            account_status='active',
            role_id='division_admin'
        )
        resp_div = self.client.get('/api/rti/officers/', **self._auth_headers(div_user))
        self.assertEqual(resp_div.status_code, status.HTTP_200_OK)
        uids_div = [o['uid'] for o in resp_div.json()]
        self.assertIn('sa_mh_text_unit_1', uids_div)

        # 2. District Admin with blank district_id and matching district text
        dist_user = OfficerProfile.objects.create(
            uid='sa_mh_dist_text_admin',
            email='dist_text@mh.gov.in',
            name='Pune City District Admin',
            designation='DCP',
            station_name='',
            station_id='',
            division_name='',
            division_id=None,
            district='  pune city  ',
            district_id=None,
            account_status='active',
            role_id='district_admin'
        )
        resp_dist = self.client.get('/api/rti/officers/', **self._auth_headers(dist_user))
        self.assertEqual(resp_dist.status_code, status.HTTP_200_OK)
        uids_dist = [o['uid'] for o in resp_dist.json()]
        self.assertIn('sa_mh_text_unit_1', uids_dist)

    def test_never_matches_blank_unit_value(self):
        """
        An officer with blank text units (station_name='', division_name='', district='')
        is never returned by unit-scoped queries.
        """
        officer_blank = OfficerProfile.objects.create(
            uid='sa_mh_blank_unit_officer',
            email='blank_units@mh.gov.in',
            name='Blank Units Officer',
            designation='Constable',
            station_name='',
            station_id=None,
            division_name='',
            division_id=None,
            district='',
            district_id=None,
            account_status='active',
            role_id='officer'
        )

        # Division admin query must not match the blank division officer
        resp_div = self.client.get('/api/rti/officers/', **self._auth_headers(self.division_admin))
        self.assertEqual(resp_div.status_code, status.HTTP_200_OK)
        uids_div = [o['uid'] for o in resp_div.json()]
        self.assertNotIn('sa_mh_blank_unit_officer', uids_div)

        # District admin query must not match the blank district officer
        resp_dist = self.client.get('/api/rti/officers/', **self._auth_headers(self.district_admin))
        self.assertEqual(resp_dist.status_code, status.HTTP_200_OK)
        uids_dist = [o['uid'] for o in resp_dist.json()]
        self.assertNotIn('sa_mh_blank_unit_officer', uids_dist)
