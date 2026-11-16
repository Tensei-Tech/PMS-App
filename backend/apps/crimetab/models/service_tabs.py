"""
Service tabs (not crimes) kept in their own tables instead of the case JSON.

Each record is still a case record (module_key) so lists, counts and transfers
keep working; its answers live in one row here, linked one-to-one to the case.
"""
from django.db import models
from django.utils import timezone


class SamWarrantRecord(models.Model):
    """sam_warrant_records: one Summons / Bailable / Non-Bailable Warrant (Sam/Warrant tab)."""

    TYPE_CHOICES = (('summons', 'Summons'), ('bw', 'Bailable Warrant'), ('nbw', 'Non-Bailable Warrant'))
    STATUS_CHOICES = (('pending', 'Pending'), ('executed', 'Executed'), ('unserved', 'Unserved'))

    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='sam_warrant',
    )
    warrant_type = models.CharField(max_length=10, choices=TYPE_CHOICES, null=True, blank=True)
    warrant_number = models.CharField(max_length=100, null=True, blank=True)
    accused_name = models.CharField(max_length=255, null=True, blank=True)
    court_name = models.CharField(max_length=255, null=True, blank=True)
    issue_date = models.DateField(null=True, blank=True)
    execution_status = models.CharField(max_length=10, choices=STATUS_CHOICES, null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'sam_warrant_records'
        verbose_name = 'Summons / Warrant Record'


class PassportPvrRecord(models.Model):
    """passport_pvr_records: one Passport or PVR verification entry (one batch with its counts)."""

    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='passport_pvr',
    )
    kind = models.CharField(max_length=10, choices=(('passport', 'Passport'), ('pvr', 'PVR')))
    file_number = models.CharField(max_length=100, null=True, blank=True)
    total_count = models.IntegerField(null=True, blank=True)
    verified_count = models.IntegerField(null=True, blank=True)
    pending_count = models.IntegerField(null=True, blank=True)
    verification_status = models.CharField(max_length=50, null=True, blank=True)
    verification_date = models.DateField(null=True, blank=True)
    # older single-applicant records
    applicant_name = models.CharField(max_length=255, null=True, blank=True)
    applicant_phone = models.CharField(max_length=20, null=True, blank=True)
    applicant_address = models.TextField(null=True, blank=True)
    verification_outcome = models.CharField(max_length=100, null=True, blank=True)
    remarks = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'passport_pvr_records'
        verbose_name = 'Passport / PVR Record'
