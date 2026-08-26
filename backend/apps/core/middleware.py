import logging
from django.utils.deprecation import MiddlewareMixin
from apps.core.tenancy import set_tenant_schema
from apps.public_master.models import StateRegistry

logger = logging.getLogger(__name__)


class TenantMiddleware(MiddlewareMixin):
    """
    Middleware that inspects incoming HTTP request headers ('X-State-Code') or token context
    and switches PostgreSQL search_path to the appropriate state schema (e.g., 'maharashtra, public').
    """

    def process_request(self, request):
        state_code = request.headers.get('X-State-Code') or request.META.get('HTTP_X_STATE_CODE')

        # Fallback to query parameter if header not present
        if not state_code:
            state_code = request.GET.get('state_code', 'MH')

        state_code = state_code.upper()
        schema_name = 'maharashtra'

        try:
            state_record = StateRegistry.objects.filter(state_code=state_code, is_active=True).first()
            if state_record:
                schema_name = state_record.schema_name
            else:
                schema_name = 'maharashtra'  # Default state schema
        except Exception as e:
            logger.warning(f"[TenantMiddleware] State registry query failed, using default 'maharashtra': {e}")
            schema_name = 'maharashtra'

        request.state_code = state_code
        request.state_schema = schema_name

        # Apply PostgreSQL search_path for current request
        set_tenant_schema(schema_name)
