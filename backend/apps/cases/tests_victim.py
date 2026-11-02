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

    def test_extract_case_victims_and_filter_matching(self):
        """Test extraction of victims across commonForm, persons, and extra_fields."""
        from apps.cases.views import extract_case_victims, case_matches_victim_filter

        # Case with multiple nested victims in commonForm
        multi_victim_case = CaseRecord.objects.create(
            title='Multi Victim Case',
            module_key='crime_women',
            status='Pending',
            extra_fields={
                'commonForm': {
                    'victims': [
                        {'gender': 'Female', 'age': '24', 'pwd': False, 'condition': 'Injured'},
                        {'gender': 'Male', 'age': '4', 'pwd': True, 'mentally_vulnerable': True, 'condition': 'Normal'},
                        {'gender': 'Female', 'age': '65', 'pwd': False, 'condition': 'Deceased'}
                    ]
                }
            }
        )
        victims = extract_case_victims(multi_victim_case)
        self.assertEqual(len(victims), 3)

        # Verify filters match correctly
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'female'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'male'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'minor'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'below_5'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'senior'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'above_60'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'pwd'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'mentally_vulnerable'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'injured'))
        self.assertTrue(case_matches_victim_filter(multi_victim_case, 'deceased'))

    def test_missing_and_traced_victim_filters(self):
        """Test tracing status classification for missing/kidnapping cases."""
        from apps.cases.views import extract_case_victims, case_matches_victim_filter

        # Pending missing case
        missing_case = CaseRecord.objects.create(
            title='Missing Boy',
            module_key='missing',
            status='Pending',
            extra_fields={'victim_gender': 'Male', 'victim_age': 12}
        )
        v_missing = extract_case_victims(missing_case)
        self.assertTrue(v_missing[0]['is_missing'])
        self.assertFalse(v_missing[0]['is_traced'])
        self.assertTrue(v_missing[0]['is_pending_tracing'])
        self.assertTrue(case_matches_victim_filter(missing_case, 'missing'))
        self.assertTrue(case_matches_victim_filter(missing_case, 'pending_tracing'))
        self.assertFalse(case_matches_victim_filter(missing_case, 'traced'))

        # Traced missing case
        traced_case = CaseRecord.objects.create(
            title='Traced Girl',
            module_key='kidnapping',
            status='Detected',
            extra_fields={'victim_gender': 'Female', 'victim_age': 16}
        )
        v_traced = extract_case_victims(traced_case)
        self.assertTrue(v_traced[0]['is_missing'])
        self.assertTrue(v_traced[0]['is_traced'])
        self.assertFalse(v_traced[0]['is_pending_tracing'])
        self.assertTrue(case_matches_victim_filter(traced_case, 'missing'))
        self.assertTrue(case_matches_victim_filter(traced_case, 'traced'))
        self.assertFalse(case_matches_victim_filter(traced_case, 'pending_tracing'))

    def test_victim_time_and_io_wise_filtered_views(self):
        """Test that time-wise and IO-wise views accept victim_filter parameter."""
        # Query with female filter
        time_res = self.client.get(reverse('victim-time-wise'), {'victim_filter': 'female'})
        self.assertEqual(time_res.status_code, status.HTTP_200_OK)

        io_res = self.client.get(reverse('victim-io-wise'), {'victim_filter': 'minor'})
        self.assertEqual(io_res.status_code, status.HTTP_200_OK)

