from django.core.management.base import BaseCommand
from apps.cases.models import CaseRecord
from apps.cases.constants import DISPOSAL_KEYS
from apps.cases.utils import get_cases_by_status

class Command(BaseCommand):
    help = 'Backfill disposal_date for all disposed cases based on status_logs.'

    def handle(self, *args, **options):
        cases = get_cases_by_status('disposal')
        count = 0
        
        for case in cases:
            extra = case.extra_fields or {}
            
            # If disposal_date is already set, skip
            if 'disposal_date' in extra:
                continue
            
            # We want to find the first time any of the DISPOSAL_KEYS was entered
            # But if status_logs don't have it, we fallback to created_at or updated_at
            # Actually, standard logs capture 'cc_st_entered', but for the other 6 keys, we might not have a specific action string.
            # Let's fallback to the last updated_at as a best guess for old data without proper logs.
            best_date = str(case.updated_at)[:10] if case.updated_at else str(case.created_at)[:10]
            
            if 'status_logs' in extra:
                for log in extra['status_logs']:
                    # if the log tells us when it was disposed
                    if log.get('action') in ['cc_st_entered', 'status_changed'] and log.get('status') == 'Disposal':
                        best_date = log.get('timestamp', best_date)[:10]
                        break
                        
            extra['disposal_date'] = best_date
            case.extra_fields = extra
            case.save(update_fields=['extra_fields'])
            count += 1
            
        self.stdout.write(self.style.SUCCESS(f'Successfully backfilled disposal_date for {count} cases.'))
