from rest_framework import permissions


class IsOfficerOrAdmin(permissions.BasePermission):
    """
    Allows access to any authenticated officer or admin.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)


class IsSupervisorOrAdmin(permissions.BasePermission):
    """
    Allows access only to officers with role 'supervisor' or 'admin'.
    """
    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        return request.user.role in ['supervisor', 'admin'] or request.user.is_staff


class IsSameStation(permissions.BasePermission):
    """
    Ensures that an officer can only view or modify records belonging to their station.
    """
    def has_object_permission(self, request, view, obj):
        if not (request.user and request.user.is_authenticated):
            return False

        if request.user.role == 'admin' or request.user.is_staff:
            return True

        record_station = getattr(obj, 'station_name', '')
        user_stations = [request.user.station_name] + (request.user.additional_stations or [])
        return record_station in user_stations
