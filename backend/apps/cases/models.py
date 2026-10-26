import uuid
from django.db import models


AD_SUMMARY_NO_KEYS = [
    'ad_summary_sent',
    'adSummarySent',
    'ad_summary_sent_no',
    'adSummarySentNo',
    'adSummaryNo',
    'ad_summary_no',
    'adSummaryNum',
    'ad_summary_num',
    'adSummaryNumber',
    'ad_summary_number',
    'adSummary',
    'ad_summary',
    'summaryNo',
    'summary_no',
    'summaryNum',
    'summary_num',
    'summaryNumber',
    'summary_number',
    'margSummaryNo',
    'marg_summary_no',
    'margSummaryNum',
    'marg_summary_num',
    'margSummaryNumber',
    'marg_summary_number',
    'margSummary',
    'marg_summary',
    'marSummaryNo',
    'mar_summary_no',
    'marSummaryNum',
    'mar_summary_num',
    'adMargSummaryNo',
    'ad_marg_summary_no',
    'मर्ग समरी No.',
    'मर्ग समरी No',
    'मर्ग समरी नं.',
    'मर्ग समरी नं',
    'मर्ग समरी क्रमांक',
    'मर्ग समरी क्र.',
    'मर्ग समरी क्र',
    'मर्ग समरी',
    'मर्ग समरी पाठविली क्र.',
    'मर्ग समरी पाठविली क्र',
    'मर्ग समरी पाठविली नं.',
    'मर्ग समरी पाठविली नं',
    'मर्ग समरी पाठविली',
    'मर्ग समरी पाठविल्याचा क्र.',
    'मर्ग समरी पाठविल्याचा क्र',
    'मर्ग समरी पाठविल्याचा क्रमांक',
    'AD Summary No.',
    'AD Summary No',
    'AD Summary Number',
    'AD Summary',
]

AD_SUMMARY_DATE_KEYS = [
    'ad_summary_sent_date',
    'adSummarySentDate',
    'ad_summary_sent_dt',
    'adSummarySentDt',
    'adSummaryDate',
    'ad_summary_date',
    'adSummaryDt',
    'ad_summary_dt',
    'summaryDate',
    'summary_date',
    'summaryDt',
    'summary_dt',
    'margSummaryDate',
    'marg_summary_date',
    'margSummaryDt',
    'marg_summary_dt',
    'marSummaryDate',
    'mar_summary_date',
    'adMargSummaryDate',
    'ad_marg_summary_date',
    'मर्ग समरी दिनांक',
    'मर्ग समरी तारीख',
    'मर्ग समरी Date',
    'मर्ग समरी Dt',
    'मर्ग समरी पाठविली दिनांक',
    'मर्ग समरी पाठविली तारीख',
    'मर्ग समरी पाठविल्याचा दिनांक',
    'मर्ग समरी पाठविल्याची तारीख',
    'AD Summary Date',
    'AD Summary Dt',
]


def _extract_first_non_empty(data, candidate_keys):
    if not isinstance(data, dict):
        return ''
    # 1. Exact match
    for k in candidate_keys:
        if k in data and data[k] is not None:
            val = str(data[k]).strip()
            if val:
                return val

    # 2. Case & whitespace normalized match
    norm_cands = {c.lower().replace(' ', '').replace('_', '').replace('-', '').replace('.', ''): c for c in candidate_keys}
    for k, v in data.items():
        if v is not None:
            k_norm = str(k).lower().replace(' ', '').replace('_', '').replace('-', '').replace('.', '')
            if k_norm in norm_cands:
                val = str(v).strip()
                if val:
                    return val

    # 3. Recursive search in sub-dictionaries
    for v in data.values():
        if isinstance(v, dict):
            res = _extract_first_non_empty(v, candidate_keys)
            if res:
                return res
    return ''


