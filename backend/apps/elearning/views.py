import logging
from django.db.models import Count, Q
from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination

from apps.core.permissions import HasPermission
from apps.users.models import OfficerProfile
from .models import Course, OfficerCourseRecord
from .serializers import (
    CourseSerializer,
    OfficerCourseRecordSerializer,
    CourseCompletionSubmissionSerializer,
)

logger = logging.getLogger(__name__)


def _get_officer_info(user):
    """
    Resolves the inbuilt user name, badge number, designation, and station name.
    """
    uid = getattr(user, 'uid', None) or str(getattr(user, 'id', ''))
    name = (
        getattr(user, 'name', None) or
        getattr(user, 'full_name', None) or
        getattr(user, 'username', '')
    )
    badge = getattr(user, 'badge_number', '') or ''
    designation = getattr(user, 'designation', '') or ''
    station = getattr(user, 'station_name', '') or ''
    district = getattr(user, 'district', '') or ''

    # Check OfficerProfile for full accurate profile if available
    if uid:
        profile = OfficerProfile.objects.filter(Q(uid=uid) | Q(badge_number=badge)).first()
        if profile:
            name = profile.name or name
            badge = profile.badge_number or badge
            designation = profile.designation or designation
            station = profile.station_name or station
            district = profile.district or district

    return {
        'uid': uid,
        'name': name.strip() if name else 'Police Personnel',
        'badge_number': badge,
        'designation': designation,
        'station_name': station,
        'district': district,
    }


class CourseListCreateView(APIView):
    """
    GET: List all available courses
    POST: Create a new course (Admin/Incharge)
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        courses = Course.objects.all().order_by('name')
        platform = request.query_params.get('platform')
        category = request.query_params.get('category')
        if platform:
            courses = courses.filter(platform__iexact=platform)
        if category:
            courses = courses.filter(category__iexact=category)
        serializer = CourseSerializer(courses, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = CourseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SubmitCourseCompletionView(APIView):
    """
    Allows an officer to record a completed course.
    Automatically grabs the inbuilt user name from OfficerProfile / authenticated user session.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CourseCompletionSubmissionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        user_info = _get_officer_info(request.user)

        # Link to matching Course catalog if exists, or auto-create/lookup
        course_name = data['course_name'].strip()
        platform = data['platform'].strip()
        course_obj = Course.objects.filter(name__iexact=course_name).first()
        if not course_obj:
            course_obj = Course.objects.create(
                name=course_name,
                platform=platform,
            )

        # Create/Update completion record
        record, created = OfficerCourseRecord.objects.update_or_create(
            officer_uid=user_info['uid'],
            course_name=course_name,
            defaults={
                'officer_name': user_info['name'],
                'badge_number': user_info['badge_number'],
                'designation': user_info['designation'],
                'station_name': user_info['station_name'],
                'district': user_info['district'],
                'course': course_obj,
                'platform': platform,
                'status': 'Completed',
                'date_of_completion': data['date_of_completion'],
                'certificate_no': data.get('certificate_no', ''),
                'remarks': data.get('remarks', ''),
            }
        )

        res_serializer = OfficerCourseRecordSerializer(record)
        return Response(res_serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class OfficerCourseRecordsListView(APIView):
    """
    GET: List course completion records with serial numbers:
    Columns:
    - Serial number (sr_no)
    - Name (inbuilt user name)
    - Course name
    - Platform of the course
    - Date of completion
    - Status
    - Station name
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        queryset = OfficerCourseRecord.objects.all().order_by('-date_of_completion', '-created_at')

        # Filter by station (if Station Incharge or query param)
        station = request.query_params.get('station')
        is_admin = getattr(request.user, 'is_superuser', False) or getattr(request.user, 'role_id', '') in ['admin', 'state_super_admin', 'master_admin']
        if station:
            queryset = queryset.filter(station_name__iexact=station)
        elif not is_admin:
            user_station = getattr(request.user, 'station_name', None)
            if user_station:
                queryset = queryset.filter(station_name=user_station)

        officer_uid = request.query_params.get('officer_uid')
        if officer_uid:
            queryset = queryset.filter(officer_uid=officer_uid)

        course_name = request.query_params.get('course_name')
        if course_name:
            queryset = queryset.filter(course_name__icontains=course_name)

        platform = request.query_params.get('platform')
        if platform:
            queryset = queryset.filter(platform__icontains=platform)

        # Pagination
        paginator = PageNumberPagination()
        page = paginator.paginate_queryset(queryset, request)
        if page is not None:
            serializer = OfficerCourseRecordSerializer(page, many=True)
            return paginator.get_paginated_response(serializer.data)

        serializer = OfficerCourseRecordSerializer(queryset, many=True)
        return Response(serializer.data)


class InchargeDashboardAnalyticsView(APIView):
    """
    Analytics for Incharge of the police station:
    - How many police personnel and officers have completed courses
    - How many courses have been completed by officers individually
    - Who has not done the courses (officers in the station with 0 completed courses)
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        station_name = request.query_params.get('station') or getattr(user, 'station_name', '')

        # All officers in this station from OfficerProfile
        officers_qs = OfficerProfile.objects.all()
        if station_name:
            officers_qs = officers_qs.filter(station_name__iexact=station_name)

        total_station_personnel = officers_qs.count()

        # Completed course records in this station
        records_qs = OfficerCourseRecord.objects.filter(status='Completed')
        if station_name:
            records_qs = records_qs.filter(station_name__iexact=station_name)

        total_completions_count = records_qs.count()

        # 1. How many distinct police personnel have completed at least one course
        completed_officer_uids = list(records_qs.values_list('officer_uid', flat=True).distinct())
        completed_personnel_count = len(completed_officer_uids)

        # 2. How many courses have been completed by officers individually
        officer_counts = records_qs.values(
            'officer_uid', 'officer_name', 'badge_number', 'designation', 'station_name'
        ).annotate(completed_count=Count('id')).order_by('-completed_count')

        individual_completed = []
        for oc in officer_counts:
            individual_completed.append({
                'officer_uid': oc['officer_uid'],
                'officer_name': oc['officer_name'],
                'badge_number': oc['badge_number'],
                'designation': oc['designation'],
                'station_name': oc['station_name'],
                'completed_courses_count': oc['completed_count'],
            })

        # 3. Who has not done the courses (officers with 0 completed courses)
        non_completers_qs = officers_qs.exclude(uid__in=completed_officer_uids)
        not_done_officers = []
        for o in non_completers_qs:
            not_done_officers.append({
                'officer_uid': o.uid,
                'officer_name': o.name or 'Officer',
                'badge_number': o.badge_number,
                'designation': o.designation,
                'station_name': o.station_name,
                'status': 'Not Completed Any Course',
            })

        # Overview cards
        return Response({
            'station_name': station_name or 'All Stations',
            'summary': {
                'total_station_personnel': total_station_personnel,
                'personnel_completed_at_least_one': completed_personnel_count,
                'personnel_not_completed_any': len(not_done_officers),
                'total_course_completions': total_completions_count,
                'completion_percentage': round(
                    (completed_personnel_count / total_station_personnel * 100), 1
                ) if total_station_personnel > 0 else 0,
            },
            'individual_officer_completions': individual_completed,
            'officers_not_completed': not_done_officers,
        })
