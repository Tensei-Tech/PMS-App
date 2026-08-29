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

DEFAULT_6_DIVISIONS = [
    'Konkan Division',
    'Pune Division',
    'Nashik Division',
    'Chhatrapati Sambhajinagar Division',
    'Amravati Division',
    'Nagpur Division',
]


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
        from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema

        active_schema = get_active_tenant_schema(request)

        # 1. Fetch all officers across active tenant schema and public schema
        officers_by_uid = {}
        try:
            for off in OfficerProfile.objects.all():
                if off.uid:
                    officers_by_uid[off.uid] = off
        except Exception:
            pass

        try:
            set_tenant_schema('public')
            for pub_off in OfficerProfile.objects.all():
                if pub_off.uid and pub_off.uid not in officers_by_uid:
                    officers_by_uid[pub_off.uid] = pub_off
        except Exception:
            pass
        finally:
            set_tenant_schema(active_schema)

        all_officers = list(officers_by_uid.values())

        # 2. Gather Divisions & Division Admins

        divisions_map = {}
        # Seed 6 standard police divisions
        for dname in DEFAULT_6_DIVISIONS:
            divisions_map[dname] = {
                'id': f"div-{dname.lower().replace(' ', '-')}",
                'name': dname,
                'admins': [],
            }

        try:
            set_tenant_schema('public')
            master_divs = list(MasterDivision.objects.all())
            for mdiv in master_divs:
                if mdiv.division_name not in divisions_map:
                    divisions_map[mdiv.division_name] = {
                        'id': f"div-{mdiv.id}",
                        'name': mdiv.division_name,
                        'admins': [],
                    }
        except Exception:
            pass
        finally:
            set_tenant_schema(active_schema)

        # Map Division Admins (role_id == 'division_admin' or designation matching DySP/ACP/SDPO/DIG/IG)
        for off in all_officers:
            role = (off.role_id or off.role or '').lower()
            desig = (off.designation or '').lower()
            is_div_admin = role in ['division_admin', 'supervisor'] or any(k in desig for k in ['dysp', 'acp', 'sdpo', 'dig', 'ig', 'division admin'])
            if is_div_admin:
                raw_dist = (off.district or off.station_name or '').lower().strip()
                div_name = DISTRICT_TO_DIVISION_MAP.get(raw_dist)
                if not div_name:
                    # Fallback lookup in default 6 divisions if contains keyword
                    for dname in DEFAULT_6_DIVISIONS:
                        if dname.lower() in raw_dist or raw_dist in dname.lower():
                            div_name = dname
                            break
                if not div_name:
                    div_name = off.district or 'General Division'

                if div_name not in divisions_map:
                    divisions_map[div_name] = {
                        'id': f"div-{div_name.lower().replace(' ', '-')}",
                        'name': div_name,
                        'admins': [],
                    }
                divisions_map[div_name]['admins'].append({
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
            role = (off.role_id or off.role or '').lower()
            desig = (off.designation or '').lower()
            is_div_admin = role in ['division_admin', 'supervisor'] or any(k in desig for k in ['dysp', 'acp', 'sdpo', 'dig', 'spl. ig', 'special ig', 'division admin']) or (desig.endswith('ig') and 'dgp' not in desig)
            is_dist_admin = not is_div_admin and (role in ['district_admin'] or any(k in desig for k in ['superintendent', 'commissioner', 'district admin']) or (desig == 'sp' or desig.startswith('sp ') or desig.endswith(' sp') or ' dcp' in desig or 'dcp ' in desig))
            if is_dist_admin:
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

        # 4. Gather Police Stations & Station Heads
        stations_map = {}
        try:
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

        # 5. Division Admin Scope Filtering (if caller is a Division Admin)
        caller = request.user
        role_id = getattr(caller, 'role_id', '')
        desig = (getattr(caller, 'designation', '') or '').upper()
        is_state_super = role_id in ['state_admin', 'state_super_admin', 'super_admin', 'master_admin'] or desig in ['DG', 'DGP', 'ADG', 'ADGP']
        is_div_admin = not is_state_super and (role_id in ['division_admin', 'supervisor'] or any(k in desig for k in ['DYSP', 'ACP', 'SDPO', 'DIG', 'IG']))

        user_division = None
        if is_div_admin:
            # 1. Primary check: Direct assigned division_name (Division Admins operate across division, not single station/district)
            direct_div = (getattr(caller, 'division_name', '') or '').strip()
            if direct_div:
                for dname in DEFAULT_6_DIVISIONS:
                    if dname.lower() in direct_div.lower() or direct_div.lower() in dname.lower():
                        user_division = dname
                        break
                if not user_division:
                    user_division = direct_div

            # 2. Secondary fallback: Infer division from assigned district or station_name
            if not user_division:
                raw_dist = (getattr(caller, 'district', '') or getattr(caller, 'station_name', '') or '').lower().strip()
                user_division = DISTRICT_TO_DIVISION_MAP.get(raw_dist)
                if not user_division:
                    for dname in DEFAULT_6_DIVISIONS:
                        if dname.lower() in raw_dist or raw_dist in dname.lower():
                            user_division = dname
                            break
            if not user_division:
                user_division = getattr(caller, 'district', None)

            if user_division:
                # Keep ONLY user's assigned division
                divisions_map = {k: v for k, v in divisions_map.items() if k == user_division}

                # Identify all districts mapped under this division
                division_districts = set()
                for dist_k, div_v in DISTRICT_TO_DIVISION_MAP.items():
                    if div_v == user_division:
                        division_districts.add(dist_k.lower())

                # Filter districts_map to only districts inside user's division
                districts_map = {
                    k: v for k, v in districts_map.items()
                    if k.lower().strip() in division_districts or (v.get('division_name') or '') == user_division
                }

                # Filter stations_map to only stations inside user's division districts
                stations_map = {
                    k: v for k, v in stations_map.items()
                    if (v.get('district') or '').lower().strip() in division_districts
                }

        return Response({
            'divisions': list(divisions_map.values()),
            'districts': list(districts_map.values()),
            'stations': list(stations_map.values()),
            'scope': 'division' if is_div_admin else 'state',
            'assigned_division': user_division if is_div_admin else 'All State Divisions',
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

