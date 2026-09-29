import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord, _extract_first_non_empty
from apps.cases.constants import CC_ST_KEYS

cursor = connection.cursor()

print('--- 4. CURRENT SCHEMA ---')
cursor.execute("SHOW search_path;")
print("search_path:", cursor.fetchone()[0])
cursor.execute("SELECT current_schema();")
print("current_schema:", cursor.fetchone()[0])

print('\n--- 1. 31 CASES TABLE ---')
cases = CaseRecord.objects.filter(status__in=['Open', 'Under Investigation'])
pending_count = 0
disposal_count = 0

print(f"{'Case ID':<40} | {'Current Status':<20} | {'CC/ST Present':<15}")
print("-" * 80)
for c in cases:
    extra = c.extra_fields if isinstance(c.extra_fields, dict) else {}
    has_cc = bool(_extract_first_non_empty(extra, CC_ST_KEYS))
    
    # Check commonForm.court.ccStNumber explicitly just in case
    if not has_cc:
        try:
            cf = extra.get('commonForm', {})
            court = cf.get('court', {})
            has_cc = bool(court.get('ccStNumber'))
        except AttributeError:
            pass
            
    print(f"{c.id:<40} | {c.status:<20} | {'Yes' if has_cc else 'No':<15}")
    if has_cc:
        disposal_count += 1
    else:
        pending_count += 1

print('\n--- 2. PENDING VS DISPOSAL PROJECTION ---')
print(f"Would become Pending: {pending_count}")
print(f"Would become Disposal: {disposal_count}")

print('\n--- 5. ONE PENDING CASE EXTRA_FIELDS ---')
pending_case = CaseRecord.objects.filter(status='Pending').first()
if pending_case:
    import json
    print(json.dumps(pending_case.extra_fields, indent=2))
else:
    print("No Pending cases found.")
