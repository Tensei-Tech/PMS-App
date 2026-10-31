from django.db import models
from django.utils import timezone
from decimal import Decimal


class MuddemalRegister(models.Model):
    """
    Main Muddemal register associated with a CR.
    Table: muddemal_records
    """
    RECORD_STATUS_CHOICES = (
        ('Active', 'Active'),
        ('Closed', 'Closed'),
        ('Archived', 'Archived'),
    )

    id = models.BigAutoField(primary_key=True)
    muddemal_register_no = models.CharField(max_length=64, unique=True, db_index=True)
    police_station_id = models.CharField(max_length=64, db_index=True)
    station_name = models.CharField(max_length=255, db_index=True)
    cr_case = models.ForeignKey(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        related_name='muddemal_registers',
        null=True,
        blank=True
    )
    cr_number_snapshot = models.CharField(max_length=128, db_index=True)
    registration_date = models.DateField(default=timezone.now)
    investigating_officer_id = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    investigating_officer_name = models.CharField(max_length=255, blank=True, null=True)
    record_status = models.CharField(max_length=32, choices=RECORD_STATUS_CHOICES, default='Active', db_index=True)
    remarks = models.TextField(blank=True, default='')
    created_by = models.CharField(max_length=128, blank=True, default='')
    updated_by = models.CharField(max_length=128, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'muddemal_records'
        verbose_name = 'Muddemal Register'
        verbose_name_plural = 'Muddemal Registers'
        ordering = ['-registration_date', '-id']

    def __str__(self):
        return f"Register {self.muddemal_register_no} (CR: {self.cr_number_snapshot} - {self.station_name})"


class MuddemalPropertyCategory(models.Model):
    """
    Backend-driven property categories.
    Table: muddemal_property_categories
    """
    id = models.BigAutoField(primary_key=True)
    category_code = models.CharField(max_length=64, unique=True, db_index=True)
    category_name = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True, db_index=True)
    display_order = models.IntegerField(default=0)
    applicable_property_rules = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'muddemal_property_categories'
        verbose_name = 'Type of Property'
        verbose_name_plural = 'Types of Property'
        ordering = ['display_order', 'category_name']

    def __str__(self):
        return f"{self.category_name} ({self.category_code})"


class MuddemalFieldDefinition(models.Model):
    """
    Configurable dynamic form fields for each property category.
    Table: muddemal_field_definitions
    """
    FIELD_TYPE_CHOICES = (
        ('text', 'Text Field'),
        ('textarea', 'Textarea'),
        ('number', 'Integer Number'),
        ('decimal', 'Decimal Number'),
        ('date', 'Date Picker'),
        ('datetime', 'Date & Time Picker'),
        ('dropdown', 'Dropdown Select'),
        ('multiselect', 'Multi-select Chips'),
        ('checkbox', 'Checkbox Toggle'),
        ('chips', 'Chips Selector'),
    )

    id = models.BigAutoField(primary_key=True)
    category = models.ForeignKey(
        MuddemalPropertyCategory,
        on_delete=models.CASCADE,
        related_name='field_definitions'
    )
    field_key = models.CharField(max_length=100)
    display_label = models.CharField(max_length=255)
    field_type = models.CharField(max_length=50, choices=FIELD_TYPE_CHOICES, default='text')
    is_required = models.BooleanField(default=False)
    validation_rules = models.JSONField(default=dict, blank=True)
    dropdown_options = models.JSONField(default=list, blank=True)
    default_value = models.CharField(max_length=255, blank=True, null=True)
    visibility_conditions = models.JSONField(default=dict, blank=True)
    display_order = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'muddemal_field_definitions'
        verbose_name = 'Muddemal Field Definition'
        verbose_name_plural = 'Muddemal Field Definitions'
        unique_together = ('category', 'field_key')
        ordering = ['display_order', 'id']

    def __str__(self):
        return f"{self.display_label} [{self.category.category_code}] ({self.field_key})"


