import logging
import jwt
from django.conf import settings
from rest_framework import authentication, exceptions
from firebase_admin import auth as firebase_auth
from config.firebase import firebase_app

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
            # Token might be a Firebase ID token, pass to next authentication class
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

            if profile and profile.account_status != 'active':
                raise exceptions.AuthenticationFailed(f'Account status is {profile.account_status}. Contact Admin.')

            return (profile, payload)
        except Exception as e:
            logger.error(f"[PrimaryJWTAuth] Error fetching officer profile: {e}")
            raise exceptions.AuthenticationFailed(f'Authentication failed: {str(e)}')


class FirebaseAuthentication(authentication.BaseAuthentication):
    """
    Fallback DRF authentication backend validating Firebase ID Tokens.
    """

    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        if not auth_header:
            return None

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return None

        id_token = parts[1]

        if not firebase_app:
            return None

        try:
            decoded_token = firebase_auth.verify_id_token(id_token)
        except Exception:
            return None  # Let next handler process

        uid = decoded_token.get('uid')
        if not uid:
            return None

        email = decoded_token.get('email', '')
        name = decoded_token.get('name', decoded_token.get('email', f'User_{uid[:6]}'))

        profile, created = OfficerProfile.objects.get_or_create(
            uid=uid,
            defaults={
                'email': email,
                'name': name,
            }
        )

        return (profile, decoded_token)
