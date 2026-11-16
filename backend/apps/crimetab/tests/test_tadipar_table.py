"""B5: Tadipar orders in tadipar_records."""
from datetime import date
from io import StringIO

from django.core.management import call_command
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.service_tabs import TadiparRecord
from apps.crimetab.serializers import FullCaseDetailSerializer, serialize_case_list
from apps.crimetab.views import _save_case_child_entities

# The dynamic form saves each answer at the top level and in two copies
ANSWERS = {
    'sr_no': '9', 'externed_name': 'Rahul', 'alias': 'Rocky', 'nickname': '', 'age': '31', 'gender': 'Male',
    'mo_no': '9876543210', 'address': 'Ward 4, Nagpur', 'order_date': '20/08/2026', 'order_number': 'TD/12',
    'act_section': 'bns', 'period_from': '01/09/2026', 'period_to': '02/10/2026', 'revoked_date': '',
    'current_address': '', 'prohibited_areas': 'Nagpur',
}
TADIPAR_EXTRA = {**ANSWERS, 'extra_field_values': dict(ANSWERS), 'dynamic_extra_fields': {**ANSWERS, 'sr_no': ''}}


class TadiparTableTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _case(self, cid, extra, module='tadipar'):
        case = CaseRecord.objects.create(id=cid, case_number=f'T/{cid}', station_name='T', module_key=module,
                                         sub_category='Tadipar', extra_fields=extra)
        _save_case_child_entities(case, {'extra_fields': extra})
        return case

    def test_order_saved(self):
        row = TadiparRecord.objects.get(case=self._case('TA1', TADIPAR_EXTRA))
        self.assertEqual((row.sr_no, row.externed_name, row.alias, row.age, row.gender),
                         (9, 'Rahul', 'Rocky', 31, 'Male'))
        self.assertIsNone(row.nickname)
        self.assertEqual((row.order_date, row.period_from, row.period_to, row.revoked_date),
                         (date(2026, 8, 20), date(2026, 9, 1), date(2026, 10, 2), None))
        self.assertEqual((row.mo_no, row.order_number, row.act_section, row.prohibited_areas),
                         ('9876543210', 'TD/12', 'bns', 'Nagpur'))

    def test_answer_only_in_a_copy_is_found(self):
        extra = {'extra_field_values': {'externed_name': 'Sahil', 'period_to': '05/12/2026'}}
        row = TadiparRecord.objects.get(case=self._case('TA2', extra))
        self.assertEqual((row.externed_name, row.period_to), ('Sahil', date(2026, 12, 5)))

    def test_bad_numbers_dropped_and_other_tabs_get_no_row(self):
        row = TadiparRecord.objects.get(case=self._case('TA3', {'age': '200', 'sr_no': 'x'}))
        self.assertEqual((row.age, row.sr_no), (None, None))
        self._case('TA4', {'externed_name': 'X'}, module='form_1_5')
        self.assertEqual(TadiparRecord.objects.count(), 1)

    def test_edit_updates_the_row(self):
        case = self._case('TA5', TADIPAR_EXTRA)
        _save_case_child_entities(case, {'extra_fields': {**TADIPAR_EXTRA, 'revoked_date': '15/09/2026'}})
        self.assertEqual(TadiparRecord.objects.get(case=case).revoked_date, date(2026, 9, 15))

    def test_read_back_keeps_the_json_shape_in_every_copy(self):
        case = self._case('TA6', TADIPAR_EXTRA)
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields={
            'sr_no': '9', 'period_to': '', 'extra_field_values': {'period_to': '01/01/2026', 'sr_no': ''},
            'dynamic_extra_fields': {'age': ''}})
        case = CaseRecord.objects.get(pk=case.pk)
        for extra in (FullCaseDetailSerializer(case).data['extra_fields'],
                      serialize_case_list([case])[0]['extra_fields']):
            self.assertEqual(extra['sr_no'], '9')            # text stays text
            self.assertEqual(extra['period_to'], '02/10/2026')  # dd/mm/yyyy like the app
            self.assertEqual(extra['externed_name'], 'Rahul')
            self.assertEqual(extra['extra_field_values'], {'period_to': '02/10/2026', 'sr_no': '9'})
            self.assertEqual(extra['dynamic_extra_fields'], {'age': '31'})  # only keys the copy holds

    def test_backfill_dry_run_then_real_run(self):
        case = CaseRecord.objects.create(id='TA7', case_number='T/7', station_name='T', module_key='tadipar',
                                         extra_fields=TADIPAR_EXTRA)
        out = StringIO()
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', '--dry-run', stdout=out)
        self.assertIn('tadipar rows 1', out.getvalue())
        self.assertFalse(TadiparRecord.objects.exists())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertEqual(TadiparRecord.objects.get(case=case).externed_name, 'Rahul')
        self.assertEqual(TadiparRecord.objects.count(), 1)

    def test_deleting_the_case_deletes_the_row(self):
        self._case('TA8', TADIPAR_EXTRA).delete()
        self.assertFalse(TadiparRecord.objects.exists())
