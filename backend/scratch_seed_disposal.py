import os, django, random
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from apps.cases.models import CaseRecord

CaseRecord.objects.all().delete()

stations = ['Central', 'North']
officers = [('Test IO', 'uid-test'), ('Other IO', 'uid-other')]
months = ['2026-09-15', '2026-10-15']

for i in range(25):
    st = stations[i % 2]
    off = officers[i % 2]
    dt = months[i % 2]
    CaseRecord.objects.create(
        module_key='theft',
        case_number=f'CR_{i}',
        station_name=st,
        assigned_officer=off[0],
        assigned_officer_uid=off[1],
        extra_fields={'ccStNumber': f'CC-{i}', 'disposal_date': dt, 'section': '379', 'act': 'IPC'}
    )
print("Seeded 25 disposed cases.")