def is_ad_case_disposed(case) -> bool:
    """
    Checks if an AD case is disposed:
    Returns True if module is 'ad' and BOTH AD Summary No and AD Summary Date are non-empty.
    """
    if isinstance(case, dict):
        mod = str(case.get('module_key') or case.get('moduleKey') or case.get('module') or '').strip().lower()
        sub = str(case.get('sub_category') or case.get('subCategory') or '').strip().lower()
        if mod != 'ad' and sub not in ['ad', 'accidental death']:
            return False
        extra = case.get('extra_fields') or case.get('extraFields') or {}
        num = _extract_first_non_empty(extra, AD_SUMMARY_NO_KEYS) or _extract_first_non_empty(case, AD_SUMMARY_NO_KEYS)
        dt = _extract_first_non_empty(extra, AD_SUMMARY_DATE_KEYS) or _extract_first_non_empty(case, AD_SUMMARY_DATE_KEYS)
        return bool(num and dt)

    mod = str(getattr(case, 'module_key', '')).strip().lower()
    sub = str(getattr(case, 'sub_category', '')).strip().lower()
    if mod != 'ad' and sub not in ['ad', 'accidental death']:
        return False

    extra = getattr(case, 'extra_fields', {}) or {}
    num = _extract_first_non_empty(extra, AD_SUMMARY_NO_KEYS)
    dt = _extract_first_non_empty(extra, AD_SUMMARY_DATE_KEYS)
    return bool(num and dt)


PREVENTIVE_NO_KEYS = [
    'preventiveNumber', 'preventive_number', 'preventiveNo', 'preventive_no',
    'istegasha_no', 'istegashaNo', 'istegasha_number', 'istegashaNumber',
    'istegasha',
    'इस्तेगाशा नंबर', 'इस्तेगाशा नं.', 'इस्तेगाशा नं', 'इस्तेगाशा क्र.', 'इस्तेगाशा क्र',
    'इस्तेगाशा क्रमांक', 'प्रतिबंधक कारवाई क्र.', 'प्रतिबंधक कारवाई क्र',
    'प्रतिबंधक क्र.', 'प्रतिबंधक क्र', 'प्रतिबंधक क्रमांक', 'chapter_case_no', 'chapterCaseNo',
    'preventiveActionNo', 'preventive_action_no',
]

PREVENTIVE_DATE_KEYS = [
    'preventiveDate', 'preventive_date', 'istegashaDate', 'istegasha_date',
    'actionDate', 'action_date', 'date', 'दिनांक', 'तारीख',
    'कारवाई दिनांक', 'इस्तेगाशा दिनांक', 'प्रतिबंधक कारवाई दिनांक',
]


def is_preventive_case_disposed(case) -> bool:
    """
    Checks if a Preventive case is disposed:
    Returns True if module is 'preventive' (or sub_category is 'preventive')
    and BOTH Preventive Number (इस्तेगाशा नंबर) and Date are non-empty.
    """
    if not case:
        return False
    if isinstance(case, dict):
        mod = str(case.get('module_key') or case.get('moduleKey') or case.get('module') or '').strip().lower()
        sub = str(case.get('sub_category') or case.get('subCategory') or '').strip().lower()
        is_prev = (mod in ['preventive', 'preventive_action', 'preventive_actions', 'chapter_case'] or
                   sub in ['preventive', 'preventive_action', 'chapter case', 'chapter_case', 'प्रतिबंधक कारवाई', 'प्रतिबंधक'])
        if not is_prev:
            return False
        extra = case.get('extra_fields') or case.get('extraFields') or {}
        num = _extract_first_non_empty(extra, PREVENTIVE_NO_KEYS) or _extract_first_non_empty(case, PREVENTIVE_NO_KEYS)
        dt = _extract_first_non_empty(extra, PREVENTIVE_DATE_KEYS) or _extract_first_non_empty(case, PREVENTIVE_DATE_KEYS)
        return bool(num and dt)

    mod = str(getattr(case, 'module_key', '')).strip().lower()
    sub = str(getattr(case, 'sub_category', '')).strip().lower()
    is_prev = (mod in ['preventive', 'preventive_action', 'preventive_actions', 'chapter_case'] or
               sub in ['preventive', 'preventive_action', 'chapter case', 'chapter_case', 'प्रतिबंधक कारवाई', 'प्रतिबंधक'])
    if not is_prev:
        return False

    extra = getattr(case, 'extra_fields', {}) or {}
    num = _extract_first_non_empty(extra, PREVENTIVE_NO_KEYS)
    dt = _extract_first_non_empty(extra, PREVENTIVE_DATE_KEYS)
    return bool(num and dt)


