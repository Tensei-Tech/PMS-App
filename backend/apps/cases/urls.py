from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.cases.views import (
    DetectedCasesView,
    IOWiseDetectedView,
    TimeWiseDetectedView,
    CaseRecordViewSet,
    CrimeTypeListView,
    CasesByCrimeTypeView,
    SectionsByCrimeTypeView,
    CreateCaseView,
    PendingCasesView,
    IOWisePendingView,
    TimeWisePendingView,
    DisposalCaseWiseView,
    TimeWiseDisposalView,
    DesignationWiseDisposalView,
    DisposalCrimeTypeWiseView,
    ArrestedCaseWiseView,
    TimeWiseArrestedView,
    IOWiseArrestedView,
)

router = DefaultRouter()
router.register(r'', CaseRecordViewSet, basename='cases')

urlpatterns = [
    # Crime Type & Raw SQL Case Endpoints (placed before router to avoid pk shadowing)
    path('crime-types/', CrimeTypeListView.as_view(), name='crime-type-list'),
    path('crime-types/<str:crime_type>/cases/', CasesByCrimeTypeView.as_view(), name='cases-by-crime-type'),
    path('crime-types/<str:crime_type>/sections/', SectionsByCrimeTypeView.as_view(), name='sections-by-crime-type'),
    path('create/', CreateCaseView.as_view(), name='case-create'),
    path('pending/', PendingCasesView.as_view(), name='pending-cases'),
    path('pending/io-wise/', IOWisePendingView.as_view(), name='pending-io-wise'),
    path('pending/time-wise/', TimeWisePendingView.as_view(), name='pending-time-wise'),
    path('detected/', DetectedCasesView.as_view(), name='detected-cases'),
    path('detected/io-wise/', IOWiseDetectedView.as_view(), name='detected-io-wise'),
    path('detected/time-wise/', TimeWiseDetectedView.as_view(), name='detected-time-wise'),
    path('disposal/case-wise/', DisposalCaseWiseView.as_view(), name='disposal-case-wise'),
    path('disposal/time-wise/', TimeWiseDisposalView.as_view(), name='disposal-time-wise'),
    path('disposal/designation-wise/', DesignationWiseDisposalView.as_view(), name='disposal-designation-wise'),
    path('disposal/crime-type-wise/', DisposalCrimeTypeWiseView.as_view(), name='disposal-crime-type-wise'),
    
    path('arrested/case-wise/', ArrestedCaseWiseView.as_view(), name='arrested-case-wise'),
    path('arrested/time-wise/', TimeWiseArrestedView.as_view(), name='arrested-time-wise'),
    path('arrested/io-wise/', IOWiseArrestedView.as_view(), name='arrested-io-wise'),

    # Existing CaseRecordViewSet router (ModelViewSet)
    path('', include(router.urls)),
]
