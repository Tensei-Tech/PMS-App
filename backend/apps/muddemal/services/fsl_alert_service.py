from datetime import date, datetime
from typing import List, Dict, Any, Optional
from django.db.models import QuerySet
from apps.muddemal.models import (
    MuddemalProperty,
    MuddemalFSLRecord,
    MuddemalConfig,
)


def get_fsl_thresholds() -> Dict[str, int]:
    """Fetch configurable FSL alert thresholds from database."""
    cfg = MuddemalConfig.objects.filter(config_key='fsl_alert_thresholds').first()
    if cfg and isinstance(cfg.config_value, dict):
        return {
            't1': int(cfg.config_value.get('threshold_1_days', 7)),
            't2': int(cfg.config_value.get('threshold_2_days', 15)),
            't3': int(cfg.config_value.get('threshold_3_days', 30)),
        }
    return {'t1': 7, 't2': 15, 't3': 30}


def get_fsl_alerts(
    station_name: Optional[str] = None,
    police_station_id: Optional[str] = None,
    io_name: Optional[str] = None,
    io_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Evaluates all active FSL pending conditions against configured thresholds.
    Returns:
    - send_pending: List of properties where FSL is required but not yet dispatched.
    - report_pending: List of properties dispatched to FSL but report is pending.
    - summary counts for 7, 15, and 30+ days.
    """
    thresholds = get_fsl_thresholds()
    today = date.today()

    properties_qs = MuddemalProperty.objects.select_related(
        'muddemal_record', 'property_category'
    ).prefetch_related('fsl_records')

    if station_name and station_name.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
        properties_qs = properties_qs.filter(muddemal_record__station_name=station_name)
    if police_station_id and police_station_id.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
        properties_qs = properties_qs.filter(muddemal_record__police_station_id=police_station_id)
    if io_name:
        properties_qs = properties_qs.filter(muddemal_record__investigating_officer_name__icontains=io_name)
    if io_id:
        properties_qs = properties_qs.filter(muddemal_record__investigating_officer_id=io_id)

    send_pending_alerts: List[Dict[str, Any]] = []
    report_pending_alerts: List[Dict[str, Any]] = []

    count_7_days = 0
    count_15_days = 0
    count_30_days = 0

    for prop in properties_qs:
        fsl_records = list(prop.fsl_records.all())

        # Condition 1: FSL Required = True, but no dispatch recorded
        if prop.fsl_required and len(fsl_records) == 0:
            ref_date = prop.seizure_date or (prop.created_at.date() if prop.created_at else today)
            days_pending = max(0, (today - ref_date).days)

            # Determine crossed threshold
            tier = 'normal'
            if days_pending >= thresholds['t3']:
                tier = 'critical_30'
                count_30_days += 1
            elif days_pending >= thresholds['t2']:
                tier = 'warning_15'
                count_15_days += 1
            elif days_pending >= thresholds['t1']:
                tier = 'alert_7'
                count_7_days += 1

            send_pending_alerts.append({
                'property_id': prop.id,
                'property_uid': prop.property_uid,
                'category_name': prop.property_category.category_name,
                'description': prop.description,
                'cr_number': prop.muddemal_record.cr_number_snapshot,
                'station_name': prop.muddemal_record.station_name,
                'io_name': prop.muddemal_record.investigating_officer_name or 'Unassigned',
                'io_id': prop.muddemal_record.investigating_officer_id or '',
                'alert_type': 'FSL_SEND_PENDING',
                'alert_title': f"FSL Dispatch Pending ({days_pending} days)",
                'days_pending': days_pending,
                'threshold_tier': tier,
                'reference_date': str(ref_date),
            })

        # Condition 2: FSL records exist, check if latest dispatch report is pending
        for fsl in fsl_records:
            if fsl.report_received_status == 'Pending':
                disp_date = fsl.dispatch_date or today
                days_pending = max(0, (today - disp_date).days)

                tier = 'normal'
                if days_pending >= thresholds['t3']:
                    tier = 'critical_30'
                    count_30_days += 1
                elif days_pending >= thresholds['t2']:
                    tier = 'warning_15'
                    count_15_days += 1
                elif days_pending >= thresholds['t1']:
                    tier = 'alert_7'
                    count_7_days += 1

                report_pending_alerts.append({
                    'fsl_record_id': fsl.id,
                    'property_id': prop.id,
                    'property_uid': prop.property_uid,
                    'fsl_reference_no': fsl.fsl_reference_no,
                    'category_name': prop.property_category.category_name,
                    'description': prop.description,
                    'cr_number': prop.muddemal_record.cr_number_snapshot,
                    'station_name': prop.muddemal_record.station_name,
                    'io_name': prop.muddemal_record.investigating_officer_name or 'Unassigned',
                    'io_id': prop.muddemal_record.investigating_officer_id or '',
                    'alert_type': 'FSL_REPORT_PENDING',
                    'alert_title': f"FSL Report Pending: Ref {fsl.fsl_reference_no} ({days_pending} days)",
                    'days_pending': days_pending,
                    'threshold_tier': tier,
                    'dispatch_date': str(disp_date),
                })

    # Sort alerts by days_pending descending (most urgent first)
    send_pending_alerts.sort(key=lambda x: x['days_pending'], reverse=True)
    report_pending_alerts.sort(key=lambda x: x['days_pending'], reverse=True)

    return {
        'thresholds': thresholds,
        'summary': {
            'total_alerts': len(send_pending_alerts) + len(report_pending_alerts),
            'total_send_pending': len(send_pending_alerts),
            'total_report_pending': len(report_pending_alerts),
            'critical_30_days': count_30_days,
            'warning_15_days': count_15_days,
            'alert_7_days': count_7_days,
        },
        'send_pending_alerts': send_pending_alerts,
        'report_pending_alerts': report_pending_alerts,
    }
