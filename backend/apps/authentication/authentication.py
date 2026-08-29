import logging
import jwt
from django.conf import settings
from rest_framework import authentication, exceptions

from apps.public_master.models import MasterUser, UserRoleMapping
from apps.users.models import OfficerProfile

logger = logging.getLogger(__name__)


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
            try:
                master_user = MasterUser.objects.get(id=uid, is_active=True)
                master_user.role_id = 'master_admin'
                return (master_user, payload)
            except MasterUser.DoesNotExist:
                raise exceptions.AuthenticationFailed('Master Admin account not found or inactive.')

        # Standard State Officer / Admin User
        from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema
        from apps.public_master.models import StateRegistry

        try:
            active_schema = get_active_tenant_schema(request)
            profile = OfficerProfile.objects.filter(uid=str(uid)).first()

            # 1. Search in public schema if not found in active schema
            if not profile and active_schema != 'public':
                try:
                    set_tenant_schema('public')
                    profile = OfficerProfile.objects.filter(uid=str(uid)).first()
                except Exception as ex:
                    logger.warning(f"[PrimaryJWTAuth] Public schema fallback error: {ex}")
                finally:
                    set_tenant_schema(active_schema)

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
                            except Exception:
                                pass
                except Exception as ex:
                    logger.warning(f"[PrimaryJWTAuth] Multi-tenant fallback error: {ex}")
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
                except Exception:
                    pass
                finally:
                    set_tenant_schema(active_schema)

            if not profile:
                raise exceptions.AuthenticationFailed('Officer profile not found.')

            if profile.account_status not in ['active', 'approved']:
                raise exceptions.AuthenticationFailed(f'Account status is {profile.account_status}. Contact Admin.')

            return (profile, payload)
        except exceptions.AuthenticationFailed:
            raise
        except Exception as e:
            logger.error(f"[PrimaryJWTAuth] Error fetching officer profile: {e}")
            raise exceptions.AuthenticationFailed(f'Authentication failed: {str(e)}')

