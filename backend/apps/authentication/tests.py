import uuid
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission
from apps.users.models import OfficerProfile


class PrimaryAuthAndRBACBackendTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.run_id = uuid.uuid4().hex[:6]

        # Seed initial Roles & Permissions
        self.master_role, _ = Role.objects.get_or_create(id='master_admin', defaults={'name': 'Master Admin', 'level': 'global'})
        self.officer_role, _ = Role.objects.get_or_create(id='officer', defaults={'name': 'Police Officer', 'level': 'station'})

        self.perm_case_create, _ = Permission.objects.get_or_create(id='case:create', defaults={'module': 'cases'})
        self.perm_case_approve, _ = Permission.objects.get_or_create(id='case:approve', defaults={'module': 'cases'})

        # Grant case:create to officer, but not case:approve
        RolePermission.objects.get_or_create(role=self.officer_role, permission=self.perm_case_create, defaults={'is_granted': True})

        # Create default Maharashtra state
        self.state_mh, _ = StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )

    def test_01_master_admin_registration_and_login(self):
        """Test Master Admin registration & login via primary backend endpoint."""
        email = f'master_{self.run_id}@pms.gov.in'
        reg_resp = self.client.post('/api/auth/register/', {
            'email': email,
            'password': 'MasterPassword123!',
            'full_name': 'Test Master Admin',
            'role_id': 'master_admin'
        }, format='json')

        self.assertEqual(reg_resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('tokens', reg_resp.data)
        self.assertIn('access_token', reg_resp.data['tokens'])

        # Perform Login
        login_resp = self.client.post('/api/auth/login/', {
            'email': email,
            'password': 'MasterPassword123!',
        }, format='json')

        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(login_resp.data['user']['role_id'], 'master_admin')
        self.assertIn('access_token', login_resp.data['tokens'])

    def test_02_officer_registration_and_login(self):
        """Test State Officer registration & login with state context."""
        email = f'officer1_{self.run_id}@mhpolice.gov.in'
        reg_resp = self.client.post('/api/auth/register/', {
            'email': email,
            'password': 'OfficerPassword123!',
            'full_name': 'Sub Inspector Shinde',
            'role_id': 'officer',
            'state_code': 'MH',
            'badge_number': f'MH-{self.run_id}',
            'station_name': 'Shivajinagar Police Station',
            'account_status': 'active'
        }, format='json')

        self.assertEqual(reg_resp.status_code, status.HTTP_201_CREATED)

        # Login as Officer
        login_resp = self.client.post('/api/auth/login/', {
            'email': email,
            'password': 'OfficerPassword123!',
            'state_code': 'MH'
        }, format='json')

        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(login_resp.data['user']['role_id'], 'officer')

        access_token = login_resp.data['tokens']['access_token']

        # Test Dynamic Permissions API
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}', HTTP_X_STATE_CODE='MH')
        perm_resp = self.client.get('/api/auth/me/permissions/')

        self.assertEqual(perm_resp.status_code, status.HTTP_200_OK)
        self.assertIn('case:create', perm_resp.data['permissions'])
        self.assertNotIn('case:approve', perm_resp.data['permissions'])

    def test_03_dynamic_rbac_live_update(self):
        """Test that updating public.role_permissions instantly grants new permissions to officer."""
        # Grant case:approve dynamically to officer role
        RolePermission.objects.get_or_create(role=self.officer_role, permission=self.perm_case_approve, defaults={'is_granted': True})

        email = f'officer2_{self.run_id}@mhpolice.gov.in'
        # Register officer
        reg_resp = self.client.post('/api/auth/register/', {
            'email': email,
            'password': 'OfficerPassword123!',
            'full_name': 'Constable Patil',
            'role_id': 'officer',
            'state_code': 'MH',
            'account_status': 'active'
        }, format='json')
        self.assertEqual(reg_resp.status_code, status.HTTP_201_CREATED)

        login_resp = self.client.post('/api/auth/login/', {
            'email': email,
            'password': 'OfficerPassword123!',
            'state_code': 'MH'
        }, format='json')

        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
        access_token = login_resp.data['tokens']['access_token']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

        perm_resp = self.client.get('/api/auth/me/permissions/')
        self.assertIn('case:approve', perm_resp.data['permissions'])

