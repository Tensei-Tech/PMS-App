"""Tests for request timing, database connection reuse and Gunicorn settings."""
import runpy
from pathlib import Path
from unittest import mock

from django.http import HttpResponse
from django.test import RequestFactory, SimpleTestCase, TestCase

from apps.core.timing_middleware import RequestTimingMiddleware
from apps.public_master.models import StateRegistry
from config.db_connections import apply_conn_max_age, conn_max_age_for

BACKEND_DIR = Path(__file__).resolve().parents[2]


class ConnMaxAgeTests(SimpleTestCase):
    def test_default_reuses_connections_for_60_seconds(self):
        self.assertEqual(conn_max_age_for('5432', env={}), 60)

    def test_env_override(self):
        self.assertEqual(conn_max_age_for('5432', env={'DB_CONN_MAX_AGE': '120'}), 120)
        self.assertEqual(conn_max_age_for('5432', env={'DB_CONN_MAX_AGE': '0'}), 0)

    def test_bad_value_falls_back_to_default(self):
        with mock.patch('sys.stderr'):
            self.assertEqual(conn_max_age_for('5432', env={'DB_CONN_MAX_AGE': 'abc'}), 60)

    def test_transaction_pooler_never_reuses_connections(self):
        # Reuse there could carry one tenant's search_path into another's queries.
        with mock.patch('sys.stderr'):
            self.assertEqual(conn_max_age_for('6543', env={}), 0)
            self.assertEqual(conn_max_age_for(6543, env={'DB_CONN_MAX_AGE': '300'}), 0)

    def test_apply_only_touches_postgresql(self):
        databases = {
            'default': {'ENGINE': 'django.db.backends.postgresql', 'PORT': '5432', 'CONN_MAX_AGE': 0},
            'replica_1': {'ENGINE': 'django.db.backends.postgresql', 'PORT': '6543', 'CONN_MAX_AGE': 0},
            'scratch': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': ':memory:'},
        }
        with mock.patch('sys.stderr'):
            apply_conn_max_age(databases, env={})
        self.assertEqual(databases['default']['CONN_MAX_AGE'], 60)
        self.assertEqual(databases['replica_1']['CONN_MAX_AGE'], 0)
        self.assertNotIn('CONN_MAX_AGE', databases['scratch'])


class GunicornConfigTests(SimpleTestCase):
    def _load(self, env):
        with mock.patch.dict('os.environ', env, clear=True):
            return runpy.run_path(str(BACKEND_DIR / 'gunicorn.conf.py'))

    def test_defaults_serve_requests_concurrently(self):
        conf = self._load({})
        self.assertEqual(conf['worker_class'], 'gthread')
        self.assertEqual(conf['workers'], 2)
        self.assertEqual(conf['threads'], 4)
        self.assertEqual(conf['timeout'], 60)

    def test_values_come_from_environment(self):
        conf = self._load({'WEB_CONCURRENCY': '1', 'GUNICORN_THREADS': '8', 'GUNICORN_TIMEOUT': '90'})
        self.assertEqual((conf['workers'], conf['threads'], conf['timeout']), (1, 8, 90))

    def test_procfile_uses_config(self):
        self.assertIn('-c gunicorn.conf.py', (BACKEND_DIR / 'Procfile').read_text())


class RequestTimingMiddlewareTests(TestCase):
    def test_reports_time_and_query_count(self):
        def view(request):
            StateRegistry.objects.count()
            StateRegistry.objects.exists()
            return HttpResponse('ok')

        middleware = RequestTimingMiddleware(view)
        with self.assertLogs('apps.core.timing', level='INFO') as logs:
            response = middleware(RequestFactory().get('/api/cases/'))

        self.assertIn('desc="2 queries"', response['Server-Timing'])
        self.assertRegex(response['Server-Timing'], r'^app;dur=\d+, db;dur=\d+')
        self.assertIn('[Timing] GET /api/cases/ 200', logs.output[0])
        self.assertIn('db=2q/', logs.output[0])

    def test_slow_request_logged_as_warning(self):
        middleware = RequestTimingMiddleware(lambda request: HttpResponse('ok'))
        with mock.patch('apps.core.timing_middleware.SLOW_REQUEST_MS', 0), \
                self.assertLogs('apps.core.timing', level='WARNING') as logs:
            middleware(RequestFactory().get('/'))
        self.assertTrue(logs.output[0].startswith('WARNING'))
