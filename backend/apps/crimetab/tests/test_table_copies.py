"""The service-tab answers stored once (in their tables): the JSON rebuilds exactly."""
import copy
from unittest import mock

from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab import table_copies as T
from apps.crimetab.models.service_tabs import SamWarrantRecord
from apps.crimetab.serializers import FullCaseDetailSerializer, serialize_case_list
from apps.crimetab.tests.test_licence_table import LICENCE_EXTRA
from apps.crimetab.tests.test_passport_pvr_table import PASSPORT_EXTRA
from apps.crimetab.tests.test_preventive_table import extra_of
from apps.crimetab.tests.test_sam_warrant_table import APP_EXTRA
from apps.crimetab.tests.test_tadipar_table import TADIPAR_EXTRA
from apps.crimetab.views import _save_case_child_entities

CASES = {
    'sam_warrant': {**APP_EXTRA, 'issue_date': '2026-11-05T16:24:41.282', 'notes': ''},
    'licence': {**LICENCE_EXTRA, 'received_date': '2026-10-30T11:22:57.975981'},
    'passport': {**PASSPORT_EXTRA, 'verification_date': '2026-10-21T17:56:38.201'},
    'tadipar': {**TADIPAR_EXTRA, 'other_answer': 'kept', 'crime_chart_entries': [
        {'cr_number': 'CR/40/2025', 'crime_head': 'Hurt', 'register_date': '05/11/2026'}]},
    'preventive': {**extra_of(), 'lastEditedAt': '2026-10-26T16:45:04.442'},
}


class TableCopiesTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _case(self, module, extra):
        case = CaseRecord.objects.create(id=f'TC-{module}', case_number=f'X/{module}', station_name='T',
                                         module_key=module, sub_category='Non-Bailable Warrant',
                                         extra_fields=copy.deepcopy(extra))
        _save_case_child_entities(case, {'extra_fields': copy.deepcopy(extra)})
        return CaseRecord.objects.get(pk=case.pk)

    def _store_stripped(self, case):
        stored, count = T.strip_table_copies(case, case.extra_fields)
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields=stored)
        return stored, count

    def test_every_tab_rebuilds_exactly_after_the_copies_are_taken_out(self):
        for module, extra in CASES.items():
            with self.subTest(module=module):
                case = self._case(module, extra)
                full = copy.deepcopy(case.extra_fields)
                detail_before = FullCaseDetailSerializer(case).data['extra_fields']
                list_before = serialize_case_list([case])[0]['extra_fields']
                self.assertEqual(case.extra_fields, full)  # the serializers do not change the case

                stored, count = self._store_stripped(case)
                self.assertGreater(count, 0)
                self.assertIn(T.MARKER, stored)

                loaded = CaseRecord.objects.get(pk=case.pk)
                self.assertEqual(loaded.extra_fields, full)  # every reader sees the JSON as sent
                self.assertNotIn(T.MARKER, loaded.extra_fields)
                self.assertEqual(FullCaseDetailSerializer(loaded).data['extra_fields'], detail_before)
                self.assertEqual(serialize_case_list([loaded])[0]['extra_fields'], list_before)

    def test_values_and_answers_not_in_a_table_stay_in_the_json(self):
        case = self._case('tadipar', CASES['tadipar'])
        stored, _count = self._store_stripped(case)
        self.assertEqual(stored['other_answer'], 'kept')
        self.assertNotIn('externed_name', stored)
        self.assertNotIn('externed_name', stored['extra_field_values'])
        self.assertNotIn('crime_chart_entries', stored)

    def test_an_answer_the_table_holds_differently_is_kept(self):
        case = self._case('sam_warrant', CASES['sam_warrant'])
        SamWarrantRecord.objects.filter(case=case).update(court_name='Another Court')
        case = CaseRecord.objects.get(pk=case.pk)
        stored, count = self._store_stripped(case)
        self.assertGreater(count, 0)
        self.assertEqual(stored['court_name'], CASES['sam_warrant']['court_name'])
        self.assertEqual(CaseRecord.objects.get(pk=case.pk).extra_fields, case.extra_fields)

    def test_issue_date_keeps_its_time(self):
        case = self._case('sam_warrant', CASES['sam_warrant'])
        stored, _count = self._store_stripped(case)
        self.assertNotIn('issue_date', stored)
        self.assertEqual(CaseRecord.objects.get(pk=case.pk).extra_fields['issue_date'], '2026-11-05T16:24:41.282')

    def test_a_save_of_the_rebuilt_json_keeps_the_tables_and_json_the_same(self):
        case = self._case('licence', CASES['licence'])
        self._store_stripped(case)
        loaded = CaseRecord.objects.get(pk=case.pk)
        _save_case_child_entities(loaded, {'extra_fields': copy.deepcopy(loaded.extra_fields)})
        loaded.save()
        self.assertEqual(CaseRecord.objects.get(pk=case.pk).extra_fields, case.extra_fields)

    def test_already_stripped_or_other_cases_are_left_alone(self):
        case = self._case('sam_warrant', CASES['sam_warrant'])
        stored, _count = self._store_stripped(case)
        self.assertEqual(T.strip_table_copies(case, stored), (stored, 0))
        crime = CaseRecord.objects.create(id='TC-crime', case_number='C/1', station_name='T', module_key='form_1_5',
                                          extra_fields={'warrant_type': 'x'})
        self.assertEqual(T.strip_table_copies(crime, crime.extra_fields), (crime.extra_fields, 0))

    def test_a_restore_error_never_breaks_loading_a_case(self):
        case = self._case('sam_warrant', CASES['sam_warrant'])
        stored, _count = self._store_stripped(case)
        with mock.patch.object(T, 'table_values', side_effect=RuntimeError('boom')), \
                self.assertLogs('apps.crimetab.table_copies', level='ERROR'):
            loaded = CaseRecord.objects.get(pk=case.pk)
        self.assertEqual(loaded.extra_fields, stored)
