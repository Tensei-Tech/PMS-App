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
        from apps.cases.models import AD_SUMMARY_NO_KEYS, AD_SUMMARY_DATE_KEYS
        # AD cases that have BOTH AD Summary No and Date
        ad_no_args = []
        for key in AD_SUMMARY_NO_KEYS:
            ad_no_args.append(Coalesce(KeyTextTransform(key, 'extra_fields'), Value(''), output_field=models.CharField()))
            ad_no_args.append(Value(' '))
            
        ad_date_args = []
        for key in AD_SUMMARY_DATE_KEYS:
            ad_date_args.append(Coalesce(KeyTextTransform(key, 'extra_fields'), Value(''), output_field=models.CharField()))
            ad_date_args.append(Value(' '))

        queryset = queryset.annotate(
            ad_no=Concat(*ad_no_args, output_field=models.CharField()),
            ad_dt=Concat(*ad_date_args, output_field=models.CharField())
        )
        
        ad_condition = (
            (Q(module_key__iexact='ad') | Q(sub_category__iexact='ad') | Q(sub_category__iexact='accidental death'))
            & Q(ad_no__regex=r'\S')
            & Q(ad_dt__regex=r'\S')
        )
        
        return queryset.filter(
            Q(all_cc_st__regex=r'\S') | ad_condition
        )
    elif tab == 'pending':
        from apps.cases.models import AD_SUMMARY_NO_KEYS, AD_SUMMARY_DATE_KEYS
        ad_no_args = []
        for key in AD_SUMMARY_NO_KEYS:
            ad_no_args.append(Coalesce(KeyTextTransform(key, 'extra_fields'), Value(''), output_field=models.CharField()))
            ad_no_args.append(Value(' '))
            
        ad_date_args = []
        for key in AD_SUMMARY_DATE_KEYS:
            ad_date_args.append(Coalesce(KeyTextTransform(key, 'extra_fields'), Value(''), output_field=models.CharField()))
            ad_date_args.append(Value(' '))

        queryset = queryset.annotate(
            ad_no=Concat(*ad_no_args, output_field=models.CharField()),
            ad_dt=Concat(*ad_date_args, output_field=models.CharField())
        )
        
        ad_condition = (
            (Q(module_key__iexact='ad') | Q(sub_category__iexact='ad') | Q(sub_category__iexact='accidental death'))
            & Q(ad_no__regex=r'\S')
            & Q(ad_dt__regex=r'\S')
        )
        
        return queryset.exclude(
            Q(all_cc_st__regex=r'\S') | ad_condition
        )
        
    return queryset
