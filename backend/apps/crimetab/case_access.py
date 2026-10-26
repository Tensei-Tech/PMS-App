"""
Who may see which case records.

Same rule as apps.cases.views.CaseRecordViewSet: master admins and roles
granted 'district:view_data' or 'state:view_all' see every station of their
state tenant; everyone else sees only their own station and their
additional_stations. Station names are compared case-insensitively.
"""
from django.db.models import Q

from apps.core.permissions import check_dynamic_permission


def sees_all_stations(user):
    if not user or not getattr(user, 'is_authenticated', False):
        return False
    if getattr(user, 'role_id', '') == 'master_admin' or getattr(user, 'user_type', '') == 'master':
        return True
    return check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')


def allowed_stations(user):
    """None when the user may see every station, else the list of their station names."""
    if sees_all_stations(user):
        return None
    names = [getattr(user, 'station_name', '')] + list(getattr(user, 'additional_stations', None) or [])
    return [n.strip() for n in names if isinstance(n, str) and n.strip()]


def scope_by_station(queryset, user, field='station_name'):
    """Restrict a queryset to the stations the user may see."""
    stations = allowed_stations(user)
    if stations is None:
        return queryset
    if not stations:
        return queryset.none()
    q = Q()
    for name in stations:
        q |= Q(**{f'{field}__iexact': name})
    return queryset.filter(q)


def can_access_station(user, station_name):
    stations = allowed_stations(user)
    if stations is None:
        return True
    return bool(station_name) and station_name.strip().lower() in {s.lower() for s in stations}
