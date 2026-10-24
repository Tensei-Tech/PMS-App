from datetime import date, datetime
from decimal import Decimal
from typing import Dict, Any, Optional, List
from django.db.models import QuerySet, Sum, Count, Q
from apps.muddemal.models import (
    MuddemalRegister,
    MuddemalProperty,
    MuddemalPropertyCategory,
    MuddemalFSLRecord,
    MuddemalDisposal,
)
from apps.muddemal.services.valuation_service import calculate_property_set_valuations
from apps.muddemal.services.fsl_alert_service import get_fsl_alerts


def _ensure_tenant_schema():
    from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema
    active = get_active_tenant_schema()
    if not active or active == 'public':
        set_tenant_schema('maharashtra')


def _apply_filters(
    qs: QuerySet,
    station_name: Optional[str] = None,
    police_station_id: Optional[str] = None,
    cr_number: Optional[str] = None,
    category_code: Optional[str] = None,
    io_name: Optional[str] = None,
    year: Optional[int] = None,
    month: Optional[int] = None,
    is_property_qs: bool = True
) -> QuerySet:
    _ensure_tenant_schema()
    prefix = 'muddemal_record__' if is_property_qs else ''

    if station_name and station_name.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
        qs = qs.filter(**{f"{prefix}station_name": station_name})
    if police_station_id and police_station_id.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
        qs = qs.filter(**{f"{prefix}police_station_id": police_station_id})
    if cr_number:
        qs = qs.filter(**{f"{prefix}cr_number_snapshot__icontains": cr_number})
    if io_name:
        qs = qs.filter(**{f"{prefix}investigating_officer_name__icontains": io_name})
    if is_property_qs and category_code:
        qs = qs.filter(property_category__category_code=category_code)
    if year:
        date_field = 'created_at__year' if is_property_qs else 'registration_date__year'
        qs = qs.filter(**{date_field: int(year)})
    if month:
        date_field = 'created_at__month' if is_property_qs else 'registration_date__month'
        qs = qs.filter(**{date_field: int(month)})

    return qs


