import logging
import re
import json
from typing import Any, List, Optional
from django.db.models import Q
from apps.cases.models import CaseRecord

logger = logging.getLogger(__name__)

# BNS sections mandated for ITSSO (Investigation Tracking System for Sexual Offences):
# - Section 64 BNS: Rape
# - Section 65 BNS: Rape of women under 16/12 etc.
# - Section 70(2) BNS: Gang rape of woman under 18 years
# - Section 62 BNS: Attempt to commit offences punishable with imprisonment for life/other imprisonment
ITSSO_BNS_SECTIONS = ['64', '65', '70(2)', '62']


def get_itsso_cases_q() -> Q:
    """
    Returns a comprehensive Django Q query for ITSSO cases:
    1. POCSO and ITSSO cases (by module_key or sub_category).
    2. Cases with BNS Sections 64, 65, 70(2), 62 in:
       - Relational charges (crime_case_acts_sections)
       - JSON extra_fields (acts_sections, charges, section_act, etc.)
       - Description and Title text fields.
    """
    # 1. Base POCSO & ITSSO module / category
    base_q = (
        Q(module_key__iexact='pocso') |
        Q(sub_category__iexact='pocso') |
        Q(sub_category__icontains='pocso') |
        Q(module_key__iexact='itsso') |
        Q(sub_category__iexact='itsso') |
        Q(sub_category__icontains='itsso')
    )

    # 2. Relational charges (crime_case_acts_sections via related name 'charges')
    bns_act_q = (
        Q(charges__act__act_name__icontains='bns') |
        Q(charges__act__act_name__icontains='nyaya') |
        Q(charges__act__act_name__icontains='bharatiya')
    )
    charges_q = (
        bns_act_q & (
            Q(charges__section__section_number__in=['64', '65', '62', '70(2)', '70 (2)']) |
            (
                Q(charges__section__section_number='70') &
                (
                    Q(charges__subsection__subsection_code__icontains='2') |
                    Q(charges__subsection__subsection_title__icontains='2')
                )
            )
        )
    )

    # 3. String tokens in extra_fields, description, or title
    sec_tokens = [
        # Section 64 BNS
        '64 BNS', '64-BNS', '64/BNS', 'BNS 64', 'BNS-64', 'BNS/64', '64 of BNS',
        '64(1) BNS', '64(2) BNS', '64(a) BNS', '64(b) BNS', '64 (1) BNS', '64 (2) BNS',
        '64 Bharatiya Nyaya', 'Bharatiya Nyaya Sanhita 64',
        # Section 65 BNS
        '65 BNS', '65-BNS', '65/BNS', 'BNS 65', 'BNS-65', 'BNS/65', '65 of BNS',
        '65(1) BNS', '65(2) BNS', '65 (1) BNS', '65 (2) BNS',
        '65 Bharatiya Nyaya', 'Bharatiya Nyaya Sanhita 65',
        # Section 70(2) BNS
        '70(2) BNS', '70 (2) BNS', '70(2)-BNS', '70(2)/BNS', 'BNS 70(2)', 'BNS 70 (2)', 'BNS-70(2)',
        '70(2) of BNS', '70 (2) of BNS', '70(2) Bharatiya Nyaya', 'Bharatiya Nyaya Sanhita 70(2)',
        '70 (2) Bharatiya Nyaya', 'Bharatiya Nyaya Sanhita 70 (2)',
        # Section 62 BNS
        '62 BNS', '62-BNS', '62/BNS', 'BNS 62', 'BNS-62', 'BNS/62', '62 of BNS',
        '62 Bharatiya Nyaya', 'Bharatiya Nyaya Sanhita 62',
    ]

    text_q = Q()
    for token in sec_tokens:
        text_q |= (
            Q(extra_fields__icontains=token) |
            Q(description__icontains=token) |
            Q(title__icontains=token)
        )

    # 4. JSON structure tokens in extra_fields (acts_sections / charges list)
    json_sec_tokens = [
        '"section": "64"', "'section': '64'", '"section_number": "64"', "'section_number': '64'",
        '"section": "65"', "'section': '65'", '"section_number": "65"', "'section_number': '65'",
        '"section": "62"', "'section': '62'", '"section_number": "62"', "'section_number': '62'",
        '"section": "70(2)"', "'section': '70(2)'", '"section_number": "70(2)"', "'section_number': '70(2)'",
        '"section": "70 (2)"', "'section': '70 (2)'", '"section_number": "70 (2)"', "'section_number': '70 (2)'",
    ]
    json_q = Q()
    for j_tok in json_sec_tokens:
        json_q |= Q(extra_fields__icontains=j_tok)

    # 70 with subsection 2 in JSON
    json_q |= (
        (Q(extra_fields__icontains='"section_number": "70"') | Q(extra_fields__icontains='"section": "70"')) &
        (Q(extra_fields__icontains='"subsection_code": "2"') | Q(extra_fields__icontains='"subsection": "2"') |
         Q(extra_fields__icontains='"subsection_code": "(2)"') | Q(extra_fields__icontains='"subsection": "(2)"'))
    )

    return base_q | charges_q | text_q | json_q


