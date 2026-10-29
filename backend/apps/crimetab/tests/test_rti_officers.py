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

    def test_transfer_date_saved_with_transferred_and_cleared_on_other_outcome(self):
        """Transfer Date is optional, saved with outcome Transferred, cleared when outcome changes."""
        headers = self._auth_headers(self.officer_a1)
        payload = {
            'rti_received_date': '01/10/2026',
            'rti_applicant_name': 'Transfer Citizen',
            'rti_outcome': 'Transferred',
            'rti_transferred_to': 'District Office',
            'rti_transferred_date': '05/10/2026',
        }
        res = self.client.post('/api/rti/', data=json.dumps(payload), content_type='application/json', **headers)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.content)
        self.assertEqual(res.json()['transferred_date'], '2026-10-05')
        rti_id = res.json()['rti_id']

        # Optional: Transferred without a date still saves
        payload_no_date = dict(payload, rti_applicant_name='No Date Citizen')
        payload_no_date.pop('rti_transferred_date')
        res2 = self.client.post('/api/rti/', data=json.dumps(payload_no_date), content_type='application/json', **headers)
        self.assertEqual(res2.status_code, status.HTTP_201_CREATED, res2.content)
        self.assertIsNone(res2.json()['transferred_date'])

        # Invalid date is rejected
        bad = dict(payload, rti_transferred_date='not-a-date')
        res3 = self.client.post('/api/rti/', data=json.dumps(bad), content_type='application/json', **headers)
        self.assertEqual(res3.status_code, status.HTTP_400_BAD_REQUEST)

        # Switching to Replied clears both transfer fields
        patch = {'rti_outcome': 'Replied', 'rti_replied_date': '10/10/2026',
                 'rti_transferred_to': '', 'rti_transferred_date': '05/10/2026'}
        res4 = self.client.patch(f'/api/rti/{rti_id}/', data=json.dumps(patch), content_type='application/json', **headers)
        self.assertEqual(res4.status_code, status.HTTP_200_OK, res4.content)
        self.assertIsNone(res4.json()['transferred_date'])
        self.assertEqual(res4.json()['replied_date'], '2026-10-10')

    def test_chart_lists_all_station_applications_with_info_given(self):
        ModuleSetting.objects.update_or_create(module_key='rti', setting_key='chart_info_given_template',
                                               defaults={'setting_value': '{outcome}|({date})'})
        ModuleSetting.objects.update_or_create(module_key='rti', setting_key='chart_info_given_separator',
                                               defaults={'setting_value': ' '})
        ModuleSetting.objects.update_or_create(module_key='rti', setting_key='chart_person_template',
                                               defaults={'setting_value': '{name}|{age} Yrs|Mob: {mobile}|{address}'})
        ModuleSetting.objects.update_or_create(module_key='rti', setting_key='chart_person_separator',
                                               defaults={'setting_value': ', '})
        headers = self._auth_headers(self.officer_a1)

        def create(body):
            res = self.client.post('/api/rti/', data=json.dumps(body), content_type='application/json', **headers)
            self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.content)

        create({'rti_applicant_name': 'Chart Pending', 'rti_received_date': '01/10/2026',
                'rti_applicant_age': '40', 'rti_mobile_no': '9876543210', 'rti_address': 'Pune'})
        create({'rti_applicant_name': 'Chart Replied', 'rti_outcome': 'Replied', 'rti_replied_date': '05/10/2026'})
        create({'rti_applicant_name': 'Chart Transferred', 'rti_outcome': 'Transferred',
                'rti_transferred_to': 'District Office'})
        # Another station's application must not appear
        other = self._auth_headers(self.officer_b1)
        self.client.post('/api/rti/', data=json.dumps({'rti_applicant_name': 'Other Station'}),
                         content_type='application/json', **other)

        res = self.client.get('/api/rti/chart/', **headers)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.json()
        self.assertEqual(data['count'], 3)
        rows = data['results']
        self.assertEqual(set(rows[0].keys()) - {'rti_id'}, {
            'sr_no', 'person', 'received_date', 'due_date',
            'info_type', 'assigned_officer', 'info_given'})
        # Name, Age, Mobile No. and Address in one column
        self.assertEqual(rows[0]['person'], 'Chart Pending, 40 Yrs, Mob: 9876543210, Pune')
        first = rows[0]
        self.assertEqual(first['received_date'], '01/10/2026')
        self.assertEqual(first['due_date'], '31/10/2026')  # received + due_days (30)
        self.assertEqual(first['info_given'], '')
        self.assertEqual(rows[1]['info_given'], 'Replied (05/10/2026)')
        self.assertEqual(rows[2]['info_given'], 'Transferred')  # no date given: date part skipped

        # Search narrows the chart too
        res_q = self.client.get('/api/rti/chart/?q=Replied', **headers)
        self.assertEqual(res_q.json()['count'], 1)

    def test_reminder_schedule_rule(self):
        from apps.crimetab.views_rti import rti_reminder_kind
        import datetime as dt
        today = dt.date(2026, 10, 16)

        def kind(days_left):
            return rti_reminder_kind(today + dt.timedelta(days=days_left), today, 30, 25, 24)

        self.assertEqual(kind(31), None)      # too early
        self.assertEqual(kind(30), 'first')   # 1st reminder: 30 days before
        self.assertEqual(kind(29), None)
        self.assertEqual(kind(26), None)
        self.assertEqual(kind(25), 'second')  # 2nd reminder: 25 days before
        self.assertEqual(kind(24), 'daily')   # then every day
        self.assertEqual(kind(1), 'daily')
        self.assertEqual(kind(0), 'daily')    # due today
        self.assertEqual(kind(-3), 'daily')   # overdue and still pending
        self.assertIsNone(rti_reminder_kind(None, today, 30, 25, 24))

    def test_reminders_go_to_assigned_officer_and_manual_send(self):
        import datetime as dt
        for key, value in [('reminder_first_days_before', '30'), ('reminder_second_days_before', '25'),
                           ('reminder_daily_from_days_before', '24'),
                           ('reminder_title', 'RTI {sr_no} reply due'),
                           ('manual_reminder_title', 'RTI {sr_no} reminder from {sender}'),
                           ('manual_reminder_sent_message', 'Reminder sent to {officer}.'),
                           ('manual_reminder_no_officer_message', 'No officer is assigned.')]:
            ModuleSetting.objects.update_or_create(module_key='rti', setting_key=key,
                                                   defaults={'setting_value': value})
        headers = self._auth_headers(self.officer_a1)
        today = dt.date.today()

        def create(name, days_left, officer=None, outcome=None):
            body = {'rti_applicant_name': name,
                    'rti_received_date': (today - dt.timedelta(days=5)).strftime('%d/%m/%Y'),
                    'rti_due_date': (today + dt.timedelta(days=days_left)).strftime('%d/%m/%Y')}
            if officer:
                body['rti_assigned_officer_uid'] = officer.uid
            if outcome:
                body.update({'rti_outcome': 'Replied', 'rti_replied_date': today.strftime('%d/%m/%Y')})
            res = self.client.post('/api/rti/', data=json.dumps(body), content_type='application/json', **headers)
            self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.content)
            return res.json()['rti_id']

        create('Due In 25', 25, self.officer_a1)                       # 2nd reminder today
        create('Due In 27', 27, self.officer_a1)                       # no reminder today
        create('Due In 3', 3, self.officer_a1)                         # daily
        create('Replied Already', 3, self.officer_a1, outcome=True)    # disposed: no reminder
        create('Other Officer', 3, self.officer_a2)                    # someone else's
        no_officer_id = create('No Officer', 3)

        res = self.client.get('/api/rti/reminders/', **headers)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        kinds = sorted(r['kind'] for r in res.json()['results'])
        self.assertEqual(kinds, ['daily', 'second'])

        # Officer a2 only sees their own reminder
        res_a2 = self.client.get('/api/rti/reminders/', **self._auth_headers(self.officer_a2))
        self.assertEqual([r['kind'] for r in res_a2.json()['results']], ['daily'])

        # Manual reminder from the Summary tab goes to the assigned officer
        target_id = create('Manual Target', 20, self.officer_a2)
        sent = self.client.post(f'/api/rti/{target_id}/remind/', **headers)
        self.assertEqual(sent.status_code, status.HTTP_201_CREATED, sent.content)
        self.assertIn('Reminder sent to', sent.json()['message'])
        res_a2 = self.client.get('/api/rti/reminders/', **self._auth_headers(self.officer_a2))
        self.assertIn('manual', [r['kind'] for r in res_a2.json()['results']])

        # Marking seen hides manual reminders; scheduled ones stay
        self.client.post('/api/rti/reminders/seen/', **self._auth_headers(self.officer_a2))
        res_a2 = self.client.get('/api/rti/reminders/', **self._auth_headers(self.officer_a2))
        self.assertNotIn('manual', [r['kind'] for r in res_a2.json()['results']])

        # No assigned officer -> 400; another station's RTI -> 404
        self.assertEqual(self.client.post(f'/api/rti/{no_officer_id}/remind/', **headers).status_code,
                         status.HTTP_400_BAD_REQUEST)
        other = self.client.post(f'/api/rti/{target_id}/remind/', **self._auth_headers(self.officer_b1))
        self.assertEqual(other.status_code, status.HTTP_404_NOT_FOUND)

    def test_reminders_stop_once_information_given_date_is_entered(self):
        import datetime as dt
        for key, value in [('reminder_first_days_before', '30'), ('reminder_second_days_before', '25'),
                           ('reminder_daily_from_days_before', '24'),
                           ('manual_reminder_info_given_message', 'Information already given.')]:
            ModuleSetting.objects.update_or_create(module_key='rti', setting_key=key,
                                                   defaults={'setting_value': value})
        headers = self._auth_headers(self.officer_a1)
        today = dt.date.today()
        due = (today + dt.timedelta(days=3)).strftime('%d/%m/%Y')

        def create(name, **extra):
            body = {'rti_applicant_name': name, 'rti_due_date': due,
                    'rti_received_date': (today - dt.timedelta(days=5)).strftime('%d/%m/%Y'),
                    'rti_assigned_officer_uid': self.officer_a1.uid, **extra}
            res = self.client.post('/api/rti/', data=json.dumps(body), content_type='application/json', **headers)
            self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.content)
            return res.json()['rti_id']

        def reminded_ids():
            res = self.client.get('/api/rti/reminders/', **headers)
            return {r.get('rti_id') for r in res.json()['results'] if r['kind'] != 'manual'}

        open_id = create('Still Open')
        # Transferred but no Transfer Date yet: reminders continue
        no_date_id = create('Transferred No Date', rti_outcome='Transferred', rti_transferred_to='District Office')
        # Transferred with its date: reminders stop
        dated_id = create('Transferred Dated', rti_outcome='Transferred', rti_transferred_to='District Office',
                          rti_transferred_date=today.strftime('%d/%m/%Y'))
        ids = reminded_ids()
        self.assertIn(open_id, ids)
        self.assertIn(no_date_id, ids)
        self.assertNotIn(dated_id, ids)

        # A manual reminder is hidden once the application gets its Replied Date
        self.assertEqual(self.client.post(f'/api/rti/{open_id}/remind/', **headers).status_code,
                         status.HTTP_201_CREATED)
        patch = {'rti_outcome': 'Replied', 'rti_replied_date': today.strftime('%d/%m/%Y')}
        self.assertEqual(self.client.patch(f'/api/rti/{open_id}/', data=json.dumps(patch),
                                           content_type='application/json', **headers).status_code, 200)
        res = self.client.get('/api/rti/reminders/', **headers).json()['results']
        self.assertNotIn('manual', [r['kind'] for r in res])
        self.assertNotIn(open_id, reminded_ids())

        # Send Reminder on an answered application is refused with the setting message
        refused = self.client.post(f'/api/rti/{dated_id}/remind/', **headers)
        self.assertEqual(refused.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(refused.json()['error'], 'Information already given.')

    def test_mobile_and_email_are_optional_but_validated_when_filled(self):
        headers = self._auth_headers(self.officer_a1)

        def post(extra):
            body = {'rti_applicant_name': 'Validation Citizen', **extra}
            return self.client.post('/api/rti/', data=json.dumps(body), content_type='application/json', **headers)

        # Both empty: saves (not required)
        ok = post({'rti_mobile_no': '', 'rti_email': ''})
        self.assertEqual(ok.status_code, status.HTTP_201_CREATED, ok.content)
        rti_id = ok.json()['rti_id']

        # Valid values save
        good = post({'rti_mobile_no': '9876543210', 'rti_email': 'citizen@example.com'})
        self.assertEqual(good.status_code, status.HTTP_201_CREATED, good.content)

        # More than 10 digits / bad e-mail are rejected with 400
        self.assertEqual(post({'rti_mobile_no': '98765432101'}).status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(post({'rti_email': 'citizen@'}).status_code, status.HTTP_400_BAD_REQUEST)

        # Same checks on edit (no 500 from the database rule)
        def patch(extra):
            return self.client.patch(f'/api/rti/{rti_id}/', data=json.dumps(extra), content_type='application/json', **headers)
        self.assertEqual(patch({'rti_mobile_no': '123'}).status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(patch({'rti_email': 'no-at-sign'}).status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(patch({'rti_mobile_no': '9123456789', 'rti_email': 'a@b.in'}).status_code, status.HTTP_200_OK)
        self.assertEqual(patch({'rti_mobile_no': '', 'rti_email': ''}).status_code, status.HTTP_200_OK)

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
