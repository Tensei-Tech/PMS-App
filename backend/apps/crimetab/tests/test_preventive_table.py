"""B9: Preventive tab answers in preventive_records and preventive_action_items."""
import copy
from datetime import date
from io import StringIO

from django.core.management import call_command
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.common_form import PreventiveActionItems
from apps.crimetab.models.service_tabs import PreventiveRecord
from apps.crimetab.serializers import FullCaseDetailSerializer, serialize_case_list
from apps.crimetab.views import _save_case_child_entities

# What preventive_form.dart sends (buildDocumentMap), under extra_fields['preventiveForm']
DOC = {
    'caseRef': {'crimeNo': '1234', 'regDate': '25/10/2026', 'crimeCategory': 'Assault',
                'caseStatus': 'Under Investigation'},
    'sections': {'act': 'BNS', 'selectedSections': ['106', '115'], 'otherSections': ''},
    'accusedList': [{'name': 'ABCD xyz', 'actionType': 'Arrested', 'bondTaken': 'Yes', 'bondDetails': 'Rs 5000'},
                    {'name': '', 'actionType': 'Arrested', 'bondTaken': 'No', 'bondDetails': ''}],
    'istegasha': {'hasPreventiveNo': 'Yes', 'preventiveSectionAct': '110 CrPC/129 BNSS', 'preventiveNo': '11',
                  'preventiveDate': '26/10/2026', 'outwardNo': '14', 'ioName': 'PSI Patil'},
    'riskAndStatus': {'riskFlag': 'High Priority', 'actionStatus': 'Preventive Action Completed', 'remarks': 'ok'},
    'preventive_no': '11', 'preventive_date': '26/10/2026', 'crimeNo': '1234',
}


def extra_of(doc=DOC):
    doc = copy.deepcopy(doc)
    return {'preventiveForm': doc, 'preventive_no': doc.get('preventive_no'),
            'preventive_date': doc.get('preventive_date'), 'crimeNo': doc.get('crimeNo')}


class PreventiveTableTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _case(self, cid, extra, module='preventive'):
        case = CaseRecord.objects.create(id=cid, case_number='1234', station_name='T', module_key=module,
                                         extra_fields=extra)
        _save_case_child_entities(case, {'extra_fields': extra})
        return case

    def test_entry_saved(self):
        row = PreventiveRecord.objects.get(case=self._case('PV1', extra_of()))
        self.assertEqual((row.crime_no, row.reg_date, row.crime_category, row.act),
                         ('1234', date(2026, 10, 25), 'Assault', 'BNS'))
        self.assertEqual(row.selected_sections, '["106", "115"]')
        self.assertEqual((row.has_preventive_no, row.preventive_section_act, row.preventive_no),
                         (True, '110 CrPC/129 BNSS', '11'))
        self.assertEqual((row.preventive_date, row.outward_no, row.io_name), (date(2026, 10, 26), '14', 'PSI Patil'))
        self.assertEqual((row.risk_flag, row.action_status, row.remarks),
                         ('High Priority', 'Preventive Action Completed', 'ok'))

    def test_each_named_accused_is_an_action_item(self):
        case = self._case('PV2', extra_of())
        items = list(PreventiveActionItems.objects.filter(case=case))
        self.assertEqual(len(items), 1)  # the empty entry is not kept
        item = items[0]
        self.assertEqual((item.name, item.action_type, item.preventive_number, item.outward_number),
                         ('ABCD xyz', '110 CrPC/129 BNSS', '11', '14'))
        self.assertEqual((item.accused_action, item.bond_taken, item.bond_details), ('Arrested', True, 'Rs 5000'))
        self.assertEqual(item.action_date, date(2026, 10, 26))

    def test_custom_provision_is_kept_not_refused(self):
        doc = copy.deepcopy(DOC)
        doc['istegasha']['preventiveSectionAct'] = 'Sec 93 Local Act (typed)'
        case = self._case('PV3', extra_of(doc))
        self.assertEqual(PreventiveActionItems.objects.get(case=case).action_type, 'Sec 93 Local Act (typed)')

    def test_edit_replaces_the_people(self):
        case = self._case('PV4', extra_of())
        doc = copy.deepcopy(DOC)
        doc['accusedList'] = [{'name': 'New One', 'actionType': 'Notice', 'bondTaken': 'No'}]
        _save_case_child_entities(case, {'extra_fields': extra_of(doc)})
        self.assertEqual(list(PreventiveActionItems.objects.filter(case=case).values_list('name', 'bond_taken')),
                         [('New One', False)])

    def test_read_back_into_the_form_document(self):
        case = self._case('PV5', extra_of())
        CaseRecord.objects.filter(pk=case.pk).update(extra_fields={'preventiveForm': {
            'caseRef': {'regDate': '25/10/2026', 'crimeNo': ''}, 'istegasha': {}}})
        case = CaseRecord.objects.get(pk=case.pk)
        for extra in (FullCaseDetailSerializer(case).data['extra_fields'],
                      serialize_case_list([case])[0]['extra_fields']):
            doc = extra['preventiveForm']
            self.assertEqual(doc['caseRef']['crimeNo'], '1234')
            self.assertEqual(doc['caseRef']['regDate'], '25/10/2026')
            self.assertEqual(doc['sections']['selectedSections'], ['106', '115'])
            self.assertEqual(doc['istegasha']['hasPreventiveNo'], 'Yes')
            self.assertEqual(doc['istegasha']['preventiveDate'], '26/10/2026')
            self.assertEqual(doc['accusedList'], [{'name': 'ABCD xyz', 'actionType': 'Arrested',
                                                   'bondTaken': 'Yes', 'bondDetails': 'Rs 5000'}])

    def test_status_rule_is_unchanged(self):
        case = self._case('PV6', extra_of())
        self.assertEqual(CaseRecord.objects.get(pk=case.pk).status, case.status)

    def test_other_tabs_get_no_row(self):
        self._case('PV7', extra_of(), module='form_1_5')
        self.assertFalse(PreventiveRecord.objects.exists())

    def test_backfill_dry_run_then_real_run(self):
        case = CaseRecord.objects.create(id='PV8', case_number='1', station_name='T', module_key='preventive',
                                         extra_fields=extra_of())
        out = StringIO()
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', '--dry-run', stdout=out)
        self.assertIn('preventive rows 1', out.getvalue())
        self.assertFalse(PreventiveRecord.objects.exists())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        call_command('backfill_service_tab_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertEqual(PreventiveRecord.objects.get(case=case).preventive_no, '11')
        self.assertEqual(PreventiveActionItems.objects.filter(case=case).count(), 1)

    def test_deleting_the_case_deletes_the_rows(self):
        self._case('PV9', extra_of()).delete()
        self.assertFalse(PreventiveRecord.objects.exists())
        self.assertFalse(PreventiveActionItems.objects.exists())
