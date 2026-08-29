"""
Django Management Command: import_police_hierarchy
Parses maharashtra_police_stations.xlsx (or state dataset files), applies official Government of Maharashtra
name transformations (Chhatrapati Sambhajinagar, Dharashiv, Ahilyanagar), and seeds:
1. Public Master Tables (`public.master_divisions`, `public.districts`, `public.police_stations`)
2. State Tenant Schema Tables (`"maharashtra".users_district`, `"maharashtra".users_policestation`, etc.)
"""

import os
import re
import uuid
import zipfile
import xml.etree.ElementTree as ET
from django.core.management.base import BaseCommand
from django.db import connection
from apps.public_master.models import StateRegistry, MasterDivision
from apps.stations.models import District, PoliceStation


# Official Government Name Transformations
DISTRICT_NAME_MAP = {
    'aurangabad': 'Chhatrapati Sambhajinagar',
    'osmanabad': 'Dharashiv',
    'ahmednagar': 'Ahmednagar (Ahilyanagar)',
}

DIVISION_NAME_MAP = {
    'aurangabad': 'Chhatrapati Sambhajinagar',
}

# Complete 36 Maharashtra Districts List for Fallback/Verification
MAHARASHTRA_36_DISTRICTS = [
    # Chhatrapati Sambhajinagar Division
    ('Chhatrapati Sambhajinagar', 'Chhatrapati Sambhajinagar'),
    ('Dharashiv', 'Chhatrapati Sambhajinagar'),
    ('Jalna', 'Chhatrapati Sambhajinagar'),
    ('Beed', 'Chhatrapati Sambhajinagar'),
    ('Latur', 'Chhatrapati Sambhajinagar'),
    ('Nanded', 'Chhatrapati Sambhajinagar'),
    ('Parbhani', 'Chhatrapati Sambhajinagar'),
    ('Hingoli', 'Chhatrapati Sambhajinagar'),
    # Pune Division
    ('Pune', 'Pune'),
    ('Satara', 'Pune'),
    ('Solapur', 'Pune'),
    ('Kolhapur', 'Pune'),
    ('Sangli', 'Pune'),
    # Nashik Division
    ('Nashik', 'Nashik'),
    ('Ahmednagar (Ahilyanagar)', 'Nashik'),
    ('Jalgaon', 'Nashik'),
    ('Dhule', 'Nashik'),
    ('Nandurbar', 'Nashik'),
    # Konkan Division
    ('Mumbai City', 'Konkan'),
    ('Mumbai Suburban', 'Konkan'),
    ('Thane', 'Konkan'),
    ('Palghar', 'Konkan'),
    ('Raigad', 'Konkan'),
    ('Ratnagiri', 'Konkan'),
    ('Sindhudurg', 'Konkan'),
    # Nagpur Division
    ('Nagpur', 'Nagpur'),
    ('Bhandara', 'Nagpur'),
    ('Gondia', 'Nagpur'),
    ('Chandrapur', 'Nagpur'),
    ('Gadchiroli', 'Nagpur'),
    ('Wardha', 'Nagpur'),
    # Amravati Division
    ('Amravati', 'Amravati'),
    ('Akola', 'Amravati'),
    ('Buldhana', 'Amravati'),
    ('Washim', 'Amravati'),
    ('Yavatmal', 'Amravati'),
]


