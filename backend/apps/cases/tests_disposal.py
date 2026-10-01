from rest_framework.test import APITestCase
from apps.cases.models import CaseRecord
from apps.cases.utils import get_cases_by_status
from django.urls import reverse

class DisposalInverseLogicTests(APITestCase):
    def setUp(self):
        # Pending cases
        CaseRecord.objects.create(case_number='CR001', extra_fields={}, station_name='Central')
        CaseRecord.objects.create(case_number='CR002', extra_fields={'ccStNumber': None}, station_name='Central')
        CaseRecord.objects.create(case_number='CR003', extra_fields={'charge_sheet_no': ''}, station_name='Central')
        CaseRecord.objects.create(case_number='CR004', extra_fields={'a_final_number': '   '}, station_name='Central')
        CaseRecord.objects.create(case_number='CR005', extra_fields={'stay_by_high_court_date': '2023-01-01', 'quashed_by_high_court_date': '2023-01-02'}, station_name='Central')
        
        # Disposal cases
        CaseRecord.objects.create(case_number='CR006', extra_fields={'ccStNumber': 'CC1234'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR007', extra_fields={'charge_sheet_no': 'CS123'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR008', extra_fields={'a_final_number': 'A1'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR009', extra_fields={'b_final_number': 'B1'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR010', extra_fields={'c_final_number': 'C1'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR011', extra_fields={'nc_final_number': 'NC1'}, station_name='Central')
        CaseRecord.objects.create(case_number='CR012', extra_fields={'abeted_summary_no': 'AS1'}, station_name='Central')
        
        # Multiple keys
        CaseRecord.objects.create(case_number='CR013', extra_fields={'ccStNumber': 'CC1234', 'charge_sheet_no': 'CS123'}, station_name='Central')
        
        # With spaces
        CaseRecord.objects.create(case_number='CR014', extra_fields={'charge_sheet_no': '  CS999  '}, station_name='Central')

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
