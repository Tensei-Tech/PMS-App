import logging
import jwt
from datetime import datetime, timedelta, timezone
from django.conf import settings
from rest_framework import status, views, permissions
from rest_framework.response import Response
from firebase_admin import auth as firebase_auth
from config.firebase import firebase_app

from apps.core.tenancy import set_tenant_schema, provision_state_schema
from apps.public_master.models import MasterUser, StateRegistry, Role, RolePermission, UserRoleMapping
from apps.users.models import OfficerProfile
from apps.stations.models import SuperAdmin, District, DistrictAdmin, PoliceStation

logger = logging.getLogger(__name__)


def generate_tokens_for_user(uid: str, email: str, role_id: str, state_code: str = 'MH', user_type: str = 'officer', extra_claims: dict = None):
    """
    Generates backend JWT access token, refresh token, and optional Firebase Custom Token.
    """
    now = datetime.now(timezone.utc)
    access_payload = {
        'uid': str(uid),
        'user_id': str(uid),
        'email': email,
        'role_id': role_id,
        'state_code': state_code,
        'user_type': user_type,
        'exp': now + timedelta(days=1),
        'iat': now,
    }
    if extra_claims:
        access_payload.update(extra_claims)

    refresh_payload = {
        'uid': str(uid),
        'user_id': str(uid),
        'type': 'refresh',
        'exp': now + timedelta(days=30),
        'iat': now,
    }

    access_token = jwt.encode(access_payload, settings.SECRET_KEY, algorithm='HS256')
    refresh_token = jwt.encode(refresh_payload, settings.SECRET_KEY, algorithm='HS256')

    firebase_token = None
    if firebase_app:
        try:
            firebase_token_bytes = firebase_auth.create_custom_token(str(uid), developer_claims={'role': role_id, 'state': state_code})
            firebase_token = firebase_token_bytes.decode('utf-8') if isinstance(firebase_token_bytes, bytes) else firebase_token_bytes
        except Exception as e:
            logger.warning(f"Failed to generate Firebase custom token: {e}")

    return {
        'access_token': access_token,
        'refresh_token': refresh_token,
        'firebase_token': firebase_token,
    }


