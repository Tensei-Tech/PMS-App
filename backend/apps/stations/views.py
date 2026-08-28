from rest_framework import viewsets, permissions
from apps.stations.models import PoliceStation
from apps.stations.serializers import PoliceStationSerializer


from rest_framework.decorators import action
from rest_framework.response import Response
from apps.stations.models import PoliceStation, District


class PoliceStationViewSet(viewsets.ModelViewSet):
    """
    API endpoint for viewing and managing police stations directory dynamically from PostgreSQL DB.
    """
    queryset = PoliceStation.objects.all()
    serializer_class = PoliceStationSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = PoliceStation.objects.all()
        district = self.request.query_params.get('district')
        if district:
            qs = qs.filter(district_name__iexact=district.strip())
        return qs

    @action(detail=False, methods=['get'], url_path='districts')
    def list_districts(self, request):
        """Dynamic DB query for all Districts in current state schema."""
        # Query District model and fallback to unique station district_names
        dist_names = list(District.objects.values_list('name', flat=True))
        if not dist_names:
            dist_names = list(PoliceStation.objects.values_list('district_name', flat=True).distinct())

        if not dist_names:
            dist_names = ['Pune', 'Mumbai', 'Thane', 'Nagpur', 'Nashik', 'Chhatrapati Sambhajinagar']

        clean_list = sorted(list(set([d.strip() for d in dist_names if d and d.strip()])))
        return Response(clean_list)

    @action(detail=False, methods=['get'], url_path='divisions')
    def list_divisions(self, request):
        """Dynamic DB query for Divisions/Zones within a district."""
        district = request.query_params.get('district', '').strip()
        qs = PoliceStation.objects.all()
        if district:
            qs = qs.filter(district_name__iexact=district)

        zones = list(qs.values_list('zone', flat=True).distinct())
        clean_zones = sorted(list(set([z.strip() for z in zones if z and z.strip()])))

        if not clean_zones:
            prefix = district if district else 'City'
            clean_zones = [f"{prefix} Division 1", f"{prefix} Division 2", f"{prefix} Central Division"]

        return Response(clean_zones)
