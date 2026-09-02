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
    # Crime Type & Raw SQL Case Endpoints (before router to avoid pk pattern shadowing)
    path('api/crime-types/', CrimeTypeListView.as_view()),
    path('api/crime-types/<str:crime_type>/cases/', CasesByCrimeTypeView.as_view()),
    path('api/crime-types/<str:crime_type>/sections/', SectionsByCrimeTypeView.as_view()),
    path('api/cases/create/', CreateCaseView.as_view()),

    # Relative path aliases
    path('crime-types/', CrimeTypeListView.as_view()),
    path('crime-types/<str:crime_type>/cases/', CasesByCrimeTypeView.as_view()),
    path('crime-types/<str:crime_type>/sections/', SectionsByCrimeTypeView.as_view()),
    path('create/', CreateCaseView.as_view()),
    path('pending/', PendingCasesView.as_view()),
    path('disposal/', DisposalCasesView.as_view()),

    # Existing CaseRecordViewSet router
    path('', include(router.urls)),
]

