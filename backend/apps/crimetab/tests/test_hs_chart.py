import datetime
import importlib

from django.apps import apps as django_apps
from django.core.cache import cache
from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.crimetab.models import ModuleSetting
from apps.crimetab.models.history_sheeter import (
    HistorySheeter,
    HistorySheeterPreventiveAction,
    HistorySheeterRelatedPerson,
)
from apps.crimetab.tests.test_history_sheeter_backend import DummyOfficerUser
from apps.crimetab.views_history_sheeter import HistorySheeterChartView, HistorySheeterConfigView


class _Editor:
    connection = connection


class HistorySheeterChartTests(TestCase):
    def setUp(self):
        cache.clear()
        importlib.import_module('apps.crimetab.migrations.0069_hs_chart_tab_settings').seed(django_apps, _Editor())
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='enforce_permissions',
                                               defaults={'setting_value': 'false'})
        self.factory = APIRequestFactory()
        self.user = DummyOfficerUser()

    def _chart(self, user=None):
        req = self.factory.get('/api/history-sheeter/chart/')
        force_authenticate(req, user=user or self.user)
        res = HistorySheeterChartView.as_view()(req)
        self.assertEqual(res.status_code, 200)
        return res.data

    def _sheet(self, sr, **kw):
        return HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=sr, **kw)

    def test_lists_open_and_closed_sheets_with_counts(self):
        hs = self._sheet(1, name='TEST Ravi', age=30, gender='Male', address='TEST Village',
                         mobile_no='9876543210', aadhaar_id_details='123412341234', total_cases=4)
        for t in ('associate', 'associate', 'rival', 'surety'):
            HistorySheeterRelatedPerson.objects.create(history_sheeter=hs, person_type=t, name='TEST')
        for a in ('MPDA', 'Externment', 'Other'):
            HistorySheeterPreventiveAction.objects.create(history_sheeter=hs, action_type=a)
        self._sheet(2, name='TEST Closed', closure_date=datetime.date(2026, 1, 1))

        data = self._chart()
        self.assertEqual(data['count'], 2)
        first, second = data['results']
        self.assertEqual((first['sr_no'], first['total_cases'], first['associates'], first['rivals'],
                          first['preventive']), (1, 4, 2, 1, 3))
        self.assertEqual(first['person'], 'TEST Ravi, 30 Yrs, Male, TEST Village, Mob: 9876543210')
        self.assertNotIn('123412341234', first['person'])
        self.assertEqual(second['sr_no'], 2)  # closed sheet is listed too

    def test_empty_parts_are_skipped_and_template_is_a_setting(self):
        self._sheet(1, name='TEST Only Name')
        self.assertEqual(self._chart()['results'][0]['person'], 'TEST Only Name')
        ModuleSetting.objects.filter(module_key='history_sheeter', setting_key='chart_person_template') \
            .update(setting_value='{name}|({gender})')
        self._sheet(2, name='TEST Two', gender='Female')
        people = [r['person'] for r in self._chart()['results']]
        self.assertEqual(people, ['TEST Only Name', 'TEST Two, (Female)'])

    def test_station_isolation_and_constant_queries(self):
        self._sheet(1, name='TEST Mine')
        other = DummyOfficerUser(station_name='TEST Other Station', uid='TEST_other')
        HistorySheeter.objects.create(station_name=other.station_name, sr_no=1, name='TEST Theirs')
        self.assertEqual([r['person'] for r in self._chart()['results']], ['TEST Mine'])

        def queries():
            with CaptureQueriesContext(connection) as ctx:
                self._chart()
            return len(ctx.captured_queries)
        one = queries()
        for i in range(2, 12):
            hs = self._sheet(i, name=f'TEST {i}')
            HistorySheeterRelatedPerson.objects.create(history_sheeter=hs, person_type='rival')
        self.assertEqual(queries(), one)

    def test_config_returns_chart_label_and_headers(self):
        req = self.factory.get('/api/history-sheeter/config/')
        force_authenticate(req, user=self.user)
        cfg = HistorySheeterConfigView.as_view()(req).data
        self.assertEqual(cfg['sub_tab_labels']['chart'], 'Chart')
        self.assertEqual(list(cfg['chart_headers']),
                         ['sr_no', 'person', 'total_cases', 'associates', 'rivals', 'preventive', 'actions'])
