from django.db import models


class NcRecord(models.Model):
    """
    One N.C. (Non-Cognizable) record, stored in the state's own schema
    (<schema>.nc_records). Not a case: N.C. never writes to cases_caserecord.
    """
    id = models.BigAutoField(primary_key=True)
    station_name = models.CharField(max_length=255)
    nc_no = models.CharField(max_length=100, blank=True, null=True)
    registered_date = models.DateField(blank=True, null=True)
    spot_village = models.CharField(max_length=255, blank=True, null=True)
    spot_area = models.CharField(max_length=255, blank=True, null=True)
    spot_address = models.TextField(blank=True, null=True)
    occurrence_at = models.DateTimeField(blank=True, null=True)
    io_name = models.CharField(max_length=255, blank=True, null=True)
    io_designation = models.CharField(max_length=255, blank=True, null=True)
    io_mobile = models.CharField(max_length=10, blank=True, null=True)
    reg_name = models.CharField(max_length=255, blank=True, null=True)
    reg_designation = models.CharField(max_length=255, blank=True, null=True)
    reg_mobile = models.CharField(max_length=10, blank=True, null=True)
    first_information = models.TextField(blank=True, null=True)
    post_crime_registered = models.CharField(max_length=100, blank=True, null=True)
    post_crime_no = models.CharField(max_length=100, blank=True, null=True)
    post_act = models.TextField(blank=True, null=True)
    post_section = models.TextField(blank=True, null=True)
    # Source cases_caserecord.id of a backfilled legacy N.C.; makes the backfill re-runnable
    legacy_case_id = models.CharField(max_length=128, unique=True, blank=True, null=True)
    created_by = models.CharField(max_length=128, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'nc_records'
        verbose_name = 'N.C. Record'
        verbose_name_plural = 'N.C. Records'

    def __str__(self):
        return f"NC {self.nc_no or self.id} ({self.station_name})"


class NcPerson(models.Model):
    """Complainant or Non applicant of an N.C. (any number of each)."""
    id = models.BigAutoField(primary_key=True)
    nc = models.ForeignKey(NcRecord, on_delete=models.CASCADE, related_name='persons', db_column='nc_id')
    person_type = models.CharField(max_length=20)  # 'complainant' | 'non_applicant'
    display_order = models.SmallIntegerField(default=0)
    name = models.CharField(max_length=255, blank=True, null=True)
    age = models.SmallIntegerField(blank=True, null=True)
    gender = models.CharField(max_length=50, blank=True, null=True)
    caste = models.CharField(max_length=255, blank=True, null=True)
    profession = models.CharField(max_length=255, blank=True, null=True)
    mobile = models.CharField(max_length=10, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    aadhaar = models.CharField(max_length=20, blank=True, null=True)

    class Meta:
        db_table = 'nc_persons'
        verbose_name = 'N.C. Person'
        verbose_name_plural = 'N.C. Persons'


class NcCharge(models.Model):
    """Act / Section / Subsection of an N.C., stored as text copies (ids without FK)."""
    id = models.BigAutoField(primary_key=True)
    nc = models.ForeignKey(NcRecord, on_delete=models.CASCADE, related_name='charges', db_column='nc_id')
    display_order = models.SmallIntegerField(default=0)
    act_id = models.BigIntegerField(blank=True, null=True)
    section_id = models.BigIntegerField(blank=True, null=True)
    subsection_id = models.BigIntegerField(blank=True, null=True)
    act_name = models.TextField(blank=True, null=True)
    section_number = models.TextField(blank=True, null=True)
    section_title = models.TextField(blank=True, null=True)
    subsection_code = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'nc_charges'
        verbose_name = 'N.C. Charge'
        verbose_name_plural = 'N.C. Charges'


class NcPreventiveAction(models.Model):
    """Preventive row of an N.C.; person may only be a Non applicant of the same N.C."""
    id = models.BigAutoField(primary_key=True)
    nc = models.ForeignKey(NcRecord, on_delete=models.CASCADE, related_name='preventive_actions', db_column='nc_id')
    person = models.ForeignKey(
        NcPerson, on_delete=models.CASCADE, related_name='preventive_actions',
        db_column='person_id', blank=True, null=True,
    )
    display_order = models.SmallIntegerField(default=0)
    provision = models.CharField(max_length=100, blank=True, null=True)
    action_date = models.DateField(blank=True, null=True)
    outward_number = models.CharField(max_length=100, blank=True, null=True)
    outward_date = models.DateField(blank=True, null=True)
    bond_date = models.DateField(blank=True, null=True)
    bond_cancellation_date = models.DateField(blank=True, null=True)
    preventive_number = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        db_table = 'nc_preventive_actions'
        verbose_name = 'N.C. Preventive Action'
        verbose_name_plural = 'N.C. Preventive Actions'
