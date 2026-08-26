import uuid
from django.db import models
from django.contrib.auth.hashers import make_password, check_password


class MasterUser(models.Model):
    """
    Master Admin User stored in `public.master_users`.
    Operates at the Company / Organization level above all State tenants.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=128)
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=32, blank=True)
    is_active = models.BooleanField(default=True)
    firebase_uid = models.CharField(max_length=128, blank=True, null=True, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'master_users'
        verbose_name = 'Master Admin User'
        verbose_name_plural = 'Master Admin Users'

    def __str__(self):
        return f"MasterAdmin: {self.full_name} ({self.email})"

    def set_password(self, raw_password):
        self.password = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.password)

    @property
    def is_authenticated(self):
        return True


class StateRegistry(models.Model):
    """
    Global Registry of States & corresponding PostgreSQL schemas in `public.states`.
    """
    state_code = models.CharField(max_length=10, primary_key=True, help_text="e.g. MH, GJ, DL")
    state_name = models.CharField(max_length=100, unique=True, help_text="e.g. Maharashtra")
    schema_name = models.CharField(max_length=64, unique=True, help_text="PostgreSQL Schema name e.g. maharashtra")
    is_active = models.BooleanField(default=True)
    created_by_master = models.ForeignKey(MasterUser, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'states'
        verbose_name = 'State Registry'
        verbose_name_plural = 'State Registries'
        ordering = ['state_name']

    def __str__(self):
        return f"{self.state_name} ({self.state_code}) [schema: {self.schema_name}]"


class Role(models.Model):
    """
    Global Roles in `public.roles`.
    """
    LEVEL_CHOICES = (
        ('global', 'Global Platform (Master Admin)'),
        ('state', 'State Level (Super Admin)'),
        ('district', 'District Level (District Admin)'),
        ('station', 'Station Level (Station Officers)'),
    )

    id = models.CharField(max_length=64, primary_key=True, help_text="e.g. master_admin, state_super_admin, district_admin, station_admin, officer, supervisor")
    name = models.CharField(max_length=100)
    level = models.CharField(max_length=32, choices=LEVEL_CHOICES, default='station')
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'roles'
        verbose_name = 'Role'
        verbose_name_plural = 'Roles'
        ordering = ['id']

    def __str__(self):
        return f"{self.name} ({self.id})"


class Permission(models.Model):
    """
    Granular Permission master list in `public.permissions`.
    """
    id = models.CharField(max_length=64, primary_key=True, help_text="e.g. district:create, district:approve, station:manage, case:create, case:approve")
    module = models.CharField(max_length=64, help_text="e.g. districts, stations, cases, users")
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'permissions'
        verbose_name = 'Permission'
        verbose_name_plural = 'Permissions'
        ordering = ['module', 'id']

    def __str__(self):
        return f"[{self.module}] {self.id}"


class RolePermission(models.Model):
    """
    Mapping between Roles & Permissions in `public.role_permissions`.
    Dynamic RBAC configuration. Modifying rows here immediately grants/revokes features across backend & frontend.
    """
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='permissions')
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE, related_name='roles')
    is_granted = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'role_permissions'
        unique_together = ('role', 'permission')
        verbose_name = 'Role Permission Mapping'
        verbose_name_plural = 'Role Permission Mappings'

    def __str__(self):
        status = "Granted" if self.is_granted else "Revoked"
        return f"{self.role.id} -> {self.permission.id} ({status})"


class UserRoleMapping(models.Model):
    """
    Maps any user (by UID/email) to their assigned Role, State, District, and Station in `public.user_role_mappings`.
    """
    uid = models.CharField(max_length=128, primary_key=True, help_text="Unique User Identifier / Firebase UID")
    email = models.EmailField()
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    state = models.ForeignKey(StateRegistry, on_delete=models.SET_NULL, null=True, blank=True)
    district_id = models.CharField(max_length=64, blank=True, null=True)
    station_id = models.CharField(max_length=64, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_role_mappings'
        verbose_name = 'User Role Mapping'
        verbose_name_plural = 'User Role Mappings'

    def __str__(self):
        return f"{self.email} -> Role: {self.role.id} | State: {self.state.state_code if self.state else 'Global'}"
