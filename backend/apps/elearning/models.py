import uuid
from django.db import models


class Course(models.Model):
    """
    Catalog of E-Learning courses available for police personnel.
    """
    id = models.CharField(max_length=128, primary_key=True, default=uuid.uuid4)
    name = models.CharField(max_length=255, unique=True, help_text="Course title/name")
    platform = models.CharField(max_length=255, default="iGOT Karmayogi", help_text="Platform of the course (e.g. iGOT Karmayogi, CDTI, BPR&D, CyberDome, Coursera, Internal)")
    description = models.TextField(blank=True, default="")
    category = models.CharField(max_length=128, blank=True, default="General", help_text="Category (BNS/BNSS, Cyber, Forensics, Investigation, etc.)")
    duration_hours = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True, help_text="Estimated duration in hours")
    is_mandatory = models.BooleanField(default=True, help_text="Is this course mandatory for officers?")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'elearning_course'
        verbose_name = 'Course'
        verbose_name_plural = 'Courses'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.platform})"


class OfficerCourseRecord(models.Model):
    """
    Records completed (or enrolled) E-Learning courses by police personnel.
    Supports user's inbuilt name, course name, platform, and date of completion.
    """
    STATUS_CHOICES = (
        ('Completed', 'Completed'),
        ('In Progress', 'In Progress'),
        ('Not Started', 'Not Started'),
    )

    id = models.CharField(max_length=128, primary_key=True, default=uuid.uuid4)
    # Officer details
    officer_uid = models.CharField(max_length=128, db_index=True, help_text="UID linking to OfficerProfile")
    officer_name = models.CharField(max_length=255, help_text="Inbuilt name of the officer")
    badge_number = models.CharField(max_length=64, blank=True, default="")
    designation = models.CharField(max_length=128, blank=True, default="")
    station_name = models.CharField(max_length=255, db_index=True, help_text="Police Station name")
    district = models.CharField(max_length=128, blank=True, default="")

    # Course details
    course = models.ForeignKey(Course, on_delete=models.SET_NULL, null=True, blank=True, related_name='records')
    course_name = models.CharField(max_length=255, help_text="Course Name")
    platform = models.CharField(max_length=255, help_text="Platform of the course (e.g., iGOT Karmayogi)")
    
    # Progress & Completion
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='Completed', db_index=True)
    date_of_completion = models.DateField(null=True, blank=True, help_text="Date when course was completed")
    certificate_no = models.CharField(max_length=128, blank=True, default="", help_text="Optional certificate / registration ID")
    certificate_url = models.URLField(max_length=1024, blank=True, null=True, help_text="Optional certificate document URL")
    
    remarks = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'elearning_officercourserecord'
        verbose_name = 'Officer Course Record'
        verbose_name_plural = 'Officer Course Records'
        ordering = ['-date_of_completion', '-created_at']

    def __str__(self):
        return f"{self.officer_name} - {self.course_name} ({self.status})"
