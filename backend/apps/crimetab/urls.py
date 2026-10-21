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
    IOWisePendingView,
    TimeWisePendingView,
    DetectedCasesView,
    CaseCountsView,
    IOWiseDetectedView,
    TimeWiseDetectedView,
    UndetectedCasesView,
    UndetectedIOWiseView,
    UndetectedTimeWiseView,
    AbscondedCasesView,
    AbscondedIOWiseView,
    AbscondedTimeWiseView,
    DisposalCaseWiseView,
    TimeWiseDisposalView,
    DesignationWiseDisposalView,
    DisposalCrimeTypeWiseView,
)

from apps.crimetab.views_rti import (
    RTIListCreateView,
    RTICountsView,
    RTIConfigView,
    RTIOfficersView,
    RTIDetailView,
    RTIPdfView,
    RTIChartView,
    RTIRemindersView,
    RTIRemindersSeenView,
    RTISendReminderView,
)

from apps.crimetab.views_history_sheeter import (
    HistorySheeterListCreateView,
    HistorySheeterCountsView,
    HistorySheeterConfigView,
    HistorySheeterDetailView,
    HistorySheeterPDFView,
    HistorySheeterChartView,
)

from apps.crimetab.views_mpda import (
    MpdaListCreateView,
    MpdaCountsView,
    MpdaConfigView,
    MpdaOfficersView,
    MpdaDetailView,
    MpdaPDFView,
    MpdaSummaryView,
    MpdaDetentionRemindersView,
    MpdaRemindersSeenView,
    MpdaSendReminderView,
)

from apps.crimetab.views_nc import (
    NcListCreateView,
    NcCountsView,
    NcConfigView,
    NcDetailView,
    NcPdfView,
    NcOfficersView,
)

from apps.crimetab.views_ad import (
    AdListCreateView,
    AdCountsView,
    AdConfigView,
    AdDetailView,
    AdPdfView,
)

from apps.crimetab.views_accident import (
    RoadAccidentListCreateView,
    RoadAccidentDetailView,
)

router = DefaultRouter()
router.register(r'groups', CaseCategoryGroupViewSet, basename='case-groups')
router.register(r'categories', CaseCategoryViewSet, basename='case-categories')

