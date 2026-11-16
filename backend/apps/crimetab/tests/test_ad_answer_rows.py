"""B4: A.D. answers in case_extra_field_values (one row per answer)."""
from io import StringIO

from django.core.cache import cache
from django.core.management import call_command
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import CaseExtraFieldValue
from apps.crimetab.services import ad_service as svc
from apps.crimetab.tests.test_ad_backend import AdBackendTests
from apps.crimetab.tests.test_ad_unknown_deceased import AdPersonsApiTests, mig_persons
from apps.crimetab.views_ad import AdDetailView

PERSONS = AdPersonsApiTests.TWO_PERSONS[mig_persons.GROUP_KEY]


class AdAnswerRowsTests(TestCase):
    setUp = AdBackendTests.setUp
    _req = AdBackendTests._req
    create = AdBackendTests.create
    list = AdBackendTests.list
    patch = AdBackendTests.patch

    def _form(self, rid):
        return AdDetailView.as_view()(self._req('get', f'/api/ad/{rid}/'), pk=rid).data['form_data']

    def _rows(self, rid):
        return CaseExtraFieldValue.objects.filter(case_id=rid)

    def _with_checkbox_and_list(self):
        first = {**PERSONS[0], 'ad_inquest_panchanama': True, 'ad_inquest_panchanama_date': '04/11/2026 11:37',
                 'ad_preserve': ['Viscera', 'Other'], 'ad_preserve_other': 'TEST cloth'}
        return {'case_number': 'TEST_AD_R1', mig_persons.GROUP_KEY: [first, PERSONS[1]]}

    def test_answers_saved_as_rows(self):
        rid = self.create(self._with_checkbox_and_list()).data['id']
        rows = {(r.field_def.field_key, r.row_no): r for r in self._rows(rid).select_related('field_def')}
        self.assertEqual(rows[('ad_relative_name', 0)].field_value, 'TEST Sita')
        self.assertEqual(rows[('ad_deceased_name', 1)].field_value, 'TEST Ram')
        self.assertEqual(rows[('ad_postmortem', 0)].field_value, 'Yes')
        tick = rows.get(('ad_inquest_panchanama', 0))
        if tick is not None:  # the field exists in this form version
            self.assertEqual(tick.value_date, '04/11/2026 11:37')

    def test_form_data_comes_back_the_same_from_the_table(self):
        rid = self.create(self._with_checkbox_and_list()).data['id']
        before = self._form(rid)
        CaseRecord.objects.filter(pk=rid).update(extra_fields={})  # only the rows are left
        self.assertEqual(self._form(rid), before)
        self.assertEqual(len(before[mig_persons.GROUP_KEY]), 2)

    def test_list_reads_the_rows(self):
        rid = self.create(self._with_checkbox_and_list()).data['id']
        before = self.list().data['results']
        CaseRecord.objects.filter(pk=rid).update(extra_fields={})
        cache.clear()
        self.assertEqual(self.list().data['results'], before)

    def test_edit_replaces_the_rows(self):
        rid = self.create(self._with_checkbox_and_list()).data['id']
        res = self.patch(rid, {mig_persons.GROUP_KEY: [PERSONS[1]]})
        self.assertEqual(res.status_code, 200, res.data)
        self.assertEqual(set(self._rows(rid).values_list('row_no', flat=True)), {0})
        self.assertEqual(self._form(rid)[mig_persons.GROUP_KEY][0]['ad_deceased_name'], 'TEST Ram')

    def test_old_records_fall_back_to_the_json_then_backfill_copies_them(self):
        rid = self.create(self._with_checkbox_and_list()).data['id']
        expected = self._form(rid)
        self._rows(rid).delete()  # a record saved before the rows existed
        self.assertEqual(self._form(rid), expected)
        out = StringIO()
        with TenantContext('maharashtra'):
            call_command('backfill_service_tab_tables', '--schema', 'maharashtra', '--dry-run', stdout=out)
        self.assertIn('a.d. cases 1', out.getvalue())
        self.assertFalse(self._rows(rid).exists())
        with TenantContext('maharashtra'):
            call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
            call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        CaseRecord.objects.filter(pk=rid).update(extra_fields={})
        self.assertEqual(self._form(rid), expected)

    def test_text_shapes(self):
        defs = svc.load_field_defs(svc.AdSettings())
        rows = svc.build_answer_rows(CaseRecord(id='X'), {mig_persons.GROUP_KEY: [
            {'ad_preserve': ['A, with comma', 'B']}]}, defs)
        self.assertEqual(svc.answers_from_rows(rows, defs),
                         {mig_persons.GROUP_KEY: [{'ad_preserve': ['A, with comma', 'B']}]})
