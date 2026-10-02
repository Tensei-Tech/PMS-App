from django.db.models import Value, Q
from django.db.models.functions import Coalesce, Concat
from django.db.models.fields.json import KeyTextTransform
from django.db import models
from apps.cases.models import CaseRecord
from apps.cases.constants import DISPOSAL_KEYS

def get_cases_by_status(tab: str):
    """
    Partitions all CaseRecords strictly by the presence of FinalVerdict values.
    Rule: A case is Disposal if ANY of these is entered:
    cc_st_number, charge_sheet_no, a_final_number, b_final_number,
    c_final_number, nc_final_number, abeted_summary_no.
    Otherwise it is Pending.
    """
    queryset = CaseRecord.objects.all()

    # The FinalVerdict fields that make a case 'Disposal'
    disposal_fields = [
        'final_verdict__cc_st_number',
        'final_verdict__charge_sheet_no',
        'final_verdict__a_final_number',
        'final_verdict__b_final_number',
        'final_verdict__c_final_number',
        'final_verdict__nc_final_number',
        'final_verdict__abeted_summary_no',
    ]

    disposal_q = Q()
    for field in disposal_fields:
        disposal_q |= Q(**{f"{field}__regex": r'\S'})

    if tab == 'disposal':
        return queryset.filter(disposal_q)
    elif tab == 'pending':
        return queryset.exclude(disposal_q)
    return queryset
