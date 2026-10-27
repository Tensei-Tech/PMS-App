"""
Who may approve, onboard or activate which officer account.

Authority comes from the caller's role_id and DB permissions, never from the
self-declared designation text. Every non-master approver must also share the
target's unit (state / division / district / station) and sit above the
target's level, so an officer can't approve a colleague and a station head
can't activate a district admin.
"""
import logging

from apps.core.permissions import check_dynamic_permission

logger = logging.getLogger(__name__)

MASTER, STATE, DIVISION, DISTRICT, STATION, OFFICER = 5, 4, 3, 2, 1, 0

STATE_ROLES = {'state_admin', 'state_super_admin', 'super_admin', 'admin'}
DIVISION_ROLES = {'division_admin'}
DISTRICT_ROLES = {'district_admin', 'sp', 'cp', 'dcp'}
STATION_ROLES = {'station_head', 'station_admin', 'pi', 'sho'}


def role_level(role_id):
    role = (role_id or '').strip().lower()
    if role == 'master_admin':
        return MASTER
    if role in STATE_ROLES:
        return STATE
    if role in DIVISION_ROLES:
        return DIVISION
    if role in DISTRICT_ROLES:
        return DISTRICT
    if role in STATION_ROLES:
        return STATION
    return OFFICER


def caller_level(caller):
    """Approval level of a logged-in user (role first, then DB permissions)."""
    if not caller or not getattr(caller, 'is_authenticated', False):
        return OFFICER
    level = role_level(getattr(caller, 'role_id', ''))
    if level == MASTER:
        return MASTER
    for perm, perm_level in (('state:manage', STATE), ('division:manage', DIVISION),
                             ('district:manage', DISTRICT), ('user:approve', STATION)):
        if level >= perm_level:
            break
        if check_dynamic_permission(caller, perm):
            level = perm_level
            break
    return level


def _same(a, b):
    a, b = (a or '').strip().casefold(), (b or '').strip().casefold()
    return bool(a) and a == b


def _same_unit(caller, target, id_field, name_fields):
    if _same(getattr(caller, id_field, ''), getattr(target, id_field, '')):
        return True
    return any(_same(getattr(caller, f, ''), getattr(target, f, '')) for f in name_fields)


def in_jurisdiction(caller, target, level):
    """True when `target` lies inside the caller's unit at `level`."""
    if level >= MASTER:
        return True
    if level == STATE:
        # Tenancy already scopes the lookup to the caller's state schema.
        return True
    if level == DIVISION:
        return _same_unit(caller, target, 'division_id', ('division_name', 'zone'))
    if level == DISTRICT:
        return _same_unit(caller, target, 'district_id', ('district',))
    if level == STATION:
        if not _same_unit(caller, target, 'station_id', ('station_name',)):
            return False
        # Same station name in another district is a different station.
        caller_district = getattr(caller, 'district', '') or ''
        target_district = getattr(target, 'district', '') or ''
        return not (caller_district and target_district) or _same(caller_district, target_district)
    return False


def can_manage_account(caller, target):
    """
    May `caller` approve, reject or activate `target` (an OfficerProfile or any
    object with role_id + unit fields)?
    """
    if not caller or not getattr(caller, 'is_authenticated', False):
        return False
    caller_uid = str(getattr(caller, 'uid', '') or getattr(caller, 'id', ''))
    if caller_uid and caller_uid == str(getattr(target, 'uid', '')):
        return False
    level = caller_level(caller)
    if level == MASTER:
        return True
    if level <= OFFICER or role_level(getattr(target, 'role_id', '')) >= level:
        return False
    return in_jurisdiction(caller, target, level)
