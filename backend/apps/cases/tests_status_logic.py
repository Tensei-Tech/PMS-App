from django.test import TestCase
from unittest.mock import patch
from apps.cases.models import CaseRecord
from apps.cases.serializers import CaseRecordSerializer
from apps.users.models import OfficerProfile
from apps.crimetab.models.common_form import FinalVerdict

class StatusLogicTests(TestCase):
    def setUp(self):
        self.user = OfficerProfile.objects.create(
            uid='test-io-123', name='Test IO', station_name='Test Station', email='testio@example.com'
        )

    def test_cc_entered_becomes_disposal(self):
        case = CaseRecord.objects.create(module_key='murder', status='Pending', extra_fields={'pendingReason': 'Waiting'})
        # Create FinalVerdict with cc_st_number
        from apps.crimetab.models.common_form import FinalVerdict
        FinalVerdict.objects.create(case=case, cc_st_number='12345')
        
        from apps.cases.utils import get_cases_by_status
        disposal_qs = get_cases_by_status('disposal')
        pending_qs = get_cases_by_status('pending')
        
        self.assertTrue(disposal_qs.filter(id=case.id).exists())
        self.assertFalse(pending_qs.filter(id=case.id).exists())

    def test_empty_final_verdict_stays_pending(self):
        case = CaseRecord.objects.create(module_key='murder', status='Pending')
        # Create FinalVerdict but all fields empty
        from apps.crimetab.models.common_form import FinalVerdict
        FinalVerdict.objects.create(case=case)
        
        from apps.cases.utils import get_cases_by_status
        disposal_qs = get_cases_by_status('disposal')
        pending_qs = get_cases_by_status('pending')
        
        self.assertFalse(disposal_qs.filter(id=case.id).exists())
        self.assertTrue(pending_qs.filter(id=case.id).exists())

    def test_whitespace_final_verdict_stays_pending(self):
        case = CaseRecord.objects.create(module_key='murder', status='Pending')
        # All whitespace should be ignored by the regex r'\S'
        FinalVerdict.objects.create(
            case=case,
            charge_sheet_no="   ",
            cc_st_number=" \t\n ",
            a_final_number=" "
        )
        
        from apps.cases.utils import get_cases_by_status
        disposal_qs = get_cases_by_status('disposal')
        pending_qs = get_cases_by_status('pending')
        
        self.assertFalse(disposal_qs.filter(id=case.id).exists())
        self.assertTrue(pending_qs.filter(id=case.id).exists())

    def test_detected_case_no_cc_keeps_status(self):
        case = CaseRecord.objects.create(module_key='murder', status='Detected', extra_fields={'pendingReason': 'Ongoing'})
        
        serializer = CaseRecordSerializer(instance=case, data={'title': 'Updated Title'}, partial=True)
        self.assertTrue(serializer.is_valid())
        serializer.save(_current_user_uid=self.user.uid)
        
        case.refresh_from_db()
        self.assertEqual(case.status, 'Detected')

    def test_patch_without_extra_fields_succeeds(self):
        case = CaseRecord.objects.create(module_key='murder', status='Pending', extra_fields={'pendingReason': 'Initial'})
        
        serializer = CaseRecordSerializer(instance=case, data={'description': 'New description'}, partial=True)
        self.assertTrue(serializer.is_valid())
        serializer.save(_current_user_uid=self.user.uid)
        
        case.refresh_from_db()
        self.assertEqual(case.description, 'New description')

    def test_client_sent_status_logs_ignored(self):
        case = CaseRecord.objects.create(module_key='murder', status='Pending', extra_fields={'pendingReason': 'Init'})
        
        serializer = CaseRecordSerializer(instance=case, data={'extra_fields': {'status_logs': [{'action': 'fake'}], 'pendingReason': 'Update'}}, partial=True)
        self.assertTrue(serializer.is_valid())
        serializer.save(_current_user_uid=self.user.uid)
        
        case.refresh_from_db()
        self.assertNotIn('status_logs', case.extra_fields)

    def test_extra_fields_none_does_not_crash(self):
        case = CaseRecord.objects.create(module_key='murder', status='Pending', extra_fields={})
        
        serializer = CaseRecordSerializer(instance=case, data={'extra_fields': None}, partial=True)
        # Validation might fail if None is not allowed by serializer, but logic shouldn't crash.
        # Assuming the serializer handles None by ignoring it or raising ValidationError.
        if serializer.is_valid():
            serializer.save(_current_user_uid=self.user.uid)
        
        case.refresh_from_db()
        self.assertIsNotNone(case.extra_fields)

    def test_ad_cases_unaffected_by_cc_logic(self):
        case = CaseRecord.objects.create(module_key='ad', status='Pending')
        
        # AD cases use the exact same FinalVerdict logic now.
        from apps.crimetab.models.common_form import FinalVerdict
        FinalVerdict.objects.create(case=case, abeted_summary_no='AD-123')
        
        from apps.cases.utils import get_cases_by_status
        disposal_qs = get_cases_by_status('disposal')
        self.assertTrue(disposal_qs.filter(id=case.id).exists())
