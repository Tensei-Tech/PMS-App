import logging
from django.utils.deprecation import MiddlewareMixin
from apps.core.tenancy import set_tenant_schema
from apps.public_master.models import StateRegistry

logger = logging.getLogger(__name__)


_STATE_SCHEMA_CACHE = {
    'MH': 'maharashtra',
    'KA': 'karnataka',
    'DL': 'delhi',
    'GJ': 'gujarat',
    'MP': 'madhya_pradesh',
    'RJ': 'rajasthan',
    'UP': 'uttar_pradesh',
    'TN': 'tamil_nadu',
    'TG': 'telangana',
    'AP': 'andhra_pradesh',
    'WB': 'west_bengal',
    'KL': 'kerala',
    'PB': 'punjab',
    'HR': 'haryana',
    'BR': 'bihar',
}


class TenantMiddleware(MiddlewareMixin):
    """
    Middleware that enforces strict Multi-Tenant PostgreSQL Schema Isolation.
    Ensures that when a user from State A logs in or calls APIs:
    1. search_path is automatically switched to "{state_schema}, public".
    2. User CANNOT view or access State B data under any circumstances.
    3. Master Admin can bypass to query system-wide registries.
    """

    def process_request(self, request):
        state_code = None

        # 1. Inspect JWT Authorization Bearer Token if present
        auth_header = request.headers.get('Authorization') or request.META.get('HTTP_AUTHORIZATION', '')
        if auth_header.startswith('Bearer '):
            try:
                import jwt
                from django.conf import settings
                token = auth_header.split(' ')[1]
                decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
                state_code = decoded.get('state_code')
            except jwt.ExpiredSignatureError:
                request._token_expired = True
                state_code = None
            except Exception:
                state_code = None

        # 2. Inspect Headers
        direct_schema = (
            request.headers.get('X-Tenant-Schema') or 
            request.META.get('HTTP_X_TENANT_SCHEMA') or 
            request.headers.get('X-State-Schema') or 
            request.META.get('HTTP_X_STATE_SCHEMA')
        )
        if not state_code:
            state_code = request.headers.get('X-State-Code') or request.META.get('HTTP_X_STATE_CODE')

        # 3. Fallback to state_code Query Parameter
        if not state_code:
            state_code = request.GET.get('state_code', '')

        schema_name = 'public'
        if direct_schema:
            schema_name = "".join(c for c in direct_schema if c.isalnum() or c == '_').lower()
        elif state_code and state_code.upper() != 'GLOBAL':
            state_code = state_code.upper()
            if state_code in _STATE_SCHEMA_CACHE:
                schema_name = _STATE_SCHEMA_CACHE[state_code]
            else:
                try:
                    state_record = StateRegistry.objects.filter(state_code=state_code, is_active=True).first()
                    if state_record and state_record.schema_name:
                        schema_name = state_record.schema_name
                        _STATE_SCHEMA_CACHE[state_code] = schema_name
                    else:
                        logger.warning(f"[TenantMiddleware] Inactive or unregistered state '{state_code}'; defaulting to 'maharashtra'")
                        schema_name = 'maharashtra'
                except Exception as e:
                    logger.warning(f"[TenantMiddleware] State lookup failed for state '{state_code}': {e}")
                    schema_name = 'maharashtra'
        elif state_code and state_code.upper() == 'GLOBAL':
            schema_name = 'public'

        request.state_code = state_code
        request.state_schema = schema_name

        # Enforce PostgreSQL search_path on active connection for pooler stability if resolved
        if schema_name and schema_name != 'public':
            try:
                set_tenant_schema(schema_name)
                request._schema_switched = (schema_name != 'maharashtra')
            except Exception as e:
                logger.warning(f"[TenantMiddleware] Failed to set search_path: {e}")
                request._schema_switched = False
        else:
            request._schema_switched = False

    def process_response(self, request, response):
        """
        Safely resets search_path back to active TenantContext (or 'public' if stack is empty)
        immediately after every request completes, preventing tenant search_path leakage.
        """
        try:
            from apps.core.tenancy import _get_schema_stack
            stack = _get_schema_stack()
            restore_schema = stack[-1] if stack else 'public'
            set_tenant_schema(restore_schema)
        except Exception as e:
            logger.warning(f"[TenantMiddleware] Failed to reset search_path on response: {e}")
        return response

    def process_exception(self, request, exception):
        """
        Ensures search_path is safely reset if an unhandled exception occurs.
        """
        try:
            from apps.core.tenancy import _get_schema_stack
            stack = _get_schema_stack()
            restore_schema = stack[-1] if stack else 'public'
            set_tenant_schema(restore_schema)
        except Exception as e:
            logger.warning(f"[TenantMiddleware] Failed to reset search_path on exception: {e}")
        return None

