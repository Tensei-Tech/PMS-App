import datetime
import importlib

from django.apps import apps as django_apps
from django.core.cache import cache
from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.crimetab.models import ModuleSetting
from apps.crimetab.models.mpda import MpdaAccusedPerson, MpdaGangMember, MpdaProposal
from apps.crimetab.tests.test_mpda_backend import DummyMpdaOfficerUser
from apps.crimetab.views_mpda import MpdaConfigView, MpdaSummaryView
from apps.crimetab.tests.state_schema import enter_state_schema


class _Editor:
    connection = connection


class MpdaSummaryTests(TestCase):
    def setUp(self):
        enter_state_schema(self)
        cache.clear()
        importlib.import_module('apps.crimetab.migrations.0074_mpda_summary_settings').seed(django_apps, _Editor())
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='enforce_permissions',
                                               defaults={'setting_value': 'false'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='date_format',
                                               defaults={'setting_value': '%d/%m/%Y'})
        self.factory = APIRequestFactory()
        self.user = DummyMpdaOfficerUser()

    def _summary(self, user=None):
        req = self.factory.get('/api/mpda/summary/')
        force_authenticate(req, user=user or self.user)
        res = MpdaSummaryView.as_view()(req)
        self.assertEqual(res.status_code, 200)
        return res.data

    def _proposal(self, **kw):
        return MpdaProposal.objects.create(station_name=self.user.station_name, **kw)

    def test_row_contents(self):
        p = self._proposal(proposal_no_and_year='TEST 1/2026', proposal_outcome='Granted',
                           granted_date=datetime.date(2026, 10, 1), mpda_category='TEST Dangerous Person')
        MpdaAccusedPerson.objects.create(proposal=p, display_order=1, name='TEST Ravi', age=30, gender='Male',
                                         mobile='9876543210', address='TEST Pune', aadhaar='123412341234')
        MpdaAccusedPerson.objects.create(proposal=p, display_order=2, name='TEST Shyam')
        for n in ('TEST A', 'TEST B', 'TEST C'):
            MpdaGangMember.objects.create(proposal=p, name=n)

        row = self._summary()['results'][0]
        self.assertEqual(row['sr_no'], 1)
        self.assertEqual(row['accused'], ['TEST Ravi, 30 Yrs, Male, Mob: 9876543210, TEST Pune', 'TEST Shyam'])
        self.assertNotIn('123412341234', str(row))
        self.assertEqual(row['gang_members'], 3)
        self.assertEqual(row['outcome'], 'Granted (01/10/2026)')
        self.assertEqual(row['category'], 'TEST Dangerous Person')

    def test_legacy_accused_rejected_date_and_other_category(self):
        self._proposal(accused_name='TEST Legacy', accused_age=40, proposal_outcome='Rejected',
                       rejected_date=datetime.date(2026, 9, 5), mpda_category='Other',
                       mpda_category_other='TEST Bootlegger')
        self._proposal()  # nothing filled
        first, second = self._summary()['results']
        self.assertEqual(first['accused'], ['TEST Legacy, 40 Yrs'])
        self.assertEqual(first['outcome'], 'Rejected (05/09/2026)')
        self.assertEqual(first['category'], 'Other (TEST Bootlegger)')
        self.assertEqual((second['sr_no'], second['accused'], second['outcome'], second['category']),
                         (2, [], '', ''))

    def test_station_isolation_and_constant_queries(self):
        self._proposal(accused_name='TEST Mine')
        other = DummyMpdaOfficerUser(station_name='TEST Other PS', uid='TEST_o')
        MpdaProposal.objects.create(station_name=other.station_name, accused_name='TEST Theirs')
        self.assertEqual([r['accused'] for r in self._summary()['results']], [['TEST Mine']])

        def queries():
            with CaptureQueriesContext(connection) as ctx:
                self._summary()
            return len(ctx.captured_queries)
        one = queries()
        for i in range(10):
            p = self._proposal(accused_name=f'TEST {i}')
            MpdaAccusedPerson.objects.create(proposal=p, name=f'TEST acc {i}')
            MpdaGangMember.objects.create(proposal=p, name=f'TEST g {i}')
        self.assertEqual(queries(), one)

    def test_config_has_summary_card_and_headers(self):
        req = self.factory.get('/api/mpda/config/')
        force_authenticate(req, user=self.user)
        cfg = MpdaConfigView.as_view()(req).data
        self.assertEqual(cfg['card_labels']['summary'], 'Summary')
        self.assertEqual(list(cfg['summary_headers']), ['sr_no', 'accused', 'gang_members', 'outcome', 'category', 'actions'])
