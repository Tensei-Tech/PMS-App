from django.db import models
from django.contrib.auth.hashers import make_password, check_password


class OfficerProfile(models.Model):
    """
    Officer Profile model stored inside state tenant schema (e.g. `maharashtra.users_officerprofile`).
    Represents Police Officers, Supervisors, Station Admins, and District Admins within a state.
    """
    ACCOUNT_STATUS_CHOICES = (
        ('active', 'Active'),
        ('archived', 'Archived'),
        ('pending_approval', 'Pending Approval'),
        ('rejected', 'Rejected'),
    )

    uid = models.CharField(max_length=128, primary_key=True, help_text="Unique Officer Identifier / Firebase UID")
    name = models.CharField(max_length=255, blank=True)
    password = models.CharField(max_length=128, blank=True, null=True, help_text="Hashed password for primary backend login")
    badge_number = models.CharField(max_length=64, blank=True)
    designation = models.CharField(max_length=128, blank=True)
    email = models.EmailField(blank=True, unique=True)
    phone = models.CharField(max_length=32, blank=True)
    station_name = models.CharField(max_length=255, blank=True)
    station_id = models.CharField(max_length=64, blank=True, null=True)
    station_address = models.TextField(blank=True)
    station_landline = models.CharField(max_length=32, blank=True)
    govt_id = models.CharField(max_length=64, blank=True)
    photo_url = models.URLField(max_length=1024, blank=True)
    id_card_url = models.URLField(max_length=1024, blank=True, null=True)
    role_id = models.CharField(max_length=64, default='officer', help_text="Dynamic Role ID referencing public.roles")
    additional_stations = models.JSONField(default=list, blank=True)
    account_status = models.CharField(max_length=32, choices=ACCOUNT_STATUS_CHOICES, default='active')
    district = models.CharField(max_length=128, blank=True, null=True)
    district_id = models.CharField(max_length=64, blank=True, null=True)
    zone = models.CharField(max_length=128, blank=True, null=True)
    station_case_view_granted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'users_officerprofile'
        verbose_name = 'Officer Profile'
        verbose_name_plural = 'Officer Profiles'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.badge_number}) - {self.station_name}"

    def set_password(self, raw_password):
        self.password = make_password(raw_password)

    def check_password(self, raw_password):
        if not self.password:
            return False
        return check_password(raw_password, self.password)

    @property
    def is_authenticated(self):
        """Duck-typing compatibility for DRF authentication backend."""
        return True

    @property
    def is_staff(self):
        return self.role_id in ['admin', 'state_super_admin', 'master_admin']

    @property
    def role(self):
        """Backward compatibility for legacy role attribute access."""
        return self.role_id
