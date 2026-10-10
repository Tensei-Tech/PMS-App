from django.db import models


class RTIApplication(models.Model):
    """
    RTI Application model stored inside state tenant schema (e.g. `<schema>.rti_applications`).
    Represents independent RTI Applications.
    """
    rti_id = models.BigAutoField(primary_key=True)
    station_name = models.CharField(max_length=255)
    serial_year = models.SmallIntegerField()
    serial_no = models.IntegerField()
    applicant_name = models.CharField(max_length=255, blank=True, null=True)
    applicant_age = models.SmallIntegerField(blank=True, null=True)
    mobile_no = models.CharField(max_length=10, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    email = models.EmailField(max_length=254, blank=True, null=True)
    received_date = models.DateField(blank=True, null=True)
    due_date = models.DateField(blank=True, null=True)
    replied_date = models.DateField(blank=True, null=True)
    rejected_date = models.DateField(blank=True, null=True)
    rejection_reason = models.TextField(blank=True, null=True)
    transferred_to = models.TextField(blank=True, null=True)
    info_type = models.CharField(max_length=50, blank=True, null=True)
    info_type_other = models.CharField(max_length=50, blank=True, null=True)
    assigned_officer_uid = models.CharField(max_length=128, blank=True, null=True)
    assigned_officer_name = models.CharField(max_length=255, blank=True, null=True)
    assigned_officer_designation = models.CharField(max_length=128, blank=True, null=True)
    mode_of_receipt = models.CharField(max_length=50, blank=True, null=True)
    is_bpl = models.BooleanField(default=False)
    remark = models.TextField(blank=True, null=True)
    appealed = models.BooleanField(default=False)
    appeal_date = models.DateField(blank=True, null=True)
    status = models.GeneratedField(
        expression=models.Case(
            models.When(
                models.Q(replied_date__isnull=False) |
                models.Q(rejected_date__isnull=False) |
                (models.Q(transferred_to__isnull=False) & ~models.Q(transferred_to='')),
                then=models.Value('Disposal')
            ),
            default=models.Value('Pending'),
            output_field=models.CharField(max_length=10),
        ),
        output_field=models.CharField(max_length=10),
        db_persist=True,
    )
    created_by = models.CharField(max_length=128, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'rti_applications'
        verbose_name = 'RTI Application'
        verbose_name_plural = 'RTI Applications'
        unique_together = ('station_name', 'serial_year', 'serial_no')
        ordering = ['-created_at']

    def __str__(self):
        return f"RTI-{self.serial_year}/{self.serial_no} ({self.applicant_name or '-'}) - {self.status}"



