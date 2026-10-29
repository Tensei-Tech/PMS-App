import logging
from collections import defaultdict
from typing import Dict, List, Optional, Set
from django.db.models import Count, Q
from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategoryLink, CaseCategory

logger = logging.getLogger(__name__)


class CategoryIndex:
    """
    Every category (id, name, parent, active) loaded in one query, so twins and
    sub-tab trees are worked out in memory instead of with a query per node.
    Build one per request and pass it to the helpers below.
    """

    def __init__(self):
        self._names: Dict[int, str] = {}
        self._active_by_name: Dict[str, List[int]] = defaultdict(list)
        self._active_children: Dict[int, List[int]] = defaultdict(list)
        rows = CaseCategory.objects.values_list('category_id', 'category_name', 'parent_category_id', 'is_active')
        for cid, name, parent_id, active in rows:
            self._names[cid] = name or ''
            if active:
                self._active_by_name[(name or '').strip().lower()].append(cid)
                if parent_id is not None:
                    self._active_children[parent_id].append(cid)

    def twins(self, category_id: int) -> List[int]:
        if category_id not in self._names:
            return [category_id]
        ids = list(self._active_by_name.get(self._names[category_id].strip().lower(), []))
        if category_id not in ids:
            ids.append(category_id)
        return ids

    def active_children(self, category_id: int) -> List[int]:
        return list(self._active_children.get(category_id, []))


def get_twin_category_ids(category_id: int, index: Optional[CategoryIndex] = None) -> List[int]:
    """
    Given a category_id, returns the IDs of all "twin" categories (same category_name,
    case-insensitive, including itself) across groups and standalone tabs.
    Does not hardcode IDs.
    """
    return (index or CategoryIndex()).twins(category_id)


def get_descendant_category_ids(category_id: int, index: Optional[CategoryIndex] = None) -> List[int]:
    """
    Recursively finds all category IDs in the subtree under `category_id` (including itself)
    and all twin categories across standalone and group copies.
    Handles nested sub-tabs (e.g. Accident -> Normal Accident / Road Accident -> Death Due to Rash Driving)
    by expanding children across all twin parent rows.
    """
    index = index or CategoryIndex()
    all_category_ids: Set[int] = set()
    to_process: List[int] = index.twins(category_id)
    all_category_ids.update(to_process)

    while to_process:
        current_id = to_process.pop()
        for cid in index.active_children(current_id):
            for t_cid in index.twins(cid):
                if t_cid not in all_category_ids:
                    all_category_ids.add(t_cid)
                    to_process.append(t_cid)

    return list(all_category_ids)


def get_group_counters(group_id: int, station_name: Optional[str] = None) -> Dict[str, int]:
    """
    Calculates live Total/Pending/Disposal counters for a Group (e.g. '1 to 5' or 'Part 6'),
    including all nested sub-tabs and their twin categories.
    """
    try:
        group_cat_ids = list(
            CaseCategory.objects.filter(group_id=group_id, is_active=True).values_list('category_id', flat=True)
        )
        all_cat_ids: Set[int] = set()
        index = CategoryIndex()
        for cat_id in group_cat_ids:
            all_cat_ids.update(get_descendant_category_ids(cat_id, index))

        from apps.cases.constants import DISPOSAL_KEYS
        from django.db.models.functions import Coalesce, Concat
        from django.db import models, connection
        from django.db.models import Value
        from django.db.models.fields.json import KeyTextTransform
        
        queryset = CaseRecord.objects.filter(
            category_links__category_id__in=list(all_cat_ids)
        )
        if station_name:
            queryset = queryset.filter(station_name=station_name)

        if connection.vendor == 'postgresql':
            concat_args = [
                Coalesce(KeyTextTransform(key, 'extra_fields'), Value(''), output_field=models.CharField())
                for key in DISPOSAL_KEYS
            ]
            queryset = queryset.annotate(all_cc_st=Concat(*concat_args, output_field=models.CharField()))
            stats = queryset.aggregate(
                total=Count('id', distinct=True),
                pending=Count('id', filter=~Q(all_cc_st__regex=r'\S') & ~Q(status__iexact='Disposal') & ~Q(status__iexact='Closed'), distinct=True),
                disposal=Count('id', filter=Q(all_cc_st__regex=r'\S') | Q(status__iexact='Disposal') | Q(status__iexact='Closed'), distinct=True),
            )
        else:
            disposal_q = Q(status__iexact='Disposal') | Q(status__iexact='Closed')
            for key in DISPOSAL_KEYS[:8]:
                disposal_q |= Q(**{f'extra_fields__{key}__isnull': False}) & ~Q(**{f'extra_fields__{key}': ''})
            stats = queryset.aggregate(
                total=Count('id', distinct=True),
                disposal=Count('id', filter=disposal_q, distinct=True),
            )
            total_cnt = stats['total'] or 0
            disp_cnt = stats['disposal'] or 0
            stats['pending'] = max(0, total_cnt - disp_cnt)

        return {
            'group_id': group_id,
            'total': stats['total'] or 0,
            'pending': stats['pending'] or 0,
            'disposal': stats['disposal'] or 0,
        }
    except Exception as e:
        logger.warning(f"[counter_service] Error computing group counters for {group_id}: {e}")
        return {
            'group_id': group_id,
            'total': 0,
            'pending': 0,
            'disposal': 0,
        }


