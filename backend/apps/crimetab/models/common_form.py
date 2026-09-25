from django.db import models
from django.utils import timezone


class CrimeRegistrationInfo(models.Model):
    """
    1. crime_registration_info — root, 1:1 with case
    """
    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='registration_info'
    )
    cr_number = models.CharField(max_length=30, null=True, blank=True)
    registered_datetime = models.DateTimeField(null=True, blank=True)
    is_unknown_accused = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'crime_registration_info'
        verbose_name = 'Crime Registration Info'
        verbose_name_plural = 'Crime Registration Infos'

    def __str__(self):
        return f"CR {self.cr_number or 'Unassigned'} (Case {self.case_id})"


class Act(models.Model):
    """
    2a. acts — reference/master list of Acts
    """
    act_id = models.BigAutoField(primary_key=True)
    act_name = models.CharField(max_length=100, default='')
    display_order = models.IntegerField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'acts'
        verbose_name = 'Act'
        verbose_name_plural = 'Acts'
        ordering = ['display_order', 'act_id']

    def __str__(self):
        return self.act_name


class ActSection(models.Model):
    """
    2b. act_sections — reference/master list of Sections per Act
    """
    section_id = models.BigAutoField(primary_key=True)
    act = models.ForeignKey(
        Act,
        on_delete=models.CASCADE,
        related_name='sections',
        db_column='act_id'
    )
    section_number = models.CharField(max_length=10, default='')
    section_title = models.CharField(max_length=255, default='')
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'act_sections'
        verbose_name = 'Act Section'
        verbose_name_plural = 'Act Sections'
        unique_together = ('act', 'section_number')
        ordering = ['act_id', 'section_number']

    def __str__(self):
        return f"{self.act.act_name} Sec. {self.section_number} - {self.section_title}"


class ActSubsection(models.Model):
    """
    2c. act_subsections — reference/master list of Subsections per Section
    """
    subsection_id = models.BigAutoField(primary_key=True)
    section = models.ForeignKey(
        ActSection,
        on_delete=models.CASCADE,
        related_name='subsections',
        db_column='section_id'
    )
    subsection_code = models.CharField(max_length=20, default='')
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'act_subsections'
        verbose_name = 'Act Subsection'
        verbose_name_plural = 'Act Subsections'
        unique_together = ('section', 'subsection_code')
        ordering = ['section_id', 'subsection_code']

    def __str__(self):
        return f"Sec {self.section.section_number}({self.subsection_code})"


class CrimeCaseActsSections(models.Model):
    """
    3. crime_case_acts_sections — Act/Section/Subsection charged on a case.
    REPEATING: a case can have multiple charges (e.g. Murder AND Hurt),
    each one independently triggering dynamic extra fields.
    """
    charge_id = models.BigAutoField(primary_key=True)
    case = models.ForeignKey(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        related_name='charges',
        db_column='case_id'
    )
    act = models.ForeignKey(
        Act,
        on_delete=models.CASCADE,
        related_name='case_charges',
        db_column='act_id'
    )
    section = models.ForeignKey(
        ActSection,
        on_delete=models.CASCADE,
        related_name='case_charges',
        db_column='section_id'
    )
    subsection = models.ForeignKey(
        ActSubsection,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='case_charges',
        db_column='subsection_id'
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'crime_case_acts_sections'
        verbose_name = 'Crime Case Act Section'
        verbose_name_plural = 'Crime Case Acts Sections'
        indexes = [
            models.Index(fields=['case'], name='idx_charges_case'),
            models.Index(fields=['section'], name='idx_charges_section'),
        ]

    def __str__(self):
        sub = f"({self.subsection.subsection_code})" if self.subsection else ""
        return f"Case {self.case_id} -> {self.act.act_name} {self.section.section_number}{sub}"


class CrimeSpot(models.Model):
    """
    4. crime_spot — 1:1 with case
    """
    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='spot'
    )
    village_town = models.CharField(max_length=100, null=True, blank=True)
    area_name = models.CharField(max_length=100, null=True, blank=True)
    full_address = models.TextField(null=True, blank=True)
    occurrence_datetime = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'crime_spot'
        verbose_name = 'Crime Spot'
        verbose_name_plural = 'Crime Spots'

    def __str__(self):
        return f"Spot for Case {self.case_id}: {self.area_name or self.village_town or 'No Address'}"


