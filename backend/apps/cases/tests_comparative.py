from datetime import datetime, timezone
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model

from apps.cases.models import CaseRecord
from apps.cases.comparative_service import (
    MonthlyCrimeComparativeService,
    get_comparative_date_ranges,
    format_inc_dec,
    classify_case_record,
)
from apps.public_master.models import Role, Permission, RolePermission

User = get_user_model()


class MonthlyCrimeComparativeTests(TestCase):
    def setUp(self):
        # 1. Setup User and Permissions
        self.user = User.objects.create_user(
            username='officer_comp',
            password='password123',
            email='comp@example.com'
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

        # 2. Seed Dynamic Test Cases Across Different Windows for 2026-10
        # Target month: 2026-10
        # CM: 2026-10-01 to 2026-10-31
        # PM: 2026-09-01 to 2026-09-30
        # SMLY: 2025-10-01 to 2025-10-31
        # CY_YTD: 2026-01-01 to 2026-10-31
        # PY_YTD: 2025-01-01 to 2025-10-31

        # Current Month (Oct 2026)
        # Murder - Detected (REP=1, DET=1)
        CaseRecord.objects.create(
            case_number='CR/2026/01',
            title='Murder Case Oct 2026',
            module_key='form_1_5',
            sub_category='Murder',
            status='Detected',
            incident_date=datetime(2026, 10, 5, 10, 0, tzinfo=timezone.utc),
            station_name='TUMSAR'
        )
        # Attempt to Murder - Pending (REP=1, DET=0)
        CaseRecord.objects.create(
            case_number='CR/2026/02',
            title='Attempt Murder Case Oct 2026',
            module_key='form_1_5',
            sub_category='Attempt to Murder',
            status='Pending',
            incident_date=datetime(2026, 10, 8, 12, 0, tzinfo=timezone.utc),
            station_name='TUMSAR'
        )
        # POCSO (SLL) - Disposal (REP=1, DET=1)
        CaseRecord.objects.create(
            case_number='CR/2026/03',
            title='POCSO Oct 2026',
            module_key='pocso',
            sub_category='POCSO',
            accused='Ramesh Accused',
            status='Disposal',
            incident_date=datetime(2026, 10, 10, 14, 0, tzinfo=timezone.utc),
            station_name='TUMSAR'
        )

        # Previous Month (Sep 2026)
        # Murder - Detected (PM REP=1, DET=1)
        CaseRecord.objects.create(
            case_number='CR/2026/04',
            title='Murder Sep 2026',
            module_key='form_1_5',
            sub_category='Murder',
            status='Detected',
            incident_date=datetime(2026, 9, 15, 11, 0, tzinfo=timezone.utc),
            station_name='TUMSAR'
        )

        # Same Month Previous Year (Oct 2025)
        # Murder - Detected (SMLY REP=1, DET=1)
        CaseRecord.objects.create(
            case_number='CR/2025/01',
            title='Murder Oct 2025',
            module_key='form_1_5',
            sub_category='Murder',
            status='Detected',
            incident_date=datetime(2025, 10, 12, 9, 0, tzinfo=timezone.utc),
            station_name='TUMSAR'
        )
        # Theft - Detected (SMLY REP=1, DET=1)
        CaseRecord.objects.create(
            case_number='CR/2025/02',
            title='Theft Oct 2025',
            module_key='theft',
            sub_category='Theft',
            status='Detected',
            incident_date=datetime(2025, 10, 20, 15, 0, tzinfo=timezone.utc),
            station_name='TUMSAR'
        )

        # Earlier in Current Year (March 2026 - CY_YTD)
        CaseRecord.objects.create(
            case_number='CR/2026/05',
            title='Murder March 2026',
            module_key='form_1_5',
            sub_category='Murder',
            status='Detected',
            incident_date=datetime(2026, 3, 10, 8, 0, tzinfo=timezone.utc),
            station_name='TUMSAR'
        )

        # Earlier in Previous Year (Feb 2025 - PY_YTD)
        CaseRecord.objects.create(
            case_number='CR/2025/03',
            title='Theft Feb 2025',
            module_key='theft',
            sub_category='Theft',
            status='Detected',
            incident_date=datetime(2025, 2, 14, 16, 0, tzinfo=timezone.utc),
            station_name='TUMSAR'
        )

    def test_format_inc_dec_rules(self):
        """Verifies police report INC/DEC formatting rules (+N, -N, =)."""
        self.assertEqual(format_inc_dec(5, 3), {'value': 2, 'text': '+2'})
        self.assertEqual(format_inc_dec(1, 4), {'value': -3, 'text': '-3'})
        self.assertEqual(format_inc_dec(10, 10), {'value': 0, 'text': '='})

    def test_date_range_calculations(self):
        """Verifies 5 reporting window calculation and boundary dates."""
        windows = get_comparative_date_ranges(year=2026, month=10)
        self.assertEqual(windows['current_month']['label'], 'OCTOBER 2026')
        self.assertEqual(windows['previous_month']['label'], 'SEPTEMBER 2026')
        self.assertEqual(windows['same_month_previous_year']['label'], 'OCTOBER 2025')
        self.assertEqual(windows['current_year_ytd']['label'], '01/01/2026 to 31/10/2026')
        self.assertEqual(windows['previous_year_ytd']['label'], '01/01/2025 to 31/10/2025')

        # Test year rollover: January 2026 -> Previous month is December 2025
        jan_windows = get_comparative_date_ranges(year=2026, month=1)
        self.assertEqual(jan_windows['current_month']['label'], 'JANUARY 2026')
        self.assertEqual(jan_windows['previous_month']['label'], 'DECEMBER 2025')
        self.assertEqual(jan_windows['previous_month']['year'], 2025)
        self.assertEqual(jan_windows['previous_month']['month'], 12)

    def test_service_aggregation_and_inc_dec(self):
        """Verifies calculations of REP/DET, INC/DEC, and totals."""
        service = MonthlyCrimeComparativeService(station_name='TUMSAR')
        data = service.get_comparative_statement(year=2026, month=10)

        # 1. Metadata checks
        self.assertEqual(data['metadata']['report_title'], 'STATEMENT SHOWING IPC & SLL CRIMES COMPARITIVE')
        self.assertEqual(data['metadata']['month'], 10)
        self.assertEqual(data['metadata']['year'], 2026)

        # 2. Crime Heads verification
        ipc_by_head = {r['head']: r for r in data['ipc_crimes']}
        sll_by_head = {r['head']: r for r in data['sll_crimes']}

        # Murder Row Checks:
        # CM REP=1, DET=1
        # PM REP=1, DET=1
        # SMLY REP=1, DET=1
        # Monthly INC/DEC: 1 - 1 = 0 -> '='
        # CY_YTD: Oct (1) + Sep (1) + March (1) = 3 (DET=3)
        # PY_YTD: Oct 2025 (1) = 1 (DET=1)
        # YTD INC/DEC: 3 - 1 = +2
        murder = ipc_by_head['MURDER']
        self.assertEqual(murder['current_month']['rep'], 1)
        self.assertEqual(murder['current_month']['det'], 1)
        self.assertEqual(murder['previous_month']['rep'], 1)
        self.assertEqual(murder['previous_month']['det'], 1)
        self.assertEqual(murder['same_month_previous_year']['rep'], 1)
        self.assertEqual(murder['same_month_previous_year']['det'], 1)
        self.assertEqual(murder['monthly_inc_dec']['text'], '=')
        self.assertEqual(murder['current_year_ytd']['rep'], 3)
        self.assertEqual(murder['current_year_ytd']['det'], 3)
        self.assertEqual(murder['previous_year_ytd']['rep'], 1)
        self.assertEqual(murder['previous_year_ytd']['det'], 1)
        self.assertEqual(murder['ytd_inc_dec']['text'], '+2')

        # Attempt to Murder Row Checks:
        # CM REP=1, DET=0
        # SMLY REP=0
        # Monthly INC/DEC: 1 - 0 = +1
        att_murder = ipc_by_head['ATTEMPT TO MURDER']
        self.assertEqual(att_murder['current_month']['rep'], 1)
        self.assertEqual(att_murder['current_month']['det'], 0)
        self.assertEqual(att_murder['monthly_inc_dec']['text'], '+1')

        # Theft Row Checks:
        # CM REP=0, DET=0
        # SMLY REP=1, DET=1
        # Monthly INC/DEC: 0 - 1 = -1
        # CY_YTD REP=0, PY_YTD (Feb 2025 + Oct 2025) = 2
        # YTD INC/DEC: 0 - 2 = -2
        thefts = ipc_by_head['THEFTS']
        self.assertEqual(thefts['current_month']['rep'], 0)
        self.assertEqual(thefts['same_month_previous_year']['rep'], 1)
        self.assertEqual(thefts['monthly_inc_dec']['text'], '-1')
        self.assertEqual(thefts['current_year_ytd']['rep'], 0)
        self.assertEqual(thefts['previous_year_ytd']['rep'], 2)
        self.assertEqual(thefts['ytd_inc_dec']['text'], '-2')

        # POCSO Row (SLL) Checks:
        # CM REP=1, DET=1
        pocso = sll_by_head['POCSO']
        self.assertEqual(pocso['current_month']['rep'], 1)
        self.assertEqual(pocso['current_month']['det'], 1)

        # Totals verification:
        total_ipc = data['total_ipc']
        # CM IPC: Murder(1) + Attempt(1) = 2 REP, 1 DET
        self.assertEqual(total_ipc['current_month']['rep'], 2)
        self.assertEqual(total_ipc['current_month']['det'], 1)
        # SMLY IPC: Murder(1) + Theft(1) = 2 REP, 2 DET
        self.assertEqual(total_ipc['same_month_previous_year']['rep'], 2)
        self.assertEqual(total_ipc['same_month_previous_year']['det'], 2)
        # Monthly INC/DEC IPC: 2 - 2 = 0 ('=')
        self.assertEqual(total_ipc['monthly_inc_dec']['text'], '=')

        total_sll = data['total_sll']
        # CM SLL: POCSO(1)
        self.assertEqual(total_sll['current_month']['rep'], 1)
        self.assertEqual(total_sll['current_month']['det'], 1)

        grand_total = data['grand_total']
        # Grand Total CM: 2 (IPC) + 1 (SLL) = 3 REP, 2 DET
        self.assertEqual(grand_total['current_month']['rep'], 3)
        self.assertEqual(grand_total['current_month']['det'], 2)

    def test_api_endpoint_authorization(self):
        """Ensures endpoint requires authentication and case:view permission."""
        url = reverse('monthly-crime-comparative')

        # 1. Unauthenticated request
        anon_client = APIClient()
        resp_anon = anon_client.get(url)
        self.assertIn(resp_anon.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

        # 2. User without permission
        user_no_perm = User.objects.create_user(username='no_perm', password='pwd')
        client_no_perm = APIClient()
        client_no_perm.force_authenticate(user=user_no_perm)
        resp_no_perm = client_no_perm.get(url)
        self.assertEqual(resp_no_perm.status_code, status.HTTP_403_FORBIDDEN)

        # 3. Authenticated authorized request
        resp_auth = self.client.get(url + '?year=2026&month=10')
        self.assertEqual(resp_auth.status_code, status.HTTP_200_OK)
        body = resp_auth.json()
        self.assertIn('metadata', body)
        self.assertIn('ipc_crimes', body)
        self.assertIn('total_ipc', body)
        self.assertIn('sll_crimes', body)
        self.assertIn('total_sll', body)
        self.assertIn('grand_total', body)
        self.assertIn('all_rows', body)

    def test_api_endpoint_alternate_urls(self):
        """Verifies alternative convenience URLs defined in crimetab."""
        url_crimetab = reverse('monthly-crime-comparative-crimetab')
        resp = self.client.get(url_crimetab + '?year=2026&month=10')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

        url_nested = reverse('monthly-comparative-nested')
        resp_nested = self.client.get(url_nested + '?year=2026&month=10')
        self.assertEqual(resp_nested.status_code, status.HTTP_200_OK)
