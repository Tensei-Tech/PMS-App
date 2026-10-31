from django.urls import path, include
from rest_framework.routers import DefaultRouter

from apps.muddemal.views import (
    MuddemalConfigView,
    MuddemalCategoryViewSet,
    MuddemalRegisterViewSet,
    MuddemalPropertyViewSet,
    CasePropertiesView,
    CaseDiscoverablePropertiesView,
    CaseLinkPropertyView,
    FSLAlertsView,
    StolenPropertyDashboardView,
    SeizedPropertyDashboardView,
    PendingMuddemalDashboardView,
    MonthYearReportsView,
    MuddemalAutoFetchStatusView,
)

router = DefaultRouter()
router.register(r'categories', MuddemalCategoryViewSet, basename='muddemal-categories')
router.register(r'registers', MuddemalRegisterViewSet, basename='muddemal-registers')
router.register(r'properties', MuddemalPropertyViewSet, basename='muddemal-properties')

urlpatterns = [
    # System Config Tokens (Thresholds, Units, Statuses, Connected Modules)
    path('configs/', MuddemalConfigView.as_view(), name='muddemal-configs'),

    # Centralized Auto-Fetch Inspection & Connected Modules
    path('auto-fetch/', MuddemalAutoFetchStatusView.as_view(), name='muddemal-auto-fetch'),

    # Case-specific integrations & cross-module linking
    path('cases/<str:case_id>/properties/', CasePropertiesView.as_view(), name='case-muddemal-properties'),
    path('cases/<str:case_id>/discoverable-properties/', CaseDiscoverablePropertiesView.as_view(), name='case-discoverable-properties'),
    path('cases/<str:case_id>/link-property/', CaseLinkPropertyView.as_view(), name='case-link-property'),

    # FSL Monitoring & Threshold Alerts
    path('alerts/fsl/', FSLAlertsView.as_view(), name='muddemal-fsl-alerts'),

    # Aggregated Analytical Dashboards & Trends
    path('dashboards/stolen/', StolenPropertyDashboardView.as_view(), name='muddemal-dashboard-stolen'),
    path('dashboards/seized/', SeizedPropertyDashboardView.as_view(), name='muddemal-dashboard-seized'),
    path('dashboards/pending/', PendingMuddemalDashboardView.as_view(), name='muddemal-dashboard-pending'),
    path('dashboards/monthly-yearly/', MonthYearReportsView.as_view(), name='muddemal-dashboard-monthly-yearly'),

    # REST ViewSets router
    path('', include(router.urls)),
]