class CasesPerson(models.Model):
    """
    5. cases_person — unified table for Complainant, Accused, Suspected Accused, and Unidentified Accused.
    Complainant: 1 row per case.
    Accused / Suspected Accused / Unidentified Accused: repeating (multiple allowed).
    """
    ROLE_CHOICES = (
        ('complainant', 'Complainant'),
        ('accused', 'Accused'),
        ('suspected_accused', 'Suspected Accused'),
        ('unidentified_accused', 'Unidentified Accused'),
    )

    person_id = models.BigAutoField(primary_key=True)
    case = models.ForeignKey(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        related_name='persons',
        db_column='case_id'
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='accused')

    # KYC fields (complainant / accused / suspected_accused)
    name = models.CharField(max_length=150, null=True, blank=True)
    age = models.IntegerField(null=True, blank=True)
    gender = models.CharField(max_length=10, null=True, blank=True)
    occupation = models.CharField(max_length=100, null=True, blank=True)
    mobile = models.CharField(max_length=10, null=True, blank=True)
    aadhaar = models.CharField(max_length=12, null=True, blank=True)
    pan = models.CharField(max_length=10, null=True, blank=True)
    religion = models.CharField(max_length=50, null=True, blank=True)
    caste = models.CharField(max_length=50, null=True, blank=True)
    address = models.TextField(null=True, blank=True)

    # Unidentified Accused-specific fields
    approximate_age = models.CharField(max_length=20, null=True, blank=True)
    skin_colour = models.CharField(max_length=50, null=True, blank=True)
    possible_occupation = models.CharField(max_length=100, null=True, blank=True)
    identification_mark = models.TextField(null=True, blank=True)
    height = models.CharField(max_length=20, null=True, blank=True)
    description = models.TextField(null=True, blank=True)

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'cases_person'
        verbose_name = 'Cases Person'
        verbose_name_plural = 'Cases Persons'
        indexes = [
            models.Index(fields=['case'], name='idx_person_case'),
            models.Index(fields=['case', 'role'], name='idx_person_case_role'),
        ]

    def __str__(self):
        return f"[{self.role}] {self.name or 'Unidentified'} (Case {self.case_id})"


class CrimeCaseResponsibility(models.Model):
    """
    6. crime_case_responsibility — IO + Registered By, 1:1 with case
    """
    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='responsibility'
    )
    io_name = models.CharField(max_length=150, null=True, blank=True)
    io_designation = models.CharField(max_length=20, null=True, blank=True)
    registered_by_name = models.CharField(max_length=150, null=True, blank=True)
    registered_by_designation = models.CharField(max_length=20, null=True, blank=True)

    class Meta:
        db_table = 'crime_case_responsibility'
        verbose_name = 'Crime Case Responsibility'
        verbose_name_plural = 'Crime Case Responsibilities'

    def __str__(self):
        return f"IO: {self.io_name} ({self.io_designation}) - Case {self.case_id}"


class ArrestReleaseStatus(models.Model):
    """
    7. arrest_release_status — per accused/suspected person
    """
    arrest_id = models.BigAutoField(primary_key=True)
    person = models.OneToOneField(
        CasesPerson,
        on_delete=models.CASCADE,
        unique=True,
        related_name='arrest_status',
        db_column='person_id'
    )
    arrest_datetime = models.DateTimeField(null=True, blank=True)
    sec_47_48_bnss = models.BooleanField(null=True, blank=True)
    relative_friend_name = models.CharField(max_length=150, null=True, blank=True)
    relative_friend_relation = models.CharField(max_length=50, null=True, blank=True)
    release_on_notice = models.BooleanField(null=True, blank=True)
    release_on_notice_datetime = models.DateTimeField(null=True, blank=True)
    anticipatory_bail = models.BooleanField(null=True, blank=True)
    anticipatory_bail_datetime = models.DateTimeField(null=True, blank=True)
    death_of_accused = models.BooleanField(null=True, blank=True)
    death_of_accused_datetime = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'arrest_release_status'
        verbose_name = 'Arrest Release Status'
        verbose_name_plural = 'Arrest Release Statuses'

    def __str__(self):
        return f"Arrest/Release for Person {self.person_id}"


