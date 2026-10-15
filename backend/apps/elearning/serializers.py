from rest_framework import serializers
from .models import Course, OfficerCourseRecord


class CourseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Course
        fields = '__all__'


class OfficerCourseRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = OfficerCourseRecord
        fields = '__all__'
        read_only_fields = ('id', 'created_at', 'updated_at')


class CourseCompletionSubmissionSerializer(serializers.Serializer):
    """
    Serializer for officers logging their completed course.
    Automatically grabs the inbuilt user name from OfficerProfile / authenticated user.
    """
    course_name = serializers.CharField(max_length=255)
    platform = serializers.CharField(max_length=255)
    date_of_completion = serializers.DateField()
    certificate_no = serializers.CharField(max_length=128, required=False, allow_blank=True, default='')
    remarks = serializers.CharField(required=False, allow_blank=True, default='')