class MuddemalProperty(models.Model):
    """
    Individual property or logically grouped item under a Muddemal Register.
    Table: muddemal_properties
    """
    VALUATION_STATUS_CHOICES = (
        ('Pending', 'Pending'),
        ('Estimated', 'Estimated'),
        ('Assessed', 'Assessed'),
        ('Verified', 'Verified'),
    )

    PROPERTY_STATUS_CHOICES = (
        ('Stolen – Not Recovered', 'Stolen – Not Recovered'),
        ('Recovered', 'Recovered'),
        ('Partially Recovered', 'Partially Recovered'),
        ('Seized', 'Seized'),
        ('Sent to FSL', 'Sent to FSL'),
        ('FSL Report Pending', 'FSL Report Pending'),
        ('Produced Before Court', 'Produced Before Court'),
        ('Released on Supurdnama', 'Released on Supurdnama'),
        ('Returned to Owner', 'Returned to Owner'),
        ('Pending Disposal', 'Pending Disposal'),
        ('Disposed', 'Disposed'),
        ('Destroyed', 'Destroyed'),
    )

    id = models.BigAutoField(primary_key=True)
    property_uid = models.CharField(max_length=128, unique=True, db_index=True)
    muddemal_record = models.ForeignKey(
        MuddemalRegister,
        on_delete=models.CASCADE,
        related_name='properties'
    )
    source_module = models.CharField(max_length=64, default='manual', db_index=True)
    source_record_id = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    property_category = models.ForeignKey(
        MuddemalPropertyCategory,
        on_delete=models.PROTECT,
        related_name='properties'
    )
    property_serial_no = models.IntegerField(default=1)
    description = models.TextField(blank=True, default='')
    quantity = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('1.00'))
    unit = models.CharField(max_length=50, default='Numbers')
    unit_value = models.DecimalField(max_digits=14, decimal_places=2, default=Decimal('0.00'))
    total_item_value = models.DecimalField(max_digits=16, decimal_places=2, default=Decimal('0.00'))
    valuation_status = models.CharField(
        max_length=32,
        choices=VALUATION_STATUS_CHOICES,
        default='Pending',
        db_index=True
    )
    owner_name = models.CharField(max_length=255, blank=True, default='')
    seized_from = models.CharField(max_length=255, blank=True, default='')
    seizure_date = models.DateField(null=True, blank=True)
    recovery_date = models.DateField(null=True, blank=True)
    property_status = models.CharField(
        max_length=64,
        choices=PROPERTY_STATUS_CHOICES,
        default='Seized',
        db_index=True
    )
    fsl_required = models.BooleanField(default=False, db_index=True)
    remarks = models.TextField(blank=True, default='')
    extra_fields = models.JSONField(default=dict, blank=True)
    created_by = models.CharField(max_length=128, blank=True, default='')
    updated_by = models.CharField(max_length=128, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'muddemal_properties'
        verbose_name = 'Muddemal Property'
        verbose_name_plural = 'Muddemal Properties'
        ordering = ['muddemal_record', 'property_serial_no', '-created_at']
        indexes = [
            models.Index(fields=['source_module', 'source_record_id'], name='idx_muddemal_source'),
            models.Index(fields=['property_status', 'fsl_required'], name='idx_muddemal_status_fsl'),
        ]

    def save(self, *args, **kwargs):
        # Enforce automatic backend valuation rule:
        # If total_item_value is 0 or unassigned, compute Quantity x Unit Value
        if self.unit_value and self.quantity and (not self.total_item_value or self.total_item_value == 0):
            self.total_item_value = round(Decimal(str(self.quantity)) * Decimal(str(self.unit_value)), 2)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.property_uid} - {self.description[:40]} ({self.property_status})"