class RemandCustody(models.Model):
    """
    8. remand_custody — PCR / MCR / PR Bond / Bail / Surety / Jail, per accused/suspected person
    Enforces 2 database-level CHECK constraints:
      1. pr_bond requires mcr = TRUE
      2. surety_name / jail requires bail = TRUE
    """
    remand_id = models.BigAutoField(primary_key=True)
    person = models.OneToOneField(
        CasesPerson,
        on_delete=models.CASCADE,
        unique=True,
        related_name='remand_custody',
        db_column='person_id'
    )
    pcr_days = models.IntegerField(null=True, blank=True)
    mcr = models.BooleanField(null=True, blank=True)
    pr_bond = models.BooleanField(null=True, blank=True)
    bail = models.BooleanField(null=True, blank=True)
    surety_name = models.CharField(max_length=150, null=True, blank=True)
    jail = models.BooleanField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'remand_custody'
        verbose_name = 'Remand Custody'
        verbose_name_plural = 'Remand Custodies'
        constraints = [
            models.CheckConstraint(
                condition=models.Q(pr_bond__isnull=True) | models.Q(pr_bond=False) | models.Q(mcr=True),
                name='chk_pr_bond_requires_mcr'
            ),
            models.CheckConstraint(
                condition=(
                    (models.Q(surety_name__isnull=True) | models.Q(surety_name='')) &
                    (models.Q(jail__isnull=True) | models.Q(jail=False))
                ) | models.Q(bail=True),
                name='chk_surety_jail_requires_bail'
            ),
        ]

    def __str__(self):
        return f"Remand/Custody for Person {self.person_id}"


class CctvTechnical(models.Model):
    """
    9. cctv_technical — CCTV + CDR, 1:1 with case
    """
    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='cctv_technical'
    )
    cctv_checked = models.BooleanField(null=True, blank=True)
    cdr_sent_date = models.DateField(null=True, blank=True)
    cdr_received_date = models.DateField(null=True, blank=True)

    class Meta:
        db_table = 'cctv_technical'
        verbose_name = 'CCTV Technical'
        verbose_name_plural = 'CCTV Technicals'

    def __str__(self):
        return f"CCTV/CDR for Case {self.case_id}"


class ProceduralChecklist(models.Model):
    """
    10. procedural_checklist — All Panchanama, repeating (7 items)
    """
    ITEM_CHOICES = (
        ('Spot Panchanama', 'Spot Panchanama'),
        ('Seizure Panchanama', 'Seizure Panchanama'),
        ('Search Panchanama', 'Search Panchanama'),
        ('Personal Search Panchanama', 'Personal Search Panchanama'),
        ('Memorandum Panchanama', 'Memorandum Panchanama'),
        ('Identification Panchanama', 'Identification Panchanama'),
        ('Identification Parade Panchanama', 'Identification Parade Panchanama'),
    )

    checklist_id = models.BigAutoField(primary_key=True)
    case = models.ForeignKey(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        related_name='procedural_checklists',
        db_column='case_id'
    )
    item_name = models.CharField(max_length=40, choices=ITEM_CHOICES)
    is_checked = models.BooleanField(default=False)
    event_datetime = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'procedural_checklist'
        verbose_name = 'Procedural Checklist'
        verbose_name_plural = 'Procedural Checklists'
        unique_together = ('case', 'item_name')

    def __str__(self):
        return f"{self.item_name}: {'Checked' if self.is_checked else 'Unchecked'} (Case {self.case_id})"


class CaseForensics(models.Model):
    """
    11. case_forensics — E-Shakshya / Fingerprint / NAFIS, 1:1 with case
    """
    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='forensics'
    )
    e_shakshya = models.BooleanField(null=True, blank=True)
    fingerprint_taken = models.BooleanField(null=True, blank=True)
    nafis_fingerprint = models.BooleanField(null=True, blank=True)

    class Meta:
        db_table = 'case_forensics'
        verbose_name = 'Case Forensics'
        verbose_name_plural = 'Case Forensics'

    def __str__(self):
        return f"Forensics for Case {self.case_id}"


