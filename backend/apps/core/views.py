from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.core.models import AuditLog, SosAlert
from apps.core.serializers import AuditLogSerializer, SosAlertSerializer


class AuditLogViewSet(viewsets.ModelViewSet):
    """
    API endpoint for logging & viewing security audit events.
    """
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.AllowAny]  # Allows logging unauthenticated login failures

    def get_queryset(self):
        user = self.request.user
        if not user or not user.is_authenticated:
            return AuditLog.objects.none()
        if getattr(user, 'role', '') in ['admin', 'state_super_admin', 'master_admin']:
            return AuditLog.objects.all()
        return AuditLog.objects.filter(uid=getattr(user, 'uid', ''))


class SosAlertViewSet(viewsets.ModelViewSet):
    """
    API endpoint for triggering & managing Emergency Duress SOS Alerts.
    """
    queryset = SosAlert.objects.all()
    serializer_class = SosAlertSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        station_name = self.request.query_params.get('station_name')
        district = self.request.query_params.get('district')
        active_only = self.request.query_params.get('active')

        qs = SosAlert.objects.all()
        if active_only and active_only.lower() == 'true':
            qs = qs.filter(status='ACTIVE_DURESS', is_resolved=False)
        if station_name:
            qs = qs.filter(station_name=station_name)
        if district:
            qs = qs.filter(district=district)
        return qs

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Resolve active SOS alert."""
        sos = self.get_object()
        resolution_note = request.data.get('resolution_note', 'Resolved by supervisor.')
        resolver_uid = request.data.get('resolved_by_uid', getattr(request.user, 'uid', 'admin'))

        sos.status = 'RESOLVED'
        sos.is_resolved = True
        sos.resolution_note = resolution_note
        sos.resolved_by_uid = resolver_uid
        sos.resolved_at = timezone.now()
        sos.save()
        return Response(SosAlertSerializer(sos).data)
