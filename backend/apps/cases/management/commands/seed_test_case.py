import uuid
import datetime
from django.core.management.base import BaseCommand
from apps.cases.models import CaseRecord

class Command(BaseCommand):
    help = 'Create a complete test case with dummy data for testing purposes.'

    def add_arguments(self, parser):
        parser.add_argument('--category', type=str, default='Murder', help='Sub-category name (e.g. Murder, Theft, Robbery)')
        parser.add_argument('--module', type=str, default='form_1_5', help='Module key (e.g. form_1_5, women, cyber, ad)')
        parser.add_argument('--cr', type=str, default=None, help='Specific CR Number (defaults to auto-generated)')
        parser.add_argument('--station', type=str, default='Panchavati Police Station', help='Police station name')

    def handle(self, *args, **options):
        category = options['category']
        module = options['module']
        station = options['station']
        now = datetime.datetime.now()
        now_str = now.strftime('%d/%m/%Y %H:%M')
        date_str = now.strftime('%d/%m/%Y')
        cr = options['cr'] or f"CR/{int(now.timestamp()) % 90000 + 10000}/{now.year}"
        case_id = str(uuid.uuid4())

        extra_fields = {
            'commonForm': {
                'crNo': cr,
                'charges': {
                    'charge-1': {
                        'act': 'BNS',
                        'sections': ['103(1)', '3(5)'],
                    }
                },
                'spotAddress': 'Near Ramkund Ghat, Panchavati, Nashik - 422003',
                'complainant': {
                    'name': 'Ramesh Vithal Patil',
                    'age': '42',
                    'gender': 'Male',
                    'mobile': '9822012345',
                    'occupation': 'Shop Owner / Trader',
                    'address': 'Flat 101, Shanti Niketan, College Road, Nashik',
                    'aadhaar': '987654321098',
                    'pan': 'ABCDE1234F',
                },
                'accused': [
                    {
                        'name': 'Suresh Tukaram Shinde',
                        'age': '29',
                        'gender': 'Male',
                        'mobile': '9876543210',
                        'occupation': 'Driver',
                        'address': 'H.No. 45, Near Hanuman Temple, CIDCO, Nashik',
                        'aadhaar': '876543210987',
                        'pan': 'XYZAB5678K',
                        'religion': 'Hindu',
                        'caste': 'Kunbi',
                        'role': 'accused',
                    }
                ],
                'procedural_checklists': [
                    {'item_name': 'Spot Panchanama', 'is_checked': True, 'event_datetime': now_str},
                    {'item_name': 'Seizure Panchanama', 'is_checked': True, 'event_datetime': now_str},
                    {'item_name': 'Inquest Panchanama', 'is_checked': True, 'event_datetime': now_str},
                ],
                'seizure_items': [
                    {
                        'object_name': 'Motorcycle & Smartphone',
                        'seizure_description': 'Hero Splendor (MH-15-AB-1234) & Samsung M31 recovered on spot',
                        'seizure_date': now_str,
                    }
                ],
                'village_town': 'Panchavati',
                'area_name': 'Ramkund Ghat Road',
                'crime_spot_address': 'Near Ramkund Ghat, Panchavati, Nashik - 422003',
                'distance_from_ps': '2.5 km',
                'direction_from_ps': 'North-East',
                'registered_datetime': now_str,
                'occurrence_datetime': (now - datetime.timedelta(hours=3)).strftime('%d/%m/%Y %H:%M'),
                'io_name': 'API Rajesh Gaikwad',
                'io_designation': 'API',
                'registered_by_name': 'PSI Sachin Deshmukh',
                'registered_by_designation': 'PSI',
                'e_shakshya': True,
                'fingerprint_taken': True,
                'cctv_checked': True,
            },
            'charges': [
                {'act': 'BNS', 'section': '103(1)'},
                {'act': 'BNS', 'section': '3(5)'},
            ],
            'village_town': 'Panchavati',
            'area_name': 'Ramkund Ghat Road',
            'crime_spot_address': 'Near Ramkund Ghat, Panchavati, Nashik - 422003',
            'brief_description': f'Test case for {category}. Suspect apprehended with evidence. Automated test seeding.',
        }

        record = CaseRecord.objects.create(
            id=case_id,
            module_key=module,
            sub_category=category,
            title=f"{category} - {cr}",
            case_number=cr,
            description=f"Automated test case for {category} generated for testing purposes.",
            complainant="Ramesh Vithal Patil",
            accused="Suresh Tukaram Shinde",
            location="Near Ramkund Ghat, Panchavati, Nashik - 422003",
            incident_date=now - datetime.timedelta(hours=3),
            priority="High",
            status="Pending",
            assigned_officer="API Rajesh Gaikwad",
            station_name=station,
            created_by="Automated Test Seeder",
            extra_fields=extra_fields,
        )

        self.stdout.write(self.style.SUCCESS(
            f"Successfully created test case:\n"
            f"  - Case ID: {record.id}\n"
            f"  - CR Number: {record.case_number}\n"
            f"  - Category: {record.sub_category}\n"
            f"  - Station: {record.station_name}\n"
            f"  - Status: {record.status}\n"
            f"  - Complainant: {record.complainant}\n"
            f"  - Accused: {record.accused}"
        ))