class SeizureRecords(models.Model):
    """
    12. seizure_records — repeating, "[Add +]"
    """
    seizure_id = models.BigAutoField(primary_key=True)
    case = models.ForeignKey(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        related_name='seizures',
        db_column='case_id'
    )
    description = models.TextField(default='')
    name = models.CharField(max_length=150, null=True, blank=True)
    seized_from_person = models.ForeignKey(
        CasesPerson,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='seized_from_person_id',
        related_name='seizures'
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'seizure_records'
        verbose_name = 'Seizure Record'
        verbose_name_plural = 'Seizure Records'

    def __str__(self):
        return f"Seizure from {self.name or self.seized_from_person_id or 'Unknown'} (Case {self.case_id})"


class PreventiveActionItems(models.Model):
    """
    13. preventive_action_items — repeating, 11 fixed provisions
    """
    ACTION_TYPE_CHOICES = (
        ('107 CrPC/126 BNSS', '107 CrPC/126 BNSS'),
        ('109 CrPC/128 BNSS', '109 CrPC/128 BNSS'),
        ('110 CrPC/129 BNSS', '110 CrPC/129 BNSS'),
        ('151(3) CrPC/170 BNSS', '151(3) CrPC/170 BNSS'),
        ('144 CrPC/163 BNSS', '144 CrPC/163 BNSS'),
        ('149 CrPC/168 BNSS', '149 CrPC/168 BNSS'),
        ('55 MPA', '55 MPA'),
        ('56 MPA', '56 MPA'),
        ('57 MPA', '57 MPA'),
        ('122 MPA', '122 MPA'),
        ('93 Prohibition Act', '93 Prohibition Act'),
    )

    item_id = models.BigAutoField(primary_key=True)
    case = models.ForeignKey(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        related_name='preventive_action_items',
        db_column='case_id'
    )
    action_type = models.CharField(max_length=30, choices=ACTION_TYPE_CHOICES, default='107 CrPC/126 BNSS')
    action_date = models.DateField(default=timezone.now)
    outward_number = models.CharField(max_length=50, null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'preventive_action_items'
        verbose_name = 'Preventive Action Item'
        verbose_name_plural = 'Preventive Action Items'
        unique_together = ('case', 'action_type')

    def __str__(self):
        return f"{self.action_type} on {self.action_date} (Case {self.case_id})"


class PreventiveBond(models.Model):
    """
    14. preventive_bond — Bond Date / Bond Cancellation Date, 1:1 with case
    """
    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='preventive_bond'
    )
    bond_date = models.DateField(null=True, blank=True)
    bond_cancellation_date = models.DateField(null=True, blank=True)

    class Meta:
        db_table = 'preventive_bond'
        verbose_name = 'Preventive Bond'
        verbose_name_plural = 'Preventive Bonds'

    def __str__(self):
        return f"Bond for Case {self.case_id}"


class DischargeStatus(models.Model):
    """
    15. discharge_status — Discharged Accused Name(s), per person
    """
    person = models.OneToOneField(
        CasesPerson,
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='person_id',
        related_name='discharge_status'
    )
    is_discharged = models.BooleanField(default=True)

    class Meta:
        db_table = 'discharge_status'
        verbose_name = 'Discharge Status'
        verbose_name_plural = 'Discharge Statuses'

    def __str__(self):
        return f"Person {self.person_id}: Discharged={self.is_discharged}"


class ScrutinyPipeline(models.Model):
    """
    16. scrutiny_pipeline — 4 tiers, 1:1 with case
    """
    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='scrutiny_pipeline'
    )
    sdpo_acp_send_date = models.DateField(null=True, blank=True)
    sdpo_acp_grant_date = models.DateField(null=True, blank=True)
    addl_sp_dcp_send_date = models.DateField(null=True, blank=True)
    addl_sp_dcp_grant_date = models.DateField(null=True, blank=True)
    addl_cp_send_date = models.DateField(null=True, blank=True)
    addl_cp_grant_date = models.DateField(null=True, blank=True)
    app_send_date = models.DateField(null=True, blank=True)
    app_grant_date = models.DateField(null=True, blank=True)

    class Meta:
        db_table = 'scrutiny_pipeline'
        verbose_name = 'Scrutiny Pipeline'
        verbose_name_plural = 'Scrutiny Pipelines'

    def __str__(self):
        return f"Scrutiny for Case {self.case_id}"


class FinalVerdict(models.Model):
    """
    17. final_verdict — 1:1 with case
    """
    case = models.OneToOneField(
        'cases.CaseRecord',
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='case_id',
        related_name='final_verdict'
    )
    charge_sheet_no = models.CharField(max_length=50, null=True, blank=True)
    a_final_number = models.CharField(max_length=50, null=True, blank=True)
    b_final_number = models.CharField(max_length=50, null=True, blank=True)
    c_final_number = models.CharField(max_length=50, null=True, blank=True)
    nc_final_number = models.CharField(max_length=50, null=True, blank=True)
    abeted_summary_no = models.CharField(max_length=50, null=True, blank=True)
    stay_by_high_court_date = models.DateField(null=True, blank=True)
    quashed_by_high_court_date = models.DateField(null=True, blank=True)

    class Meta:
        db_table = 'final_verdict'
        verbose_name = 'Final Verdict'
        verbose_name_plural = 'Final Verdicts'

    def __str__(self):
        return f"Verdict for Case {self.case_id}: CS={self.charge_sheet_no or 'Pending'}"
