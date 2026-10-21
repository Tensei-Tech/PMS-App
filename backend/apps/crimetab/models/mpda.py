from django.db import models


class MpdaProposal(models.Model):
    """
    MPDA proposal main record stored inside state tenant schema (e.g. `<schema>.mpda_proposals`).
    """
    id = models.BigAutoField(primary_key=True)
    station_name = models.CharField(max_length=255)
    proposal_no_and_year = models.CharField(max_length=100, blank=True, null=True)
    proposal_no = models.CharField(max_length=50, blank=True, null=True, db_column='proposal_no')
    proposal_year = models.CharField(max_length=10, blank=True, null=True, db_column='proposal_year')
    accused_name = models.CharField(max_length=255, blank=True, null=True)
    accused_aadhaar = models.CharField(max_length=50, blank=True, null=True)
    accused_mobile = models.CharField(max_length=10, blank=True, null=True)
    accused_address = models.TextField(blank=True, null=True)
    accused_age = models.IntegerField(blank=True, null=True)
    accused_gender = models.CharField(max_length=50, blank=True, null=True)
    io_uid = models.CharField(max_length=100, blank=True, null=True)
    io_name = models.CharField(max_length=255, blank=True, null=True)
    io_post = models.CharField(max_length=100, blank=True, null=True)
    proposal_outcome = models.CharField(max_length=20, blank=True, null=True)  # 'Granted' or 'Rejected'
    granted_date = models.DateField(blank=True, null=True)
    rejected_date = models.DateField(blank=True, null=True)
    proposal_revoked = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    proposal_revoked_date = models.DateField(blank=True, null=True)
    detaining_authority = models.CharField(max_length=50, blank=True, null=True)
    detaining_authority_other = models.CharField(max_length=255, blank=True, null=True)
    detained = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    detention_date = models.DateField(blank=True, null=True)
    detention_completion_date = models.DateField(blank=True, null=True)
    jail_name = models.CharField(max_length=255, blank=True, null=True)
    transfer_jail_name = models.CharField(max_length=255, blank=True, null=True)
    government_confirmation = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    govt_confirmation_date = models.DateField(blank=True, null=True)
    detention_order_revoked = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    order_revoked_date = models.DateField(blank=True, null=True)
    mpda_category = models.CharField(max_length=100, blank=True, null=True)
    mpda_category_other = models.CharField(max_length=255, blank=True, null=True)
    total_crime = models.IntegerField(blank=True, null=True)
    serious_crimes = models.IntegerField(blank=True, null=True)
    total_misc_crime = models.IntegerField(blank=True, null=True)
    created_by = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'mpda_proposals'
        verbose_name = 'MPDA Proposal'
        verbose_name_plural = 'MPDA Proposals'
        ordering = ['-created_at']

    def __str__(self):
        prop_label = f"{self.proposal_no}/{self.proposal_year}" if (self.proposal_no and self.proposal_year) else (self.proposal_no or self.proposal_no_and_year or '-')
        return f"MPDA-{prop_label} ({self.accused_name or '-'})"


class MpdaAccusedPerson(models.Model):
    """
    Repeating accused person stored in `<schema>.mpda_accused_persons`.
    """
    id = models.BigAutoField(primary_key=True)
    proposal = models.ForeignKey(
        MpdaProposal,
        on_delete=models.CASCADE,
        related_name='accused_persons',
        db_column='proposal_id'
    )
    display_order = models.SmallIntegerField(default=1)
    name = models.CharField(max_length=255, blank=True, null=True)
    age = models.IntegerField(blank=True, null=True)
    gender = models.CharField(max_length=50, blank=True, null=True)
    occupation = models.CharField(max_length=255, blank=True, null=True)
    mobile = models.CharField(max_length=10, blank=True, null=True)
    aadhaar = models.CharField(max_length=50, blank=True, null=True)
    pan = models.CharField(max_length=50, blank=True, null=True)
    cast = models.CharField(max_length=100, blank=True, null=True)
    religion = models.CharField(max_length=100, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'mpda_accused_persons'
        verbose_name = 'MPDA Accused Person'
        verbose_name_plural = 'MPDA Accused Persons'
        ordering = ['display_order', 'id']

    def __str__(self):
        return f"{self.name or 'Unknown'} (Age: {self.age or '-'})"


class MpdaGangMember(models.Model):
    """
    Repeating gang / group member name (at most 5) stored in `<schema>.mpda_gang_members`.
    """
    id = models.BigAutoField(primary_key=True)
    proposal = models.ForeignKey(
        MpdaProposal,
        on_delete=models.CASCADE,
        related_name='gang_members',
        db_column='proposal_id'
    )
    name = models.CharField(max_length=255, blank=True, null=True)
    display_order = models.SmallIntegerField(default=1)
    # Same personal details as an accused person
    age = models.IntegerField(blank=True, null=True)
    gender = models.CharField(max_length=50, blank=True, null=True)
    occupation = models.CharField(max_length=255, blank=True, null=True)
    mobile = models.CharField(max_length=10, blank=True, null=True)
    aadhaar = models.CharField(max_length=50, blank=True, null=True)
    pan = models.CharField(max_length=50, blank=True, null=True)
    cast = models.CharField(max_length=100, blank=True, null=True)
    religion = models.CharField(max_length=100, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'mpda_gang_members'
        verbose_name = 'MPDA Gang Member'
        verbose_name_plural = 'MPDA Gang Members'
        ordering = ['display_order']


class MpdaCrimeChartEntry(models.Model):
    """
    Repeating crime chart row stored in `<schema>.mpda_crime_chart_entries`.
    """
    id = models.BigAutoField(primary_key=True)
    proposal = models.ForeignKey(
        MpdaProposal,
        on_delete=models.CASCADE,
        related_name='crime_chart_entries',
        db_column='proposal_id'
    )
    crime_type = models.CharField(max_length=100, blank=True, null=True)
    cr_no = models.CharField(max_length=100, blank=True, null=True)
    crime_date = models.DateField(blank=True, null=True)
    police_station = models.CharField(max_length=255, blank=True, null=True)
    # Act / Section / Subsection picked from the Acts master (ids, no FK, plus
    # text copies); act_section holds the combined text
    act_id = models.BigIntegerField(blank=True, null=True)
    section_id = models.BigIntegerField(blank=True, null=True)
    subsection_id = models.BigIntegerField(blank=True, null=True)
    act_name = models.TextField(blank=True, null=True)
    section_number = models.TextField(blank=True, null=True)
    section_title = models.TextField(blank=True, null=True)
    subsection_code = models.TextField(blank=True, null=True)
    act_section = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'mpda_crime_chart_entries'
        verbose_name = 'MPDA Crime Chart Entry'
        verbose_name_plural = 'MPDA Crime Chart Entries'
        ordering = ['-crime_date']
