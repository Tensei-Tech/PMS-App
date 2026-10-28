"""
Who may approve, onboard or activate which officer account.

Authority comes from the caller's role_id and DB permissions, never from the
self-declared designation text. Every non-master approver must also share the
target's unit (state / district / division / station) and sit above the
target's level, so an officer can't approve a colleague and a station head
can't activate a district admin.

Order: state > district > division (a sub-division inside one district) >
station.
"""
import logging

from apps.core.permissions import check_dynamic_permission

logger = logging.getLogger(__name__)

MASTER, STATE, DISTRICT, DIVISION, STATION, OFFICER = 5, 4, 3, 2, 1, 0

STATE_ROLES = {'state_admin', 'state_super_admin', 'super_admin', 'admin'}
DIVISION_ROLES = {'division_admin'}
# A city admin (police commissionerate) sits at district level; their city
# is kept in the 'district' field until cities get their own list.
DISTRICT_ROLES = {'district_admin', 'city_admin', 'sp', 'cp', 'dcp'}
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
    for perm, perm_level in (('state:manage', STATE), ('district:manage', DISTRICT),
                             ('division:manage', DIVISION), ('user:approve', STATION)):
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
    if level == DISTRICT:
        return _same_unit(caller, target, 'district_id', ('district',))
    if level == DIVISION:
        # A sub-division name can repeat in another district.
        return (_same_unit(caller, target, 'division_id', ('division_name', 'zone'))
                and _same_district_if_known(caller, target))
    if level == STATION:
        # Same station name in another district is a different station.
        return (_same_unit(caller, target, 'station_id', ('station_name',))
                and _same_district_if_known(caller, target))
    return False


def _same_district_if_known(caller, target):
    caller_district = getattr(caller, 'district', '') or ''
    target_district = getattr(target, 'district', '') or ''
    return not (caller_district and target_district) or _same(caller_district, target_district)


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


# ── Which officers a user may see ──────────────────────────────────────────
# State admin: the whole state. District or city admin: their district or
# city (and the divisions in it). Division admin: their sub-division's
# officers. Station head and officers: their own police station(s).

def _own_stations(caller):
    names = [getattr(caller, 'station_name', '')] + list(getattr(caller, 'additional_stations', None) or [])
    return [n.strip() for n in names if isinstance(n, str) and n.strip()]


def sees_officer(caller, officer, level=None):
    """
    May `caller` see `officer` in officer lists and directories? Pass the
    caller's `level` when checking many officers, to look it up only once.
    """
    level = caller_level(caller) if level is None else level
    if level >= STATE:
        return True
    if level == DISTRICT:
        return _same_unit(caller, officer, 'district_id', ('district',))
    if level == DIVISION:
        return in_jurisdiction(caller, officer, DIVISION)
    station = (getattr(officer, 'station_name', '') or '').strip().casefold()
    return bool(station) and station in {s.casefold() for s in _own_stations(caller)}


def officer_scope_q(caller):
    """
    The same rule as a queryset filter on OfficerProfile, or None when the
    caller sees every officer. A caller missing the unit their level needs
    sees nobody rather than everybody.
    """
    from django.db.models import Q

    def any_of(field, values):
        q = Q()
        for value in values:
            q |= Q(**{f'{field}__iexact': value})
        return q

    level = caller_level(caller)
    if level >= STATE:
        return None
    district = (getattr(caller, 'district', '') or '').strip()
    district_id = (getattr(caller, 'district_id', '') or '').strip()
    if level == DISTRICT:
        if not (district or district_id):
            return Q(pk__in=[])
        q = Q(district__iexact=district) if district else Q()
        return q | Q(district_id=district_id) if district_id else q
    if level == DIVISION:
        division = (getattr(caller, 'division_name', '') or getattr(caller, 'zone', '') or '').strip()
        if not division:
            return Q(pk__in=[])
        q = Q(division_name__iexact=division) | Q(zone__iexact=division)
        # A sub-division name can repeat in another district.
        return q & (Q(district__iexact=district) | Q(district='') | Q(district__isnull=True)) if district else q
    stations = _own_stations(caller)
    return any_of('station_name', stations) if stations else Q(pk__in=[])
