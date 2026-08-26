from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.stations.views import PoliceStationViewSet

router = DefaultRouter()
router.register(r'', PoliceStationViewSet, basename='stations')

urlpatterns = [
    path('', include(router.urls)),
]
