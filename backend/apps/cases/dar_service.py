import logging
from typing import Dict, List, Optional, Any, Tuple
from django.db.models import Q
from apps.cases.models import CaseRecord
from apps.crimetab.models.dynamic_engine import FieldTemplateField
from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema

logger = logging.getLogger(__name__)

STATUS_PENDING = 'Pending'
STATUS_FILLED = 'Filled'

COLOR_PENDING = '#E74C3C'  # Red
COLOR_FILLED = '#2ECC71'   # Green


def is_truthy_yes(val: Any) -> bool:
    """Returns True if the value represents an affirmative 'Yes'."""
    if val is True:
        return True
    if isinstance(val, str):
        cleaned = val.strip().lower()
        return cleaned in ['yes', 'y', 'true', '1', 'filled', 'completed']
    if isinstance(val, (int, float)):
        return val == 1
    return False


def is_falsy_no(val: Any) -> bool:
    """Returns True if the value represents an explicit negative 'No'."""
    if val is False:
        return True
    if isinstance(val, str):
        cleaned = val.strip().lower()
        return cleaned in ['no', 'n', 'false', '0', 'pending']
    if isinstance(val, (int, float)):
        return val == 0
    return False


class RoadAccidentDarService:
    """
    Dedicated Business Logic Service for DAR (Detailed Accident Report)
    under Road Accident cases.

    Rules:
    1. Identifies all Road Accident cases dynamically from database.
    2. If all required DAR fields are marked 'Yes', DAR is Filled/Completed.
    3. If any required DAR field is marked 'No', DAR is Pending.
    4. Pending status color is Red (#E74C3C), Filled/Completed is Green (#2ECC71).
    5. Calculates Total DAR, DAR Form Filled, and DAR Form Pending dynamically.
    6. Sends reminder notifications to the assigned IO for pending DAR forms.
    """

    @classmethod
    def get_road_accident_category_codes(cls) -> List[str]:
        """Dynamically fetch all accident and road-rash category codes from database."""
        try:
            from apps.crimetab.models.groupings import CaseCategory
            codes = list(CaseCategory.objects.filter(
                Q(category_name__icontains='accident') |
                Q(category_name__icontains='rash') |
                Q(category_code__icontains='acc')
            ).values_list('category_code', flat=True))
            return [str(c).strip() for c in codes if c]
        except Exception:
            return []

    def __init__(self, station_name: Optional[str] = None, allowed_stations: Optional[List[str]] = None):
        self.station_name = station_name
        self.allowed_stations = allowed_stations

    @classmethod
    def get_road_accident_query(cls) -> Q:
        """
        Constructs the dynamic database Q filter to find all Road Accident cases
        across database categories, module keys, sub-categories, titles, and extra fields.
        """
        dynamic_codes = cls.get_road_accident_category_codes()
        q_filter = (
            Q(module_key__iexact='accident')
            | Q(module_key__iexact='road_accident')
            | Q(module_key__iexact='road accident')
            | Q(module_key__iexact='dar')
            | Q(sub_category__icontains='accident')
            | Q(sub_category__icontains='rash')
            | Q(sub_category__icontains='road')
            | Q(category_links__category__category_name__icontains='accident')
            | Q(extra_fields__has_key='acc_dar')
            | Q(extra_fields__has_key='acc_dar_date')
            | Q(extra_fields__has_key='acc_irad')
            | Q(extra_fields__has_key='accident_datetime')
            | Q(extra_fields__has_key='accident_spot')
            | Q(title__icontains='accident')
            | Q(title__icontains='rash driving')
        )
        if dynamic_codes:
            q_filter |= Q(category_links__category__category_code__in=dynamic_codes)
        return q_filter

    def get_base_queryset(self):
        """Returns scoped CaseRecord queryset for road accident cases."""
        q_filter = self.get_road_accident_query()
        queryset = CaseRecord.objects.filter(q_filter).distinct()

        if self.station_name:
            queryset = queryset.filter(station_name__iexact=self.station_name)
        elif self.allowed_stations is not None:
            queryset = queryset.filter(station_name__in=self.allowed_stations)

        return queryset

    @classmethod
    def evaluate_case_dar(cls, case: CaseRecord) -> Dict[str, Any]:
        """
        Evaluates DAR form status for a single road accident CaseRecord.
        
        Business Logic:
        - If all required DAR fields are marked 'Yes', consider DAR as Filled/Completed.
        - If any required DAR field is marked 'No', consider DAR as Pending.
        - If no DAR fields are answered or field is blank/null, consider DAR as Pending.
        - Status color: Green for Filled, Red for Pending.
        """
        extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
        dar_fields: Dict[str, Any] = {}

        # 1. Primary DAR fields
        if 'acc_dar' in extra:
            dar_fields['acc_dar'] = extra.get('acc_dar')
        if 'acc_dar_date' in extra:
            dar_fields['acc_dar_date'] = extra.get('acc_dar_date')
        if 'dar_date' in extra:
            dar_fields['dar_date'] = extra.get('dar_date')

        # 2. Check for nested 'dar_form' or 'dar_fields' or explicit dar_* keys
        nested_dar = extra.get('dar_form') or extra.get('dar_fields') or {}
        if isinstance(nested_dar, dict):
            for k, v in nested_dar.items():
                dar_fields[k] = v

        for k, v in extra.items():
            if 'dar' in k.lower() and k not in dar_fields:
                dar_fields[k] = v

        # 3. Dynamic template fields for DAR
        # Find any FieldTemplateField configured for DAR (e.g. in Road Accident Extra Template)
        try:
            template_dar_fields = list(
                FieldTemplateField.objects.filter(
                    Q(field_key__icontains='dar') | Q(section__icontains='dar')
                ).values('field_key', 'is_required', 'field_label')
            )
        except Exception:
            template_dar_fields = []

        # Required fields check
        required_keys = []
        for tf in template_dar_fields:
            if tf.get('is_required'):
                required_keys.append(tf['field_key'])

        # Always include acc_dar as primary evaluation key if no template fields are marked required
        if not required_keys:
            required_keys = ['acc_dar']

        # Determine Filled vs Pending
        # Rule 2: If all required DAR fields are marked "Yes", consider the DAR as Filled/Completed.
        # Rule 3: If any required DAR field is marked "No", consider the DAR as Pending.
        has_any_no = False
        all_required_yes = True
        answered_count = 0

        # Check required fields
        for rk in required_keys:
            val = dar_fields.get(rk) or extra.get(rk)
            if val is not None and str(val).strip() != '':
                answered_count += 1
                if is_falsy_no(val):
                    has_any_no = True
                    all_required_yes = False
                elif not is_truthy_yes(val):
                    all_required_yes = False
            else:
                all_required_yes = False

        # Also inspect any extra DAR fields that were filled
        for k, val in dar_fields.items():
            if k in ['acc_dar_date', 'dar_date', 'dar_status_color']:
                continue
            if val is not None and str(val).strip() != '':
                if is_falsy_no(val):
                    has_any_no = True

        # Rule 2: If all required DAR fields are marked "Yes", consider the DAR as Filled/Completed.
        # Rule 3: If any required DAR field is marked "No", consider the DAR as Pending.
        if has_any_no:
            final_status = STATUS_PENDING
        elif all_required_yes and answered_count > 0:
            final_status = STATUS_FILLED
        else:
            final_status = STATUS_PENDING

        status_color = COLOR_FILLED if final_status == STATUS_FILLED else COLOR_PENDING

        dar_date = (
            dar_fields.get('acc_dar_date')
            or dar_fields.get('dar_date')
            or extra.get('acc_dar_date')
            or extra.get('dar_date')
            or None
        )

        return {
            'status': final_status,
            'status_color': status_color,
            'dar_date': str(dar_date) if dar_date else None,
            'dar_fields': dar_fields,
            'can_remind': (final_status == STATUS_PENDING),
        }

    def get_summary_statistics(self) -> Dict[str, int]:
        """
        Calculates dynamic summary cards:
        - Total DAR
        - DAR Form Filled
        - DAR Form Pending
        """
        cases = self.get_base_queryset()
        total_dar = 0
        dar_filled = 0
        dar_pending = 0

        for case in cases:
            total_dar += 1
            eval_result = self.evaluate_case_dar(case)
            if eval_result['status'] == STATUS_FILLED:
                dar_filled += 1
            else:
                dar_pending += 1

        return {
            'total_dar': total_dar,
            'dar_filled': dar_filled,
            'dar_pending': dar_pending,
        }

    def get_cases_data(self, status_filter: Optional[str] = None, search: Optional[str] = None) -> Tuple[Dict[str, int], List[Dict[str, Any]]]:
        """
        Fetches all road accident cases, evaluates DAR status, applies filters,
        and returns summary statistics and serialized rows for the table.
        """
        cases = self.get_base_queryset().order_by('-created_at')
        from apps.cases.serializers import DarCaseRecordSerializer

        summary = {
            'total_dar': 0,
            'dar_filled': 0,
            'dar_pending': 0,
        }

        evaluated_rows: List[Dict[str, Any]] = []

        for case in cases:
            summary['total_dar'] += 1
            eval_result = self.evaluate_case_dar(case)

            if eval_result['status'] == STATUS_FILLED:
                summary['dar_filled'] += 1
            else:
                summary['dar_pending'] += 1

            # Filter by status if requested
            if status_filter:
                st_clean = status_filter.strip().lower()
                if st_clean in ['pending', 'open'] and eval_result['status'] != STATUS_PENDING:
                    continue
                elif st_clean in ['filled', 'completed'] and eval_result['status'] != STATUS_FILLED:
                    continue

            # Search filter if requested
            if search:
                s_lower = search.strip().lower()
                case_no = str(case.case_number or '').lower()
                io = str(case.assigned_officer or '').lower()
                title = str(case.title or '').lower()
                station = str(case.station_name or '').lower()
                if s_lower not in case_no and s_lower not in io and s_lower not in title and s_lower not in station:
                    continue

            # Serialize using DarCaseRecordSerializer
            serializer = DarCaseRecordSerializer(case, context={'dar_eval': eval_result})
            evaluated_rows.append(serializer.data)

        # Assign serial numbers
        for idx, row in enumerate(evaluated_rows):
            row['sr_no'] = idx + 1

        return summary, evaluated_rows
