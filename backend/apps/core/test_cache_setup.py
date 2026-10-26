"""
Shared cache setup: Upstash Redis must never break requests or wipe the shared
database, tests must never use it, and cached responses must never cross users.
"""
from pathlib import Path
from unittest import mock

from django.conf import settings
from django.core.cache import cache
from django.test import RequestFactory, SimpleTestCase
from rest_framework.response import Response
from rest_framework.test import force_authenticate
from rest_framework.views import APIView

from apps.core.cache_backends import SafeRedisCache
from apps.core.cache_decorators import cache_response

UNREACHABLE = 'redis://127.0.0.1:1/0'  # nothing listens on port 1: connection refused at once


def _redis_cache(location=UNREACHABLE, prefix='pms'):
    return SafeRedisCache(location, {
        'KEY_PREFIX': prefix,
        'OPTIONS': {'socket_connect_timeout': 0.5, 'socket_timeout': 0.5},
    })


class SafeRedisCacheTests(SimpleTestCase):
    def setUp(self):
        SafeRedisCache._down_until = 0.0

    def tearDown(self):
        SafeRedisCache._down_until = 0.0

    def test_unreachable_redis_behaves_like_an_empty_cache(self):
        c = _redis_cache()
        with self.assertLogs('apps.core.cache_backends', level='WARNING'):
            self.assertEqual(c.get('k', 'default'), 'default')
        self.assertIsNone(c.set('k', 'v'))
        self.assertFalse(c.add('lock', '1'))
        self.assertFalse(c.delete('k'))
        self.assertEqual(c.get_many(['a', 'b']), {})
        with self.assertRaises(ValueError):
            c.incr('counter')

    def test_after_a_failure_redis_is_paused_instead_of_timing_out_each_call(self):
        c = _redis_cache()
        with self.assertLogs('apps.core.cache_backends', level='WARNING'):
            c.get('k')
        with mock.patch('django.core.cache.backends.redis.RedisCache.get') as real_get:
            self.assertIsNone(c.get('k'))
            real_get.assert_not_called()

    def _with_fake_client(self, c, keys):
        client = mock.MagicMock()
        client.scan_iter.return_value = iter(keys)
        client.delete.return_value = len(keys)
        fake = mock.MagicMock()
        fake.get_client.return_value = client
        c.__dict__['_cache'] = fake  # RedisCache._cache is a cached_property
        return client

    def test_clear_deletes_only_this_apps_keys_and_never_flushes(self):
        c = _redis_cache()
        client = self._with_fake_client(c, [b'pms:1:a', b'pms:1:b'])
        self.assertTrue(c.clear())
        client.scan_iter.assert_called_once_with(match='pms:*', count=500)
        client.delete.assert_called_once_with(b'pms:1:a', b'pms:1:b')
        client.flushdb.assert_not_called()
        client.flushall.assert_not_called()

    def test_clear_without_prefix_refuses(self):
        c = _redis_cache(prefix='')
        client = self._with_fake_client(c, [b'x'])
        with self.assertLogs('apps.core.cache_backends', level='WARNING'):
            self.assertFalse(c.clear())
        client.scan_iter.assert_not_called()
        client.flushdb.assert_not_called()

    def test_delete_pattern_matches_prefixed_keys(self):
        c = _redis_cache()
        client = self._with_fake_client(c, [b'pms:1:pms:cache:MH:x'])
        self.assertEqual(c.delete_pattern('pms:cache:MH:*'), 1)
        client.scan_iter.assert_called_once_with(match='pms:1:pms:cache:MH:*', count=500)


class CacheSettingsTests(SimpleTestCase):
    def test_tests_never_use_the_shared_redis(self):
        self.assertEqual(settings.CACHES['default']['BACKEND'],
                         'django.core.cache.backends.locmem.LocMemCache')

    def test_no_upstash_address_or_token_written_in_code(self):
        backend = Path(settings.BASE_DIR)
        for rel in ('config/settings.py', 'apps/core/cache.py'):
            text = (backend / rel).read_text(encoding='utf-8')
            self.assertNotIn('upstash.io', text, rel)
        self.assertIn("os.getenv('REDIS_URL', '')", (backend / 'config/settings.py').read_text(encoding='utf-8'))


class _WhoAmI(APIView):
    calls = 0

    @cache_response(ttl=60, key_prefix="test:whoami")
    def get(self, request):
        _WhoAmI.calls += 1
        return Response({'uid': request.user.uid})


class _Reference(APIView):
    calls = 0

    @cache_response(ttl=60, key_prefix="test:reference", per_user=False)
    def get(self, request):
        _Reference.calls += 1
        return Response({'value': 'same for everyone', 'call': _Reference.calls})


class _Denied(APIView):
    calls = 0

    @cache_response(ttl=60, key_prefix="test:denied")
    def get(self, request):
        _Denied.calls += 1
        return Response({'error': 'no'}, status=403)


class _User:
    is_anonymous = False
    is_authenticated = True

    def __init__(self, uid):
        self.uid = uid
        self.state_code = 'MH'


class CacheResponseScopeTests(SimpleTestCase):
    def setUp(self):
        cache.clear()
        self.factory = RequestFactory()
        _WhoAmI.calls = _Reference.calls = _Denied.calls = 0

    def tearDown(self):
        cache.clear()

    def _get(self, view, uid):
        request = self.factory.get('/api/test/', HTTP_X_STATE_CODE='MH')
        force_authenticate(request, user=_User(uid))
        return view.as_view()(request)

    def test_users_never_receive_each_others_cached_response(self):
        self.assertEqual(self._get(_WhoAmI, 'officer-a').data['uid'], 'officer-a')
        self.assertEqual(self._get(_WhoAmI, 'officer-b').data['uid'], 'officer-b')
        self.assertEqual(self._get(_WhoAmI, 'officer-a').data['uid'], 'officer-a')
        self.assertEqual(_WhoAmI.calls, 2)  # second call for officer-a came from the cache

    def test_reference_data_is_shared(self):
        first = self._get(_Reference, 'officer-a').data
        second = self._get(_Reference, 'officer-b').data
        self.assertEqual(first, second)
        self.assertEqual(_Reference.calls, 1)

    def test_error_responses_are_not_cached_and_view_runs_once(self):
        response = self._get(_Denied, 'officer-a')
        self.assertEqual(response.status_code, 403)
        self.assertEqual(_Denied.calls, 1)
