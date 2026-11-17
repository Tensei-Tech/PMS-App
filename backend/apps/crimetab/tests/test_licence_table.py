"""B7: Licence applications in licence_records."""
from datetime import date, datetime
from io import StringIO

from django.core.management import call_command
from django.test import TestCase
from django.utils import timezone

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.service_tabs import LicenceRecord
from apps.crimetab.serializers import FullCaseDetailSerializer, serialize_case_list
from apps.crimetab.views import _save_case_child_entities


def _ist(*day):
    return timezone.make_aware(datetime(*day))

# What licence_add_edit_dialog.dart sends
LICENCE_EXTRA = {
    'applicant_name': 'Sneha Patil', 'business_name': 'Patil Arms', 'licence_type': '1. Arms Licence',
    'base_licence_type': 'Arms Licence', 'other_noc_type': '', 'received_date': '2026-11-05T00:00:00.000',
    'licence_number': 'LIC-261105-1', 'licence_status': 'Pending',
    'status_updated_at': '2026-11-05T14:30:00.000',
}


class LicenceTableTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _case(self, cid, extra, module='licence'):
        case = CaseRecord.objects.create(id=cid, case_number=f'L/{cid}', station_name='T', module_key=module,
                                         sub_category='1. Arms Licence', extra_fields=extra)
        _save_case_child_entities(case, {'extra_fields': extra})
        return case

    def test_application_saved(self):
        row = LicenceRecord.objects.get(case=self._case('LI1', LICENCE_EXTRA))
        self.assertEqual((row.licence_number, row.licence_type, row.base_licence_type),
                         ('LIC-261105-1', '1. Arms Licence', 'Arms Licence'))
        self.assertEqual((row.applicant_name, row.business_name, row.licence_status),
                         ('Sneha Patil', 'Patil Arms', 'Pending'))
        self.assertIsNone(row.other_noc_type)
        self.assertEqual(timezone.localtime(row.received_date), _ist(2026, 11, 5))  # the day, at midnight India time
        local = timezone.localtime(row.status_updated_at)
        self.assertEqual((local.date(), local.hour, local.minute), (date(2026, 11, 5), 14, 30))

    def test_other_tabs_get_no_row(self):
        self._case('LI2', {'licence_number': 'X'}, module='form_1_5')
        self.assertFalse(LicenceRecord.objects.exists())

    def test_status_change_updates_the_row(self):
        case = self._case('LI3', LICENCE_EXTRA)
        _save_case_child_entities(case, {'extra_fields': {**LICENCE_EXTRA, 'licence_status': 'Approved',
                                                          'status_updated_at': '2026-11-07T10:00:00.000'}})
        row = LicenceRecord.objects.get(case=case)
        self.assertEqual(row.licence_status, 'Approved')
        self.assertEqual(timezone.localtime(row.status_updated_at).date(), date(2026, 11, 7))

    def test_detail_and_list_show_the_table_values(self):
        case = self._case('LI4', LICENCE_EXTRA)
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields={
            'received_date': '2026-11-05T00:00:00.000', 'status_updated_at': '2026-11-05T14:30:00.000'})
        case = CaseRecord.objects.get(pk=case.pk)
        for extra in (FullCaseDetailSerializer(case).data['extra_fields'],
                      serialize_case_list([case])[0]['extra_fields']):
            self.assertEqual((extra['licence_status'], extra['business_name']), ('Pending', 'Patil Arms'))
            # same day / same moment: the app's own text is kept
            self.assertEqual(extra['received_date'], '2026-11-05T00:00:00.000')
            self.assertEqual(extra['status_updated_at'], '2026-11-05T14:30:00.000')

    def test_a_changed_moment_is_written_in_india_time(self):
        case = self._case('LI5', LICENCE_EXTRA)
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields={'status_updated_at': '2026-01-01T00:00:00'})
        extra = FullCaseDetailSerializer(CaseRecord.objects.get(pk=case.pk)).data['extra_fields']
        self.assertEqual(extra['status_updated_at'], '2026-11-05T14:30:00+05:30')

    def test_backfill_dry_run_then_real_run(self):
        case = CaseRecord.objects.create(id='LI6', case_number='L/6', station_name='T', module_key='licence',
                                         extra_fields=LICENCE_EXTRA)
        out = StringIO()
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', '--dry-run', stdout=out)
        self.assertIn('licence rows 1', out.getvalue())
        self.assertFalse(LicenceRecord.objects.exists())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertEqual(LicenceRecord.objects.get(case=case).licence_status, 'Pending')
        self.assertEqual(LicenceRecord.objects.count(), 1)

    def test_deleting_the_case_deletes_the_row(self):
        self._case('LI7', LICENCE_EXTRA).delete()
        self.assertFalse(LicenceRecord.objects.exists())
