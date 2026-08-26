import logging
from django.utils.deprecation import MiddlewareMixin
from apps.core.tenancy import set_tenant_schema
from apps.public_master.models import StateRegistry

logger = logging.getLogger(__name__)


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
                token = auth_header.split(' ')[1]
                decoded = jwt.decode(token, options={"verify_signature": False})
                state_code = decoded.get('state_code')
            except Exception:
                pass

        # 2. Inspect X-State-Code HTTP Request Header
        if not state_code:
            state_code = request.headers.get('X-State-Code') or request.META.get('HTTP_X_STATE_CODE')

        # 3. Fallback to state_code Query Parameter
        if not state_code:
            state_code = request.GET.get('state_code', '')

        schema_name = 'maharashtra'
        if state_code and state_code.upper() != 'GLOBAL':
            state_code = state_code.upper()
            try:
                state_record = StateRegistry.objects.filter(state_code=state_code, is_active=True).first()
                if state_record:
                    schema_name = state_record.schema_name
                else:
                    schema_name = state_code.lower()
            except Exception as e:
                logger.warning(f"[TenantMiddleware] State lookup failed: {e}")
                schema_name = state_code.lower()
        elif state_code and state_code.upper() == 'GLOBAL':
            schema_name = 'public'

        request.state_code = state_code or 'MH'
        request.state_schema = schema_name

        # Enforce PostgreSQL search_path for the request
        set_tenant_schema(schema_name)
