from io import StringIO

from django.core.management import call_command
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.common_form_tables import save_common_form_tables
from apps.crimetab.models.common_form import (
    Act,
    ActSection,
    ActSubsection,
    CaseForensics,
    CctvTechnical,
    CrimeCaseActsSections,
    ProceduralChecklist,
)
from apps.crimetab.views import _save_case_child_entities

# What the app sends today: the Acts master was re-imported since, so act_id 6 /
# section_id 202 / subsection_id 253 no longer exist; the names and numbers do.
STALE_CHARGE = {
    'act': 6, 'act_id': 6, 'act_name': 'BNS', 'section': 202, 'section_id': 202,
    'section_number': '310', 'section_title': 'Dacoity', 'subsection': 253,
    'subsection_id': 253, 'subsection_code': '2',
}


class CommonFormTablesTests(TestCase):

    def setUp(self):
        self.other = Act.objects.create(act_name='THE MAHARASHTRA POLICE ACT, 1951')
        ActSection.objects.create(act=self.other, section_number='310', section_title='Other')
        self.bns = Act.objects.create(act_name='THE BHARATIYA NYAYA SANHITA (BNS), 2023')
        self.s310 = ActSection.objects.create(act=self.bns, section_number='310', section_title='Dacoity')
        self.sub2 = ActSubsection.objects.create(section=self.s310, subsection_code='2')
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()
        self.case = CaseRecord.objects.create(id='TEST_CF_1', case_number='CR/CF/1', station_name='TEST')

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _save(self, extra, **top):
        _save_case_child_entities(self.case, {'extra_fields': extra, **top})

    # --- charges
    def test_stale_ids_resolve_by_act_name_and_section_number(self):
        self._save({'charges': [STALE_CHARGE]})
        row = CrimeCaseActsSections.objects.get(case=self.case)
        self.assertEqual((row.act, row.section, row.subsection), (self.bns, self.s310, self.sub2))

    def test_current_ids_are_used_directly(self):
        charge = {'act_id': self.bns.act_id, 'section_id': self.s310.section_id,
                  'subsection_id': self.sub2.subsection_id}
        self._save({'charges': [charge]})
        self.assertEqual(CrimeCaseActsSections.objects.get(case=self.case).section, self.s310)

    def test_unknown_act_is_skipped_never_guessed(self):
        self._save({'charges': [{'act': 999, 'act_name': 'NO SUCH ACT', 'section_number': '310'}]})
        self.assertFalse(CrimeCaseActsSections.objects.filter(case=self.case).exists())

    def test_empty_commonform_copy_does_not_hide_real_charges(self):
        self._save({'charges': [STALE_CHARGE], 'commonForm': {'charges': {}}})
        self.assertEqual(CrimeCaseActsSections.objects.filter(case=self.case).count(), 1)

    def test_removing_all_charges_clears_the_table(self):
        self._save({'charges': [STALE_CHARGE]})
        self._save({'charges': []})
        self.assertFalse(CrimeCaseActsSections.objects.filter(case=self.case).exists())

    def test_old_dict_shape_still_works(self):
        self._save({'charges': {'a': {'act': 'BNS', 'sections': ['310']}}})
        self.assertEqual(CrimeCaseActsSections.objects.get(case=self.case).section, self.s310)

    # --- CCTV, forensics, panchanama
    def test_cctv_from_flat_keys(self):
        self._save({'cctv_checked': True, 'cdr_sent_date': '05/11/2026'})
        cctv = CctvTechnical.objects.get(case=self.case)
        self.assertTrue(cctv.cctv_checked)
        self.assertEqual(str(cctv.cdr_sent_date), '2026-11-05')

    def test_forensics_ticks_and_dates(self):
        self._save({'e_shakshya': True, 'e_shakshya_date': '01/11/2026', 'fingerprint_taken': 'Yes',
                    'nafis_fingerprint': False})
        f = CaseForensics.objects.get(case=self.case)
        self.assertEqual((f.e_shakshya, f.fingerprint_taken, f.nafis_fingerprint), (True, True, False))
        self.assertEqual(str(f.e_shakshya_date), '2026-11-01')

    def test_old_investigation_notes_still_work(self):
        self._save({'investigationNotes': {'nafisFingerprint': 'Yes', 'fingerprintVal': 'No'}})
        f = CaseForensics.objects.get(case=self.case)
        self.assertEqual((f.nafis_fingerprint, f.fingerprint_taken), (True, False))

    def test_panchanama_ticks_and_untick(self):
        self._save({'spot_panchanama': True, 'seizure_panchanama': True, 'search_panchanama': False})
        names = set(ProceduralChecklist.objects.filter(case=self.case).values_list('item_name', flat=True))
        self.assertEqual(names, {'Spot Panchanama', 'Seizure Panchanama'})
        self._save({'spot_panchanama': False, 'seizure_panchanama': True})
        names = set(ProceduralChecklist.objects.filter(case=self.case).values_list('item_name', flat=True))
        self.assertEqual(names, {'Seizure Panchanama'})

    def test_write_false_changes_nothing(self):
        done = save_common_form_tables(self.case, extra={
            'charges': [STALE_CHARGE], 'cctv_checked': True, 'nafis_fingerprint': True,
            'spot_panchanama': True}, write=False)
        self.assertEqual((done['charges'], done['cctv'], done['forensics'], done['panchanama']), (1, True, True, 1))
        for model in (CrimeCaseActsSections, CctvTechnical, CaseForensics, ProceduralChecklist):
            self.assertFalse(model.objects.filter(case=self.case).exists(), model.__name__)

    # --- backfill command
    def test_backfill_dry_run_then_real_run(self):
        self.case.extra_fields = {'charges': [STALE_CHARGE], 'cctv_checked': True,
                                  'commonForm': {'spot_panchanama': True}}
        self.case.save()
        out = StringIO()
        call_command('backfill_common_form_tables', '--schema', 'maharashtra', '--dry-run', stdout=out)
        self.assertIn('would write', out.getvalue())
        self.assertFalse(CrimeCaseActsSections.objects.filter(case=self.case).exists())
        call_command('backfill_common_form_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertEqual(CrimeCaseActsSections.objects.filter(case=self.case).count(), 1)
        self.assertTrue(CctvTechnical.objects.get(case=self.case).cctv_checked)
        self.assertTrue(ProceduralChecklist.objects.filter(case=self.case, item_name='Spot Panchanama').exists())

    def test_backfill_keeps_charges_when_json_has_none(self):
        CrimeCaseActsSections.objects.create(case=self.case, act=self.bns, section=self.s310)
        self.case.extra_fields = {'charges': {}, 'cctv_checked': False}
        self.case.save()
        call_command('backfill_common_form_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertEqual(CrimeCaseActsSections.objects.filter(case=self.case).count(), 1)


class CommonFormPeopleAndPlaceTests(TestCase):

    def setUp(self):
        self.ctx = TenantContext('maharashtra')
        self.ctx.__enter__()
        self.case = CaseRecord.objects.create(id='TEST_CF_P1', case_number='CR/CF/P1', station_name='TEST')

    def tearDown(self):
        self.ctx.__exit__(None, None, None)

    def _save(self, extra, **top):
        _save_case_child_entities(self.case, {'extra_fields': extra, **top})

    def _people(self, role):
        from apps.crimetab.models.common_form import CasesPerson
        return CasesPerson.objects.filter(case=self.case, role=role)

    def test_crime_spot_from_flat_keys(self):
        from apps.crimetab.models.common_form import CrimeSpot
        self._save({'commonForm': {'village_town': 'Beltarodi', 'area_name': 'Ward 4',
                                   'full_address': 'Near temple', 'occurrence_datetime': '07/10/2026 20:41'}})
        spot = CrimeSpot.objects.get(case=self.case)
        self.assertEqual((spot.village_town, spot.area_name, spot.full_address),
                         ('Beltarodi', 'Ward 4', 'Near temple'))
        self.assertEqual(spot.occurrence_datetime.strftime('%d/%m/%Y'), '07/10/2026')

    def test_complainant_from_flat_keys_over_empty_object(self):
        self._save({'complainant': {'name': '', 'age': ''},
                    'complainant_name': 'Ramesh Patil', 'complainant_age': '42',
                    'complainant_mobile': '98765 43210', 'complainant_aadhaar': '1234 5678 9012'})
        person = self._people('complainant').get()
        self.assertEqual((person.name, person.age, person.mobile, person.aadhaar),
                         ('Ramesh Patil', 42, '9876543210', '123456789012'))

    def test_accused_list_survives_the_plain_text_accused_field(self):
        # The request's own `accused` is the case's text column; the list is in the JSON
        self._save({'commonForm': {'accused': [{'name': 'Rohit', 'age': '', 'gender': 'Male'},
                                               {'name': 'Amit', 'age': '25'}]}}, accused='Rohit, Amit')
        self.assertEqual(set(self._people('accused').values_list('name', flat=True)), {'Rohit', 'Amit'})
        self.assertIsNone(self._people('accused').get(name='Rohit').age)

    def test_accused_list_with_other_key_names_and_single_flat_accused(self):
        self._save({'accused_list': [{'name': 'Sunil', 'pan_number': 'abcde1234f', 'aadhar_number': '111122223333'}],
                    'accused_name': 'Vijay'})
        sunil = self._people('accused').get(name='Sunil')
        self.assertEqual((sunil.pan, sunil.aadhaar), ('ABCDE1234F', '111122223333'))
        self.assertTrue(self._people('accused').filter(name='Vijay').exists())

    def test_bad_values_are_dropped_not_crashing(self):
        self._save({'complainant_name': 'X' * 200, 'complainant_mobile': '12345',
                    'complainant_age': 'forty', 'complainant_pan': 'not-a-pan'})
        person = self._people('complainant').get()
        self.assertEqual(len(person.name), 150)
        self.assertEqual((person.mobile, person.age, person.pan), (None, None, None))

    def test_saving_twice_adds_no_duplicates_and_fills_details(self):
        self._save({'accused_name': 'Rohit'})
        self._save({'accused_name': 'Rohit', 'accused_age': '30'})
        rows = self._people('accused')
        self.assertEqual(rows.count(), 1)
        self.assertEqual(rows.get().age, 30)

    def test_backfill_people_and_place(self):
        from apps.crimetab.models.common_form import CrimeSpot
        self.case.extra_fields = {'village_town': 'Beltarodi', 'complainant_name': 'Roch',
                                  'commonForm': {'accused': [{'name': 'Rohit'}]}}
        self.case.save()
        out = StringIO()
        call_command('backfill_common_form_tables', '--schema', 'maharashtra', '--dry-run', stdout=out)
        self.assertIn('people added 2', out.getvalue())
        self.assertFalse(self._people('accused').exists())
        call_command('backfill_common_form_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertTrue(self._people('complainant').filter(name='Roch').exists())
        self.assertTrue(self._people('accused').filter(name='Rohit').exists())
        self.assertEqual(CrimeSpot.objects.get(case=self.case).village_town, 'Beltarodi')
        call_command('backfill_common_form_tables', '--schema', 'maharashtra', stdout=StringIO())
        self.assertEqual(self._people('accused').count(), 1)
