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


class LicenceRecord(models.Model):
    """licence_records: one Licence / NOC verification application (Licence tab)."""

    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='licence',
    )
    licence_number = models.CharField(max_length=100, null=True, blank=True)
    licence_type = models.CharField(max_length=255, null=True, blank=True)
    base_licence_type = models.CharField(max_length=255, null=True, blank=True)
    other_noc_type = models.CharField(max_length=255, null=True, blank=True)
    applicant_name = models.CharField(max_length=255, null=True, blank=True)
    business_name = models.CharField(max_length=255, null=True, blank=True)
    received_date = models.DateField(null=True, blank=True)
    licence_status = models.CharField(max_length=20, null=True, blank=True)
    status_updated_at = models.DateTimeField(null=True, blank=True)
    remarks = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'licence_records'
        verbose_name = 'Licence Record'


class TadiparRecord(models.Model):
    """tadipar_records: one externment (Tadipar) order. Column names follow the form keys."""

    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='tadipar',
    )
    sr_no = models.IntegerField(null=True, blank=True)
    externed_name = models.CharField(max_length=255, null=True, blank=True)
    alias = models.CharField(max_length=255, null=True, blank=True)
    nickname = models.CharField(max_length=255, null=True, blank=True)
    age = models.IntegerField(null=True, blank=True)
    gender = models.CharField(max_length=20, null=True, blank=True)
    mo_no = models.CharField(max_length=15, null=True, blank=True)
    address = models.TextField(null=True, blank=True)
    order_date = models.DateField(null=True, blank=True)
    order_number = models.CharField(max_length=100, null=True, blank=True)
    # The app shows these as text boxes: kept as typed
    act_id = models.CharField(max_length=255, null=True, blank=True)
    section_id = models.CharField(max_length=255, null=True, blank=True)
    subsection_id = models.CharField(max_length=255, null=True, blank=True)
    act_section = models.TextField(null=True, blank=True)
    period_from = models.DateField(null=True, blank=True)
    period_to = models.DateField(null=True, blank=True)
    revoked_date = models.DateField(null=True, blank=True)
    current_address = models.TextField(null=True, blank=True)
    prohibited_areas = models.CharField(max_length=255, null=True, blank=True)
    crime_chart_entries = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'tadipar_records'
        verbose_name = 'Tadipar Record'


class TadiparCrimeChartEntry(models.Model):
    """tadipar_crime_chart_entries: one row of a Tadipar order's Crime Chart. Act / Section /
    station names are copied beside their ids so a row stays readable if the master changes."""

    id = models.BigAutoField(primary_key=True)
    record = models.ForeignKey(TadiparRecord, on_delete=models.CASCADE, related_name='crime_chart',
                               db_column='case_id')
    row_no = models.IntegerField(default=0)
    cr_number = models.CharField(max_length=100, null=True, blank=True)
    crime_head = models.TextField(null=True, blank=True)
    act_id = models.BigIntegerField(null=True, blank=True)
    act_name = models.TextField(null=True, blank=True)
    section_id = models.BigIntegerField(null=True, blank=True)
    section_number = models.CharField(max_length=50, null=True, blank=True)
    register_date = models.DateField(null=True, blank=True)
    police_station_id = models.BigIntegerField(null=True, blank=True)
    police_station_name = models.CharField(max_length=255, null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'tadipar_crime_chart_entries'
        verbose_name = 'Tadipar Crime Chart Entry'
        unique_together = ('record', 'row_no')
