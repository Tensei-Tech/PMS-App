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


class RoadAccidentIradService:
    """
    Dedicated Business Logic Service for IRAD (Integrated Road Accident Database)
    under Road Accident cases.

    Rules:
    1. Identifies all Road Accident cases dynamically from database.
    2. If all required IRAD fields are marked 'Yes', IRAD is Filled/Completed.
    3. If any required IRAD field is marked 'No', IRAD is Pending.
    4. Pending status color is Red (#E74C3C), Filled/Completed is Green (#2ECC71).
    5. Calculates Total IRAD, IRAD Form Filled, and IRAD Form Pending dynamically.
    6. Sends reminder notifications to the assigned IO for pending IRAD forms.
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
            | Q(module_key__iexact='irad')
            | Q(module_key__iexact='dar')
            | Q(sub_category__icontains='accident')
            | Q(sub_category__icontains='rash')
            | Q(sub_category__icontains='road')
            | Q(category_links__category__category_name__icontains='accident')
            | Q(extra_fields__has_key='acc_irad')
            | Q(extra_fields__has_key='acc_irad_date')
            | Q(extra_fields__has_key='acc_dar')
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
    def evaluate_case_irad(cls, case: CaseRecord) -> Dict[str, Any]:
        """
        Evaluates IRAD form status for a single road accident CaseRecord.
        
        Business Logic:
        - If all required IRAD fields are marked 'Yes', consider IRAD as Filled/Completed.
        - If any required IRAD field is marked 'No', consider IRAD as Pending.
        - If no IRAD fields are answered or field is blank/null, consider IRAD as Pending.
        - Status color: Green for Filled, Red for Pending.
        """
        extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
        irad_fields: Dict[str, Any] = {}

        # 1. Primary IRAD fields
        if 'acc_irad' in extra:
            irad_fields['acc_irad'] = extra.get('acc_irad')
        if 'acc_irad_date' in extra:
            irad_fields['acc_irad_date'] = extra.get('acc_irad_date')
        if 'irad_date' in extra:
            irad_fields['irad_date'] = extra.get('irad_date')

        # 2. Check for nested 'irad_form' or 'irad_fields' or explicit irad_* keys
        nested_irad = extra.get('irad_form') or extra.get('irad_fields') or {}
        if isinstance(nested_irad, dict):
            for k, v in nested_irad.items():
                irad_fields[k] = v

        for k, v in extra.items():
            if 'irad' in k.lower() and k not in irad_fields:
                irad_fields[k] = v

        # 3. Dynamic template fields for IRAD
        try:
            template_irad_fields = list(
                FieldTemplateField.objects.filter(
                    Q(field_key__icontains='irad') | Q(section__icontains='irad')
                ).values('field_key', 'is_required', 'field_label')
            )
        except Exception:
            template_irad_fields = []

        # Required fields check
        required_keys = []
        for tf in template_irad_fields:
            if tf.get('is_required'):
                required_keys.append(tf['field_key'])

        # Always include acc_irad as primary evaluation key if no template fields are marked required
        if not required_keys:
            required_keys = ['acc_irad']

        # Determine Filled vs Pending
        # Rule 2: If all required IRAD fields are marked "Yes", consider IRAD as Filled/Completed.
        # Rule 3: If any required IRAD field is marked "No", consider IRAD as Pending.
        has_any_no = False
        all_required_yes = True
        answered_count = 0

        # Check required fields
        for rk in required_keys:
            val = irad_fields.get(rk) or extra.get(rk)
            if val is not None and str(val).strip() != '':
                answered_count += 1
                if is_falsy_no(val):
                    has_any_no = True
                    all_required_yes = False
                elif not is_truthy_yes(val):
                    all_required_yes = False
            else:
                all_required_yes = False

        # Also inspect any extra IRAD fields that were filled
        for k, val in irad_fields.items():
            if k in ['acc_irad_date', 'irad_date', 'irad_status_color']:
                continue
            if val is not None and str(val).strip() != '':
                if is_falsy_no(val):
                    has_any_no = True

        # Rule 2: If all required IRAD fields are marked "Yes", consider the IRAD as Filled/Completed.
        # Rule 3: If any required IRAD field is marked "No", consider the IRAD as Pending.
        if has_any_no:
            final_status = STATUS_PENDING
        elif all_required_yes and answered_count > 0:
            final_status = STATUS_FILLED
        else:
            final_status = STATUS_PENDING

        is_filled = (final_status == STATUS_FILLED)
        status_color = COLOR_FILLED if is_filled else COLOR_PENDING

        return {
            'status': final_status,
            'is_filled': is_filled,
            'status_color': status_color,
            'can_remind': not is_filled,
            'irad_fields': irad_fields,
            'irad_date': irad_fields.get('acc_irad_date') or irad_fields.get('irad_date') or '',
            'answered_count': answered_count,
            'has_any_no': has_any_no,
        }

    def get_summary_statistics(self) -> Dict[str, int]:
        """
        Dynamically computes:
        - Total IRAD
        - IRAD Form Filled
        - IRAD Form Pending
        """
        queryset = self.get_base_queryset()

        total_irad = 0
        irad_filled = 0
        irad_pending = 0

        for case in queryset:
            total_irad += 1
            eval_res = self.evaluate_case_irad(case)
            if eval_res['is_filled']:
                irad_filled += 1
            else:
                irad_pending += 1

        return {
            'total_irad': total_irad,
            'irad_form_filled': irad_filled,
            'irad_form_pending': irad_pending,
            # Aliases for backward & frontend flexibility
            'irad_filled': irad_filled,
            'irad_pending': irad_pending,
            'total': total_irad,
            'filled': irad_filled,
            'pending': irad_pending,
        }

    def get_cases_data(self, status_filter: Optional[str] = None, search: Optional[str] = None) -> Tuple[Dict[str, int], List[Dict[str, Any]]]:
        """
        Fetches all road accident cases, evaluates IRAD status, applies filters,
        and returns summary statistics and serialized rows for the table.
        """
        cases = self.get_base_queryset().order_by('-created_at')
        from apps.cases.serializers import IradCaseRecordSerializer

        summary = {
            'total_irad': 0,
            'irad_filled': 0,
            'irad_pending': 0,
            'irad_form_filled': 0,
            'irad_form_pending': 0,
        }

        evaluated_rows: List[Dict[str, Any]] = []

        for case in cases:
            summary['total_irad'] += 1
            eval_result = self.evaluate_case_irad(case)

            if eval_result['status'] == STATUS_FILLED:
                summary['irad_filled'] += 1
                summary['irad_form_filled'] += 1
            else:
                summary['irad_pending'] += 1
                summary['irad_form_pending'] += 1

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

            # Serialize using IradCaseRecordSerializer
            serializer = IradCaseRecordSerializer(case, context={'irad_eval': eval_result})
            evaluated_rows.append(serializer.data)

        # Assign serial numbers
        for idx, row in enumerate(evaluated_rows):
            row['sr_no'] = idx + 1

        return summary, evaluated_rows

