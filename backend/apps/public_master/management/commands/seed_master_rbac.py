from django.core.management.base import BaseCommand
from apps.core.tenancy import provision_state_schema
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission


class Command(BaseCommand):
    help = "Seeds initial global Roles, Permissions, Role-Permission mappings, Maharashtra State schema, and Master Admin user."

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS("Starting Master RBAC & State Schema Seeding..."))

        # 1. Seed Global Roles matching 4-tier Maharashtra Police Hierarchy
        roles_data = [
            ('master_admin', 'Master Admin', 'global', 'Full platform access across all states and settings'),
            ('state_super_admin', 'State Super Admin', 'state', 'State-level admin managing districts and state operations'),
            ('district_admin', 'Top Leadership (CP / DCP / SP)', 'district', 'District/City leadership (DCP to CP) with full city/district oversight'),
            ('supervisor', 'Division Head (ACP / Dy. SP)', 'station', 'Division head (ACP / Dy. SP) overseeing multi-station sub-divisions'),
            ('station_admin', 'Station In-Charge (Sr. PI / SHO)', 'station', 'Station in-charge (Sr. PI) with full edit authority over all station cases'),
            ('officer', 'Regular Officer (PC to PI)', 'station', 'Field/Station officer with station view and edit access limited to own cases'),
        ]

        for r_id, name, level, desc in roles_data:
            role, created = Role.objects.update_or_create(
                id=r_id,
                defaults={'name': name, 'level': level, 'description': desc}
            )
            if created:
                self.stdout.write(f"  [+] Created Role: {role.name}")

        # 2. Seed Granular Permissions for 4-Tier Matrix
        permissions_data = [
            # State Management
            ('state:create', 'states', 'Create new state tenant schemas'),
            ('state:manage', 'states', 'Manage state settings and status'),
            ('state:view', 'states', 'View state registries'),

            # District & Division Management
            ('district:create', 'districts', 'Create districts'),
            ('district:approve', 'districts', 'Approve/Reject proposed districts'),
            ('district:view', 'districts', 'View district lists'),

            # Station Directory & Multi-Station Switching
            ('station:create', 'stations', 'Create police stations'),
            ('station:manage', 'stations', 'Edit/Manage police station details'),
            ('station:view', 'stations', 'View police station directory'),
            ('station:switch_multi', 'stations', 'Switch and view data across multiple police stations'),

            # User & Account Approvals
            ('user:create', 'users', 'Register new users'),
            ('user:view_profile', 'users', 'View officer profiles'),
            ('user:approve_station', 'users', 'Approve pending officer accounts in caller station'),
            ('user:approve_district', 'users', 'Approve pending officer accounts in caller district/zone'),
            ('user:assign_role', 'users', 'Modify dynamic role assignments'),

            # Case Management Scopes
            ('case:create', 'cases', 'Log new crime/case records'),
            ('case:view_station', 'cases', 'View cases registered in assigned station'),
            ('case:view_division', 'cases', 'View cases across multi-station division'),
            ('case:view_district', 'cases', 'View cases across full city/district'),
            ('case:edit_own', 'cases', 'Edit ONLY cases created by or assigned to self as IO'),
            ('case:edit_station', 'cases', 'Edit ALL cases registered in caller station'),
            ('case:delete', 'cases', 'Delete case records'),

            # Directives & Reminders
            ('reminder:send', 'reminders', 'Send case reminders and supervisory directives to IOs'),
            ('reminder:view', 'reminders', 'View case reminders and directives'),

            # Analytics & Performance
            ('analytics:view', 'analytics', 'View city/district-wide analytics and performance dashboards'),
            ('report:generate', 'reports', 'Generate and print official PDF reports'),
        ]

        for p_id, module, desc in permissions_data:
            perm, created = Permission.objects.update_or_create(
                id=p_id,
                defaults={'module': module, 'description': desc}
            )
            if created:
                self.stdout.write(f"  [+] Created Permission: {perm.id}")

        # 3. Seed 4-Tier Role-Permission Matrix
        role_perm_matrix = {
            'master_admin': [p[0] for p in permissions_data],
            'state_super_admin': [p[0] for p in permissions_data],

            # Tier 4: Top Leadership (DCP to CP)
            'district_admin': [
                'district:view', 'station:view', 'station:switch_multi', 'station:manage',
                'user:create', 'user:view_profile', 'user:approve_district', 'user:assign_role',
                'case:create', 'case:view_station', 'case:view_division', 'case:view_district',
                'case:edit_station', 'case:delete', 'reminder:send', 'reminder:view',
                'analytics:view', 'report:generate'
            ],

            # Tier 3: Division Heads (ACP / Dy. SP)
            'supervisor': [
                'station:view', 'station:switch_multi', 'user:view_profile',
                'case:create', 'case:view_station', 'case:view_division', 'case:edit_station',
                'reminder:send', 'reminder:view', 'report:generate'
            ],

            # Tier 2: Station In-charge (Sr. PI / SHO)
            'station_admin': [
                'station:view', 'user:create', 'user:view_profile', 'user:approve_station',
                'case:create', 'case:view_station', 'case:edit_station',
                'reminder:send', 'reminder:view', 'report:generate'
            ],

            # Tier 1: Regular Officers (PC to PI)
            'officer': [
                'station:view', 'user:view_profile',
                'case:create', 'case:view_station', 'case:edit_own',
                'reminder:view', 'report:generate'
            ]
        }

        for r_id, p_list in role_perm_matrix.items():
            role_obj = Role.objects.get(id=r_id)
            for p_id in p_list:
                perm_obj = Permission.objects.get(id=p_id)
                RolePermission.objects.update_or_create(
                    role=role_obj,
                    permission=perm_obj,
                    defaults={'is_granted': True}
                )

        self.stdout.write(self.style.SUCCESS("  [+] 4-Tier Police Access Matrix Configured!"))

        # 4. Seed Default Master Admin User
        master_email = 'admin@pms.gov.in'
        master_user, created = MasterUser.objects.get_or_create(
            email=master_email,
            defaults={'full_name': 'System Master Admin', 'phone': '+919999999999'}
        )
        if created or not master_user.check_password('AdminPMS@2026!'):
            master_user.set_password('AdminPMS@2026!')
            master_user.save()
            self.stdout.write(self.style.SUCCESS(f"  [+] Master Admin User Ready: {master_email} (password: AdminPMS@2026!)"))

        # 5. Provision Default Maharashtra State & Schema
        mh_state, created = StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={
                'state_name': 'Maharashtra',
                'schema_name': 'maharashtra',
                'created_by_master': master_user
            }
        )
        provision_state_schema('maharashtra')
        self.stdout.write(self.style.SUCCESS("  [+] Provisioned State: Maharashtra (MH) [schema: maharashtra]"))

        self.stdout.write(self.style.SUCCESS("\n[SUCCESS] Master RBAC & State Schema Seeding Completed Successfully!"))
