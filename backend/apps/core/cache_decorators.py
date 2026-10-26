"""
View Decorators for Upstash Redis Response Caching & Invalidation in PMS-App Backend.
"""

from functools import wraps
from rest_framework.response import Response
from apps.core.cache import upstash_cache


def _user_scope(request):
    """Cache scope of the caller: their uid, or 'anon' before login."""
    user = getattr(request, 'user', None)
    is_anon = getattr(user, 'is_anonymous', True)
    if callable(is_anon):
        is_anon = is_anon()
    if not user or is_anon:
        return 'anon'
    uid = getattr(user, 'uid', None) or getattr(user, 'pk', None) or getattr(user, 'id', None)
    return f"u:{uid}" if uid else 'anon'


def cache_response(ttl: int = 300, key_prefix: str = "", per_user: bool = True):
    """
    Decorator for DRF APIViews and ViewSets to cache GET responses in Upstash Redis
    with Stampede protection and tenant scoping.

    per_user=True (default) keys the cache by the logged-in user, so one user
    never receives another user's response (case lists, counts, permissions
    depend on who asks). Pass per_user=False only for reference data that is
    the same for everyone and depends only on the URL and query string.
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(self_or_request, *args, **kwargs):
            request = getattr(self_or_request, 'request', self_or_request)

            # Only cache GET requests
            if request.method != 'GET':
                return view_func(self_or_request, *args, **kwargs)

            # Determine Tenant / State Code Scoping
            tenant_code = getattr(request, 'state_schema', None) or getattr(request, 'tenant', 'public')
            if not tenant_code or tenant_code == 'public':
                state_hdr = request.headers.get('X-State-Code') or request.META.get('HTTP_X_STATE_CODE')
                if state_hdr:
                    tenant_code = state_hdr.upper()
                elif hasattr(request, 'user') and hasattr(request.user, 'state_code'):
                    tenant_code = getattr(request.user, 'state_code', 'public')

            # Build Unique Cache Key
            import re
            path = request.path.strip('/')
            query = request.META.get('QUERY_STRING', '')
            clean_query = re.sub(r'[\s:=]+', '_', query).strip('_')
            clean_path = path.replace('/', ':')
            prefix = f"{key_prefix}:{clean_path}" if key_prefix else clean_path
            scope = _user_scope(request) if per_user else 'shared'
            base = f"pms:cache:{tenant_code}:{scope}:{prefix}"
            cache_key = f"{base}:{clean_query}" if clean_query else base

            uncached = {}

            def fetch_data():
                response = view_func(self_or_request, *args, **kwargs)
                if isinstance(response, Response) and 200 <= response.status_code < 300:
                    return response.data
                uncached['response'] = response
                return None

            cached_data = upstash_cache.get_or_set_stampede_proof(
                key=cache_key,
                callback_fn=fetch_data,
                ttl=ttl
            )

            if cached_data is not None:
                return Response(cached_data)

            # Error responses are not cached; return the one already computed
            if 'response' in uncached:
                return uncached['response']
            return view_func(self_or_request, *args, **kwargs)

        return _wrapped_view
    return decorator


def invalidate_tenant_cache(tenant_code: str, entity_name: str = ""):
    """Helper to delete cached keys for a specific state tenant and entity."""
    pattern = f"pms:cache:{tenant_code}:*"
    if entity_name:
        pattern = f"pms:cache:{tenant_code}:*{entity_name}*"
    return upstash_cache.delete_pattern(pattern)
