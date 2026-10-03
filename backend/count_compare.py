import os
import django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from apps.cases.models import CaseRecord
from apps.cases.utils import get_cases_by_status

old_pending = CaseRecord.objects.filter(status='Pending').count()
old_disposal = CaseRecord.objects.filter(status='Disposal').count()
old_other = CaseRecord.objects.exclude(status__in=['Pending', 'Disposal']).count()

new_pending = get_cases_by_status('pending').count()
new_disposal = get_cases_by_status('disposal').count()

print(f"Old Pending: {old_pending}")
print(f"Old Disposal: {old_disposal}")
print(f"Old Other: {old_other}")
print(f"---")
print(f"New Pending: {new_pending}")
print(f"New Disposal: {new_disposal}")
print(f"Total Old Cases: {old_pending + old_disposal + old_other}")
print(f"Total New Partitioned: {new_pending + new_disposal}")
