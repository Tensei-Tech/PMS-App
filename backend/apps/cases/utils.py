from django.db.models import Value, Q
from django.db.models.functions import Coalesce, Concat
from django.db.models.fields.json import KeyTextTransform
from django.db import models
from apps.cases.models import CaseRecord
from apps.cases.constants import DISPOSAL_KEYS

def get_cases_by_status(tab: str):
    """
    Partitions all CaseRecords strictly by the presence of any DISPOSAL_KEYS.
    """
    queryset = CaseRecord.objects.all()
    
    concat_args = []
    for key in DISPOSAL_KEYS:
        concat_args.append(Coalesce(KeyTextTransform(key, 'extra_fields'), Value(''), output_field=models.CharField()))
        concat_args.append(Value(' '))
        
    queryset = queryset.annotate(
        all_cc_st=Concat(*concat_args, output_field=models.CharField())
    )
    
    if tab == 'disposal':
        return queryset.filter(all_cc_st__regex=r'\S')
    elif tab == 'pending':
        return queryset.exclude(all_cc_st__regex=r'\S')
        
    return queryset
