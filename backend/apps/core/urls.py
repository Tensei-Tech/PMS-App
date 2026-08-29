from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.core.views import AuditLogViewSet, SosAlertViewSet

router = DefaultRouter()
router.register(r'audit-logs', AuditLogViewSet, basename='audit-logs')
router.register(r'sos-alerts', SosAlertViewSet, basename='sos-alerts')

urlpatterns = [
    path('', include(router.urls)),
]
