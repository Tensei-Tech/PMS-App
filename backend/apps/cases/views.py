from rest_framework import viewsets, permissions, status, exceptions
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import connection
from apps.cases.models import CaseRecord
from apps.cases.serializers import CaseRecordSerializer
from apps.core.permissions import check_dynamic_permission
from apps.repositories import CaseRepository


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

        role_id = getattr(user, 'role_id', 'officer')

        # Dynamic DB Permission Check: District/State visibility vs Station visibility
        if check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all'):
            queryset = self.case_repo.get_all()
        else:
            stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
            queryset = self.case_repo.get_cases_for_stations(stations)


        # Apply query parameter filters
        module_key = self.request.query_params.get('module_key')
        if module_key:
            queryset = queryset.filter(module_key=module_key)

        status_param = self.request.query_params.get('status')
        if status_param:
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
# Raw SQL Database Views
# ------------------------------------------------------------------------------

class PendingCasesView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM pending_cases_combined")
            columns = [col[0] for col in cursor.description]
            rows = [dict(zip(columns, row)) for row in cursor.fetchall()]
        return Response(rows)


class DisposalCasesView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM disposal_cases_combined")
            columns = [col[0] for col in cursor.description]
            rows = [dict(zip(columns, row)) for row in cursor.fetchall()]
        return Response(rows)


class CasesByCrimeTypeView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, crime_type):
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
        return Response(rows)


class CrimeTypeListView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        with connection.cursor() as cursor:
            cursor.execute("SELECT DISTINCT crime_type FROM crime_type_master ORDER BY crime_type")
            rows = cursor.fetchall()
        return Response([r[0] for r in rows])


class SectionsByCrimeTypeView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, crime_type):
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


class CreateCaseView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        data = request.data
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO cases (case_number, title, case_type, priority, status, module, crime_type_master_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING case_id
            """, [
                data['case_number'], data['title'],
                '1-5',
                data['priority'], 'Draft', data['module'], data['crime_type_master_id']
            ])
            case_id = cursor.fetchone()[0]
        return Response({'case_id': case_id}, status=201)

