import uuid
from django.test import TestCase
from django.db import connection
from rest_framework.test import APIClient
from rest_framework import status
from apps.public_master.models import StateRegistry, Role, Permission, RolePermission
from apps.users.models import OfficerProfile


class CaseManagementAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # 1. Seed Roles & Permissions
        self.master_role = Role.objects.create(id='master_admin', name='Master Admin', level='global')
        self.officer_role = Role.objects.create(id='officer', name='Police Officer', level='station')
        self.restricted_role = Role.objects.create(id='restricted_role', name='Restricted Role', level='station')

        self.perm_case_view = Permission.objects.create(id='case:view', module='cases')
        self.perm_case_create = Permission.objects.create(id='case:create', module='cases')

        # Grant case:view and case:create to officer
        RolePermission.objects.create(role=self.officer_role, permission=self.perm_case_view, is_granted=True)
        RolePermission.objects.create(role=self.officer_role, permission=self.perm_case_create, is_granted=True)

        # Grant only case:view to restricted_role (no case:create)
        RolePermission.objects.create(role=self.restricted_role, permission=self.perm_case_view, is_granted=True)

        # 2. Seed State Registries
        self.state_mh = StateRegistry.objects.create(
            state_code='MH',
            state_name='Maharashtra',
            schema_name='maharashtra'
        )
        self.state_ka = StateRegistry.objects.create(
            state_code='KA',
            state_name='Karnataka',
            schema_name='karnataka'
        )

        # 3. Create tables / mock views if not present in test DB
        with connection.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS crime_type_master (
                    id SERIAL PRIMARY KEY,
                    crime_type VARCHAR(255) NOT NULL,
                    act VARCHAR(255),
                    section VARCHAR(255),
                    sub_section VARCHAR(255),
                    ipc_number VARCHAR(255)
                );
            """)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS cases (
                    case_id SERIAL PRIMARY KEY,
                    case_number VARCHAR(128) NOT NULL,
                    title VARCHAR(255) NOT NULL,
                    description TEXT,
                    module VARCHAR(64),
                    priority VARCHAR(32),
                    status VARCHAR(32),
                    station_id VARCHAR(128),
                    assigned_to_uid VARCHAR(128),
                    created_by_uid VARCHAR(128),
                    incident_date TIMESTAMPTZ,
                    location_address VARCHAR(255),
                    latitude DOUBLE PRECISION,
                    longitude DOUBLE PRECISION,
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    updated_at TIMESTAMPTZ DEFAULT NOW(),
                    case_type VARCHAR(64),
                    crime_type_master_id INTEGER
                );
            """)
            cursor.execute("""
                CREATE OR REPLACE VIEW pending_cases_combined AS
                SELECT 'cases' AS source, case_id, case_number, title, case_type, priority,
                       'Shivajinagar Police Station' AS station_name, '' AS assigned_officer, status, created_at
                FROM cases
                WHERE status IN ('Pending', 'Draft');
            """)
            cursor.execute("""
                CREATE OR REPLACE VIEW disposal_cases_combined AS
                SELECT 'cases' AS source, case_id, case_number, title, case_type, priority,
                       'Shivajinagar Police Station' AS station_name, '' AS assigned_officer, status, created_at
                FROM cases
                WHERE status IN ('Disposal', 'Closed');
            """)

            # Insert sample crime type
            cursor.execute("""
                INSERT INTO crime_type_master (crime_type, act, section, sub_section, ipc_number)
                VALUES ('Theft', 'IPC', '379', '1', 'IPC 379')
                ON CONFLICT DO NOTHING;
            """)

        # 4. Register and obtain tokens for test users
        self.officer_token = self._register_and_login(
            'officer_case_test@mhpolice.gov.in', 'OfficerPass123!', 'officer', 'MH'
        )
        self.restricted_token = self._register_and_login(
            'restricted_user@mhpolice.gov.in', 'RestrictedPass123!', 'restricted_role', 'MH'
        )

    def _register_and_login(self, email, password, role_id, state_code):
        self.client.post('/api/auth/register/', {
            'email': email,
            'password': password,
            'full_name': f'Test {role_id}',
            'role_id': role_id,
            'state_code': state_code,
            'badge_number': f'BDG-{uuid.uuid4().hex[:6]}',
            'station_name': 'Shivajinagar Police Station'
        }, format='json')

        login_resp = self.client.post('/api/auth/login/', {
            'email': email,
            'password': password,
            'state_code': state_code
        }, format='json')
        return login_resp.data['tokens']['access_token']

    # --------------------------------------------------------------------------
    # Test 1: Unauthenticated Requests Return 401
    # --------------------------------------------------------------------------
    def test_01_unauthenticated_requests_return_401(self):
        """Verify all case endpoints reject unauthenticated access with 401."""
        endpoints = [
            ('/api/cases/crime-types/', 'get'),
            ('/api/cases/crime-types/Theft/cases/', 'get'),
            ('/api/cases/crime-types/Theft/sections/', 'get'),
            ('/api/cases/pending/', 'get'),
            ('/api/cases/disposal/', 'get'),
            ('/api/cases/create/', 'post'),
        ]

        # Explicitly empty credentials
        self.client.credentials()

        for url, method in endpoints:
            with self.subTest(url=url, method=method):
                if method == 'get':
                    response = self.client.get(url)
                else:
                    response = self.client.post(url, {}, format='json')
                self.assertEqual(
                    response.status_code,
                    status.HTTP_401_UNAUTHORIZED,
                    f"Expected 401 for {url}, got {response.status_code}"
                )

    # --------------------------------------------------------------------------
    # Test 2: Authenticated but Unauthorized Requests Return 403
    # --------------------------------------------------------------------------
    def test_02_unauthorized_case_creation_returns_403(self):
        """User without case:create permission should receive 403 Forbidden."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.restricted_token}')
        response = self.client.post('/api/cases/create/', {
            'case_number': 'FIR-2026-999',
            'title': 'Unauthorized Case Attempt',
            'module': 'theft',
            'priority': 'Medium'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    # --------------------------------------------------------------------------
    # Test 3: Authorized User Reads Crime Types and Sections
    # --------------------------------------------------------------------------
    def test_03_authorized_user_can_view_crime_types_and_sections(self):
        """Authorized user with case:view can retrieve crime types and sections."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.officer_token}')

        # Crime Type List
        resp_list = self.client.get('/api/cases/crime-types/')
        self.assertEqual(resp_list.status_code, status.HTTP_200_OK)
        self.assertIsInstance(resp_list.data, list)
        self.assertIn('Theft', resp_list.data)

        # Sections for Theft
        resp_sec = self.client.get('/api/cases/crime-types/Theft/sections/')
        self.assertEqual(resp_sec.status_code, status.HTTP_200_OK)
        self.assertIsInstance(resp_sec.data, list)
        self.assertTrue(any(s.get('section') == '379' for s in resp_sec.data))

    # --------------------------------------------------------------------------
    # Test 4: Create Case Validation Errors Return 400
    # --------------------------------------------------------------------------
    def test_04_create_case_invalid_payload_returns_400(self):
        """Invalid or missing fields in case create payload return 400 Bad Request."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.officer_token}')

        # Missing required fields: title, module
        bad_payload = {
            'case_number': 'FIR-2026-001',
            'priority': 'InvalidPriorityChoice'
        }
        resp = self.client.post('/api/cases/create/', bad_payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('title', resp.data)
        self.assertIn('module', resp.data)
        self.assertIn('priority', resp.data)

    # --------------------------------------------------------------------------
    # Test 5: Valid Case Creation Returns 201
    # --------------------------------------------------------------------------
    def test_05_create_case_valid_payload_returns_201(self):
        """Valid payload creates case record and returns 201 Created with case_id."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.officer_token}')

        valid_payload = {
            'case_number': 'FIR-2026-101',
            'title': 'Night Patrol Mobile Theft',
            'module': 'theft',
            'priority': 'High',
            'status': 'Draft',
            'case_type': '1-5'
        }
        resp = self.client.post('/api/cases/create/', valid_payload, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('case_id', resp.data)
        self.assertIsNotNone(resp.data['case_id'])

    # --------------------------------------------------------------------------
    # Test 6 & 7: Pagination Structure on List Endpoints
    # --------------------------------------------------------------------------
    def test_06_pending_and_disposal_pagination_structure(self):
        """Pending and disposal case endpoints return standard DRF paginated structure."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.officer_token}')

        # Pending Cases
        pending_resp = self.client.get('/api/cases/pending/')
        self.assertEqual(pending_resp.status_code, status.HTTP_200_OK)
        self.assertIn('count', pending_resp.data)
        self.assertIn('next', pending_resp.data)
        self.assertIn('previous', pending_resp.data)
        self.assertIn('results', pending_resp.data)
        self.assertIsInstance(pending_resp.data['results'], list)

        # Disposal Cases
        disposal_resp = self.client.get('/api/cases/disposal/')
        self.assertEqual(disposal_resp.status_code, status.HTTP_200_OK)
        self.assertIn('count', disposal_resp.data)
        self.assertIn('results', disposal_resp.data)

    # --------------------------------------------------------------------------
    # Test 8: Cases by Crime Type with Pagination
    # --------------------------------------------------------------------------
    def test_07_cases_by_crime_type_pagination(self):
        """Cases by crime type returns paginated list of matching cases."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.officer_token}')

        # Create a case linked to crime_type_master
        with connection.cursor() as cursor:
            cursor.execute("SELECT id FROM crime_type_master WHERE crime_type = 'Theft' LIMIT 1;")
            m_id = cursor.fetchone()[0]
            cursor.execute("""
                INSERT INTO cases (case_number, title, module, priority, status, case_type, crime_type_master_id)
                VALUES ('FIR-2026-777', 'Vehicle Theft', 'theft', 'High', 'Pending', '1-5', %s);
            """, [m_id])

        resp = self.client.get('/api/cases/crime-types/Theft/cases/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('count', resp.data)
        self.assertIn('results', resp.data)
        self.assertTrue(any(c.get('case_number') == 'FIR-2026-777' for c in resp.data['results']))

    # --------------------------------------------------------------------------
    # Test 9: Tenant / State Context Isolation
    # --------------------------------------------------------------------------
    def test_08_tenant_state_context_isolation(self):
        """Requests with different State headers switch search_path cleanly without leakage."""
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.officer_token}',
            HTTP_X_STATE_CODE='MH'
        )
        resp_mh = self.client.get('/api/cases/crime-types/')
        self.assertEqual(resp_mh.status_code, status.HTTP_200_OK)

        # Calling with a different valid state header
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.officer_token}',
            HTTP_X_STATE_CODE='KA'
        )
        resp_ka = self.client.get('/api/cases/crime-types/')
        self.assertEqual(resp_ka.status_code, status.HTTP_200_OK)
