from typing import Dict, List, Optional, Set
from django.db.models import Count, Q
from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategoryLink, CaseCategory


def get_descendant_category_ids(category_id: int) -> List[int]:
    """
    Recursively finds all category IDs in the subtree under `category_id` (including itself).
    """
    category_ids: Set[int] = {category_id}
    to_process: List[int] = [category_id]
    while to_process:
        current_id = to_process.pop()
        child_ids = list(
            CaseCategory.objects.filter(parent_category_id=current_id).values_list('category_id', flat=True)
        )
        for cid in child_ids:
            if cid not in category_ids:
                category_ids.add(cid)
                to_process.append(cid)
    return list(category_ids)


def get_group_counters(group_id: int, station_name: Optional[str] = None) -> Dict[str, int]:
    """
    Calculates live Total/Pending/Disposal counters for a Group (e.g. '1 to 5' or 'Part 6'),
    including all nested sub-tabs.
    """
    group_cat_ids = list(CaseCategory.objects.filter(group_id=group_id).values_list('category_id', flat=True))
    all_cat_ids: Set[int] = set()
    for cat_id in group_cat_ids:
        all_cat_ids.update(get_descendant_category_ids(cat_id))

    queryset = CaseRecord.objects.filter(
        category_links__category_id__in=list(all_cat_ids)
    )
    if station_name:
        queryset = queryset.filter(station_name=station_name)

    stats = queryset.aggregate(
        total=Count('id', distinct=True),
        pending=Count('id', filter=Q(status__iexact='Pending'), distinct=True),
        disposal=Count('id', filter=Q(status__in=['Disposal', 'Disposed', 'Closed']), distinct=True),
    )
    return {
        'group_id': group_id,
        'total': stats['total'] or 0,
        'pending': stats['pending'] or 0,
        'disposal': stats['disposal'] or 0,
    }


def get_category_counters(category_id: int, station_name: Optional[str] = None) -> Dict[str, int]:
    """
    Calculates live Total/Pending/Disposal counters for a specific Sub-tab / Category (e.g. 'Accident'),
    rolling up cases from all its nested child sub-tabs (e.g. 'Road Accident', 'Death Due to Rash Driving').
    """
    descendant_ids = get_descendant_category_ids(category_id)
    queryset = CaseRecord.objects.filter(
        category_links__category_id__in=descendant_ids
    )
    if station_name:
        queryset = queryset.filter(station_name=station_name)

    stats = queryset.aggregate(
        total=Count('id', distinct=True),
        pending=Count('id', filter=Q(status__iexact='Pending'), distinct=True),
        disposal=Count('id', filter=Q(status__in=['Disposal', 'Disposed', 'Closed']), distinct=True),
    )
    return {
        'category_id': category_id,
        'total': stats['total'] or 0,
        'pending': stats['pending'] or 0,
        'disposal': stats['disposal'] or 0,
    }