def get_category_counters(category_id: int, station_name: Optional[str] = None,
                          index: Optional[CategoryIndex] = None) -> Dict[str, int]:
    """
    Calculates live Total/Pending/Disposal counters for a specific Sub-tab / Category (e.g. 'Theft', 'Accident'),
    rolling up cases from all its twin categories and nested child sub-tabs.
    """
    try:
        from apps.cases.constants import DISPOSAL_KEYS
        from django.db.models.functions import Coalesce, Concat
        from django.db import models, connection
        from django.db.models import Value
        from django.db.models.fields.json import KeyTextTransform
        
        descendant_ids = get_descendant_category_ids(category_id, index)
        queryset = CaseRecord.objects.filter(
            category_links__category_id__in=descendant_ids
        )
        if station_name:
            queryset = queryset.filter(station_name=station_name)

        if connection.vendor == 'postgresql':
            concat_args = [
                Coalesce(KeyTextTransform(key, 'extra_fields'), Value(''), output_field=models.CharField())
                for key in DISPOSAL_KEYS
            ]
            queryset = queryset.annotate(all_cc_st=Concat(*concat_args, output_field=models.CharField()))
            stats = queryset.aggregate(
                total=Count('id', distinct=True),
                pending=Count('id', filter=~Q(all_cc_st__regex=r'\S') & ~Q(status__iexact='Disposal') & ~Q(status__iexact='Closed'), distinct=True),
                disposal=Count('id', filter=Q(all_cc_st__regex=r'\S') | Q(status__iexact='Disposal') | Q(status__iexact='Closed'), distinct=True),
            )
        else:
            disposal_q = Q(status__iexact='Disposal') | Q(status__iexact='Closed')
            for key in DISPOSAL_KEYS[:8]:
                disposal_q |= Q(**{f'extra_fields__{key}__isnull': False}) & ~Q(**{f'extra_fields__{key}': ''})
            stats = queryset.aggregate(
                total=Count('id', distinct=True),
                disposal=Count('id', filter=disposal_q, distinct=True),
            )
            total_cnt = stats['total'] or 0
            disp_cnt = stats['disposal'] or 0
            stats['pending'] = max(0, total_cnt - disp_cnt)

        return {
            'category_id': category_id,
            'total': stats['total'] or 0,
            'pending': stats['pending'] or 0,
            'disposal': stats['disposal'] or 0,
        }
    except Exception as e:
        logger.warning(f"[counter_service] Error computing category counters for {category_id}: {e}")
        return {
            'category_id': category_id,
            'total': 0,
            'pending': 0,
            'disposal': 0,
        }

