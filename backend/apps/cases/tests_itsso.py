from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.urls import reverse
from apps.cases.models import CaseRecord
from django.contrib.auth import get_user_model
from apps.public_master.models import Role, Permission, RolePermission
from apps.cases.serializers import ItssoCaseRecordSerializer
from apps.cases.itsso_service import ItssoService, is_itsso_case
from unittest.mock import MagicMock

User = get_user_model()

class ItssoCasesTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='itsso_admin',
            password='password123',
            email='admin@example.com'
        )
        self.role, _ = Role.objects.get_or_create(id='officer', defaults={'name': 'Police Officer', 'level': 'station'})
        self.perm_view, _ = Permission.objects.get_or_create(id='case:view', defaults={'module': 'cases'})
        RolePermission.objects.get_or_create(role=self.role, permission=self.perm_view, defaults={'is_granted': True})
        self.user.role = self.role
        self.user.station_name = 'Central Station'
        self.user.save()

        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

        # 1 POCSO case pending (no charge sheet)
        self.pocso_pending = CaseRecord.objects.create(
            case_number='CR-101',
            module_key='pocso',
            status='Pending',
            assigned_officer='Officer A',
            assigned_officer_uid='io-1',
            station_name='Central Station',
            extra_fields={}
        )

        # 1 POCSO case with chargesheet
        self.pocso_chargesheeted = CaseRecord.objects.create(
            case_number='CR-102',
            module_key='pocso',
            status='Disposal',
            assigned_officer='Officer B',
            assigned_officer_uid='io-2',
            station_name='Central Station',
            extra_fields={'charge_sheet_number': 'CS-2024-99', 'charge_sheet_date': '2024-05-10'}
        )

        # 1 Non-POCSO case (should NOT appear)
        self.theft_case = CaseRecord.objects.create(
            case_number='CR-103',
            module_key='theft',
            status='Pending',
            assigned_officer='Officer A',
            station_name='Central Station',
            extra_fields={}
        )

        # BNS Section 64 Case (Crime Against Women / Any module)
        self.bns_64_case = CaseRecord.objects.create(
            case_number='CR-201',
            module_key='crime_women',
            sub_category='Rape',
            status='Pending',
            assigned_officer='Officer C',
            station_name='Central Station',
            extra_fields={'section_act': 'Section 64 BNS'}
        )

        # BNS Section 65 Case
        self.bns_65_case = CaseRecord.objects.create(
            case_number='CR-202',
            module_key='general_crime',
            sub_category='Sexual Offences',
            status='Pending',
            assigned_officer='Officer D',
            station_name='Central Station',
            extra_fields={'acts_sections': [{'act': 'Bharatiya Nyaya Sanhita, 2023', 'section': '65'}]}
        )

        # BNS Section 70(2) Case
        self.bns_70_2_case = CaseRecord.objects.create(
            case_number='CR-203',
            module_key='crime_women',
            sub_category='Gang Rape',
            status='Disposal',
            assigned_officer='Officer E',
            station_name='Central Station',
            extra_fields={'section_act': 'section 70(2) BNS', 'charge_sheet_number': 'CS-702', 'charge_sheet_date': '2024-06-01'}
        )

        # BNS Section 62 Case
        self.bns_62_case = CaseRecord.objects.create(
            case_number='CR-204',
            module_key='other_crime',
            status='Pending',
            assigned_officer='Officer F',
            station_name='Central Station',
            extra_fields={'section_act': 'SECTION 62 BNS'}
        )

    def test_itsso_cases_api(self):
        url = reverse('itsso-cases')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.json()
        results = data.get('results', data)
        case_numbers = [item['case_number'] for item in results]

        self.assertIn('CR-101', case_numbers)
        self.assertIn('CR-102', case_numbers)
        self.assertIn('CR-201', case_numbers)
        self.assertIn('CR-202', case_numbers)
        self.assertIn('CR-203', case_numbers)
        self.assertIn('CR-204', case_numbers)
        self.assertNotIn('CR-103', case_numbers)

    def test_itsso_time_wise_api(self):
        url = reverse('itsso-time-wise')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.json()
        self.assertTrue(len(data) > 0)
        periods = [item['period'] for item in data]
        self.assertIn('Under 1 month', periods)

    def test_itsso_io_wise_api(self):
        url = reverse('itsso-io-wise')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.json()
        self.assertTrue(len(data) > 0)
        io_names = [item['io_name'] for item in data]
        self.assertIn('Officer A', io_names)

    def test_itsso_action_api(self):
        url = reverse('itsso-action', kwargs={'pk': self.pocso_pending.pk})
        res = self.client.post(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.json().get('status'), 'success')

    def test_itsso_serializer_with_nullable_act_and_section(self):
        """Test that ItssoCaseRecordSerializer handles null act or section without raising AttributeError."""
        case = CaseRecord(
            case_number='CR-NULLABLE',
            module_key='crime_women',
            status='Pending',
            extra_fields={}
        )

        mock_charge_1 = MagicMock()
        mock_charge_1.act = None
        mock_charge_1.section = MagicMock(section_number='64')
        mock_charge_1.subsection = None

        mock_charge_2 = MagicMock()
        mock_charge_2.act = MagicMock(act_name='Bharatiya Nyaya Sanhita, 2023')
        mock_charge_2.section = None
        mock_charge_2.subsection = None

        mock_charge_3 = MagicMock()
        mock_charge_3.act = MagicMock(act_name='BNS')
        mock_charge_3.section = MagicMock(section_number='70')
        mock_charge_3.subsection = MagicMock(subsection_code='(2)')

        mock_charges_mgr = MagicMock()
        mock_charges_mgr.select_related.return_value.all.return_value = [
            mock_charge_1,
            mock_charge_2,
            mock_charge_3,
        ]

        case.charges = mock_charges_mgr
        serializer = ItssoCaseRecordSerializer(case)
        section_act = serializer.data.get('section_act')

        self.assertIn('Sec. 64', section_act)
        self.assertIn('BNS', section_act)
        self.assertIn('BNS Sec. 70(2)', section_act)

    def test_itsso_rejection_of_non_bns_section_64(self):
        """Ensure section 64 belonging to non-BNS acts (e.g. Customs Act, Bombay Police Act) is not falsely classified as ITSSO."""
        non_bns_case = CaseRecord.objects.create(
            case_number='CR-NON-BNS-64',
            module_key='customs',
            status='Pending',
            station_name='Central Station',
            extra_fields={'section': '64', 'act': 'Customs Act'}
        )
        self.assertFalse(is_itsso_case(non_bns_case))

        # Check that it is not in the queryset
        qs = ItssoService.get_itsso_cases_queryset()
        self.assertNotIn(non_bns_case, qs)

    def test_itsso_station_filtering(self):
        """Test station_name filter query parameter on itsso-cases."""
        other_st_case = CaseRecord.objects.create(
            case_number='CR-OTHER-ST',
            module_key='pocso',
            status='Pending',
            station_name='North Station',
            extra_fields={}
        )
        url = reverse('itsso-cases')
        res = self.client.get(url, {'station_name': 'Central Station'})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.json().get('results', res.json())
        case_nums = [item['case_number'] for item in results]
        self.assertIn('CR-101', case_nums)
        self.assertNotIn('CR-OTHER-ST', case_nums)
