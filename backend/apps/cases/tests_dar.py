import json
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model

from apps.cases.models import CaseRecord
from apps.cases.dar_service import (
    RoadAccidentDarService,
    STATUS_PENDING,
    STATUS_FILLED,
    COLOR_PENDING,
    COLOR_FILLED,
)
from apps.public_master.models import Role, Permission, RolePermission
from apps.users.models import NotificationRecord
from apps.core.models import AuditLog

User = get_user_model()


class RoadAccidentDarTests(TestCase):
    def setUp(self):
        # 1. Setup User and Permissions
        self.user = User.objects.create_user(
            username='dar_officer',
            password='password123',
            email='dar_officer@example.com'
        )
        self.role, _ = Role.objects.get_or_create(
            id='officer_role',
            defaults={'name': 'Police Officer', 'level': 'station'}
        )
        self.perm_view, _ = Permission.objects.get_or_create(
            id='case:view',
            defaults={'module': 'cases'}
        )
        RolePermission.objects.get_or_create(
            role=self.role,
            permission=self.perm_view,
            defaults={'is_granted': True}
        )
        self.user.role = self.role
        self.user.station_name = 'TUMSAR'
        self.user.save()

        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

        # 2. Seed Dynamic Test Cases

        # Case 1: Road Accident - DAR Filled ("Yes")
        self.case_filled = CaseRecord.objects.create(
            case_number='CR/2026/ACC-01',
            title='Fatal Highway Accident',
            sub_category='Death Due to Rash Driving',
            module_key='form_1_5',
            station_name='TUMSAR',
            assigned_officer='PI Ramesh Patil',
            assigned_officer_uid='io_uid_001',
            extra_fields={
                'acc_dar': 'Yes',
                'acc_dar_date': '2026-10-15',
                'section_act': 'Sec 279, 304A IPC & Sec 134 M.V. Act',
            }
        )

        # Case 2: Road Accident - DAR Pending ("No")
        self.case_pending_no = CaseRecord.objects.create(
            case_number='CR/2026/ACC-02',
            title='City Intersection Collision',
            sub_category='Normal Accident',
            module_key='accident',
            station_name='TUMSAR',
            assigned_officer='PSI Suresh Shinde',
            assigned_officer_uid='io_uid_002',
            extra_fields={
                'acc_dar': 'No',
                'acts_sections': [{'act': 'M.V. Act', 'section': '184'}],
            }
        )

        # Case 3: Road Accident - DAR Unset / Blank -> Evaluates to Pending
        self.case_pending_unset = CaseRecord.objects.create(
            case_number='CR/2026/ACC-03',
            title='Overturning Vehicle',
            sub_category='Road Accident',
            module_key='form_1_5',
            station_name='TUMSAR',
            assigned_officer='API Anita Deshmukh',
            assigned_officer_uid='io_uid_003',
            extra_fields={
                'accident_spot': 'National Highway 53',
                'section_act': 'Sec 279 IPC',
            }
        )

        # Case 4: Non-Accident Case (Murder) -> Must NOT appear in DAR tab
        self.case_non_accident = CaseRecord.objects.create(
            case_number='CR/2026/MUR-99',
            title='Robbery with Murder',
            sub_category='Murder',
            module_key='form_1_5',
            station_name='TUMSAR',
            assigned_officer='PI Ramesh Patil',
            assigned_officer_uid='io_uid_001',
            extra_fields={'motive': 'Property dispute'}
        )

        # Case 5: Road Accident at another station (BHANDARA) -> Multi-tenancy isolation
        self.case_other_station = CaseRecord.objects.create(
            case_number='CR/2026/ACC-BHD',
            title='Bhandara Ring Road Accident',
            sub_category='Normal Accident',
            module_key='accident',
            station_name='BHANDARA',
            assigned_officer='PI Vikas Kale',
            assigned_officer_uid='io_uid_004',
            extra_fields={'acc_dar': 'Yes'}
        )

    def test_01_road_accident_case_discovery(self):
        """Verifies that only Road Accident cases are retrieved, filtering out other crime types."""
        service = RoadAccidentDarService(station_name='TUMSAR')
        qs = service.get_base_queryset()

        case_numbers = list(qs.values_list('case_number', flat=True))
        self.assertIn('CR/2026/ACC-01', case_numbers)
        self.assertIn('CR/2026/ACC-02', case_numbers)
        self.assertIn('CR/2026/ACC-03', case_numbers)
        # Non-accident case must NOT be included
        self.assertNotIn('CR/2026/MUR-99', case_numbers)
        # Other station case must NOT be included when filtered by station TUMSAR
        self.assertNotIn('CR/2026/ACC-BHD', case_numbers)

    def test_02_dar_status_evaluation_filled(self):
        """Verifies that when DAR fields are marked 'Yes', status is 'Filled' and color is Green."""
        eval_result = RoadAccidentDarService.evaluate_case_dar(self.case_filled)
        self.assertEqual(eval_result['status'], STATUS_FILLED)
        self.assertEqual(eval_result['status_color'], COLOR_FILLED)
        self.assertEqual(eval_result['dar_date'], '2026-10-15')
        self.assertFalse(eval_result['can_remind'])

    def test_03_dar_status_evaluation_pending_when_marked_no(self):
        """Verifies that when any DAR field is marked 'No', status is 'Pending' and color is Red."""
        eval_result = RoadAccidentDarService.evaluate_case_dar(self.case_pending_no)
        self.assertEqual(eval_result['status'], STATUS_PENDING)
        self.assertEqual(eval_result['status_color'], COLOR_PENDING)
        self.assertTrue(eval_result['can_remind'])

    def test_04_dar_status_evaluation_pending_when_unset(self):
        """Verifies that when DAR fields are empty/unset, status defaults to 'Pending' (Red)."""
        eval_result = RoadAccidentDarService.evaluate_case_dar(self.case_pending_unset)
        self.assertEqual(eval_result['status'], STATUS_PENDING)
        self.assertEqual(eval_result['status_color'], COLOR_PENDING)
        self.assertTrue(eval_result['can_remind'])

    def test_05_summary_statistics_calculation(self):
        """Verifies dynamic calculation of Total DAR, DAR Form Filled, and DAR Form Pending."""
        service = RoadAccidentDarService(station_name='TUMSAR')
        summary = service.get_summary_statistics()

        self.assertEqual(summary['total_dar'], 3)
        self.assertEqual(summary['dar_filled'], 1)
        self.assertEqual(summary['dar_pending'], 2)

    def test_06_dar_cases_list_api_response(self):
        """Verifies GET /api/cases/dar/ endpoint returns summary cards and table columns."""
        response = self.client.get('/api/cases/dar/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.json()
        self.assertIn('summary', data)
        self.assertIn('results', data)

        summary = data['summary']
        self.assertEqual(summary['total_dar'], 3)
        self.assertEqual(summary['dar_filled'], 1)
        self.assertEqual(summary['dar_pending'], 2)

        results = data['results']
        self.assertEqual(len(results), 3)

        # Verify Table Columns for first row
        first_row = results[0]
        self.assertIn('sr_no', first_row)
        self.assertIn('cr_no', first_row)
        self.assertIn('case_number', first_row)
        self.assertIn('act_and_section', first_row)
        self.assertIn('io_name', first_row)
        self.assertIn('status', first_row)
        self.assertIn('status_color', first_row)
        self.assertIn('can_remind', first_row)

    def test_07_dar_filter_by_status_pending(self):
        """Verifies filtering by status=pending returns only pending DAR cases."""
        response = self.client.get('/api/cases/dar/?status=pending')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.json()
        results = data['results']
        self.assertEqual(len(results), 2)
        for row in results:
            self.assertEqual(row['status'], STATUS_PENDING)
            self.assertEqual(row['status_color'], COLOR_PENDING)

    def test_08_dar_filter_by_status_filled(self):
        """Verifies filtering by status=filled returns only filled DAR cases."""
        response = self.client.get('/api/cases/dar/?status=filled')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.json()
        results = data['results']
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['case_number'], 'CR/2026/ACC-01')
        self.assertEqual(results[0]['status'], STATUS_FILLED)
        self.assertEqual(results[0]['status_color'], COLOR_FILLED)

    def test_09_dar_summary_stats_api(self):
        """Verifies GET /api/cases/dar/stats/ returns summary counts."""
        response = self.client.get('/api/cases/dar/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.json()
        self.assertEqual(data['total_dar'], 3)
        self.assertEqual(data['dar_filled'], 1)
        self.assertEqual(data['dar_pending'], 2)

    def test_10_dar_remind_io_action(self):
        """Verifies POST /api/cases/dar/<pk>/remind/ creates NotificationRecord and AuditLog."""
        url = f"/api/cases/dar/{self.case_pending_no.pk}/remind/"
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.json()
        self.assertEqual(data['status'], 'success')
        self.assertEqual(data['case_number'], self.case_pending_no.case_number)

        # Verify NotificationRecord was created in DB
        notif = NotificationRecord.objects.filter(
            registration_uid=self.case_pending_no.case_number
        ).first()
        self.assertIsNotNone(notif)
        self.assertEqual(notif.target_user_uid, 'io_uid_002')
        self.assertEqual(notif.target_station_name, 'TUMSAR')
        self.assertIn('DAR Form Pending', notif.title)

        # Verify AuditLog was recorded
        audit = AuditLog.objects.filter(
            action_details__icontains=self.case_pending_no.case_number
        ).first()
        self.assertIsNotNone(audit)
        self.assertEqual(audit.event, 'dar_reminder_sent')

    def test_11_dar_crimetab_alias_routes(self):
        """Verifies DAR endpoints under direct /api/dar/ routes from crimetab."""
        resp_cases = self.client.get('/api/dar/cases/')
        self.assertEqual(resp_cases.status_code, status.HTTP_200_OK)

        resp_stats = self.client.get('/api/dar/stats/')
        self.assertEqual(resp_stats.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_stats.json()['total_dar'], 3)
