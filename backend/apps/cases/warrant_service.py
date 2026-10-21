import calendar
import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple, Any

from django.db.models import Q
from django.db.models.functions import Coalesce

from apps.cases.models import CaseRecord
from apps.stations.models import PoliceStation, District

logger = logging.getLogger(__name__)


WARRANT_TYPE_SUMMONS = 'summons'
WARRANT_TYPE_BW = 'bw'
WARRANT_TYPE_NBW = 'nbw'


def get_comparative_date_ranges(
    year: int,
    month: int,
    cutoff_day: Optional[int] = None
) -> Dict[str, Dict[str, Any]]:
    """
    Computes reporting time windows for comparative analysis:
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


def classify_warrant_record(record: CaseRecord) -> Optional[str]:
    """
    Classifies a CaseRecord into one of 3 Warrant sections:
    - 'summons' (समंस)
    - 'bw' (जमानती वारंट / Bailable Warrant)
    - 'nbw' (पकड वारंट / Non-Bailable Warrant)
    
    Checks extra_fields, sub_category, title, module_key, and description.
    Returns None if the record does not belong to summons / warrant.
    """
    extra = record.extra_fields if isinstance(record.extra_fields, dict) else {}

    raw_type = (
        extra.get('warrant_type')
        or extra.get('warrantType')
        or extra.get('type')
        or extra.get('process_type')
        or extra.get('processType')
        or extra.get('category')
        or record.sub_category
        or ''
    )
    type_str = str(raw_type).strip().lower()

    # Also inspect title and description for keywords if type_str is generic
    combined_text = f"{type_str} {record.title or ''} {record.description or ''}".lower()

    # 1. Non-Bailable Warrant (NBW / पकड वारंट)
    if any(k in type_str for k in ['nbw', 'non-bailable', 'non_bailable', 'non bailable', 'पकड']):
        return WARRANT_TYPE_NBW
    if any(k in combined_text for k in ['non-bailable warrant', 'non bailable warrant', 'nbw', 'पकड वारंट']):
        return WARRANT_TYPE_NBW

    # 2. Bailable Warrant (BW / जमानती वारंट)
    if any(k in type_str for k in ['bw', 'bailable', 'जमानती']):
        return WARRANT_TYPE_BW
    if any(k in combined_text for k in ['bailable warrant', 'bw', 'जमानती वारंट', 'जमानती']):
        return WARRANT_TYPE_BW

    # 3. Summons (समंस)
    if any(k in type_str for k in ['summons', 'sam', 'समंस']):
        return WARRANT_TYPE_SUMMONS
    if any(k in combined_text for k in ['summons', 'समंस', 'समन्स']):
        return WARRANT_TYPE_SUMMONS

    # 4. If record belongs to 'sam_warrant' module but specific sub-type is ambiguous
    mod = (record.module_key or '').strip().lower()
    if mod == 'sam_warrant':
        if 'पकड' in combined_text or 'arrest' in combined_text:
            return WARRANT_TYPE_NBW
        if 'जमानत' in combined_text:
            return WARRANT_TYPE_BW
        # Default for sam_warrant module if unspecified
        return WARRANT_TYPE_SUMMONS

    return None


def get_warrant_execution_status(record: CaseRecord) -> str:
    """
    Determines execution outcome:
    - 'executed' (तामील / Executed / Served)
    - 'unserved' (अदम / Unserved / Returned Unexecuted)
    - 'pending' (अखेर / Pending)
    """
    extra = record.extra_fields if isinstance(record.extra_fields, dict) else {}

    raw_status = (
        extra.get('execution_status')
        or extra.get('executionStatus')
        or extra.get('service_status')
        or extra.get('warrant_status')
        or extra.get('process_status')
        or record.status
        or ''
    )
    status_str = str(raw_status).strip().lower()

    # Check unserved (अदम)
    if any(k in status_str for k in ['unserved', 'unexecuted', 'अदम', 'adam', 'returned', 'not served', 'untraceable']):
        return 'unserved'

    # Check executed / served (तामील)
    if any(k in status_str for k in ['executed', 'served', 'तामील', 'tamil', 'disposal', 'disposed', 'closed', 'resolved']):
        return 'executed'

    # Extra checks: served_date or execution_date present
    if extra.get('served_date') or extra.get('execution_date') or extra.get('tamila_date') or extra.get('तामील_दिनांक'):
        return 'executed'
    if extra.get('unserved_date') or extra.get('adam_date') or extra.get('अदम_दिनांक'):
        return 'unserved'

    return 'pending'


class SummonsWarrantReportService:
    """
    Dynamic database calculation service for the Official Police Summons & Warrant Report.
    Marathi Format:
    - समंस (Summons)
    - पकड वारंट (NBW - Non-Bailable Warrant)
    - जमानती वारंट (BW - Bailable Warrant)

    Columns per section:
    - मागील (Previous Month pending)
    - चालु माहे (Current Month received / issued)
    - बेरीज (Total = Previous Month + Current Month)
    - तामील (Executed / Served)
    - तामील टक्के (Executed % = (Executed / Total) * 100)
    - अदम (Unserved)
    - अखेर (Pending = Total - Executed - Unserved)
    """

    SECTIONS = [
        {
            'key': WARRANT_TYPE_SUMMONS,
            'title_en': 'Summons',
            'title_mr': 'समंस',
            'code': 'SUMMONS',
        },
        {
            'key': WARRANT_TYPE_NBW,
            'title_en': 'NBW (Non-Bailable Warrant)',
            'title_mr': 'पकड वारंट',
            'code': 'NBW',
        },
        {
            'key': WARRANT_TYPE_BW,
            'title_en': 'BW (Bailable Warrant)',
            'title_mr': 'जमानती वारंट',
            'code': 'BW',
        },
    ]

    def __init__(
        self,
        station_name: Optional[str] = None,
        district_name: Optional[str] = None,
        allowed_stations: Optional[List[str]] = None
    ):
        self.station_name = station_name
        self.district_name = district_name
        self.allowed_stations = allowed_stations

    def _get_base_queryset(self):
        """
        Builds filtered base queryset matching tenant and warrant criteria.
        """
        q_filter = (
            Q(module_key__iexact='sam_warrant')
            | Q(module_key__icontains='warrant')
            | Q(module_key__icontains='summons')
            | Q(sub_category__icontains='warrant')
            | Q(sub_category__icontains='summons')
            | Q(sub_category__icontains='समंस')
            | Q(sub_category__icontains='वारंट')
            | Q(title__icontains='warrant')
            | Q(title__icontains='summons')
            | Q(title__icontains='समंस')
            | Q(title__icontains='वारंट')
            | Q(extra_fields__has_key='warrant_type')
            | Q(extra_fields__has_key='warrantType')
        )

        queryset = CaseRecord.objects.annotate(
            record_date=Coalesce('incident_date', 'created_at')
        ).filter(q_filter)

        # Multi-tenancy & Station/District filters
        if self.station_name:
            queryset = queryset.filter(station_name__iexact=self.station_name)
        elif self.district_name:
            # Match stations belonging to this district
            st_names = list(
                PoliceStation.objects.filter(
                    Q(district_name__iexact=self.district_name) | Q(district__name__iexact=self.district_name)
                ).values_list('station_name', flat=True)
            )
            if st_names:
                queryset = queryset.filter(station_name__in=st_names)
            else:
                queryset = queryset.filter(station_name__iexact=self.district_name)
        elif self.allowed_stations is not None:
            queryset = queryset.filter(station_name__in=self.allowed_stations)

        return queryset

    def get_report(
        self,
        year: int,
        month: int,
        cutoff_day: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Computes dynamic Summons and Warrant statistics for the given month & year.
        Returns full breakdown with sections and optional station/division rows.
        """
        windows = get_comparative_date_ranges(year, month, cutoff_day=cutoff_day)
        cm = windows['current_month']
        pm = windows['previous_month']

        # Determine station rows for the table:
        # If a single station is selected, show that station.
        # Otherwise, discover active stations from PoliceStation table or CaseRecord data.
        station_rows = self._resolve_stations_list()

        # Query all warrant records up to current month end
        queryset = self._get_base_queryset().filter(record_date__lte=cm['end'])
        records = list(queryset)

        # Structure storage per section and station
        # section_key -> { 'summary': stats_dict, 'by_station': { station_name: stats_dict } }
        def _empty_stats():
            return {
                'previous_month': 0,
                'current_month': 0,
                'total': 0,
                'executed': 0,
                'executed_percent': '0%',
                'executed_percent_val': 0.0,
                'unserved': 0,
                'pending': 0,
                'case_ids': {
                    'previous_month': [],
                    'current_month': [],
                    'executed': [],
                    'unserved': [],
                    'pending': [],
                }
            }

        section_data = {
            s['key']: {
                'summary': _empty_stats(),
                'by_station': {st: _empty_stats() for st in station_rows}
            }
            for s in self.SECTIONS
        }

        # Lookup mapping of cases for client click-through
        cases_lookup = {}

        for rec in records:
            sec_key = classify_warrant_record(rec)
            if not sec_key or sec_key not in section_data:
                continue

            rec_dt = getattr(rec, 'record_date', None) or getattr(rec, 'incident_date', None) or getattr(rec, 'created_at', None)
            if not rec_dt:
                continue

            case_id = str(rec.pk or rec.id)
            exec_status = get_warrant_execution_status(rec)
            st_name = (rec.station_name or '').strip()

            # Ensure station exists in by_station dict
            for s_key in section_data:
                if st_name and st_name not in section_data[s_key]['by_station']:
                    section_data[s_key]['by_station'][st_name] = _empty_stats()
                    if st_name not in station_rows:
                        station_rows.append(st_name)

            # Store in cases_lookup for quick retrieval
            inc_str = rec_dt.isoformat() if hasattr(rec_dt, 'isoformat') else str(rec_dt)
            cases_lookup[case_id] = {
                'id': case_id,
                'case_number': str(getattr(rec, 'case_number', '') or ''),
                'title': str(getattr(rec, 'title', '') or ''),
                'incident_date': inc_str,
                'status': str(getattr(rec, 'status', '') or 'Pending'),
                'execution_status': exec_status,
                'section': sec_key,
                'station_name': st_name,
                'assigned_officer': str(getattr(rec, 'assigned_officer', '') or ''),
                'accused': str(getattr(rec, 'accused', '') or ''),
                'complainant': str(getattr(rec, 'complainant', '') or ''),
            }

            is_cm = (cm['start'] <= rec_dt <= cm['end'])
            is_pm_or_earlier = (rec_dt < cm['start'])

            # Accumulation helper
            def _accumulate(target_stats: dict):
                if is_cm:
                    target_stats['current_month'] += 1
                    target_stats['case_ids']['current_month'].append(case_id)
                elif is_pm_or_earlier:
                    # In official police reporting, cases carried forward before CM are Previous Month
                    target_stats['previous_month'] += 1
                    target_stats['case_ids']['previous_month'].append(case_id)

                if exec_status == 'executed':
                    target_stats['executed'] += 1
                    target_stats['case_ids']['executed'].append(case_id)
                elif exec_status == 'unserved':
                    target_stats['unserved'] += 1
                    target_stats['case_ids']['unserved'].append(case_id)
                else:
                    target_stats['pending'] += 1
                    target_stats['case_ids']['pending'].append(case_id)

            # Accumulate in overall section summary
            _accumulate(section_data[sec_key]['summary'])

            # Accumulate in station row if station matched
            if st_name and st_name in section_data[sec_key]['by_station']:
                _accumulate(section_data[sec_key]['by_station'][st_name])

        # Finalize calculations (Total, Executed %, Pending)
        def _finalize_stats(item: dict):
            tot = item['previous_month'] + item['current_month']
            item['total'] = tot
            exec_cnt = item['executed']
            uns_cnt = item['unserved']
            
            # Recalculate pending: Total - Executed - Unserved
            calc_pending = max(0, tot - exec_cnt - uns_cnt)
            item['pending'] = calc_pending

            if tot > 0:
                pct = round((exec_cnt / tot) * 100, 1)
                item['executed_percent_val'] = pct
                item['executed_percent'] = f"{int(pct) if pct.is_integer() else pct}%"
            else:
                item['executed_percent_val'] = 0.0
                item['executed_percent'] = "0%"

        sections_result = []
        for s_def in self.SECTIONS:
            sec_key = s_def['key']
            sec_bundle = section_data[sec_key]
            _finalize_stats(sec_bundle['summary'])

            station_table_rows = []
            for idx, st_name in enumerate(station_rows, start=1):
                st_stat = sec_bundle['by_station'].get(st_name, _empty_stats())
                _finalize_stats(st_stat)
                station_table_rows.append({
                    'sr_no': idx,
                    'station_name': st_name,
                    **st_stat
                })

            sections_result.append({
                'key': sec_key,
                'code': s_def['code'],
                'title_en': s_def['title_en'],
                'title_mr': s_def['title_mr'],
                'summary': sec_bundle['summary'],
                'stations': station_table_rows,
            })

        # Calculate Grand Total across all 3 sections
        grand_total_summary = _empty_stats()
        for sec in sections_result:
            s_sum = sec['summary']
            grand_total_summary['previous_month'] += s_sum['previous_month']
            grand_total_summary['current_month'] += s_sum['current_month']
            grand_total_summary['executed'] += s_sum['executed']
            grand_total_summary['unserved'] += s_sum['unserved']
            for k in grand_total_summary['case_ids']:
                grand_total_summary['case_ids'][k].extend(s_sum['case_ids'][k])
        _finalize_stats(grand_total_summary)

        return {
            'metadata': {
                'report_title_en': 'SUMMONS & WARRANT MONTHLY REPORT',
                'report_title_mr': f'समंस वारंट माहीती माहे {month} सन {year}',
                'month': month,
                'month_name': calendar.month_name[month].upper(),
                'year': year,
                'station_name': self.station_name or 'ALL',
                'district_name': self.district_name or 'ALL',
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
                },
                'total_warrant_records_analyzed': len(records),
            },
            'sections': sections_result,
            'grand_total': grand_total_summary,
            'cases_lookup': cases_lookup,
        }

    def _resolve_stations_list(self) -> List[str]:
        """
        Retrieves ordered list of station names for the report rows.
        """
        if self.station_name:
            return [self.station_name]

        station_names: List[str] = []
        if self.district_name:
            ps_qs = PoliceStation.objects.filter(
                Q(district_name__iexact=self.district_name) | Q(district__name__iexact=self.district_name)
            ).order_by('station_name')
            station_names = list(ps_qs.values_list('station_name', flat=True))

        if not station_names and self.allowed_stations:
            station_names = list(self.allowed_stations)

        if not station_names:
            # Query distinct stations with existing records
            distinct_in_cases = list(
                CaseRecord.objects.exclude(station_name='')
                .values_list('station_name', flat=True)
                .distinct()
            )
            station_names = sorted([s for s in distinct_in_cases if s])

        return station_names
