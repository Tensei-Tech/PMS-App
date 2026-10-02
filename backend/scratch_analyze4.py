import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord
from apps.cases.utils import get_cases_by_status

cases = get_cases_by_status('disposal')
fallback_count = 0

for case in cases:
    extra = case.extra_fields or {}
    ddate = extra.get('disposal_date')
    if ddate:
        best_date = str(case.updated_at)[:10] if case.updated_at else str(case.created_at)[:10]
        # Check if it was from a status log
        log_date = None
        if 'status_logs' in extra:
            for log in extra['status_logs']:
                if log.get('action') in ['cc_st_entered', 'status_changed'] and log.get('status') == 'Disposal':
                    log_date = log.get('timestamp')[:10]
                    break
        if not log_date and ddate == best_date:
            fallback_count += 1
            print(f"Case {case.id} used fallback: {best_date}")

print("FALLBACK COUNT:", fallback_count)