urlpatterns = [
    # RTI API Endpoints
    path('rti/counts/', RTICountsView.as_view(), name='rti-counts'),
    path('rti/config/', RTIConfigView.as_view(), name='rti-config'),
    path('rti/chart/', RTIChartView.as_view(), name='rti-chart'),
    path('rti/reminders/seen/', RTIRemindersSeenView.as_view(), name='rti-reminders-seen'),
    path('rti/reminders/', RTIRemindersView.as_view(), name='rti-reminders'),
    path('rti/<int:pk>/remind/', RTISendReminderView.as_view(), name='rti-remind'),
    path('rti/officers/', RTIOfficersView.as_view(), name='rti-officers'),
    path('rti/<int:pk>/pdf/', RTIPdfView.as_view(), name='rti-pdf'),
    path('rti/<int:pk>/', RTIDetailView.as_view(), name='rti-detail'),
    path('rti/', RTIListCreateView.as_view(), name='rti-list-create'),

    # History Sheeter Endpoints
    path('history-sheeter/counts/', HistorySheeterCountsView.as_view(), name='history-sheeter-counts'),
    path('history-sheeter/config/', HistorySheeterConfigView.as_view(), name='history-sheeter-config'),
    path('history-sheeter/chart/', HistorySheeterChartView.as_view(), name='history-sheeter-chart'),
    path('history-sheeter/<int:pk>/pdf/', HistorySheeterPDFView.as_view(), name='history-sheeter-pdf'),
    path('history-sheeter/<int:pk>/', HistorySheeterDetailView.as_view(), name='history-sheeter-detail'),
    path('history-sheeter/', HistorySheeterListCreateView.as_view(), name='history-sheeter-list-create'),

    # MPDA Endpoints
    path('mpda/counts/', MpdaCountsView.as_view(), name='mpda-counts'),
    path('mpda/config/', MpdaConfigView.as_view(), name='mpda-config'),
    path('mpda/summary/', MpdaSummaryView.as_view(), name='mpda-summary'),
    path('mpda/reminders/seen/', MpdaRemindersSeenView.as_view(), name='mpda-reminders-seen'),
    path('mpda/reminders/', MpdaDetentionRemindersView.as_view(), name='mpda-reminders'),
    path('mpda/<int:pk>/remind/', MpdaSendReminderView.as_view(), name='mpda-remind'),
    path('mpda/officers/', MpdaOfficersView.as_view(), name='mpda-officers'),
    path('mpda/<int:pk>/pdf/', MpdaPDFView.as_view(), name='mpda-pdf'),
    path('mpda/<int:pk>/', MpdaDetailView.as_view(), name='mpda-detail'),
    path('mpda/', MpdaListCreateView.as_view(), name='mpda-list-create'),

    # N.C. Endpoints (independent module, not cases)
    path('nc/counts/', NcCountsView.as_view(), name='nc-counts'),
    path('nc/config/', NcConfigView.as_view(), name='nc-config'),
    path('nc/officers/', NcOfficersView.as_view(), name='nc-officers'),
    path('nc/<int:pk>/pdf/', NcPdfView.as_view(), name='nc-pdf'),
    path('nc/<int:pk>/', NcDetailView.as_view(), name='nc-detail'),
    path('nc/', NcListCreateView.as_view(), name='nc-list-create'),

    # A.D. Endpoints (Suicide / Other sub-tabs; case records with module_key 'ad')
    path('ad/counts/', AdCountsView.as_view(), name='ad-counts'),
    path('ad/config/', AdConfigView.as_view(), name='ad-config'),
    path('ad/<str:pk>/pdf/', AdPdfView.as_view(), name='ad-pdf'),
    path('ad/<str:pk>/', AdDetailView.as_view(), name='ad-detail'),
    path('ad/', AdListCreateView.as_view(), name='ad-list-create'),

    # Road Accident Endpoints
    path('road-accident/<str:pk>/', RoadAccidentDetailView.as_view(), name='road-accident-detail'),
    path('road-accident/', RoadAccidentListCreateView.as_view(), name='road-accident-list-create'),

    # Options route for dynamic drop-downs & radios (e.g. GET /api/options/<group>/)
    path('options/<str:group>/', OptionValuesView.as_view(), name='option-values-by-group'),
    path('<path:slug>/form-schema/', FormSchemaView.as_view(), name='tab-form-schema'),
    # Case Management specific endpoints
    path('cases/crime-types/', CrimeTypeListView.as_view(), name='crime-type-list'),
    path('cases/crime-types/<path:crime_type>/cases/', CasesByCrimeTypeView.as_view(), name='cases-by-crime-type'),
    path('cases/crime-types/<path:crime_type>/sections/', SectionsByCrimeTypeView.as_view(), name='sections-by-crime-type'),
    path('cases/create/', CreateCaseView.as_view(), name='case-create'),
    path('cases/pending/', PendingCasesView.as_view(), name='pending-cases'),
    path('cases/pending/io-wise/', IOWisePendingView.as_view(), name='pending-io-wise'),
    path('cases/pending/time-wise/', TimeWisePendingView.as_view(), name='pending-time-wise'),
    path('cases/detected/', DetectedCasesView.as_view(), name='detected-cases-alias'),
    path('cases/detected/io-wise/', IOWiseDetectedView.as_view(), name='detected-io-wise'),
    path('cases/detected/time-wise/', TimeWiseDetectedView.as_view(), name='detected-time-wise'),
    path('cases/undetected/', UndetectedCasesView.as_view(), name='undetected-cases'),
    path('cases/undetected/io-wise/', UndetectedIOWiseView.as_view(), name='undetected-io-wise'),
    path('cases/undetected/time-wise/', UndetectedTimeWiseView.as_view(), name='undetected-time-wise'),
    path('cases/absconded/', AbscondedCasesView.as_view(), name='absconded-cases'),
    path('cases/absconded/io-wise/', AbscondedIOWiseView.as_view(), name='absconded-io-wise'),
    path('cases/absconded/time-wise/', AbscondedTimeWiseView.as_view(), name='absconded-time-wise'),
    path('cases/disposal/case-wise/', DisposalCaseWiseView.as_view(), name='disposal-case-wise'),
    path('cases/disposal/time-wise/', TimeWiseDisposalView.as_view(), name='disposal-time-wise'),
    path('cases/disposal/designation-wise/', DesignationWiseDisposalView.as_view(), name='disposal-designation-wise'),
    path('cases/disposal/crime-type-wise/', DisposalCrimeTypeWiseView.as_view(), name='disposal-crime-type-wise'),

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

