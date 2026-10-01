from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.cases.views import (
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
    path('disposal/case-wise/', DisposalCaseWiseView.as_view(), name='disposal-case-wise'),
    path('disposal/time-wise/', TimeWiseDisposalView.as_view(), name='disposal-time-wise'),
    path('disposal/designation-wise/', DesignationWiseDisposalView.as_view(), name='disposal-designation-wise'),
    # Existing CaseRecordViewSet router (ModelViewSet)
    path('', include(router.urls)),
]
