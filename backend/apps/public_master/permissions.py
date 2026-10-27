"""Write access to the global master tables (states, RBAC tables, announcements)."""
from rest_framework import permissions

from apps.authentication.approval_scope import MASTER, STATE, caller_level


class ReadAuthenticatedWriteMaster(permissions.BasePermission):
    """Any logged-in user may read; only a Master Admin may change anything."""

    def has_permission(self, request, view):
        user = request.user
        if not user or not getattr(user, 'is_authenticated', False):
            return False
        if request.method in permissions.SAFE_METHODS:
            return True
        return caller_level(user) >= MASTER


class ReadAnyWriteStateAdmin(permissions.BasePermission):
    """Anyone may read; only a State Admin or Master Admin may change anything."""

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return caller_level(request.user) >= STATE
