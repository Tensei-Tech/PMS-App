import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord, is_ad_case_disposed
import json
import re

all_cases = CaseRecord.objects.all()

keys_found = set()
pattern = re.compile(r'cc.*st|st.*cc|cc_no|st_no|charge.*sheet|final.*no|summary|dispos|cc.*no|st.*no', re.IGNORECASE)

for c in all_cases:
    if c.extra_fields and isinstance(c.extra_fields, dict):
        for k in c.extra_fields.keys():
            if pattern.search(k):
                keys_found.add(k)
            # Or just blindly check for 'cc', 'st', 'charge', 'final', 'summary'
            if any(x in k.lower() for x in ['cc', 'st', 'charge', 'final', 'summary']):
                keys_found.add(k)

print("FOUND KEYS:", keys_found)

from apps.cases.constants import DISPOSAL_KEYS
from apps.cases.utils import get_cases_by_status

old_disposal = []
for c in all_cases:
    if c.status in ['Disposal', 'Disposed', 'Closed', 'Resolved'] or is_ad_case_disposed(c):
        old_disposal.append(c)

new_disposal = list(get_cases_by_status('disposal'))

print("OLD DISPOSAL COUNT:", len(old_disposal))
print("NEW DISPOSAL COUNT:", len(new_disposal))

print("\n--- MOVED PENDING -> DISPOSAL ---")
for c in new_disposal:
    if c not in old_disposal:
        extra = c.extra_fields or {}
        rel_fields = {k: extra.get(k) for k in list(keys_found)}
        print(f"ID: {c.id} | Fields: {json.dumps(rel_fields)}")

print("\n--- MOVED DISPOSAL -> PENDING ---")
for c in old_disposal:
    if c not in new_disposal:
        extra = c.extra_fields or {}
        rel_fields = {k: extra.get(k) for k in list(keys_found)}
        print(f"ID: {c.id} | Fields: {json.dumps(rel_fields)}")