class Command(BaseCommand):
    help = "Import and seed Police Divisions, Districts (36), and Police Stations (825) from Excel dataset."

    def add_arguments(self, parser):
        parser.add_argument('--file', type=str, default='maharashtra_police_stations.xlsx', help='Path to Excel dataset file')
        parser.add_argument('--state-code', type=str, default='MH', help='State code (e.g. MH)')

    def handle(self, *args, **options):
        file_path = options['file']
        state_code = options['state_code'].upper()

        if not os.path.isabs(file_path):
            candidates = [
                os.path.join(r'a:\PMS\PMS-App', options['file']),
                os.path.join(r'a:\PMS\PMS-App\backend', options['file']),
                os.path.abspath(options['file'])
            ]
            for c in candidates:
                if os.path.exists(c):
                    file_path = c
                    break

        if not os.path.exists(file_path):
            self.stdout.write(self.style.ERROR(f"Dataset file not found at: {file_path}"))
            return

        self.stdout.write(self.style.SUCCESS(f"Processing dataset: {file_path} for State: {state_code}"))

        # Parse Excel XML zip format directly
        parsed_records = []
        try:
            with zipfile.ZipFile(file_path) as z:
                sheet_xml = z.read('xl/worksheets/sheet1.xml')
                tree = ET.fromstring(sheet_xml)
                ns = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
                rows = tree.findall('.//s:row', ns)

                for r in rows[1:]:
                    cells = []
                    for c in r.findall('s:c', ns):
                        t_el = c.find('.//s:t', ns)
                        v_el = c.find('s:v', ns)
                        val = t_el.text if t_el is not None else (v_el.text if v_el is not None else '')
                        cells.append(val.strip())

                    if len(cells) >= 5:
                        station_name = cells[0]
                        location = cells[1]
                        raw_district = cells[2]
                        raw_division = cells[3]
                        state_name = cells[4] or 'Maharashtra'

                        # Apply official name transformations
                        clean_dist_lower = raw_district.lower().strip()
                        clean_div_lower = raw_division.lower().strip()

                        district_name = DISTRICT_NAME_MAP.get(clean_dist_lower, raw_district)
                        division_name = DIVISION_NAME_MAP.get(clean_div_lower, raw_division)

                        parsed_records.append({
                            'station_name': station_name,
                            'location': location,
                            'district_name': district_name,
                            'division_name': division_name,
                            'state_name': state_name
                        })
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Failed to parse Excel XML: {e}"))
            return

        self.stdout.write(self.style.SUCCESS(f"Successfully parsed {len(parsed_records)} station records from Excel."))

        # 0. Ensure public.master_divisions table exists
        with connection.cursor() as cursor:
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS public.master_divisions (
                id BIGSERIAL PRIMARY KEY,
                state_code VARCHAR(10) DEFAULT 'MH',
                state_name VARCHAR(100) DEFAULT 'Maharashtra',
                name VARCHAR(128),
                code VARCHAR(64),
                created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT unique_state_div_name UNIQUE (state_code, name)
            );
            """)

        # 1. Seed Master Divisions in public.master_divisions
        unique_divisions = set(r['division_name'] for r in parsed_records)
        unique_divisions.update([d[1] for d in MAHARASHTRA_36_DISTRICTS])

        div_map = {}
        for div_name in sorted(list(unique_divisions)):
            div_code = f"DIV-{state_code}-{div_name[:4].upper()}"
            div_obj, _ = MasterDivision.objects.update_or_create(
                state_code=state_code,
                name=div_name,
                defaults={'state_name': 'Maharashtra', 'code': div_code}
            )
            div_map[div_name] = div_obj

        self.stdout.write(self.style.SUCCESS(f"Seeded {len(div_map)} Divisions in public.master_divisions."))

        # 2. Seed All 36 Districts in public AND state tenant schema (e.g. maharashtra)
        unique_districts = {}
        for r in parsed_records:
            unique_districts[r['district_name']] = r['division_name']

        for dist_name, div_name in MAHARASHTRA_36_DISTRICTS:
            if dist_name not in unique_districts:
                unique_districts[dist_name] = div_name

        schema_name = StateRegistry.objects.filter(state_code=state_code).values_list('schema_name', flat=True).first() or 'maharashtra'
        clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()

        with connection.cursor() as cursor:
            cursor.execute(f'CREATE SCHEMA IF NOT EXISTS "{clean_schema}";')
            cursor.execute(f"""
            CREATE TABLE IF NOT EXISTS "{clean_schema}".districts (
                district_id VARCHAR(64) PRIMARY KEY,
                name VARCHAR(128) UNIQUE,
                code VARCHAR(32),
                status VARCHAR(32) DEFAULT 'approved',
                approved_by_super_admin_uid VARCHAR(128),
                created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS "{clean_schema}".stations_policestation (
                station_id VARCHAR(64) PRIMARY KEY,
                station_name VARCHAR(255) UNIQUE,
                district_id VARCHAR(64),
                district_name VARCHAR(128),
                zone VARCHAR(128),
                address TEXT,
                landline VARCHAR(32),
                pi_in_charge VARCHAR(255),
                created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
            );
            """)

        seeded_districts = 0
        dist_rows = []
        for dist_name, div_name in unique_districts.items():
            dist_slug = "".join(c for c in dist_name if c.isalnum()).upper()[:8]
            dist_id = f"DST-{state_code}-{dist_slug}"
            dist_rows.append((dist_id, dist_name, 'approved'))
            seeded_districts += 1

        with connection.cursor() as cursor:
            cursor.execute(f'TRUNCATE TABLE "{clean_schema}".districts CASCADE;')
            cursor.executemany(f"""
            INSERT INTO "{clean_schema}".districts (district_id, name, status)
            VALUES (%s, %s, %s)
            ON CONFLICT (district_id) DO UPDATE SET name = EXCLUDED.name;
            """, dist_rows)

        self.stdout.write(self.style.SUCCESS(f"Seeded {seeded_districts} Districts in schema '{clean_schema}'."))

        # 3. Seed All 825 Police Stations into state tenant schema
        st_rows = []
        for i, r in enumerate(parsed_records, 1):
            st_name = r['station_name']
            dist_name = r['district_name']
            div_name = r['division_name']
            address = r['location']
            dist_slug = "".join(c for c in dist_name if c.isalnum()).upper()[:8]
            st_id = f"PS-{state_code}-{dist_slug}-{i:03d}"
            dist_id = f"DST-{state_code}-{dist_slug}"
            st_rows.append((st_id, st_name, dist_id, dist_name, f"{div_name} Zone", address))

        with connection.cursor() as cursor:
            cursor.executemany(f"""
            INSERT INTO "{clean_schema}".stations_policestation (
                station_id, station_name, district_id, district_name, zone, address
            ) VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (station_name) DO UPDATE SET
                district_name = EXCLUDED.district_name,
                zone = EXCLUDED.zone,
                address = EXCLUDED.address;
            """, st_rows)

        with connection.cursor() as cursor:
            cursor.execute(f'SELECT COUNT(*) FROM "{clean_schema}".stations_policestation;')
            total_st = cursor.fetchone()[0]

        self.stdout.write(self.style.SUCCESS(f"Import complete! Total {total_st} Police Stations active in schema '{clean_schema}'."))



