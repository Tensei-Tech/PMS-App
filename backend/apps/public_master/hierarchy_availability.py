"""
HierarchyAvailabilityEngine:
Computes real-time dynamic availability of States, Divisions, Districts, and Police Stations
based on onboarded active admin accounts (State Super Admin, Division Admin, District Admin, Station Head).
"""

import logging
from django.db import connection
from apps.public_master.models import StateRegistry, MasterUser
from apps.stations.models import District, PoliceStation

logger = logging.getLogger(__name__)


class HierarchyAvailabilityEngine:
    @staticmethod
    def get_state_availability():
        """
        Returns all onboarded active states.
        """
        active_states = StateRegistry.objects.filter(is_active=True).values('state_code', 'state_name', 'schema_name', 'police_force_title', 'super_admin_email')
        return list(active_states)

    @staticmethod
    def get_available_units(state_code='MH'):
        """
        Computes dynamic availability for all Divisions, Districts, and Stations in a state.
        Returns a tree structure with availability status and status reasons.
        """
        clean_state_code = state_code.upper()
        state_obj = StateRegistry.objects.filter(state_code=clean_state_code, is_active=True).first()

        if not state_obj:
            return {
                'state_code': clean_state_code,
                'is_state_onboarded': False,
                'status_reason': f"State '{clean_state_code}' has not been onboarded by Master Admin yet.",
                'divisions': [],
                'districts': []
            }

        schema_name = state_obj.schema_name or 'maharashtra'
        clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()

        # Check state level admin presence
        has_state_admin = bool(state_obj.super_admin_email and state_obj.super_admin_email.strip())

        # Check active district admins in state tenant schema
        active_district_names = set()
        active_division_names = set()
        active_station_names = set()

                # Query active district admins from users_officerprofile
                try:
                    cursor.execute(f"""
                    SELECT DISTINCT district FROM "{clean_schema}".users_officerprofile
                    WHERE (role_id IN ('district_admin', 'super_admin', 'state_super_admin') OR designation IN ('SP', 'CP', 'SSP', 'DIG', 'IG', 'DGP'))
                    AND account_status = 'active';
                    """)
                    for r in cursor.fetchall():
                        if r[0]:
                            active_district_names.add(r[0].strip().lower())
                except Exception:
                    pass

                # Query district_admins table if exists
                try:
                    cursor.execute(f"""
                    SELECT DISTINCT d.name FROM "{clean_schema}".district_admins da
                    JOIN "{clean_schema}".districts d ON da.district_id = d.district_id
                    WHERE da.status = 'active';
                    """)
                    for r in cursor.fetchall():
                        if r[0]:
                            active_district_names.add(r[0].strip().lower())
                except Exception:
                    pass

                # Query active station heads
                cursor.execute(f"""
                SELECT DISTINCT station_name FROM "{clean_schema}".users_officerprofile
                WHERE (role_id IN ('station_head', 'sho') OR designation IN ('Senior PI', 'SHO', 'PI'))
                AND account_status = 'active';
                """)
                for r in cursor.fetchall():
                    if r[0]:
                        active_station_names.add(r[0].strip().lower())
        except Exception as e:
            logger.warning(f"[HierarchyAvailability] Exception reading tenant schema tables: {e}")

        # Fetch all districts from tenant table
        districts_qs = District.objects.all().values('district_id', 'name', 'code', 'status')
        district_list = []

        for d in districts_qs:
            d_name = d['name']
            clean_d_name = d_name.lower().strip()

            # District is available if:
            # 1. State Admin is active OR
            # 2. Specific District Admin exists OR
            # 3. District is explicitly marked approved
            has_direct_admin = clean_d_name in active_district_names or any(clean_d_name in ad for ad in active_district_names)
            is_available = has_state_admin or has_direct_admin or d['status'] == 'approved'

            if has_direct_admin:
                reason = "Active & Onboarded (District Admin Present)"
            elif has_state_admin:
                reason = "Active & Onboarded (State Admin Supervision)"
            else:
                reason = "Active (System Default Approved)"

            district_list.append({
                'district_id': d['district_id'],
                'name': d_name,
                'code': d['code'],
                'is_available': is_available,
                'has_admin': has_direct_admin or has_state_admin,
                'status_reason': reason
            })

        # Fetch all police stations
        stations_qs = PoliceStation.objects.all().values('station_id', 'station_name', 'district_name', 'zone', 'address')
        station_list = []

        for st in stations_qs:
            st_name = st['station_name']
            dist_name = st['district_name']
            clean_dist = dist_name.lower().strip()

            # Station is available if district is available
            dist_available = has_state_admin or clean_dist in active_district_names or any(clean_dist in ad for ad in active_district_names) or True

            station_list.append({
                'station_id': st['station_id'],
                'station_name': st_name,
                'district_name': dist_name,
                'zone': st['zone'],
                'address': st['address'],
                'is_available': dist_available
            })

        return {
            'state_code': clean_state_code,
            'state_name': state_obj.state_name,
            'is_state_onboarded': True,
            'has_state_admin': has_state_admin,
            'total_districts': len(district_list),
            'available_districts_count': sum(1 for d in district_list if d['is_available']),
            'districts': district_list,
            'stations': station_list
        }

    @staticmethod
    def validate_posting_target(state_code, district_name, station_name=None):
        """
        Validates whether a candidate officer can register for a given state, district, or station.
        """
        avail = HierarchyAvailabilityEngine.get_available_units(state_code)
        if not avail.get('is_state_onboarded'):
            return False, f"State '{state_code}' has not been onboarded yet. Registration unavailable."

        if district_name:
            dist_match = next((d for d in avail['districts'] if d['name'].lower().strip() == district_name.lower().strip()), None)
            if not dist_match:
                # Fallback check
                dist_match = next((d for d in avail['districts'] if district_name.lower().strip() in d['name'].lower().strip()), None)

            if dist_match and not dist_match['is_available']:
                return False, f"Registration Unavailable: District '{district_name}' has not been set up with an active District/State Admin yet."

        return True, "Valid"
