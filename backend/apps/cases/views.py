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

    def _link_case_category(self, instance):
        try:
            from apps.crimetab.models.groupings import CaseCategory, CaseCategoryLink
            from django.db.models import Q
            found_cat = None
            if instance.sub_category and instance.sub_category.strip():
                found_cat = CaseCategory.objects.filter(
                    category_name__iexact=instance.sub_category.strip()
                ).first()
            if not found_cat and instance.module_key and instance.module_key.strip():
                norm = instance.module_key.replace('_', ' ').strip()
                found_cat = CaseCategory.objects.filter(
                    Q(category_code__iexact=instance.module_key.strip()) |
                    Q(category_name__iexact=norm) |
                    Q(category_name__iexact=instance.module_key.strip())
                ).first()
            if found_cat:
                CaseCategoryLink.objects.get_or_create(
                    case=instance,
                    category=found_cat,
                    defaults={'is_primary': True}
                )
        except Exception as e:
            logger.debug(f"Failed to auto-link case category: {e}")

    def perform_create(self, serializer):
        user = self.request.user
        if not check_dynamic_permission(user, 'case:create'):
            raise exceptions.PermissionDenied("You do not have permission to create case records.")

        created_by = getattr(user, 'uid', getattr(user, 'id', ''))
        station_name = getattr(user, 'station_name', '')

        instance = serializer.save(
            created_by=serializer.validated_data.get('created_by') or str(created_by),
            station_name=serializer.validated_data.get('station_name') or station_name
        )
        self._link_case_category(instance)
        upstash_cache.delete_pattern("pms:cache:*:cases:*")

    def perform_update(self, serializer):
        user = self.request.user
        instance = self.get_object()

        # Enforce case edit scope using Repository logic
        if not self.case_repo.can_officer_edit_case(user, instance):
            raise exceptions.PermissionDenied("You do not have permission to edit this case record.")

        instance = serializer.save()
        self._link_case_category(instance)
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
            from django.db.models import Q
            from apps.crimetab.models.groupings import CaseCategory
            mod_lower = module_key.lower().strip()
            if mod_lower == 'undetected':
                undetected_q = (
                    Q(accused__isnull=True) |
                    Q(accused__exact='') |
                    Q(accused__iexact='unknown') |
                    Q(accused__iexact='अज्ञात') |
                    Q(accused__iexact='unidentified')
                )
                queryset = queryset.filter(undetected_q).exclude(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])
            elif mod_lower == 'detected':
                detected_q = (
                    Q(accused__isnull=False) &
                    ~Q(accused__exact='') &
                    ~Q(accused__iexact='unknown') &
                    ~Q(accused__iexact='अज्ञात') &
                    ~Q(accused__iexact='unidentified')
                )
                queryset = queryset.filter(detected_q).exclude(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])
            elif mod_lower == 'absconded':
                from apps.cases.utils import get_absconded_cases
                absconded_qs = get_absconded_cases()
                queryset = queryset.filter(id__in=absconded_qs.values_list('id', flat=True))
            elif mod_lower in ['form_1_5', 'form_iv', 'form_i_v', '1_to_5']:
                # Group 1 (Form I to V / Parts 1–5): Form 1-5 + all Group 1 categories
                group_1_cats = list(CaseCategory.objects.filter(
                    Q(group_id=1) | Q(group__group_code__iexact='I TO V')
                ).values_list('category_name', flat=True))
                group_1_codes = list(CaseCategory.objects.filter(
                    Q(group_id=1) | Q(group__group_code__iexact='I TO V')
                ).values_list('category_code', flat=True))

                known_g1 = {
                    'form_1_5', 'murder', 'attempt_to_murder', 'dacoity', 'robbery', 'hbt',
                    'theft', 'riot', 'unlawful_assembly', 'kidnapping', 'cbt', 'cheating',
                    'mischief', 'hurt', 'assault_on_public_servant', 'rape', 'molestation',
                    'extortion', 'ipc_304', '498_a_ipc', 'other_ipc', 'chain_snatching',
                    'sand_theft', 'two_four_wheeler', 'two_wheeler', 'missing',
                    'crime_women', 'accident', 'bnss', 'coin', 'suicide', 'absconded',
                    'arrested', 'juvenile', 'victim'
                }
                for c in group_1_codes:
                    if c:
                        known_g1.add(c.lower().strip())

                q_group = (
                    Q(module_key__in=list(known_g1)) |
                    Q(category_links__category__group_id=1) |
                    Q(category_links__category__group__group_code__iexact='I TO V')
                )
                for name in group_1_cats:
                    if name:
                        q_group |= Q(sub_category__iexact=name)

                queryset = queryset.filter(q_group).distinct()

            elif mod_lower in ['form_6', 'form_vi', 'part_6']:
                # Group 2 (Form VI / Part 6): Form 6 + all Group 2 categories
                group_2_cats = list(CaseCategory.objects.filter(
                    Q(group_id=2) | Q(group__group_code__iexact='VI')
                ).values_list('category_name', flat=True))
                group_2_codes = list(CaseCategory.objects.filter(
                    Q(group_id=2) | Q(group__group_code__iexact='VI')
                ).values_list('category_code', flat=True))

                known_g2 = {
                    'form_6', 'st_drugs', 'prohibition', 'gambling', 'pocso', 'ndps',
                    'gowans', 'it_act', 'mv_act', 'traffic', 'uapa', 'mcoca', 'mpda',
                    'passport', 'sam_warrant', 'muddemal', 'application'
                }
                for c in group_2_codes:
                    if c:
                        known_g2.add(c.lower().strip())

                q_group = (
                    Q(module_key__in=list(known_g2)) |
                    Q(category_links__category__group_id=2) |
                    Q(category_links__category__group__group_code__iexact='VI')
                )
                for name in group_2_cats:
                    if name:
                        q_group |= Q(sub_category__iexact=name)

                queryset = queryset.filter(q_group).distinct()

            else:
                # Specific category / module
                norm_name = module_key.replace('_', ' ').strip()
                q_mod = (
                    Q(module_key__iexact=module_key) |
                    Q(sub_category__iexact=norm_name) |
                    Q(sub_category__iexact=module_key) |
                    Q(category_links__category__category_name__iexact=norm_name) |
                    Q(category_links__category__category_code__iexact=module_key)
                )
                queryset = queryset.filter(q_mod).distinct()

        status_param = self.request.query_params.get('status')
        if status_param:
            st_lower = status_param.lower()
            if st_lower in ['disposal', 'disposed', 'closed', 'resolved']:
                queryset = queryset.filter(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])
            elif st_lower in ['pending', 'open', 'active']:
                queryset = queryset.exclude(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])
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
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('pending')
            
            # Enforce station-level visibility
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            # Apply ?io filter
            io_name = request.query_params.get('io')
            if io_name:
                queryset = queryset.filter(assigned_officer=io_name)

            # Apply ?head filter (category)
            head = request.query_params.get('head')
            if head:
                queryset = queryset.filter(head__iexact=head)

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
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('pending')
            
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
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('pending')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            now = timezone.now()
            month_1 = now - timedelta(days=30)
            months_3 = now - timedelta(days=90)
            months_6 = now - timedelta(days=180)
            year_1 = now - timedelta(days=365)

            under_1_month = queryset.filter(created_at__gte=month_1).count()
            months_1_to_3 = queryset.filter(created_at__gte=months_3, created_at__lt=month_1).count()
            months_3_to_6 = queryset.filter(created_at__gte=months_6, created_at__lt=months_3).count()
            months_6_to_12 = queryset.filter(created_at__gte=year_1, created_at__lt=months_6).count()
            more_than_1_year = queryset.filter(created_at__lt=year_1).count()
            
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

