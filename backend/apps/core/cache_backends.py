"""
Django cache backend for the shared Upstash Redis.

Django's own RedisCache raises when Redis is slow or unreachable, which would
turn a cache problem into failed requests. SafeRedisCache treats any Redis or
network error as an empty cache instead: reads return the default, writes are
skipped, and Redis is not tried again for BACKOFF_SECONDS so requests do not
each wait for the socket timeout.

clear() deletes only keys under KEY_PREFIX instead of FLUSHDB, because the
Upstash database may hold other data (and other environments' keys).
"""
import logging
import time

from django.core.cache.backends.base import DEFAULT_TIMEOUT
from django.core.cache.backends.redis import RedisCache
from redis.exceptions import RedisError

logger = logging.getLogger(__name__)

BACKOFF_SECONDS = 30
_SCAN_BATCH = 500


class SafeRedisCache(RedisCache):
    # Shared by every instance in the process: one failure pauses Redis for all threads.
    _down_until = 0.0

    @classmethod
    def _is_down(cls):
        return time.monotonic() < cls._down_until

    @classmethod
    def _mark_down(cls, operation, exc):
        cls._down_until = time.monotonic() + BACKOFF_SECONDS
        logger.warning("[Cache] Redis %s failed (%s); serving without cache for %ss",
                       operation, type(exc).__name__, BACKOFF_SECONDS)

    def _safe(self, operation, default, call):
        if self._is_down():
            return default
        try:
            return call()
        except (RedisError, OSError) as exc:
            self._mark_down(operation, exc)
            return default

    def get(self, key, default=None, version=None):
        return self._safe('get', default, lambda: super(SafeRedisCache, self).get(key, default, version))

    def get_many(self, keys, version=None):
        return self._safe('get_many', {}, lambda: super(SafeRedisCache, self).get_many(keys, version))

    def has_key(self, key, version=None):
        return self._safe('has_key', False, lambda: super(SafeRedisCache, self).has_key(key, version))

    def set(self, key, value, timeout=DEFAULT_TIMEOUT, version=None):
        return self._safe('set', None, lambda: super(SafeRedisCache, self).set(key, value, timeout, version))

    def set_many(self, data, timeout=DEFAULT_TIMEOUT, version=None):
        return self._safe('set_many', list(data),
                          lambda: super(SafeRedisCache, self).set_many(data, timeout, version))

    def add(self, key, value, timeout=DEFAULT_TIMEOUT, version=None):
        return self._safe('add', False, lambda: super(SafeRedisCache, self).add(key, value, timeout, version))

    def touch(self, key, timeout=DEFAULT_TIMEOUT, version=None):
        return self._safe('touch', False, lambda: super(SafeRedisCache, self).touch(key, timeout, version))

    def delete(self, key, version=None):
        return self._safe('delete', False, lambda: super(SafeRedisCache, self).delete(key, version))

    def delete_many(self, keys, version=None):
        return self._safe('delete_many', None, lambda: super(SafeRedisCache, self).delete_many(keys, version))

    def incr(self, key, delta=1, version=None):
        # Missing key -> ValueError, as Django documents; an unreachable Redis looks the same.
        if self._is_down():
            raise ValueError(f"Key '{key}' not found (cache unavailable)")
        try:
            return super().incr(key, delta, version)
        except (RedisError, OSError) as exc:
            self._mark_down('incr', exc)
            raise ValueError(f"Key '{key}' not found (cache unavailable)") from exc

    def clear(self):
        """Delete this app's keys only (KEY_PREFIX); never FLUSHDB the shared database."""
        if not self.key_prefix:
            logger.warning("[Cache] clear() skipped: no KEY_PREFIX, refusing to wipe the whole Redis database")
            return False
        self._scan_delete(f'{self.key_prefix}:*')
        return True

    def delete_pattern(self, pattern, version=None):
        """Delete keys matching a glob pattern of logical keys, e.g. 'pms:cache:MH:*'."""
        return self._scan_delete(self.make_key(pattern, version=version))

    def _scan_delete(self, match):
        if self._is_down():
            return 0
        try:
            client = self._cache.get_client(write=True)
            deleted, batch = 0, []
            for redis_key in client.scan_iter(match=match, count=_SCAN_BATCH):
                batch.append(redis_key)
                if len(batch) >= _SCAN_BATCH:
                    deleted += client.delete(*batch)
                    batch = []
            if batch:
                deleted += client.delete(*batch)
            return deleted
        except (RedisError, OSError) as exc:
            self._mark_down('delete_pattern', exc)
            return 0
