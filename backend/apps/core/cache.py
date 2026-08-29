"""
Upstash Redis Cache Manager for PMS-App Backend.
Provides high-performance caching, Cache Stampede (Dogpile) protection, TTL jittering,
and dual REST/TCP Upstash connection with automatic database fallback.
"""

import json
import logging
import random
import time
from typing import Any, Callable, Optional, List
from django.conf import settings
from django.core.cache import cache
import requests

logger = logging.getLogger(__name__)


class UpstashRedisManager:
    """
    Stampede-proof Redis Cache Manager supporting Upstash REST API and Django Cache Framework.
    """

    def __init__(self):
        self.rest_url = getattr(settings, 'UPSTASH_REDIS_REST_URL', 'https://mature-eel-202638.upstash.io')
        self.rest_token = getattr(settings, 'UPSTASH_REDIS_REST_TOKEN', '')
        self.headers = {
            'Authorization': f'Bearer {self.rest_token}',
            'Content-Type': 'application/json',
        }

    def _apply_jitter(self, ttl: int) -> int:
        """Adds +/- 10% random jitter to TTL to prevent synchronized key expirations."""
        if ttl <= 0:
            return ttl
        jitter_factor = random.uniform(0.9, 1.1)
        return max(1, int(ttl * jitter_factor))

    def get(self, key: str) -> Optional[Any]:
        """Fetch value from cache with REST fallback."""
        try:
            val = cache.get(key)
            if val is not None:
                return val
        except Exception as e:
            logger.warning(f"[Cache GET Error] Django cache failed for key '{key}': {e}")

        # REST API Fallback
        if self.rest_url and self.rest_token:
            try:
                resp = requests.post(
                    f"{self.rest_url}/get/{key}",
                    headers=self.headers,
                    timeout=2.0
                )
                if resp.status_code == 200:
                    data = resp.json()
                    result = data.get('result')
                    if result is not None:
                        try:
                            return json.loads(result)
                        except (json.JSONDecodeError, TypeError):
                            return result
            except Exception as re:
                logger.warning(f"[Upstash REST GET Error] REST fallback failed for key '{key}': {re}")

        return None

    def set(self, key: str, value: Any, ttl: int = 300, apply_jitter: bool = True) -> bool:
        """Store value in cache with TTL jittering."""
        final_ttl = self._apply_jitter(ttl) if apply_jitter else ttl
        success = False

        try:
            cache.set(key, value, timeout=final_ttl)
            success = True
        except Exception as e:
            logger.warning(f"[Cache SET Error] Django cache set failed for key '{key}': {e}")

        # Sync to Upstash REST API if Django cache fails or for REST consistency
        if not success and self.rest_url and self.rest_token:
            try:
                serialized = json.dumps(value) if not isinstance(value, (str, int, float)) else str(value)
                payload = ["SET", key, serialized, "EX", str(final_ttl)]
                resp = requests.post(
                    self.rest_url,
                    json=payload,
                    headers=self.headers,
                    timeout=2.0
                )
                if resp.status_code == 200:
                    success = True
            except Exception as re:
                logger.warning(f"[Upstash REST SET Error] REST set failed for key '{key}': {re}")

        return success

    def delete(self, key: str) -> bool:
        """Delete key from cache."""
        try:
            cache.delete(key)
        except Exception as e:
            logger.warning(f"[Cache DELETE Error] Django cache delete failed for key '{key}': {e}")

        if self.rest_url and self.rest_token:
            try:
                requests.post(
                    f"{self.rest_url}/del/{key}",
                    headers=self.headers,
                    timeout=2.0
                )
            except Exception:
                pass

        return True

    def delete_pattern(self, pattern: str) -> int:
        """Invalidate keys matching pattern (e.g. 'pms:cache:MH:*')."""
        deleted_count = 0
        try:
            if hasattr(cache, 'delete_pattern'):
                deleted_count = cache.delete_pattern(pattern)
            else:
                keys = cache.keys(pattern) if hasattr(cache, 'keys') else []
                for k in keys:
                    cache.delete(k)
                    deleted_count += 1
        except Exception as e:
            logger.warning(f"[Cache DELETE_PATTERN Error] Pattern delete failed for '{pattern}': {e}")

        # REST API Pattern Search & Delete
        if self.rest_url and self.rest_token:
            try:
                search_pattern = pattern if '*' in pattern else f"{pattern}*"
                resp = requests.post(
                    self.rest_url,
                    json=["KEYS", search_pattern],
                    headers=self.headers,
                    timeout=2.0
                )
                if resp.status_code == 200:
                    keys = resp.json().get('result', [])
                    if keys and isinstance(keys, list):
                        del_resp = requests.post(
                            self.rest_url,
                            json=["DEL"] + keys,
                            headers=self.headers,
                            timeout=2.0
                        )
                        if del_resp.status_code == 200:
                            deleted_count = max(deleted_count, len(keys))
            except Exception as re:
                logger.warning(f"[Upstash REST DELETE_PATTERN Error] REST pattern delete failed: {re}")

        return deleted_count

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