NC_PREVENTIVE_NO_KEYS = [
    'preventiveNumber', 'preventive_number', 'preventiveNo', 'preventive_no',
    'istegasha_no', 'istegashaNo', 'istegasha_number', 'इस्तेगाशा नंबर', 'इस्तेगाशा क्र'
]
NC_OUTWARD_NO_KEYS = [
    'outwardNumber', 'outward_number', 'preventiveOutwardNumber', 'preventive_outward_no',
    'preventiveOutwardNo', 'outward_no', 'जावक क्र', 'जावक नंबर'
]
NC_PREVENTIVE_DATE_KEYS = [
    'preventiveDate', 'preventive_date', 'outwardDate', 'outward_date',
    'date', 'दिनांक', 'तारीख'
]
NC_NO_PREVENTIVE_REASON_KEYS = [
    'noPreventiveReason', 'no_preventive_reason', 'preventiveNotDoneReason',
    'preventive_not_done_reason', 'reason_for_no_preventive', 'preventive_reason',
    'no_action_reason'
]


def is_nc_case_disposed(case) -> bool:
    """
    Checks if an NC (Non-Cognizable) case is disposed:
    Returns True if:
    1. Preventive Action is taken with Section & Act, Preventive/Istegasha No, Outward No, and Date filled.
       OR
    2. Preventive Action is NOT done, but a valid reason is provided:
       1 - Family matter
       2 - Other
    """
    if not case:
        return False

    if isinstance(case, dict):
        mod = str(case.get('module_key') or case.get('moduleKey') or case.get('module') or '').strip().lower()
        sub = str(case.get('sub_category') or case.get('subCategory') or '').strip().lower()
        extra = case.get('extra_fields') or case.get('extraFields') or {}
    else:
        mod = str(getattr(case, 'module_key', '')).strip().lower()
        sub = str(getattr(case, 'sub_category', '')).strip().lower()
        extra = getattr(case, 'extra_fields', {}) or {}

    if not isinstance(extra, dict):
        extra = {}

    is_nc = (mod in ['nc', 'nc_register', 'nc_form'] or sub in ['nc', 'non-cognizable', 'non cognizable', 'nc register'])
    if not is_nc:
        return False

    all_dicts = [extra]
    if isinstance(extra.get('preventiveDetails'), dict):
        all_dicts.append(extra['preventiveDetails'])
    if isinstance(extra.get('preventive_details'), dict):
        all_dicts.append(extra['preventive_details'])
    if isinstance(case, dict) and isinstance(case.get('preventiveDetails'), dict):
        all_dicts.append(case['preventiveDetails'])

    # 1. Condition: Preventive action done
    has_prev_no = any(_extract_first_non_empty(d, NC_PREVENTIVE_NO_KEYS) for d in all_dicts)
    has_outward_no = any(_extract_first_non_empty(d, NC_OUTWARD_NO_KEYS) for d in all_dicts)
    has_date = any(_extract_first_non_empty(d, NC_PREVENTIVE_DATE_KEYS) for d in all_dicts)

    has_charges = False
    for d in all_dicts:
        pch = d.get('preventiveCharges') or d.get('preventive_charges') or d.get('charges')
        if isinstance(pch, dict) and pch:
            has_charges = any(isinstance(v, dict) and (v.get('act') or v.get('sections')) for v in pch.values())
            if has_charges:
                break
        elif isinstance(pch, list) and pch:
            has_charges = True
            break
        elif d.get('preventive_action') or d.get('action_type') or d.get('preventive_section'):
            has_charges = True
            break

    if has_prev_no and has_outward_no and has_date and has_charges:
        return True

    # 2. Condition: If preventive action not done, reason must be provided (family matter / other)
    for d in all_dicts:
        reason = _extract_first_non_empty(d, NC_NO_PREVENTIVE_REASON_KEYS)
        if reason:
            return True

    prev_done = str(extra.get('preventiveActionDone') or extra.get('preventive_action_done') or '').strip().lower()
    if prev_done in ['no', 'false', 'nahi']:
        for d in all_dicts:
            reason = _extract_first_non_empty(d, NC_NO_PREVENTIVE_REASON_KEYS) or d.get('reason')
            if reason and str(reason).strip():
                return True

    return False


