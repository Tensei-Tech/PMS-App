from datetime import datetime, timezone
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model

from apps.cases.models import CaseRecord
from apps.cases.warrant_service import (
    SummonsWarrantReportService,
    classify_warrant_record,
    get_warrant_execution_status,
    WARRANT_TYPE_SUMMONS,
    WARRANT_TYPE_BW,
    WARRANT_TYPE_NBW,
)
from apps.public_master.models import Role, Permission, RolePermission, StateRegistry

User = get_user_model()


class SummonsWarrantReportTests(TestCase):
    def setUp(self):
        # 1. Setup User and Permissions
        self.state, _ = StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        self.user = User.objects.create_user(
            username='warrant_officer',
            password='password123',
            email='warrant@example.com'
        )
        self.role, _ = Role.objects.get_or_create(
            id='warrant_test_role',
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
        self.user.state_code = 'MH'
        self.user.save()

        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

        # 2. Seed Dynamic Test Cases for 2026-09
        # CM: 2026-09-01 to 2026-09-30
        # PM: before 2026-09-01

        # Section 1: Summons (समंस)
        # Previous Month: 30 cases
        for i in range(30):
            CaseRecord.objects.create(
                case_number=f'SAM/PM/{i}',
                title=f'Summons PM {i}',
                module_key='sam_warrant',
                sub_category='Summons',
                station_name='TUMSAR',
                incident_date=datetime(2026, 8, 15, 10, 0, 0, tzinfo=timezone.utc),
                extra_fields={'warrant_type': 'summons', 'execution_status': 'pending'}
            )
        # Current Month: 70 cases
        # 60 executed (तामील)
        for i in range(60):
            CaseRecord.objects.create(
                case_number=f'SAM/CM/EXEC/{i}',
                title=f'Summons CM Executed {i}',
                module_key='sam_warrant',
                sub_category='Summons',
                station_name='TUMSAR',
                incident_date=datetime(2026, 9, 10, 10, 0, 0, tzinfo=timezone.utc),
                extra_fields={'warrant_type': 'summons', 'execution_status': 'executed'}
            )
        # 5 unserved (अदम)
        for i in range(5):
            CaseRecord.objects.create(
                case_number=f'SAM/CM/UNS/{i}',
                title=f'Summons CM Unserved {i}',
                module_key='sam_warrant',
                sub_category='Summons',
                station_name='TUMSAR',
                incident_date=datetime(2026, 9, 12, 10, 0, 0, tzinfo=timezone.utc),
                extra_fields={'warrant_type': 'summons', 'execution_status': 'unserved'}
            )
        # 5 pending
        for i in range(5):
            CaseRecord.objects.create(
                case_number=f'SAM/CM/PEND/{i}',
                title=f'Summons CM Pending {i}',
                module_key='sam_warrant',
                sub_category='Summons',
                station_name='TUMSAR',
                incident_date=datetime(2026, 9, 15, 10, 0, 0, tzinfo=timezone.utc),
                extra_fields={'warrant_type': 'summons', 'execution_status': 'pending'}
            )

        # Section 2: NBW / Non-Bailable Warrant (पकड वारंट)
        # PM: 0, CM: 9, Executed: 8, Unserved: 1, Pending: 0
        for i in range(8):
            CaseRecord.objects.create(
                case_number=f'NBW/CM/EXEC/{i}',
                title=f'NBW CM Executed {i}',
                module_key='sam_warrant',
                sub_category='पकड वारंट',
                station_name='TUMSAR',
                incident_date=datetime(2026, 9, 5, 10, 0, 0, tzinfo=timezone.utc),
                extra_fields={'warrant_type': 'nbw', 'execution_status': 'executed'}
            )
        CaseRecord.objects.create(
            case_number='NBW/CM/UNS/0',
            title='NBW CM Unserved 0',
            module_key='sam_warrant',
            sub_category='पकड वारंट',
            station_name='TUMSAR',
            incident_date=datetime(2026, 9, 6, 10, 0, 0, tzinfo=timezone.utc),
            extra_fields={'warrant_type': 'nbw', 'execution_status': 'unserved'}
        )

        # Section 3: BW / Bailable Warrant (जमानती वारंट)
        # PM: 0, CM: 25, Executed: 25, Unserved: 0, Pending: 0
        for i in range(25):
            CaseRecord.objects.create(
                case_number=f'BW/CM/EXEC/{i}',
                title=f'BW CM Executed {i}',
                module_key='sam_warrant',
                sub_category='जमानती वारंट',
                station_name='TUMSAR',
                incident_date=datetime(2026, 9, 18, 10, 0, 0, tzinfo=timezone.utc),
                extra_fields={'warrant_type': 'bw', 'execution_status': 'executed'}
            )

    def test_classification_logic(self):
        sam_rec = CaseRecord(module_key='sam_warrant', sub_category='Summons')
        self.assertEqual(classify_warrant_record(sam_rec), WARRANT_TYPE_SUMMONS)

        nbw_rec = CaseRecord(module_key='sam_warrant', sub_category='पकड वारंट')
        self.assertEqual(classify_warrant_record(nbw_rec), WARRANT_TYPE_NBW)

        bw_rec = CaseRecord(module_key='sam_warrant', sub_category='जमानती वारंट')
        self.assertEqual(classify_warrant_record(bw_rec), WARRANT_TYPE_BW)

        nbw_rec2 = CaseRecord(extra_fields={'warrant_type': 'non-bailable warrant'})
        self.assertEqual(classify_warrant_record(nbw_rec2), WARRANT_TYPE_NBW)

    def test_execution_status_logic(self):
        rec_exec = CaseRecord(extra_fields={'execution_status': 'served'})
        self.assertEqual(get_warrant_execution_status(rec_exec), 'executed')

        rec_uns = CaseRecord(extra_fields={'execution_status': 'अदम'})
        self.assertEqual(get_warrant_execution_status(rec_uns), 'unserved')

        rec_pend = CaseRecord(extra_fields={'execution_status': 'pending'})
        self.assertEqual(get_warrant_execution_status(rec_pend), 'pending')

    def test_report_service_calculation(self):
        service = SummonsWarrantReportService(station_name='TUMSAR')
        report = service.get_report(year=2026, month=9)

        sections = {s['key']: s for s in report['sections']}

        # Summons checks:
        # Previous Month: 30
        # Current Month: 70
        # Total: 100
        # Executed: 60
        # Executed %: 60%
        # Unserved: 5
        # Pending: 35 (100 - 60 - 5)
        summons_summary = sections['summons']['summary']
        self.assertEqual(summons_summary['previous_month'], 30)
        self.assertEqual(summons_summary['current_month'], 70)
        self.assertEqual(summons_summary['total'], 100)
        self.assertEqual(summons_summary['executed'], 60)
        self.assertEqual(summons_summary['executed_percent'], '60%')
        self.assertEqual(summons_summary['unserved'], 5)
        self.assertEqual(summons_summary['pending'], 35)

        # NBW checks:
        # Previous Month: 0
        # Current Month: 9
        # Total: 9
        # Executed: 8
        # Executed %: 88.9%
        # Unserved: 1
        # Pending: 0
        nbw_summary = sections['nbw']['summary']
        self.assertEqual(nbw_summary['previous_month'], 0)
        self.assertEqual(nbw_summary['current_month'], 9)
        self.assertEqual(nbw_summary['total'], 9)
        self.assertEqual(nbw_summary['executed'], 8)
        self.assertEqual(nbw_summary['executed_percent'], '88.9%')
        self.assertEqual(nbw_summary['unserved'], 1)
        self.assertEqual(nbw_summary['pending'], 0)

        # BW checks:
        # Previous Month: 0
        # Current Month: 25
        # Total: 25
        # Executed: 25
        # Executed %: 100%
        # Unserved: 0
        # Pending: 0
        bw_summary = sections['bw']['summary']
        self.assertEqual(bw_summary['previous_month'], 0)
        self.assertEqual(bw_summary['current_month'], 25)
        self.assertEqual(bw_summary['total'], 25)
        self.assertEqual(bw_summary['executed'], 25)
        self.assertEqual(bw_summary['executed_percent'], '100%')
        self.assertEqual(bw_summary['unserved'], 0)
        self.assertEqual(bw_summary['pending'], 0)

    def test_api_endpoint(self):
        url = reverse('summons-warrant-report')
        resp = self.client.get(f"{url}?year=2026&month=9", HTTP_X_STATE_CODE='MH')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

        data = resp.data
        self.assertIn('sections', data)
        self.assertEqual(len(data['sections']), 3)
        self.assertIn('grand_total', data)
        self.assertIn('metadata', data)
        self.assertEqual(data['metadata']['year'], 2026)
        self.assertEqual(data['metadata']['month'], 9)

        # Alias route test
        alias_url = reverse('sam-warrant-report')
        alias_resp = self.client.get(f"{alias_url}?year=2026&month=9", HTTP_X_STATE_CODE='MH')
        self.assertEqual(alias_resp.status_code, status.HTTP_200_OK)
