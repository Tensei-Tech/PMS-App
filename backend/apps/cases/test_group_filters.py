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
        self.assertFalse({'t-standalone', 't-victim'} & (g1 | self._ids(2)))

    def test_preventive_case_filter_only_includes_present_eligible_categories(self):
        from apps.cases.group_filters import preventive_case_q
        from apps.crimetab.models import FieldTemplate, FieldTemplateField, CategoryFieldTemplate, PreventiveActionItems
        import datetime

        # Create template with preventive field
        tmpl = FieldTemplate.objects.create(template_name='TEST Prev Baseline')
        FieldTemplateField.objects.create(
            template=tmpl, field_key='preventive_action_type', field_label='Preventive Action Type',
            field_type='dropdown', display_order=1
        )
        cat_murder = CaseCategory.objects.create(
            category_name='TEST Murder', category_code='TEST_MURDER', is_active=True, display_order=10
        )
        CategoryFieldTemplate.objects.create(category=cat_murder, template=tmpl)

        # Standalone preventive case
        self._case('p-standalone', 'preventive')

        # Murder case WITH preventive action
        self._case('p-murder-with-prev', 'form_1_5', 'TEST Murder')
        with TenantContext('maharashtra'):
            case_murder = CaseRecord.objects.get(id='p-murder-with-prev')
            PreventiveActionItems.objects.create(
                case=case_murder, action_type='107 CrPC', action_date=datetime.date.today()
            )

        # Murder case WITHOUT preventive action
        self._case('p-murder-no-prev', 'form_1_5', 'TEST Murder')

        # Fake non-existent / deleted module case (e.g. ST Drugs) with preventive action
        self._case('p-st-drugs', 'form_6', 'ST Drugs')
        with TenantContext('maharashtra'):
            case_st = CaseRecord.objects.get(id='p-st-drugs')
            PreventiveActionItems.objects.create(
                case=case_st, action_type='55 MPA', action_date=datetime.date.today()
            )

        with TenantContext('maharashtra'):
            prev_ids = set(CaseRecord.objects.filter(preventive_case_q()).values_list('id', flat=True))

        # Must include standalone preventive
        self.assertIn('p-standalone', prev_ids)
        # Must include eligible present crime case with preventive action
        self.assertIn('p-murder-with-prev', prev_ids)
        # Must NOT include crime case without preventive action
        self.assertNotIn('p-murder-no-prev', prev_ids)
        # Must NOT include non-existent/inactive module case (ST Drugs)
        self.assertNotIn('p-st-drugs', prev_ids)

