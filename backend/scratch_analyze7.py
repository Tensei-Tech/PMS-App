import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord, is_ad_case_disposed
from apps.cases.utils import get_cases_by_status
from django.db.models import Q

pending_qs = get_cases_by_status('pending')
disposal_qs = get_cases_by_status('disposal')
pending_ids = set(pending_qs.values_list('id', flat=True))
disposal_ids = set(disposal_qs.values_list('id', flat=True))

old_ad_disposed = CaseRecord.objects.filter(
    Q(status__in=['Disposal', 'Closed', 'Disposed', 'Resolved']) | Q(module_key='ad')
)

ad_cases_old_disposal = [c for c in old_ad_disposed if is_ad_case_disposed(c) or c.status == 'Disposal' and (c.module_key == 'ad' or getattr(c, 'sub_category', '') == 'ad')]

print("--- AD Cases that were Disposed under old logic ---")
for c in ad_cases_old_disposal:
    current_tab = "Disposal" if c.id in disposal_ids else ("Pending" if c.id in pending_ids else "Other")
    print(f"ID: {c.id}, module: {c.module_key}, extra: {c.extra_fields}, current_tab: {current_tab}")

print("\n--- The 2 specific cases ---")
for cid in ['1790416953330', '1790398503143']:
    try:
        c = CaseRecord.objects.get(id=cid)
        current_tab = "Disposal" if c.id in disposal_ids else ("Pending" if c.id in pending_ids else "Other")
        print(f"ID: {c.id}, module: {c.module_key}, status: {c.status}, current_tab: {current_tab}")
        print(f"extra_fields: {c.extra_fields}")
    except CaseRecord.DoesNotExist:
        print(f"Case {cid} not found.")