COURT_FILING_DISPOSAL_KEYS = [
    'a_final_number', 'aFinalNumber', 'a_final_no', 'aFinalNo',
    'b_final_number', 'bFinalNumber', 'b_final_no', 'bFinalNo',
    'c_final_number', 'cFinalNumber', 'c_final_no', 'cFinalNo',
    'nc_final_number', 'ncFinalNumber', 'nc_final_no', 'ncFinalNo',
    'abeted_summary_no', 'abetedSummaryNo', 'abeted_summary_number', 'abated_summary_no', 'abatedSummaryNo',
    'cc_st_number', 'ccStNumber', 'cc_st_no', 'ccStNo',
    'stay_by_high_court_date', 'stayByHighCourtDate', 'stay_by_high_court', 'stayHighCourtDate',
    'quashed_by_high_court_date', 'quashedByHighCourtDate', 'quashed_by_high_court', 'quashedHighCourtDate',
]


def is_case_disposed_by_court_filing(case) -> bool:
    """
    Checks if ANY of the 8 Court Filing & Final Summary fields is filled (non-empty):
    1. A Final Number
    2. B Final Number
    3. C Final Number
    4. NC Final Number
    5. Abeted Summary No.
    6. CC/ST Number
    7. Stay by High Court Date
    8. Quashed by High Court Date
    If any of these fields is filled, status automatically becomes 'Disposal'.
    Note: AD cases are handled separately by is_ad_case_disposed.
    """
    if not case:
        return False

    if isinstance(case, dict):
        mod = str(case.get('module_key') or case.get('moduleKey') or case.get('module') or '').strip().lower()
        sub = str(case.get('sub_category') or case.get('subCategory') or '').strip().lower()
        if mod == 'ad' or sub in ['ad', 'accidental death']:
            return False
    else:
        mod = str(getattr(case, 'module_key', '')).strip().lower()
        sub = str(getattr(case, 'sub_category', '')).strip().lower()
        if mod == 'ad' or sub in ['ad', 'accidental death']:
            return False

    def _check_dict(d: dict) -> bool:
        if not isinstance(d, dict):
            return False
        for k in COURT_FILING_DISPOSAL_KEYS:
            v = d.get(k)
            if v is not None and str(v).strip():
                return True
        for sub_k in ['final_verdict', 'finalVerdict', 'court', 'court_filing', 'courtFiling', 'commonForm', 'common_form']:
            sub = d.get(sub_k)
            if isinstance(sub, dict) and _check_dict(sub):
                return True
        return False

    if isinstance(case, dict):
        extra = case.get('extra_fields') or case.get('extraFields') or {}
        return _check_dict(case) or _check_dict(extra)

    extra = getattr(case, 'extra_fields', {}) or {}
    if _check_dict(extra):
        return True

    # Check related final_verdict if present or in DB
    try:
        fv = getattr(case, 'final_verdict', None)
        if not fv and hasattr(case, 'pk') and case.pk:
            from apps.crimetab.models.common_form import FinalVerdict
            fv = FinalVerdict.objects.filter(case=case).first()
        if fv:
            for attr in [
                'a_final_number', 'b_final_number', 'c_final_number', 'nc_final_number',
                'abeted_summary_no', 'cc_st_number', 'stay_by_high_court_date', 'quashed_by_high_court_date'
            ]:
                val = getattr(fv, attr, None)
                if val is not None and str(val).strip():
                    return True
    except Exception:
        pass

    return False


