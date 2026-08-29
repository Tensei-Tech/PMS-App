from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.core.models import AuditLog, SosAlert
from apps.core.serializers import AuditLogSerializer, SosAlertSerializer


class AuditLogViewSet(viewsets.ModelViewSet):
    """
    API endpoint for logging & viewing security audit events with strict 4-tier ABAC hierarchy scoping.
    Prevents data leaks across State, Division, District, and Station boundaries.
    """
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if not user or not user.is_authenticated:
            return AuditLog.objects.none()

        role_id = (getattr(user, 'role_id', '') or getattr(user, 'role', '')).lower()
        desig = (getattr(user, 'designation', '') or '').upper()

        is_state_admin = role_id in ['state_admin', 'state_super_admin', 'super_admin', 'master_admin'] or desig in ['DG', 'DGP', 'ADG', 'ADGP']
        is_div_admin = not is_state_admin and (role_id in ['division_admin', 'supervisor'] or any(k in desig for k in ['DYSP', 'ACP', 'SDPO', 'DIG', 'IG']))
        is_district_admin = not is_state_admin and not is_div_admin and (role_id in ['district_admin'] or any(k in desig for k in ['SUPERINTENDENT', 'COMMISSIONER', 'SP', 'CP', 'DCP']))
        is_station_admin = not is_state_admin and not is_div_admin and not is_district_admin and (role_id in ['station_head', 'station_admin'] or any(k in desig for k in ['SHO', 'PI', 'API']))

        qs = AuditLog.objects.all()

        # 1. Scope Filtering (Zero Data Leak ABAC Control)
        if is_state_admin:
            pass  # State Admins see full state-wide audit logs
        elif is_div_admin:
            user_div = (getattr(user, 'division_name', '') or '').strip()
            if user_div:
                from apps.users.views import DISTRICT_TO_DIVISION_MAP
                div_districts = [k for k, v in DISTRICT_TO_DIVISION_MAP.items() if v.lower() in user_div.lower() or user_div.lower() in v.lower()]
                from django.db.models import Q
                qs = qs.filter(Q(division_name__iexact=user_div) | Q(district_name__in=div_districts))
            else:
                qs = AuditLog.objects.none()
        elif is_district_admin:
            user_dist = (getattr(user, 'district', '') or '').strip()
            if user_dist:
                qs = qs.filter(district_name__iexact=user_dist)
            else:
                qs = AuditLog.objects.none()
        elif is_station_admin:
            user_st = (getattr(user, 'station_name', '') or '').strip()
            if user_st:
                qs = qs.filter(station_name__iexact=user_st)
            else:
                qs = AuditLog.objects.none()
        else:
            # Regular officers only see their own audit actions
            qs = qs.filter(uid=getattr(user, 'uid', ''))

        # 2. Query Parameter Filters (Search, Category)
        query = self.request.query_params.get('q', '').strip()
        if query:
            from django.db.models import Q
            qs = qs.filter(
                Q(event__icontains=query) |
                Q(user_name__icontains=query) |
                Q(user_email__icontains=query) |
                Q(action_details__icontains=query) |
                Q(ip_address__icontains=query)
            )

        category = self.request.query_params.get('category', '').strip()
        if category and category != 'all':
            qs = qs.filter(category__iexact=category)

        return qs.order_by('-created_at')


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
