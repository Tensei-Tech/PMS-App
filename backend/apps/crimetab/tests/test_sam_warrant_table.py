"""B8: Sam/Warrant answers in sam_warrant_records."""
from datetime import date, datetime
from io import StringIO

from django.core.management import call_command
from django.test import TestCase
from django.utils import timezone

from apps.cases.models import CaseRecord
from apps.cases.warrant_service import classify_warrant_record, get_warrant_execution_status
from apps.core.tenancy import TenantContext
from apps.crimetab.models.service_tabs import SamWarrantRecord
from apps.crimetab.views import _save_case_child_entities


def _ist(*day):
    return timezone.make_aware(datetime(*day))

# What add_warrant_case_dialog.dart sends
APP_EXTRA = {
    'warrant_type': 'nbw', 'execution_status': 'pending', 'warrant_number': 'W/12/2026',
    'accused_name': 'Rohit Patil', 'court_name': 'JMFC Nagpur',
    'issue_date': '2026-11-05T00:00:00.000', 'notes': 'Serve at home address',
}


class SamWarrantTableTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _case(self, cid, extra, module='sam_warrant', sub='Non-Bailable Warrant (पकड वारंट)'):
        case = CaseRecord.objects.create(id=cid, case_number=f'W/{cid}', station_name='T', module_key=module,
                                         sub_category=sub, extra_fields=extra)
        _save_case_child_entities(case, {'extra_fields': extra})
        return case

    def test_save_fills_the_row(self):
        case = self._case('SW1', APP_EXTRA)
        row = SamWarrantRecord.objects.get(case=case)
        self.assertEqual((row.warrant_type, row.execution_status), ('nbw', 'pending'))
        self.assertEqual((row.warrant_number, row.accused_name, row.court_name),
                         ('W/12/2026', 'Rohit Patil', 'JMFC Nagpur'))
        self.assertEqual(timezone.localtime(row.issue_date), _ist(2026, 11, 5))  # the day, at midnight India time
        self.assertEqual(row.notes, 'Serve at home address')

    def test_other_tabs_get_no_row(self):
        self._case('SW2', {'court_name': 'X'}, module='form_1_5', sub='Theft')
        self.assertFalse(SamWarrantRecord.objects.exists())

    def test_app_code_wins_over_the_tab_name_and_labels_are_understood(self):
        case = self._case('SW3', {**APP_EXTRA, 'warrant_type': 'summons'}, sub='Bailable Warrant (जमानती वारंट)')
        self.assertEqual(SamWarrantRecord.objects.get(case=case).warrant_type, 'summons')
        case = self._case('SW4', {'execution_status': 'तामील'}, sub='Bailable Warrant (जमानती वारंट)')
        row = SamWarrantRecord.objects.get(case=case)
        self.assertEqual((row.warrant_type, row.execution_status), ('bw', 'executed'))

    def test_edit_updates_the_row_and_report_reads_it(self):
        case = self._case('SW5', APP_EXTRA)
        _save_case_child_entities(case, {'extra_fields': {**APP_EXTRA, 'execution_status': 'executed'}})
        self.assertEqual(SamWarrantRecord.objects.get(case=case).execution_status, 'executed')
        # the report follows the table even when the JSON says otherwise
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields={'warrant_type': 'summons'})
        case = CaseRecord.objects.select_related('sam_warrant').get(pk=case.pk)
        self.assertEqual(classify_warrant_record(case), 'nbw')
        self.assertEqual(get_warrant_execution_status(case), 'executed')

    def test_api_shows_the_table_values(self):
        from apps.crimetab.serializers import FullCaseDetailSerializer
        case = self._case('SW6', APP_EXTRA)
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields={'issue_date': '2026-11-05T00:00:00.000'})
        extra = FullCaseDetailSerializer(CaseRecord.objects.get(pk=case.pk)).data['extra_fields']
        self.assertEqual(extra['court_name'], 'JMFC Nagpur')
        self.assertEqual(extra['execution_status'], 'pending')
        self.assertEqual(extra['issue_date'], '2026-11-05T00:00:00.000')  # same day: kept as the app wrote it

    def test_backfill_dry_run_then_real_run(self):
        case = CaseRecord.objects.create(id='SW7', case_number='W/7', station_name='T', module_key='sam_warrant',
                                         sub_category='Summons (समंस)', extra_fields=APP_EXTRA)
        out = StringIO()
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', '--dry-run', stdout=out)
        self.assertIn('would write sam/warrant rows 1', out.getvalue())
        self.assertFalse(SamWarrantRecord.objects.exists())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertEqual(SamWarrantRecord.objects.get(case=case).warrant_type, 'nbw')
        self.assertEqual(SamWarrantRecord.objects.count(), 1)

    def test_deleting_the_case_deletes_the_row(self):
        case = self._case('SW8', APP_EXTRA)
        case.delete()
        self.assertFalse(SamWarrantRecord.objects.exists())
