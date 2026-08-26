import uuid
from django.db import models


class CaseRecord(models.Model):
    """
    Case Record model matching Flutter ModuleRecord for PostgreSQL storage.
    Supports extra_fields (JSONB) for flexible per-module dynamic attributes.
    """
    PRIORITY_CHOICES = (
        ('Low', 'Low'),
        ('Medium', 'Medium'),
        ('High', 'High'),
        ('Critical', 'Critical'),
    )

    STATUS_CHOICES = (
        ('Pending', 'Pending'),
        ('Disposal', 'Disposal'),
        ('Closed', 'Closed'),
        ('Open', 'Open'),
    )

    id = models.CharField(max_length=128, primary_key=True, default=uuid.uuid4)
    module_key = models.CharField(max_length=64, db_index=True)
    title = models.CharField(max_length=255)
    case_number = models.CharField(max_length=128, db_index=True)
    description = models.TextField(blank=True)
    complainant = models.CharField(max_length=255, blank=True)
    accused = models.CharField(max_length=255, blank=True)
    location = models.CharField(max_length=255, blank=True)
    incident_date = models.DateTimeField(null=True, blank=True)
    priority = models.CharField(max_length=32, choices=PRIORITY_CHOICES, default='Low')
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='Pending', db_index=True)
    assigned_officer = models.CharField(max_length=255, blank=True)
    assigned_officer_uid = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    sub_category = models.CharField(max_length=128, blank=True, null=True)
    created_by = models.CharField(max_length=128, blank=True)
    station_name = models.CharField(max_length=255, db_index=True)
    extra_fields = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'cases_caserecord'
        verbose_name = 'Case Record'
        verbose_name_plural = 'Case Records'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.module_key}] {self.case_number}: {self.title} ({self.station_name})"
