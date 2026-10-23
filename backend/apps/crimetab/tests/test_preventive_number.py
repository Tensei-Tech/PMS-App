from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.crimetab.models import OptionValue
from apps.crimetab.models.common_form import PreventiveActionItems
from apps.crimetab.views import _save_case_child_entities


class CommonFormPreventiveNumberTests(TestCase):
    def setUp(self):
        OptionValue.objects.get_or_create(option_group='preventive_action_types',
                                          option_value='107 CrPC/126 BNSS',
                                          defaults={'display_order': 10, 'is_active': True})
        self.case = CaseRecord.objects.create(id='TEST_case_prev_no', module_key='form_1_5',
                                              title='TEST', station_name='TEST_Station')

    def _save(self, extra):
        item = {'name': 'TEST Accused', 'action_type': '107 CrPC/126 BNSS',
                'action_date': '15/10/2026', 'outward_number': 'TEST-OUT'}
        item.update(extra)
        _save_case_child_entities(self.case, {'preventive_actions': [item]})
        return PreventiveActionItems.objects.get(case=self.case)

    def test_preventive_number_is_saved(self):
        self.assertEqual(self._save({'preventive_number': 'TEST-PN-1'}).preventive_number, 'TEST-PN-1')

    def test_camel_case_key_is_accepted(self):
        self.assertEqual(self._save({'preventiveNumber': 'TEST-PN-2'}).preventive_number, 'TEST-PN-2')

    def test_blank_preventive_number_is_null(self):
        self.assertIsNone(self._save({'preventive_number': '  '}).preventive_number)
