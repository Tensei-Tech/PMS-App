import logging
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from apps.core.tenancy import provision_state_schema
from apps.core.permissions import HasPermission
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission, UserRoleMapping
from apps.public_master.serializers import (
    MasterUserSerializer, StateRegistrySerializer, RoleSerializer,
    PermissionSerializer, RolePermissionSerializer, UserRoleMappingSerializer
)

logger = logging.getLogger(__name__)


class StateRegistryViewSet(viewsets.ModelViewSet):
    """
    Master Admin API to manage State Registries & provision state schemas dynamically.
    """
    queryset = StateRegistry.objects.all()
    serializer_class = StateRegistrySerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        state_obj = serializer.save()

        # Provision PostgreSQL schema automatically
        try:
            provision_state_schema(state_obj.schema_name)
            logger.info(f"[StateRegistryViewSet] Successfully provisioned state schema: {state_obj.schema_name}")
        except Exception as e:
            logger.error(f"[StateRegistryViewSet] Failed to provision schema {state_obj.schema_name}: {e}")

        return Response(serializer.data, status=status.HTTP_201_CREATED)


class RoleViewSet(viewsets.ModelViewSet):
    """
    Master Admin API to view & create dynamic Roles in `public.roles`.
    """
    queryset = Role.objects.all()
    serializer_class = RoleSerializer
    permission_classes = [permissions.IsAuthenticated]


class PermissionViewSet(viewsets.ModelViewSet):
    """
    Master Admin API to view & create dynamic Permissions in `public.permissions`.
    """
    queryset = Permission.objects.all()
    serializer_class = PermissionSerializer
    permission_classes = [permissions.IsAuthenticated]


class RolePermissionViewSet(viewsets.ModelViewSet):
    """
    Master Admin API to update Role-Permission mappings in `public.role_permissions`.
    Changes here dynamically update permission enforcement across backend APIs and frontend UI!
    """
    queryset = RolePermission.objects.all()
    serializer_class = RolePermissionSerializer
    permission_classes = [permissions.IsAuthenticated]
