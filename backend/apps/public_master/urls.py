from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.public_master.views import (
    StateRegistryViewSet, RoleViewSet, PermissionViewSet, RolePermissionViewSet
)

router = DefaultRouter()
router.register(r'states', StateRegistryViewSet, basename='master-states')
router.register(r'roles', RoleViewSet, basename='master-roles')
router.register(r'permissions', PermissionViewSet, basename='master-permissions')
router.register(r'role-permissions', RolePermissionViewSet, basename='master-role-permissions')

urlpatterns = [
    path('', include(router.urls)),
]
