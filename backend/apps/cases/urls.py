from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.cases.views import (
    CaseRecordViewSet,
    CrimeTypeListView,
    CasesByCrimeTypeView,
    SectionsByCrimeTypeView,
    CreateCaseView,
    PendingCasesView,
    DisposalCasesView,
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
    path('disposal/', DisposalCasesView.as_view(), name='disposal-cases'),

    # Existing CaseRecordViewSet router (ModelViewSet)
    path('', include(router.urls)),
]