class CaseRecord(models.Model):
    """
    Case Record model matching Flutter ModuleRecord for PostgreSQL storage.
    Supports extra_fields (JSONB) for flexible per-module dynamic attributes.
    """
    PRIORITY_CHOICES = (
        ('Low', 'Low'),
        ('Medium', 'Medium'),
        ('High', 'High'),
        ('Critical', 'Critical'),
    )

    STATUS_CHOICES = (
        ('Pending', 'Pending'),
        ('Detected', 'Detected'),
        ('Disposal', 'Disposal'),
        ('Closed', 'Closed'),
        ('Open', 'Open'),
    )

    id = models.CharField(max_length=128, primary_key=True, default=uuid.uuid4)
    module_key = models.CharField(max_length=64, db_index=True)
    title = models.CharField(max_length=255)
    case_number = models.CharField(max_length=128, db_index=True)
    description = models.TextField(blank=True)
    complainant = models.CharField(max_length=255, blank=True)
    accused = models.CharField(max_length=255, blank=True)
    location = models.CharField(max_length=255, blank=True)
    incident_date = models.DateTimeField(null=True, blank=True)
    priority = models.CharField(max_length=32, choices=PRIORITY_CHOICES, default='Low')
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='Pending', db_index=True)
    assigned_officer = models.CharField(max_length=255, blank=True)
    assigned_officer_uid = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    sub_category = models.CharField(max_length=128, blank=True, null=True)
    created_by = models.CharField(max_length=128, blank=True)
    station_name = models.CharField(max_length=255, db_index=True)
    extra_fields = models.JSONField(default=dict, blank=True)
    disposal_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'cases_caserecord'
        verbose_name = 'Case Record'
        verbose_name_plural = 'Case Records'
        ordering = ['-created_at', '-id']

    def save(self, *args, **kwargs):
        # 1. Reject client status overrides (handled before save if we want, but enforced here)
        # Actually, if we just want to compute it:
        from apps.cases.constants import CC_ST_KEYS, DISPOSAL_KEYS
        from django.utils import timezone
        
        has_disposal_key = False
        
        # Original AD Logic
        if is_ad_case_disposed(self):
            has_disposal_key = True
            if self.status not in ['Disposal', 'Closed', 'Resolved']:
                self.status = 'Disposal'
            if isinstance(self.extra_fields, dict):
                ad_dt = _extract_first_non_empty(self.extra_fields, AD_SUMMARY_DATE_KEYS)
                if ad_dt and not self.extra_fields.get('disposal_date'):
                    self.extra_fields['disposal_date'] = ad_dt

        # Preventive Disposal Logic
        elif is_preventive_case_disposed(self):
            has_disposal_key = True
            if self.status not in ['Disposal', 'Closed', 'Resolved']:
                self.status = 'Disposal'
            if isinstance(self.extra_fields, dict):
                p_dt = _extract_first_non_empty(self.extra_fields, PREVENTIVE_DATE_KEYS)
                if p_dt and not self.extra_fields.get('disposal_date'):
                    self.extra_fields['disposal_date'] = p_dt

        # NC Disposal Logic
        elif is_nc_case_disposed(self):
            has_disposal_key = True
            if self.status not in ['Disposal', 'Closed', 'Resolved']:
                self.status = 'Disposal'
            if isinstance(self.extra_fields, dict):
                nc_dt = _extract_first_non_empty(self.extra_fields, NC_PREVENTIVE_DATE_KEYS)
                if nc_dt and not self.extra_fields.get('disposal_date'):
                    self.extra_fields['disposal_date'] = nc_dt
            
        # CC/ST / Court Filing Logic (Skip AD, Preventive, and NC cases)
        elif self.module_key not in ['ad', 'preventive', 'nc']:
            # Check if CC/ST or Court Filing fields are present in extra_fields
            has_cc = False
            if isinstance(self.extra_fields, dict):
                has_cc = bool(_extract_first_non_empty(self.extra_fields, DISPOSAL_KEYS))
            has_disposal_key = has_cc
            
        if self.pk:
            try:
                old_instance = CaseRecord.objects.get(pk=self.pk)
                old_extra = old_instance.extra_fields if isinstance(old_instance.extra_fields, dict) else {}
                
                if isinstance(self.extra_fields, dict):
                    # ALWAYS preserve the old disposal_date if it's missing from the incoming payload
                    if 'disposal_date' not in self.extra_fields and 'disposal_date' in old_extra:
                        self.extra_fields['disposal_date'] = old_extra['disposal_date']
                        
                    # If it's a disposal case now and STILL doesn't have a disposal_date, set it
                    if has_disposal_key and not self.extra_fields.get('disposal_date'):
                        self.extra_fields['disposal_date'] = timezone.localtime(timezone.now()).strftime('%Y-%m-%d')
            except CaseRecord.DoesNotExist:
                # It's a new instance despite having a PK (because of uuid4 default)
                if has_disposal_key:
                    if isinstance(self.extra_fields, dict) and not self.extra_fields.get('disposal_date'):
                        self.extra_fields['disposal_date'] = timezone.localtime(timezone.now()).strftime('%Y-%m-%d')
        else:
            if has_disposal_key:
                if isinstance(self.extra_fields, dict) and not self.extra_fields.get('disposal_date'):
                    self.extra_fields['disposal_date'] = timezone.localtime(timezone.now()).strftime('%Y-%m-%d')
                    
        # Update the status based on disposal key presence
        from apps.cases.constants import CASE_STATUS_DISPOSAL, CASE_STATUS_PENDING, CASE_STATUS_DETECTED
        # Service modules (e.g. passport, licence, application) manage their own verification statuses
        # and do not use criminal detection / disposal status logic.
        if getattr(self, 'module_key', '') in ['passport', 'licence', 'application']:
            super().save(*args, **kwargs)
            return

        sub_cat = str(getattr(self, 'sub_category', '') or '').lower().strip()
        mod_key = str(getattr(self, 'module_key', '') or '').lower().strip()
        is_ad = mod_key == 'ad' or sub_cat in ['ad', 'accidental death']
        is_preventive = (mod_key in ['preventive', 'preventive_action', 'preventive_actions', 'chapter_case'] or
                         sub_cat in ['preventive', 'preventive_action', 'chapter case', 'chapter_case', 'प्रतिबंधक कारवाई', 'प्रतिबंधक'])
        is_nc = mod_key in ['nc', 'nc_register', 'nc_form'] or sub_cat in ['nc', 'non-cognizable', 'non cognizable', 'nc register']
        is_missing = mod_key == 'missing' or sub_cat == 'missing'
        
        # Helper to determine if case has a valid identified accused
        def _has_valid_accused_name(val):
            if not val:
                return False
            if isinstance(val, str):
                s = val.strip().lower()
                return bool(s and s not in ['unknown', 'अज्ञात', 'unidentified', 'none', 'null', 'na', 'n/a', 'default accused', 'passport verification'])
            if isinstance(val, dict):
                return _has_valid_accused_name(val.get('name') or val.get('accused_name'))
            if isinstance(val, list):
                return any(_has_valid_accused_name(x) for x in val)
            return False

        is_detected = False
        if not is_ad and not is_preventive and not is_nc and not is_missing:
            # Check standard accused field
            if _has_valid_accused_name(self.accused):
                is_detected = True
            # Check extra_fields for accused
            elif isinstance(self.extra_fields, dict):
                for accused_key in ['accused', 'AccusedName', 'accused_name', 'accusedName', 'accused_list']:
                    val = self.extra_fields.get(accused_key)
                    if _has_valid_accused_name(val):
                        is_detected = True
                        break

        if is_ad:
            if is_ad_case_disposed(self):
                self.status = CASE_STATUS_DISPOSAL
            elif self.status == CASE_STATUS_DISPOSAL:
                self.status = CASE_STATUS_PENDING
        elif is_preventive:
            if is_preventive_case_disposed(self):
                self.status = CASE_STATUS_DISPOSAL
                if isinstance(self.extra_fields, dict):
                    p_dt = _extract_first_non_empty(self.extra_fields, PREVENTIVE_DATE_KEYS)
                    if p_dt and not self.extra_fields.get('disposal_date'):
                        self.extra_fields['disposal_date'] = p_dt
            elif self.status == CASE_STATUS_DISPOSAL:
                self.status = CASE_STATUS_PENDING
        elif is_nc:
            if is_nc_case_disposed(self):
                self.status = CASE_STATUS_DISPOSAL
            elif self.status == CASE_STATUS_DISPOSAL:
                self.status = CASE_STATUS_PENDING
        elif is_missing:
            if has_disposal_key:
                self.status = CASE_STATUS_DISPOSAL
            elif self.status in [CASE_STATUS_DETECTED, '']:
                self.status = CASE_STATUS_PENDING
        else:
            if has_disposal_key:
                self.status = CASE_STATUS_DISPOSAL
            else:
                self.status = CASE_STATUS_DETECTED if is_detected else CASE_STATUS_PENDING

        super().save(*args, **kwargs)

    def __str__(self):
        return f"[{self.module_key}] {self.case_number}: {self.title} ({self.station_name})"
