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
)

from apps.cases.views import (
    CrimeTypeListView,
    CasesByCrimeTypeView,
    SectionsByCrimeTypeView,
    CreateCaseView,
    PendingCasesView,
    DisposalCaseWiseView,
)

router = DefaultRouter()
router.register(r'groups', CaseCategoryGroupViewSet, basename='case-groups')
router.register(r'categories', CaseCategoryViewSet, basename='case-categories')

urlpatterns = [
    path('<str:slug>/form-schema/', FormSchemaView.as_view(), name='tab-form-schema'),
    # Case Management specific endpoints
    path('cases/crime-types/', CrimeTypeListView.as_view(), name='crime-type-list'),
    path('cases/crime-types/<str:crime_type>/cases/', CasesByCrimeTypeView.as_view(), name='cases-by-crime-type'),
    path('cases/crime-types/<str:crime_type>/sections/', SectionsByCrimeTypeView.as_view(), name='sections-by-crime-type'),
    path('cases/create/', CreateCaseView.as_view(), name='case-create'),
    path('cases/pending/', PendingCasesView.as_view(), name='pending-cases'),
    path('cases/disposal/', DisposalCaseWiseView.as_view(), name='disposal-cases'),

    # Explicit Action Endpoints for Cases
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

    # Routers for groups, categories
    path('', include(router.urls)),
]

