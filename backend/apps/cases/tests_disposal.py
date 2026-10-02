from rest_framework.test import APITestCase
from apps.cases.models import CaseRecord
from apps.cases.utils import get_cases_by_status
from django.urls import reverse

class DisposalInverseLogicTests(APITestCase):
    def setUp(self):
        # Pending cases
        CaseRecord.objects.create(case_number='CR001', extra_fields={}, station_name='Central')
        CaseRecord.objects.create(case_number='CR002', extra_fields={'ccStNumber': None}, station_name='Central')
        CaseRecord.objects.create(case_number='CR003', extra_fields={'chargeSheetNumber': ''}, station_name='Central')
        CaseRecord.objects.create(case_number='CR004', extra_fields={'aFinalNo': '   '}, station_name='Central')
        CaseRecord.objects.create(case_number='CR005', extra_fields={'stay_by_high_court_date': '2023-01-01', 'quashed_by_high_court_date': '2023-01-02'}, station_name='Central')
        
        # Disposal cases
        CaseRecord.objects.create(case_number='CR006', extra_fields={'ccStNumber': 'CC1234'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR007', extra_fields={'chargeSheetNumber': 'CS123'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR008', extra_fields={'aFinalNo': 'A1'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR009', extra_fields={'bFinalNo': 'B1'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR010', extra_fields={'cFinalNo': 'C1'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR011', extra_fields={'ncFinalNo': 'NC1'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR012', extra_fields={'abatedSummaryNo': 'AS1'}, station_name='Central')
        
        # Multiple keys
        CaseRecord.objects.create(case_number='CR013', extra_fields={'ccStNumber': 'CC1234', 'chargeSheetNumber': 'CS123'}, station_name='Central')
        
        # With spaces
        CaseRecord.objects.create(case_number='CR014', extra_fields={'chargeSheetNumber': '  CS999  '}, station_name='Central')

    def test_pending_and_disposal_inverses(self):
        total_cases = CaseRecord.objects.count()
        self.assertEqual(total_cases, 14)
        
        pending_qs = get_cases_by_status('pending')
        disposal_qs = get_cases_by_status('disposal')
        
        pending_ids = set(pending_qs.values_list('id', flat=True))
        disposal_ids = set(disposal_qs.values_list('id', flat=True))
        
        self.assertEqual(len(pending_ids) + len(disposal_ids), total_cases)
        self.assertEqual(len(pending_ids.intersection(disposal_ids)), 0)
        self.assertEqual(len(pending_ids), 5)
        self.assertEqual(len(disposal_ids), 9)

from django.contrib.auth import get_user_model
from unittest.mock import patch
User = get_user_model()

class DisposalAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test_officer', password='pw')
        self.user.station_name = 'Central'
        self.user.save()
        
        self.client.force_authenticate(user=self.user)
        
        from apps.cases.views import DisposalCaseWiseView, TimeWiseDisposalView, DesignationWiseDisposalView
        DisposalCaseWiseView.permission_classes = []
        TimeWiseDisposalView.permission_classes = []
        DesignationWiseDisposalView.permission_classes = []

        # Create disposal cases for 'Central' and 'North'
        for i in range(15):
            CaseRecord.objects.create(
                case_number=f'CR_{i}',
                station_name='Central',
                extra_fields={'ccStNumber': f'CC{i}', 'disposal_date': '2023-10-01'},
                assigned_officer='Test IO'
            )
        # Out of scope case
        CaseRecord.objects.create(
            case_number='CR_NORTH',
            station_name='North',
            extra_fields={'ccStNumber': 'CC999', 'disposal_date': '2023-10-01'},
            assigned_officer='Other IO'
        )

    def test_scoping_and_pagination_cap(self):
        url = reverse('disposal-case-wise')
        response = self.client.get(url, {'page_size': 200})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        self.assertEqual(data['count'], 15)
        self.assertEqual(len(data['results']), 15)
        
    def test_time_wise_view(self):
        url = reverse('disposal-time-wise')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data), 6)
        more_than_1_yr = next((item for item in data if item['period'] == 'More than 1 year'), None)
        self.assertIsNotNone(more_than_1_yr)
        self.assertEqual(more_than_1_yr['count'], 15)
        
    def test_designation_wise_view(self):
        url = reverse('disposal-designation-wise')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['disposal_count'], 15)
        self.assertEqual(data[0]['io_uid'], '')

    def test_disposal_date_persistence(self):
        # 1. Create sets the date
        from django.utils import timezone
        import datetime
        from unittest.mock import patch

        with patch('django.utils.timezone.now', return_value=datetime.datetime(2023, 1, 1, tzinfo=datetime.timezone.utc)):
            c1 = CaseRecord.objects.create(case_number='CR_DATE_1', extra_fields={'ccStNumber': '123'}, station_name='Central')
            c1.refresh_from_db()
            self.assertEqual(c1.extra_fields['disposal_date'], '2023-01-01')

        # 2. Later update keeps the same date (freeze time to prove it)
        with patch('django.utils.timezone.now', return_value=datetime.datetime(2025, 5, 5, tzinfo=datetime.timezone.utc)):
            c1.extra_fields['chargeSheetNumber'] = '456'
            c1.save()
            c1.refresh_from_db()
            self.assertEqual(c1.extra_fields['disposal_date'], '2023-01-01') # Unchanged

        # 3. Partial update that omits extra_fields does not lose it
        with patch('django.utils.timezone.now', return_value=datetime.datetime(2026, 6, 6, tzinfo=datetime.timezone.utc)):
            c1.title = 'Updated Title'
            c1.save(update_fields=['title']) # Does not touch extra_fields
            c1.refresh_from_db()
            self.assertEqual(c1.extra_fields['disposal_date'], '2023-01-01')

        # 4. Update that clears the fields keeps the date (but it's Pending now)
        with patch('django.utils.timezone.now', return_value=datetime.datetime(2027, 7, 7, tzinfo=datetime.timezone.utc)):
            c1.extra_fields = {'ccStNumber': '', 'chargeSheetNumber': None}
            c1.save()
            c1.refresh_from_db()
            self.assertEqual(c1.extra_fields['disposal_date'], '2023-01-01') # Still kept!
            
            # Verify it is Pending
            from apps.cases.utils import get_cases_by_status
            self.assertIn(c1, get_cases_by_status('pending'))
            self.assertNotIn(c1, get_cases_by_status('disposal'))

    def test_io_filter_uid(self):
        # Two officers
        c1 = CaseRecord.objects.create(
            case_number='CR_IO_1',
            station_name='Central',
            assigned_officer_uid='io-uid-1',
            extra_fields={'ccStNumber': '111', 'disposal_date': '2023-11-01'}
        )
        c2 = CaseRecord.objects.create(
            case_number='CR_IO_2',
            station_name='Central',
            assigned_officer_uid='io-uid-2',
            extra_fields={'ccStNumber': '222', 'disposal_date': '2023-11-01'}
        )
        
        url = reverse('disposal-case-wise')
        response = self.client.get(url, {'io_uid': 'io-uid-1', 'page_size': 200})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        self.assertEqual(data['count'], 1)
        self.assertEqual(data['results'][0]['case_number'], 'CR_IO_1')



    def test_pagination_stability(self):
        from rest_framework.test import APIClient
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user = User.objects.create(username='testpagi', password='123')
        user.station_name = 'Central'
        user.save()
        client = APIClient()
        client.force_authenticate(user=user)
        
        CaseRecord.objects.all().delete()
        
        # Create 25 cases with identical data
        from datetime import datetime, timezone
        identical_time = datetime(2023, 1, 1, 12, 0, 0, tzinfo=timezone.utc)
        
        for i in range(25):
            c = CaseRecord.objects.create(
                module_key='theft',
                case_number=f'CR_{i}',
                station_name='Central',
                extra_fields={'ccStNumber': f'CC-{i}', 'disposal_date': '2023-01-01'}
            )
            # Force same created_at
            CaseRecord.objects.filter(id=c.id).update(created_at=identical_time)
            
        res1 = client.get('/api/cases/disposal/case-wise/?page=1&page_size=20')
        self.assertEqual(res1.status_code, 200, f"res1 failed: {res1.json()}")
        res2 = client.get('/api/cases/disposal/case-wise/?page=2&page_size=20')
        self.assertEqual(res2.status_code, 200, f"res2 failed: {res2.json()}")
        
        ids1 = [item['id'] for item in res1.data['results']]
        ids2 = [item['id'] for item in res2.data['results']]
        
        self.assertEqual(len(ids1), 20)
        self.assertEqual(len(ids2), 5)
        # Ensure no overlap
        self.assertEqual(set(ids1).intersection(set(ids2)), set())
