"""rti_outcome(): what happened to an RTI application (Replied / Rejected /
Transferred), as the RTI detail API sends it."""
import contextlib
import datetime

from django.test import SimpleTestCase, TestCase

from apps.crimetab.models import RTIApplication
from apps.crimetab.serializers_rti import rti_outcome
from apps.crimetab.views_rti import RTI_OUTCOMES, rti_outcome_q


class RTIOutcomeTabFilterTests(TestCase):
    """Each RTI tab (Pending, Replied, Rejected, Transferred) lists only its own applications."""

    def setUp(self):
        day = datetime.date(2026, 10, 24)
        # Only rows the database accepts: on PostgreSQL rti_applications allows
        # at most one outcome (rti_one_outcome) and a rejection reason only
        # with its date (rti_reject_reason).
        rows = {
            1: {},                                                    # pending
            2: {'replied_date': day},                                 # replied
            4: {'rejected_date': day, 'rejection_reason': 'x'},       # rejected
            6: {'transferred_to': 'DIG office'},                      # transferred
            7: {'transferred_to': '   '},                             # blank = pending
        }
        for no, fields in rows.items():
            RTIApplication.objects.create(station_name='S', serial_year=2026, serial_no=no, **fields)

    def serials(self, outcome):
        return sorted(RTIApplication.objects.filter(rti_outcome_q(outcome)).values_list('serial_no', flat=True))

    def test_each_tab_gets_its_applications(self):
        self.assertEqual(self.serials('pending'), [1, 7])
        self.assertEqual(self.serials('replied'), [2])
        self.assertEqual(self.serials('rejected'), [4])
        self.assertEqual(self.serials('transferred'), [6])

    def test_tabs_cover_every_application_once(self):
        found = sum((self.serials(o) for o in RTI_OUTCOMES), [])
        self.assertEqual(sorted(found), [1, 2, 4, 6, 7])

    def test_matches_the_badge(self):
        for app in RTIApplication.objects.all():
            outcome = (rti_outcome(app) or 'Pending').lower()
            self.assertIn(app.serial_no, self.serials(outcome))

    def test_unknown_or_all_means_no_filter(self):
        self.assertIsNone(rti_outcome_q('all'))
        self.assertIsNone(rti_outcome_q(''))


class RTISummaryViewTests(TestCase):
    """Summary tab: counts by Type of Info x outcome, with a grand total."""

    def setUp(self):
        from apps.crimetab.models import OptionValue
        # On PostgreSQL migration 0029 seeds five types (Crime record ...
        # Other); seed them on every database, then keep only the three this
        # test uses, so the rows are the same on SQLite and PostgreSQL.
        for i, name in enumerate(['Crime record', 'Personal', 'Missing',
                                  'Accident record', 'Other'], 1):
            OptionValue.objects.update_or_create(
                option_group='rti_info_type', option_value=name,
                defaults={'display_order': i * 10, 'is_active': True})
        OptionValue.objects.filter(option_group='rti_info_type').exclude(
            option_value__in=['Crime record', 'Personal', 'Missing']).update(is_active=False)
        day = datetime.date(2026, 10, 24)
        rows = [
            ('Crime record', {'replied_date': day}),
            ('Crime record', {'replied_date': day}),
            ('Crime record', {'rejected_date': day, 'rejection_reason': 'x'}),
            ('Missing', {}),
            ('Old type', {'transferred_to': 'DIG office'}),
        ]
        for no, (info, fields) in enumerate(rows, 1):
            RTIApplication.objects.create(station_name='S', serial_year=2026, serial_no=no,
                                          info_type=info, **fields)
        RTIApplication.objects.create(station_name='Other station', serial_year=2026,
                                      serial_no=1, info_type='Crime record')

    def get(self):
        from unittest import mock
        from rest_framework.test import APIRequestFactory
        from apps.crimetab import views_rti

        request = APIRequestFactory().get('/api/rti/summary/')
        request.user = type('User', (), {'station_name': 'S'})()
        # Keep the connection's own schema: on PostgreSQL rti_applications lives in the
        # state schema, not in public, so the view must not switch schemas here
        with mock.patch.object(views_rti, '_resolve_tenant_and_auth', return_value=('test', None)), \
                mock.patch.object(views_rti, 'TenantContext', contextlib.nullcontext):
            return views_rti.RTISummaryView().get(request).data

    def test_counts_by_type_and_outcome(self):
        data = self.get()
        rows = {r['info_type']: r for r in data['rows']}
        self.assertEqual([c['key'] for c in data['columns']],
                         ['replied', 'rejected', 'pending', 'transferred', 'total'])
        # every info type is listed, in option order, then types found only on cases
        self.assertEqual(list(rows), ['Crime record', 'Personal', 'Missing', 'Old type'])
        self.assertEqual((rows['Crime record']['replied'], rows['Crime record']['rejected'],
                          rows['Crime record']['total']), (2, 1, 3))
        self.assertEqual(rows['Personal']['total'], 0)
        self.assertEqual(rows['Missing']['pending'], 1)
        self.assertEqual(rows['Old type']['transferred'], 1)
        # only this station's applications
        self.assertEqual(data['grand_total'],
                         {'replied': 2, 'rejected': 1, 'pending': 1, 'transferred': 1, 'total': 5})

    def chart(self, **params):
        from unittest import mock
        from rest_framework.test import APIRequestFactory
        from apps.crimetab import views_rti

        request = APIRequestFactory().get('/api/rti/chart/', params)
        request.query_params = request.GET
        request.user = type('User', (), {'station_name': 'S'})()
        # Keep the connection's own schema: on PostgreSQL rti_applications lives in the
        # state schema, not in public, so the view must not switch schemas here
        with mock.patch.object(views_rti, '_resolve_tenant_and_auth', return_value=('test', None)), \
                mock.patch.object(views_rti, 'TenantContext', contextlib.nullcontext):
            data = views_rti.RTIChartView().get(request).data
        return data['count'], [r['sr_no'] for r in data['results']]

    def test_clicked_count_lists_its_cases(self):
        """A count in the summary opens the cases behind it: Type of Info x outcome."""
        self.assertEqual(self.chart(info_type='Crime record', outcome='replied'),
                         (2, ['RTI-2026/1', 'RTI-2026/2']))
        self.assertEqual(self.chart(info_type='Crime record'), (3, ['RTI-2026/1', 'RTI-2026/2', 'RTI-2026/3']))
        self.assertEqual(self.chart(info_type='Missing', outcome='pending'), (1, ['RTI-2026/4']))
        self.assertEqual(self.chart(info_type='Personal'), (0, []))
        self.assertEqual(self.chart(outcome='transferred'), (1, ['RTI-2026/5']))


class RTIOutcomeTests(SimpleTestCase):
    def app(self, **fields):
        return RTIApplication(station_name='S', serial_year=2026, serial_no=1, **fields)

    def test_outcome_of_each_kind(self):
        day = datetime.date(2026, 10, 24)
        self.assertEqual(rti_outcome(self.app(replied_date=day)), 'Replied')
        self.assertEqual(rti_outcome(self.app(rejected_date=day, rejection_reason='x')), 'Rejected')
        self.assertEqual(rti_outcome(self.app(transferred_to='DIG office')), 'Transferred')
        self.assertIsNone(rti_outcome(self.app()))
        self.assertIsNone(rti_outcome(self.app(transferred_to='   ')))
