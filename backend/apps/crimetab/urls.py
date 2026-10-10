from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.crimetab.views import (
    CaseCategoryGroupViewSet,
    CaseCategoryViewSet,
    CrimeCaseManageView,
    CaseTransferView,
    TransferredInInboxView,
    AssignTransferredCaseView,
    LocationDivisionsView,
    LocationDistrictsView,
    LocationStationsView,
    ActsView,
    ActSectionsView,
    ActSubsectionsView,
    CasePdfView,
    FormSchemaView,
    OptionValuesView,
)

from apps.cases.views import (
    CrimeTypeListView,
    CasesByCrimeTypeView,
    SectionsByCrimeTypeView,
    CreateCaseView,
    PendingCasesView,
    DetectedCasesView,
    CaseCountsView,
)

from apps.crimetab.views_rti import (
    RTIListCreateView,
    RTICountsView,
    RTIConfigView,
    RTIOfficersView,
    RTIDetailView,
    RTIPdfView,
)

router = DefaultRouter()
router.register(r'groups', CaseCategoryGroupViewSet, basename='case-groups')
router.register(r'categories', CaseCategoryViewSet, basename='case-categories')

urlpatterns = [
    # RTI API Endpoints
    path('rti/counts/', RTICountsView.as_view(), name='rti-counts'),
    path('rti/config/', RTIConfigView.as_view(), name='rti-config'),
    path('rti/officers/', RTIOfficersView.as_view(), name='rti-officers'),
    path('rti/<int:pk>/pdf/', RTIPdfView.as_view(), name='rti-pdf'),
    path('rti/<int:pk>/', RTIDetailView.as_view(), name='rti-detail'),
    path('rti/', RTIListCreateView.as_view(), name='rti-list-create'),

    # Options route for dynamic drop-downs & radios (e.g. GET /api/options/<group>/)
    path('options/<str:group>/', OptionValuesView.as_view(), name='option-values-by-group'),
    path('<path:slug>/form-schema/', FormSchemaView.as_view(), name='tab-form-schema'),
    # Case Management specific endpoints
    path('cases/crime-types/', CrimeTypeListView.as_view(), name='crime-type-list'),
    path('cases/crime-types/<path:crime_type>/cases/', CasesByCrimeTypeView.as_view(), name='cases-by-crime-type'),
    path('cases/crime-types/<path:crime_type>/sections/', SectionsByCrimeTypeView.as_view(), name='sections-by-crime-type'),
    path('cases/create/', CreateCaseView.as_view(), name='case-create'),
    path('cases/pending/', PendingCasesView.as_view(), name='pending-cases'),
    path('cases/detected/', DetectedCasesView.as_view(), name='detected-cases-alias'),

    # Explicit Action Endpoints for Cases
    path('cases/counts/', CaseCountsView.as_view(), name='case-counts'),
    path('cases/transferred-in/', TransferredInInboxView.as_view(), name='cases-transferred-in'),
    path('cases/<str:pk>/transfer/', CaseTransferView.as_view(), name='case-transfer'),
    path('cases/<str:pk>/assign-io/', AssignTransferredCaseView.as_view(), name='case-assign-io'),
    path('cases/<str:pk>/pdf/', CasePdfView.as_view(), name='case-pdf'),
    path('cases/<str:pk>/', CrimeCaseManageView.as_view(), name='case-detail-manage'),
    path('cases/', CrimeCaseManageView.as_view(), name='case-create-list'),

    # Reference Data Cascades for Acts & Charges
    path('acts/', ActsView.as_view(), name='acts-list'),
    path('act-sections/', ActSectionsView.as_view(), name='act-sections-list'),
    path('act-subsections/', ActSubsectionsView.as_view(), name='act-subsections-list'),

    # Location Cascades for Transfer & Form Pickers
    path('divisions/', LocationDivisionsView.as_view(), name='location-divisions'),
    path('districts/', LocationDistrictsView.as_view(), name='location-districts'),
    path('stations/', LocationStationsView.as_view(), name='location-stations'),

    # Category Collections (Standalone & Dashboard Tabs)
    path('categories/standalone/', CaseCategoryViewSet.as_view({'get': 'standalone'}), name='category-standalone'),
    path('categories/dashboard-tabs/', CaseCategoryViewSet.as_view({'get': 'dashboard_tabs'}), name='category-dashboard-tabs'),

    # ID-based category routes (first priority)
    path('categories/<int:pk>/form-definition/', CaseCategoryViewSet.as_view({'get': 'form_definition'}), name='category-form-definition-by-id'),
    path('categories/<int:pk>/children/', CaseCategoryViewSet.as_view({'get': 'children'}), name='category-children-by-id'),
    path('categories/<int:pk>/counters/', CaseCategoryViewSet.as_view({'get': 'counters'}), name='category-counters-by-id'),
    path('categories/<int:pk>/cases/', CaseCategoryViewSet.as_view({'get': 'cases'}), name='category-cases-by-id'),
    path('categories/<int:pk>/', CaseCategoryViewSet.as_view({'get': 'retrieve'}), name='category-detail-by-id'),

    # Name-based category routes (path-converter for slashes, backwards compatibility)
    path('categories/<path:pk>/form-definition/', CaseCategoryViewSet.as_view({'get': 'form_definition'}), name='category-form-definition-by-name'),
    path('categories/<path:pk>/children/', CaseCategoryViewSet.as_view({'get': 'children'}), name='category-children-by-name'),
    path('categories/<path:pk>/counters/', CaseCategoryViewSet.as_view({'get': 'counters'}), name='category-counters-by-name'),
    path('categories/<path:pk>/cases/', CaseCategoryViewSet.as_view({'get': 'cases'}), name='category-cases-by-name'),
    path('categories/<path:pk>/', CaseCategoryViewSet.as_view({'get': 'retrieve'}), name='category-detail-by-name'),

    # Routers for groups, categories
    path('', include(router.urls)),
]

