import logging
from rest_framework import viewsets, permissions, exceptions, status
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db import connection, transaction
from apps.cases.models import CaseRecord, is_ad_case_disposed
from apps.cases.serializers import CaseRecordSerializer, CreateCaseSerializer
from apps.core.permissions import check_dynamic_permission, HasPermission
from apps.repositories import CaseRepository

logger = logging.getLogger(__name__)


from apps.core.cache_decorators import cache_response
from apps.core.cache import upstash_cache


class CaseRecordViewSet(viewsets.ModelViewSet):
    """
    API endpoint for viewing, creating, updating, and filtering case records.
    Uses CaseRepository from feature repositories to encapsulate ORM access and 4-tier access checks.
    """
    queryset = CaseRecord.objects.all()
    serializer_class = CaseRecordSerializer
    permission_classes = [permissions.IsAuthenticated]

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.case_repo = CaseRepository()

    @cache_response(ttl=900, key_prefix="cases:list")
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    def perform_create(self, serializer):
        user = self.request.user
        if not check_dynamic_permission(user, 'case:create'):
            raise exceptions.PermissionDenied("You do not have permission to create case records.")

        created_by = getattr(user, 'uid', getattr(user, 'id', ''))
        station_name = getattr(user, 'station_name', '')

        serializer.save(
            created_by=serializer.validated_data.get('created_by') or str(created_by),
            station_name=serializer.validated_data.get('station_name') or station_name
        )
        upstash_cache.delete_pattern("pms:cache:*:cases:*")

    def perform_update(self, serializer):
        user = self.request.user
        instance = self.get_object()

        # Enforce case edit scope using Repository logic
        if not self.case_repo.can_officer_edit_case(user, instance):
            raise exceptions.PermissionDenied("You do not have permission to edit this case record.")

        serializer.save()
        upstash_cache.delete_pattern("pms:cache:*:cases:*")

    def perform_destroy(self, instance):
        user = self.request.user
        if not check_dynamic_permission(user, 'case:delete'):
            raise exceptions.PermissionDenied("Only Top Leadership and Master Admins can delete case records.")
        self.case_repo.delete(instance)
        upstash_cache.delete_pattern("pms:cache:*:cases:*")

    def get_queryset(self):
        user = self.request.user
        if not user or not user.is_authenticated:
            return CaseRecord.objects.none()

        # Dynamic DB Permission Check: District/State visibility vs Station visibility
        if check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all'):
            queryset = self.case_repo.get_all()
        else:
            stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
            queryset = self.case_repo.get_cases_for_stations(stations)

        # Apply query parameter filters
        module_key = self.request.query_params.get('module_key')
        if module_key:
            queryset = queryset.filter(module_key__iexact=module_key)

        status_param = self.request.query_params.get('status')
        if status_param:
            st_lower = status_param.lower()
            if st_lower in ['disposal', 'disposed', 'closed', 'resolved']:
                disposed_ids = [c.id for c in queryset if c.status in ['Disposal', 'Disposed', 'Closed', 'Resolved'] or is_ad_case_disposed(c)]
                queryset = queryset.filter(id__in=disposed_ids)
            elif st_lower in ['pending', 'open', 'active']:
                disposed_ids = [c.id for c in queryset if c.status in ['Disposal', 'Disposed', 'Closed', 'Resolved'] or is_ad_case_disposed(c)]
                queryset = queryset.exclude(id__in=disposed_ids)
            else:
                queryset = queryset.filter(status__iexact=status_param)

        assigned_uid = self.request.query_params.get('assigned_officer_uid')
        if assigned_uid:
            queryset = queryset.filter(assigned_officer_uid=assigned_uid)

        station_param = self.request.query_params.get('station_name')
        if station_param:
            queryset = queryset.filter(station_name=station_param)

        return queryset

    @cache_response(ttl=900, key_prefix="cases:assigned_to_me")
    @action(detail=False, methods=['get'], url_path='assigned-to-me')
    def assigned_to_me(self, request):
        """Get cases assigned to the authenticated officer."""
        user = request.user
        user_uid = str(getattr(user, 'uid', getattr(user, 'id', '')))
        if not user_uid:
            return Response([])

        active_only = request.query_params.get('active_only', 'true').lower() == 'true'
        queryset = self.case_repo.get_assigned_cases_for_officer(user_uid, active_only=active_only)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


