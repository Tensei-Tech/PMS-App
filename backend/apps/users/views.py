import logging
from django.utils import timezone
from django.db import transaction
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

logger = logging.getLogger(__name__)


DISTRICT_TO_DIVISION_MAP = {
    # Konkan Division
    'mumbai': 'Konkan Division', 'mumbai city': 'Konkan Division', 'mumbai suburban': 'Konkan Division',
    'thane': 'Konkan Division', 'palghar': 'Konkan Division', 'raigad': 'Konkan Division',
    'ratnagiri': 'Konkan Division', 'sindhudurg': 'Konkan Division', 'navi mumbai': 'Konkan Division',

    # Pune Division
    'pune': 'Pune Division', 'satara': 'Pune Division', 'solapur': 'Pune Division',
    'kolhapur': 'Pune Division', 'sangli': 'Pune Division', 'pimpri chinchwad': 'Pune Division',

    # Nashik Division
    'nashik': 'Nashik Division', 'ahmednagar': 'Nashik Division', 'ahilyanagar': 'Nashik Division',
    'dhule': 'Nashik Division', 'jalgaon': 'Nashik Division', 'nandurbar': 'Nashik Division',

    # Chhatrapati Sambhajinagar Division
    'aurangabad': 'Chhatrapati Sambhajinagar Division', 'chhatrapati sambhajinagar': 'Chhatrapati Sambhajinagar Division',
    'jalna': 'Chhatrapati Sambhajinagar Division', 'beed': 'Chhatrapati Sambhajinagar Division',
    'osmanabad': 'Chhatrapati Sambhajinagar Division', 'dharashiv': 'Chhatrapati Sambhajinagar Division',
    'nanded': 'Chhatrapati Sambhajinagar Division', 'parbhani': 'Chhatrapati Sambhajinagar Division',
    'hingoli': 'Chhatrapati Sambhajinagar Division', 'latur': 'Chhatrapati Sambhajinagar Division',

    # Amravati Division
    'amravati': 'Amravati Division', 'akola': 'Amravati Division', 'buldhana': 'Amravati Division',
    'yavatmal': 'Amravati Division', 'washim': 'Amravati Division',

    # Nagpur Division
    'nagpur': 'Nagpur Division', 'wardha': 'Nagpur Division', 'bhandara': 'Nagpur Division',
    'gondia': 'Nagpur Division', 'chandrapur': 'Nagpur Division', 'gadchiroli': 'Nagpur Division',
}


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

    @action(detail=False, methods=['get'], url_path='hierarchy-directory')
    def hierarchy_directory(self, request):
        """
        State Admin / Super Admin endpoint returning hierarchical directory:
        - Divisions & assigned Division Admins
        - Districts & assigned District Admins
        - Police Stations & assigned Station Heads (SHO/PI)
        """
        from apps.public_master.models import MasterDivision
        from apps.stations.models import District, PoliceStation
        from apps.core.tenancy import TenantContext, get_active_tenant_schema, set_tenant_schema

        active_schema = get_active_tenant_schema(request)

        # 1. Fetch all officers across active tenant schema and public schema
        officers_by_uid = {}
        try:
            with transaction.atomic():  # savepoint: a missing table spoils nothing else
                for off in OfficerProfile.objects.all():
                    if off.uid:
                        officers_by_uid[off.uid] = off
        except Exception:
            pass

        try:
            with transaction.atomic():  # savepoint: a missing table spoils nothing else
                set_tenant_schema('public')
                for pub_off in OfficerProfile.objects.all():
                    if pub_off.uid and pub_off.uid not in officers_by_uid:
                        officers_by_uid[pub_off.uid] = pub_off
        except Exception:
            pass
        finally:
            set_tenant_schema(active_schema)

        all_officers = list(officers_by_uid.values())

        # 2. Gather Divisions & Division Admins. A division is a sub-division
        # inside one district or city, named when its Division Admin is
        # created, so the tab lists the sub-divisions division admins hold
        # (plus any rows a state adds to master_divisions). Admin kinds come
        # from the role, never from the designation text.
        divisions_map = {}

        def division_entry(name, district=''):
            key = (name.strip().casefold(), district.strip().casefold())
            if key not in divisions_map:
                slug = '-'.join(p for p in (name, district) if p).lower().replace(' ', '-')
                divisions_map[key] = {'id': f"div-{slug}", 'name': name.strip(), 'district': district.strip(),
                                      'admins': []}
            return divisions_map[key]

        try:
            # Schema switch outside the savepoint: it must never run inside a
            # failed transaction (set_tenant_schema then drops the connection).
            with TenantContext(active_schema), transaction.atomic():
                for mdiv in MasterDivision.objects.all():
                    if getattr(mdiv, 'name', ''):
                        division_entry(mdiv.name)
        except Exception as e:
            logger.warning(f"[HierarchyDirectory] MasterDivision query failed in {active_schema}: {e}")

        for off in all_officers:
            if (off.role_id or '').lower() not in ('division_admin', 'supervisor'):
                continue
            division_entry(off.division_name or off.zone or 'Sub-division not set',
                           off.district or '')['admins'].append({
                'uid': off.uid,
                'name': off.name,
                'email': off.email,
                'phone': off.phone or '',
                'designation': off.designation or 'Division Admin',
                'badge_number': off.badge_number or '',
                'account_status': off.account_status,
            })

        # 3. Gather Districts & District Admins
        districts_map = {}
        try:
            with transaction.atomic():  # savepoint: a missing table spoils nothing else
                set_tenant_schema('public')
                master_districts = list(District.objects.all())
                for mdist in master_districts:
                    dist_name = getattr(mdist, 'name', None) or getattr(mdist, 'district_name', 'District')
                    dist_id = getattr(mdist, 'district_id', None) or getattr(mdist, 'id', '0')
                    districts_map[dist_name] = {
                        'id': f"dist-{dist_id}",
                        'name': dist_name,
                        'division_name': getattr(mdist, 'division_name', ''),
                        'admins': [],
                    }
        except Exception:
            pass
        finally:
            set_tenant_schema(active_schema)

        # Map District Admins (role_id == 'district_admin' or designation SP/CP/DCP, excluding Division Admins)
        for off in all_officers:
            # By role: a district admin with designation DIG is still a district admin.
            if (off.role_id or '').lower() == 'district_admin':
                dist_name = off.district or off.station_name or 'District HQ'
                if dist_name not in districts_map:
                    districts_map[dist_name] = {
                        'id': f"dist-{dist_name.lower().replace(' ', '-')}",
                        'name': dist_name,
                        'division_name': '',
                        'admins': [],
                    }
                districts_map[dist_name]['admins'].append({
                    'uid': off.uid,
                    'name': off.name,
                    'email': off.email,
                    'phone': off.phone or '',
                    'designation': off.designation or 'District Admin',
                    'badge_number': off.badge_number or '',
                    'account_status': off.account_status,
                })

        # 3b. Cities (police commissionerates) & City Admins. Cities have no
        # master list yet, so a city admin's city is the 'district' they hold.
        cities_map = {}
        for off in all_officers:
            if (off.role_id or '').lower() != 'city_admin':
                continue
            city_name = off.district or 'City'
            cities_map.setdefault(city_name, {
                'id': f"city-{city_name.lower().replace(' ', '-')}",
                'name': city_name,
                'admins': [],
            })['admins'].append({
                'uid': off.uid,
                'name': off.name,
                'email': off.email,
                'phone': off.phone or '',
                'designation': off.designation or 'City Admin',
                'badge_number': off.badge_number or '',
                'account_status': off.account_status,
            })

        # 4. Gather Police Stations & Station Heads
        stations_map = {}
        try:
            with transaction.atomic():  # savepoint: a missing table spoils nothing else
                set_tenant_schema('public')
                master_stations = list(PoliceStation.objects.all())
                for ps in master_stations:
                    st_name = getattr(ps, 'station_name', None) or getattr(ps, 'name', 'Police Station')
                    st_id = getattr(ps, 'station_id', None) or getattr(ps, 'id', '0')
                    st_dist = ps.district.name if hasattr(ps, 'district') and ps.district else getattr(ps, 'district_name', '')
                    stations_map[st_name] = {
                        'id': f"st-{st_id}",
                        'name': st_name,
                        'district': st_dist,
                        'head': None,
                    }
        except Exception:
            pass
        finally:
            set_tenant_schema(active_schema)

        # Map Station Heads (role_id == 'station_admin' or PI/SHO/Officer in charge)
        for off in all_officers:
            st_name = off.station_name
            if not st_name:
                continue
            if st_name not in stations_map:
                stations_map[st_name] = {
                    'id': f"st-{st_name.lower().replace(' ', '-')}",
                    'name': st_name,
                    'district': off.district or '',
                    'head': None,
                }

            role = (off.role_id or off.role or '').lower()
            desig = (off.designation or '').lower()
            is_head = role in ['station_admin'] or any(k in desig for k in ['pi', 'inspector', 'sho', 'in charge', 'station head'])

            if is_head or stations_map[st_name]['head'] is None:
                stations_map[st_name]['head'] = {
                    'uid': off.uid,
                    'name': off.name,
                    'email': off.email,
                    'phone': off.phone or '',
                    'designation': off.designation or 'Station Head',
                    'badge_number': off.badge_number or '',
                    'account_status': off.account_status,
                }

        # 5. Division Admin Scope Filtering (if caller is a Division Admin):
        # their own sub-division, and the districts and stations of their district.
        caller = request.user
        role_id = (getattr(caller, 'role_id', '') or '').lower()
        is_div_admin = role_id in ('division_admin', 'supervisor')

        user_division = None
        if is_div_admin:
            user_division = (getattr(caller, 'division_name', '') or getattr(caller, 'zone', '') or '').strip()
            caller_district = (getattr(caller, 'district', '') or '').strip().casefold()
            divisions_map = {
                k: v for k, v in divisions_map.items()
                if k[0] == user_division.casefold() and (not caller_district or k[1] in ('', caller_district))
            }
            if caller_district:
                districts_map = {k: v for k, v in districts_map.items() if k.strip().casefold() == caller_district}
                stations_map = {
                    k: v for k, v in stations_map.items()
                    if (v.get('district') or '').strip().casefold() == caller_district
                }

        return Response({
            'divisions': list(divisions_map.values()),
            'districts': list(districts_map.values()),
            # A division admin's scope holds no city.
            'cities': [] if is_div_admin else sorted(cities_map.values(), key=lambda c: c['name']),
            'stations': list(stations_map.values()),
            'scope': 'division' if is_div_admin else 'state',
            'assigned_division': user_division if is_div_admin else 'All Divisions',
        }, status=status.HTTP_200_OK)


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

