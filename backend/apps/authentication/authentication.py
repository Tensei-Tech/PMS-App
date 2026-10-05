import logging
import re
import jwt
from django.conf import settings
from django.core.cache import cache
from django.db import DatabaseError, OperationalError
from rest_framework import authentication, exceptions, status
from rest_framework.exceptions import APIException

from apps.public_master.models import MasterUser, UserRoleMapping, StateRegistry
from apps.users.models import OfficerProfile
from apps.core.tenancy import TenantContext, set_tenant_schema

logger = logging.getLogger(__name__)


class ServiceUnavailable(APIException):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = 'Database service temporarily unavailable. Please retry shortly.'
    default_code = 'service_unavailable'


def _redact_message(msg: object) -> str:
    """Redact hostnames, IPs, passwords, and tokens from exception logs."""
    text = str(msg)
    text = re.sub(r'connection to server at "[^"]*" \([^)]*\), port \d+', 'connection to server at [REDACTED], port [REDACTED]', text)
    text = re.sub(r'(postgres(?:ql)?://)([^@]+)@([^:/]+)(:\d+)?(/.*)?', r'\1[REDACTED]@\3\4\5', text)
    text = re.sub(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', '[REDACTED_IP]', text)
    text = re.sub(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', '[REDACTED_EMAIL]', text)
    text = re.sub(r'(password|pwd|secret|token|key)=\S+', r'\1=[REDACTED]', text, flags=re.IGNORECASE)
    return text


class PrimaryJWTAuthentication(authentication.BaseAuthentication):
    """
    Primary DRF Authentication backend validating backend-issued JWT tokens.
    Supports Master Admins (stored in `public.master_users`) and State Officers/Admins
    (stored in state tenant schema `<state_schema>.users_officerprofile`).
    """

    def authenticate_header(self, request):
        return 'Bearer realm="api"'

    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        if not auth_header:
            return None

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return None

        raw_token = parts[1]

        try:
            payload = jwt.decode(
                raw_token,
                settings.SECRET_KEY,
                algorithms=['HS256']
            )
        except jwt.ExpiredSignatureError:
            logger.info("[PrimaryJWTAuthentication] Token expired; falling back.")
            return None
        except jwt.InvalidTokenError:
            logger.info("[PrimaryJWTAuthentication] Invalid token; falling back.")
            return None

        user_type = payload.get('user_type', 'officer')
        uid = payload.get('uid') or payload.get('user_id')

        if not uid:
            raise exceptions.AuthenticationFailed('Invalid token payload: missing user identifier.')

        if user_type == 'master':
            cache_key = f"auth_master_user_{uid}"
            cached_master = cache.get(cache_key)
            if cached_master is not None:
                return (cached_master, payload)

            try:
                master_user = MasterUser.objects.get(id=uid, is_active=True)
                master_user.role_id = 'master_admin'
                cache.set(cache_key, master_user, timeout=45)
                return (master_user, payload)
            except MasterUser.DoesNotExist:
                raise exceptions.AuthenticationFailed('Master Admin account not found or inactive.')
            except (OperationalError, DatabaseError) as e:
                logger.error(f"[PrimaryJWTAuth] Database connection error during master user lookup: {_redact_message(e)}")
                raise ServiceUnavailable('Database service temporarily unavailable.')
            except Exception as e:
                logger.error(f"[PrimaryJWTAuth] Unexpected error during master user lookup: {_redact_message(e)}")
                raise exceptions.AuthenticationFailed('Authentication failed.')

        # Standard State Officer / Admin User
        from apps.core.tenancy import TenantContext
        from apps.core.middleware import _STATE_SCHEMA_CACHE

        state_code = payload.get('state_code')
        if state_code:
            state_code = state_code.upper()
            active_schema = _STATE_SCHEMA_CACHE.get(state_code, state_code.lower())
        else:
            active_schema = getattr(request, 'state_schema', None) or 'maharashtra'

        request.state_code = state_code or 'MH'
        request.state_schema = active_schema

        cache_key = f"auth_officer_profile_{active_schema}_{uid}"
        cached_profile = cache.get(cache_key)
        if cached_profile is not None:
            if cached_profile.account_status not in ['active', 'approved']:
                raise exceptions.AuthenticationFailed(f'Account status is {cached_profile.account_status}. Contact Admin.')
            return (cached_profile, payload)

        try:
            with TenantContext(active_schema):
                profile = OfficerProfile.objects.filter(uid=str(uid)).first()

            # 1. Search in public schema if not found in active schema
            if not profile and active_schema != 'public':
                try:
                    with TenantContext('public'):
                        profile = OfficerProfile.objects.filter(uid=str(uid)).first()
                except (OperationalError, DatabaseError):
                    raise
                except Exception as ex:
                    logger.warning(f"[PrimaryJWTAuth] Public schema fallback warning: {_redact_message(ex)}")

            # 2. Search across registered state tenant schemas if still not found
            if not profile:
                try:
                    set_tenant_schema('public')
                    state_schemas = list(StateRegistry.objects.values_list('schema_name', flat=True))
                    for sch in state_schemas:
                        if sch != active_schema:
                            try:
                                set_tenant_schema(sch)
                                profile = OfficerProfile.objects.filter(uid=str(uid)).first()
                                if profile:
                                    break
                            except (OperationalError, DatabaseError):
                                raise
                            except Exception:
                                pass
                except (OperationalError, DatabaseError):
                    raise
                except Exception as ex:
                    logger.warning(f"[PrimaryJWTAuth] Multi-tenant fallback warning: {_redact_message(ex)}")
                finally:
                    set_tenant_schema(active_schema)

            if not profile:
                # Check user_role_mappings mapping if needed
                try:
                    set_tenant_schema('public')
                    mapping = UserRoleMapping.objects.filter(uid=str(uid)).first()
                    if mapping:
                        profile = OfficerProfile.objects.create(
                            uid=str(uid),
                            email=mapping.email,
                            name=mapping.email.split('@')[0],
                            role_id=mapping.role_id,
                            district_id=mapping.district_id,
                            station_id=mapping.station_id
                        )
                except (OperationalError, DatabaseError):
                    raise
                except Exception:
                    pass
                finally:
                    set_tenant_schema(active_schema)

            if not profile:
                raise exceptions.AuthenticationFailed('Officer profile not found.')

            if profile.account_status not in ['active', 'approved']:
                raise exceptions.AuthenticationFailed(f'Account status is {profile.account_status}. Contact Admin.')

            cache.set(cache_key, profile, timeout=45)
            return (profile, payload)
        except (OperationalError, DatabaseError) as e:
            logger.error(f"[PrimaryJWTAuth] Database connection error fetching officer profile: {_redact_message(e)}")
            raise ServiceUnavailable('Database service temporarily unavailable.')
        except exceptions.AuthenticationFailed:
            raise
        except Exception as e:
            err_str = str(e)
            if 'connection' in err_str.lower() or 'pool' in err_str.lower() or 'timeout' in err_str.lower():
                logger.error(f"[PrimaryJWTAuth] Database error fetching officer profile: {_redact_message(e)}")
                raise ServiceUnavailable('Database service temporarily unavailable.')
            logger.error(f"[PrimaryJWTAuth] Error fetching officer profile: {_redact_message(e)}")
            raise exceptions.AuthenticationFailed(f'Authentication failed: {_redact_message(e)}')


