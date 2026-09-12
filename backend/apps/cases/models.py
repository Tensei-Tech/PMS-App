import uuid
from django.db import models


AD_SUMMARY_NO_KEYS = [
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
    'AD Summary No.',
    'AD Summary No',
    'AD Summary Number',
    'AD Summary',
]

AD_SUMMARY_DATE_KEYS = [
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
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'cases_caserecord'
        verbose_name = 'Case Record'
        verbose_name_plural = 'Case Records'
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if is_ad_case_disposed(self) and self.status not in ['Disposal', 'Closed', 'Resolved']:
            self.status = 'Disposal'
        super().save(*args, **kwargs)

    def __str__(self):
        return f"[{self.module_key}] {self.case_number}: {self.title} ({self.station_name})"
