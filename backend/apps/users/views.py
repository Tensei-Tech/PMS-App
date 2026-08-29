from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.users.models import OfficerProfile
from apps.users.serializers import (
    OfficerProfileSerializer,
    OfficerStatusUpdateSerializer,
    TransferRequestSerializer,
)
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

    @action(detail=True, methods=['patch'], permission_classes=[permissions.IsAuthenticated], url_path='grant-station-access')
    def grant_station_access(self, request, pk=None):
        """PI/API action to toggle station_case_view_granted for an officer."""
        profile = self.get_object()
        granted = request.data.get('station_case_view_granted', True)
        profile.station_case_view_granted = granted
        profile.save()
        return Response(OfficerProfileSerializer(profile).data)


class TransferRequestViewSet(viewsets.ModelViewSet):
    """
    API endpoint for handling officer station/district transfer requests.
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = TransferRequestSerializer

    def get_queryset(self):
        from apps.users.models import TransferRequest
        user = self.request.user
        if not user or not user.is_authenticated:
            return TransferRequest.objects.none()

        uid = self.request.query_params.get('uid')
        if uid:
            return TransferRequest.objects.filter(requested_by_uid=uid)

        approver_station = self.request.query_params.get('to_station_name')
        approver_district = self.request.query_params.get('to_district')
        status_filter = self.request.query_params.get('status')

        qs = TransferRequest.objects.all()
        if status_filter:
            qs = qs.filter(status=status_filter)
        if approver_station:
            qs = qs.filter(to_station_name=approver_station)
        if approver_district:
            qs = qs.filter(to_district=approver_district)
        return qs

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve transfer request and update officer posting in database."""
        from apps.users.models import TransferRequest
        transfer = self.get_object()
        approver_uid = request.data.get('approved_by_uid', getattr(request.user, 'uid', 'admin'))
        
        transfer.status = 'approved'
        transfer.approved_by_uid = approver_uid
        transfer.approved_at = timezone.now()
        transfer.save()

        # Update officer's primary posting
        try:
            profile = OfficerProfile.objects.get(uid=transfer.requested_by_uid)
            if transfer.to_designation:
                profile.designation = transfer.to_designation
            if transfer.to_station_name:
                profile.station_name = transfer.to_station_name
            if transfer.to_district:
                profile.district = transfer.to_district
            profile.save()
        except OfficerProfile.DoesNotExist:
            pass

        return Response(TransferRequestSerializer(transfer).data)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject transfer request with optional reason."""
        transfer = self.get_object()
        rejection_reason = request.data.get('rejection_reason', '')
        rejecter_uid = request.data.get('rejected_by_uid', getattr(request.user, 'uid', 'admin'))

        transfer.status = 'rejected'
        transfer.rejected_by_uid = rejecter_uid
        transfer.rejection_reason = rejection_reason
        transfer.rejected_at = timezone.now()
        transfer.save()
        return Response(TransferRequestSerializer(transfer).data)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel transfer request."""
        transfer = self.get_object()
        transfer.status = 'cancelled'
        transfer.save()
        return Response(TransferRequestSerializer(transfer).data)

