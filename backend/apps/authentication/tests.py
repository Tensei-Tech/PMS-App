from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission
from apps.users.models import OfficerProfile


class PrimaryAuthAndRBACBackendTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Seed initial Roles & Permissions
        self.master_role = Role.objects.create(id='master_admin', name='Master Admin', level='global')
        self.officer_role = Role.objects.create(id='officer', name='Police Officer', level='station')

        self.perm_case_create = Permission.objects.create(id='case:create', module='cases')
        self.perm_case_approve = Permission.objects.create(id='case:approve', module='cases')

        # Grant case:create to officer, but not case:approve
        RolePermission.objects.create(role=self.officer_role, permission=self.perm_case_create, is_granted=True)

        # Create default Maharashtra state
        self.state_mh = StateRegistry.objects.create(
            state_code='MH',
            state_name='Maharashtra',
            schema_name='maharashtra'
        )

    def test_01_master_admin_registration_and_login(self):
        """Test Master Admin registration & login via primary backend endpoint."""
        reg_resp = self.client.post('/api/auth/register/', {
            'email': 'mastertest@pms.gov.in',
            'password': 'MasterPassword123!',
            'full_name': 'Test Master Admin',
            'role_id': 'master_admin'
        }, format='json')

        self.assertEqual(reg_resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('tokens', reg_resp.data)
        self.assertIn('access_token', reg_resp.data['tokens'])

        # Perform Login
        login_resp = self.client.post('/api/auth/login/', {
            'email': 'mastertest@pms.gov.in',
            'password': 'MasterPassword123!',
        }, format='json')

        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(login_resp.data['user']['role_id'], 'master_admin')
        self.assertIn('access_token', login_resp.data['tokens'])

    def test_02_officer_registration_and_login(self):
        """Test State Officer registration & login with state context."""
        reg_resp = self.client.post('/api/auth/register/', {
            'email': 'officer1@mhpolice.gov.in',
            'password': 'OfficerPassword123!',
            'full_name': 'Sub Inspector Shinde',
            'role_id': 'officer',
            'state_code': 'MH',
            'badge_number': 'MH-1002',
            'station_name': 'Shivajinagar Police Station'
        }, format='json')

        self.assertEqual(reg_resp.status_code, status.HTTP_201_CREATED)

        # Login as Officer
        login_resp = self.client.post('/api/auth/login/', {
            'email': 'officer1@mhpolice.gov.in',
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
        RolePermission.objects.create(role=self.officer_role, permission=self.perm_case_approve, is_granted=True)

        # Register officer
        self.client.post('/api/auth/register/', {
            'email': 'officer2@mhpolice.gov.in',
            'password': 'OfficerPassword123!',
            'full_name': 'Constable Patil',
            'role_id': 'officer',
            'state_code': 'MH'
        }, format='json')

        login_resp = self.client.post('/api/auth/login/', {
            'email': 'officer2@mhpolice.gov.in',
            'password': 'OfficerPassword123!',
            'state_code': 'MH'
        }, format='json')

        access_token = login_resp.data['tokens']['access_token']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

        perm_resp = self.client.get('/api/auth/me/permissions/')
        self.assertIn('case:approve', perm_resp.data['permissions'])