# ------------------------------------------------------------------------------
# Raw SQL Database Views (Secured with Dynamic RBAC, Pagination & Safe Queries)
# ------------------------------------------------------------------------------

class PendingCasesView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from apps.cases.constants import CASE_STATUS_PENDING
            # Replaced raw SQL with ORM since pending_cases_combined does not exist
            queryset = CaseRecord.objects.filter(status=CASE_STATUS_PENDING)
            
            # Enforce station-level visibility
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            # Apply ?io filter
            io_name = request.query_params.get('io')
            if io_name:
                queryset = queryset.filter(assigned_officer=io_name)

            # Apply time range filter (start_date, end_date)
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            if start_date:
                queryset = queryset.filter(created_at__date__gte=start_date)
            if end_date:
                queryset = queryset.filter(created_at__date__lte=end_date)

            from apps.cases.serializers import CaseRecordSerializer
            
            paginator = PageNumberPagination()
            page = paginator.paginate_queryset(queryset.order_by('-created_at'), request)
            if page is not None:
                serializer = CaseRecordSerializer(page, many=True)
                return paginator.get_paginated_response(serializer.data)
                
            serializer = CaseRecordSerializer(queryset.order_by('-created_at'), many=True)
            return Response(serializer.data)
        except Exception as e:
            logger.exception(f"[PendingCasesView] Database error: {e}")
            return Response({'error': 'Failed to retrieve pending cases.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class IOWisePendingView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Count
            from apps.cases.constants import CASE_STATUS_PENDING
            # Don't exclude null uids so we can see cases where only assigned_officer name is set
            queryset = CaseRecord.objects.filter(status=CASE_STATUS_PENDING)
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            # Apply time range filter (start_date, end_date)
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            if start_date:
                queryset = queryset.filter(created_at__date__gte=start_date)
            if end_date:
                queryset = queryset.filter(created_at__date__lte=end_date)

            # Group by the string name if uid is missing
            counts = queryset.values('assigned_officer', 'station_name').annotate(count=Count('id')).order_by('-count')
            
            results = []
            for c in counts:
                name = c['assigned_officer']
                results.append({
                    'io_uid': name, # Use name as fallback uid for routing
                    'io_name': name if name else 'Unassigned',
                    'io_rank': '',
                    'station_name': c['station_name'],
                    'pending_count': c['count']
                })

            return Response(results)
        except Exception as e:
            logger.exception(f"[IOWisePendingView] Database error: {e}")
            return Response({'error': 'Failed to retrieve IO-wise counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class TimeWisePendingView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Q
            from django.utils import timezone
            from datetime import timedelta
            from apps.cases.constants import CASE_STATUS_PENDING
            
            queryset = CaseRecord.objects.filter(status=CASE_STATUS_PENDING)
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            now = timezone.now()
            month_1 = now - timedelta(days=30)
            months_3 = now - timedelta(days=90)
            months_6 = now - timedelta(days=180)
            year_1 = now - timedelta(days=365)

            under_1_month = queryset.filter(incident_date__gte=month_1).count()
            months_1_to_3 = queryset.filter(incident_date__gte=months_3, incident_date__lt=month_1).count()
            months_3_to_6 = queryset.filter(incident_date__gte=months_6, incident_date__lt=months_3).count()
            months_6_to_12 = queryset.filter(incident_date__gte=year_1, incident_date__lt=months_6).count()
            more_than_1_year = queryset.filter(incident_date__lt=year_1).count()
            
            results = [
                {'period': 'Under 1 month', 'count': under_1_month},
                {'period': '1 to 3 months', 'count': months_1_to_3},
                {'period': '3 to 6 months', 'count': months_3_to_6},
                {'period': '6 to 12 months', 'count': months_6_to_12},
                {'period': 'More than 1 year', 'count': more_than_1_year},
                {'period': 'Under 3 months (Total)', 'count': under_1_month + months_1_to_3}
            ]

            return Response(results)
        except Exception as e:
            logger.exception(f"[TimeWisePendingView] Database error: {e}")
            return Response({'error': 'Failed to retrieve Time-wise counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DisposalCasesView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT source, case_id, case_number, title, case_type, priority, station_name, assigned_officer, status
                    FROM disposal_cases_combined
                """)
                columns = [col[0] for col in cursor.description]
                rows = [dict(zip(columns, row)) for row in cursor.fetchall()]

            # Include any AD cases from CaseRecord table that qualify as disposal
            existing_ids = {r.get('case_id') for r in rows if r.get('case_id')}
            ad_cases = CaseRecord.objects.filter(module_key='ad')
            for c in ad_cases:
                if c.id not in existing_ids and is_ad_case_disposed(c):
                    rows.append({
                        'source': 'cases',
                        'case_id': c.id,
                        'case_number': c.case_number,
                        'title': c.title,
                        'case_type': c.module_key,
                        'priority': c.priority,
                        'station_name': c.station_name,
                        'assigned_officer': c.assigned_officer,
                        'status': 'Disposal',
                    })
                    existing_ids.add(c.id)

            paginator = PageNumberPagination()
            page = paginator.paginate_queryset(rows, request)
            if page is not None:
                return paginator.get_paginated_response(page)
            return Response(rows)
        except Exception as e:
            logger.exception(f"[DisposalCasesView] Database error: {e}")
            return Response({'error': 'Failed to retrieve disposal cases.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CasesByCrimeTypeView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request, crime_type):
        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT c.case_id, c.case_number, c.title, c.status, c.priority,
                           m.crime_type, m.act, m.section, m.sub_section, m.ipc_number
                    FROM cases c
                    JOIN crime_type_master m ON m.id = c.crime_type_master_id
                    WHERE m.crime_type = %s
                    ORDER BY c.created_at DESC
                """, [crime_type])
                columns = [col[0] for col in cursor.description]
                rows = [dict(zip(columns, row)) for row in cursor.fetchall()]

            paginator = PageNumberPagination()
            page = paginator.paginate_queryset(rows, request)
            if page is not None:
                return paginator.get_paginated_response(page)
            return Response(rows)
        except Exception as e:
            logger.exception(f"[CasesByCrimeTypeView] Database error: {e}")
            return Response({'error': 'Failed to retrieve cases by crime type.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CrimeTypeListView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT DISTINCT crime_type FROM crime_type_master WHERE crime_type IS NOT NULL AND crime_type != '' ORDER BY crime_type")
                rows = cursor.fetchall()
            return Response([r[0] for r in rows if r[0]])
        except Exception as e:
            logger.exception(f"[CrimeTypeListView] Database error: {e}")
            return Response({'error': 'Failed to retrieve crime types.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SectionsByCrimeTypeView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request, crime_type):
        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT id, act, section, sub_section, ipc_number
                    FROM crime_type_master
                    WHERE crime_type = %s
                    ORDER BY section, sub_section
                """, [crime_type])
                columns = [col[0] for col in cursor.description]
                rows = [dict(zip(columns, row)) for row in cursor.fetchall()]
            return Response(rows)
        except Exception as e:
            logger.exception(f"[SectionsByCrimeTypeView] Database error: {e}")
            return Response({'error': 'Failed to retrieve sections.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CreateCaseView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:create')]

    def post(self, request):
        serializer = CreateCaseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        validated = serializer.validated_data

        try:
            with transaction.atomic():
                with connection.cursor() as cursor:
                    cursor.execute("""
                        INSERT INTO cases (case_number, title, case_type, priority, status, module, crime_type_master_id)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        RETURNING case_id
                    """, [
                        validated['case_number'],
                        validated['title'],
                        validated.get('case_type', '1-5'),
                        validated.get('priority', 'Low'),
                        validated.get('status', 'Draft'),
                        validated['module'],
                        validated.get('crime_type_master_id')
                    ])
                    row = cursor.fetchone()
                    case_id = row[0] if row else None

            return Response({'case_id': case_id}, status=status.HTTP_201_CREATED)
        except Exception as e:
            logger.exception(f"[CreateCaseView] Database insertion failed: {e}")
            return Response({'error': 'Failed to create case record.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
