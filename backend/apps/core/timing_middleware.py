"""
Logs how long each request took and how much of it was database work.

One line per request in the server log, e.g.
    [Timing] GET /api/cases/ 200 412ms db=9q/180ms
and a Server-Timing response header (visible in the browser's network tab).
Requests slower than SLOW_REQUEST_MS are logged as warnings.
"""
import logging
import os
import time

from django.db import connection

logger = logging.getLogger('apps.core.timing')

SLOW_REQUEST_MS = int(os.getenv('SLOW_REQUEST_MS', '1000'))


class _QueryStats:
    """execute_wrapper hook: counts queries and their time on this thread's connection."""

    def __init__(self):
        self.count = 0
        self.seconds = 0.0

    def __call__(self, execute, sql, params, many, context):
        start = time.perf_counter()
        try:
            return execute(sql, params, many, context)
        finally:
            self.count += 1
            self.seconds += time.perf_counter() - start


class RequestTimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        stats = _QueryStats()
        start = time.perf_counter()
        with connection.execute_wrapper(stats):
            response = self.get_response(request)
        total_ms = (time.perf_counter() - start) * 1000
        db_ms = stats.seconds * 1000

        response['Server-Timing'] = (
            f'app;dur={total_ms:.0f}, db;dur={db_ms:.0f};desc="{stats.count} queries"'
        )
        logger.log(
            logging.WARNING if total_ms >= SLOW_REQUEST_MS else logging.INFO,
            '[Timing] %s %s %s %.0fms db=%dq/%.0fms',
            request.method, request.path, response.status_code, total_ms, stats.count, db_ms,
        )
        return response
