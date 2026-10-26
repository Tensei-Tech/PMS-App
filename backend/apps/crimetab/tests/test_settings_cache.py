"""
Reminder endpoints are polled on every dashboard open. Their display settings
(reminder labels/days, yes value) are cached; permission checks are never
cached, so permission changes, even made directly in the database, apply at once.
"""
import jwt

from django.conf import settings
from django.core.cache import cache
from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from apps.crimetab import settings_cache
from apps.crimetab.models import ModuleSetting
from apps.public_master.models import Permission, Role, RolePermission, StateRegistry
from apps.users.models import OfficerProfile

RTI_URL = '/api/rti/reminders/'
MPDA_URL = '/api/mpda/reminders/'


class ReminderSettingsCacheTests(TestCase):
    def setUp(self):
        cache.clear()
        StateRegistry.objects.create(state_code='MH', state_name='Maharashtra', schema_name='maharashtra', is_active=True)
        self.role, _ = Role.objects.get_or_create(id='officer', defaults={'name': 'Officer', 'level': 'station'})
        for pid in ('rti:view', 'mpda:view'):
            perm, _ = Permission.objects.get_or_create(id=pid, defaults={'module': pid.split(':')[0]})
            RolePermission.objects.get_or_create(role=self.role, permission=perm, defaults={'is_granted': True})
        OfficerProfile.objects.create(uid='cache-1', email='cache@x.in', name='C',
                                      station_name='Shivajinagar', account_status='active')
        for module in ('rti', 'mpda'):
            ModuleSetting.objects.update_or_create(module_key=module, setting_key='enforce_permissions',
                                                   defaults={'setting_value': 'true'})
        token = jwt.encode({'uid': 'cache-1', 'state_code': 'MH', 'user_type': 'officer'},
                           settings.SECRET_KEY, algorithm='HS256')
        self.client = APIClient()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}', HTTP_X_STATE_CODE='MH')

    def tearDown(self):
        cache.clear()

    def _data_queries(self, url):
        """SQL of one request, without SET search_path (PostgreSQL counts those, SQLite runs none)."""
        with CaptureQueriesContext(connection) as ctx:
            self.assertEqual(self.client.get(url).status_code, 200)
        return [q['sql'] for q in ctx.captured_queries if not q['sql'].lstrip().upper().startswith('SET ')]

    def test_warm_rti_reminders_read_settings_from_cache(self):
        self.client.get(RTI_URL)
        sql = self._data_queries(RTI_URL)
        # Live permission check (enforce flag + role grant), then applications + manual notifications.
        self.assertEqual(len(sql), 4, sql)
        self.assertEqual(sum('module_settings' in q for q in sql), 1, 'only the live enforce flag')

    def test_warm_mpda_reminders_read_settings_from_cache(self):
        self.client.get(MPDA_URL)
        sql = self._data_queries(MPDA_URL)
        self.assertEqual(len(sql), 4, sql)
        self.assertEqual(sum('module_settings' in q for q in sql), 1, 'only the live enforce flag')
        self.assertFalse(any('option_values' in q for q in sql), 'yes value comes from cache')

    def test_permission_change_made_without_signals_applies_immediately(self):
        # A bulk update (or an edit straight in the database) fires no signal;
        # permission checks must still see it on the next request.
        ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').update(setting_value='false')
        RolePermission.objects.filter(role=self.role, permission_id='rti:view').update(is_granted=False)
        self.assertEqual(self.client.get(RTI_URL).status_code, 200)
        ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').update(setting_value='true')
        self.assertEqual(self.client.get(RTI_URL).status_code, 403)

    def test_revoked_permission_applies_on_the_next_request(self):
        self.assertEqual(self.client.get(RTI_URL).status_code, 200)
        RolePermission.objects.filter(role=self.role, permission_id='rti:view').delete()
        self.assertEqual(self.client.get(RTI_URL).status_code, 403)

    def test_enforce_flag_change_applies_on_the_next_request(self):
        RolePermission.objects.filter(role=self.role, permission_id='mpda:view').delete()
        self.assertEqual(self.client.get(MPDA_URL).status_code, 403)
        setting = ModuleSetting.objects.get(module_key='mpda', setting_key='enforce_permissions')
        setting.setting_value = 'false'
        setting.save()
        self.assertEqual(self.client.get(MPDA_URL).status_code, 200)

    def test_reminder_setting_change_applies_on_the_next_request(self):
        ModuleSetting.objects.update_or_create(module_key='rti', setting_key='reminder_tab_label',
                                               defaults={'setting_value': 'Old'})
        self.assertEqual(self.client.get(RTI_URL).data['labels']['tab'], 'Old')
        ModuleSetting.objects.update_or_create(module_key='rti', setting_key='reminder_tab_label',
                                               defaults={'setting_value': 'New'})
        self.assertEqual(self.client.get(RTI_URL).data['labels']['tab'], 'New')


class SettingsCacheUnitTests(TestCase):
    def tearDown(self):
        cache.clear()

    def test_computes_once_until_invalidated(self):
        calls = []

        def compute():
            calls.append(1)
            return len(calls)

        self.assertEqual(settings_cache.cached(('unit', 'a'), compute), 1)
        self.assertEqual(settings_cache.cached(('unit', 'a'), compute), 1)
        settings_cache.invalidate()
        self.assertEqual(settings_cache.cached(('unit', 'a'), compute), 2)

    def test_keys_are_separate_per_schema(self):
        self.assertEqual(settings_cache.cached(('unit', 'maharashtra'), lambda: 'mh'), 'mh')
        self.assertEqual(settings_cache.cached(('unit', 'gujarat'), lambda: 'gj'), 'gj')

    def test_falsy_values_are_cached(self):
        calls = []
        settings_cache.cached(('unit', 'falsy'), lambda: calls.append(1) or False)
        settings_cache.cached(('unit', 'falsy'), lambda: calls.append(1) or False)
        self.assertEqual(len(calls), 1)
