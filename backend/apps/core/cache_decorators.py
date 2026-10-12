"""
View Decorators for Upstash Redis Response Caching & Invalidation in PMS-App Backend.
"""

from functools import wraps
from rest_framework.response import Response
from apps.core.cache import upstash_cache


def cache_response(ttl: int = 300, key_prefix: str = ""):
    """
    Decorator for DRF APIViews and ViewSets to cache GET responses in Upstash Redis
    with Stampede protection and tenant scoping.
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(self_or_request, *args, **kwargs):
            request = getattr(self_or_request, 'request', self_or_request)

            # Only cache GET requests
            if request.method != 'GET':
                return view_func(self_or_request, *args, **kwargs)

            # Determine Tenant / State Code Scoping
            tenant_code = getattr(request, 'tenant', 'public')
            if not tenant_code or tenant_code == 'public':
                state_hdr = request.headers.get('X-State-Code') or request.META.get('HTTP_X_STATE_CODE')
                if state_hdr:
                    tenant_code = state_hdr.upper()
                elif hasattr(request, 'user') and hasattr(request.user, 'state_code'):
                    tenant_code = getattr(request.user, 'state_code', 'public')

            # Build Unique Cache Key
            path = request.path.strip('/')
            query = request.META.get('QUERY_STRING', '')
            prefix = key_prefix or path.replace('/', ':')
            cache_key = f"pms:cache:{tenant_code}:{prefix}:{query}"

            def fetch_data():
                response = view_func(self_or_request, *args, **kwargs)
                if isinstance(response, Response) and 200 <= response.status_code < 300:
                    return response.data
                return None

            cached_data = upstash_cache.get_or_set_stampede_proof(
                key=cache_key,
                callback_fn=fetch_data,
                ttl=ttl
            )

            if cached_data is not None:
                return Response(cached_data)

            # Direct fallback if data is None
            return view_func(self_or_request, *args, **kwargs)

        return _wrapped_view
    return decorator


def invalidate_tenant_cache(tenant_code: str, entity_name: str = ""):
    """Helper to delete cached keys for a specific state tenant and entity."""
    pattern = f"pms:cache:{tenant_code}:*"
    if entity_name:
        pattern = f"pms:cache:{tenant_code}:*{entity_name}*"
    return upstash_cache.delete_pattern(pattern)
