from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.urls import reverse
from apps.cases.models import CaseRecord
from django.contrib.auth import get_user_model
from apps.public_master.models import Role, Permission, RolePermission

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

    def test_itsso_cases_api(self):
        url = reverse('itsso-cases')
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.json()
        results = data.get('results', data)
        case_numbers = [item['case_number'] for item in results]

        self.assertIn('CR-101', case_numbers)
        self.assertIn('CR-102', case_numbers)
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
