import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.crimetab.models.dynamic_engine import FieldTemplateField
from apps.crimetab.tests.test_ad_backend import AdBackendTests, _seed_ad_public_data
from apps.crimetab.views_ad import AdOfficersView

mig = importlib.import_module('apps.crimetab.migrations.0162_ad_registration_year_io_and_sdm_acp')


class AdRegistrationFormTests(TestCase):
    """Migration 0162: section name, Year / IO fields after AD No., SDM/ACP."""

    def setUp(self):
        _seed_ad_public_data()

    def fields(self):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME)}

    def test_registration_section_and_new_fields_after_ad_no(self):
        f = self.fields()
        self.assertEqual(f['case_number'].section, mig.NEW_SECTION)
        order = sorted((x for x in f.values() if x.section == mig.NEW_SECTION),
                       key=lambda x: x.display_order)
        self.assertEqual([x.field_key for x in order],
                         ['case_number', 'ad_year', 'ad_io_name', 'ad_io_designation'])
        year = f['ad_year']
        self.assertEqual((year.field_type, year.options_source, year.is_required),
                         ('year', 'years:2001-3001', True))
        self.assertEqual(year.depends_on_field_key, 'case_number')
        self.assertEqual(f['ad_io_name'].options_source, '/api/ad/officers/')
        self.assertEqual((f['ad_io_designation'].field_type, f['ad_io_designation'].options_source),
                         ('dropdown', '/api/options/designations/'))

    def test_sdm_sent_reads_sdm_acp(self):
        f = self.fields()
        self.assertEqual(f['ad_sdm_sent'].field_label, 'SDM/ACP Sent')
        self.assertEqual(f['ad_sdm_sent_date'].field_label, 'SDM/ACP Sent Date')
        self.assertEqual(f['ad_sdm_returned'].field_label, 'SDM Returned')

    def test_idempotent_and_backwards(self):
        mig.forwards(django_apps, None)
        self.assertEqual(FieldTemplateField.objects.filter(field_key='ad_year').count(), 1)
        mig.backwards(django_apps, None)
        f = self.fields()
        self.assertNotIn('ad_year', f)
        self.assertNotIn('ad_io_name', f)
        self.assertEqual(f['case_number'].section, mig.OLD_SECTION)
        self.assertEqual(f['ad_sdm_sent'].field_label, 'SDM Sent')
        mig.forwards(django_apps, None)


class AdYearAndOfficersApiTests(AdBackendTests):
    """The Year rule and the IO Name picker through the API."""

    def test_ad_no_without_year_is_refused(self):
        res = self.create({'case_number': 'TEST_AD_Y1', 'ad_year': ''})
        self.assertEqual(res.status_code, 400)
        self.assertIn('Year is required', str(res.data))
        self.assertFalse(CaseRecord.objects.filter(case_number='TEST_AD_Y1').exists())

    def test_year_outside_2001_3001_is_refused(self):
        for bad in ('2000', '3002', '20x6'):
            res = self.create({'case_number': 'TEST_AD_Y2', 'ad_year': bad})
            self.assertEqual(res.status_code, 400, bad)
        res = self.create({'case_number': 'TEST_AD_Y2', 'ad_year': '3001'})
        self.assertEqual(res.status_code, 201, res.data)

    def test_year_saved_with_io_and_not_needed_without_ad_no(self):
        res = self.create({'case_number': 'TEST_AD_Y3', 'ad_year': '2026',
                           'ad_io_name': 'TEST Officer', 'ad_io_designation': 'PSI'})
        extra = CaseRecord.objects.get(pk=res.data['id']).extra_fields
        self.assertEqual((extra['ad_year'], extra['ad_io_name'], extra['ad_io_designation']),
                         ('2026', 'TEST Officer', 'PSI'))
        # No AD No. yet: Year is hidden, so it is neither needed nor kept
        # (A case-level answer: PM is per deceased person since 0173)
        res = self.create({'ad_summary_sent': True, 'ad_year': '2026'})
        self.assertEqual(res.status_code, 201, res.data)
        self.assertNotIn('ad_year', CaseRecord.objects.get(pk=res.data['id']).extra_fields)

    def test_officers_endpoint_lists_station_officers(self):
        res = AdOfficersView.as_view()(self._req('get', '/api/ad/officers/'))
        self.assertEqual(res.status_code, 200)
        self.assertIsInstance(res.data, list)
