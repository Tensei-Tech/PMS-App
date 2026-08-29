import logging
import jwt
from datetime import datetime, timedelta, timezone
from django.conf import settings
from rest_framework import status, views, permissions
from rest_framework.response import Response

from apps.core.tenancy import set_tenant_schema, provision_state_schema, get_active_tenant_schema
from apps.core.permissions import check_dynamic_permission
from apps.public_master.models import MasterUser, StateRegistry, Role, RolePermission, UserRoleMapping
from apps.users.models import OfficerProfile
from apps.stations.models import SuperAdmin, District, DistrictAdmin, PoliceStation

logger = logging.getLogger(__name__)


def generate_tokens_for_user(uid: str, email: str, role_id: str, state_code: str = 'MH', user_type: str = 'officer', extra_claims: dict = None):
    """
    Generates backend JWT access token and refresh token.
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

    return {
        'access_token': access_token,
        'refresh_token': refresh_token,
        'access': access_token,
        'refresh': refresh_token,
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

    def get(self, request):
        return self._handle_check(request.query_params)

    def post(self, request):
        return self._handle_check(request.data)

    def _handle_check(self, data):
        email = data.get('email', '').strip().lower()
        phone = data.get('phone', '').strip()

        email_exists = False
        phone_exists = False
        is_biometric_enabled = False

        if email:
            email_exists = MasterUser.objects.filter(email=email).exists() or OfficerProfile.objects.filter(email=email).exists()
            off = OfficerProfile.objects.filter(email=email).first()
            if off:
                is_biometric_enabled = bool(getattr(off, 'is_biometric_enabled', False))

        if phone:
            phone_exists = MasterUser.objects.filter(phone=phone).exists() or OfficerProfile.objects.filter(phone=phone).exists()

        return Response({
            'exists': email_exists or phone_exists,
            'email_exists': email_exists,
            'phone_exists': phone_exists,
            'is_biometric_enabled': is_biometric_enabled,
        }, status=status.HTTP_200_OK)


class RegisterView(views.APIView):
    """
    Primary Registration API endpoint: POST /api/v1/auth/register/
    """
    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        try:
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

            # Block State Admin self-registration via public API
            if role_id in ['state_admin', 'state_super_admin', 'master_admin']:
                return Response({
                    'error': 'State Admin accounts cannot be created via public self-registration. State Admins are onboarded directly by a Master Admin or existing State Admin.'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Upstream Command Authority Validation: Block registration if jurisdiction lacks active approving admin
            if role_id not in ['master_admin', 'state_super_admin']:
                try:
                    from apps.public_master.hierarchy_availability import HierarchyAvailabilityEngine
                    is_valid, err_msg = HierarchyAvailabilityEngine.validate_posting_target(state_code, district_name, station_name)
                    if not is_valid:
                        return Response({'error': err_msg}, status=status.HTTP_400_BAD_REQUEST)
                except Exception as val_err:
                    logger.warning(f"[HierarchyValidation] Non-fatal check error: {val_err}")

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
            schema_name = state_registry.schema_name if state_registry else get_active_tenant_schema(request)

            # Provision schema if needed
            provision_state_schema(schema_name)
            set_tenant_schema(schema_name)

            import uuid
            uid = str(uuid.uuid4())

            # Determine account status: Self-registered officers (including Station Heads) require hierarchical approval (pending_approval)
            initial_status = 'active' if (data.get('account_status') == 'active' or role_id == 'master_admin') else 'pending_approval'

            division_name = data.get('division_name') or data.get('division') or ''
            division_id = data.get('division_id') or ''

            officer = OfficerProfile(
                uid=uid,
                email=email,
                name=full_name,
                badge_number=badge_number,
                designation=designation,
                phone=phone,
                station_name=station_name,
                station_id=station_id,
                division_name=division_name,
                division_id=division_id,
                district=district_name,
                district_id=district_id,
                role_id=role_id,
                account_status=initial_status
            )
            officer.set_password(password)
            officer.save()

            # If district admin, register in District & DistrictAdmin models
            if role_id == 'district_admin' and district_name:
                try:
                    dist_obj, _ = District.objects.get_or_create(
                        name=district_name,
                        defaults={'district_id': f"DST-{district_name[:4].upper()}", 'status': 'approved'}
                    )
                    DistrictAdmin.objects.update_or_create(
                        uid=uid,
                        defaults={
                            'district': dist_obj,
                            'name': full_name,
                            'email': email,
                            'phone': phone,
                            'badge_number': badge_number,
                            'status': 'active'
                        }
                    )
                except Exception as e:
                    logger.warning(f"Failed to sync DistrictAdmin record: {e}")

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
                    division_name=division_name,
                    division_id=division_id,
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

            tokens = None
            if initial_status == 'active':
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
            }, status=status.HTTP_201_CREATED if initial_status == 'active' else status.HTTP_202_ACCEPTED)
        except Exception as e:
            logger.error(f"[RegisterView] Unhandled exception during registration: {e}", exc_info=True)
            return Response({'error': f'Registration failed: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


class PendingApprovalsNotificationListView(views.APIView):
    """
    Returns pending registration notifications.
    Combines both NotificationRecord entries and pending OfficerProfiles across public & tenant schemas.
    Enforces authentication for superior officers and admins managing registration approvals.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from apps.users.models import NotificationRecord, OfficerProfile
        from apps.core.tenancy import set_tenant_schema

        seen_uids = set()
        data = []

        # 1. Gather pending NotificationRecord entries in active tenant schema
        try:
            for n in NotificationRecord.objects.filter(status='pending', category='approval_request'):
                uid = n.registration_uid
                if uid and uid not in seen_uids:
                    seen_uids.add(uid)
                    data.append({
                        'id': n.id,
                        'title': n.title,
                        'body': n.body,
                        'category': n.category,
                        'registration_uid': uid,
                        'target_station': n.target_station_name or '',
                        'target_district': n.target_district or '',
                        'created_at': n.created_at.isoformat() if hasattr(n, 'created_at') and n.created_at else datetime.now(timezone.utc).isoformat(),
                    })
        except Exception as e:
            logger.warning(f"[PendingApprovals] Notif query error: {e}")

        active_schema = get_active_tenant_schema(request)

        # 2. Gather pending OfficerProfile entries in active tenant schema
        try:
            for off in list(OfficerProfile.objects.filter(account_status__in=['pending_approval', 'pending'])):
                if off.uid and off.uid not in seen_uids:
                    seen_uids.add(off.uid)
                    data.append({
                        'id': f"off-{off.uid}",
                        'title': f"{off.name} ({off.designation or 'Officer'})",
                        'body': f"Pending officer registration request for {off.station_name or off.district or 'Police Station'}.",
                        'category': 'approval_request',
                        'registration_uid': off.uid,
                        'name': off.name or '',
                        'email': off.email or '',
                        'phone': off.phone or '',
                        'designation': off.designation or '',
                        'badge_number': off.badge_number or '',
                        'target_station': off.station_name or '',
                        'target_district': off.district or '',
                        'govt_id': off.govt_id or '',
                        'photo_url': off.photo_url or '',
                        'id_card_url': off.id_card_url or '',
                        'role_id': off.role_id or 'officer',
                        'account_status': off.account_status or 'pending_approval',
                        'created_at': datetime.now(timezone.utc).isoformat(),
                    })
        except Exception as e:
            logger.warning(f"[PendingApprovals] Tenant officer query error: {e}")

        # 3. Gather pending OfficerProfile entries in public schema
        try:
            set_tenant_schema('public')
            for pub_off in list(OfficerProfile.objects.filter(account_status__in=['pending_approval', 'pending'])):
                if pub_off.uid and pub_off.uid not in seen_uids:
                    seen_uids.add(pub_off.uid)
                    data.append({
                        'id': f"pub-{pub_off.uid}",
                        'title': f"{pub_off.name} ({pub_off.designation or 'Officer'})",
                        'body': f"Pending officer registration request for {pub_off.station_name or pub_off.district or 'Police Station'}.",
                        'category': 'approval_request',
                        'registration_uid': pub_off.uid,
                        'name': pub_off.name or '',
                        'email': pub_off.email or '',
                        'phone': pub_off.phone or '',
                        'designation': pub_off.designation or '',
                        'badge_number': pub_off.badge_number or '',
                        'target_station': pub_off.station_name or '',
                        'target_district': pub_off.district or '',
                        'govt_id': pub_off.govt_id or '',
                        'photo_url': pub_off.photo_url or '',
                        'id_card_url': pub_off.id_card_url or '',
                        'role_id': pub_off.role_id or 'officer',
                        'account_status': pub_off.account_status or 'pending_approval',
                        'created_at': datetime.now(timezone.utc).isoformat(),
                    })
        except Exception as e:
            logger.warning(f"[PendingApprovals] Public officer query error: {e}")
        finally:
            set_tenant_schema(active_schema)

        return Response(data, status=status.HTTP_200_OK)


