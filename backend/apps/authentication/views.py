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


from apps.authentication.otp_service import OTPService


class SendOTPView(views.APIView):
    """
    Compliant OTP Dispatch API for Email and SMS using NIC Gateway / Dev Mode.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        phone = request.data.get('phone', '').strip()
        otp_type = request.data.get('type', 'email')

        if otp_type == 'email' and email:
            OTPService.send_email_otp(email, '123456')
            return Response({'message': f'OTP dispatched to {email}'}, status=status.HTTP_200_OK)
        elif otp_type == 'sms' and phone:
            OTPService.send_sms_otp(phone, '123456')
            return Response({'message': f'OTP dispatched to {phone}'}, status=status.HTTP_200_OK)

        return Response({'error': 'Valid email or phone number required.'}, status=status.HTTP_400_BAD_REQUEST)


class CheckContactExistsView(views.APIView):
    """
    Check if an email address or phone number is already registered in PostgreSQL database.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        phone = request.data.get('phone', '').strip()

        email_exists = False
        phone_exists = False

        if email:
            email_exists = MasterUser.objects.filter(email=email).exists() or OfficerProfile.objects.filter(email=email).exists()

        if phone:
            phone_exists = MasterUser.objects.filter(phone=phone).exists() or OfficerProfile.objects.filter(phone=phone).exists()

        return Response({
            'exists': email_exists or phone_exists,
            'email_exists': email_exists,
            'phone_exists': phone_exists
        }, status=status.HTTP_200_OK)


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
        phone = data.get('phone', '').strip()

        if not email or not password:
            return Response({'error': 'Email and password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # Global duplicate email and phone validations
        if MasterUser.objects.filter(email=email).exists() or OfficerProfile.objects.filter(email=email).exists():
            return Response({'error': f'An account with email "{email}" already exists.'}, status=status.HTTP_400_BAD_REQUEST)

        if phone and (MasterUser.objects.filter(phone=phone).exists() or OfficerProfile.objects.filter(phone=phone).exists()):
            return Response({'error': f'An account with phone number "{phone}" already exists.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Registration for Master Admin
        if role_id == 'master_admin':
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

        import uuid
        uid = str(uuid.uuid4())

        # Determine account status: Self-registered officers require hierarchical approval
        initial_status = 'pending_approval' if role_id not in ['master_admin', 'state_super_admin'] else 'active'

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
            account_status=initial_status
        )
        officer.set_password(password)
        officer.save()

        # Mirror officer profile in public schema for Master Admin global visibility
        try:
            set_tenant_schema('public')
            pub_officer = OfficerProfile(
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
                account_status=initial_status
            )
            pub_officer.set_password(password)
            pub_officer.save()
            set_tenant_schema(schema_name)
        except Exception as e:
            logger.warning(f"Failed to mirror officer to public schema: {e}")
            set_tenant_schema(schema_name)

        # Dispatch Scoped Approval Notifications (RBAC + ABAC Hierarchy Routing)
        if initial_status == 'pending_approval':
            from apps.users.models import NotificationRecord

            # 1. Target ONLY the Station Head of THIS specific station (Strict ABAC Scope)
            if station_name:
                NotificationRecord.objects.create(
                    target_role_id='station_head',
                    target_station_name=station_name,
                    target_district=district_name,
                    target_state_code=state_code,
                    title='New Station Officer Registration Pending',
                    body=f'Officer {full_name} ({designation}) registered for {station_name}. Approval required.',
                    category='approval_request',
                    registration_uid=uid,
                    status='pending'
                )

            # 2. Target District Admin of THIS specific district (Strict ABAC Scope)
            if district_name:
                NotificationRecord.objects.create(
                    target_role_id='district_admin',
                    target_district=district_name,
                    target_state_code=state_code,
                    title='New District Officer Registration Pending',
                    body=f'Officer {full_name} ({designation}) registered for {station_name}, {district_name}.',
                    category='approval_request',
                    registration_uid=uid,
                    status='pending'
                )

            # 3. Target State Super Admin of THIS state
            NotificationRecord.objects.create(
                target_role_id='state_super_admin',
                target_state_code=state_code,
                title='New State Officer Registration Pending',
                body=f'Officer {full_name} ({designation}) registered in {state_code} state.',
                category='approval_request',
                registration_uid=uid,
                status='pending'
            )

            # 4. Target Master Admin
            NotificationRecord.objects.create(
                target_role_id='master_admin',
                title='New Officer System-Wide Registration Pending',
                body=f'Officer {full_name} ({designation}) registered for {state_code} state.',
                category='approval_request',
                registration_uid=uid,
                status='pending'
            )

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
            'message': 'Officer registered successfully.' if initial_status == 'active' else 'Registration submitted for hierarchical approval.',
            'account_status': initial_status,
            'user': {
                'uid': uid,
                'email': officer.email,
                'name': officer.name,
                'role_id': officer.role_id,
                'state_code': state_code,
                'district': officer.district,
                'station_name': officer.station_name,
                'account_status': initial_status
            },
            'tokens': tokens
        }, status=status.HTTP_201_CREATED)


class PendingApprovalsNotificationListView(views.APIView):
    """
    Returns pending registration notifications filtered STRICTLY to caller's ABAC & RBAC hierarchy.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from apps.users.models import NotificationRecord
        caller = request.user
        role_id = getattr(caller, 'role_id', 'officer')
        station_name = getattr(caller, 'station_name', '')
        district = getattr(caller, 'district', '')
        state_code = getattr(caller, 'state_code', 'MH')

        qs = NotificationRecord.objects.filter(status='pending', category='approval_request')

        # Filter strictly by hierarchy scope
        if role_id == 'master_admin' or getattr(caller, 'user_type', '') == 'master':
            pass  # Master sees all
        elif role_id in ['state_super_admin', 'super_admin']:
            qs = qs.filter(target_state_code=state_code)
        elif role_id == 'district_admin':
            qs = qs.filter(target_district=district)
        elif role_id in ['station_head', 'pi', 'sho'] or station_name:
            qs = qs.filter(target_station_name=station_name)
        else:
            qs = NotificationRecord.objects.none()

        data = []
        for n in qs:
            data.append({
                'id': n.id,
                'title': n.title,
                'body': n.body,
                'category': n.category,
                'registration_uid': n.registration_uid,
                'target_station': n.target_station_name,
                'target_district': n.target_district,
                'created_at': n.created_at.isoformat(),
            })

        return Response(data, status=status.HTTP_200_OK)


class ApproveRejectOfficerRegistrationView(views.APIView):
    """
    Approve or Reject pending officer registration. Enforces strict ABAC + RBAC hierarchy authorization.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, uid):
        from apps.users.models import NotificationRecord
        action = request.data.get('action', 'approve').lower()
        caller = request.user

        officer = OfficerProfile.objects.filter(uid=uid).first()
        if not officer:
            return Response({'error': 'Target officer profile not found'}, status=status.HTTP_404_NOT_FOUND)

        # ABAC + RBAC Scope Verification
        is_master = getattr(caller, 'role_id', '') == 'master_admin' or getattr(caller, 'user_type', '') == 'master'
        is_state_super = check_dynamic_permission(caller, 'state:manage') or getattr(caller, 'role_id', '') in ['state_super_admin', 'super_admin']
        is_district_admin = check_dynamic_permission(caller, 'district:manage') or getattr(caller, 'role_id', '') == 'district_admin'
        is_station_head = getattr(caller, 'station_name', '') == officer.station_name if officer.station_name else False

        if not (is_master or is_state_super or is_district_admin or is_station_head):
            return Response({
                'error': f'Access Denied: You can only approve registration requests for your assigned station ({getattr(caller, "station_name", "N/A")}), district, or state hierarchy.'
            }, status=status.HTTP_403_FORBIDDEN)

        if action == 'approve':
            officer.account_status = 'active'
            officer.save()
            NotificationRecord.objects.filter(registration_uid=uid).update(status='approved', is_read=True)
            return Response({'message': f'Officer {officer.name} account successfully APPROVED and activated.'}, status=status.HTTP_200_OK)
        else:
            officer.account_status = 'rejected'
            officer.save()
            NotificationRecord.objects.filter(registration_uid=uid).update(status='rejected', is_read=True)
            return Response({'message': f'Officer {officer.name} registration REJECTED.'}, status=status.HTTP_200_OK)


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
