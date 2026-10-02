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
        self.original_perms_case = DisposalCaseWiseView.permission_classes
        self.original_perms_time = TimeWiseDisposalView.permission_classes
        self.original_perms_desig = DesignationWiseDisposalView.permission_classes
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

    def tearDown(self):
        from apps.cases.views import DisposalCaseWiseView, TimeWiseDisposalView, DesignationWiseDisposalView
        DisposalCaseWiseView.permission_classes = self.original_perms_case
        TimeWiseDisposalView.permission_classes = self.original_perms_time
        DesignationWiseDisposalView.permission_classes = self.original_perms_desig

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
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['count'], 15)
        
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

class ADCaseDisposalTests(APITestCase):
    def test_ad_rule(self):
        from apps.cases.utils import get_cases_by_status
        from django.utils import timezone
        
        # 1. AD case with 7 fields is disposed
        c1 = CaseRecord.objects.create(module_key='ad', extra_fields={'ccStNumber': 'AD-CC'})
        self.assertTrue(get_cases_by_status('disposal').filter(id=c1.id).exists())
        
        # 2. AD case with AD Summary No AND Date is disposed
        c2 = CaseRecord.objects.create(module_key='ad', extra_fields={'adSummaryNo': 'AD-123', 'adSummaryDate': '2023-01-01'})
        self.assertTrue(get_cases_by_status('disposal').filter(id=c2.id).exists())
        
        # 3. AD case with ONLY AD Summary No is pending
        c3 = CaseRecord.objects.create(module_key='ad', extra_fields={'adSummaryNo': 'AD-456'})
        self.assertTrue(get_cases_by_status('pending').filter(id=c3.id).exists())
        
        # 4. AD case with ONLY AD Summary Date is pending
        c4 = CaseRecord.objects.create(module_key='ad', extra_fields={'adSummaryDate': '2023-01-01'})
        self.assertTrue(get_cases_by_status('pending').filter(id=c4.id).exists())
        
        # 5. Non-AD case with AD Summary No and Date is pending (if no 7 fields)
        c5 = CaseRecord.objects.create(module_key='theft', extra_fields={'adSummaryNo': 'AD-123', 'adSummaryDate': '2023-01-01'})
        self.assertTrue(get_cases_by_status('pending').filter(id=c5.id).exists())
        
        # 6. AD case identified by sub_category
        c6 = CaseRecord.objects.create(module_key='missing', sub_category='accidental death', extra_fields={'adSummaryNo': 'AD-99', 'adSummaryDate': '2023-01-01'})
        self.assertTrue(get_cases_by_status('disposal').filter(id=c6.id).exists())

        # Verify save() sets disposal_date for AD rule cases
        c2.refresh_from_db()
        self.assertTrue(bool(c2.extra_fields.get('disposal_date')))
        
    def test_ad_sql_vs_python(self):
        from apps.cases.utils import get_cases_by_status
        # Compare Python is_ad_case_disposed vs SQL rule for random combinations
        cases = [
            CaseRecord.objects.create(module_key='ad', extra_fields={'adSummaryNo': 'A', 'adSummaryDate': 'D'}),
            CaseRecord.objects.create(module_key='ad', extra_fields={'adSummaryNo': 'A'}),
            CaseRecord.objects.create(module_key='missing', sub_category='ad', extra_fields={'adSummaryNo': 'A', 'adSummaryDate': 'D'}),
            CaseRecord.objects.create(module_key='theft', extra_fields={'adSummaryNo': 'A', 'adSummaryDate': 'D', 'ccStNumber': '1'}),
        ]
        
        from apps.cases.models import is_ad_case_disposed
        sql_disposed_ids = set(get_cases_by_status('disposal').values_list('id', flat=True))
        
        for c in cases:
            c.refresh_from_db() # Get updated status
            python_result = is_ad_case_disposed(c) or any(bool(str(c.extra_fields.get(k, '')).strip()) for k in ['ccStNumber'])
            sql_result = c.id in sql_disposed_ids
            self.assertEqual(python_result, sql_result)
        
    def test_inverse(self):
        from apps.cases.utils import get_cases_by_status
        # Ensure pending + disposal = total, and no intersection
        CaseRecord.objects.create(module_key='ad', extra_fields={'adSummaryNo': 'A', 'adSummaryDate': 'D'})
        CaseRecord.objects.create(module_key='ad', extra_fields={'adSummaryNo': 'A'})
        
        all_ids = set(CaseRecord.objects.values_list('id', flat=True))
        disp_ids = set(get_cases_by_status('disposal').values_list('id', flat=True))
        pend_ids = set(get_cases_by_status('pending').values_list('id', flat=True))
        
        self.assertEqual(disp_ids.intersection(pend_ids), set())
        self.assertEqual(disp_ids.union(pend_ids), all_ids)

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
        res2 = client.get('/api/cases/disposal/case-wise/?page=2&page_size=20')
        
        ids1 = [item['id'] for item in res1.data['results']]
        ids2 = [item['id'] for item in res2.data['results']]
        
        self.assertEqual(len(ids1), 20)
        self.assertEqual(len(ids2), 5)
        # Ensure no overlap
        self.assertEqual(set(ids1).intersection(set(ids2)), set())