class UndetectedCasesView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Q
            undetected_q = (
                Q(accused__isnull=True) |
                Q(accused__exact='') |
                Q(accused__iexact='unknown') |
                Q(accused__iexact='अज्ञात') |
                Q(accused__iexact='unidentified')
            )
            queryset = CaseRecord.objects.filter(undetected_q).exclude(
                status__in=['Disposal', 'Disposed', 'Closed', 'Resolved']
            )

            # Enforce station-level visibility
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            # Apply ?io filter
            io_name = request.query_params.get('io')
            if io_name:
                queryset = queryset.filter(assigned_officer=io_name)

            # Apply ?category / ?head filter
            category = request.query_params.get('category') or request.query_params.get('head')
            if category:
                norm_cat = category.replace('_', ' ').strip()
                queryset = queryset.filter(
                    Q(module_key__iexact=category) |
                    Q(sub_category__iexact=category) |
                    Q(sub_category__iexact=norm_cat) |
                    Q(category_links__category__category_name__iexact=norm_cat) |
                    Q(category_links__category__category_code__iexact=category)
                ).distinct()

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
            logger.exception(f"[UndetectedCasesView] Database error: {e}")
            return Response({'error': 'Failed to retrieve undetected cases.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class UndetectedIOWiseView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Count, Q
            undetected_q = (
                Q(accused__isnull=True) |
                Q(accused__exact='') |
                Q(accused__iexact='unknown') |
                Q(accused__iexact='अज्ञात') |
                Q(accused__iexact='unidentified')
            )
            queryset = CaseRecord.objects.filter(undetected_q).exclude(
                status__in=['Disposal', 'Disposed', 'Closed', 'Resolved']
            )

            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            if start_date:
                queryset = queryset.filter(created_at__date__gte=start_date)
            if end_date:
                queryset = queryset.filter(created_at__date__lte=end_date)

            counts = queryset.values('assigned_officer', 'station_name').annotate(count=Count('id')).order_by('-count')
            results = []
            for c in counts:
                name = c['assigned_officer']
                results.append({
                    'io_uid': name,
                    'io_name': name if name else 'Unassigned',
                    'io_rank': '',
                    'station_name': c['station_name'],
                    'undetected_count': c['count'],
                    'pending_count': c['count'],
                })

            return Response(results)
        except Exception as e:
            logger.exception(f"[UndetectedIOWiseView] Database error: {e}")
            return Response({'error': 'Failed to retrieve IO-wise undetected counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class UndetectedTimeWiseView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Q
            from django.utils import timezone
            from datetime import timedelta

            undetected_q = (
                Q(accused__isnull=True) |
                Q(accused__exact='') |
                Q(accused__iexact='unknown') |
                Q(accused__iexact='अज्ञात') |
                Q(accused__iexact='unidentified')
            )
            queryset = CaseRecord.objects.filter(undetected_q).exclude(
                status__in=['Disposal', 'Disposed', 'Closed', 'Resolved']
            )

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
            logger.exception(f"[UndetectedTimeWiseView] Database error: {e}")
            return Response({'error': 'Failed to retrieve Time-wise undetected counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AbscondedCasesView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Q
            from apps.cases.utils import get_absconded_cases
            queryset = get_absconded_cases()

            # Enforce station-level visibility
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            # Apply ?io filter
            io_name = request.query_params.get('io')
            if io_name:
                queryset = queryset.filter(assigned_officer=io_name)

            # Apply ?category / ?head filter
            category = request.query_params.get('category') or request.query_params.get('head')
            if category:
                norm_cat = category.replace('_', ' ').strip()
                queryset = queryset.filter(
                    Q(module_key__iexact=category) |
                    Q(sub_category__iexact=category) |
                    Q(sub_category__iexact=norm_cat) |
                    Q(category_links__category__category_name__iexact=norm_cat) |
                    Q(category_links__category__category_code__iexact=category)
                ).distinct()

            # Apply ?status filter (pending or disposal)
            status_param = request.query_params.get('status')
            if status_param:
                st_lower = status_param.lower().strip()
                if st_lower in ['disposal', 'disposed', 'closed', 'resolved']:
                    queryset = queryset.filter(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])
                elif st_lower in ['pending', 'open', 'active']:
                    queryset = queryset.exclude(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])

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
            logger.exception(f"[AbscondedCasesView] Database error: {e}")
            return Response({'error': 'Failed to retrieve absconded cases.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AbscondedIOWiseView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Count
            from apps.cases.utils import get_absconded_cases
            queryset = get_absconded_cases()

            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            status_param = request.query_params.get('status')
            if status_param:
                st_lower = status_param.lower().strip()
                if st_lower in ['disposal', 'disposed', 'closed', 'resolved']:
                    queryset = queryset.filter(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])
                elif st_lower in ['pending', 'open', 'active']:
                    queryset = queryset.exclude(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])

            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            if start_date:
                queryset = queryset.filter(created_at__date__gte=start_date)
            if end_date:
                queryset = queryset.filter(created_at__date__lte=end_date)

            counts = queryset.values('assigned_officer', 'station_name').annotate(count=Count('id')).order_by('-count')
            results = []
            for c in counts:
                name = c['assigned_officer']
                results.append({
                    'io_uid': name,
                    'io_name': name if name else 'Unassigned',
                    'io_rank': '',
                    'station_name': c['station_name'],
                    'absconded_count': c['count'],
                    'pending_count': c['count'],
                })

            return Response(results)
        except Exception as e:
            logger.exception(f"[AbscondedIOWiseView] Database error: {e}")
            return Response({'error': 'Failed to retrieve IO-wise absconded counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AbscondedTimeWiseView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.utils import timezone
            from datetime import timedelta
            from apps.cases.utils import get_absconded_cases
            queryset = get_absconded_cases()

            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            status_param = request.query_params.get('status')
            if status_param:
                st_lower = status_param.lower().strip()
                if st_lower in ['disposal', 'disposed', 'closed', 'resolved']:
                    queryset = queryset.filter(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])
                elif st_lower in ['pending', 'open', 'active']:
                    queryset = queryset.exclude(status__in=['Disposal', 'Disposed', 'Closed', 'Resolved'])

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
            logger.exception(f"[AbscondedTimeWiseView] Database error: {e}")
            return Response({'error': 'Failed to retrieve time-wise absconded counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DisposalCaseWiseView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('disposal')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            io_uid = request.query_params.get('io_uid')
            if io_uid:
                queryset = queryset.filter(assigned_officer_uid=io_uid)

            from django.db.models.fields.json import KeyTextTransform
            start_date = request.query_params.get('start_date') or request.query_params.get('from_date')
            end_date = request.query_params.get('end_date') or request.query_params.get('to_date')
            
            if start_date or end_date:
                # Exclude cases with no disposal_date or empty disposal_date
                queryset = queryset.exclude(extra_fields__disposal_date__isnull=True)
                queryset = queryset.exclude(extra_fields__disposal_date__exact='')
            if start_date:
                queryset = queryset.filter(extra_fields__disposal_date__gte=start_date)
            if end_date:
                queryset = queryset.filter(extra_fields__disposal_date__lte=end_date)
                
            district = request.query_params.get('district')
            if district:
                from apps.public_master.models import District, PoliceStation
                try:
                    d = District.objects.get(name__iexact=district)
                    stations_in_district = PoliceStation.objects.filter(district=d).values_list('name', flat=True)
                    queryset = queryset.filter(station_name__in=stations_in_district)
                except District.DoesNotExist:
                    queryset = queryset.none()

            station = request.query_params.get('station')
            if station:
                queryset = queryset.filter(station_name=station)
                
            crime_type = request.query_params.get('crime_type')
            if crime_type:
                from django.db.models import Q
                queryset = queryset.filter(Q(module_key__iexact=crime_type) | Q(sub_category__iexact=crime_type))
                
            search = request.query_params.get('search')
            if search:
                queryset = queryset.filter(case_number__icontains=search)

            from apps.cases.serializers import DisposalCaseRecordSerializer
            from django.db.models.fields.json import KeyTextTransform
            
            # Order by module_key (grouping), then disposal_date (descending), then created_at, then id
            queryset = queryset.annotate(parsed_disposal_date=KeyTextTransform('disposal_date', 'extra_fields')).order_by('module_key', '-parsed_disposal_date', '-created_at', 'id')
            
            from apps.crimetab.models.groupings import CaseCategory
            cats = CaseCategory.objects.all()
            cat_map = {}
            for c in cats:
                if c.category_code:
                    cat_map[c.category_code.lower()] = c.category_name
                if c.category_name:
                    cat_map[c.category_name.lower()] = c.category_name

            from rest_framework.pagination import PageNumberPagination
            paginator = PageNumberPagination()
            paginator.page_size = 20
            paginator.page_size_query_param = 'page_size'
            print("Queryset count in view:", queryset.count())
            page = paginator.paginate_queryset(queryset, request)
            if page is not None:
                serializer = DisposalCaseRecordSerializer(page, many=True, context={'cat_map': cat_map})
                results = serializer.data
                page_number = paginator.page.number
                page_size = paginator.page.paginator.per_page
                for idx, row in enumerate(results):
                    row['sr_no'] = (page_number - 1) * page_size + idx + 1
                return paginator.get_paginated_response(results)
                
            serializer = DisposalCaseRecordSerializer(queryset, many=True, context={'cat_map': cat_map})
            results = serializer.data
            for idx, row in enumerate(results):
                row['sr_no'] = idx + 1
            return Response(results)
        except Exception as e:
            logger.exception(f"[DisposalCaseWiseView] Database error: {e}")
            return Response({'error': 'Failed to retrieve disposal cases.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class TimeWiseDisposalView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models.fields.json import KeyTextTransform
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('disposal')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            district = request.query_params.get('district')
            if district:
                from apps.stations.models import PoliceStation
                stations = PoliceStation.objects.filter(district__name__iexact=district).values_list('station_name', flat=True)
                queryset = queryset.filter(station_name__in=stations)

            from django.db.models.fields.json import KeyTextTransform
            from django.utils import timezone
            from datetime import timedelta, datetime
            
            now_dt = timezone.now().date()
            month_1 = now_dt - timedelta(days=30)
            months_3 = now_dt - timedelta(days=90)
            months_6 = now_dt - timedelta(days=180)
            year_1 = now_dt - timedelta(days=365)

            under_1_month = 0
            months_1_to_3 = 0
            months_3_to_6 = 0
            months_6_to_12 = 0
            more_than_1_year = 0

            cases = queryset.annotate(d_date=KeyTextTransform('disposal_date', 'extra_fields')).values_list('d_date', flat=True)
            
            import re
            for d in cases:
                if d and isinstance(d, str):
                    d = d.strip()
                    if re.match(r'^\d{4}-\d{2}-\d{2}', d):
                        try:
                            dt = datetime.strptime(d[:10], "%Y-%m-%d").date()
                            if dt >= month_1:
                                under_1_month += 1
                            elif dt >= months_3:
                                months_1_to_3 += 1
                            elif dt >= months_6:
                                months_3_to_6 += 1
                            elif dt >= year_1:
                                months_6_to_12 += 1
                            else:
                                more_than_1_year += 1
                        except ValueError:
                            pass
                            
            results = [
                {'period': 'Under 1 month', 'count': under_1_month, 'start_date': month_1.strftime('%Y-%m-%d'), 'end_date': now_dt.strftime('%Y-%m-%d')},
                {'period': '1 to 3 months', 'count': months_1_to_3, 'start_date': months_3.strftime('%Y-%m-%d'), 'end_date': month_1.strftime('%Y-%m-%d')},
                {'period': '3 to 6 months', 'count': months_3_to_6, 'start_date': months_6.strftime('%Y-%m-%d'), 'end_date': months_3.strftime('%Y-%m-%d')},
                {'period': '6 to 12 months', 'count': months_6_to_12, 'start_date': year_1.strftime('%Y-%m-%d'), 'end_date': months_6.strftime('%Y-%m-%d')},
                {'period': 'More than 1 year', 'count': more_than_1_year, 'start_date': '', 'end_date': year_1.strftime('%Y-%m-%d')},
                {'period': 'Under 3 months (Total)', 'count': under_1_month + months_1_to_3, 'start_date': months_3.strftime('%Y-%m-%d'), 'end_date': now_dt.strftime('%Y-%m-%d')}
            ]
            results = [r for r in results if r['count'] > 0]
            
            return Response(results)
        except Exception as e:
            logger.exception(f"[TimeWiseDisposalView] Database error: {e}")
            return Response({'error': 'Failed to retrieve Time-wise disposal.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DesignationWiseDisposalView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Count
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('disposal')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            district = request.query_params.get('district')
            if district:
                from apps.stations.models import PoliceStation
                stations = PoliceStation.objects.filter(district__name__iexact=district).values_list('station_name', flat=True)
                queryset = queryset.filter(station_name__in=stations)

            counts = queryset.values('assigned_officer_uid', 'assigned_officer', 'station_name').annotate(count=Count('id')).order_by('-count')
            
            from apps.users.models import OfficerProfile
            uid_to_rank = {p.uid: p.designation for p in OfficerProfile.objects.filter(uid__in=[c['assigned_officer_uid'] for c in counts if c['assigned_officer_uid']])}
            
            results = []
            for c in counts:
                uid = c.get('assigned_officer_uid') or ''
                name = c.get('assigned_officer') or 'Unassigned'
                rank = uid_to_rank.get(uid, '') if uid else ''
                results.append({
                    'io_uid': uid,
                    'io_name': name,
                    'io_rank': rank,
                    'station_name': c['station_name'],
                    'disposal_count': c['count']
                })
            return Response(results)
        except Exception as e:
            logger.exception(f"[DesignationWiseDisposalView] Database error: {e}")
            return Response({'error': 'Failed to retrieve IO-wise counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DisposalCrimeTypeWiseView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Count
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('disposal')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            counts = queryset.values('module_key', 'sub_category').annotate(count=Count('id'))
            
            from apps.crimetab.models.groupings import CaseCategory
            cats = CaseCategory.objects.all()
            cat_map = {}
            for c in cats:
                name = c.category_name if c.category_name else c.category_code
                cat_map[c.category_code.lower()] = name
                cat_map[name.lower()] = name

            grouped = {}
            for c in counts:
                mk = (c.get('module_key') or '').strip()
                sc = (c.get('sub_category') or '').strip()
                
                # Prioritize sub_category if present
                raw_key = sc if sc else mk
                if not raw_key:
                    raw_key = 'Other'
                    
                # Try to map, otherwise use raw_key
                display_name = cat_map.get(raw_key.lower(), raw_key.title() if sc else raw_key)
                
                if raw_key not in grouped:
                    grouped[raw_key] = {
                        'crime_type': raw_key,
                        'crime_type_name': display_name,
                        'count': 0
                    }
                grouped[raw_key]['count'] += c['count']

            results = sorted(grouped.values(), key=lambda x: x['count'], reverse=True)
            return Response(results)
        except Exception as e:
            logger.exception(f"[DisposalCrimeTypeWiseView] Database error: {e}")
            return Response({'error': 'Failed to retrieve Crime-wise counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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


class DetectedCasesView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('Detected')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            # Optional time range filter
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            if start_date:
                queryset = queryset.filter(created_at__date__gte=start_date)
            if end_date:
                queryset = queryset.filter(created_at__date__lte=end_date)
                
            from apps.cases.serializers import CaseRecordSerializer
            serializer = CaseRecordSerializer(queryset.order_by('-created_at'), many=True)
            return Response(serializer.data)
        except Exception as e:
            logger.exception(f"[DetectedCasesView] Database error: {e}")
            return Response({'error': 'Failed to retrieve detected cases.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class IOWiseDetectedView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Count
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('Detected')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            if start_date:
                queryset = queryset.filter(created_at__date__gte=start_date)
            if end_date:
                queryset = queryset.filter(created_at__date__lte=end_date)

            counts = queryset.values('assigned_officer', 'station_name').annotate(count=Count('id')).order_by('-count')
            
            results = []
            for c in counts:
                name = c['assigned_officer']
                results.append({
                    'io_uid': name, 
                    'io_name': name if name else 'Unassigned',
                    'io_rank': '',
                    'station_name': c['station_name'],
                    'detected_count': c['count']
                })

            return Response(results)
        except Exception as e:
            logger.exception(f"[IOWiseDetectedView] Database error: {e}")
            return Response({'error': 'Failed to retrieve IO-wise detected counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class TimeWiseDetectedView(APIView):
    permission_classes = [permissions.IsAuthenticated, HasPermission('case:view')]

    def get(self, request):
        try:
            from django.db.models import Q
            from django.utils import timezone
            from datetime import timedelta
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('Detected')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            now = timezone.now()
            month_1 = now - timedelta(days=30)
            months_3 = now - timedelta(days=90)
            months_6 = now - timedelta(days=180)
            year_1 = now - timedelta(days=365)

            under_1_month = queryset.filter(created_at__gte=month_1).count()
            months_1_to_3 = queryset.filter(created_at__gte=months_3, created_at__lt=month_1).count()
            months_3_to_6 = queryset.filter(created_at__gte=months_6, created_at__lt=months_3).count()
            months_6_to_12 = queryset.filter(created_at__gte=year_1, created_at__lt=months_6).count()
            more_than_1_year = queryset.filter(created_at__lt=year_1).count()
            
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
            logger.exception(f"[TimeWiseDetectedView] Database error: {e}")
            return Response({'error': 'Failed to retrieve Time-wise detected counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ArrestedCaseWiseView(PendingCasesView):
    def get(self, request):
        try:
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('arrested')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            io_name = request.query_params.get('io')
            if io_name:
                queryset = queryset.filter(assigned_officer=io_name)

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
            logger.exception(f'[ArrestedCaseWiseView] Database error: {e}')
            return Response({'error': 'Failed to retrieve arrested cases.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class IOWiseArrestedView(IOWisePendingView):
    def get(self, request):
        try:
            from django.db.models import Count
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('arrested')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            if start_date:
                queryset = queryset.filter(created_at__date__gte=start_date)
            if end_date:
                queryset = queryset.filter(created_at__date__lte=end_date)

            counts = queryset.values('assigned_officer', 'station_name').annotate(count=Count('id')).order_by('-count')
            
            results = []
            for c in counts:
                name = c['assigned_officer']
                results.append({
                    'io_uid': name,
                    'io_name': name if name else 'Unassigned',
                    'io_rank': '',
                    'station_name': c['station_name'],
                    'pending_count': c['count']
                })

            return Response(results)
        except Exception as e:
            logger.exception(f'[IOWiseArrestedView] Database error: {e}')
            return Response({'error': 'Failed to retrieve IO-wise arrested counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class TimeWiseArrestedView(TimeWisePendingView):
    def get(self, request):
        try:
            from django.db.models import Q
            from django.utils import timezone
            from datetime import timedelta
            from apps.cases.utils import get_cases_by_status
            queryset = get_cases_by_status('arrested')
            
            user = request.user
            if not (check_dynamic_permission(user, 'district:view_data') or check_dynamic_permission(user, 'state:view_all')):
                stations = [getattr(user, 'station_name', '')] + (getattr(user, 'additional_stations', []) or [])
                queryset = queryset.filter(station_name__in=stations)

            now = timezone.now()
            month_1 = now - timedelta(days=30)
            months_3 = now - timedelta(days=90)
            months_6 = now - timedelta(days=180)
            year_1 = now - timedelta(days=365)

            under_1_month = queryset.filter(created_at__gte=month_1).count()
            months_1_to_3 = queryset.filter(created_at__gte=months_3, created_at__lt=month_1).count()
            months_3_to_6 = queryset.filter(created_at__gte=months_6, created_at__lt=months_3).count()
            months_6_to_12 = queryset.filter(created_at__gte=year_1, created_at__lt=months_6).count()
            more_than_1_year = queryset.filter(created_at__lt=year_1).count()
            
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
            logger.exception(f'[TimeWiseArrestedView] Database error: {e}')
            return Response({'error': 'Failed to retrieve Time-wise arrested counts.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

