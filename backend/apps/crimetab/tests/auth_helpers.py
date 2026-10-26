"""Login headers for tests that call case endpoints the way the app does."""
import jwt
from django.conf import settings

from apps.public_master.models import Permission, Role, RolePermission
from apps.users.models import OfficerProfile


def district_officer_headers(uid='test-district-officer', state_code='MH'):
    """
    Headers of a logged-in district-level officer (role granted
    'district:view_data', so every station is visible). Case endpoints need a
    login; an X-State-Code header alone is no longer enough.
    Call inside the state's TenantContext so the profile lands in that schema.
    """
    role, _ = Role.objects.get_or_create(id='district_admin', defaults={'name': 'District Admin', 'level': 'district'})
    perm, _ = Permission.objects.get_or_create(id='district:view_data', defaults={'module': 'district'})
    RolePermission.objects.update_or_create(role=role, permission=perm, defaults={'is_granted': True})
    OfficerProfile.objects.update_or_create(uid=uid, defaults={
        'email': f'{uid}@example.com', 'name': uid, 'station_name': 'District HQ',
        'role_id': 'district_admin', 'account_status': 'active',
    })
    token = jwt.encode({'uid': uid, 'state_code': state_code, 'user_type': 'officer'},
                       settings.SECRET_KEY, algorithm='HS256')
    return {'HTTP_AUTHORIZATION': f'Bearer {token}', 'HTTP_X_STATE_CODE': state_code}
