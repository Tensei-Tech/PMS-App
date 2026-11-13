"""Shared rules of the fetching tabs: crime cases only, one meaning of "accused known"."""
from django.test import TestCase

from apps.cases import utils as U
from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.common_form import ArrestReleaseStatus, CaseForensics, CasesPerson


class FetchingRulesTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _case(self, cid, **kw):
        defaults = {'case_number': f'CR/{cid}', 'station_name': 'TEST', 'module_key': 'form_1_5',
                    'status': 'Pending', 'extra_fields': {}}
        defaults.update(kw)
        return CaseRecord.objects.create(id=cid, **defaults)

    def _ids(self, qs):
        return set(qs.values_list('id', flat=True))

    def test_service_records_are_not_pending_or_detected(self):
        crime = self._case('C1')
        warrant = self._case('W1', module_key='sam_warrant', status='Detected')
        passport = self._case('P1', module_key='passport')
        self.assertEqual(self._ids(U.get_cases_by_status('pending')) & {'C1', 'P1', 'W1'}, {'C1'})
        self.assertNotIn(warrant.id, self._ids(U.get_cases_by_status('detected')))
        self.assertNotIn(passport.id, self._ids(U.get_undetected_base_queryset()))
        self.assertTrue(crime)

    def test_accused_in_persons_table_counts_as_known(self):
        case = self._case('C2', accused='')
        CasesPerson.objects.create(case=case, role='accused', name='Rohit')
        self.assertNotIn('C2', self._ids(U.get_undetected_base_queryset()))
        self.assertIn('C2', self._ids(U.get_absconded_cases()))

    def test_detected_case_is_never_undetected(self):
        self._case('C3', status='Detected', accused='')
        self.assertIn('C3', self._ids(U.get_cases_by_status('detected')))
        self.assertNotIn('C3', self._ids(U.get_undetected_base_queryset()))

    def test_arrest_in_table_means_not_absconded(self):
        case = self._case('C4', accused='Amit')
        person = CasesPerson.objects.create(case=case, role='accused', name='Amit')
        import datetime
        from django.utils import timezone
        ArrestReleaseStatus.objects.create(person=person, arrest_datetime=timezone.make_aware(
            datetime.datetime(2026, 10, 5, 20, 38)))
        self.assertNotIn('C4', self._ids(U.get_absconded_cases()))

    def test_ad_and_preventive_are_not_undetected_or_absconded(self):
        self._case('AD1', module_key='ad', accused='')
        self._case('PR1', module_key='preventive', accused='Someone')
        self.assertFalse(self._ids(U.get_undetected_base_queryset()) & {'AD1', 'PR1'})
        self.assertFalse(self._ids(U.get_absconded_cases()) & {'AD1', 'PR1'})

    def test_nafis_lists_crime_cases_with_a_forensics_row(self):
        case = self._case('C5')
        CaseForensics.objects.create(case=case, nafis_fingerprint=True)
        self._case('L1', module_key='licence', extra_fields={'nafis_fingerprint': False})
        ids = self._ids(U.get_cases_by_status('nafis'))
        self.assertIn('C5', ids)
        self.assertNotIn('L1', ids)


class RoadAccidentRowGuardTests(TestCase):
    """Saving a non-accident case no longer creates an empty road_accident_records row."""

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _save(self, cid, sub, extra):
        from apps.crimetab.views import _save_case_child_entities
        case = CaseRecord.objects.create(id=cid, case_number=f'CR/{cid}', station_name='TEST',
                                         module_key='form_1_5', sub_category=sub, extra_fields=extra)
        _save_case_child_entities(case, {'extra_fields': extra})
        from apps.crimetab.models.accident import RoadAccidentRecord
        return RoadAccidentRecord.objects.filter(case=case).exists()

    def test_tadipar_with_accused_acc_keys_and_deceased_gets_no_row(self):
        self.assertFalse(self._save('T1', 'Tadipar', {'acc_id': '1', 'acc_bail': False,
                                                      'deceased': [{'name': 'X'}]}))

    def test_road_accident_case_gets_its_row(self):
        self.assertTrue(self._save('R1', 'Road Accident', {'accident_spot': 'NH 53'}))

    def test_accident_answers_on_another_tab_still_saved(self):
        self.assertTrue(self._save('R2', 'Murder', {'acc_nature_of_accident': 'Collision'}))
