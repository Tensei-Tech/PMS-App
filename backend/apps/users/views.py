from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.users.models import OfficerProfile
from apps.users.serializers import OfficerProfileSerializer, OfficerStatusUpdateSerializer
from apps.authentication.permissions import IsSupervisorOrAdmin


class OfficerProfileViewSet(viewsets.ModelViewSet):
    """
    API endpoint for viewing and editing officer profiles.
    """
    queryset = OfficerProfile.objects.all()
    serializer_class = OfficerProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if not user or not user.is_authenticated:
            return OfficerProfile.objects.none()

        if user.role == 'admin' or user.is_staff:
            return OfficerProfile.objects.all()

        # Officers see profiles from their station
        stations = [user.station_name] + (user.additional_stations or [])
        return OfficerProfile.objects.filter(station_name__in=stations)

    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get profile of current authenticated officer."""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='station-officers')
    def station_officers(self, request):
        """Get list of officers belonging to caller's station."""
        station_name = request.query_params.get('station_name', request.user.station_name)
        officers = OfficerProfile.objects.filter(station_name=station_name)
        serializer = self.get_serializer(officers, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['patch'], permission_classes=[IsSupervisorOrAdmin], url_path='update-status')
    def update_status(self, request, pk=None):
        """Supervisor/Admin action to update officer account status or role."""
        profile = self.get_object()
        serializer = OfficerStatusUpdateSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(OfficerProfileSerializer(profile).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
