"""
Admin onboarding chain, order state > district or city > division (a
sub-division) > station: state admin -> district, city, division admins and
station heads; district or city admin -> division admins and station heads of
their area; division admin -> station heads of its division.

Every account an admin creates waits in Pending Approvals. The admin who
created it and every admin above them in that area see it there and may
approve it; once approved it logs in with the password the admin set.
"""
import uuid

from rest_framework import status

from apps.authentication.test_security_holes import SecurityTestBase, _officer, _officer_headers, _save_everywhere
from apps.users.models import OfficerProfile


class OnboardingChainTests(SecurityTestBase):
    def setUp(self):
        super().setUp()
        self.state_admin = _officer('state_admin', station='', district='', division='')
        self.district_admin = _officer('district_admin', station='', district='Ahilyanagar', division='')
        self.other_district_admin = _officer('district_admin', station='', district='Satara', division='')
        self.division_admin = _officer('division_admin', station='', district='Ahilyanagar',
                                       division='Shirdi Sub-Division')
        self.other_division_admin = _officer('division_admin', station='', district='Ahilyanagar',
                                             division='Sangamner Sub-Division')
        self.city_admin = _officer('city_admin', station='', district='Pune City', division='')

    def _onboard(self, caller, **body):
        email = f'n-{uuid.uuid4().hex[:6]}@mh.gov.in'
        # PI is on both the district and the city designation lists.
        payload = {'email': email, 'password': 'Admin@123', 'full_name': 'New Admin',
                   'state_code': 'MH', 'district': 'Ahilyanagar', 'designation': 'PI'}
        payload.update(body)
        response = self.client.post('/api/auth/register/', payload, format='json', **_officer_headers(caller))
        self.assertEqual(response.status_code, status.HTTP_202_ACCEPTED, response.data)
        return OfficerProfile.objects.get(email=email)

    def _sees(self, caller, account):
        response = self.client.get('/api/auth/notifications/pending-approvals/', **_officer_headers(caller))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        return account.uid in {item['registration_uid'] for item in response.data}

    def _approve(self, caller, account):
        return self.client.post(f'/api/auth/users/{account.uid}/approve-registration/', {'action': 'approve'},
                                format='json', **_officer_headers(caller))

    def _status(self, account):
        return OfficerProfile.objects.get(uid=account.uid).account_status

    def test_every_account_an_admin_creates_waits_in_pending(self):
        made = [
            self._onboard(self.state_admin, role_id='district_admin'),
            self._onboard(self.state_admin, role_id='city_admin', district='Pune City', designation='CP'),
            self._onboard(self.state_admin, role_id='division_admin', zone='Shirdi Sub-Division'),
            self._onboard(self.state_admin, role_id='station_head', station_name='Shirdi Police Station'),
        ]
        self.assertEqual({self._status(a) for a in made}, {'pending_approval'})
        # The typed sub-division is saved as the division.
        self.assertEqual(made[2].division_name, 'Shirdi Sub-Division')
        self.assertEqual(made[1].district, 'Pune City')
        for account in made:
            self.assertTrue(self._sees(self.state_admin, account))

    def test_district_admin_and_state_admin_approve_what_the_district_admin_creates(self):
        division = self._onboard(self.district_admin, role_id='division_admin',
                                 division_name='Rahata Sub-Division', designation='SDPO')
        head = self._onboard(self.district_admin, role_id='station_head', station_name='Rahata Police Station')
        for account in (division, head):
            self.assertTrue(self._sees(self.district_admin, account))
            self.assertTrue(self._sees(self.state_admin, account))
            self.assertFalse(self._sees(self.other_district_admin, account))
        self.assertFalse(self._sees(self.division_admin, division))  # same level

        self.assertEqual(self._approve(self.other_district_admin, head).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self._approve(self.district_admin, head).status_code, status.HTTP_200_OK)
        self.assertEqual(self._approve(self.state_admin, division).status_code, status.HTTP_200_OK)
        self.assertEqual((self._status(head), self._status(division)), ('active', 'active'))

    def test_division_district_and_state_admin_approve_what_the_division_admin_creates(self):
        head = self._onboard(self.division_admin, role_id='station_head', division_name='Shirdi Sub-Division',
                             station_name='Shirdi Police Station')
        for approver in (self.division_admin, self.district_admin, self.state_admin):
            self.assertTrue(self._sees(approver, head), approver.uid)
        for outsider in (self.other_division_admin, self.other_district_admin):
            self.assertFalse(self._sees(outsider, head), outsider.uid)
        self.assertEqual(self._approve(self.other_division_admin, head).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self._approve(self.division_admin, head).status_code, status.HTTP_200_OK)
        self.assertEqual(self._status(head), 'active')

    def test_same_sub_division_name_in_another_district_is_outside(self):
        # Made by the state admin: the Shirdi division admin of Ahilyanagar may not approve it.
        head = self._onboard(self.state_admin, role_id='station_head', district='Satara',
                             division_name='Shirdi Sub-Division', station_name='Satara City Police Station')
        self.assertFalse(self._sees(self.division_admin, head))
        self.assertTrue(self._sees(self.other_district_admin, head))

    def test_city_admin_and_state_admin_approve_what_the_city_admin_creates(self):
        division = self._onboard(self.city_admin, role_id='division_admin', district='Pune City',
                                 division_name='Zone 1', designation='DCP')
        head = self._onboard(self.city_admin, role_id='station_head', district='Pune City',
                             station_name='Shivajinagar Police Station', designation='Jt. CP')
        for account in (division, head):
            self.assertTrue(self._sees(self.city_admin, account))
            self.assertTrue(self._sees(self.state_admin, account))
            self.assertFalse(self._sees(self.district_admin, account))
        self.assertEqual(self._approve(self.city_admin, division).status_code, status.HTTP_200_OK)
        self.assertEqual(self._approve(self.state_admin, head).status_code, status.HTTP_200_OK)

    def test_no_one_approves_their_own_level_or_above(self):
        # A peer district admin made by the state admin waits for the state admin.
        peer = self._onboard(self.state_admin, role_id='district_admin', district='Ahilyanagar')
        self.assertFalse(self._sees(self.district_admin, peer))
        self.assertEqual(self._approve(self.district_admin, peer).status_code, status.HTTP_403_FORBIDDEN)
        self.assertTrue(self._sees(self.state_admin, peer))

    def _refused(self, caller, **body):
        payload = {'email': f'x-{uuid.uuid4().hex[:6]}@mh.gov.in', 'password': 'Admin@123',
                   'full_name': 'X', 'state_code': 'MH', 'district': 'Ahilyanagar', 'designation': 'PI'}
        payload.update(body)
        response = self.client.post('/api/auth/register/', payload, format='json', **_officer_headers(caller))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN, response.data)
        self.assertFalse(OfficerProfile.objects.filter(email=payload['email']).exists())
        return response.data['error']

    def test_admins_create_only_below_their_own_level(self):
        self._refused(self.division_admin, role_id='district_admin')
        self._refused(self.district_admin, role_id='district_admin')
        self._refused(self.district_admin, role_id='city_admin', district='Pune City', designation='CP')

    def test_district_admin_creates_only_inside_their_district(self):
        # The Wardha example: a Wardha district admin creates only inside Wardha.
        wardha = _officer('district_admin', station='', district='Wardha', division='')
        self._onboard(wardha, role_id='division_admin', district='Wardha', division_name='Hinganghat Sub-Division',
                      designation='SDPO')
        self._onboard(wardha, role_id='station_head', district='Wardha', station_name='Arvi Police Station')
        error = self._refused(wardha, role_id='station_head', district='Nagpur', station_name='Sitabuldi Police Station')
        self.assertIn('Wardha', error)
        self._refused(wardha, role_id='division_admin', district='Nagpur', division_name='Kamptee Sub-Division',
                      designation='SDPO')

    def test_city_admin_creates_only_inside_their_city(self):
        self._onboard(self.city_admin, role_id='station_head', district='Pune City',
                      station_name='Shivajinagar Police Station', designation='PI')
        self.assertIn('Pune City', self._refused(self.city_admin, role_id='station_head', district='Pune',
                                                 station_name='Baramati Police Station'))

    def test_division_admin_creates_only_inside_their_sub_division(self):
        self._onboard(self.division_admin, role_id='station_head', division_name='Shirdi Sub-Division',
                      station_name='Shirdi Police Station')
        self.assertIn('Shirdi Sub-Division', self._refused(
            self.division_admin, role_id='station_head', division_name='Sangamner Sub-Division',
            station_name='Sangamner Police Station'))
        # The same sub-division name in another district is another area.
        self._refused(self.division_admin, role_id='station_head', district='Satara',
                      division_name='Shirdi Sub-Division', station_name='Satara City Police Station')

    def test_station_head_creates_only_inside_their_station(self):
        head = _officer('station_head', station='Shirdi Police Station', district='Ahilyanagar',
                        division='Shirdi Sub-Division')
        self._onboard(head, role_id='officer', station_name='Shirdi Police Station')
        self._refused(head, role_id='officer', station_name='Rahata Police Station')

    def test_state_admin_creates_only_in_their_state(self):
        self.assertIn('state', self._refused(self.state_admin, role_id='district_admin', state_code='GJ',
                                             district='Surat'))

    def test_city_admin_needs_a_city_and_a_city_designation(self):
        response = self.client.post('/api/auth/register/', {
            'email': 'nocity@mh.gov.in', 'password': 'Admin@123', 'full_name': 'No City', 'state_code': 'MH',
            'role_id': 'city_admin', 'district': '', 'designation': 'CP',
        }, format='json', **_officer_headers(self.state_admin))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        response = self.client.post('/api/auth/register/', {
            'email': 'sp@mh.gov.in', 'password': 'Admin@123', 'full_name': 'SP', 'state_code': 'MH',
            'role_id': 'city_admin', 'district': 'Pune City', 'designation': 'SP',
        }, format='json', **_officer_headers(self.state_admin))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('City Admin', response.data['error'])

    def test_city_admin_onboards_only_city_ranks(self):
        response = self.client.post('/api/auth/register/', {
            'email': 'dysp@mh.gov.in', 'password': 'Admin@123', 'full_name': 'DySP', 'state_code': 'MH',
            'role_id': 'division_admin', 'district': 'Pune City', 'division_name': 'Zone 2', 'designation': 'DySP',
        }, format='json', **_officer_headers(self.city_admin))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_district_admin_and_their_admins_hold_district_designations(self):
        response = self.client.post('/api/auth/register/', {
            'email': 'cp-dist@mh.gov.in', 'password': 'Admin@123', 'full_name': 'CP', 'state_code': 'MH',
            'role_id': 'district_admin', 'district': 'Ahilyanagar', 'designation': 'CP',
        }, format='json', **_officer_headers(self.state_admin))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('District Admin', response.data['error'])
        self._onboard(self.state_admin, role_id='district_admin', designation='Addl.SP')
        response = self.client.post('/api/auth/register/', {
            'email': 'acp-div@mh.gov.in', 'password': 'Admin@123', 'full_name': 'ACP', 'state_code': 'MH',
            'role_id': 'division_admin', 'district': 'Ahilyanagar', 'division_name': 'Rahuri Sub-Division',
            'designation': 'ACP',
        }, format='json', **_officer_headers(self.district_admin))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self._onboard(self.district_admin, role_id='division_admin', division_name='Rahuri Sub-Division',
                      designation='SDPO')

    def test_division_admin_holds_a_city_or_district_designation(self):
        for rank in ('ACP', 'SDPO'):  # one from each list
            self._onboard(self.state_admin, role_id='division_admin', division_name=f'{rank} Sub-Division',
                          designation=rank)
        response = self.client.post('/api/auth/register/', {
            'email': 'dysp-div@mh.gov.in', 'password': 'Admin@123', 'full_name': 'DySP', 'state_code': 'MH',
            'role_id': 'division_admin', 'district': 'Ahilyanagar', 'division_name': 'Other Sub-Division',
            'designation': 'DySP',
        }, format='json', **_officer_headers(self.state_admin))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Division Admin', response.data['error'])

    def test_hierarchy_directory_lists_city_admins_under_cities(self):
        self.city_admin.designation = 'ACP'  # a division-like rank must not move them under Divisions
        _save_everywhere(self.city_admin)
        response = self.client.get('/api/users/hierarchy-directory/', **_officer_headers(self.state_admin))
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        cities = {c['name']: [a['uid'] for a in c['admins']] for c in response.data['cities']}
        self.assertEqual(cities, {'Pune City': [self.city_admin.uid]})
        listed_elsewhere = [a['uid'] for group in ('divisions', 'districts') for unit in response.data[group]
                            for a in unit['admins']]
        self.assertNotIn(self.city_admin.uid, listed_elsewhere)

    def test_approved_admin_logs_in_with_the_password_set_for_them(self):
        head = self._onboard(self.district_admin, role_id='station_head', station_name='Rahata Police Station')
        login = {'email': head.email, 'password': 'Admin@123', 'state_code': 'MH'}
        self.assertNotEqual(self.client.post('/api/auth/login/', login, format='json').status_code,
                            status.HTTP_200_OK)
        self.assertEqual(self._approve(self.district_admin, head).status_code, status.HTTP_200_OK)
        response = self.client.post('/api/auth/login/', login, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.assertEqual(response.data['user']['role_id'], 'station_head')
