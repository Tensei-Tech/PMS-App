"""
Cache manager for PMS-App Backend: stampede (dogpile) protection, TTL jitter
and pattern invalidation on top of Django's cache.

Django's cache is the shared Upstash Redis when REDIS_URL is set (see
CACHES in config/settings.py and apps/core/cache_backends.py), and
per-process memory otherwise. This module no longer calls the Upstash REST
API itself: values were only written to local memory, so every REST lookup
missed and only added a network round trip.
"""

import fnmatch
import logging
import random
import time
from typing import Any, Callable, Optional

from django.core.cache import cache

logger = logging.getLogger(__name__)


class UpstashRedisManager:
    """Stampede-proof helpers over Django's configured cache."""

    def _apply_jitter(self, ttl: int) -> int:
        """Adds +/- 10% random jitter to TTL to prevent synchronized key expirations."""
        if ttl <= 0:
            return ttl
        jitter_factor = random.uniform(0.9, 1.1)
        return max(1, int(ttl * jitter_factor))

    def get(self, key: str) -> Optional[Any]:
        try:
            return cache.get(key)
        except Exception as e:
            logger.warning(f"[Cache GET Error] key '{key}': {type(e).__name__}")
            return None

    def set(self, key: str, value: Any, ttl: int = 300, apply_jitter: bool = True) -> bool:
        """Store value with TTL jitter. Returns False if it could not be stored (e.g. not picklable)."""
        final_ttl = self._apply_jitter(ttl) if apply_jitter else ttl
        try:
            cache.set(key, value, timeout=final_ttl)
            return True
        except Exception as e:
            logger.warning(f"[Cache SET Error] key '{key}': {type(e).__name__}")
            return False

    def delete(self, key: str) -> bool:
        try:
            cache.delete(key)
        except Exception as e:
            logger.warning(f"[Cache DELETE Error] key '{key}': {type(e).__name__}")
        return True

    def delete_pattern(self, pattern: str) -> int:
        """Invalidate keys matching a glob pattern (e.g. 'pms:cache:MH:*')."""
        try:
            if hasattr(cache, 'delete_pattern'):
                # SafeRedisCache: SCAN + DEL of matching keys
                return cache.delete_pattern(pattern)
            if hasattr(cache, '_cache'):
                # LocMemCache: stored keys carry Django's prefix and version
                deleted = 0
                for k in list(cache._cache.keys()):
                    if fnmatch.fnmatch(k, f"*{pattern}") or fnmatch.fnmatch(k, f"*{pattern}*"):
                        if hasattr(cache, '_delete'):
                            cache._delete(k)
                        else:
                            cache._cache.pop(k, None)
                            if hasattr(cache, '_expire_info'):
                                cache._expire_info.pop(k, None)
                        deleted += 1
                return deleted
        except Exception as e:
            logger.warning(f"[Cache DELETE_PATTERN Error] pattern '{pattern}': {type(e).__name__}")
        return 0

    def get_or_set_stampede_proof(
        self,
        key: str,
        callback_fn: Callable[[], Any],
        ttl: int = 300,
        lock_timeout: int = 5
    ) -> Any:
        """
        Retrieves data from cache or computes it safely using a distributed mutex lock to prevent Cache Stampede.
        """
        # 1. Attempt Cache Read
        cached_val = self.get(key)
        if cached_val is not None:
            return cached_val

        # 2. Acquire Mutex Lock (Dogpile Lock)
        lock_key = f"lock:{key}"
        acquired_lock = False

        try:
            acquired_lock = cache.add(lock_key, "1", timeout=lock_timeout)
        except Exception:
            acquired_lock = True  # Fallback if lock addition raises error

        if acquired_lock:
            try:
                # Double-check cache in case winning thread wrote just before lock acquire
                cached_val = self.get(key)
                if cached_val is not None:
                    return cached_val

                # Execute DB query / expensive operation
                data = callback_fn()

                # Save to cache with jittered TTL
                if data is not None:
                    self.set(key, data, ttl=ttl)

                return data
            finally:
                try:
                    cache.delete(lock_key)
                except Exception:
                    pass
        else:
            # Another thread is computing the key. Wait briefly and retry cache read up to 3 times.
            for _ in range(3):
                time.sleep(0.05)  # 50ms wait
                cached_val = self.get(key)
                if cached_val is not None:
                    return cached_val

            # If still missing after waiting, compute fallback directly
            return callback_fn()


# Global Singleton Instance
upstash_cache = UpstashRedisManager()
