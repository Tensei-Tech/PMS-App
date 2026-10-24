from decimal import Decimal, ROUND_HALF_UP
from typing import Dict, Any, Optional
from django.db.models import QuerySet, Sum, Q
from apps.muddemal.models import MuddemalProperty, MuddemalRegister


def compute_item_value(
    quantity: Any,
    unit_value: Any,
    manual_total: Optional[Any] = None
) -> Decimal:
    """
    Computes total item value safely using Decimal arithmetic.
    If manual_total is provided and > 0, it takes precedence.
    Otherwise Quantity x Unit Value is calculated.
    """
    try:
        if manual_total is not None and Decimal(str(manual_total)) > 0:
            return Decimal(str(manual_total)).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    except Exception:
        pass

    try:
        qty = Decimal(str(quantity or 1))
        u_val = Decimal(str(unit_value or 0))
        return (qty * u_val).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    except Exception:
        return Decimal('0.00')


def calculate_register_valuations(register: MuddemalRegister) -> Dict[str, Any]:
    """
    Computes comprehensive, mathematically rigorous valuation metrics for a Muddemal Register.
    Stolen property metrics are strictly segregated from general seized properties to prevent double counting.
    """
    properties = MuddemalProperty.objects.filter(muddemal_record=register)
    return calculate_property_set_valuations(properties)


def calculate_property_set_valuations(properties: QuerySet[MuddemalProperty]) -> Dict[str, Any]:
    """
    Computes aggregated valuation metrics across any filtered set of Muddemal properties.
    """
    stolen_statuses = [
        'Stolen – Not Recovered',
        'Recovered',
        'Partially Recovered',
    ]

    # Stolen items partition: either category is STOLEN_PROPERTY / RECOVERED_STOLEN_PROPERTY
    # or status is in stolen_statuses
    stolen_qs = properties.filter(
        Q(property_category__category_code__in=['STOLEN_PROPERTY', 'RECOVERED_STOLEN_PROPERTY']) |
        Q(property_status__in=stolen_statuses)
    )

    total_stolen_items_count = stolen_qs.count()

    total_stolen_value = Decimal('0.00')
    recovered_value = Decimal('0.00')
    partially_recovered_value = Decimal('0.00')
    returned_to_owner_value = Decimal('0.00')

    for p in stolen_qs:
        val = p.total_item_value or Decimal('0.00')
        total_stolen_value += val

        status = p.property_status
        if status == 'Recovered':
            recovered_value += val
        elif status == 'Partially Recovered':
            # Check extra_fields for specific recovered portion, else default to val
            extra = p.extra_fields if isinstance(p.extra_fields, dict) else {}
            part_val = extra.get('recovered_value') or extra.get('partial_recovered_amount')
            if part_val is not None:
                try:
                    p_rec = Decimal(str(part_val))
                    partially_recovered_value += p_rec
                    recovered_value += p_rec
                except Exception:
                    partially_recovered_value += val
                    recovered_value += val
            else:
                partially_recovered_value += val
                recovered_value += val
        elif status in ['Returned to Owner', 'Released on Supurdnama']:
            returned_to_owner_value += val
            recovered_value += val

    not_recovered_value = max(Decimal('0.00'), total_stolen_value - recovered_value)
    property_pending_recovery_value = not_recovered_value

    if total_stolen_value > 0:
        rec_pct_dec = (recovered_value / total_stolen_value) * Decimal('100.00')
        recovery_percentage_num = float(rec_pct_dec.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP))
        recovery_percentage_str = f"{recovery_percentage_num:.2f}%"
    else:
        recovery_percentage_num = 0.0
        recovery_percentage_str = "N/A"

    # Seized properties partition: items seized during raids/investigations
    # (Excludes purely stolen items that are not yet seized/recovered)
    seized_statuses = [
        'Seized',
        'Produced Before Court',
        'Sent to FSL',
        'FSL Report Pending',
        'Released on Supurdnama',
        'Returned to Owner',
        'Pending Disposal',
        'Disposed',
        'Destroyed',
    ]

    seized_qs = properties.filter(
        Q(property_status__in=seized_statuses) |
        Q(property_category__category_code__in=[
            'SEIZED_PROPERTY', 'WEAPON', 'VEHICLE', 'ALCOHOL', 'NARCOTIC',
            'GAMBLING', 'CASH', 'GOLD_SILVER', 'ELECTRONIC', 'DOCUMENTS',
            'BIOLOGICAL_SAMPLE', 'VISCERA', 'CHEMICAL_SAMPLE', 'FOOD_DRUG_SAMPLE',
            'FSL_SAMPLE', 'COURT_MUDDEMAL', 'UNCLAIMED_PROPERTY', 'OTHER'
        ])
    ).exclude(property_status='Stolen – Not Recovered')

    total_seized_value = Decimal('0.00')
    for p in seized_qs:
        total_seized_value += (p.total_item_value or Decimal('0.00'))

    # All items total registered value
    total_registered_value = sum((p.total_item_value or Decimal('0.00')) for p in properties)

    return {
        'total_items_count': properties.count(),
        'total_stolen_items_count': total_stolen_items_count,
        'total_stolen_value': float(total_stolen_value),
        'recovered_property_value': float(recovered_value),
        'not_recovered_property_value': float(not_recovered_value),
        'partially_recovered_property_value': float(partially_recovered_value),
        'returned_property_value': float(returned_to_owner_value),
        'property_pending_recovery_value': float(property_pending_recovery_value),
        'total_seized_property_value': float(total_seized_value),
        'total_registered_value': float(total_registered_value),
        'recovery_percentage': recovery_percentage_str,
        'recovery_percentage_numeric': recovery_percentage_num,
        'has_stolen_property': total_stolen_items_count > 0,
    }
