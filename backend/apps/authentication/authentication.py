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
            raise exceptions.AuthenticationFailed('Backend JWT token has expired.')
        except jwt.InvalidTokenError:
            raise exceptions.AuthenticationFailed('Invalid authentication token.')

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
        try:
            profile = OfficerProfile.objects.filter(uid=str(uid)).first()
            if not profile:
                # Get profile mapping from public.user_role_mappings if needed
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

            if profile and profile.account_status not in ['active', 'approved']:
                raise exceptions.AuthenticationFailed(f'Account status is {profile.account_status}. Contact Admin.')

            return (profile, payload)
        except Exception as e:
            logger.error(f"[PrimaryJWTAuth] Error fetching officer profile: {e}")
            raise exceptions.AuthenticationFailed(f'Authentication failed: {str(e)}')

