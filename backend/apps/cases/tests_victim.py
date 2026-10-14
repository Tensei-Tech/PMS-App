from unittest.mock import patch
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.urls import reverse
from apps.cases.models import CaseRecord
from apps.cases.utils import get_victim_cases
from django.contrib.auth import get_user_model

User = get_user_model()

class VictimCasesTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='victim_admin',
            password='password123',
            email='admin@example.com'
        )
        
        from apps.public_master.models import Role, Permission, RolePermission
        self.role, _ = Role.objects.get_or_create(id='officer', defaults={'name': 'Police Officer', 'level': 'station'})
        self.perm_view, _ = Permission.objects.get_or_create(id='case:view', defaults={'module': 'cases'})
        RolePermission.objects.get_or_create(role=self.role, permission=self.perm_view, defaults={'is_granted': True})
        
        self.user.role = self.role
        self.user.save()

        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        
        # Valid victim categories
        self.case1 = CaseRecord.objects.create(title='Case 1', module_key='pocso', status='Pending')
        self.case2 = CaseRecord.objects.create(title='Case 2', module_key='missing', status='Detected')
        self.case3 = CaseRecord.objects.create(title='Case 3', module_key='cheating', status='Disposal')
        
        # Invalid categories (should not be in victim list)
        self.case4 = CaseRecord.objects.create(title='Case 4', module_key='theft', status='Pending')
        self.case5 = CaseRecord.objects.create(title='Case 5', module_key='murder', status='Disposal')

    def test_get_victim_cases_utility(self):
        """Utility should only return cases in the victim target modules."""
        qs = get_victim_cases()
        ids = [str(id) for id in list(qs.values_list('id', flat=True))]
        
        self.assertIn(str(self.case1.id), ids)
        self.assertIn(str(self.case2.id), ids)
        self.assertIn(str(self.case3.id), ids)
        self.assertNotIn(str(self.case4.id), ids)
        self.assertNotIn(str(self.case5.id), ids)

    def test_victim_case_wise_api(self):
        """Victim Case Wise API should return only the valid cases."""
        url = reverse('victim-case-wise')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Verify pagination or list structure
        data = response.json()
        results = data.get('results', data)
        
        ids = [item['id'] for item in results]
        self.assertIn(str(self.case1.id), ids)
        self.assertNotIn(str(self.case4.id), ids)

    def test_victim_stats_api(self):
        """Victim Stats API should return structured counts."""
        url = reverse('victim-stats')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertIn('stats', data)
        self.assertIn('total_cases', data)
        self.assertEqual(data['total_cases'], 3)
        self.assertIn('gender', data['stats'])
        self.assertIn('age', data['stats'])
