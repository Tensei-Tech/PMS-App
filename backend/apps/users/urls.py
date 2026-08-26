from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.users.views import OfficerProfileViewSet

router = DefaultRouter()
router.register(r'', OfficerProfileViewSet, basename='users')

urlpatterns = [
    path('', include(router.urls)),
]