def is_itsso_case(case: Any) -> bool:
    """
    Evaluates whether a given case (CaseRecord or dict) qualifies for the ITSSO tab.
    Matches POCSO cases and cases registered under BNS 64, 65, 70(2), 62.
    """
    if not case:
        return False

    if isinstance(case, dict):
        mod = str(case.get('module_key') or case.get('moduleKey') or case.get('module') or '').strip().lower()
        sub = str(case.get('sub_category') or case.get('subCategory') or '').strip().lower()
        extra = case.get('extra_fields') or case.get('extraFields') or {}
        desc = str(case.get('description') or '')
        title = str(case.get('title') or '')
    else:
        mod = str(getattr(case, 'module_key', '')).strip().lower()
        sub = str(getattr(case, 'sub_category', '')).strip().lower()
        extra = getattr(case, 'extra_fields', {}) or {}
        desc = str(getattr(case, 'description', '') or '')
        title = str(getattr(case, 'title', '') or '')

    # 1. Base POCSO / ITSSO
    if mod in ['pocso', 'itsso'] or 'pocso' in sub or 'itsso' in sub:
        return True

    # 2. Relational charges if CaseRecord instance
    if hasattr(case, 'charges'):
        try:
            for ch in case.charges.select_related('act', 'section', 'subsection').all():
                act_name = (ch.act.act_name if ch.act else '').lower()
                is_bns = 'bns' in act_name or 'nyaya' in act_name or 'bharatiya' in act_name
                if not is_bns:
                    continue
                sec_num = str(ch.section.section_number if ch.section else '').strip().lower()
                subsec = str(ch.subsection.subsection_code if ch.subsection else '').strip().lower()
                if sec_num in ['64', '65', '62', '70(2)', '70 (2)']:
                    return True
                if sec_num == '70' and '2' in subsec:
                    return True
        except Exception:
            pass

    # 3. Extra fields acts_sections / charges list or dict
    if isinstance(extra, dict):
        charges_data = (
            extra.get('acts_sections') or
            extra.get('charges') or
            (extra.get('commonForm', {}).get('acts_sections') if isinstance(extra.get('commonForm'), dict) else None)
        )
        if isinstance(charges_data, list):
            for ch in charges_data:
                if isinstance(ch, dict):
                    act_name = str(ch.get('act_name') or ch.get('act') or '').lower()
                    is_bns = 'bns' in act_name or 'nyaya' in act_name or 'bharatiya' in act_name or not act_name
                    sec_num = str(ch.get('section_number') or ch.get('section') or ch.get('section_id') or '').strip().lower()
                    subsec = str(ch.get('subsection_code') or ch.get('subsection') or ch.get('subsection_id') or '').strip().lower()
                    if is_bns:
                        if sec_num in ['64', '65', '62', '70(2)', '70 (2)']:
                            return True
                        if sec_num == '70' and '2' in subsec:
                            return True
        elif isinstance(charges_data, dict):
            for ch in charges_data.values():
                if isinstance(ch, dict):
                    act_name = str(ch.get('act') or ch.get('act_name') or '').lower()
                    is_bns = 'bns' in act_name or 'nyaya' in act_name or 'bharatiya' in act_name or not act_name
                    secs = ch.get('sections', [])
                    if isinstance(secs, str):
                        secs = [secs]
                    if is_bns:
                        for s in secs:
                            s_str = str(s).strip().lower()
                            if s_str in ['64', '65', '62', '70(2)', '70 (2)']:
                                return True

    # 4. Text regex matching in title, description, and entire extra_fields string
    combined_text = f"{title} {desc} "
    if isinstance(extra, dict):
        try:
            combined_text += json.dumps(extra)
        except Exception:
            combined_text += str(extra)

    patterns = [
        # Section 64 BNS
        r'\b64\s*(?:\([^\)]*\)\s*)?(?:of\s+)?(?:the\s+)?bns\b',
        r'\bbns\s*(?:sec(?:tion)?\.?\s*)?64\b',
        r'64\s*bns',
        r'bns\s*64',
        r'64\s*bharatiya\s*nyaya',
        # Section 65 BNS
        r'\b65\s*(?:\([^\)]*\)\s*)?(?:of\s+)?(?:the\s+)?bns\b',
        r'\bbns\s*(?:sec(?:tion)?\.?\s*)?65\b',
        r'65\s*bns',
        r'bns\s*65',
        r'65\s*bharatiya\s*nyaya',
        # Section 70(2) BNS
        r'\b70\s*\(\s*2\s*\)\s*(?:of\s+)?(?:the\s+)?bns\b',
        r'\bbns\s*(?:sec(?:tion)?\.?\s*)?70\s*\(\s*2\s*\)',
        r'70\s*\(\s*2\s*\)\s*bns',
        r'bns\s*70\s*\(\s*2\s*\)',
        r'70\s*\(\s*2\s*\)\s*bharatiya\s*nyaya',
        # Section 62 BNS
        r'\b62\s*(?:\([^\)]*\)\s*)?(?:of\s+)?(?:the\s+)?bns\b',
        r'\bbns\s*(?:sec(?:tion)?\.?\s*)?62\b',
        r'62\s*bns',
        r'bns\s*62',
        r'62\s*bharatiya\s*nyaya',
    ]

    for p in patterns:
        if re.search(p, combined_text, re.IGNORECASE):
            return True

    return False


class ItssoService:
    """
    Dedicated Service for ITSSO (Investigation Tracking System for Sexual Offences).
    """

    @classmethod
    def get_itsso_cases_queryset(cls, base_queryset=None):
        """
        Returns a distinct queryset of CaseRecord instances matching ITSSO criteria.
        """
        qs = base_queryset if base_queryset is not None else CaseRecord.objects.all()
        return qs.filter(get_itsso_cases_q()).distinct()
