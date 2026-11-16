"""Rules of Disposal, Victim, Repeat Offender and Monthly (fetching tabs, second part)."""
from django.test import TestCase

from apps.cases import utils as U
from apps.cases.comparative_service import classify_case_record, is_case_detected
from apps.cases.group_filters import group_case_q
from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.common_form import CasesPerson
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup, CaseCategoryLink


class TabRulesTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()
        g1 = CaseCategoryGroup.objects.create(group_id=1, group_name='1 to 5', group_code='I TO V')
        g2 = CaseCategoryGroup.objects.create(group_id=2, group_name='Part 6', group_code='VI')
        CaseCategory.objects.create(group=g1, category_name='Theft', category_code='119')
        CaseCategory.objects.create(group=g2, category_name='Gambling', category_code='603')
        CaseCategory.objects.create(group=g2, category_name='Prohibition', category_code='602')
        self.standalone_prohibition = CaseCategory.objects.create(category_name='Prohibition',
                                                                  category_code='STAND_PROHIBITION')

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _case(self, cid, **kw):
        defaults = {'case_number': f'CR/{cid}', 'station_name': 'TEST', 'module_key': 'form_1_5',
                    'status': 'Disposal', 'extra_fields': {}}
        defaults.update(kw)
        return CaseRecord.objects.create(id=cid, **defaults)

    def _ids(self, qs):
        return set(qs.values_list('id', flat=True))

    # --- Disposal: one group per case
    def test_part6_crime_saved_from_1_to_5_counts_only_in_part6(self):
        self._case('G1', sub_category='Gambling')
        self._case('T1', sub_category='Theft')
        self._case('F1', sub_category=None)  # only the module says 1 to 5
        g1 = self._ids(CaseRecord.objects.filter(group_case_q(1)).distinct())
        g2 = self._ids(CaseRecord.objects.filter(group_case_q(2)).distinct())
        self.assertEqual(g1, {'T1', 'F1'})
        self.assertEqual(g2, {'G1'})

    # --- Victim
    def test_victim_includes_1_to_5_women_crimes_and_skips_service_records(self):
        self._case('V1', sub_category='Rape', status='Pending')
        self._case('V2', sub_category='Molestation', status='Pending')
        self._case('V3', module_key='passport', sub_category='Missing', status='Pending')
        ids = self._ids(U.get_victim_cases())
        self.assertTrue({'V1', 'V2'} <= ids)
        self.assertNotIn('V3', ids)

    # --- Repeat Offender
    def test_repeat_offender_needs_matching_age_and_ignores_placeholders(self):
        a = self._case('R1', status='Pending')
        b = self._case('R2', status='Pending')
        c = self._case('R3', status='Pending')
        CasesPerson.objects.create(case=a, role='accused', name='Sneha', age=22)
        CasesPerson.objects.create(case=b, role='accused', name='Sneha', age=45)  # different person
        CasesPerson.objects.create(case=c, role='accused', name='Rohit', age=30)
        d = self._case('R4', status='Pending')
        CasesPerson.objects.create(case=d, role='accused', name='rohit', age=31)  # same person
        e = self._case('R5', status='Pending', extra_fields={'accused_name': 'Business / Entity'})
        f = self._case('R6', status='Pending', extra_fields={'accused_name': 'Business / Entity'})
        ids, info = U.get_repeat_offender_map()
        self.assertEqual(ids, {'R3', 'R4'})
        self.assertEqual(info['R3']['other_crs'], ['CR/R4'])
        self.assertTrue(e and f)

    # --- Monthly
    def test_standalone_tab_counts_in_its_twins_group(self):
        case = self._case('M1', module_key='prohibition')
        CaseCategoryLink.objects.create(case=case, category=self.standalone_prohibition)
        twins = {c.category_name.lower(): c.group for c in CaseCategory.objects.filter(group__isnull=False)}
        self.assertEqual(classify_case_record(case, twins)[0], 'SLL')

    def test_accused_in_persons_table_counts_as_detected(self):
        case = self._case('M2', status='Pending', accused='')
        self.assertFalse(is_case_detected(case, set()))
        self.assertTrue(is_case_detected(case, {'M2'}))