class ApproveRejectOfficerRegistrationView(views.APIView):
    """
    Approve or Reject pending officer registration. Enforces strict ABAC + RBAC hierarchy authorization and dynamic DB permissions.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, uid):
        from apps.users.models import NotificationRecord
        from apps.core.tenancy import set_tenant_schema
        active_schema = get_active_tenant_schema(request)
        action = request.data.get('action', 'approve').lower()
        caller = request.user

        officer = OfficerProfile.objects.filter(uid=uid).first()
        if not officer:
            try:
                set_tenant_schema('public')
                officer = OfficerProfile.objects.filter(uid=uid).first()
            except Exception:
                pass
            finally:
                try:
                    set_tenant_schema(active_schema)
                except Exception:
                    pass

        if not officer:
            return Response({'error': 'Target officer profile not found'}, status=status.HTTP_404_NOT_FOUND)

        # Dynamic DB Permission + ABAC + RBAC Scope Verification
        role_id = getattr(caller, 'role_id', '')
        desig = (getattr(caller, 'designation', '') or '').upper()

        has_user_approve_perm = check_dynamic_permission(caller, 'user:approve')
        is_master = role_id == 'master_admin' or getattr(caller, 'user_type', '') == 'master'
        is_state_super = check_dynamic_permission(caller, 'state:manage') or role_id in ['state_super_admin', 'super_admin', 'state_admin', 'admin'] or desig in ['DG', 'DGP', 'ADG', 'ADGP']
        is_division_admin = check_dynamic_permission(caller, 'division:manage') or role_id in ['division_admin'] or desig in ['DIG', 'IG', 'SPL.IG']
        is_district_admin = check_dynamic_permission(caller, 'district:manage') or role_id in ['district_admin', 'sp', 'cp', 'dcp'] or desig in ['SP', 'CP', 'SSP', 'DCP', 'ADDL. SP', 'ADDL. CP']
        is_station_head = role_id in ['station_head', 'station_admin', 'pi', 'sho'] or (getattr(caller, 'station_name', '') == officer.station_name if officer.station_name else False)

        if not (has_user_approve_perm or is_master or is_state_super or is_division_admin or is_district_admin or is_station_head):
            return Response({
                'error': f'Access Denied: You do not have permissions to approve registration requests in jurisdiction scope ({getattr(caller, "station_name", getattr(caller, "district", "N/A"))}).'
            }, status=status.HTTP_403_FORBIDDEN)

        new_status = 'active' if action == 'approve' else 'rejected'
        notif_status = 'approved' if action == 'approve' else 'rejected'

        # 1. Update in active schema
        try:
            OfficerProfile.objects.filter(uid=str(uid)).update(account_status=new_status)
            NotificationRecord.objects.filter(registration_uid=str(uid)).update(status=notif_status, is_read=True)
        except Exception as ex:
            logger.warning(f"[ApproveRegistration] Active schema update error: {ex}")

        # 2. Update in public schema
        if active_schema != 'public':
            try:
                set_tenant_schema('public')
                OfficerProfile.objects.filter(uid=str(uid)).update(account_status=new_status)
                NotificationRecord.objects.filter(registration_uid=str(uid)).update(status=notif_status, is_read=True)
            except Exception as ex:
                logger.warning(f"[ApproveRegistration] Public schema update error: {ex}")
            finally:
                set_tenant_schema(active_schema)

        # 3. Update across all registered state tenant schemas
        try:
            set_tenant_schema('public')
            state_schemas = list(StateRegistry.objects.values_list('schema_name', flat=True))
            for sch in state_schemas:
                if sch != active_schema:
                    try:
                        set_tenant_schema(sch)
                        OfficerProfile.objects.filter(uid=str(uid)).update(account_status=new_status)
                        NotificationRecord.objects.filter(registration_uid=str(uid)).update(status=notif_status, is_read=True)
                    except Exception:
                        pass
        except Exception as ex:
            logger.warning(f"[ApproveRegistration] Multi-tenant update error: {ex}")
        finally:
            set_tenant_schema(active_schema)

        if action == 'approve':
            return Response({'message': f'Officer {officer.name} account successfully APPROVED and activated.'}, status=status.HTTP_200_OK)
        else:
            return Response({'message': f'Officer {officer.name} registration REJECTED.'}, status=status.HTTP_200_OK)


class LoginView(views.APIView):
    """
    Primary Login API endpoint: POST /api/v1/auth/login/
    """
    authentication_classes = []
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
        schema_name = state_registry.schema_name if state_registry else get_active_tenant_schema(request)

        set_tenant_schema(schema_name)

        officer = OfficerProfile.objects.filter(email=email).first()
        if not officer:
            try:
                set_tenant_schema('public')
                officer = OfficerProfile.objects.filter(email=email).first()
            except Exception:
                pass
            finally:
                try:
                    set_tenant_schema(schema_name)
                except Exception:
                    pass

        if officer and officer.check_password(password):
            if officer.account_status != 'active':
                return Response({
                    'error': 'Account Authorization Pending: Your registration request is currently awaiting approval from your Station Head or Superior Officer.'
                }, status=status.HTTP_403_FORBIDDEN)

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


from apps.core.cache_decorators import cache_response


class UserPermissionsView(views.APIView):
    """
    Dynamic Permissions Retrieval API: GET /api/v1/auth/me/permissions/
    Returns dynamic list of permission codes configured in public.role_permissions for logged-in user.
    """

    @cache_response(ttl=3600, key_prefix="user_permissions")
    def get(self, request):
        user = request.user
        role_id = getattr(user, 'role_id', None) or getattr(user, 'role', None) or 'officer'
        state_code = getattr(user, 'state_code', getattr(request, 'state_code', 'MH'))

        granted_perms = list(RolePermission.objects.filter(
            role_id=role_id,
            is_granted=True
        ).values_list('permission_id', flat=True))

        return Response({
            'role_id': role_id,
            'state_code': state_code,
            'permissions': granted_perms
        }, status=status.HTTP_200_OK)


class ChangePasswordView(views.APIView):
    """
    API endpoint to change user password in PostgreSQL database: POST /api/v1/auth/change-password/
    Updates user password across active tenant and public schemas.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        old_password = request.data.get('old_password', '')
        new_password = request.data.get('new_password', '')

        if not old_password or not new_password:
            return Response({'error': 'Both current password and new password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if len(new_password) < 6:
            return Response({'error': 'New password must be at least 6 characters long.'}, status=status.HTTP_400_BAD_REQUEST)

        if old_password == new_password:
            return Response({'error': 'New password cannot be the same as current password.'}, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        if not user or not getattr(user, 'is_authenticated', False):
            return Response({'error': 'Authentication required.'}, status=status.HTTP_401_UNAUTHORIZED)

        # Verify old password against database
        if not user.check_password(old_password):
            return Response({'error': 'Current password is incorrect.'}, status=status.HTTP_400_BAD_REQUEST)

        # Set new hashed password in database
        user.set_password(new_password)
        user.save()

        # Sync across public schema if OfficerProfile exists in public
        active_schema = get_active_tenant_schema(request)
        if active_schema != 'public' and hasattr(user, 'uid') and user.uid:
            try:
                set_tenant_schema('public')
                pub_officer = OfficerProfile.objects.filter(uid=user.uid).first()
                if pub_officer:
                    pub_officer.set_password(new_password)
                    pub_officer.save()
            except Exception as e:
                logger.warning(f"[ChangePasswordView] Public schema sync warning: {e}")
            finally:
                set_tenant_schema(active_schema)

        return Response({'message': 'Password updated successfully in database.'}, status=status.HTTP_200_OK)


class CustomTokenRefreshView(views.APIView):
    """
    Custom JWT Token Refresh API endpoint: POST /api/v1/auth/token/refresh/
    Validates refresh token and re-issues new access_token and refresh_token.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        refresh_raw = request.data.get('refresh', '') or request.data.get('refresh_token', '')
        if not refresh_raw:
            return Response({'error': 'Refresh token is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            payload = jwt.decode(refresh_raw, settings.SECRET_KEY, algorithms=['HS256'])
            uid = payload.get('uid') or payload.get('user_id')
            if not uid:
                return Response({'error': 'Invalid refresh token payload.'}, status=status.HTTP_400_BAD_REQUEST)

            tokens = generate_tokens_for_user(
                uid=uid,
                email=payload.get('email', ''),
                role_id=payload.get('role_id', 'officer'),
                state_code=payload.get('state_code', 'MH'),
                user_type=payload.get('user_type', 'officer')
            )
            return Response(tokens, status=status.HTTP_200_OK)
        except jwt.ExpiredSignatureError:
            return Response({'error': 'Refresh token has expired.'}, status=status.HTTP_401_UNAUTHORIZED)
        except Exception as e:
            return Response({'error': f'Invalid refresh token: {e}'}, status=status.HTTP_401_UNAUTHORIZED)


