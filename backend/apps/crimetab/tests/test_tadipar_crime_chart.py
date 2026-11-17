"""B10: the Tadipar Crime Chart rows the app sends (PR #172) in tadipar_crime_chart_entries."""
from datetime import date

from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.common_form import Act, ActSection
from apps.crimetab.models.service_tabs import TadiparCrimeChartEntry, TadiparRecord
from apps.crimetab.serializers import FullCaseDetailSerializer, serialize_case_list
from apps.crimetab.views import _save_case_child_entities


class TadiparCrimeChartTests(TestCase):

    def setUp(self):
        self.bns = Act.objects.create(act_name='THE BHARATIYA NYAYA SANHITA (BNS), 2023')
        self.s303 = ActSection.objects.create(act=self.bns, section_number='303', section_title='Theft')
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _rows(self):
        return [
            {'cr_number': 'CR/12/2026', 'crime_head': 'Theft', 'act_id': self.bns.act_id,
             'section_id': self.s303.section_id, 'register_date': '05/11/2026'},
            {'cr_number': 'CR/40/2025', 'crime_head': 'Hurt'},
            {'cr_number': '', 'crime_head': ''},  # an empty row the form leaves behind
        ]

    def _case(self, cid, extra):
        case = CaseRecord.objects.create(id=cid, case_number=f'T/{cid}', station_name='T', module_key='tadipar',
                                         sub_category='Tadipar', extra_fields=extra)
        _save_case_child_entities(case, {'extra_fields': extra})
        return case

    def test_rows_saved_with_names_copied(self):
        case = self._case('TC1', {'externed_name': 'Rahul', 'act_id': self.bns.act_id,
                                  'crime_chart_entries': self._rows()})
        entries = list(TadiparCrimeChartEntry.objects.filter(record_id=case.pk).order_by('row_no'))
        self.assertEqual(len(entries), 2)
        first = entries[0]
        self.assertEqual((first.cr_number, first.crime_head, first.act_id, first.section_id),
                         ('CR/12/2026', 'Theft', self.bns.act_id, self.s303.section_id))
        self.assertEqual((first.act_name, first.section_number), (self.bns.act_name, '303'))
        self.assertEqual(first.register_date, date(2026, 11, 5))
        record = TadiparRecord.objects.get(case=case)
        self.assertIsNone(record.crime_chart_entries)  # rows are not kept as text
        self.assertEqual(record.act_id, str(self.bns.act_id))

    def test_read_back_in_the_app_shape(self):
        case = self._case('TC2', {'act_id': self.bns.act_id, 'crime_chart_entries': self._rows(),
                                  'dynamic_extra_fields': {'crime_chart_entries': ''}})
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields={
            'act_id': self.bns.act_id, 'dynamic_extra_fields': {'crime_chart_entries': ''}})
        case = CaseRecord.objects.get(pk=case.pk)
        expected = [{'cr_number': 'CR/12/2026', 'crime_head': 'Theft', 'act_id': self.bns.act_id,
                     'section_id': self.s303.section_id, 'register_date': '05/11/2026'},
                    {'cr_number': 'CR/40/2025', 'crime_head': 'Hurt'}]
        for extra in (FullCaseDetailSerializer(case).data['extra_fields'],
                      serialize_case_list([case])[0]['extra_fields']):
            self.assertEqual(extra['crime_chart_entries'], expected)
            self.assertEqual(extra['dynamic_extra_fields']['crime_chart_entries'], expected)
            self.assertEqual(extra['act_id'], self.bns.act_id)  # the app's number stays a number

    def test_typed_text_of_older_orders_stays_text(self):
        case = self._case('TC3', {'crime_chart_entries': 'CR 12/2026 theft, CR 40/2025 hurt'})
        self.assertEqual(TadiparRecord.objects.get(case=case).crime_chart_entries,
                         'CR 12/2026 theft, CR 40/2025 hurt')
        self.assertFalse(TadiparCrimeChartEntry.objects.exists())

    def test_edit_replaces_rows_and_save_without_the_chart_keeps_them(self):
        case = self._case('TC4', {'crime_chart_entries': self._rows()})
        _save_case_child_entities(case, {'extra_fields': {'crime_chart_entries': [{'cr_number': 'CR/1'}]}})
        self.assertEqual(list(TadiparCrimeChartEntry.objects.values_list('cr_number', flat=True)), ['CR/1'])
        _save_case_child_entities(case, {'extra_fields': {'externed_name': 'X'}})
        self.assertEqual(TadiparCrimeChartEntry.objects.count(), 1)
        _save_case_child_entities(case, {'extra_fields': {'crime_chart_entries': []}})
        self.assertFalse(TadiparCrimeChartEntry.objects.exists())

    def test_deleting_the_case_deletes_the_rows(self):
        self._case('TC5', {'crime_chart_entries': self._rows()}).delete()
        self.assertFalse(TadiparCrimeChartEntry.objects.exists())

    def test_list_reads_rows_without_a_query_per_case(self):
        cases = [self._case(f'TL{i}', {'crime_chart_entries': self._rows()}) for i in range(4)]
        records = list(CaseRecord.objects.filter(pk__in=[c.pk for c in cases]))
        from apps.crimetab.service_tab_tables import service_rows_by_case
        with self.assertNumQueries(2):
            rows = service_rows_by_case(records)
            for r in rows.values():
                list(r.crime_chart.all())
