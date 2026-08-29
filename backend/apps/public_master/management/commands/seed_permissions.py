# pyrefly: ignore [missing-import]
from django.core.management.base import BaseCommand
from apps.public_master.models import Role, Permission, RolePermission, Designation
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Seeds 100% Dynamic Database Permissions, Roles, and Police Rank Designations.'

    def handle(self, *args, **options):
        self.stdout.write(self.style.MIGRATE_HEADING("=== SEEDING DYNAMIC DATABASE PERMISSIONS & ROLES ==="))

        # 1. Seed Roles
        roles_data = [
            ('master_admin', 'Master Admin', 'global', 'Top-level Company System Administrator'),
            ('state_super_admin', 'State Super Admin', 'state', 'State Police Leadership (DG, ADG, IG, DIG)'),
            ('district_admin', 'District Admin', 'district', 'District Police Leadership (SP, SSP, DCP)'),
            ('division_admin', 'Division Admin', 'district', 'Subdivision / Zone Admin (DySP, ACP, SDPO, ASP)'),
            ('station_head', 'Station Head / SHO', 'station', 'Police Station In-Charge (PI, API, PSI)'),
            ('officer', 'Field Police Officer', 'station', 'Investigating Officer / Field Staff'),
        ]

        roles_dict = {}
        for r_id, r_name, r_level, r_desc in roles_data:
            role_obj, created = Role.objects.update_or_create(
                id=r_id,
                defaults={'name': r_name, 'level': r_level, 'description': r_desc}
            )
            roles_dict[r_id] = role_obj
            status_str = "Created" if created else "Updated"
            self.stdout.write(f"  Role: [{r_id}] -> {status_str}")

        # 2. Seed Permissions Master
        permissions_data = [
            # Case Management
            ('case:view', 'cases', 'View cases'),
            ('case:create', 'cases', 'Create new case/FIR'),
            ('case:edit', 'cases', 'Edit assigned or station case'),
            ('case:delete', 'cases', 'Delete case record'),
            ('case:approve', 'cases', 'Approve submitted case reports'),
            ('case:assign', 'cases', 'Assign case to Investigating Officer'),
            
            # Station Level
            ('station:view', 'stations', 'View station details and roster'),
            ('station:create', 'stations', 'Register new police station'),
            ('station:case:edit', 'stations', 'Edit all station level cases'),
            ('station:reminder:send', 'stations', 'Send case reminder to IO'),
            
            # Division / Subdivision
            ('division:view', 'division', 'View division and subdivision stations'),
            ('division:multi_station', 'division', 'Access multiple stations in division'),
            ('division:station:switch', 'division', 'Switch station context in district'),
            
            # District Level
            ('district:view', 'districts', 'View district-wide police data'),
            ('district:create', 'districts', 'Manage district boundaries'),
            ('district:alert:send', 'districts', 'Send district emergency alert'),
            ('district:reminder:send', 'districts', 'Send district reminder'),
            
            # State Level
            ('state:view', 'state', 'View state-wide police analytics'),
            ('state:admin:manage', 'state', 'Create & manage district/division admins'),
            ('state:alert:send', 'state', 'Dispatch state-wide alert'),
            ('state:reminder:send', 'state', 'Send state-level reminder'),
            
            # User & Role Admin
            ('user:view', 'users', 'View user officer accounts'),
            ('user:create', 'users', 'Register/create officer account'),
            ('user:approve', 'users', 'Approve/reject pending registrations'),
            ('user:permission:manage', 'users', 'Grant or revoke permissions dynamically'),
        ]

        perms_dict = {}
        for p_id, p_mod, p_desc in permissions_data:
            perm_obj, created = Permission.objects.update_or_create(
                id=p_id,
                defaults={'module': p_mod, 'description': p_desc}
            )
            perms_dict[p_id] = perm_obj

        self.stdout.write(self.style.SUCCESS(f"  Permissions: {len(permissions_data)} master permissions created/updated."))

        # 3. Seed Dynamic Role-Permission Mappings in DB
        role_permission_mappings = {
            'master_admin': list(perms_dict.keys()),
            'state_super_admin': [
                'state:view', 'state:admin:manage', 'state:alert:send', 'state:reminder:send',
                'district:view', 'district:alert:send', 'district:reminder:send',
                'station:view', 'case:view', 'user:view', 'user:approve', 'user:create'
            ],
            'district_admin': [
                'district:view', 'district:alert:send', 'district:reminder:send',
                'division:view', 'division:multi_station',
                'station:view', 'station:case:edit', 'case:view', 'case:approve',
                'user:view', 'user:approve'
            ],
            'division_admin': [
                'division:view', 'division:multi_station', 'division:station:switch',
                'district:view', 'station:view', 'case:view', 'case:edit', 'case:assign'
            ],
            'station_head': [
                'station:view', 'station:case:edit', 'station:reminder:send',
                'case:view', 'case:create', 'case:edit', 'case:approve', 'case:assign',
                'user:view', 'user:approve'
            ],
            'officer': [
                'station:view', 'case:view', 'case:create', 'case:edit'
            ],
        }

        for role_id, perm_codes in role_permission_mappings.items():
            role_obj = roles_dict[role_id]
            for perm_code in perm_codes:
                perm_obj = perms_dict[perm_code]
                RolePermission.objects.update_or_create(
                    role=role_obj,
                    permission=perm_obj,
                    defaults={'is_granted': True}
                )

        self.stdout.write(self.style.SUCCESS("  Role-Permission Mappings: 100% DB-driven role mapping initialized."))

        # 4. Seed Police Rank Designations (Level 1 to 12) with Dynamic DB Capabilities
        designations = [
            # Staff Ranks (Station Level, Non-Admin)
            ('PC', 'Police Constable', 'Police Constable (PC)', 12, 'staff_only', ['field_officer'], [], 'station', 'station_admin', None, False, False, False, False, False, False),
            ('WPC', 'Women Police Constable', 'Women Police Constable (WPC)', 12, 'staff_only', ['field_officer'], [], 'station', 'station_admin', None, False, False, False, False, False, False),
            ('NPC', 'Naik Police Constable', 'Naik Police Constable (NPC)', 11, 'staff_only', ['field_officer'], [], 'station', 'station_admin', None, False, False, False, False, False, False),
            ('PN', 'Police Naik', 'Police Naik (PN)', 11, 'staff_only', ['field_officer'], [], 'station', 'station_admin', None, False, False, False, False, False, False),
            ('HC', 'Head Constable', 'Head Constable (HC)', 10, 'staff_only', ['field_officer'], [], 'station', 'station_admin', None, False, False, False, False, False, False),
            ('WHC', 'Women Head Constable', 'Women Head Constable (WHC)', 10, 'staff_only', ['field_officer'], [], 'station', 'station_admin', None, False, False, False, False, False, False),
            ('ASI', 'Assistant Sub Inspector', 'Assistant Sub Inspector (ASI)', 9, 'staff_only', ['field_officer'], [], 'station', 'station_admin', None, False, False, False, False, False, False),
            ('WASI', 'Women Assistant Sub Inspector', 'Women Assistant Sub Inspector (WASI)', 9, 'staff_only', ['field_officer'], [], 'station', 'station_admin', None, False, False, False, False, False, False),

            # Station Sub-Officers & Incharges (Dual: Field / Station Admin)
            ('PSI', 'Police Sub Inspector', 'Police Sub Inspector (PSI)', 8, 'dual_role', ['field_officer', 'admin_officer'], ['station_admin'], 'station', 'station_admin', None, False, False, False, False, False, True),
            ('API', 'Assistant Police Inspector', 'Assistant Police Inspector (API)', 7, 'dual_role', ['field_officer', 'admin_officer'], ['station_admin'], 'station', 'station_admin', None, False, False, False, False, False, True),
            ('PI', 'Police Inspector', 'Police Inspector (PI)', 6, 'dual_role', ['field_officer', 'admin_officer'], ['station_admin'], 'station', 'district_admin', None, False, False, False, False, False, True),
            ('SHO', 'Station House Officer', 'Station House Officer (SHO)', 6, 'dual_role', ['field_officer', 'admin_officer'], ['station_admin'], 'station', 'district_admin', None, False, False, False, False, False, True),

            # Sub-Divisional / Supervisory Officers (Station/Division Level)
            ('Dy. SP', 'Deputy Superintendent of Police', 'Deputy Superintendent of Police (Dy. SP)', 5, 'dual_role', ['field_officer', 'admin_officer'], ['station_admin', 'district_admin'], 'station', 'district_admin', 'Superintendent Police (Rural)', False, True, False, True, False, True),
            ('DySP', 'Deputy Superintendent of Police', 'Deputy Superintendent of Police (DySP)', 5, 'dual_role', ['field_officer', 'admin_officer'], ['station_admin', 'district_admin'], 'station', 'district_admin', 'Superintendent Police (Rural)', False, True, False, True, False, True),
            ('ASP', 'Assistant Superintendent of Police', 'Assistant Superintendent of Police (ASP)', 5, 'dual_role', ['field_officer', 'admin_officer'], ['station_admin', 'district_admin'], 'station', 'district_admin', 'Superintendent Police (Rural)', False, True, False, True, False, True),
            ('ACP', 'Assistant Commissioner of Police', 'Assistant Commissioner of Police (ACP)', 5, 'dual_role', ['field_officer', 'admin_officer'], ['station_admin', 'district_admin'], 'station', 'district_admin', 'Commissionerate Police', False, True, False, True, False, True),

            # District / Zone Command Level (Dual: Field / District Admin)
            ('DCP', 'Deputy Commissioner of Police', 'Deputy Commissioner of Police (DCP)', 4, 'dual_role', ['field_officer', 'admin_officer'], ['district_admin'], 'district', 'state_admin', 'Commissionerate Police', True, True, False, True, False, False),
            ('Addl. SP', 'Additional Superintendent of Police', 'Additional Superintendent of Police (Addl. SP)', 4, 'dual_role', ['field_officer', 'admin_officer'], ['district_admin'], 'district', 'state_admin', 'Superintendent Police (Rural)', True, True, False, True, False, False),
            ('Addl. CP', 'Additional Commissioner of Police', 'Additional Commissioner of Police (Addl. CP)', 4, 'dual_role', ['field_officer', 'admin_officer'], ['district_admin'], 'district', 'state_admin', 'Commissionerate Police', True, True, False, True, False, False),
            ('SP', 'Superintendent of Police', 'Superintendent of Police (SP)', 3, 'dual_role', ['field_officer', 'admin_officer'], ['district_admin'], 'district', 'state_admin', 'Superintendent Police (Rural)', True, True, False, True, False, False),
            ('CP', 'Commissioner of Police', 'Commissioner of Police (CP)', 3, 'dual_role', ['field_officer', 'admin_officer'], ['district_admin'], 'district', 'state_admin', 'Commissionerate Police', True, True, False, True, False, False),
            ('JT. CP', 'Joint Commissioner of Police', 'Joint Commissioner of Police (JT. CP)', 3, 'dual_role', ['field_officer', 'admin_officer'], ['district_admin'], 'district', 'state_admin', 'Commissionerate Police', True, True, False, True, False, False),

            # Division / Range Command Level (Dual: Field / Division Admin)
            ('DIG', 'Deputy Inspector General', 'Deputy Inspector General of Police (DIG)', 2, 'dual_role', ['field_officer', 'admin_officer'], ['division_admin'], 'division', 'state_admin', None, True, True, True, True, True, False),
            ('IG', 'Inspector General', 'Inspector General of Police (IG)', 2, 'dual_role', ['field_officer', 'admin_officer'], ['division_admin'], 'division', 'state_admin', None, True, True, True, True, True, False),
            ('Spl. IG', 'Special Inspector General', 'Special Inspector General of Police (Spl. IG)', 2, 'dual_role', ['field_officer', 'admin_officer'], ['division_admin'], 'division', 'state_admin', None, True, True, True, True, True, False),

            # State Apex Command Level (State Admin Only - Console Managed)
            ('ADG', 'Additional Director General', 'Additional Director General (ADG)', 1, 'state_hq_only', ['admin_officer'], ['state_admin'], 'state', 'master_admin', None, True, True, True, False, False, False),
            ('DGP', 'Director General of Police', 'Director General of Police (DGP)', 1, 'state_hq_only', ['admin_officer'], ['state_admin'], 'state', 'master_admin', None, True, True, True, False, False, False),
        ]

        for code, title, display_name, rank_level, role_type, allowed_cats, allowed_adm_roles, req_hierarchy, approver, implied_unit, can_transfer, can_cases, st_adm, dist_adm, div_adm, stn_adm in designations:
            Designation.objects.update_or_create(
                code=code,
                defaults={
                    'title': title,
                    'display_name': display_name,
                    'rank_level': rank_level,
                    'role_type': role_type,
                    'allowed_categories': allowed_cats,
                    'allowed_admin_roles': allowed_adm_roles,
                    'required_hierarchy_level': req_hierarchy,
                    'approving_authority': approver,
                    'implied_unit_type': implied_unit,
                    'can_approve_transfers': can_transfer,
                    'can_manage_all_cases': can_cases,
                    'is_state_admin_allowed': st_adm,
                    'is_district_admin_allowed': dist_adm,
                    'is_division_admin_allowed': div_adm,
                    'is_station_admin_allowed': stn_adm,
                    'is_active': True,
                }
            )

        self.stdout.write(self.style.SUCCESS("  Police Designations: Seeded dynamic DB matrix flags for all rank levels."))
        self.stdout.write(self.style.SUCCESS("\n[SUCCESS] 100% Dynamic Permissions & Hierarchy Seeding Completed!"))
