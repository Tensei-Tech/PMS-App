from django.core.management.base import BaseCommand
from apps.core.tenancy import provision_state_schema
from apps.public_master.models import MasterUser, StateRegistry, Role, Permission, RolePermission


class Command(BaseCommand):
    help = "Seeds initial global Roles, Permissions, Role-Permission mappings, Maharashtra State schema, and Master Admin user."

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS("Starting Master Dynamic RBAC Seeding..."))

        # 1. Seed 6 Global Roles matching Police Hierarchy Specification Matrix
        roles_data = [
            (
                'master_admin',
                'Master Admin (Company)',
                'global',
                'Company-level account with 100% authority across all state schemas and system settings.'
            ),
            (
                'state_super_admin',
                'Super Admin (State)',
                'state',
                'State-level leadership (PI, SDPO, Add.SP, SI, DIG, IG, ADG, DG) with full state oversight, alerts, and reminders.'
            ),
            (
                'district_admin',
                'District Admin',
                'district',
                'District/City leadership (CP, DCP, Add.CP, Ut.CP) managing district data, divisions, and station heads.'
            ),
            (
                'division_admin',
                'Division Admin (City)',
                'station',
                'Division head (DySP, ACP, SDPO, ASP) with multi-station selection, station switching, and district visibility.'
            ),
            (
                'station_admin',
                'Station Head',
                'station',
                'Station in-charge (PSI, API, PI, ASP) managing station data, station case editing, and IO reminders.'
            ),
            (
                'officer',
                'Officer',
                'station',
                'Field/Station officer (all ranks excluding DG) with access to edit own cases and view station cases.'
            ),
        ]

        for r_id, name, level, desc in roles_data:
            role, created = Role.objects.update_or_create(
                id=r_id,
                defaults={'name': name, 'level': level, 'description': desc}
            )
            if created:
                self.stdout.write(f"  [+] Created Role: {role.name}")

        # Also support legacy 'supervisor' role alias pointing to division_admin capabilities
        Role.objects.update_or_create(
            id='supervisor',
            defaults={
                'name': 'Division Head (Legacy Supervisor)',
                'level': 'station',
                'description': 'Legacy alias for Division Admin (ACP / Dy. SP).'
            }
        )

        # 2. Seed Granular Permissions for Dynamic RBAC Matrix
        permissions_data = [
            # State Level
            ('state:view_all', 'states', 'View all state-wide data'),
            ('state:manage', 'states', 'Manage state settings and schemas'),

            # Admin Management
            ('district:create_admin', 'districts', 'Create District Admin accounts'),
            ('division:create_admin', 'districts', 'Create Division / Station Head accounts'),
            ('station:create_head', 'stations', 'Create Station Head accounts'),

            # Communication & Directives
            ('alert:send', 'alerts', 'Send state or district emergency alerts'),
            ('reminder:send', 'reminders', 'Send supervisory reminders to officers/stations'),
            ('reminder:to_io', 'reminders', 'Send directives and reminders to Investigating Officers (IO)'),

            # Data Scope Oversight
            ('district:view_data', 'districts', 'View district-wide data and cases'),
            ('station:view_data', 'stations', 'View station data'),
            ('station:select_multiple', 'stations', 'Select and view data across multiple police stations'),
            ('station:switch', 'stations', 'Switch active station within district'),
            ('station:multi_handle', 'stations', 'Handle multiple police stations concurrently'),

            # Case Editing & Viewing
            ('case:create', 'cases', 'Log new crime/case records'),
            ('case:view_station', 'cases', 'View cases registered in assigned station'),
            ('case:edit_own', 'cases', 'Edit ONLY cases created by or assigned to self as IO'),
            ('case:edit_station', 'cases', 'Edit ALL cases registered in caller station'),
            ('case:edit_district', 'cases', 'Edit cases registered across district'),
            ('case:delete', 'cases', 'Delete case records'),

            # User & Role Governance
            ('user:create', 'users', 'Register new users'),
            ('user:view_profile', 'users', 'View officer profiles'),
            ('user:assign_role', 'users', 'Modify dynamic role assignments'),
            ('report:generate', 'reports', 'Generate and print official PDF reports'),
        ]

        for p_id, module, desc in permissions_data:
            perm, created = Permission.objects.update_or_create(
                id=p_id,
                defaults={'module': module, 'description': desc}
            )
            if created:
                self.stdout.write(f"  [+] Created Permission: {perm.id}")

        # 3. Seed Role-Permission Mapping Matrix matching Specification Table
        all_perm_ids = [p[0] for p in permissions_data]

        role_perm_matrix = {
            # Master Admin: 100% authority across all modules
            'master_admin': all_perm_ids,

            # Super Admin (State): State oversight, create admins, send alerts, send reminders
            'state_super_admin': [
                'state:view_all', 'state:manage',
                'district:create_admin', 'division:create_admin', 'station:create_head',
                'alert:send', 'reminder:send', 'reminder:to_io',
                'district:view_data', 'station:view_data', 'station:select_multiple',
                'case:create', 'case:view_station', 'case:edit_station', 'case:edit_district', 'case:delete',
                'user:create', 'user:view_profile', 'user:assign_role', 'report:generate'
            ],

            # District Admin: Create division/station head, view district data, send alerts & reminders
            'district_admin': [
                'division:create_admin', 'station:create_head',
                'district:view_data', 'station:view_data', 'station:select_multiple', 'station:switch',
                'alert:send', 'reminder:send', 'reminder:to_io',
                'case:create', 'case:view_station', 'case:edit_station', 'case:edit_district',
                'user:create', 'user:view_profile', 'user:assign_role', 'report:generate'
            ],

            # Division Admin (City / DySP / ACP / SDPO / ASP):
            # District & station data view, select multiple stations, own case edit, switch station, handle multi-stations
            'division_admin': [
                'district:view_data', 'station:view_data', 'station:select_multiple', 'station:switch', 'station:multi_handle',
                'case:create', 'case:view_station', 'case:edit_own', 'case:edit_station',
                'reminder:send', 'reminder:to_io', 'report:generate'
            ],
            'supervisor': [
                'district:view_data', 'station:view_data', 'station:select_multiple', 'station:switch', 'station:multi_handle',
                'case:create', 'case:view_station', 'case:edit_own', 'case:edit_station',
                'reminder:send', 'reminder:to_io', 'report:generate'
            ],

            # Station Head (PSI, API, PI, ASP): Edit station cases, view station data, reminder to IO
            'station_admin': [
                'station:view_data', 'case:create', 'case:view_station', 'case:edit_station',
                'reminder:to_io', 'reminder:send', 'user:create', 'user:view_profile', 'report:generate'
            ],

            # Officer (Regular Ranks): Edit own case, view station's cases
            'officer': [
                'station:view_data', 'case:create', 'case:view_station', 'case:edit_own',
                'user:view_profile', 'report:generate'
            ],
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

        self.stdout.write(self.style.SUCCESS("  [+] Dynamic RBAC Matrix Configured for 6 Police Roles!"))

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

        self.stdout.write(self.style.SUCCESS("\n[SUCCESS] Master Dynamic RBAC Seeding Completed Successfully!"))
