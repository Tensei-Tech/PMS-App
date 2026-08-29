from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.public_master.views import (
    StateRegistryViewSet, RoleViewSet, PermissionViewSet, RolePermissionViewSet, DesignationViewSet,
    MasterDivisionsView, MasterDistrictsView, MasterStationsView, AvailableUnitsView, MasterRankConfigsView,
    AppAnnouncementViewSet
)

router = DefaultRouter()
router.register(r'states', StateRegistryViewSet, basename='master-states')
router.register(r'roles', RoleViewSet, basename='master-roles')
router.register(r'permissions', PermissionViewSet, basename='master-permissions')
router.register(r'role-permissions', RolePermissionViewSet, basename='master-role-permissions')
router.register(r'designations', DesignationViewSet, basename='master-designations')
router.register(r'announcements', AppAnnouncementViewSet, basename='master-announcements')


urlpatterns = [
    path('hierarchy/rank-configs/', MasterRankConfigsView.as_view(), name='master-rank-configs'),
    path('hierarchy/divisions/', MasterDivisionsView.as_view(), name='master-divisions'),
    path('hierarchy/districts/', MasterDistrictsView.as_view(), name='master-districts'),
    path('hierarchy/stations/', MasterStationsView.as_view(), name='master-stations'),
    path('hierarchy/available-units/', AvailableUnitsView.as_view(), name='master-available-units'),
    path('', include(router.urls)),
]

