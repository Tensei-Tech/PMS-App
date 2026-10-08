import uuid
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.public_master.models import Role, Permission, RolePermission, StateRegistry
from apps.users.models import OfficerProfile
from apps.cases.models import CaseRecord


class UndetectedAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        from apps.core.cache import upstash_cache
        upstash_cache.delete_pattern("pms:cache:*")

        # Seed roles and permissions
        self.officer_role, _ = Role.objects.get_or_create(id='officer', defaults={'name': 'Police Officer', 'level': 'station'})
        self.perm_case_view, _ = Permission.objects.get_or_create(id='case:view', defaults={'module': 'cases'})
        self.perm_case_create, _ = Permission.objects.get_or_create(id='case:create', defaults={'module': 'cases'})
        RolePermission.objects.get_or_create(role=self.officer_role, permission=self.perm_case_view, defaults={'is_granted': True})
        RolePermission.objects.get_or_create(role=self.officer_role, permission=self.perm_case_create, defaults={'is_granted': True})

        self.state_mh, _ = StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )

        self.officer_token = self._register_and_login(
            'pi_pawar_undetected@mhpolice.gov.in', 'OfficerPass123!', 'officer', 'MH'
        )
        self.officer = OfficerProfile.objects.get(email='pi_pawar_undetected@mhpolice.gov.in')

        # Seed test cases
        # 1. Undetected theft (no accused)
        self.c1 = CaseRecord.objects.create(
            module_key='theft',
            title='House Break-in',
            case_number='CR-201/2026',
            accused='',
            station_name='Shivajinagar Police Station',
            assigned_officer='PI Pawar',
            assigned_officer_uid=self.officer.uid,
            created_by=self.officer.uid
        )

        # 2. Undetected murder (unknown accused)
        self.c2 = CaseRecord.objects.create(
            module_key='murder',
            title='Highway Incident',
            case_number='CR-202/2026',
            accused='Unknown',
            station_name='Shivajinagar Police Station',
            assigned_officer='PI Pawar',
            assigned_officer_uid=self.officer.uid,
            created_by=self.officer.uid
        )

        # 3. Detected theft (named accused)
        self.c3 = CaseRecord.objects.create(
            module_key='theft',
            title='Vehicle Snatching',
            case_number='CR-203/2026',
            accused='Ganesh Shinde',
            station_name='Shivajinagar Police Station',
            assigned_officer='PI Pawar',
            assigned_officer_uid=self.officer.uid,
            created_by=self.officer.uid
        )

        # 4. Disposed case
        self.c4 = CaseRecord.objects.create(
            module_key='theft',
            title='Old Theft Case',
            case_number='CR-204/2026',
            accused='Anil Deshmukh',
            status='Disposal',
            station_name='Shivajinagar Police Station',
            assigned_officer='PI Pawar',
            assigned_officer_uid=self.officer.uid,
            created_by=self.officer.uid,
            extra_fields={'ccStNumber': 'CC-999/2026'}
        )

    def _register_and_login(self, email, password, role_id, state_code):
        OfficerProfile.objects.filter(email=email).delete()
        self.client.post('/api/auth/register/', {
            'email': email,
            'password': password,
            'full_name': 'PI Pawar',
            'role_id': role_id,
            'state_code': state_code,
            'badge_number': f'BDG-{uuid.uuid4().hex[:6]}',
            'station_name': 'Shivajinagar Police Station',
            'account_status': 'active',
        }, format='json')

        login_resp = self.client.post('/api/auth/login/', {
            'email': email,
            'password': password,
            'state_code': state_code
        }, format='json')
        return login_resp.data['tokens']['access_token']

    def test_filter_by_module_key_undetected(self):
        """Test GET /api/cases/?module_key=undetected returns only undetected cases."""
        from apps.core.cache import upstash_cache
        upstash_cache.delete_pattern("pms:cache:*")
        response = self.client.get(
            '/api/cases/',
            {'module_key': 'undetected'},
            HTTP_AUTHORIZATION=f'Bearer {self.officer_token}'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get('results') if isinstance(response.data, dict) else response.data
        case_ids = [str(r['id']) for r in results]
        self.assertIn(str(self.c1.id), case_ids)
        self.assertIn(str(self.c2.id), case_ids)
        self.assertNotIn(str(self.c3.id), case_ids)
        self.assertNotIn(str(self.c4.id), case_ids)

    def test_filter_by_module_key_detected(self):
        """Test GET /api/cases/?module_key=detected returns only detected non-disposed cases."""
        from apps.core.cache import upstash_cache
        upstash_cache.delete_pattern("pms:cache:*")
        response = self.client.get(
            '/api/cases/',
            {'module_key': 'detected'},
            HTTP_AUTHORIZATION=f'Bearer {self.officer_token}'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get('results') if isinstance(response.data, dict) else response.data
        case_ids = [str(r['id']) for r in results]
        self.assertNotIn(str(self.c1.id), case_ids)
        self.assertNotIn(str(self.c2.id), case_ids)
        self.assertIn(str(self.c3.id), case_ids)
        self.assertNotIn(str(self.c4.id), case_ids)

    def test_undetected_cases_view(self):
        """Test GET /api/cases/undetected/ endpoint."""
        response = self.client.get(
            '/api/cases/undetected/',
            HTTP_AUTHORIZATION=f'Bearer {self.officer_token}'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data.get('results') if isinstance(response.data, dict) else response.data
        case_ids = [str(r['id']) for r in results]
        self.assertIn(str(self.c1.id), case_ids)
        self.assertIn(str(self.c2.id), case_ids)
        self.assertNotIn(str(self.c3.id), case_ids)

    def test_undetected_io_wise_view(self):
        """Test GET /api/cases/undetected/io-wise/ endpoint."""
        response = self.client.get(
            '/api/cases/undetected/io-wise/',
            HTTP_AUTHORIZATION=f'Bearer {self.officer_token}'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data) > 0)
        self.assertEqual(response.data[0]['undetected_count'], 2)

    def test_undetected_time_wise_view(self):
        """Test GET /api/cases/undetected/time-wise/ endpoint."""
        response = self.client.get(
            '/api/cases/undetected/time-wise/',
            HTTP_AUTHORIZATION=f'Bearer {self.officer_token}'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(isinstance(response.data, list))

