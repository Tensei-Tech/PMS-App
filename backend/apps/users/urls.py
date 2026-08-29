from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.users.views import OfficerProfileViewSet, TransferRequestViewSet

router = DefaultRouter()
router.register(r'transfers', TransferRequestViewSet, basename='transfers')
router.register(r'', OfficerProfileViewSet, basename='users')

urlpatterns = [
    path('', include(router.urls)),
]