class RegisterView(views.APIView):
    """
    Primary Registration API endpoint: POST /api/v1/auth/register/
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        data = request.data
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')
        full_name = data.get('full_name') or data.get('name', '')
        role_id = data.get('role_id', 'officer')
        state_code = data.get('state_code', 'MH').upper()
        district_name = data.get('district', '')
        district_id = data.get('district_id', '')
        station_name = data.get('station_name', '')
        station_id = data.get('station_id', '')
        badge_number = data.get('badge_number', '')
        designation = data.get('designation', '')
        phone = data.get('phone', '')

        if not email or not password:
            return Response({'error': 'Email and password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Registration for Master Admin
        if role_id == 'master_admin':
            if MasterUser.objects.filter(email=email).exists():
                return Response({'error': 'Master Admin with this email already exists.'}, status=status.HTTP_400_BAD_REQUEST)

            master_user = MasterUser(
                email=email,
                full_name=full_name,
                phone=phone
            )
            master_user.set_password(password)
            master_user.save()

            tokens = generate_tokens_for_user(
                uid=str(master_user.id),
                email=master_user.email,
                role_id='master_admin',
                state_code='GLOBAL',
                user_type='master'
            )

            return Response({
                'message': 'Master Admin registered successfully.',
                'user': {
                    'id': str(master_user.id),
                    'email': master_user.email,
                    'full_name': master_user.full_name,
                    'role_id': 'master_admin'
                },
                'tokens': tokens
            }, status=status.HTTP_201_CREATED)

        # 2. Registration for State Level Users / Officers
        state_registry = StateRegistry.objects.filter(state_code=state_code).first()
        schema_name = state_registry.schema_name if state_registry else 'maharashtra'

        # Provision schema if needed
        provision_state_schema(schema_name)
        set_tenant_schema(schema_name)

        # Check existing officer profile
        if OfficerProfile.objects.filter(email=email).exists():
            return Response({'error': 'Officer with this email already exists in state tenant.'}, status=status.HTTP_400_BAD_REQUEST)

        import uuid
        uid = str(uuid.uuid4())

        officer = OfficerProfile(
            uid=uid,
            email=email,
            name=full_name,
            badge_number=badge_number,
            designation=designation,
            phone=phone,
            station_name=station_name,
            station_id=station_id,
            district=district_name,
            district_id=district_id,
            role_id=role_id,
            account_status='active'
        )
        officer.set_password(password)
        officer.save()

        # Update UserRoleMapping in public schema
        role_obj = Role.objects.filter(id=role_id).first()
        if role_obj:
            UserRoleMapping.objects.update_or_create(
                uid=uid,
                defaults={
                    'email': email,
                    'role': role_obj,
                    'state': state_registry,
                    'district_id': district_id,
                    'station_id': station_id
                }
            )

        tokens = generate_tokens_for_user(
            uid=uid,
            email=email,
            role_id=role_id,
            state_code=state_code,
            user_type='officer',
            extra_claims={'district_id': district_id, 'station_id': station_id}
        )

        return Response({
            'message': 'Officer registered successfully.',
            'user': {
                'uid': uid,
                'email': officer.email,
                'name': officer.name,
                'role_id': officer.role_id,
                'state_code': state_code,
                'district': officer.district,
                'station_name': officer.station_name
            },
            'tokens': tokens
        }, status=status.HTTP_201_CREATED)


class LoginView(views.APIView):
    """
    Primary Login API endpoint: POST /api/v1/auth/login/
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        password = request.data.get('password', '')
        state_code = request.data.get('state_code', 'MH').upper()

        if not email or not password:
            return Response({'error': 'Email and password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Try authenticating as Master Admin
        master_user = MasterUser.objects.filter(email=email, is_active=True).first()
        if master_user and master_user.check_password(password):
            tokens = generate_tokens_for_user(
                uid=str(master_user.id),
                email=master_user.email,
                role_id='master_admin',
                state_code='GLOBAL',
                user_type='master'
            )
            return Response({
                'message': 'Master Admin login successful.',
                'user': {
                    'id': str(master_user.id),
                    'email': master_user.email,
                    'full_name': master_user.full_name,
                    'role_id': 'master_admin'
                },
                'tokens': tokens
            }, status=status.HTTP_200_OK)

        # 2. Try authenticating as Officer / State Admin
        state_registry = StateRegistry.objects.filter(state_code=state_code).first()
        schema_name = state_registry.schema_name if state_registry else 'maharashtra'

        set_tenant_schema(schema_name)

        officer = OfficerProfile.objects.filter(email=email).first()
        if officer and officer.check_password(password):
            if officer.account_status != 'active':
                return Response({'error': f'Account status is {officer.account_status}. Access denied.'}, status=status.HTTP_403_FORBIDDEN)

            tokens = generate_tokens_for_user(
                uid=officer.uid,
                email=officer.email,
                role_id=officer.role_id,
                state_code=state_code,
                user_type='officer',
                extra_claims={'district_id': officer.district_id, 'station_id': officer.station_id}
            )

            return Response({
                'message': 'Login successful.',
                'user': {
                    'uid': officer.uid,
                    'email': officer.email,
                    'name': officer.name,
                    'badge_number': officer.badge_number,
                    'designation': officer.designation,
                    'role_id': officer.role_id,
                    'state_code': state_code,
                    'district': officer.district,
                    'station_name': officer.station_name,
                    'account_status': officer.account_status
                },
                'tokens': tokens
            }, status=status.HTTP_200_OK)

        return Response({'error': 'Invalid email or password.'}, status=status.HTTP_401_UNAUTHORIZED)


class UserPermissionsView(views.APIView):
    """
    Dynamic Permissions Retrieval API: GET /api/v1/auth/me/permissions/
    Returns dynamic list of permission codes configured in public.role_permissions for logged-in user.
    """

    def get(self, request):
        user = request.user
        role_id = getattr(user, 'role_id', None) or getattr(user, 'role', None) or 'officer'
        state_code = getattr(request, 'state_code', 'MH')

        if role_id == 'master_admin':
            all_perms = list(Permission.objects.values_list('id', flat=True))
            return Response({
                'role_id': 'master_admin',
                'state_code': 'GLOBAL',
                'is_master': True,
                'permissions': all_perms
            })

        granted_perms = list(RolePermission.objects.filter(
            role_id=role_id,
            is_granted=True
        ).values_list('permission_id', flat=True))

        return Response({
            'role_id': role_id,
            'state_code': state_code,
            'is_master': False,
            'permissions': granted_perms
        })
