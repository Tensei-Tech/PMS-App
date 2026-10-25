"""Login must verify a password at most once: each check is a deliberately slow PBKDF2 hash."""
from unittest import mock

from django.contrib.auth.hashers import check_password as real_check_password
from django.core.cache import cache
from django.test import TestCase, override_settings
from rest_framework import status
from rest_framework.test import APIClient

from apps.authentication.views import _login_schema_cache_key
from apps.public_master.models import StateRegistry
from apps.users.models import OfficerProfile

EMAIL = 'speed.officer@mhpolice.gov.in'
PASSWORD = 'OfficerPassword123!'


# A fast hasher keeps the test quick; the number of checks is what matters.
@override_settings(PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'])
class LoginPasswordCheckCountTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        StateRegistry.objects.create(state_code='MH', state_name='Maharashtra', schema_name='maharashtra', is_active=True)
        StateRegistry.objects.create(state_code='GJ', state_name='Gujarat', schema_name='gujarat', is_active=True)
        self.officer = OfficerProfile(
            uid='officer-speed-1',
            name='Sub Inspector Speed',
            email=EMAIL,
            badge_number='MH-SPEED1',
            station_name='Shivajinagar Police Station',
            # SQLite has no per-state schemas, so the uid "exists" in every state;
            # the district name makes the state lookup resolve to MH deterministically.
            district='Pune, Maharashtra',
            account_status='active',
        )
        self.officer.set_password(PASSWORD)
        self.officer.save()

    def _login(self, password=PASSWORD, **extra):
        with mock.patch('apps.users.models.check_password', wraps=real_check_password) as counted:
            response = self.client.post(
                '/api/auth/login/', {'email': EMAIL, 'password': password, **extra}, format='json'
            )
        return response, counted.call_count

    def test_login_without_state_checks_password_once(self):
        # The app sends no state_code, so this is the common path.
        response, checks = self._login()
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['user']['state_code'], 'MH')
        self.assertEqual(checks, 1)

    def test_login_with_declared_state_checks_password_once(self):
        response, checks = self._login(state_code='MH')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(checks, 1)

    def test_wrong_password_is_rejected_with_one_check(self):
        response, checks = self._login(password='wrong-password')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(checks, 1)

    def test_pending_account_still_blocked(self):
        self.officer.account_status = 'pending_approval'
        self.officer.save()
        response, _ = self._login()
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_unknown_declared_state_still_rejected(self):
        response, checks = self._login(state_code='ZZ')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(checks, 0)

    def test_successful_login_remembers_state_schema(self):
        self._login()
        self.assertEqual(cache.get(_login_schema_cache_key(EMAIL)), 'maharashtra')

    def test_failed_login_does_not_remember_state(self):
        self._login(password='wrong-password')
        self.assertIsNone(cache.get(_login_schema_cache_key(EMAIL)))

    def test_remembered_schema_is_only_a_hint(self):
        # A stale or wrong hint must not let a bad password in.
        cache.set(_login_schema_cache_key(EMAIL), 'gujarat')
        response, _ = self._login(password='wrong-password')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
