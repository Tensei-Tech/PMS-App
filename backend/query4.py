import os
import json
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.constants import CC_ST_KEYS
from apps.cases.models import _extract_first_non_empty

cursor = connection.cursor()

cursor.execute("SELECT id, status, extra_fields FROM cases_caserecord WHERE status IN ('Open', 'Under Investigation');")
cases = cursor.fetchall()
print(f"Total cases found: {len(cases)}")

pending_count = 0
disposal_count = 0

print('\n--- 1. 31 CASES TABLE ---')
print(f"{'Case ID':<40} | {'Current Status':<20} | {'CC/ST Present':<15}")
print("-" * 80)

for c_id, status, extra_fields_raw in cases:
    extra = extra_fields_raw if isinstance(extra_fields_raw, dict) else {}
    if isinstance(extra_fields_raw, str):
        try:
            extra = json.loads(extra_fields_raw)
        except:
            pass
            
    has_cc = bool(_extract_first_non_empty(extra, CC_ST_KEYS))
    if not has_cc:
        try:
            cf = extra.get('commonForm', {})
            court = cf.get('court', {})
            has_cc = bool(court.get('ccStNumber'))
        except AttributeError:
            pass
            
    print(f"{c_id:<40} | {status:<20} | {'Yes' if has_cc else 'No':<15}")
    if has_cc:
        disposal_count += 1
    else:
        pending_count += 1

print('\n--- 2. PENDING VS DISPOSAL PROJECTION ---')
print(f"Would become Pending: {pending_count}")
print(f"Would become Disposal: {disposal_count}")
