from django.db.models import Value, Q
from django.db.models.functions import Coalesce, Concat
from django.db.models.fields.json import KeyTextTransform
from django.db import models
from apps.cases.models import CaseRecord
from apps.cases.constants import DISPOSAL_KEYS

def get_cases_by_status(tab: str):
    """
    Returns cases strictly based on their persisted status field.
    The CaseRecord.save() method handles updating this status based on extra_fields.
    """
    queryset = CaseRecord.objects.all()
    
    if tab.lower() == 'disposal':
        return queryset.filter(status__iexact='Disposal')
    elif tab.lower() == 'pending':
        # "Pending" includes anything that is not Disposal, Closed, or Resolved
        return queryset.filter(status__iexact='Pending')
    elif tab.lower() == 'detected':
        return queryset.filter(status__iexact='Detected')
    elif tab.lower() == 'arrested':
        return queryset.filter(
            Q(module_key__iexact='arrested') |
            Q(persons__arrest_status__arrest_datetime__isnull=False) |
            (Q(extra_fields__has_key='arrest_records') & ~Q(extra_fields__arrest_records=[]) & ~Q(extra_fields__arrest_records=None)) |
            (Q(extra_fields__has_key='arrest_datetime') & ~Q(extra_fields__arrest_datetime='') & ~Q(extra_fields__arrest_datetime=None)) |
            (Q(extra_fields__has_key='arrested_person_name') & ~Q(extra_fields__arrested_person_name='') & ~Q(extra_fields__arrested_person_name=None)) |
            (Q(extra_fields__has_key='arrests') & ~Q(extra_fields__arrests=[]) & ~Q(extra_fields__arrests=None))
        ).distinct()
    elif tab.lower() in ['repeat_offender', 'repeat offender']:
        from apps.crimetab.models.common_form import CasesPerson
        from django.db.models import Count
        repeat_names = CasesPerson.objects.filter(
            role__in=['accused', 'suspected_accused']
        ).exclude(
            name__isnull=True
        ).exclude(
            name__exact=''
        ).values('name').annotate(
            case_count=Count('case_id', distinct=True)
        ).filter(
            case_count__gt=1
        ).values_list('name', flat=True)
        
        return queryset.filter(
            persons__role__in=['accused', 'suspected_accused'],
            persons__name__in=repeat_names
        ).distinct()
        
    return queryset

