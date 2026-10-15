from django.urls import path
from .views import (
    CourseListCreateView,
    SubmitCourseCompletionView,
    OfficerCourseRecordsListView,
    InchargeDashboardAnalyticsView,
)

app_name = 'elearning'

urlpatterns = [
    path('courses/', CourseListCreateView.as_view(), name='course-list-create'),
    path('submit/', SubmitCourseCompletionView.as_view(), name='course-submit'),
    path('records/', OfficerCourseRecordsListView.as_view(), name='course-records-list'),
    path('analytics/', InchargeDashboardAnalyticsView.as_view(), name='incharge-analytics'),
]
