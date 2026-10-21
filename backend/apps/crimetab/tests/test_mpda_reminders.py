import datetime

from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import force_authenticate

from apps.crimetab.models import ModuleSetting
from apps.crimetab.models.mpda import MpdaAccusedPerson, MpdaProposal
from apps.crimetab.tests.test_mpda_backend import DummyMpdaOfficerUser, MpdaBackendTestCase
from apps.crimetab.views_mpda import (
    MpdaDetentionRemindersView,
    MpdaRemindersSeenView,
    MpdaSendReminderView,
    MpdaSummaryView,
)
from apps.users.models import NotificationRecord, OfficerProfile


class MpdaDetentionReminderTests(TestCase):
    def setUp(self):
        MpdaBackendTestCase.setUp(self)
        for key, value in [('enforce_permissions', 'false'),
                           ('detention_reminder_first_days', '30'),
                           ('detention_reminder_second_days', '20'),
                           ('detention_reminder_daily_from_days', '10'),
                           ('detention_reminder_title', 'TEST Title'),
                           ('detention_reminder_message', 'TEST {proposal_no}|{accused}|{end_date}|{days_left}'),
                           ('manual_reminder_title', 'TEST Remind'),
                           ('manual_reminder_message', 'TEST {sender} {proposal_no} {days_left}'),
                           ('manual_reminder_sent_message', 'TEST sent to {count} of {station}'),
                           ('manual_reminder_no_officers_message', 'TEST no officers'),
                           ('manual_reminder_ended_message', 'TEST ended')]:
            ModuleSetting.objects.update_or_create(module_key='mpda', setting_key=key,
                                                   defaults={'setting_value': value})
        self.today = datetime.date.today()
        self.station = str(getattr(self.user, 'station_name', '') or '').strip()

    def _prop(self, no, end_in_days, station=None, detained='Yes', revoked=None, io_name=None):
        return MpdaProposal.objects.create(
            station_name=station or self.station, proposal_no_and_year=no, detained=detained,
            detention_order_revoked=revoked, io_name=io_name,
            detention_completion_date=self.today + datetime.timedelta(days=end_in_days))

    def _get(self, user=None):
        req = self.factory.get('/api/mpda/reminders/')
        force_authenticate(req, user=user or self.user)
        res = MpdaDetentionRemindersView.as_view()(req)
        self.assertEqual(res.status_code, 200)
        return res.data

    def _remind(self, pk):
        req = self.factory.post(f'/api/mpda/{pk}/remind/')
        force_authenticate(req, user=self.user)
        return MpdaSendReminderView.as_view()(req, pk=pk)

    def test_schedule_30_20_then_daily_from_10(self):
        due = self._prop('TEST 10', 10)
        MpdaAccusedPerson.objects.create(proposal=due, name='TEST Ravi', display_order=1)
        self._prop('TEST 0', 0)              # ends today: still reminded
        self._prop('TEST 5', 5)              # daily from 10 days
        self._prop('TEST 11', 11)            # between 20 and 10: no reminder
        self._prop('TEST 20', 20)            # second reminder
        self._prop('TEST 25', 25)            # between 30 and 20: no reminder
        self._prop('TEST 30', 30)            # first reminder
        self._prop('TEST 31', 31)            # too early
        self._prop('TEST -1', -1)            # already ended
        self._prop('TEST other', 5, station='TEST Other Station')
        self._prop('TEST not detained', 5, detained='No')
        self._prop('TEST revoked', 5, revoked='Yes')

        data = self._get()
        self.assertEqual([r['proposal_no'] for r in data['results']],
                         ['TEST 0', 'TEST 5', 'TEST 10', 'TEST 20', 'TEST 30'])
        self.assertEqual(data['days'], 30)
        row = data['results'][2]
        self.assertEqual((row['kind'], row['title'], row['days_left']), ('auto', 'TEST Title', 10))
        self.assertTrue(row['message'].startswith('TEST TEST 10|TEST Ravi|'))
        self.assertTrue(row['message'].endswith('|10'))

    def test_constant_queries(self):
        for i in range(5):
            p = self._prop(f'TEST {i}', i)
            MpdaAccusedPerson.objects.create(proposal=p, name=f'TEST A{i}', display_order=1)
        with CaptureQueriesContext(connection) as few:
            self._get()
        for i in range(5, 11):
            p = self._prop(f'TEST {i}', i)
            MpdaAccusedPerson.objects.create(proposal=p, name=f'TEST A{i}', display_order=1)
        with CaptureQueriesContext(connection) as many:
            self.assertEqual(self._get()['count'], 11)
        self.assertEqual(len(few), len(many))

    def _officer(self, uid, station_id='st_crime_hq', station_name='', status='active'):
        OfficerProfile.objects.update_or_create(
            uid=uid, defaults={'name': uid, 'email': f'{uid}@example.com', 'station_id': station_id,
                               'station_name': station_name, 'account_status': status})

    def test_reminder_goes_to_every_station_officer_until_end_date(self):
        self._officer('test_off_a')
        self._officer('test_off_b', station_id='', station_name=self.station)
        self._officer('test_off_other', station_id='st_other', station_name='TEST Other Station')
        self._officer('test_off_inactive', status='inactive')
        prop = self._prop('TEST R/1', 15, io_name='TEST Io, PSI')
        res = self._remind(prop.pk)
        self.assertEqual(res.status_code, 201, res.data)
        # officer_io_101 is the station's officer from the base setUp
        self.assertEqual(res.data['sent_to'], 3)
        self.assertEqual(res.data['message'], f'TEST sent to 3 of {self.station}')
        notes = NotificationRecord.objects.filter(category='mpda_reminder')
        self.assertEqual(sorted(notes.values_list('target_user_uid', flat=True)),
                         ['officer_io_101', 'test_off_a', 'test_off_b'])
        self.assertEqual({n.registration_uid for n in notes}, {str(prop.pk)})
        self.assertEqual(notes.first().body, 'TEST Inspector MPDA Test TEST R/1 15')

        # Each officer sees it with their reminders until they open them
        officer = DummyMpdaOfficerUser(uid='test_off_a')
        manual = [r for r in self._get(officer)['results'] if r['kind'] == 'manual']
        self.assertEqual([r['title'] for r in manual], ['TEST Remind'])
        req = self.factory.post('/api/mpda/reminders/seen/')
        force_authenticate(req, user=officer)
        self.assertEqual(MpdaRemindersSeenView.as_view()(req).data['updated'], 1)
        self.assertFalse([r for r in self._get(officer)['results'] if r['kind'] == 'manual'])

        # Summary offers the action only until the end date
        self._prop('TEST R/ended', -1)
        req = self.factory.get('/api/mpda/summary/')
        force_authenticate(req, user=self.user)
        flags = {r['proposal_no']: r['can_remind'] for r in MpdaSummaryView.as_view()(req).data['results']}
        self.assertEqual(flags, {'TEST R/1': True, 'TEST R/ended': False})

    def test_reminder_refused_after_end_date_revoked_or_without_officers(self):
        OfficerProfile.objects.filter(uid='officer_io_101').update(account_status='inactive')
        ended = self._prop('TEST E/1', -1)
        revoked = self._prop('TEST E/2', 5, revoked='Yes')
        no_officers = self._prop('TEST E/3', 5)
        for prop, msg in ((ended, 'TEST ended'), (revoked, 'TEST ended'), (no_officers, 'TEST no officers')):
            res = self._remind(prop.pk)
            self.assertEqual((res.status_code, res.data['error']), (400, msg))
        self.assertFalse(NotificationRecord.objects.filter(category='mpda_reminder').exists())
