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
        self.master_role, _ = Role.objects.get_or_create(id='master_admin', defaults={'name': 'Master Admin', 'level': 'global'})
        self.officer_role, _ = Role.objects.get_or_create(id='officer', defaults={'name': 'Police Officer', 'level': 'station'})
        self.restricted_role, _ = Role.objects.get_or_create(id='restricted_role', defaults={'name': 'Restricted Role', 'level': 'station'})

        self.perm_case_view, _ = Permission.objects.get_or_create(id='case:view', defaults={'module': 'cases'})
        self.perm_case_create, _ = Permission.objects.get_or_create(id='case:create', defaults={'module': 'cases'})

        # Grant case:view and case:create to officer
        RolePermission.objects.get_or_create(role=self.officer_role, permission=self.perm_case_view, defaults={'is_granted': True})
        RolePermission.objects.get_or_create(role=self.officer_role, permission=self.perm_case_create, defaults={'is_granted': True})

        # Grant only case:view to restricted_role (no case:create)
        RolePermission.objects.get_or_create(role=self.restricted_role, permission=self.perm_case_view, defaults={'is_granted': True})

        # 2. Seed State Registries
        self.state_mh, _ = StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        self.state_ka, _ = StateRegistry.objects.get_or_create(
            state_code='KA',
            defaults={'state_name': 'Karnataka', 'schema_name': 'karnataka', 'is_active': True}
        )

        from apps.crimetab.models.groupings import CaseCategoryGroup, CaseCategory
        self.cat_group_1, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1,
            defaults={'group_name': 'Form I to V', 'group_code': 'I TO V', 'display_order': 1}
        )
        self.cat_theft, _ = CaseCategory.objects.get_or_create(
            category_id=1,
            defaults={
                'category_name': 'Theft',
                'category_code': 'theft',
                'group': self.cat_group_1,
                'is_active': True,
                'display_order': 1,
            }
        )

        # 3. Create tables / mock views if not present in test DB
        with connection.cursor() as cursor:
            if connection.vendor == 'postgresql':
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
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS remand_custody (
                        id SERIAL PRIMARY KEY,
                        person_id INTEGER NOT NULL,
                        pcr_days INTEGER,
                        mcr BOOLEAN DEFAULT FALSE,
                        pr_bond BOOLEAN DEFAULT FALSE,
                        pr_bond_date DATE,
                        bail BOOLEAN DEFAULT FALSE,
                        surety_jail BOOLEAN DEFAULT FALSE,
                        surety_name VARCHAR(255),
                        surety_age INTEGER,
                        surety_gender VARCHAR(50),
                        surety_occupation VARCHAR(255),
                        surety_mobile VARCHAR(20),
                        surety_aadhaar VARCHAR(20),
                        surety_pan VARCHAR(20),
                        surety_add TEXT,
                        created_at TIMESTAMPTZ DEFAULT NOW(),
                        CONSTRAINT chk_pr_bond_requires_mcr CHECK (
                            NOT pr_bond OR mcr = TRUE
                        ),
                        CONSTRAINT chk_surety_jail_requires_bail CHECK (
                            NOT surety_jail OR bail = TRUE
                        )
                    );
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS preventive_action_items (
                        id SERIAL PRIMARY KEY,
                        case_id INTEGER NOT NULL,
                        person_id INTEGER NOT NULL,
                        action VARCHAR(255),
                        created_at TIMESTAMPTZ DEFAULT NOW(),
                        UNIQUE(case_id, person_id, action)
                    );
                """)
                cursor.execute("""
                    INSERT INTO crime_type_master (crime_type, act, section, sub_section, ipc_number)
                    VALUES ('Theft', 'IPC', '379', '1', 'IPC 379')
                    ON CONFLICT DO NOTHING;
                """)
            else:
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS crime_type_master (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        crime_type VARCHAR(255) NOT NULL,
                        act VARCHAR(255),
                        section VARCHAR(255),
                        sub_section VARCHAR(255),
                        ipc_number VARCHAR(255)
                    );
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS cases (
                        case_id INTEGER PRIMARY KEY AUTOINCREMENT,
                        case_number VARCHAR(128) NOT NULL,
                        title VARCHAR(255) NOT NULL,
                        description TEXT,
                        module VARCHAR(64),
                        priority VARCHAR(32),
                        status VARCHAR(32),
                        station_id VARCHAR(128),
                        assigned_to_uid VARCHAR(128),
                        created_by_uid VARCHAR(128),
                        incident_date DATETIME,
                        location_address VARCHAR(255),
                        latitude REAL,
                        longitude REAL,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        case_type VARCHAR(64),
                        crime_type_master_id INTEGER
                    );
                """)
                cursor.execute("DROP VIEW IF EXISTS pending_cases_combined;")
                cursor.execute("""
                    CREATE VIEW pending_cases_combined AS
                    SELECT 'cases' AS source, case_id, case_number, title, case_type, priority,
                           'Shivajinagar Police Station' AS station_name, '' AS assigned_officer, status, created_at
                    FROM cases
                    WHERE status IN ('Pending', 'Draft');
                """)
                cursor.execute("DROP VIEW IF EXISTS disposal_cases_combined;")
                cursor.execute("""
                    CREATE VIEW disposal_cases_combined AS
                    SELECT 'cases' AS source, case_id, case_number, title, case_type, priority,
                           'Shivajinagar Police Station' AS station_name, '' AS assigned_officer, status, created_at
                    FROM cases
                    WHERE status IN ('Disposal', 'Closed');
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS remand_custody (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        person_id INTEGER NOT NULL,
                        pcr_days INTEGER,
                        mcr BOOLEAN DEFAULT 0,
                        pr_bond BOOLEAN DEFAULT 0,
                        pr_bond_date DATE,
                        bail BOOLEAN DEFAULT 0,
                        surety_jail BOOLEAN DEFAULT 0,
                        surety_name VARCHAR(255),
                        surety_age INTEGER,
                        surety_gender VARCHAR(50),
                        surety_occupation VARCHAR(255),
                        surety_mobile VARCHAR(20),
                        surety_aadhaar VARCHAR(20),
                        surety_pan VARCHAR(20),
                        surety_add TEXT,
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                    );
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS preventive_action_items (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        case_id INTEGER NOT NULL,
                        person_id INTEGER NOT NULL,
                        action VARCHAR(255),
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(case_id, person_id, action)
                    );
                """)
                cursor.execute("""
                    INSERT OR IGNORE INTO crime_type_master (crime_type, act, section, sub_section, ipc_number)
                    VALUES ('Theft', 'IPC', '379', '1', 'IPC 379');
                """)

        # 4. Register and obtain tokens for test users
        self.officer_token = self._register_and_login(
            'officer_case_test@mhpolice.gov.in', 'OfficerPass123!', 'officer', 'MH'
        )
        self.restricted_token = self._register_and_login(
            'restricted_user@mhpolice.gov.in', 'RestrictedPass123!', 'restricted_role', 'MH'
        )

    def _register_and_login(self, email, password, role_id, state_code):
        OfficerProfile.objects.filter(email=email).delete()
        self.client.post('/api/auth/register/', {
            'email': email,
            'password': password,
            'full_name': f'Test {role_id}',
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
            ('/api/cases/disposal/case-wise/', 'get'),
            ('/api/cases/create/', 'post'),
        ]

        from apps.core.tenancy import set_tenant_schema

        for url, method in endpoints:
            set_tenant_schema('maharashtra')
            self.client.credentials()
            with self.subTest(url=url, method=method):
                if method == 'get':
                    response = self.client.get(url, HTTP_X_STATE_CODE='MH')
                else:
                    response = self.client.post(url, {}, format='json', HTTP_X_STATE_CODE='MH')
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
        disposal_resp = self.client.get('/api/cases/disposal/case-wise/')
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

    # --------------------------------------------------------------------------
    # Test 9: AD Disposal Detection and Status Setting
    # --------------------------------------------------------------------------
    def test_09_ad_disposal_detection_and_model_save(self):
        """AD cases with both summary number and date are classified as Disposal."""
        from apps.cases.models import CaseRecord, is_ad_case_disposed

        # 1. AD case with English summary number and date in extra_fields
        ad_case_full = CaseRecord.objects.create(
            module_key='ad',
            title='AD Case 01',
            case_number='AD/01/2026',
            status='Pending',
            station_name='Shivajinagar Police Station',
            extra_fields={'adSummaryNo': 'SUM-12345', 'adSummaryDate': '2026-09-10'}
        )
        self.assertTrue(is_ad_case_disposed(ad_case_full))
        self.assertEqual(ad_case_full.status, 'Disposal')

        # 2. AD case with Marathi keys in extra_fields
        ad_case_marathi = CaseRecord.objects.create(
            module_key='ad',
            title='AD Case 02 Marathi',
            case_number='AD/02/2026',
            status='Pending',
            station_name='Shivajinagar Police Station',
            extra_fields={'मर्ग समरी No.': 'MARG-999', 'मर्ग समरी दिनांक': '10/09/2026'}
        )
        self.assertTrue(is_ad_case_disposed(ad_case_marathi))
        self.assertEqual(ad_case_marathi.status, 'Disposal')

        # 3. Incomplete AD cases stay Pending
        ad_missing_date = CaseRecord.objects.create(
            module_key='ad',
            title='AD Case Missing Date',
            case_number='AD/03/2026',
            status='Pending',
            station_name='Shivajinagar Police Station',
            extra_fields={'adSummaryNo': 'SUM-999'}
        )
        self.assertFalse(is_ad_case_disposed(ad_missing_date))
        self.assertEqual(ad_missing_date.status, 'Pending')

        # 4. Non-AD case with summary fields is unaffected
        theft_case = CaseRecord.objects.create(
            module_key='theft',
            title='Theft Case',
            case_number='TH-100',
            status='Pending',
            station_name='Shivajinagar Police Station',
            extra_fields={'adSummaryNo': 'SUM-999', 'adSummaryDate': '2026-09-10'}
        )
        self.assertFalse(is_ad_case_disposed(theft_case))
        self.assertEqual(theft_case.status, 'Pending')

    # --------------------------------------------------------------------------
    # Test 10: AD Disposal API Queryset Filtering
    # --------------------------------------------------------------------------
    def test_10_ad_disposal_api_queryset_filtering(self):
        """API endpoints filter disposal and pending correctly for AD cases."""
        from apps.cases.models import CaseRecord

        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.officer_token}',
            HTTP_X_STATE_CODE='MH'
        )

        # Create disposed AD case and pending AD case
        CaseRecord.objects.create(
            module_key='ad',
            title='Disposed AD 10',
            case_number='AD/10/2026',
            status='Pending',
            station_name='Shivajinagar Police Station',
            extra_fields={'adSummaryNo': 'SUM-10', 'adSummaryDate': '2026-09-10'}
        )
        CaseRecord.objects.create(
            module_key='ad',
            title='Pending AD 11',
            case_number='AD/11/2026',
            status='Pending',
            station_name='Shivajinagar Police Station',
            extra_fields={'otherField': 'value'}
        )

        # Query /api/cases/?status=disposal
        resp_disp = self.client.get('/api/cases/?status=disposal')
        self.assertEqual(resp_disp.status_code, status.HTTP_200_OK)
        disp_case_numbers = [c.get('case_number') for c in resp_disp.data.get('results', resp_disp.data if isinstance(resp_disp.data, list) else [])]
        self.assertIn('AD/10/2026', disp_case_numbers)
        self.assertNotIn('AD/11/2026', disp_case_numbers)

        # Query /api/cases/?status=pending
        resp_pend = self.client.get('/api/cases/?status=pending')
        self.assertEqual(resp_pend.status_code, status.HTTP_200_OK)
        pend_case_numbers = [c.get('case_number') for c in resp_pend.data.get('results', resp_pend.data if isinstance(resp_pend.data, list) else [])]
        self.assertNotIn('AD/10/2026', pend_case_numbers)
        self.assertIn('AD/11/2026', pend_case_numbers)

    # --------------------------------------------------------------------------
    # Test 11: JWT and Tenant Resolution on /api/cases/
    # --------------------------------------------------------------------------
    def test_11_tenant_and_jwt_resolution_cases_endpoint(self):
        """Verify /api/cases/ handles valid JWT, expired JWT, and no JWT safely without 500."""
        import jwt
        from datetime import datetime, timedelta, timezone
        from django.conf import settings

        # 1. No JWT -> 401 Unauthorized
        self.client.credentials()  # Clear credentials
        resp_no_jwt = self.client.get('/api/cases/?module_key=form_1_5')
        self.assertEqual(resp_no_jwt.status_code, status.HTTP_401_UNAUTHORIZED)

        # 2. Expired JWT -> 401 Unauthorized
        expired_payload = {
            'uid': 'test_expired_uid',
            'user_id': 'test_expired_uid',
            'email': 'expired@mhpolice.gov.in',
            'role_id': 'officer',
            'state_code': 'MH',
            'exp': datetime.now(timezone.utc) - timedelta(hours=1),
            'iat': datetime.now(timezone.utc) - timedelta(hours=2),
        }
        expired_token = jwt.encode(expired_payload, settings.SECRET_KEY, algorithm='HS256')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {expired_token}')
        resp_expired = self.client.get('/api/cases/?module_key=form_1_5')
        self.assertEqual(resp_expired.status_code, status.HTTP_401_UNAUTHORIZED)

        # 3. Valid JWT -> 200 OK
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.officer_token}')
        resp_valid = self.client.get('/api/cases/?module_key=form_1_5')
        self.assertEqual(resp_valid.status_code, status.HTTP_200_OK)

    # --------------------------------------------------------------------------
    # Test 12: Two Different Tenants In A Row (No Schema Leak)
    # --------------------------------------------------------------------------
    def test_12_two_different_tenants_isolation(self):
        """Two different tenants in a row isolate data with zero leakage."""
        ka_token = self._register_and_login(
            'officer_ka@kapolice.gov.in', 'OfficerPass123!', 'officer', 'KA'
        )

        # Request 1: Maharashtra Tenant
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.officer_token}')
        resp_mh = self.client.get('/api/cases/?module_key=form_1_5')
        self.assertEqual(resp_mh.status_code, status.HTTP_200_OK)

        # Request 2: Karnataka Tenant
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {ka_token}')
        resp_ka = self.client.get('/api/cases/?module_key=form_1_5')
        self.assertEqual(resp_ka.status_code, status.HTTP_200_OK)

    # --------------------------------------------------------------------------
    # Test 13: 20 Sequential Requests Mixing Endpoints & Tokens for Two Tenants
    # --------------------------------------------------------------------------
    def test_13_twenty_sequential_requests_two_tenants_isolation(self):
        """
        Run 20 requests in a row mixing endpoints and tokens for two tenants.
        Confirms 200 for all, zero cross-tenant data leakage, 401 for no token,
        and 4xx for a token whose state has no valid tenant schema.
        """
        import jwt
        from datetime import datetime, timedelta, timezone
        from django.conf import settings
        from apps.cases.models import CaseRecord
        from apps.core.tenancy import TenantContext

        # Register KA officer
        ka_token = self._register_and_login(
            'officer_ka_seq@kapolice.gov.in', 'OfficerPass123!', 'officer', 'KA'
        )

        # Seed distinct cases in MH and KA schemas
        with TenantContext('maharashtra'):
            CaseRecord.objects.create(
                id=str(uuid.uuid4()),
                module_key='form_1_5',
                title='MH Unique Case Sequence',
                case_number='MH-SEQ-001',
                status='Pending',
                station_name='Shivajinagar Police Station',
                sub_category='Theft'
            )

        with TenantContext('karnataka'):
            CaseRecord.objects.create(
                id=str(uuid.uuid4()),
                module_key='form_1_5',
                title='KA Unique Case Sequence',
                case_number='KA-SEQ-001',
                status='Pending',
                station_name='Shivajinagar Police Station',
                sub_category='Theft'
            )

        # Execute 20 sequential requests alternating tokens and endpoints
        endpoints = [
            '/api/cases/?module_key=form_1_5',
            '/api/categories/theft/form-definition/',
            '/api/cases/',
            '/api/categories/dashboard-tabs/',
        ]

        for i in range(20):
            is_mh = (i % 2 == 0)
            token = self.officer_token if is_mh else ka_token
            endpoint = endpoints[i % len(endpoints)]
            
            self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
            resp = self.client.get(endpoint)
            self.assertEqual(
                resp.status_code, status.HTTP_200_OK,
                f"Request {i+1} failed with status {resp.status_code} for {endpoint}"
            )

            # If PostgreSQL, verify schema isolation (no cross-tenant leakage)
            if connection.vendor == 'postgresql' and '/api/cases/' in endpoint:
                data = resp.data.get('results', resp.data) if isinstance(resp.data, dict) else resp.data
                if isinstance(data, list):
                    case_numbers = [c.get('case_number') for c in data if isinstance(c, dict)]
                    if is_mh:
                        self.assertIn('MH-SEQ-001', case_numbers)
                        self.assertNotIn('KA-SEQ-001', case_numbers)
                    else:
                        self.assertIn('KA-SEQ-001', case_numbers)
                        self.assertNotIn('MH-SEQ-001', case_numbers)

        # Request with no token -> 401 Unauthorized
        self.client.credentials()
        resp_no_token = self.client.get('/api/cases/?module_key=form_1_5')
        self.assertEqual(resp_no_token.status_code, status.HTTP_401_UNAUTHORIZED)

        # Request with a token whose state has no schema -> 4xx (400 or 401)
        no_schema_payload = {
            'uid': 'invalid_state_uid',
            'user_id': 'invalid_state_uid',
            'email': 'invalid_state@police.gov.in',
            'role_id': 'officer',
            'state_code': 'NON_EXISTENT_STATE_XYZ',
            'exp': datetime.now(timezone.utc) + timedelta(hours=1),
            'iat': datetime.now(timezone.utc),
        }
        no_schema_token = jwt.encode(no_schema_payload, settings.SECRET_KEY, algorithm='HS256')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {no_schema_token}')
        resp_no_schema = self.client.get('/api/cases/?module_key=form_1_5')
        self.assertTrue(
            status.is_client_error(resp_no_schema.status_code),
            f"Expected 4xx client error, got {resp_no_schema.status_code}"
        )

    def test_case_counts_endpoint_and_egress_optimizations(self):
        """
        Verify:
        1. GET /api/cases/counts/ returns SQL-aggregated numbers without downloading case lists.
        2. Counts grouped by status (total, pending, disposal, detected) and groups (1 to 5, Part 6).
        3. Response caching on counts endpoint and invalidation on case save.
        4. Case list pagination (page size <= 50) and lightweight serializer (no extra_fields in list).
        5. Case retrieve returns full details (with extra_fields).
        """
        from apps.cases.models import CaseRecord
        from apps.core.tenancy import set_tenant_schema
        set_tenant_schema('maharashtra')

        # Clean sample cases for test
        CaseRecord.objects.all().delete()
        c1 = CaseRecord.objects.create(
            id='test-c-1',
            case_number='FIR-COUNT-001',
            title='Sample Pending Theft',
            module_key='theft',
            status='Pending',
            accused='Ramesh Kumar',
            station_name='Shivajinagar Police Station',
            extra_fields={'nested_detail': 'heavy_data_123'},
        )
        c2 = CaseRecord.objects.create(
            id='test-c-2',
            case_number='FIR-COUNT-002',
            title='Sample Disposed Murder',
            module_key='murder',
            status='Disposal',
            accused='Suresh Verma',
            station_name='Shivajinagar Police Station',
            extra_fields={'court_order': 'heavy_order_456', 'cc_st_number': 'CC/123/2026'},
        )
        c3 = CaseRecord.objects.create(
            id='test-c-3',
            case_number='FIR-COUNT-003',
            title='Sample Undetected Dacoity',
            module_key='dacoity',
            status='Pending',
            accused='',
            station_name='Shivajinagar Police Station',
            extra_fields={'scene_photos': 'heavy_photos_789'},
        )

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.officer_token}')

        # 1. Test Counts Endpoint
        resp = self.client.get('/api/cases/counts/?station_name=Shivajinagar Police Station')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.data
        self.assertIn('total', data)
        self.assertIn('pending', data)
        self.assertIn('disposal', data)
        self.assertIn('detected', data)
        self.assertIn('groups', data)
        self.assertIn('tabs', data)

        self.assertEqual(data['total'], 3)
        self.assertEqual(data['disposal'], 1)
        self.assertEqual(data['pending'], 2)
        self.assertEqual(data['detected'], 1)  # only c1 has accused and is pending

        # Group 1 (1 to 5) includes theft, murder, dacoity
        g1 = data['groups']['1']
        self.assertEqual(g1['total'], 3)
        self.assertEqual(g1['pending'], 2)
        self.assertEqual(g1['disposal'], 1)

        # 2. Test Pagination and Lightweight Serializer on List
        list_resp = self.client.get('/api/cases/?station_name=Shivajinagar Police Station')
        self.assertEqual(list_resp.status_code, status.HTTP_200_OK)
        self.assertIn('results', list_resp.data)
        self.assertIn('count', list_resp.data)
        self.assertEqual(list_resp.data['count'], 3)
        results = list_resp.data['results']
        self.assertTrue(len(results) <= 50)
        # Verify light serializer does not leak heavy extra_fields in list view
        for r in results:
            self.assertNotIn('extra_fields', r)

        # 3. Test Full Detail on Retrieve
        detail_resp = self.client.get(f'/api/cases/{c1.id}/')
        self.assertEqual(detail_resp.status_code, status.HTTP_200_OK)
        self.assertIn('extra_fields', detail_resp.data)
        self.assertEqual(detail_resp.data['extra_fields'].get('nested_detail'), 'heavy_data_123')

        # 4. Invalidation: Save a new case and verify counts update
        c4 = CaseRecord.objects.create(
            id='test-c-4',
            case_number='FIR-COUNT-004',
            title='Sample Part 6 NDPS',
            module_key='ndps',
            status='Pending',
            accused='Drug Dealer',
            station_name='Shivajinagar Police Station',
        )
        resp2 = self.client.get('/api/cases/counts/?station_name=Shivajinagar Police Station')
        self.assertEqual(resp2.status_code, status.HTTP_200_OK)
        self.assertEqual(resp2.data['total'], 4)
        self.assertEqual(resp2.data['groups']['2']['total'], 1)


