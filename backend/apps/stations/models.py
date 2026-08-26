from django.db import models


class SuperAdmin(models.Model):
    """
    State-level Super Admin record inside state tenant schema.
    Approve Districts and manage state-level police operations.
    """
    uid = models.CharField(max_length=128, primary_key=True)
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=32, blank=True)
    status = models.CharField(max_length=32, default='active')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'super_admins'
        verbose_name = 'State Super Admin'
        verbose_name_plural = 'State Super Admins'

    def __str__(self):
        return f"SuperAdmin: {self.name} ({self.email})"


class District(models.Model):
    """
    Districts inside state tenant schema. Created by Super Admin.
    """
    STATUS_CHOICES = (
        ('pending_approval', 'Pending Approval'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    district_id = models.CharField(max_length=64, primary_key=True)
    name = models.CharField(max_length=128, unique=True)
    code = models.CharField(max_length=32, blank=True)
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='approved')
    approved_by_super_admin_uid = models.CharField(max_length=128, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'districts'
        verbose_name = 'District'
        verbose_name_plural = 'Districts'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.district_id})"


class DistrictAdmin(models.Model):
    """
    District Admin record managing police stations within a specific district.
    """
    uid = models.CharField(max_length=128, primary_key=True)
    district = models.ForeignKey(District, on_delete=models.CASCADE, related_name='district_admins')
    name = models.CharField(max_length=255)
    email = models.EmailField()
    phone = models.CharField(max_length=32, blank=True)
    badge_number = models.CharField(max_length=64, blank=True)
    status = models.CharField(max_length=32, default='active')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'district_admins'
        verbose_name = 'District Admin'
        verbose_name_plural = 'District Admins'

    def __str__(self):
        return f"DistrictAdmin: {self.name} - District: {self.district.name}"


class PoliceStation(models.Model):
    """
    Police Station model inside state tenant schema.
    """
    station_id = models.CharField(max_length=64, primary_key=True)
    station_name = models.CharField(max_length=255, unique=True)
    district = models.ForeignKey(District, on_delete=models.CASCADE, related_name='stations', null=True, blank=True)
    district_name = models.CharField(max_length=128, blank=True)
    zone = models.CharField(max_length=128, blank=True)
    address = models.TextField(blank=True)
    landline = models.CharField(max_length=32, blank=True)
    pi_in_charge = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'stations_policestation'
        verbose_name = 'Police Station'
        verbose_name_plural = 'Police Stations'
        ordering = ['station_name']

    def __str__(self):
        return f"{self.station_name} ({self.district_name})"
