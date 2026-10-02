import os
import django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from apps.cases.models import CaseRecord
from apps.cases.utils import get_cases_by_status
import json

old_disposal = CaseRecord.objects.filter(status='Disposal')
new_disposal_qs = get_cases_by_status('disposal')
new_disposal_ids = set(new_disposal_qs.values_list('id', flat=True))
new_pending_qs = get_cases_by_status('pending')
new_pending_ids = set(new_pending_qs.values_list('id', flat=True))

print("=== CASES THAT WERE DISPOSAL UNDER OLD LOGIC ===")
for c in old_disposal:
    new_status = "Disposal" if c.id in new_disposal_ids else ("Pending" if c.id in new_pending_ids else "Other")
    relevant = {k: v for k, v in (c.extra_fields or {}).items() if 'cc' in k.lower() or 'st' in k.lower() or 'charge' in k.lower() or 'final' in k.lower() or 'summary' in k.lower() or 'nc' in k.lower() or 'abet' in k.lower()}
    print(f"ID {c.id} ({c.case_number}): Now -> {new_status}. Keys: {relevant}")

print("\n=== CASES THAT MOVED INTO DISPOSAL (Were Pending/Other, now Disposal) ===")
old_disposal_ids = set(old_disposal.values_list('id', flat=True))
moved_to_disposal = [c for c in new_disposal_qs if c.id not in old_disposal_ids]
for c in moved_to_disposal:
    print(f"ID {c.id} ({c.case_number}): Old Status -> {c.status}")
    relevant = {k: v for k, v in (c.extra_fields or {}).items() if 'cc' in k.lower() or 'st' in k.lower() or 'charge' in k.lower() or 'final' in k.lower() or 'summary' in k.lower() or 'nc' in k.lower() or 'abet' in k.lower()}
    print(f"   Keys: {relevant}")

from apps.cases.constants import DISPOSAL_KEYS
print("\n=== CURRENT DISPOSAL KEYS ===")
print(DISPOSAL_KEYS)
