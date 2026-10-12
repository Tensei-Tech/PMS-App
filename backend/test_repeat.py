import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.utils import get_cases_by_status
from apps.crimetab.models.common_form import CasesPerson
from django.db.models import Count

try:
    print("Testing get_cases_by_status...")
    qs = get_cases_by_status('repeat_offender')
    count = qs.count()
    print(f"Cases count: {count}")
    
    print("Testing _enrich_data logic...")
    repeat_names_qs = CasesPerson.objects.filter(role__in=['accused', 'suspected_accused']).exclude(name__isnull=True).exclude(name__exact='').values('name').annotate(case_count=Count('case_id', distinct=True)).filter(case_count__gt=1)
    repeat_names = set(repeat_names_qs.values_list('name', flat=True))
    print(f"Repeat names: {repeat_names}")
    
except Exception as e:
    import traceback
    traceback.print_exc()
