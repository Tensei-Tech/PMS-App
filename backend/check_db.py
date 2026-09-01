import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord

print(f"Total Case Records: {CaseRecord.objects.count()}")
for case in CaseRecord.objects.all():
    print(f"ID: {case.id}")
    print(f"Module: {case.module_key}")
    print(f"Case No: {case.case_number}")
    print(f"Title: {case.title}")
    print(f"Station: {case.station_name}")
    print(f"Status: {case.status} | Priority: {case.priority}")
    print(f"Complainant: {case.complainant} | Accused: {case.accused}")
    print(f"Extra Fields: {case.extra_fields}")
    print("=" * 60)
