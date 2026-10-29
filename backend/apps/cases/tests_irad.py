import json
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model

from apps.cases.models import CaseRecord
from apps.cases.irad_service import (
    RoadAccidentIradService,
    STATUS_PENDING,
    STATUS_FILLED,
    COLOR_PENDING,
    COLOR_FILLED,
)
from apps.public_master.models import Role, Permission, RolePermission
from apps.users.models import NotificationRecord
from apps.core.models import AuditLog

User = get_user_model()


class RoadAccidentIradTests(TestCase):
    def setUp(self):
        # 1. Setup User and Permissions
        self.user = User.objects.create_user(
            username='irad_officer',
            password='password123',
            email='irad_officer@example.com'
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

        # Case 1: Road Accident - IRAD Filled ("Yes")
        self.case_filled = CaseRecord.objects.create(
            case_number='CR/2026/IRAD-01',
            title='Fatal Highway Accident',
            sub_category='Death Due to Rash Driving',
            module_key='form_1_5',
            station_name='TUMSAR',
            assigned_officer='PI Ramesh Patil',
            assigned_officer_uid='io_uid_001',
            extra_fields={
                'acc_irad': 'Yes',
                'acc_irad_date': '2026-10-15',
                'section_act': 'Sec 279, 304A IPC & Sec 134 M.V. Act',
            }
        )

        # Case 2: Road Accident - IRAD Pending ("No")
        self.case_pending_no = CaseRecord.objects.create(
            case_number='CR/2026/IRAD-02',
            title='City Intersection Collision',
            sub_category='Normal Accident',
            module_key='accident',
            station_name='TUMSAR',
            assigned_officer='PSI Suresh Shinde',
            assigned_officer_uid='io_uid_002',
            extra_fields={
                'acc_irad': 'No',
                'acts_sections': [{'act': 'M.V. Act', 'section': '184'}],
            }
        )

        # Case 3: Road Accident - IRAD Unset / Blank -> Evaluates to Pending
        self.case_pending_unset = CaseRecord.objects.create(
            case_number='CR/2026/IRAD-03',
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

        # Case 4: Non-Accident Case (Murder) -> Must NOT appear in IRAD tab
        self.case_non_accident = CaseRecord.objects.create(
            case_number='CR/2026/MURDER-01',
            title='Homicide Case',
            sub_category='Murder',
            module_key='form_1_5',
            station_name='TUMSAR',
            assigned_officer='PI Ramesh Patil',
            extra_fields={'motive': 'Property dispute'}
        )

        # Case 5: Different Station Case (isolation check)
        self.case_other_station = CaseRecord.objects.create(
            case_number='CR/2026/IRAD-OTHER',
            title='Accident in Nagpur',
            sub_category='Road Accident',
            module_key='accident',
            station_name='NAGPUR_CITY',
            assigned_officer='PI Vikas Roy',
            extra_fields={'acc_irad': 'Yes'}
        )

    def test_road_accident_query_and_case_filtering(self):
        """Verifies only road accident cases belonging to officer's station are fetched."""
        service = RoadAccidentIradService(station_name='TUMSAR')
        qs = service.get_base_queryset()

        case_numbers = list(qs.values_list('case_number', flat=True))
        self.assertIn('CR/2026/IRAD-01', case_numbers)
        self.assertIn('CR/2026/IRAD-02', case_numbers)
        self.assertIn('CR/2026/IRAD-03', case_numbers)

        # Non-accident and other station cases must be excluded
        self.assertNotIn('CR/2026/MURDER-01', case_numbers)
        self.assertNotIn('CR/2026/IRAD-OTHER', case_numbers)

    def test_irad_status_evaluation_filled(self):
        """Rule 2: If all required IRAD fields are marked 'Yes', IRAD is Filled/Completed (Green)."""
        eval_result = RoadAccidentIradService.evaluate_case_irad(self.case_filled)
        self.assertEqual(eval_result['status'], STATUS_FILLED)
        self.assertTrue(eval_result['is_filled'])
        self.assertEqual(eval_result['status_color'], COLOR_FILLED)
        self.assertFalse(eval_result['can_remind'])

    def test_irad_status_evaluation_pending_with_no(self):
        """Rule 3 & 4: If any required IRAD field is marked 'No', IRAD is Pending (Red)."""
        eval_result = RoadAccidentIradService.evaluate_case_irad(self.case_pending_no)
        self.assertEqual(eval_result['status'], STATUS_PENDING)
        self.assertFalse(eval_result['is_filled'])
        self.assertEqual(eval_result['status_color'], COLOR_PENDING)
        self.assertTrue(eval_result['can_remind'])

    def test_irad_status_evaluation_pending_with_blank(self):
        """Rule: If IRAD fields are blank or null, IRAD is Pending (Red)."""
        eval_result = RoadAccidentIradService.evaluate_case_irad(self.case_pending_unset)
        self.assertEqual(eval_result['status'], STATUS_PENDING)
        self.assertFalse(eval_result['is_filled'])
        self.assertEqual(eval_result['status_color'], COLOR_PENDING)
        self.assertTrue(eval_result['can_remind'])

    def test_irad_summary_statistics_calculation(self):
        """Rule 5: Calculate Total IRAD, IRAD Form Filled, and IRAD Form Pending dynamically."""
        service = RoadAccidentIradService(station_name='TUMSAR')
        stats = service.get_summary_statistics()

        self.assertEqual(stats['total_irad'], 3)
        self.assertEqual(stats['irad_form_filled'], 1)
        self.assertEqual(stats['irad_form_pending'], 2)

    def test_irad_cases_list_api(self):
        """Rule 1-5: GET /api/cases/irad/ returns summary metrics and serialized cases with correct columns."""
        url = reverse('irad-cases-list')
        response = self.client.get(url, {'station_name': 'TUMSAR'})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()

        # Check Summary
        self.assertEqual(data['total_irad'], 3)
        self.assertEqual(data['irad_form_filled'], 1)
        self.assertEqual(data['irad_form_pending'], 2)

        # Check Cases Table Results
        results = data['results']
        self.assertEqual(len(results), 3)

        # Verify Table Columns exist for each row:
        # Sr. No., CR No., Act and Section, IO Name, Status, Action Button / Remind to IO (can_remind)
        first_row = next(r for r in results if r['cr_no'] == 'CR/2026/IRAD-01')
        self.assertEqual(first_row['status'], STATUS_FILLED)
        self.assertEqual(first_row['status_color'], COLOR_FILLED)
        self.assertEqual(first_row['io_name'], 'PI Ramesh Patil')
        self.assertFalse(first_row['can_remind'])
        self.assertIn('Sec 279', first_row['act_and_section'])

        second_row = next(r for r in results if r['cr_no'] == 'CR/2026/IRAD-02')
        self.assertEqual(second_row['status'], STATUS_PENDING)
        self.assertEqual(second_row['status_color'], COLOR_PENDING)
        self.assertEqual(second_row['io_name'], 'PSI Suresh Shinde')
        self.assertTrue(second_row['can_remind'])

    def test_irad_filter_by_status_api(self):
        """Verifies filtering by status=pending or status=filled via query params."""
        url = reverse('irad-cases-list')

        # Filter: Pending only
        res_pending = self.client.get(url, {'station_name': 'TUMSAR', 'status': 'pending'})
        self.assertEqual(res_pending.status_code, status.HTTP_200_OK)
        rows_pending = res_pending.json()['results']
        self.assertEqual(len(rows_pending), 2)
        for r in rows_pending:
            self.assertEqual(r['status'], STATUS_PENDING)

        # Filter: Filled only
        res_filled = self.client.get(url, {'station_name': 'TUMSAR', 'status': 'filled'})
        self.assertEqual(res_filled.status_code, status.HTTP_200_OK)
        rows_filled = res_filled.json()['results']
        self.assertEqual(len(rows_filled), 1)
        self.assertEqual(rows_filled[0]['cr_no'], 'CR/2026/IRAD-01')
        self.assertEqual(rows_filled[0]['status'], STATUS_FILLED)

    def test_irad_summary_stats_api(self):
        """Verifies lightweight stats endpoint GET /api/cases/irad/stats/."""
        url = reverse('irad-summary-stats')
        response = self.client.get(url, {'station_name': 'TUMSAR'})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['total_irad'], 3)
        self.assertEqual(data['irad_form_filled'], 1)
        self.assertEqual(data['irad_form_pending'], 2)

    def test_irad_remind_io_action_success(self):
        """Rule 6: Action/Remind to IO button allows reminders to be sent to assigned IO."""
        url = reverse('irad-remind-io', kwargs={'pk': str(self.case_pending_no.pk)})
        response = self.client.post(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['status'], 'success')
        self.assertIn('PSI Suresh Shinde', data['message'])

        # Verify NotificationRecord created in database
        notification = NotificationRecord.objects.filter(
            registration_uid=str(self.case_pending_no.case_number)
        ).first()
        self.assertIsNotNone(notification)
        self.assertEqual(notification.category, 'reminder')
        self.assertEqual(notification.target_station_name, 'TUMSAR')
        self.assertIn('IRAD Form Pending', notification.title)

        # Verify AuditLog created
        audit = AuditLog.objects.filter(
            event='irad_reminder_sent',
            metadata__case_id=str(self.case_pending_no.pk)
        ).first()
        self.assertIsNotNone(audit)
        self.assertIn('PSI Suresh Shinde', audit.action_details)

    def test_irad_remind_io_non_existent_case(self):
        """Verifies 404 response when reminding for a non-existent case."""
        import uuid
        url = reverse('irad-remind-io', kwargs={'pk': str(uuid.uuid4())})
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_irad_station_security_denied(self):
        """Verifies an officer without district/state permission cannot view other stations' data."""
        url = reverse('irad-cases-list')
        response = self.client.get(url, {'station_name': 'NAGPUR_CITY'})
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
