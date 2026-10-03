import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord
from apps.cases.constants import CC_ST_KEYS, DISPOSAL_KEYS
from apps.cases.utils import get_cases_by_status
import json

all_cases = CaseRecord.objects.all()

old_disposal = []
for c in all_cases:
    extra = c.extra_fields or {}
    for k in CC_ST_KEYS:
        val = extra.get(k)
        if val is not None and str(val).strip():
            old_disposal.append(c)
            break

new_disposal = list(get_cases_by_status('disposal'))

print("OLD DISPOSAL COUNT:", len(old_disposal))
print("NEW DISPOSAL COUNT:", len(new_disposal))

print("\n--- OLD DISPOSAL CASES ---")
for c in old_disposal:
    status_now = 'Disposal' if c in new_disposal else 'Pending'
    extra = c.extra_fields or {}
    rel_fields = {k: extra.get(k) for k in CC_ST_KEYS + DISPOSAL_KEYS if k in extra}
    print(f"ID: {c.id} | Now: {status_now} | Fields: {json.dumps(rel_fields)}")

print("\n--- NEW DISPOSAL CASES NOT IN OLD ---")
for c in new_disposal:
    if c not in old_disposal:
        extra = c.extra_fields or {}
        rel_fields = {k: extra.get(k) for k in CC_ST_KEYS + DISPOSAL_KEYS if k in extra}
        print(f"ID: {c.id} | Fields: {json.dumps(rel_fields)}")