class MuddemalPropertyMovement(models.Model):
    """
    Append-only chain of custody movements.
    Table: muddemal_property_movements
    """
    id = models.BigAutoField(primary_key=True)
    property = models.ForeignKey(
        MuddemalProperty,
        on_delete=models.CASCADE,
        related_name='movements'
    )
    from_location = models.CharField(max_length=255)
    to_location = models.CharField(max_length=255)
    movement_type = models.CharField(max_length=64)
    movement_date = models.DateTimeField(default=timezone.now)
    responsible_officer = models.CharField(max_length=255)
    reference_no = models.CharField(max_length=128, blank=True, default='')
    remarks = models.TextField(blank=True, default='')
    created_by = models.CharField(max_length=128, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'muddemal_property_movements'
        verbose_name = 'Muddemal Property Movement'
        verbose_name_plural = 'Muddemal Property Movements'
        ordering = ['-movement_date', '-id']

    def __str__(self):
        return f"{self.property.property_uid}: {self.from_location} -> {self.to_location} ({self.movement_type})"


class MuddemalFSLRecord(models.Model):
    """
    FSL Laboratory dispatch and report history.
    Table: muddemal_fsl_records
    """
    REPORT_STATUS_CHOICES = (
        ('Pending', 'Pending'),
        ('Received', 'Received'),
        ('Inconclusive', 'Inconclusive'),
    )

    id = models.BigAutoField(primary_key=True)
    property = models.ForeignKey(
        MuddemalProperty,
        on_delete=models.CASCADE,
        related_name='fsl_records'
    )
    fsl_reference_no = models.CharField(max_length=128, db_index=True)
    dispatch_date = models.DateField(default=timezone.now)
    dispatch_details = models.TextField(blank=True, default='')
    report_received_status = models.CharField(
        max_length=32,
        choices=REPORT_STATUS_CHOICES,
        default='Pending',
        db_index=True
    )
    report_received_date = models.DateField(null=True, blank=True)
    report_reference = models.CharField(max_length=128, blank=True, default='')
    remarks = models.TextField(blank=True, default='')
    created_by = models.CharField(max_length=128, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'muddemal_fsl_records'
        verbose_name = 'Muddemal FSL Record'
        verbose_name_plural = 'Muddemal FSL Records'
        ordering = ['-dispatch_date', '-id']

    def __str__(self):
        return f"FSL {self.fsl_reference_no} for {self.property.property_uid} [{self.report_received_status}]"


class MuddemalDisposal(models.Model):
    """
    Property return, Supurdnama, destruction, forfeiture and final disposal.
    Table: muddemal_disposals
    """
    DISPOSAL_TYPE_CHOICES = (
        ('Supurdnama', 'Released on Supurdnama'),
        ('Returned to Owner', 'Returned to Owner'),
        ('Auction', 'Disposed by Public Auction'),
        ('Destruction', 'Destroyed as per Court Order'),
        ('Forfeiture', 'Forfeited to State Government'),
        ('Other', 'Other Disposal'),
    )

    id = models.BigAutoField(primary_key=True)
    property = models.ForeignKey(
        MuddemalProperty,
        on_delete=models.CASCADE,
        related_name='disposals'
    )
    disposal_type = models.CharField(max_length=64, choices=DISPOSAL_TYPE_CHOICES)
    court_order_reference = models.CharField(max_length=128, blank=True, default='')
    order_date = models.DateField(null=True, blank=True)
    owner_recipient_details = models.JSONField(default=dict, blank=True)
    supurdnama_details = models.JSONField(default=dict, blank=True)
    disposal_date = models.DateField(default=timezone.now)
    authorization_details = models.CharField(max_length=255, blank=True, default='')
    remarks = models.TextField(blank=True, default='')
    created_by = models.CharField(max_length=128, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'muddemal_disposals'
        verbose_name = 'Muddemal Disposal'
        verbose_name_plural = 'Muddemal Disposals'
        ordering = ['-disposal_date', '-id']

    def __str__(self):
        return f"{self.disposal_type} for {self.property.property_uid} on {self.disposal_date}"


class MuddemalAuditLog(models.Model):
    """
    Audit log for sensitive property movements, valuations, and status changes.
    Table: muddemal_audit_logs
    """
    id = models.BigAutoField(primary_key=True)
    property = models.ForeignKey(
        MuddemalProperty,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs'
    )
    muddemal_record = models.ForeignKey(
        MuddemalRegister,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs'
    )
    action = models.CharField(max_length=64, db_index=True)
    performed_by = models.CharField(max_length=128, default='anonymous')
    performed_by_name = models.CharField(max_length=255, blank=True, default='')
    details = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'muddemal_audit_logs'
        verbose_name = 'Muddemal Audit Log'
        verbose_name_plural = 'Muddemal Audit Logs'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.action}] by {self.performed_by_name or self.performed_by} at {self.created_at}"


class MuddemalConfig(models.Model):
    """
    Backend-driven system configurations (alert thresholds, measurement units, dropdown lists).
    Table: muddemal_configs
    """
    id = models.BigAutoField(primary_key=True)
    config_key = models.CharField(max_length=64, unique=True, db_index=True)
    config_value = models.JSONField(default=dict)
    description = models.TextField(blank=True, default='')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'muddemal_configs'
        verbose_name = 'Muddemal Configuration'
        verbose_name_plural = 'Muddemal Configurations'

    def __str__(self):
        return self.config_key
