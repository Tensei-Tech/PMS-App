from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from apps.cases.models import CaseRecord
from apps.users.models import OfficerProfile
from unittest.mock import patch

class IOWiseTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        
        # User in Station A
        self.user_a = OfficerProfile.objects.create(uid='uid-a', name='Officer A', station_name='Station A', email='a@example.com')
        
        # User in Station B
        self.user_b = OfficerProfile.objects.create(uid='uid-b', name='Officer B', station_name='Station B', email='b@example.com')
        
        # Case in Station A assigned to Officer A
        CaseRecord.objects.create(module_key='murder', status='Pending', station_name='Station A', assigned_officer_uid='uid-a')
        
        # Case in Station B assigned to Officer B
        CaseRecord.objects.create(module_key='theft', status='Pending', station_name='Station B', assigned_officer_uid='uid-b')

    @patch('apps.cases.views.check_dynamic_permission')
    def test_station_a_user_sees_only_station_a_counts(self, mock_perm):
        mock_perm.return_value = False  # Deny global/district view, force station-level logic
        
        # Give user permission via mock
        with patch('apps.core.permissions.HasPermission.__call__') as mock_has_perm:
            # Bypass permission class checking for the test
            self.client.force_authenticate(user=self.user_a)
            url = reverse('pending-io-wise')
            
            # Since mocking DRF permission factory is tricky, we can just 
            # mock the has_permission of whatever class it returns.
            # But wait, it's easier to just mock the whole permission_classes on the view.
            with patch('apps.cases.views.IOWisePendingView.permission_classes', []):
                res = self.client.get(url)
        
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['station_name'], 'Station A')
        self.assertEqual(data[0]['io_uid'], 'uid-a')
