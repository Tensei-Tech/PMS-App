import datetime
import importlib

from django.conf import settings
from django.test import TestCase
from django.utils import timezone

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models.common_form import CrimeRegistrationInfo, CrimeSpot
from apps.crimetab.views import _parse_d, _parse_dt, _save_case_child_entities

fix = importlib.import_module('apps.crimetab.migrations.0176_typed_datetimes_to_india_time')
UTC = datetime.timezone.utc


class IndiaTimeTests(TestCase):

    def test_time_zone_is_india(self):
        self.assertEqual(settings.TIME_ZONE, 'Asia/Kolkata')

    def test_typed_time_is_indian_time(self):
        dt = _parse_dt('07/10/2026 20:41')
        self.assertTrue(timezone.is_aware(dt))
        self.assertEqual(dt.astimezone(UTC), datetime.datetime(2026, 10, 7, 15, 11, tzinfo=UTC))
        self.assertEqual(timezone.localtime(dt).strftime('%d/%m/%Y %H:%M'), '07/10/2026 20:41')

    def test_iso_text_keeps_its_offset(self):
        dt = _parse_dt('2026-10-25T20:48:08Z')
        self.assertEqual(dt.astimezone(UTC).hour, 20)

    def test_typed_date_is_the_date_as_written(self):
        self.assertEqual(_parse_d('07/10/2026 23:59'), datetime.date(2026, 10, 7))
        self.assertEqual(_parse_d('2026-10-07T23:30:00Z'), datetime.date(2026, 10, 7))

    def test_place_and_registration_times_saved_as_indian_time(self):
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(id='TEST_TZ_1', case_number='CR/TZ/1', station_name='TEST')
            _save_case_child_entities(case, {'extra_fields': {
                'occurrence_datetime': '07/10/2026 20:41', 'registered_datetime': '08/10/2026 09:15'}})
            occ = CrimeSpot.objects.get(case=case).occurrence_datetime
            reg = CrimeRegistrationInfo.objects.get(case=case).registered_datetime
        self.assertEqual(occ.astimezone(UTC), datetime.datetime(2026, 10, 7, 15, 11, tzinfo=UTC))
        self.assertEqual(timezone.localtime(reg).strftime('%d/%m/%Y %H:%M'), '08/10/2026 09:15')


class OldValuesMigrationHelperTests(TestCase):
    """The SQL in migration 0176 runs only on PostgreSQL; its text handling is checked here."""

    def test_typed_text_top_level_then_common_form(self):
        self.assertEqual(fix.typed_text({'occurrence_datetime': '07/10/2026 20:41'}, ('occurrence_datetime',)),
                         '07/10/2026 20:41')
        self.assertEqual(fix.typed_text({'commonForm': {'regDate': '15/04/2026 20:36'}},
                                        ('registered_datetime', 'regDate')), '15/04/2026 20:36')
        self.assertIsNone(fix.typed_text({'occurrence_datetime': ''}, ('occurrence_datetime',)))

    def test_as_local_reads_indian_time_and_skips_iso_with_offset(self):
        value = fix.as_local('07/10/2026 20:41', fix.IST)
        self.assertEqual(value.astimezone(UTC), datetime.datetime(2026, 10, 7, 15, 11, tzinfo=UTC))
        self.assertIsNone(fix.as_local('2026-10-25T20:48:08Z', fix.IST))
