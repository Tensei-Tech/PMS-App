from rest_framework import viewsets, permissions
from apps.stations.models import PoliceStation
from apps.stations.serializers import PoliceStationSerializer


class PoliceStationViewSet(viewsets.ModelViewSet):
    """
    API endpoint for viewing and managing police stations directory.
    """
    queryset = PoliceStation.objects.all()
    serializer_class = PoliceStationSerializer
    permission_classes = [permissions.IsAuthenticated]
