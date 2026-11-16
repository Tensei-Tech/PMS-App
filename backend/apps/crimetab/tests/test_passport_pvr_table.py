"""B6: Passport / PVR entries in passport_pvr_records."""
from datetime import date
from io import StringIO

from django.core.management import call_command
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.service_tabs import PassportPvrRecord
from apps.crimetab.serializers import FullCaseDetailSerializer, serialize_case_list
from apps.crimetab.views import _save_case_child_entities

# What passport_add_edit_dialog.dart sends
PASSPORT_EXTRA = {
    'file_number': 'PV-261105-123', 'applicant_name': 'Passport Verification (5)',
    'verified_count': 3, 'pending_count': 2, 'total_count': 5,
    'verification_status': 'Partially Verified', 'verification_date': '2026-11-05T00:00:00.000',
}
# pvr_add_edit_dialog.dart sends no verification_date
PVR_EXTRA = {
    'file_number': 'PVR-261105-1', 'applicant_name': 'PVR Verification (2)',
    'verified_count': 2, 'pending_count': 0, 'total_count': 2, 'verification_status': 'Verified',
}


class PassportPvrTableTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _case(self, cid, extra, module='passport'):
        case = CaseRecord.objects.create(id=cid, case_number=f'F/{cid}', station_name='T', module_key=module,
                                         sub_category='Passport Verification', extra_fields=extra)
        _save_case_child_entities(case, {'extra_fields': extra})
        return case

    def test_passport_batch_saved(self):
        case = self._case('PP1', PASSPORT_EXTRA)
        row = PassportPvrRecord.objects.get(case=case)
        self.assertEqual((row.kind, row.file_number), ('passport', 'PV-261105-123'))
        self.assertEqual((row.total_count, row.verified_count, row.pending_count), (5, 3, 2))
        self.assertEqual(row.verification_status, 'Partially Verified')
        self.assertEqual(row.verification_date, date(2026, 11, 5))

    def test_pvr_saved_without_a_date_and_counts_as_text(self):
        case = self._case('PP2', {**PVR_EXTRA, 'verified_count': '2', 'pending_count': 'x'}, module='pvr')
        row = PassportPvrRecord.objects.get(case=case)
        self.assertEqual((row.kind, row.verified_count, row.pending_count, row.verification_date),
                         ('pvr', 2, None, None))

    def test_other_tabs_get_no_row(self):
        self._case('PP3', {'file_number': 'X'}, module='form_1_5')
        self.assertFalse(PassportPvrRecord.objects.exists())

    def test_edit_updates_the_row(self):
        case = self._case('PP4', PASSPORT_EXTRA)
        _save_case_child_entities(case, {'extra_fields': {**PASSPORT_EXTRA, 'verified_count': 5, 'pending_count': 0,
                                                          'verification_status': 'Verified / Report Submitted'}})
        row = PassportPvrRecord.objects.get(case=case)
        self.assertEqual((row.verified_count, row.pending_count), (5, 0))
        self.assertEqual(row.verification_status, 'Verified / Report Submitted')

    def test_detail_and_list_show_the_table_values(self):
        case = self._case('PP5', PASSPORT_EXTRA)
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields={'verification_date': '2026-11-05T00:00:00.000'})
        case = CaseRecord.objects.get(pk=case.pk)
        detail = FullCaseDetailSerializer(case).data['extra_fields']
        listed = serialize_case_list([case])[0]['extra_fields']
        for extra in (detail, listed):
            self.assertEqual((extra['verified_count'], extra['pending_count'], extra['total_count']), (3, 2, 5))
            self.assertEqual(extra['verification_status'], 'Partially Verified')
            self.assertEqual(extra['verification_date'], '2026-11-05T00:00:00.000')  # same day kept as written

    def test_list_reads_the_rows_in_one_query_per_tab(self):
        cases = [self._case(f'PQ{i}', PASSPORT_EXTRA) for i in range(5)]
        records = list(CaseRecord.objects.filter(pk__in=[c.pk for c in cases]))
        from apps.crimetab.service_tab_tables import service_rows_by_case
        with self.assertNumQueries(1):
            rows = service_rows_by_case(records)
        self.assertEqual(len(rows), 5)

    def test_backfill_dry_run_then_real_run(self):
        case = CaseRecord.objects.create(id='PP6', case_number='F/6', station_name='T', module_key='pvr',
                                         extra_fields=PVR_EXTRA)
        out = StringIO()
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', '--dry-run', stdout=out)
        self.assertIn('would write passport/pvr rows 1', out.getvalue())
        self.assertFalse(PassportPvrRecord.objects.exists())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertEqual(PassportPvrRecord.objects.get(case=case).total_count, 2)
        self.assertEqual(PassportPvrRecord.objects.count(), 1)

    def test_deleting_the_case_deletes_the_row(self):
        self._case('PP7', PASSPORT_EXTRA).delete()
        self.assertFalse(PassportPvrRecord.objects.exists())
