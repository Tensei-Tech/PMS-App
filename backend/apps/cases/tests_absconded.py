import uuid
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.public_master.models import Role, Permission, RolePermission, StateRegistry
from apps.users.models import OfficerProfile
from apps.cases.models import CaseRecord
from apps.cases.utils import get_absconded_cases, get_cases_by_status


class AbscondedLogicTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Seed roles & permissions
        self.role, _ = Role.objects.get_or_create(id='officer', defaults={'name': 'Police Officer', 'level': 'station'})
        self.perm_view, _ = Permission.objects.get_or_create(id='case:view', defaults={'module': 'cases'})
        RolePermission.objects.get_or_create(role=self.role, permission=self.perm_view, defaults={'is_granted': True})

        self.state, _ = StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )

        OfficerProfile.objects.filter(email='io_absconded@mhpolice.gov.in').delete()
        reg_resp = self.client.post('/api/auth/register/', {
            'email': 'io_absconded@mhpolice.gov.in',
            'password': 'OfficerPass123!',
            'full_name': 'IO Absconded Test',
            'role_id': 'officer',
            'state_code': 'MH',
            'badge_number': f'BDG-{uuid.uuid4().hex[:6]}',
            'station_name': 'Crime Branch',
            'account_status': 'active',
        }, format='json')

        login_resp = self.client.post('/api/auth/login/', {
            'email': 'io_absconded@mhpolice.gov.in',
            'password': 'OfficerPass123!',
            'state_code': 'MH'
        }, format='json')
        self.token = login_resp.data['tokens']['access_token']
        self.officer = OfficerProfile.objects.get(email='io_absconded@mhpolice.gov.in')

        # Case 1: Absconded with CC ST Number -> Should be in Disposal AND Absconded
        self.c1 = CaseRecord.objects.create(
            module_key='theft',
            title='Theft with absconded accused chargesheeted',
            case_number='CR-ABS-001',
            accused='Wanted Person A',
            station_name='Crime Branch',
            assigned_officer='IO Absconded Test',
            assigned_officer_uid=self.officer.uid,
            created_by=self.officer.uid,
            extra_fields={
                'ccStNumber': 'CC-101/2026',
                # No arrest date
            }
        )

        # Case 2: Absconded without CC ST Number -> Should be in Pending AND Absconded
        self.c2 = CaseRecord.objects.create(
            module_key='murder',
            title='Murder with absconded accused pending investigation',
            case_number='CR-ABS-002',
            accused='Wanted Person B',
            station_name='Crime Branch',
            assigned_officer='IO Absconded Test',
            assigned_officer_uid=self.officer.uid,
            created_by=self.officer.uid,
            extra_fields={
                # No ccStNumber, no arrest date
            }
        )

        # Case 3: Arrested accused (Arrest date present) -> NOT Absconded
        self.c3 = CaseRecord.objects.create(
            module_key='robbery',
            title='Robbery with arrested accused',
            case_number='CR-ABS-003',
            accused='Arrested Person C',
            station_name='Crime Branch',
            assigned_officer='IO Absconded Test',
            assigned_officer_uid=self.officer.uid,
            created_by=self.officer.uid,
            extra_fields={
                'arrest_date': '2026-05-10',
            }
        )

    def test_absconded_with_cc_in_disposal_and_absconded(self):
        """Case with missing arrest date and CC ST Number must appear under both Disposal and Absconded."""
        absconded_ids = set(str(x) for x in get_absconded_cases().values_list('id', flat=True))
        disposal_ids = set(str(x) for x in get_cases_by_status('disposal').values_list('id', flat=True))
        pending_ids = set(str(x) for x in get_cases_by_status('pending').values_list('id', flat=True))

        # Appears in Absconded
        self.assertIn(str(self.c1.id), absconded_ids)
        # Appears in Disposal
        self.assertIn(str(self.c1.id), disposal_ids)
        # Does NOT appear in Pending
        self.assertNotIn(str(self.c1.id), pending_ids)

    def test_absconded_without_cc_in_pending_and_absconded(self):
        """Case with missing arrest date and no CC ST Number must appear under both Pending and Absconded."""
        absconded_ids = set(str(x) for x in get_absconded_cases().values_list('id', flat=True))
        disposal_ids = set(str(x) for x in get_cases_by_status('disposal').values_list('id', flat=True))
        pending_ids = set(str(x) for x in get_cases_by_status('pending').values_list('id', flat=True))

        # Appears in Absconded
        self.assertIn(str(self.c2.id), absconded_ids)
        # Appears in Pending
        self.assertIn(str(self.c2.id), pending_ids)
        # Does NOT appear in Disposal
        self.assertNotIn(str(self.c2.id), disposal_ids)

    def test_arrested_accused_not_in_absconded(self):
        """Case with an arrested date must NOT appear in Absconded."""
        absconded_ids = set(str(x) for x in get_absconded_cases().values_list('id', flat=True))
        self.assertNotIn(str(self.c3.id), absconded_ids)

    def test_absconded_endpoint_all(self):
        """GET /api/cases/absconded/ returns all absconded cases (both pending and disposal)."""
        resp = self.client.get(
            '/api/cases/absconded/',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        results = resp.data.get('results') if isinstance(resp.data, dict) else resp.data
        case_ids = [str(r['id']) for r in results]
        self.assertIn(str(self.c1.id), case_ids)
        self.assertIn(str(self.c2.id), case_ids)
        self.assertNotIn(str(self.c3.id), case_ids)

    def test_absconded_endpoint_filtered_by_status(self):
        """GET /api/cases/absconded/?status=pending and ?status=disposal."""
        # Pending absconded
        resp_pend = self.client.get(
            '/api/cases/absconded/?status=pending',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        self.assertEqual(resp_pend.status_code, status.HTTP_200_OK)
        results_pend = resp_pend.data.get('results') if isinstance(resp_pend.data, dict) else resp_pend.data
        pend_ids = [str(r['id']) for r in results_pend]
        self.assertIn(str(self.c2.id), pend_ids)
        self.assertNotIn(str(self.c1.id), pend_ids)

        # Disposal absconded
        resp_disp = self.client.get(
            '/api/cases/absconded/?status=disposal',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        self.assertEqual(resp_disp.status_code, status.HTTP_200_OK)
        results_disp = resp_disp.data.get('results') if isinstance(resp_disp.data, dict) else resp_disp.data
        disp_ids = [str(r['id']) for r in results_disp]
        self.assertIn(str(self.c1.id), disp_ids)
        self.assertNotIn(str(self.c2.id), disp_ids)
