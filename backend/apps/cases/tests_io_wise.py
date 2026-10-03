from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from apps.cases.models import CaseRecord
from apps.users.models import OfficerProfile
from unittest.mock import patch

from apps.core.tenancy import TenantContext

class IOWiseTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.client.credentials(HTTP_X_STATE_CODE='MH')
        
        with TenantContext('maharashtra'):
            # User in Station A
            self.user_a, _ = OfficerProfile.objects.get_or_create(uid='uid-a', defaults={'name': 'Officer A', 'station_name': 'Station A', 'email': 'a@example.com'})
            
            # User in Station B
            self.user_b, _ = OfficerProfile.objects.get_or_create(uid='uid-b', defaults={'name': 'Officer B', 'station_name': 'Station B', 'email': 'b@example.com'})
            
            # Case in Station A assigned to Officer A
            CaseRecord.objects.get_or_create(id='case-io-a', defaults={'module_key': 'murder', 'status': 'Pending', 'station_name': 'Station A', 'assigned_officer_uid': 'uid-a', 'assigned_officer': 'Officer A'})
            
            # Case in Station B assigned to Officer B
            CaseRecord.objects.get_or_create(id='case-io-b', defaults={'module_key': 'theft', 'status': 'Pending', 'station_name': 'Station B', 'assigned_officer_uid': 'uid-b', 'assigned_officer': 'Officer B'})

    @patch('apps.cases.views.check_dynamic_permission')
    def test_station_a_user_sees_only_station_a_counts(self, mock_perm):
        def side_effect(user, perm_code):
            if perm_code == 'case:view':
                return True
            return False  # Deny global/district view, force station-level logic
        mock_perm.side_effect = side_effect
        
        # Authenticate the user properly
        self.client.force_authenticate(user=self.user_a)
        url = reverse('pending-io-wise')
        response = self.client.get(url, HTTP_X_STATE_CODE='MH')
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['station_name'], 'Station A')
        self.assertEqual(data[0]['io_uid'], 'Officer A')
