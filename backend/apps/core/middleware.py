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
    1. Tenant is resolved from verified JWT state claim, headers, stack, or params.
    2. Connection search_path is set to the resolved tenant schema.
    3. Connection search_path is unconditionally reset to 'public' after every response/exception.
    4. Resolution source is logged for traceability.
    """

    def process_request(self, request):
        state_code = None
        schema_name = None
        source = 'default'

        # 1. Check if an active TenantContext stack exists
        from apps.core.tenancy import _get_schema_stack
        stack = _get_schema_stack()
        if stack:
            schema_name = stack[-1]
            source = 'stack'

        # 2. Inspect JWT Authorization Bearer Token if present
        if not schema_name:
            auth_header = request.headers.get('Authorization') or request.META.get('HTTP_AUTHORIZATION', '')
            if auth_header.startswith('Bearer '):
                try:
                    import jwt
                    from django.conf import settings
                    token = auth_header.split(' ')[1]
                    decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
                    token_user_type = decoded.get('user_type')
                    token_state = decoded.get('state_code')
                    token_schema = decoded.get('schema_name')

                    if token_user_type == 'master':
                        schema_name = 'public'
                        source = 'token_claim'
                        state_code = 'GLOBAL'
                    elif token_schema:
                        schema_name = "".join(c for c in token_schema if c.isalnum() or c == '_').lower()
                        source = 'token_claim'
                        state_code = token_state
                    elif token_state and str(token_state).upper() != 'GLOBAL':
                        state_code = str(token_state).upper()
                        if state_code in _STATE_SCHEMA_CACHE:
                            schema_name = _STATE_SCHEMA_CACHE[state_code]
                            source = 'token_claim'
                        else:
                            try:
                                state_record = StateRegistry.objects.filter(state_code=state_code, is_active=True).first()
                                if state_record and state_record.schema_name:
                                    schema_name = state_record.schema_name
                                    _STATE_SCHEMA_CACHE[state_code] = schema_name
                                    source = 'token_claim'
                            except Exception:
                                pass
                except jwt.ExpiredSignatureError:
                    request._token_expired = True
                except Exception:
                    pass

        # 3. Inspect Headers (X-Tenant-Schema, X-State-Schema, X-State-Code)
        if not schema_name:
            direct_schema = (
                request.headers.get('X-Tenant-Schema') or 
                request.META.get('HTTP_X_TENANT_SCHEMA') or 
                request.headers.get('X-State-Schema') or 
                request.META.get('HTTP_X_STATE_SCHEMA')
            )
            header_state_code = request.headers.get('X-State-Code') or request.META.get('HTTP_X_STATE_CODE')

            if direct_schema:
                schema_name = "".join(c for c in direct_schema if c.isalnum() or c == '_').lower()
                source = 'header'
                state_code = header_state_code
            elif header_state_code and str(header_state_code).upper() != 'GLOBAL':
                sc = str(header_state_code).upper()
                state_code = sc
                if sc in _STATE_SCHEMA_CACHE:
                    schema_name = _STATE_SCHEMA_CACHE[sc]
                    source = 'header'
                else:
                    try:
                        state_record = StateRegistry.objects.filter(state_code=sc, is_active=True).first()
                        if state_record and state_record.schema_name:
                            schema_name = state_record.schema_name
                            _STATE_SCHEMA_CACHE[sc] = schema_name
                            source = 'header'
                    except Exception:
                        pass

        # 4. Fallback to state_code / state_id Query Parameter
        if not schema_name:
            param_state = request.GET.get('state_code') or request.GET.get('state_id')
            if param_state and str(param_state).upper() != 'GLOBAL':
                sc = str(param_state).upper()
                state_code = sc
                if sc in _STATE_SCHEMA_CACHE:
                    schema_name = _STATE_SCHEMA_CACHE[sc]
                    source = 'query_param'
                else:
                    try:
                        state_record = StateRegistry.objects.filter(state_code=sc, is_active=True).first()
                        if state_record and state_record.schema_name:
                            schema_name = state_record.schema_name
                            _STATE_SCHEMA_CACHE[sc] = schema_name
                            source = 'query_param'
                    except Exception:
                        pass

        # 5. Default Fallback
        if not schema_name:
            schema_name = 'public'
            source = 'default'

        request.state_code = state_code
        request.state_schema = schema_name
        request.schema_resolution_source = source

        logger.info(
            f"[TenantMiddleware] {request.method} {request.path} -> "
            f"resolved_schema='{schema_name}', source='{source}', state_code='{state_code}'"
        )

        # Enforce PostgreSQL search_path on active connection
        try:
            set_tenant_schema(schema_name)
            request._schema_switched = (schema_name != 'public')
        except Exception as e:
            logger.warning(f"[TenantMiddleware] Failed to set search_path to {schema_name}: {e}")
            request._schema_switched = False

    def process_response(self, request, response):
        """
        Safely resets search_path back to 'public' immediately after every request completes,
        preventing tenant search_path leakage across connection pools.
        """
        try:
            set_tenant_schema('public')
        except Exception as e:
            logger.warning(f"[TenantMiddleware] Failed to reset search_path to public on response: {e}")
        return response

    def process_exception(self, request, exception):
        """
        Ensures search_path is safely reset to 'public' if an unhandled exception occurs.
        """
        try:
            set_tenant_schema('public')
        except Exception as e:
            logger.warning(f"[TenantMiddleware] Failed to reset search_path to public on exception: {e}")
        return None

