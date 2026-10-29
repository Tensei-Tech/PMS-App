import calendar
import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple, Any

from django.db.models import Q
from django.db.models.functions import Coalesce

from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategory

logger = logging.getLogger(__name__)




def format_inc_dec(current_val: int, previous_val: int) -> Dict[str, Any]:
    """
    Computes INC/DEC difference and formats for police reports:
    - Positive difference: '+N'
    - Negative difference: '-N'
    - Zero difference: '='
    """
    diff = int(current_val) - int(previous_val)
    if diff > 0:
        formatted = f"+{diff}"
    elif diff < 0:
        formatted = f"{diff}"
    else:
        formatted = "="
    return {
        'value': diff,
        'text': formatted,
    }


def get_comparative_date_ranges(
    year: int,
    month: int,
    cutoff_day: Optional[int] = None
) -> Dict[str, Dict[str, Any]]:
    """
    Computes the 5 police comparative reporting time windows:
    1. Current Month (CM)
    2. Previous Month (PM)
    3. Same Month Previous Year (SMLY)
    4. Current Year to Date (CY_YTD)
    5. Previous Year to Date (PY_YTD)
    """
    month_max_day = calendar.monthrange(year, month)[1]
    day = min(cutoff_day, month_max_day) if cutoff_day else month_max_day

    # 1. Current Month (CM)
    cm_start = datetime(year, month, 1, 0, 0, 0, tzinfo=timezone.utc)
    cm_end = datetime(year, month, day, 23, 59, 59, 999999, tzinfo=timezone.utc)
    cm_label = f"{calendar.month_name[month].upper()} {year}"

    # 2. Previous Month (PM)
    if month == 1:
        pm_year = year - 1
        pm_month = 12
    else:
        pm_year = year
        pm_month = month - 1
    pm_max_day = calendar.monthrange(pm_year, pm_month)[1]
    pm_start = datetime(pm_year, pm_month, 1, 0, 0, 0, tzinfo=timezone.utc)
    pm_end = datetime(pm_year, pm_month, pm_max_day, 23, 59, 59, 999999, tzinfo=timezone.utc)
    pm_label = f"{calendar.month_name[pm_month].upper()} {pm_year}"

    # 3. Same Month Previous Year (SMLY)
    smly_year = year - 1
    smly_month = month
    smly_max_day = calendar.monthrange(smly_year, smly_month)[1]
    smly_day = min(day, smly_max_day)
    smly_start = datetime(smly_year, smly_month, 1, 0, 0, 0, tzinfo=timezone.utc)
    smly_end = datetime(smly_year, smly_month, smly_day, 23, 59, 59, 999999, tzinfo=timezone.utc)
    smly_label = f"{calendar.month_name[smly_month].upper()} {smly_year}"

    # 4. Current Year to Date (CY_YTD)
    cy_start = datetime(year, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
    cy_end = cm_end
    cy_label = f"01/01/{year} to {day:02d}/{month:02d}/{year}"

    # 5. Previous Year to Date (PY_YTD)
    py_start = datetime(smly_year, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
    py_end = smly_end
    py_label = f"01/01/{smly_year} to {smly_day:02d}/{smly_month:02d}/{smly_year}"

    return {
        'current_month': {
            'start': cm_start,
            'end': cm_end,
            'label': cm_label,
            'year': year,
            'month': month,
        },
        'previous_month': {
            'start': pm_start,
            'end': pm_end,
            'label': pm_label,
            'year': pm_year,
            'month': pm_month,
        },
        'same_month_previous_year': {
            'start': smly_start,
            'end': smly_end,
            'label': smly_label,
            'year': smly_year,
            'month': smly_month,
        },
        'current_year_ytd': {
            'start': cy_start,
            'end': cy_end,
            'label': cy_label,
            'year': year,
        },
        'previous_year_ytd': {
            'start': py_start,
            'end': py_end,
            'label': py_label,
            'year': smly_year,
        },
    }


def classify_case_record(case: CaseRecord) -> Tuple[str, str]:
    """
    Maps a CaseRecord instance to its crime group ('IPC' or 'SLL') and standard crime head.
    Utilizes:
    1. CaseCategoryLink relations (database dynamic hierarchy)
    2. sub_category
    3. module_key
    4. title heuristics
    """
    # 1. Check direct database Category Links
    try:
        links = case.category_links.select_related('category__group').all()
        for link in links:
            cat = link.category
            if not cat:
                continue
            group_code = (cat.group.group_code if cat.group else '') or ''
            group_name = (cat.group.group_name if cat.group else '') or ''
            cat_name = (cat.category_name or '').strip().upper()

            is_sll = (
                (cat.group and cat.group.group_id == 2) or
                'VI' in group_code.upper() or
                '6' in group_name
            )
            target_group = 'SLL' if is_sll else 'IPC'

            # Normalize to standard head if possible
            head = _normalize_head_name(cat_name, target_group)
            return (target_group, head)
    except Exception as e:
        logger.debug(f"Error checking category links: {e}")

    # 2. Sub-category & Module heuristics
    sub = (case.sub_category or '').strip().lower()
    mod = (case.module_key or '').strip().lower()
    title = (case.title or '').strip().lower()

    # Special and Local Laws (SLL / Class VI)
    if 'st drugs' in sub or 'st_drugs' in mod:
        return ('SLL', 'ST DRUGS')
    if 'prohibit' in sub or 'prohibit' in mod or 'mpda' in mod:
        return ('SLL', 'PROHIBITION')
    if 'gambl' in sub or 'gambl' in mod:
        return ('SLL', 'GAMBLING')
    if 'pocso' in sub or 'pocso' in mod:
        return ('SLL', 'POCSO')
    if 'ndps' in sub or 'ndps' in mod:
        return ('SLL', 'NDPS')
    if 'gowan' in sub or 'gowan' in mod:
        return ('SLL', 'GOWANSH')
    if 'it act' in sub or 'it_act' in mod:
        return ('SLL', 'IT ACT')
    if 'm.v' in sub or 'mv act' in sub or 'motor vehicle' in sub or 'traffic' in mod:
        return ('SLL', 'M.V. ACT')
    if 'uapa' in sub or 'uapa' in mod:
        return ('SLL', 'UAPA')
    if 'arms' in sub or 'arms' in mod:
        return ('SLL', 'ARMS ACT')
    if mod in ['form_6', 'form_vi', 'part_6']:
        return ('SLL', 'OTHER SLL')

    # IPC / Class I to V
    if 'murder' in sub or 'murder' in mod:
        if 'attempt' in sub or 'att' in sub or 'attempt' in mod:
            return ('IPC', 'ATTEMPT TO MURDER')
        return ('IPC', 'MURDER')

    if 'dacoity' in sub or 'dacoity' in mod:
        return ('IPC', 'DACOITY')

    if 'robbery' in sub or 'robery' in sub or 'robbery' in mod:
        return ('IPC', 'ROBBERY')

    if 'hbt' in sub or 'hbt' in mod or 'house break' in sub:
        if 'day' in sub or 'day' in title:
            return ('IPC', 'HBT BY DAY')
        return ('IPC', 'HBT BY NIGHT')

    if 'chain snatch' in sub or 'chain' in title:
        return ('IPC', 'CHAIN SNATCHING')

    if 'theft' in sub or 'theft' in mod:
        return ('IPC', 'THEFTS')

    if 'riot' in sub or 'riot' in mod:
        return ('IPC', 'RIOTS')

    if 'unlawful' in sub or 'assembly' in sub:
        return ('IPC', 'UNLAWFUL ASSEMBLY')

    if 'cbt' in sub or 'breach of trust' in sub:
        return ('IPC', 'C.B.T.')

    if 'cheating' in sub or 'fraud' in sub:
        return ('IPC', 'CHEATING')

    if 'mischief' in sub:
        return ('IPC', 'MISCHIEF')

    if 'hurt' in sub or 'hurt' in mod:
        return ('IPC', 'HURTS')

    if 'assault' in sub or 'govt' in sub:
        return ('IPC', 'ASSAULT ON PUBLIC SERVANT')

    if 'rape' in sub or 'rape' in mod:
        return ('IPC', 'RAPE')

    if 'molestation' in sub or '354' in sub:
        return ('IPC', 'MOLESTATION')

    if 'extortion' in sub or 'extortion' in mod:
        return ('IPC', 'EXTORTION')

    if '304' in sub or 'accident' in sub or 'accident' in mod or 'rash driving' in sub:
        return ('IPC', 'IPC (A) 304 / ACCIDENT')

    if '498' in sub or '498_a' in mod:
        return ('IPC', '498(A) IPC')

    if 'kidnap' in sub or 'missing' in sub or 'kidnapping' in mod or 'missing' in mod:
        return ('IPC', 'KIDNAPPING')

    if 'women' in sub or 'crime_women' in mod:
        return ('IPC', 'CRIME AGAINST WOMEN')

    if 'coin' in sub:
        return ('IPC', 'COIN')

    return ('IPC', 'OTHER IPC')


def _normalize_head_name(raw_name: str, group: str) -> str:
    name_upper = raw_name.upper().strip()
    name_lower = raw_name.lower().strip()

    if group == 'IPC':
        if 'MURDER' in name_upper:
            return 'ATTEMPT TO MURDER' if 'ATTEMPT' in name_upper else 'MURDER'
        if 'DACOITY' in name_upper:
            return 'DACOITY'
        if 'ROBBERY' in name_upper:
            return 'ROBBERY'
        if 'HBT' in name_upper:
            return 'HBT BY DAY' if 'DAY' in name_upper else 'HBT BY NIGHT'
        if 'THEFT' in name_upper:
            return 'THEFTS'
        if 'RIOT' in name_upper:
            return 'RIOTS'
        if 'UNLAWFUL' in name_upper:
            return 'UNLAWFUL ASSEMBLY'
        if 'CBT' in name_upper or 'BREACH OF TRUST' in name_upper:
            return 'C.B.T.'
        if 'CHEATING' in name_upper:
            return 'CHEATING'
        if 'MISCHIEF' in name_upper:
            return 'MISCHIEF'
        if 'HURT' in name_upper:
            return 'HURTS'
        if 'ASSAULT' in name_upper:
            return 'ASSAULT ON PUBLIC SERVANT'
        if 'RAPE' in name_upper:
            return 'RAPE'
        if 'MOLESTATION' in name_upper or '354' in name_upper:
            return 'MOLESTATION'
        if 'EXTORTION' in name_upper:
            return 'EXTORTION'
        if '304' in name_upper or 'ACCIDENT' in name_upper:
            return 'IPC (A) 304 / ACCIDENT'
        if '498' in name_upper:
            return '498(A) IPC'
        if 'KIDNAP' in name_upper or 'MISSING' in name_upper:
            return 'KIDNAPPING'
        if 'CHAIN SNATCHING' in name_upper:
            return 'CHAIN SNATCHING'
        if 'WOMEN' in name_upper:
            return 'CRIME AGAINST WOMEN'
        if 'COIN' in name_upper:
            return 'COIN'
        if 'OTHER' in name_upper or 'MISC' in name_upper:
            return 'OTHER IPC'
        return name_upper

    # SLL
    if 'ST DRUGS' in name_upper:
        return 'ST DRUGS'
    if 'PROHIBITION' in name_upper:
        return 'PROHIBITION'
    if 'GAMBLING' in name_upper:
        return 'GAMBLING'
    if 'POCSO' in name_upper:
        return 'POCSO'
    if 'NDPS' in name_upper:
        return 'NDPS'
    if 'GOWANSH' in name_upper:
        return 'GOWANSH'
    if 'IT ACT' in name_upper:
        return 'IT ACT'
    if 'M.V' in name_upper or 'MV' in name_upper or 'MOTOR VEHICLE' in name_upper:
        return 'M.V. ACT'
    if 'UAPA' in name_upper:
        return 'UAPA'
    if 'ARMS' in name_upper:
        return 'ARMS ACT'
    if 'OTHER' in name_upper or 'MISC' in name_upper:
        return 'OTHER SLL'
    return name_upper


def is_case_detected(case: CaseRecord) -> bool:
    """
    Determines if a case is Detected (DET) for police comparative reporting:
    - Status in ['Detected', 'Disposal', 'Disposed', 'Closed', 'Resolved']
    - Or accused person is identified.
    """
    status_str = (getattr(case, 'status', '') or '').strip().lower()
    if status_str in ['detected', 'disposal', 'disposed', 'closed', 'resolved']:
        return True

    accused = (getattr(case, 'accused', '') or '').strip()
    if accused and accused.lower() not in ['unknown', 'अज्ञात', 'unidentified', 'none', 'null']:
        return True

    return False


class MonthlyCrimeComparativeService:
    """
    Dynamic database calculation service for the Police Monthly Crime Comparative Report.
    Follows official police comparative statement format:
    HEADS | CM (REP/DET) | PM (REP/DET) | SMLY (REP/DET) | INC/DEC | CY_YTD (REP/DET) | PY_YTD (REP/DET) | INC/DEC
    """

    def __init__(self, station_name: Optional[str] = None, allowed_stations: Optional[List[str]] = None):
        self.station_name = station_name
        self.allowed_stations = allowed_stations

    def get_comparative_statement(
        self,
        year: int,
        month: int,
        cutoff_day: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Executes dynamic database aggregation and returns fully calculated report structure.
        """
        windows = get_comparative_date_ranges(year, month, cutoff_day=cutoff_day)

        cm = windows['current_month']
        pm = windows['previous_month']
        smly = windows['same_month_previous_year']
        cy = windows['current_year_ytd']
        py = windows['previous_year_ytd']

        # Determine overall query bounding box to fetch all candidate records in a single query
        overall_start = min(smly['start'], py['start'], pm['start'], cy['start'])
        overall_end = max(cm['end'], cy['end'])

        queryset = CaseRecord.objects.annotate(
            record_date=Coalesce('incident_date', 'created_at')
        ).filter(
            record_date__gte=overall_start,
            record_date__lte=overall_end
        ).prefetch_related('category_links__category__group')

        # Station filtering & multi-tenancy
        if self.station_name:
            queryset = queryset.filter(station_name__iexact=self.station_name)
        elif self.allowed_stations is not None:
            queryset = queryset.filter(station_name__in=self.allowed_stations)

        cases = list(queryset)

        # Build dynamic list of active heads from database CaseCategory tables
        ipc_heads_order: List[str] = []
        sll_heads_order: List[str] = []
        try:
            db_cats = CaseCategory.objects.filter(is_active=True).select_related('group').order_by(
                'group__display_order', 'display_order', 'category_id'
            )
            for c in db_cats:
                g_code = (c.group.group_code if c.group else '') or ''
                g_name = (c.group.group_name if c.group else '') or ''
                is_sll = (c.group and c.group.group_id == 2) or ('VI' in g_code.upper()) or ('6' in g_name)
                norm_h = _normalize_head_name(c.category_name, 'SLL' if is_sll else 'IPC')
                if is_sll:
                    if norm_h not in sll_heads_order:
                        sll_heads_order.append(norm_h)
                else:
                    if norm_h not in ipc_heads_order:
                        ipc_heads_order.append(norm_h)
        except Exception as e:
            logger.debug(f"Error fetching db categories: {e}")

        # Structure storage for aggregations
        def _empty_head_data(head_name: str, group_name: str) -> Dict[str, Any]:
            return {
                'head': head_name,
                'group': group_name,
                'current_month': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
                'previous_month': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
                'same_month_previous_year': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
                'current_year_ytd': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
                'previous_year_ytd': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
            }

        ipc_agg = {h: _empty_head_data(h, 'IPC') for h in ipc_heads_order}
        sll_agg = {h: _empty_head_data(h, 'SLL') for h in sll_heads_order}

        # Aggregate dynamically in single pass
        for case in cases:
            rec_dt = getattr(case, 'record_date', None) or getattr(case, 'incident_date', None) or getattr(case, 'created_at', None)
            if not rec_dt:
                continue

            case_id = str(case.pk or case.id)
            detected = is_case_detected(case)
            grp, head = classify_case_record(case)

            target_agg = ipc_agg if grp == 'IPC' else sll_agg
            if head not in target_agg:
                target_agg[head] = _empty_head_data(head, grp)
                if grp == 'IPC':
                    ipc_heads_order.append(head)
                else:
                    sll_heads_order.append(head)

            data = target_agg[head]

            # Check CM
            if cm['start'] <= rec_dt <= cm['end']:
                data['current_month']['rep'] += 1
                data['current_month']['rep_case_ids'].append(case_id)
                if detected:
                    data['current_month']['det'] += 1
                    data['current_month']['det_case_ids'].append(case_id)

            # Check PM
            if pm['start'] <= rec_dt <= pm['end']:
                data['previous_month']['rep'] += 1
                data['previous_month']['rep_case_ids'].append(case_id)
                if detected:
                    data['previous_month']['det'] += 1
                    data['previous_month']['det_case_ids'].append(case_id)

            # Check SMLY
            if smly['start'] <= rec_dt <= smly['end']:
                data['same_month_previous_year']['rep'] += 1
                data['same_month_previous_year']['rep_case_ids'].append(case_id)
                if detected:
                    data['same_month_previous_year']['det'] += 1
                    data['same_month_previous_year']['det_case_ids'].append(case_id)

            # Check CY_YTD
            if cy['start'] <= rec_dt <= cy['end']:
                data['current_year_ytd']['rep'] += 1
                data['current_year_ytd']['rep_case_ids'].append(case_id)
                if detected:
                    data['current_year_ytd']['det'] += 1
                    data['current_year_ytd']['det_case_ids'].append(case_id)

            # Check PY_YTD
            if py['start'] <= rec_dt <= py['end']:
                data['previous_year_ytd']['rep'] += 1
                data['previous_year_ytd']['rep_case_ids'].append(case_id)
                if detected:
                    data['previous_year_ytd']['det'] += 1
                    data['previous_year_ytd']['det_case_ids'].append(case_id)

        # Assemble formatted rows with INC/DEC calculations
        def _finalize_rows(heads_order: List[str], agg_dict: Dict[str, Any]) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
            rows = []
            total = {
                'current_month': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
                'previous_month': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
                'same_month_previous_year': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
                'current_year_ytd': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
                'previous_year_ytd': {'rep': 0, 'det': 0, 'rep_case_ids': [], 'det_case_ids': []},
            }

            for idx, h in enumerate(heads_order, start=1):
                item = agg_dict[h]
                m_inc = format_inc_dec(item['current_month']['rep'], item['same_month_previous_year']['rep'])
                ytd_inc = format_inc_dec(item['current_year_ytd']['rep'], item['previous_year_ytd']['rep'])

                row = {
                    'sr_no': idx,
                    'head': h,
                    'group': item['group'],
                    'current_month': {
                        'rep': item['current_month']['rep'],
                        'det': item['current_month']['det'],
                        'rep_case_ids': item['current_month']['rep_case_ids'],
                        'det_case_ids': item['current_month']['det_case_ids'],
                    },
                    'previous_month': {
                        'rep': item['previous_month']['rep'],
                        'det': item['previous_month']['det'],
                        'rep_case_ids': item['previous_month']['rep_case_ids'],
                        'det_case_ids': item['previous_month']['det_case_ids'],
                    },
                    'same_month_previous_year': {
                        'rep': item['same_month_previous_year']['rep'],
                        'det': item['same_month_previous_year']['det'],
                        'rep_case_ids': item['same_month_previous_year']['rep_case_ids'],
                        'det_case_ids': item['same_month_previous_year']['det_case_ids'],
                    },
                    'monthly_inc_dec': m_inc,
                    'current_year_ytd': {
                        'rep': item['current_year_ytd']['rep'],
                        'det': item['current_year_ytd']['det'],
                        'rep_case_ids': item['current_year_ytd']['rep_case_ids'],
                        'det_case_ids': item['current_year_ytd']['det_case_ids'],
                    },
                    'previous_year_ytd': {
                        'rep': item['previous_year_ytd']['rep'],
                        'det': item['previous_year_ytd']['det'],
                        'rep_case_ids': item['previous_year_ytd']['rep_case_ids'],
                        'det_case_ids': item['previous_year_ytd']['det_case_ids'],
                    },
                    'ytd_inc_dec': ytd_inc,
                }
                rows.append(row)

                # Accumulate totals
                for w in ['current_month', 'previous_month', 'same_month_previous_year', 'current_year_ytd', 'previous_year_ytd']:
                    total[w]['rep'] += item[w]['rep']
                    total[w]['det'] += item[w]['det']
                    total[w]['rep_case_ids'].extend(item[w]['rep_case_ids'])
                    total[w]['det_case_ids'].extend(item[w]['det_case_ids'])

            total_m_inc = format_inc_dec(total['current_month']['rep'], total['same_month_previous_year']['rep'])
            total_ytd_inc = format_inc_dec(total['current_year_ytd']['rep'], total['previous_year_ytd']['rep'])

            total_row = {
                'head': 'TOTAL',
                'current_month': total['current_month'],
                'previous_month': total['previous_month'],
                'same_month_previous_year': total['same_month_previous_year'],
                'monthly_inc_dec': total_m_inc,
                'current_year_ytd': total['current_year_ytd'],
                'previous_year_ytd': total['previous_year_ytd'],
                'ytd_inc_dec': total_ytd_inc,
            }

            return rows, total_row

        ipc_rows, total_ipc = _finalize_rows(ipc_heads_order, ipc_agg)
        total_ipc['head'] = 'TOTAL IPC CRIMES'
        total_ipc['group'] = 'IPC'

        sll_rows, total_sll = _finalize_rows(sll_heads_order, sll_agg)
        total_sll['head'] = 'TOTAL SLL CRIMES'
        total_sll['group'] = 'SLL'

        # Grand Total Calculation (Total IPC + Total SLL)
        grand_total_counts = {
            'current_month': {
                'rep': total_ipc['current_month']['rep'] + total_sll['current_month']['rep'],
                'det': total_ipc['current_month']['det'] + total_sll['current_month']['det'],
                'rep_case_ids': total_ipc['current_month']['rep_case_ids'] + total_sll['current_month']['rep_case_ids'],
                'det_case_ids': total_ipc['current_month']['det_case_ids'] + total_sll['current_month']['det_case_ids'],
            },
            'previous_month': {
                'rep': total_ipc['previous_month']['rep'] + total_sll['previous_month']['rep'],
                'det': total_ipc['previous_month']['det'] + total_sll['previous_month']['det'],
                'rep_case_ids': total_ipc['previous_month']['rep_case_ids'] + total_sll['previous_month']['rep_case_ids'],
                'det_case_ids': total_ipc['previous_month']['det_case_ids'] + total_sll['previous_month']['det_case_ids'],
            },
            'same_month_previous_year': {
                'rep': total_ipc['same_month_previous_year']['rep'] + total_sll['same_month_previous_year']['rep'],
                'det': total_ipc['same_month_previous_year']['det'] + total_sll['same_month_previous_year']['det'],
                'rep_case_ids': total_ipc['same_month_previous_year']['rep_case_ids'] + total_sll['same_month_previous_year']['rep_case_ids'],
                'det_case_ids': total_ipc['same_month_previous_year']['det_case_ids'] + total_sll['same_month_previous_year']['det_case_ids'],
            },
            'current_year_ytd': {
                'rep': total_ipc['current_year_ytd']['rep'] + total_sll['current_year_ytd']['rep'],
                'det': total_ipc['current_year_ytd']['det'] + total_sll['current_year_ytd']['det'],
                'rep_case_ids': total_ipc['current_year_ytd']['rep_case_ids'] + total_sll['current_year_ytd']['rep_case_ids'],
                'det_case_ids': total_ipc['current_year_ytd']['det_case_ids'] + total_sll['current_year_ytd']['det_case_ids'],
            },
            'previous_year_ytd': {
                'rep': total_ipc['previous_year_ytd']['rep'] + total_sll['previous_year_ytd']['rep'],
                'det': total_ipc['previous_year_ytd']['det'] + total_sll['previous_year_ytd']['det'],
                'rep_case_ids': total_ipc['previous_year_ytd']['rep_case_ids'] + total_sll['previous_year_ytd']['rep_case_ids'],
                'det_case_ids': total_ipc['previous_year_ytd']['det_case_ids'] + total_sll['previous_year_ytd']['det_case_ids'],
            },
        }

        grand_m_inc = format_inc_dec(
            grand_total_counts['current_month']['rep'],
            grand_total_counts['same_month_previous_year']['rep']
        )
        grand_ytd_inc = format_inc_dec(
            grand_total_counts['current_year_ytd']['rep'],
            grand_total_counts['previous_year_ytd']['rep']
        )

        grand_total = {
            'head': 'GRAND TOTAL (IPC + SLL)',
            'group': 'ALL',
            'current_month': grand_total_counts['current_month'],
            'previous_month': grand_total_counts['previous_month'],
            'same_month_previous_year': grand_total_counts['same_month_previous_year'],
            'monthly_inc_dec': grand_m_inc,
            'current_year_ytd': grand_total_counts['current_year_ytd'],
            'previous_year_ytd': grand_total_counts['previous_year_ytd'],
            'ytd_inc_dec': grand_ytd_inc,
        }

        # Build cases_lookup for instant client-side case card display
        cases_lookup = {}
        for case in cases:
            c_id = str(case.pk or case.id)
            inc_dt = getattr(case, 'incident_date', None) or getattr(case, 'record_date', None) or getattr(case, 'created_at', None)
            inc_str = inc_dt.isoformat() if inc_dt and hasattr(inc_dt, 'isoformat') else str(inc_dt or '')
            cases_lookup[c_id] = {
                'id': c_id,
                'case_number': str(getattr(case, 'case_number', '') or ''),
                'title': str(getattr(case, 'title', '') or ''),
                'incident_date': inc_str,
                'status': str(getattr(case, 'status', '') or 'Open'),
                'priority': str(getattr(case, 'priority', '') or 'Medium'),
                'assigned_officer': str(getattr(case, 'assigned_officer', '') or ''),
                'complainant': str(getattr(case, 'complainant', '') or ''),
                'accused': str(getattr(case, 'accused', '') or ''),
                'location': str(getattr(case, 'location', '') or ''),
                'sub_category': str(getattr(case, 'sub_category', '') or ''),
                'module_key': str(getattr(case, 'module_key', '') or ''),
                'station_name': str(getattr(case, 'station_name', '') or ''),
            }

        # Prepare unified all_rows array for simple table rendering / export
        all_rows: List[Dict[str, Any]] = []
        all_rows.append({'type': 'section_header', 'title': 'I TO V - IPC CRIMES'})
        all_rows.extend(ipc_rows)
        all_rows.append({'type': 'subtotal', **total_ipc})
        all_rows.append({'type': 'section_header', 'title': 'VI - SLL CRIMES'})
        all_rows.extend(sll_rows)
        all_rows.append({'type': 'subtotal', **total_sll})
        all_rows.append({'type': 'grand_total', **grand_total})

        return {
            'metadata': {
                'report_title': 'STATEMENT SHOWING IPC & SLL CRIMES COMPARITIVE',
                'month': month,
                'month_name': calendar.month_name[month].upper(),
                'year': year,
                'station_name': self.station_name or 'ALL',
                'windows': {
                    'current_month': {
                        'label': cm['label'],
                        'start': cm['start'].isoformat(),
                        'end': cm['end'].isoformat(),
                    },
                    'previous_month': {
                        'label': pm['label'],
                        'start': pm['start'].isoformat(),
                        'end': pm['end'].isoformat(),
                    },
                    'same_month_previous_year': {
                        'label': smly['label'],
                        'start': smly['start'].isoformat(),
                        'end': smly['end'].isoformat(),
                    },
                    'monthly_inc_dec': {'label': 'INC/DEC'},
                    'current_year_ytd': {
                        'label': cy['label'],
                        'start': cy['start'].isoformat(),
                        'end': cy['end'].isoformat(),
                    },
                    'previous_year_ytd': {
                        'label': py['label'],
                        'start': py['start'].isoformat(),
                        'end': py['end'].isoformat(),
                    },
                    'ytd_inc_dec': {'label': 'INC/DEC'},
                },
                'total_cases_analyzed': len(cases),
                'available_years': sorted(list({
                    y for y in CaseRecord.objects.dates('incident_date', 'year').values_list('incident_date__year', flat=True)
                    if y
                } | {year, datetime.now().year}), reverse=True),
            },
            'ipc_crimes': ipc_rows,
            'total_ipc': total_ipc,
            'sll_crimes': sll_rows,
            'total_sll': total_sll,
            'grand_total': grand_total,
            'all_rows': all_rows,
            'cases_lookup': cases_lookup,
        }
