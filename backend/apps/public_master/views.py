import logging
from rest_framework import viewsets, views, permissions, status
from rest_framework.response import Response
from apps.core.tenancy import provision_state_schema
from apps.core.permissions import HasPermission
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission, UserRoleMapping
from apps.public_master.serializers import (
    MasterUserSerializer, StateRegistrySerializer, RoleSerializer,
    PermissionSerializer, RolePermissionSerializer, UserRoleMappingSerializer
)

logger = logging.getLogger(__name__)


from apps.core.cache_decorators import cache_response, invalidate_tenant_cache
from apps.core.cache import upstash_cache


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

    @cache_response(ttl=43200, key_prefix="public_master:states")
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

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

        # Invalidate State Master Cache
        upstash_cache.delete_pattern("pms:cache:*:public_master:states:*")

        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request, *args, **kwargs):
        res = super().update(request, *args, **kwargs)
        upstash_cache.delete_pattern("pms:cache:*:public_master:states:*")
        return res

    def destroy(self, request, *args, **kwargs):
        res = super().destroy(request, *args, **kwargs)
        upstash_cache.delete_pattern("pms:cache:*:public_master:states:*")
        return res


class RoleViewSet(viewsets.ModelViewSet):
    """
    Master Admin API to view & create dynamic Roles in `public.roles`.
    """
    queryset = Role.objects.all()
    serializer_class = RoleSerializer
    permission_classes = [permissions.IsAuthenticated]

    @cache_response(ttl=43200, key_prefix="public_master:roles")
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    def create(self, request, *args, **kwargs):
        res = super().create(request, *args, **kwargs)
        upstash_cache.delete_pattern("pms:cache:*:public_master:roles:*")
        return res


class PermissionViewSet(viewsets.ModelViewSet):
    """
    Master Admin API to view & create dynamic Permissions in `public.permissions`.
    """
    queryset = Permission.objects.all()
    serializer_class = PermissionSerializer
    permission_classes = [permissions.IsAuthenticated]

    @cache_response(ttl=43200, key_prefix="public_master:permissions")
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    def create(self, request, *args, **kwargs):
        res = super().create(request, *args, **kwargs)
        upstash_cache.delete_pattern("pms:cache:*:public_master:permissions:*")
        return res


class RolePermissionViewSet(viewsets.ModelViewSet):
    """
    Master Admin API to update Role-Permission mappings in `public.role_permissions`.
    Changes here dynamically update permission enforcement across backend APIs and frontend UI!
    """
    queryset = RolePermission.objects.all()
    serializer_class = RolePermissionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        res = super().create(request, *args, **kwargs)
        upstash_cache.delete_pattern("pms:cache:*:user_permissions:*")
        return res

    def update(self, request, *args, **kwargs):
        res = super().update(request, *args, **kwargs)
        upstash_cache.delete_pattern("pms:cache:*:user_permissions:*")
        return res


from apps.public_master.models import Designation
from apps.public_master.serializers import DesignationSerializer

class DesignationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API to fetch dynamic Police Rank & Designation Master from DB (`public.designations`).
    Supports filtering by role: ?role=state_admin or ?allowed_for=state_admin
    """
    queryset = Designation.objects.filter(is_active=True).order_by('-rank_level', 'code')
    serializer_class = DesignationSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None

    @cache_response(ttl=43200, key_prefix="public_master:designations")
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    def get_queryset(self):
        qs = super().get_queryset()
        role = self.request.query_params.get('role') or self.request.query_params.get('admin_level') or self.request.query_params.get('allowed_for')
        if role:
            r = role.lower()
            if 'state' in r:
                qs = qs.filter(is_state_admin_allowed=True)
            elif 'district' in r:
                qs = qs.filter(is_district_admin_allowed=True)
            elif 'division' in r or 'subdivision' in r:
                qs = qs.filter(is_division_admin_allowed=True)
            elif 'station' in r or 'head' in r:
                qs = qs.filter(is_station_admin_allowed=True)
        return qs


class MasterRankConfigsView(views.APIView):
    """
    GET /api/master/hierarchy/rank-configs/
    Returns all active police rank capability configurations directly from PostgreSQL in real-time.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        ranks = Designation.objects.filter(is_active=True, display_name__isnull=False).order_by('rank_level', 'code')
        serializer = DesignationSerializer(ranks, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class MasterDivisionsView(views.APIView):
    """
    GET /api/v1/master/hierarchy/divisions/?state_code=MH
    """
    permission_classes = [permissions.AllowAny]

    @cache_response(ttl=43200, key_prefix="hierarchy:divisions")
    def get(self, request):
        from .models import MasterDivision
        state_code = request.query_params.get('state_code', 'MH').upper()
        divs = MasterDivision.objects.filter(state_code=state_code).values('id', 'name', 'code', 'state_name')
        data = list(divs)
        if not data:
            data = [
                {'name': 'Amravati'}, {'name': 'Chhatrapati Sambhajinagar'},
                {'name': 'Konkan'}, {'name': 'Nagpur'}, {'name': 'Nashik'}, {'name': 'Pune'}
            ]
        return Response(data, status=status.HTTP_200_OK)


class MasterDistrictsView(views.APIView):
    """
    GET /api/v1/master/hierarchy/districts/?state_code=MH
    """
    permission_classes = [permissions.AllowAny]

    @cache_response(ttl=43200, key_prefix="hierarchy:districts")
    def get(self, request):
        from apps.stations.models import District
        dists = District.objects.filter(status='approved').values('district_id', 'name', 'code')
        return Response(list(dists), status=status.HTTP_200_OK)


class MasterStationsView(views.APIView):
    """
    GET /api/v1/master/hierarchy/stations/?district=Ahmednagar
    """
    permission_classes = [permissions.AllowAny]

    @cache_response(ttl=43200, key_prefix="hierarchy:stations")
    def get(self, request):
        from apps.stations.models import PoliceStation
        district_name = request.query_params.get('district', '').strip()
        qs = PoliceStation.objects.all()
        if district_name:
            qs = qs.filter(district_name__icontains=district_name)
        data = list(qs.values('station_id', 'station_name', 'district_name', 'zone', 'address'))
        for item in data:
            item['name'] = item.get('station_name', '')
        return Response(data, status=status.HTTP_200_OK)


class AvailableUnitsView(views.APIView):
    """
    GET /api/v1/master/hierarchy/available-units/?state_code=MH
    Returns real-time dynamic availability of divisions, districts, and stations with status reasons.
    """
    permission_classes = [permissions.AllowAny]

    @cache_response(ttl=3600, key_prefix="hierarchy:units")
    def get(self, request):
        from .hierarchy_availability import HierarchyAvailabilityEngine
        state_code = request.query_params.get('state_code', 'MH').upper()
        data = HierarchyAvailabilityEngine.get_available_units(state_code)
        return Response(data, status=status.HTTP_200_OK)


class AppAnnouncementViewSet(viewsets.ModelViewSet):
    """
    API endpoint for viewing and managing Law & Order App Announcements carousel items.
    """
    from apps.public_master.models import AppAnnouncement
    from apps.public_master.serializers import AppAnnouncementSerializer

    queryset = AppAnnouncement.objects.filter(is_active=True).order_by('order', '-created_at')
    serializer_class = AppAnnouncementSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        from apps.public_master.models import AppAnnouncement
        if self.request.user and getattr(self.request.user, 'role', '') in ['admin', 'master_admin', 'state_super_admin']:
            return AppAnnouncement.objects.all().order_by('order', '-created_at')
        return AppAnnouncement.objects.filter(is_active=True).order_by('order', '-created_at')