def get_stolen_property_dashboard(
    station_name: Optional[str] = None,
    police_station_id: Optional[str] = None,
    cr_number: Optional[str] = None,
    io_name: Optional[str] = None,
    year: Optional[int] = None,
    month: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Computes Stolen Property Dashboard aggregations:
    - Total Theft Cases
    - Total Stolen Value, Recovered Value, Not Recovered Value, Recovery %
    - Cases with 100% Recovery, Partial Recovery, Zero Recovery
    """
    registers_qs = MuddemalRegister.objects.all()
    registers_qs = _apply_filters(
        registers_qs, station_name, police_station_id, cr_number, None, io_name, year, month, is_property_qs=False
    )

    properties_qs = MuddemalProperty.objects.select_related('property_category', 'muddemal_record')
    properties_qs = _apply_filters(
        properties_qs, station_name, police_station_id, cr_number, None, io_name, year, month, is_property_qs=True
    )

    valuations = calculate_property_set_valuations(properties_qs)

    theft_registers = []
    cases_100_recovery = 0
    cases_partial_recovery = 0
    cases_zero_recovery = 0

    for reg in registers_qs:
        reg_props = properties_qs.filter(muddemal_record=reg)
        reg_val = calculate_property_set_valuations(reg_props)
        if reg_val['has_stolen_property'] or reg_val['total_stolen_value'] > 0:
            stolen_val = Decimal(str(reg_val['total_stolen_value']))
            rec_val = Decimal(str(reg_val['recovered_property_value']))

            if stolen_val > 0 and rec_val >= stolen_val:
                cases_100_recovery += 1
                rec_cat = '100%'
            elif rec_val > 0 and rec_val < stolen_val:
                cases_partial_recovery += 1
                rec_cat = 'Partial'
            else:
                cases_zero_recovery += 1
                rec_cat = 'Zero'

            theft_registers.append({
                'register_id': reg.id,
                'register_no': reg.muddemal_register_no,
                'cr_number': reg.cr_number_snapshot,
                'station_name': reg.station_name,
                'io_name': reg.investigating_officer_name or 'Unassigned',
                'registration_date': str(reg.registration_date),
                'total_stolen_value': reg_val['total_stolen_value'],
                'recovered_property_value': reg_val['recovered_property_value'],
                'not_recovered_property_value': reg_val['not_recovered_property_value'],
                'recovery_percentage': reg_val['recovery_percentage'],
                'recovery_category': rec_cat,
            })

    total_theft_cases = len(theft_registers)

    return {
        'total_theft_cases': total_theft_cases,
        'total_stolen_property_value': valuations['total_stolen_value'],
        'recovered_property_value': valuations['recovered_property_value'],
        'not_recovered_property_value': valuations['not_recovered_property_value'],
        'partially_recovered_property_value': valuations['partially_recovered_property_value'],
        'returned_property_value': valuations['returned_property_value'],
        'property_pending_recovery_value': valuations['property_pending_recovery_value'],
        'recovery_percentage': valuations['recovery_percentage'],
        'recovery_percentage_numeric': valuations['recovery_percentage_numeric'],
        'cases_with_100_recovery': cases_100_recovery,
        'cases_with_partial_recovery': cases_partial_recovery,
        'cases_with_zero_recovery': cases_zero_recovery,
        'cases_list': theft_registers,
    }


def get_seized_property_dashboard(
    station_name: Optional[str] = None,
    police_station_id: Optional[str] = None,
    cr_number: Optional[str] = None,
    io_name: Optional[str] = None,
    year: Optional[int] = None,
    month: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Computes Seized Property Dashboard aggregations across all 21 categories:
    - Total Seized Property Value
    - Category-wise counts and monetary values
    """
    properties_qs = MuddemalProperty.objects.select_related('property_category', 'muddemal_record')
    properties_qs = _apply_filters(
        properties_qs, station_name, police_station_id, cr_number, None, io_name, year, month, is_property_qs=True
    )

    valuations = calculate_property_set_valuations(properties_qs)

    categories = MuddemalPropertyCategory.objects.filter(is_active=True).order_by('display_order')
    category_breakdown = []

    for cat in categories:
        cat_props = properties_qs.filter(property_category=cat)
        cnt = cat_props.count()
        total_val = sum((p.total_item_value or Decimal('0.00')) for p in cat_props)

        category_breakdown.append({
            'category_code': cat.category_code,
            'category_name': cat.category_name,
            'count': cnt,
            'total_value': float(total_val),
        })

    def _cat_summary(code: str) -> Dict[str, Any]:
        match = next((c for c in category_breakdown if c['category_code'] == code), None)
        return match or {'category_code': code, 'category_name': code, 'count': 0, 'total_value': 0.0}

    return {
        'total_seized_property_value': valuations['total_seized_property_value'],
        'total_items_count': valuations['total_items_count'],
        'vehicles_seized': _cat_summary('VEHICLE'),
        'weapons_seized': _cat_summary('WEAPON'),
        'mobile_electronic_devices': _cat_summary('ELECTRONIC'),
        'alcohol_prohibition_property': _cat_summary('ALCOHOL'),
        'gambling_property': _cat_summary('GAMBLING'),
        'cash_currency': _cat_summary('CASH'),
        'gold_silver_jewellery': _cat_summary('GOLD_SILVER'),
        'narcotic_contraband': _cat_summary('NARCOTIC'),
        'biological_samples': _cat_summary('BIOLOGICAL_SAMPLE'),
        'viscera_samples': _cat_summary('VISCERA'),
        'fsl_samples': _cat_summary('FSL_SAMPLE'),
        'chemical_samples': _cat_summary('CHEMICAL_SAMPLE'),
        'food_drug_samples': _cat_summary('FOOD_DRUG_SAMPLE'),
        'documents': _cat_summary('DOCUMENTS'),
        'court_muddemal': _cat_summary('COURT_MUDDEMAL'),
        'unclaimed_unknown_property': _cat_summary('UNCLAIMED_PROPERTY'),
        'other_property': _cat_summary('OTHER'),
        'all_categories_breakdown': category_breakdown,
    }


def get_pending_muddemal_dashboard(
    station_name: Optional[str] = None,
    police_station_id: Optional[str] = None,
    cr_number: Optional[str] = None,
    io_name: Optional[str] = None,
    year: Optional[int] = None,
    month: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Computes Pending Muddemal Dashboard metrics:
    - FSL Send Pending
    - FSL Report Pending
    - Disposal Pending
    - Property Awaiting Owner Release
    - Property Awaiting Court Order
    - Vehicles Pending Disposal
    - Long-Pending Muddemal (>30, >90, >180 days)
    - Property Without Valuation
    """
    properties_qs = MuddemalProperty.objects.select_related('property_category', 'muddemal_record')
    properties_qs = _apply_filters(
        properties_qs, station_name, police_station_id, cr_number, None, io_name, year, month, is_property_qs=True
    )

    fsl_data = get_fsl_alerts(station_name, police_station_id, io_name)

    disposal_pending_qs = properties_qs.filter(property_status__in=['Pending Disposal', 'Seized', 'Produced Before Court'])
    awaiting_owner_release_qs = properties_qs.filter(property_status__in=['Recovered', 'Released on Supurdnama'])
    awaiting_court_order_qs = properties_qs.filter(property_status='Produced Before Court')
    vehicles_pending_disposal_qs = properties_qs.filter(
        property_category__category_code='VEHICLE',
        property_status__in=['Seized', 'Pending Disposal', 'Produced Before Court']
    )
    without_valuation_qs = properties_qs.filter(Q(total_item_value=0) | Q(valuation_status='Pending'))

    today = date.today()
    long_pending_30 = 0
    long_pending_90 = 0
    long_pending_180 = 0

    for p in properties_qs.exclude(property_status__in=['Disposed', 'Destroyed', 'Returned to Owner']):
        ref = p.seizure_date or (p.created_at.date() if p.created_at else today)
        days = (today - ref).days
        if days >= 180:
            long_pending_180 += 1
            long_pending_90 += 1
            long_pending_30 += 1
        elif days >= 90:
            long_pending_90 += 1
            long_pending_30 += 1
        elif days >= 30:
            long_pending_30 += 1

    return {
        'fsl_send_pending_count': fsl_data['summary']['total_send_pending'],
        'fsl_report_pending_count': fsl_data['summary']['total_report_pending'],
        'disposal_pending_count': disposal_pending_qs.count(),
        'awaiting_owner_release_count': awaiting_owner_release_qs.count(),
        'awaiting_court_order_count': awaiting_court_order_qs.count(),
        'vehicles_pending_disposal_count': vehicles_pending_disposal_qs.count(),
        'long_pending_over_30_days': long_pending_30,
        'long_pending_over_90_days': long_pending_90,
        'long_pending_over_180_days': long_pending_180,
        'property_without_valuation_count': without_valuation_qs.count(),
        'fsl_alerts_summary': fsl_data['summary'],
    }


def get_month_year_reports(
    station_name: Optional[str] = None,
    police_station_id: Optional[str] = None,
    year: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Computes Month-wise and Year-wise comparative trend reports:
    - Month
    - Total Stolen Value
    - Recovered Value
    - Not Recovered Value
    - Recovery Percentage
    - Seized Property Value
    - Pending Property Counts
    """
    target_year = year or datetime.now().year
    month_names = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
    ]

    base_props = MuddemalProperty.objects.select_related('property_category', 'muddemal_record')
    if station_name and station_name.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
        base_props = base_props.filter(muddemal_record__station_name=station_name)
    if police_station_id and police_station_id.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
        base_props = base_props.filter(muddemal_record__police_station_id=police_station_id)

    year_props = base_props.filter(created_at__year=target_year)

    monthly_data = []
    for m_idx in range(1, 13):
        m_props = year_props.filter(created_at__month=m_idx)
        val = calculate_property_set_valuations(m_props)

        pending_count = m_props.exclude(property_status__in=['Disposed', 'Destroyed', 'Returned to Owner']).count()

        monthly_data.append({
            'month_number': m_idx,
            'month_name': month_names[m_idx - 1],
            'total_stolen_value': val['total_stolen_value'],
            'recovered_value': val['recovered_property_value'],
            'not_recovered_value': val['not_recovered_property_value'],
            'recovery_percentage': val['recovery_percentage'],
            'recovery_percentage_numeric': val['recovery_percentage_numeric'],
            'seized_property_value': val['total_seized_property_value'],
            'pending_property_count': pending_count,
            'total_items_count': val['total_items_count'],
        })

    year_valuation = calculate_property_set_valuations(year_props)

    # Past 3 years trend comparison
    yearly_data = []
    current_yr = datetime.now().year
    for yr in range(current_yr - 2, current_yr + 1):
        y_props = base_props.filter(created_at__year=yr)
        y_val = calculate_property_set_valuations(y_props)
        y_pending = y_props.exclude(property_status__in=['Disposed', 'Destroyed', 'Returned to Owner']).count()
        yearly_data.append({
            'year': yr,
            'total_stolen_value': y_val['total_stolen_value'],
            'recovered_value': y_val['recovered_property_value'],
            'not_recovered_value': y_val['not_recovered_property_value'],
            'recovery_percentage': y_val['recovery_percentage'],
            'recovery_percentage_numeric': y_val['recovery_percentage_numeric'],
            'seized_property_value': y_val['total_seized_property_value'],
            'pending_property_count': y_pending,
            'total_items_count': y_val['total_items_count'],
        })

    return {
        'selected_year': target_year,
        'year_summary': year_valuation,
        'monthly_report': monthly_data,
        'yearly_comparison': yearly_data,
    }
