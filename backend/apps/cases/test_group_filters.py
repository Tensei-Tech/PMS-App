from django.test import TestCase

from apps.cases.group_filters import group_case_q
from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.public_master.models import StateRegistry


class GroupCaseFilterTests(TestCase):
    def setUp(self):
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True})
        g1, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1})
        g2, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=2, defaults={'group_name': 'Part 6', 'group_code': 'VI', 'display_order': 2})
        CaseCategory.objects.create(group=g1, category_name='TEST Attempt Case', category_code='T101', display_order=1)
        CaseCategory.objects.create(group=g2, category_name='TEST Part Six', category_code='T601', display_order=1)
        CaseCategory.objects.create(category_name='TEST Standalone', category_code='TEST_STAND', display_order=1)

    def _ids(self, group_id):
        with TenantContext('maharashtra'):
            return set(CaseRecord.objects.filter(group_case_q(group_id)).values_list('id', flat=True))

    def _case(self, cid, module_key, sub=None):
        with TenantContext('maharashtra'):
            CaseRecord.objects.create(id=cid, module_key=module_key, sub_category=sub, title=cid,
                                      case_number=cid, station_name='TEST PS')

    def test_membership_comes_from_database_categories(self):
        self._case('t-own-module', 'form_1_5')
        self._case('t-by-name-key', 'test_attempt_case')
        self._case('t-by-code', 't101')
        self._case('t-by-sub', 'crime', 'TEST Attempt Case')
        self._case('t-part6', 'form_6', 'TEST Part Six')
        self._case('t-standalone', 'test_stand', 'TEST Standalone')
        self._case('t-victim', 'victim', 'Victim')

        g1 = self._ids(1)
        self.assertTrue({'t-own-module', 't-by-name-key', 't-by-code', 't-by-sub'} <= g1)
        self.assertNotIn('t-part6', g1)
        self.assertEqual(self._ids(2) & {'t-part6', 't-standalone', 't-victim', 't-own-module'}, {'t-part6'})
        # A standalone tab is in neither group (no hard-coded module list)
        self.assertFalse({'t-standalone', 't-victim'} & (g1 | self._ids(2)))
