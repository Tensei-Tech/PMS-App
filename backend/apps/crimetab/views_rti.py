import io
import re
import datetime
import logging
from django.db import connection, transaction
from django.db.models import Q, Max, Count
from django.db.models.functions import Trim
from django.core.cache import cache
from django.core.exceptions import ValidationError
from django.core.validators import validate_email
from django.http import HttpResponse
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from apps.core.tenancy import TenantContext, get_active_tenant_schema
from apps.core.models import AuditLog
from apps.users.models import OfficerProfile
from apps.crimetab.models import RTIApplication, OptionValue, ModuleSetting, FieldTemplateField
from apps.crimetab.serializers_rti import RTIApplicationSerializer, RTIApplicationListSerializer, format_rti_serial

logger = logging.getLogger(__name__)


def _log_rti_audit(request, event, rti_id, changed_fields=None):
    try:
        user = getattr(request, 'user', None)
        uid = getattr(user, 'uid', None) or getattr(user, 'id', 'anonymous')
        name = getattr(user, 'name', None) or getattr(user, 'full_name', '')
        email = getattr(user, 'email', '')
        role = getattr(user, 'role_id', '')
        station = getattr(user, 'station_name', '')

        meta = {'rti_id': str(rti_id)}
        if changed_fields:
            meta['changed_fields'] = [str(f) for f in changed_fields]

        AuditLog.objects.create(
            event=event,
            category='rti',
            uid=str(uid),
            user_name=str(name),
            user_email=str(email),
            user_role=str(role),
            station_name=str(station),
            action_details=f"RTI event '{event}' on ID {rti_id}",
            metadata=meta
        )
    except Exception as e:
        logger.warning(f"[RTI AuditLog] Exception writing audit log: {e}")


def _resolve_tenant_and_auth(request, perm_key):
    user = getattr(request, 'user', None)
    is_anon = getattr(user, 'is_anonymous', False)
    if callable(is_anon):
        is_anon = is_anon()
    if not user or is_anon:
        return None, Response({'error': 'Authentication credentials were not provided.'}, status=status.HTTP_401_UNAUTHORIZED)

    target_schema = getattr(request, 'state_schema', None)
    if not target_schema or target_schema == 'public':
        target_schema = get_active_tenant_schema(request)

    if not target_schema or target_schema == 'public':
        user_state = getattr(user, 'state_code', None) or getattr(user, 'state_schema', None)
        if user_state and str(user_state).upper() != 'GLOBAL':
            from apps.core.middleware import _STATE_SCHEMA_CACHE
            target_schema = _STATE_SCHEMA_CACHE.get(str(user_state).upper(), str(user_state).lower())
        elif connection.vendor != 'postgresql':
            target_schema = 'public'
        else:
            return None, Response({'error': 'State tenant schema is required.'}, status=status.HTTP_400_BAD_REQUEST)

    # Permission check via module_settings
    enforce_setting = ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').first()
    enforce = (enforce_setting.setting_value.strip().lower() == 'true') if enforce_setting else False

    if enforce and perm_key:
        from apps.public_master.models import RolePermission
        has_perm = RolePermission.objects.filter(
            role_id=getattr(user, 'role_id', ''),
            permission_id=perm_key,
            is_granted=True
        ).exists()
        if not has_perm:
            return None, Response({'error': f'Permission {perm_key} is required.'}, status=status.HTTP_403_FORBIDDEN)

    return target_schema, None


def _get_setting(key, default):
    s = ModuleSetting.objects.filter(module_key='rti', setting_key=key).first()
    if s and s.setting_value is not None:
        val = s.setting_value.strip()
        if val.isdigit():
            return int(val)
        return val
    return default


def _get_scoped_officers_queryset(user):
    """
    Evaluates role scope hierarchy for the authenticated user based on module_settings:
    1. Station roles (scope_station_roles): active officers with same station_id.
       If user has no station_id, matches by trimmed station_name.
    2. Division roles (scope_division_roles): active officers with same division_id.
       If user has no division_id, matches by trimmed division_name.
    3. District roles (scope_district_roles): active officers with same district_id.
       If user has no district_id, matches by trimmed district name.
    4. State roles (scope_state_roles): all active officers of the state tenant schema.
    5. Other/unconfigured roles: empty queryset and no_scope_message.
    
    Never matches blank values. Strictly filters account_status='active'.
    Returns (queryset, error_message).
    """
    user_role = str(getattr(user, 'role_id', '') or '').strip()

    station_roles_str = str(_get_setting('scope_station_roles', 'officer,station_admin,station_head'))
    station_roles = [r.strip() for r in station_roles_str.split(',') if r.strip()]

    division_roles_str = str(_get_setting('scope_division_roles', 'division_admin,supervisor'))
    division_roles = [r.strip() for r in division_roles_str.split(',') if r.strip()]

    district_roles_str = str(_get_setting('scope_district_roles', 'district_admin'))
    district_roles = [r.strip() for r in district_roles_str.split(',') if r.strip()]

    state_roles_str = str(_get_setting('scope_state_roles', 'state_super_admin'))
    state_roles = [r.strip() for r in state_roles_str.split(',') if r.strip()]

    qs = OfficerProfile.objects.annotate(
        trimmed_station=Trim('station_name'),
        trimmed_division=Trim('division_name'),
        trimmed_district=Trim('district')
    ).filter(account_status='active')

    if user_role in station_roles:
        user_station_id = str(getattr(user, 'station_id', '') or '').strip()
        user_station_name = str(getattr(user, 'station_name', '') or '').strip()
        if user_station_id:
            return qs.filter(station_id=user_station_id), None
        elif user_station_name:
            return qs.filter(trimmed_station__iexact=user_station_name).exclude(trimmed_station=''), None
        else:
            msg = _get_setting('no_station_message', 'No police station assigned to the logged-in user.')
            return None, msg

    elif user_role in division_roles:
        user_division_id = str(getattr(user, 'division_id', '') or '').strip()
        user_division_name = str(getattr(user, 'division_name', '') or '').strip()
        if user_division_id:
            return qs.filter(division_id=user_division_id), None
        elif user_division_name:
            return qs.filter(trimmed_division__iexact=user_division_name).exclude(trimmed_division=''), None
        else:
            msg = _get_setting('no_division_message', 'No division assigned to the logged-in user.')
            return None, msg

    elif user_role in district_roles:
        user_district_id = str(getattr(user, 'district_id', '') or '').strip()
        user_district = str(getattr(user, 'district', '') or getattr(user, 'district_name', '') or '').strip()
        if user_district_id:
            return qs.filter(district_id=user_district_id), None
        elif user_district:
            return qs.filter(trimmed_district__iexact=user_district).exclude(trimmed_district=''), None
        else:
            msg = _get_setting('no_district_message', 'No district assigned to the logged-in user.')
            return None, msg

    elif user_role in state_roles:
        # State admin scope: all active officers of the state schema (station/division/district on profile are ignored)
        return qs, None

    else:
        msg = _get_setting('no_scope_message', 'User role does not have an officer assignment scope configured.')
        return None, msg


def _word_count(text):
    if not text:
        return 0
    return len(text.strip().split())


def _parse_rti_date(val):
    if not val:
        return None
    s = str(val).strip()
    if not s or s.lower() in ('null', 'none', '-', ''):
        return None
    for fmt in ('%Y-%m-%d', '%d/%m/%Y', '%d-%m-%Y', '%Y/%m/%d', '%d.%m.%Y', '%m/%d/%Y'):
        try:
            return datetime.datetime.strptime(s, fmt).date()
        except ValueError:
            pass
    try:
        from django.utils.dateparse import parse_date, parse_datetime
        d = parse_date(s)
        if d:
            return d
        dt = parse_datetime(s)
        if dt:
            return dt.date()
    except Exception:
        pass
    return None


class DisplayRow(list):
    """
    Represents an ordered (label, display_value) row.
    Inherits from list for JSON serialization and 2-element index access,
    while also exposing label, value properties and dict-like key access.
    """
    def __init__(self, label, value):
        super().__init__([label, value])

    @property
    def label(self):
        return self[0]

    @property
    def value(self):
        return self[1]

    def __getitem__(self, item):
        if item == 'label':
            return self[0]
        if item == 'value':
            return self[1]
        return super().__getitem__(item)

    def get(self, key, default=None):
        if key == 'label':
            return self[0]
        if key == 'value':
            return self[1]
        return default


def ensure_date_format_setting():
    """
    Reads 'date_format' from module_settings under module_key='rti'.
    If none exists, adds one row with default '%d/%m/%Y' and returns it.
    """
    with TenantContext('public'):
        s = ModuleSetting.objects.filter(module_key='rti', setting_key='date_format').first()
        if not s or not s.setting_value:
            ModuleSetting.objects.update_or_create(
                module_key='rti',
                setting_key='date_format',
                defaults={'setting_value': '%d/%m/%Y'}
            )
            return '%d/%m/%Y'
        return s.setting_value.strip()


def _is_valid_email(value):
    try:
        validate_email(value)
        return True
    except ValidationError:
        return False


def _format_rti_date(val, date_fmt):
    if not val:
        return ""
    fmt = date_fmt
    if '%' not in fmt:
        fmt = (
            fmt.replace('yyyy', '%Y')
               .replace('YYYY', '%Y')
               .replace('yy', '%y')
               .replace('YY', '%y')
               .replace('MM', '%m')
               .replace('dd', '%d')
               .replace('DD', '%d')
        )
    if isinstance(val, (datetime.date, datetime.datetime)):
        try:
            return val.strftime(fmt)
        except Exception:
            return val.strftime('%d/%m/%Y')
    s = str(val).strip()
    try:
        parts = s.split('-')
        if len(parts) == 3:
            d = datetime.date(int(parts[0]), int(parts[1]), int(parts[2]))
            return d.strftime(fmt)
    except Exception:
        pass
    parsed = _parse_rti_date(val)
    if parsed:
        try:
            return parsed.strftime(fmt)
        except Exception:
            return parsed.strftime('%d/%m/%Y')
    return s


def _format_rti_bool(val):
    if val is True:
        return "Yes"
    if val is False:
        return "No"
    return ""


def _safe_rti_str(val):
    if val is None:
        return ""
    s = str(val).strip()
    if s.lower() in ('none', 'null'):
        return ""
    return s


def get_rti_display_rows(rti, schema='public'):
    """
    Single source of truth: turns an application into an ordered list of
    (label, display value) rows, using field_template_fields for the labels
    and order, option_values for option text, module_settings for status labels,
    the serial format setting for the serial, and 'Name, Designation' for the officer.
    Dates are formatted using the date_format module setting.
    Booleans format as 'Yes' and 'No'.
    Blank values format as empty cell (''), never 'None'.
    Conditional fields are hidden when their parent value does not show them.
    """
    date_fmt = ensure_date_format_setting()

    with TenantContext('public'):
        serial_label = _safe_rti_str(ModuleSetting.objects.filter(module_key='rti', setting_key='serial_label').values_list('setting_value', flat=True).first()) or 'Sr. No.'
        status_label = _safe_rti_str(ModuleSetting.objects.filter(module_key='rti', setting_key='status_label').values_list('setting_value', flat=True).first()) or 'Status'
        status_pending = _safe_rti_str(ModuleSetting.objects.filter(module_key='rti', setting_key='status_pending_label').values_list('setting_value', flat=True).first()) or 'Pending'
        status_disposal = _safe_rti_str(ModuleSetting.objects.filter(module_key='rti', setting_key='status_disposal_label').values_list('setting_value', flat=True).first()) or 'Disposal'

        ftfs = list(FieldTemplateField.objects.filter(template__template_name='RTI Form').order_by('display_order'))

    serial_val = format_rti_serial(rti.serial_year, rti.serial_no)
    status_val = status_disposal if str(getattr(rti, 'status', '')).lower() == 'disposal' else status_pending

    if rti.assigned_officer_name and rti.assigned_officer_designation:
        officer_val = f"{rti.assigned_officer_name.strip()}, {rti.assigned_officer_designation.strip()}"
    elif rti.assigned_officer_name:
        officer_val = rti.assigned_officer_name.strip()
    elif rti.assigned_officer_designation:
        officer_val = rti.assigned_officer_designation.strip()
    else:
        officer_val = ""

    if rti.replied_date:
        outcome_val = 'Replied'
    elif rti.rejected_date or rti.rejection_reason:
        outcome_val = 'Rejected'
    elif rti.transferred_to and str(rti.transferred_to).strip():
        outcome_val = 'Transferred'
    else:
        outcome_val = ""

    attr_map = {
        'rti_received_date': _format_rti_date(rti.received_date, date_fmt),
        'rti_due_date': _format_rti_date(rti.due_date, date_fmt),
        'rti_mode_of_receipt': _safe_rti_str(rti.mode_of_receipt),
        'rti_applicant_name': _safe_rti_str(rti.applicant_name),
        'rti_applicant_age': _safe_rti_str(rti.applicant_age),
        'rti_mobile_no': _safe_rti_str(rti.mobile_no),
        'rti_address': _safe_rti_str(rti.address),
        'rti_email': _safe_rti_str(rti.email),
        'rti_is_bpl': _format_rti_bool(rti.is_bpl),
        'rti_info_type': _safe_rti_str(rti.info_type),
        'rti_info_type_other': _safe_rti_str(rti.info_type_other),
        'rti_assigned_officer': officer_val,
        'rti_outcome': outcome_val,
        'rti_replied_date': _format_rti_date(rti.replied_date, date_fmt),
        'rti_rejected_date': _format_rti_date(rti.rejected_date, date_fmt),
        'rti_rejection_reason': _safe_rti_str(rti.rejection_reason),
        'rti_transferred_to': _safe_rti_str(rti.transferred_to),
        'rti_transferred_date': _format_rti_date(rti.transferred_date, date_fmt),
        'rti_remark': _safe_rti_str(rti.remark),
        'rti_appealed': _format_rti_bool(rti.appealed),
        'rti_appeal_date': _format_rti_date(rti.appeal_date, date_fmt),
    }

    rows = [
        DisplayRow(serial_label, serial_val),
        DisplayRow(status_label, status_val),
    ]

    for ftf in ftfs:
        if ftf.depends_on_field_key:
            parent_val = attr_map.get(ftf.depends_on_field_key, '')
            dep_target = str(ftf.depends_on_value or '').strip()
            if parent_val.strip().lower() != dep_target.lower():
                continue
        disp_val = attr_map.get(ftf.field_key, '')
        rows.append(DisplayRow(ftf.field_label, disp_val))

    return rows



class RTIListCreateView(APIView):
    """
    POST /api/rti/ - Create RTI Application
    GET /api/rti/?status=all|pending|disposal&page=&q= - Paginated RTI Applications list
    """

    def get(self, request):
        schema, err = _resolve_tenant_and_auth(request, 'rti:view')
        if err:
            return err

        user = request.user
        station_name = getattr(user, 'station_name', '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        with TenantContext(schema):
            qs = RTIApplication.objects.filter(station_name__iexact=station_name)

            status_param = request.query_params.get('status', 'all').strip().lower()
            if status_param == 'pending':
                qs = qs.filter(status='Pending')
            elif status_param == 'disposal':
                qs = qs.filter(status='Disposal')

            q = request.query_params.get('q', '').strip()
            if q:
                if q.isdigit():
                    qs = qs.filter(Q(serial_no=int(q)) | Q(applicant_name__icontains=q))
                else:
                    qs = qs.filter(applicant_name__icontains=q)

            page_size = _get_setting('page_size', 20)
            try:
                page = int(request.query_params.get('page', 1))
            except ValueError:
                page = 1

            total_count = qs.count()
            start = (page - 1) * page_size
            end = start + page_size
            results = list(qs[start:end])

            serializer = RTIApplicationListSerializer(results, many=True)
            return Response({
                'count': total_count,
                'page': page,
                'page_size': page_size,
                'results': serializer.data
            })

    def post(self, request):
        schema, err = _resolve_tenant_and_auth(request, 'rti:create')
        if err:
            return err

        user = request.user
        user_station_id = str(getattr(user, 'station_id', '') or '').strip()
        station_name = str(getattr(user, 'station_name', '') or '').strip()
        if not user_station_id and not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        raw_data = request.data
        data = {}
        for k, v in raw_data.items():
            norm_k = k[4:] if (k.startswith('rti_') and k not in ('rti_id', 'rti_outcome')) else k
            if k in ('rti_assigned_officer', 'rti_assigned_officer_uid'):
                norm_k = 'assigned_officer_uid'
            data[norm_k] = v

        # Empty save protection:
        # Check if every form field is missing or empty.
        form_keys = [
            'received_date', 'due_date', 'mode_of_receipt', 'applicant_name',
            'applicant_age', 'mobile_no', 'address', 'email', 'is_bpl',
            'info_type', 'info_type_other', 'assigned_officer_uid',
            'rti_outcome', 'replied_date', 'rejected_date', 'rejection_reason',
            'transferred_to', 'transferred_date', 'remark', 'appealed', 'appeal_date'
        ]
        has_any_field = False
        for fk in form_keys:
            val = data.get(fk)
            if val is not None:
                if isinstance(val, bool):
                    # bool is also an int: only a ticked box counts as filled
                    if val:
                        has_any_field = True
                        break
                elif isinstance(val, (int, float)):
                    has_any_field = True
                    break
                elif isinstance(val, str) and val.strip() and val.strip().lower() not in ('null', 'none', 'false'):
                    has_any_field = True
                    break

        if not has_any_field:
            empty_msg = _get_setting('empty_application_message', 'At least one form field must be provided to submit an RTI application.')
            return Response({'error': empty_msg}, status=status.HTTP_400_BAD_REQUEST)

        # Dates & Validation
        received_date = None
        rec_date_str = data.get('received_date')
        if rec_date_str and str(rec_date_str).strip():
            received_date = _parse_rti_date(rec_date_str)
            if not received_date:
                return Response({'error': 'received_date must be a valid date (e.g. YYYY-MM-DD or DD/MM/YYYY).'}, status=status.HTTP_400_BAD_REQUEST)

        due_date = None
        due_date_str = data.get('due_date')
        if due_date_str and str(due_date_str).strip():
            due_date = _parse_rti_date(due_date_str)
            if not due_date:
                return Response({'error': 'due_date must be a valid date (e.g. YYYY-MM-DD or DD/MM/YYYY).'}, status=status.HTTP_400_BAD_REQUEST)
        elif received_date:
            due_days = int(_get_setting('due_days', 30))
            due_date = received_date + datetime.timedelta(days=due_days)

        if received_date and due_date and due_date < received_date:
            return Response({'error': 'due_date cannot be earlier than received_date.'}, status=status.HTTP_400_BAD_REQUEST)

        # Mode of Receipt (optional)
        mode = data.get('mode_of_receipt', '')
        if mode and str(mode).strip():
            mode = str(mode).strip()
            with TenantContext(schema):
                valid_modes = list(OptionValue.objects.filter(option_group='rti_mode_of_receipt', is_active=True).values_list('option_value', flat=True))
            if mode not in valid_modes:
                return Response({'error': f"Invalid mode_of_receipt '{mode}'. Allowed: {valid_modes}"}, status=status.HTTP_400_BAD_REQUEST)
        else:
            mode = None

        # Applicant Name & Address (optional)
        applicant_name = data.get('applicant_name', '')
        applicant_name = str(applicant_name).strip() if applicant_name else None

        address = data.get('address', '')
        address = str(address).strip() if address else None

        applicant_age = data.get('applicant_age')
        if applicant_age is not None and str(applicant_age).strip() != '':
            try:
                age_int = int(applicant_age)
                if not (1 <= age_int <= 120):
                    return Response({'error': 'applicant_age must be between 1 and 120.'}, status=status.HTTP_400_BAD_REQUEST)
                applicant_age = age_int
            except ValueError:
                return Response({'error': 'applicant_age must be an integer.'}, status=status.HTTP_400_BAD_REQUEST)
        else:
            applicant_age = None

        mobile_no = data.get('mobile_no')
        if mobile_no and str(mobile_no).strip() != '':
            mob_str = str(mobile_no).strip()
            if not re.match(r'^[0-9]{10}$', mob_str):
                return Response({'error': 'mobile_no must be exactly 10 digits.'}, status=status.HTTP_400_BAD_REQUEST)
            mobile_no = mob_str
        else:
            mobile_no = None

        # E-mail (optional): checked only when filled
        email_val = str(data.get('email') or '').strip()
        if email_val and not _is_valid_email(email_val):
            return Response({'error': 'email must be a valid e-mail address.'}, status=status.HTTP_400_BAD_REQUEST)

        # Info Type (optional)
        info_type = data.get('info_type', '')
        info_type = str(info_type).strip() if info_type else None
        info_type_other = data.get('info_type_other', '')
        info_type_other = str(info_type_other).strip() if info_type_other else None

        if info_type:
            with TenantContext(schema):
                valid_types = list(OptionValue.objects.filter(option_group='rti_info_type', is_active=True).values_list('option_value', flat=True))
            if info_type not in valid_types:
                return Response({'error': f"Invalid info_type '{info_type}'. Allowed: {valid_types}"}, status=status.HTTP_400_BAD_REQUEST)

            if info_type == 'Other':
                if not info_type_other:
                    return Response({'error': 'info_type_other is required when info_type is Other.'}, status=status.HTTP_400_BAD_REQUEST)
                max_chars = _get_setting('max_chars_info_other', 20)
                if len(info_type_other) > max_chars:
                    return Response({'error': f'info_type_other exceeds maximum character limit of {max_chars}.'}, status=status.HTTP_400_BAD_REQUEST)
            else:
                info_type_other = None
        else:
            info_type = None
            info_type_other = None

        # Assigned Officer (optional)
        officer_uid = data.get('assigned_officer_uid', '')
        officer_uid = str(officer_uid).strip() if officer_uid else None
        officer = None

        if officer_uid:
            officer_name_prefix = officer_uid.split(',')[0].strip()
            with TenantContext(schema):
                scoped_qs, error_msg = _get_scoped_officers_queryset(user)
                if scoped_qs is None:
                    return Response({'error': error_msg}, status=status.HTTP_400_BAD_REQUEST)

                officer = scoped_qs.filter(
                    Q(uid=officer_uid) | Q(name__iexact=officer_uid) | Q(name__iexact=officer_name_prefix)
                ).first()

            if not officer:
                out_of_scope_msg = _get_setting('officer_out_of_scope_message', 'Assigned officer does not belong to your unit scope.')
                return Response({'error': out_of_scope_msg}, status=status.HTTP_400_BAD_REQUEST)

        # Outcome Logic
        outcome = data.get('rti_outcome', '')
        outcome = str(outcome).strip() if outcome else ''
        replied_date = None
        rejected_date = None
        rejection_reason = None
        transferred_to = None
        transferred_date = None

        if outcome == 'Replied':
            r_str = data.get('replied_date')
            if not r_str:
                return Response({'error': 'replied_date is required when outcome is Replied.'}, status=status.HTTP_400_BAD_REQUEST)
            replied_date = _parse_rti_date(r_str)
            if not replied_date:
                return Response({'error': 'replied_date must be a valid date.'}, status=status.HTTP_400_BAD_REQUEST)
        elif outcome == 'Rejected':
            rej_str = data.get('rejected_date')
            if not rej_str:
                return Response({'error': 'rejected_date is required when outcome is Rejected.'}, status=status.HTTP_400_BAD_REQUEST)
            rejected_date = _parse_rti_date(rej_str)
            if not rejected_date:
                return Response({'error': 'rejected_date must be a valid date.'}, status=status.HTTP_400_BAD_REQUEST)

            rejection_reason = data.get('rejection_reason', '')
            rejection_reason = str(rejection_reason).strip() if rejection_reason else None
            if not rejection_reason:
                return Response({'error': 'rejection_reason is required when outcome is Rejected.'}, status=status.HTTP_400_BAD_REQUEST)
            max_words = _get_setting('max_words_reason', 20)
            if _word_count(rejection_reason) > max_words:
                return Response({'error': f'rejection_reason exceeds maximum limit of {max_words} words.'}, status=status.HTTP_400_BAD_REQUEST)
        elif outcome == 'Transferred':
            transferred_to = data.get('transferred_to', '')
            transferred_to = str(transferred_to).strip() if transferred_to else None
            if not transferred_to:
                return Response({'error': 'transferred_to is required when outcome is Transferred.'}, status=status.HTTP_400_BAD_REQUEST)
            max_words = _get_setting('max_words_transfer', 20)
            if _word_count(transferred_to) > max_words:
                return Response({'error': f'transferred_to exceeds maximum limit of {max_words} words.'}, status=status.HTTP_400_BAD_REQUEST)
            # Transfer Date is optional
            td_str = data.get('transferred_date')
            if td_str and str(td_str).strip():
                transferred_date = _parse_rti_date(td_str)
                if not transferred_date:
                    return Response({'error': 'transferred_date must be a valid date.'}, status=status.HTTP_400_BAD_REQUEST)

        # Remark
        remark = data.get('remark', '')
        remark = str(remark).strip() if remark else None
        if remark:
            max_words = _get_setting('max_words_remark', 20)
            if _word_count(remark) > max_words:
                return Response({'error': f'remark exceeds maximum limit of {max_words} words.'}, status=status.HTTP_400_BAD_REQUEST)

        # Appeal
        appealed = data.get('appealed', False) in (True, 'true', 'True', 1, '1')
        appeal_date = None
        if appealed:
            app_str = data.get('appeal_date')
            if not app_str:
                return Response({'error': 'appeal_date is required when appealed is True.'}, status=status.HTTP_400_BAD_REQUEST)
            appeal_date = _parse_rti_date(app_str)
            if not appeal_date:
                return Response({'error': 'appeal_date must be a valid date.'}, status=status.HTTP_400_BAD_REQUEST)

        # Serial Number Generation under lock
        serial_year = received_date.year if received_date else datetime.date.today().year
        with TenantContext(schema):
            with transaction.atomic():
                max_serial = RTIApplication.objects.filter(station_name__iexact=station_name, serial_year=serial_year).aggregate(Max('serial_no'))['serial_no__max']
                serial_no = (max_serial or 0) + 1

                rti = RTIApplication.objects.create(
                    station_name=station_name,
                    serial_year=serial_year,
                    serial_no=serial_no,
                    applicant_name=applicant_name,
                    applicant_age=applicant_age,
                    mobile_no=mobile_no,
                    address=address,
                    email=email_val or None,
                    received_date=received_date,
                    due_date=due_date,
                    replied_date=replied_date,
                    rejected_date=rejected_date,
                    rejection_reason=rejection_reason,
                    transferred_to=transferred_to,
                    transferred_date=transferred_date,
                    info_type=info_type,
                    info_type_other=info_type_other,
                    assigned_officer_uid=officer.uid if officer else None,
                    assigned_officer_name=officer.name if officer else None,
                    assigned_officer_designation=officer.designation if officer else None,
                    mode_of_receipt=mode,
                    is_bpl=data.get('is_bpl', False) in (True, 'true', 'True', 1, '1'),
                    remark=remark,
                    appealed=appealed,
                    appeal_date=appeal_date,
                    created_by=getattr(user, 'uid', None) or getattr(user, 'id', 'anonymous')
                )



        cache.delete(f"rti:counts:{schema}:{station_name}")
        _log_rti_audit(request, 'rti:create', rti.rti_id)

        serializer = RTIApplicationSerializer(rti)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class RTICountsView(APIView):
    """
    GET /api/rti/counts/ - {total, pending, disposal} from ONE SQL query, cached 30 to 60s per schema & station
    """

    def get(self, request):
        schema, err = _resolve_tenant_and_auth(request, 'rti:view')
        if err:
            return err

        user = request.user
        station_name = getattr(user, 'station_name', '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        cache_key = f"rti:counts:{schema}:{station_name}"
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        with TenantContext(schema):
            counts = RTIApplication.objects.filter(station_name__iexact=station_name).aggregate(
                total=Count('rti_id'),
                pending=Count('rti_id', filter=Q(status='Pending')),
                disposal=Count('rti_id', filter=Q(status='Disposal'))
            )

        data = {
            'total': counts['total'] or 0,
            'pending': counts['pending'] or 0,
            'disposal': counts['disposal'] or 0
        }
        cache.set(cache_key, data, timeout=45)
        return Response(data)


class RTIConfigView(APIView):
    """
    GET /api/rti/config/ - Return all dynamic UI labels, limits, and messages from module_settings
    """

    def get(self, request):
        schema, err = _resolve_tenant_and_auth(request, 'rti:view')
        if err:
            return err

        settings_qs = ModuleSetting.objects.filter(Q(module_key='rti') | Q(module_key='common'))
        settings_map = {s.setting_key: s.setting_value for s in settings_qs}

        data = {
            'target_category_code': settings_map.get('target_category_code', 'STAND_RTI'),
            'sub_tab_labels': {
                'all': settings_map.get('tab_total_label', 'Total'),
                'pending': settings_map.get('tab_pending_label', 'Pending'),
                'disposal': settings_map.get('tab_disposal_label', 'Disposal'),
                'chart': settings_map.get('tab_chart_label', ''),
            },
            'chart_headers': {
                k: settings_map.get(f'chart_header_{k}', '') for k in _RTI_CHART_COLUMNS
            },
            'row_action_labels': {
                'edit': settings_map.get('action_edit_label', 'Edit'),
                'view': settings_map.get('action_view_label', 'View'),
                'pdf': settings_map.get('action_pdf_label', 'PDF'),
                'remind': settings_map.get('action_remind_label', ''),
            },
            'add_button_label': settings_map.get('add_button_label', 'Add RTI Application'),
            'serial_label': settings_map.get('serial_label', 'Sr. No.'),
            'empty_list_message': settings_map.get('empty_list_message', 'No RTI applications found'),
            'no_form_message': settings_map.get('no_form_message', 'No form configured for this tab'),
            'page_size': int(settings_map.get('page_size', '20')),
            # Form fills Due Date = Received Date + due_days as soon as Received Date is
            # picked (same rule the backend applies when Due Date is left blank)
            'date_offset_rules': [{
                'source_field': 'rti_received_date',
                'target_field': 'rti_due_date',
                'days': int(settings_map.get('due_days', '30')),
            }],
            'limits': {
                'due_days': int(settings_map.get('due_days', '30')),
                'max_words_reason': int(settings_map.get('max_words_reason', '20')),
                'max_words_transfer': int(settings_map.get('max_words_transfer', '20')),
                'max_words_remark': int(settings_map.get('max_words_remark', '20')),
                'max_chars_info_other': int(settings_map.get('max_chars_info_other', '20')),
            }
        }
        return Response(data)


# Chart tab columns, in display order (header text: module_settings chart_header_<key>)
_RTI_CHART_COLUMNS = (
    'sr_no', 'person', 'received_date', 'due_date',
    'info_type', 'assigned_officer', 'info_given', 'action',
)


def _render_parts(values, template, separator):
    """
    Text from a module_settings template: split on '|' into parts; a part whose
    placeholders are all empty is skipped; parts are joined with separator.
    """
    parts = []
    for segment in (template or '').split('|'):
        keys = [k for k in values if '{' + k + '}' in segment]
        if not keys or all(not values[k] for k in keys):
            continue
        try:
            parts.append(segment.format(**values).strip())
        except (KeyError, IndexError, ValueError):
            continue
    return (separator or '').join(p for p in parts if p)


def _rti_info_given(rti, date_fmt, template, separator):
    """
    'Information Given' cell: the outcome chosen by the user with its date, from
    the module_settings template. Parts are split on '|'; a part whose
    placeholders are all empty is skipped. Empty when no outcome is chosen yet.
    """
    if rti.replied_date:
        outcome, date_val = 'Replied', rti.replied_date
    elif rti.rejected_date or (rti.rejection_reason and str(rti.rejection_reason).strip()):
        outcome, date_val = 'Rejected', rti.rejected_date
    elif rti.transferred_to and str(rti.transferred_to).strip():
        outcome, date_val = 'Transferred', rti.transferred_date
    else:
        return ''
    values = {'outcome': outcome, 'date': _format_rti_date(date_val, date_fmt)}
    return _render_parts(values, template, separator)


class RTIChartView(APIView):
    """
    GET /api/rti/chart/?page=&q= - Chart tab: ALL RTI applications of the user's
    station (pending and disposal), one row per application, in serial order.
    Settings are read in one query; one query for the page plus one COUNT.
    """

    def get(self, request):
        schema, err = _resolve_tenant_and_auth(request, 'rti:view')
        if err:
            return err

        user = request.user
        station_name = getattr(user, 'station_name', '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        smap = {
            s_.setting_key: s_.setting_value for s_ in ModuleSetting.objects.filter(
                module_key='rti',
                setting_key__in=['page_size', 'date_format', 'serial_prefix', 'serial_format',
                                 'chart_info_given_template', 'chart_info_given_separator',
                                 'chart_person_template', 'chart_person_separator'],
            )
        }
        try:
            page_size = int(smap.get('page_size') or 20)
            page = max(int(request.query_params.get('page', 1)), 1)
        except ValueError:
            page_size, page = 20, 1
        date_fmt = (smap.get('date_format') or '%d/%m/%Y').strip()
        prefix = (smap.get('serial_prefix') or 'RTI').strip()
        serial_fmt = (smap.get('serial_format') or '{prefix}-{year}/{serial_no}').strip()
        template = smap.get('chart_info_given_template')
        separator = smap.get('chart_info_given_separator')
        if template is None:
            logger.warning("[RTI] module_settings missing: rti.chart_info_given_template")
        person_template = smap.get('chart_person_template')
        person_separator = smap.get('chart_person_separator')
        if person_template is None:
            logger.warning("[RTI] module_settings missing: rti.chart_person_template")

        def serial(r):
            try:
                return serial_fmt.format(prefix=prefix, year=r.serial_year, serial_no=r.serial_no)
            except (KeyError, IndexError, ValueError):
                return f"{prefix}-{r.serial_year}/{r.serial_no}"

        with TenantContext(schema):
            qs = RTIApplication.objects.filter(station_name__iexact=station_name)
            q = request.query_params.get('q', '').strip()
            if q:
                if q.isdigit():
                    qs = qs.filter(Q(serial_no=int(q)) | Q(applicant_name__icontains=q))
                else:
                    qs = qs.filter(applicant_name__icontains=q)

            total_count = qs.count()
            rows = list(qs.order_by('serial_year', 'serial_no', 'rti_id')[(page - 1) * page_size: page * page_size])

        results = []
        for r in rows:
            info_type = _safe_rti_str(r.info_type)
            info_other = _safe_rti_str(r.info_type_other)
            officer = ', '.join(p for p in (_safe_rti_str(r.assigned_officer_name),
                                            _safe_rti_str(r.assigned_officer_designation)) if p)
            results.append({
                'rti_id': r.rti_id,
                'sr_no': serial(r),
                # Name, Age, Mobile No. and Address in one column
                'person': _render_parts({
                    'name': _safe_rti_str(r.applicant_name),
                    'age': _safe_rti_str(r.applicant_age),
                    'mobile': _safe_rti_str(r.mobile_no),
                    'address': _safe_rti_str(r.address),
                }, person_template, person_separator),
                'received_date': _format_rti_date(r.received_date, date_fmt),
                'due_date': _format_rti_date(r.due_date, date_fmt),
                'info_type': f"{info_type} ({info_other})" if info_type and info_other else (info_type or info_other),
                'assigned_officer': officer,
                'info_given': _rti_info_given(r, date_fmt, template, separator),
            })
        return Response({'count': total_count, 'page': page, 'page_size': page_size, 'results': results})


# ── RTI due-date reminders ─────────────────────────────────────────────────
# Reminders go only to the assigned officer of a pending application:
#   1st reminder  : reminder_first_days_before  days before the Due Date
#   2nd reminder  : reminder_second_days_before days before the Due Date
#   then daily    : from reminder_daily_from_days_before days before the Due
#                   Date, every day until the application is disposed
# Computed on every request (no scheduler). Manual reminders sent from the
# Summary tab are stored as users_notificationrecord rows (category below).
RTI_MANUAL_REMINDER_CATEGORY = 'rti_reminder'


def rti_info_given_q():
    """Applications whose 'Information Given' date is filled: reminders stop for them."""
    return (Q(replied_date__isnull=False) | Q(rejected_date__isnull=False)
            | Q(transferred_date__isnull=False))

_RTI_REMINDER_SETTING_KEYS = [
    'reminder_first_days_before', 'reminder_second_days_before', 'reminder_daily_from_days_before',
    'reminder_title', 'reminder_message', 'reminder_tab_label', 'reminder_banner',
    'manual_reminder_title', 'manual_reminder_message', 'manual_reminder_sent_message',
    'manual_reminder_no_officer_message', 'manual_reminder_info_given_message',
    'date_format', 'serial_prefix', 'serial_format',
]


def _rti_int(smap, key, default):
    try:
        return int(str(smap.get(key)).strip())
    except (TypeError, ValueError):
        return default


def rti_reminder_kind(due_date, today, first, second, daily_from):
    """'first' / 'second' / 'daily' when a reminder is due today, else None."""
    if not due_date:
        return None
    days_left = (due_date - today).days
    if days_left == first:
        return 'first'
    if days_left == second:
        return 'second'
    if days_left <= daily_from:
        return 'daily'
    return None


def _safe_format(template, values):
    try:
        return (template or '').format(**values)
    except (KeyError, IndexError, ValueError):
        return template or ''


class RTIRemindersView(APIView):
    """
    GET /api/rti/reminders/ - Reminders for the logged-in officer: scheduled
    due-date reminders of the pending applications assigned to them, plus unread
    manual reminders. Two queries (settings + applications) and one for manual.
    """

    def get(self, request):
        schema, err = _resolve_tenant_and_auth(request, 'rti:view')
        if err:
            return err

        uid = str(getattr(request.user, 'uid', '') or '').strip()
        smap = {s_.setting_key: s_.setting_value for s_ in
                ModuleSetting.objects.filter(module_key='rti', setting_key__in=_RTI_REMINDER_SETTING_KEYS)}
        first = _rti_int(smap, 'reminder_first_days_before', 30)
        second = _rti_int(smap, 'reminder_second_days_before', 25)
        daily_from = _rti_int(smap, 'reminder_daily_from_days_before', 24)
        labels = {'tab': smap.get('reminder_tab_label') or '', 'banner': smap.get('reminder_banner') or ''}
        if not uid:
            return Response({'count': 0, 'labels': labels, 'results': []})

        date_fmt = (smap.get('date_format') or '%d/%m/%Y').strip()
        prefix = (smap.get('serial_prefix') or 'RTI').strip()
        serial_fmt = (smap.get('serial_format') or '{prefix}-{year}/{serial_no}').strip()
        today = datetime.date.today()

        with TenantContext(schema):
            rows = list(
                RTIApplication.objects.filter(assigned_officer_uid=uid, due_date__isnull=False)
                # Reminders stop once the Information Given date is entered
                .exclude(rti_info_given_q())
                .filter(Q(due_date=today + datetime.timedelta(days=first)) |
                        Q(due_date=today + datetime.timedelta(days=second)) |
                        Q(due_date__lte=today + datetime.timedelta(days=daily_from)))
                .order_by('due_date', 'rti_id')
            )
            from apps.users.models import NotificationRecord
            manual = list(NotificationRecord.objects.filter(
                category=RTI_MANUAL_REMINDER_CATEGORY, target_user_uid=uid, is_read=False,
            ).order_by('-created_at')[:50])
            # Manual reminders of applications that are now answered are dropped too
            manual_rti_ids = {int(m.registration_uid) for m in manual
                              if str(m.registration_uid or '').isdigit()}
            answered = set(
                RTIApplication.objects.filter(rti_id__in=manual_rti_ids).filter(rti_info_given_q())
                .values_list('rti_id', flat=True)
            ) if manual_rti_ids else set()
            manual = [m for m in manual
                      if not (str(m.registration_uid or '').isdigit() and int(m.registration_uid) in answered)]

        results = []
        for m in manual:
            results.append({
                'id': f'manual-{m.id}', 'kind': 'manual', 'title': m.title, 'message': m.body,
                'days_left': None, 'due_date': '',
            })
        for r in rows:
            kind = rti_reminder_kind(r.due_date, today, first, second, daily_from)
            if not kind:
                continue
            try:
                sr_no = serial_fmt.format(prefix=prefix, year=r.serial_year, serial_no=r.serial_no)
            except (KeyError, IndexError, ValueError):
                sr_no = f"{prefix}-{r.serial_year}/{r.serial_no}"
            values = {
                'sr_no': sr_no,
                'applicant': _safe_rti_str(r.applicant_name),
                'due_date': _format_rti_date(r.due_date, date_fmt),
                'days_left': str((r.due_date - today).days),
            }
            results.append({
                'id': f'rti-{r.rti_id}', 'rti_id': r.rti_id, 'kind': kind,
                'title': _safe_format(smap.get('reminder_title'), values),
                'message': _safe_format(smap.get('reminder_message'), values),
                'days_left': int(values['days_left']), 'due_date': values['due_date'],
            })
        return Response({'count': len(results), 'labels': labels, 'results': results})


class RTIRemindersSeenView(APIView):
    """POST /api/rti/reminders/seen/ - mark the officer's manual reminders as read."""

    def post(self, request):
        schema, err = _resolve_tenant_and_auth(request, 'rti:view')
        if err:
            return err
        uid = str(getattr(request.user, 'uid', '') or '').strip()
        updated = 0
        if uid:
            from apps.users.models import NotificationRecord
            with TenantContext(schema):
                updated = NotificationRecord.objects.filter(
                    category=RTI_MANUAL_REMINDER_CATEGORY, target_user_uid=uid, is_read=False,
                ).update(is_read=True)
        return Response({'updated': updated})


class RTISendReminderView(APIView):
    """
    POST /api/rti/<pk>/remind/ - Summary tab action: send a reminder now to the
    officer assigned to this application (same station only).
    """

    def post(self, request, pk):
        schema, err = _resolve_tenant_and_auth(request, 'rti:update')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        smap = {s_.setting_key: s_.setting_value for s_ in
                ModuleSetting.objects.filter(module_key='rti', setting_key__in=_RTI_REMINDER_SETTING_KEYS)}
        date_fmt = (smap.get('date_format') or '%d/%m/%Y').strip()
        prefix = (smap.get('serial_prefix') or 'RTI').strip()
        serial_fmt = (smap.get('serial_format') or '{prefix}-{year}/{serial_no}').strip()

        from apps.users.models import NotificationRecord
        with TenantContext(schema):
            rti = RTIApplication.objects.filter(rti_id=pk, station_name__iexact=station_name).first()
            if not rti:
                return Response({'error': _get_setting('not_found_message', 'RTI application not found.')},
                                status=status.HTTP_404_NOT_FOUND)
            officer_uid = _safe_rti_str(rti.assigned_officer_uid)
            if not officer_uid:
                return Response({'error': smap.get('manual_reminder_no_officer_message') or ''},
                                status=status.HTTP_400_BAD_REQUEST)
            if rti.replied_date or rti.rejected_date or rti.transferred_date:
                return Response({'error': smap.get('manual_reminder_info_given_message') or ''},
                                status=status.HTTP_400_BAD_REQUEST)
            try:
                sr_no = serial_fmt.format(prefix=prefix, year=rti.serial_year, serial_no=rti.serial_no)
            except (KeyError, IndexError, ValueError):
                sr_no = f"{prefix}-{rti.serial_year}/{rti.serial_no}"
            today = datetime.date.today()
            values = {
                'sr_no': sr_no,
                'applicant': _safe_rti_str(rti.applicant_name),
                'due_date': _format_rti_date(rti.due_date, date_fmt),
                'days_left': str((rti.due_date - today).days) if rti.due_date else '',
                'sender': _safe_rti_str(getattr(user, 'name', '')),
                'officer': _safe_rti_str(rti.assigned_officer_name),
            }
            NotificationRecord.objects.create(
                target_user_uid=officer_uid,
                target_station_name=station_name,
                title=_safe_format(smap.get('manual_reminder_title'), values),
                body=_safe_format(smap.get('manual_reminder_message'), values),
                category=RTI_MANUAL_REMINDER_CATEGORY,
                registration_uid=str(rti.rti_id),
                status='sent',
            )

        _log_rti_audit(request, 'rti:remind', pk)
        return Response({'message': _safe_format(smap.get('manual_reminder_sent_message'), values)},
                        status=status.HTTP_201_CREATED)


class RTIOfficersView(APIView):
    """
    GET /api/rti/officers/ - Active officers within user's unit/role scope
    """

    def get(self, request):
        schema, err = _resolve_tenant_and_auth(request, 'rti:view')
        if err:
            return err

        user = request.user

        with TenantContext(schema):
            scoped_qs, error_msg = _get_scoped_officers_queryset(user)
            if scoped_qs is None:
                return Response({'results': [], 'message': error_msg}, status=status.HTTP_200_OK)

            officers = scoped_qs.order_by('name')
            results = [
                {
                    'val': o.uid,
                    'uid': o.uid,
                    'name': o.name or '',
                    'designation': o.designation or '',
                    'label': f"{o.name}, {o.designation}".strip(', ') if o.designation else (o.name or '')
                }
                for o in officers
            ]
        return Response(results)


class RTIDetailView(APIView):
    """
    GET /api/rti/<id>/ - View RTI application
    PATCH /api/rti/<id>/ - Update RTI application
    """

    def get(self, request, pk):
        schema, err = _resolve_tenant_and_auth(request, 'rti:view')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()

        with TenantContext(schema):
            rti = RTIApplication.objects.annotate(
                trimmed_station=Trim('station_name')
            ).filter(pk=pk, trimmed_station__iexact=station_name).first()
            if not rti:
                return Response({'error': 'RTI application not found.'}, status=status.HTTP_404_NOT_FOUND)
            serializer = RTIApplicationSerializer(rti)
            data = serializer.data
            data['display_rows'] = get_rti_display_rows(rti, schema=schema)
            return Response(data)

    def patch(self, request, pk):
        schema, err = _resolve_tenant_and_auth(request, 'rti:update')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()

        with TenantContext(schema):
            rti = RTIApplication.objects.annotate(
                trimmed_station=Trim('station_name')
            ).filter(pk=pk, trimmed_station__iexact=station_name).first()
            if not rti:
                return Response({'error': 'RTI application not found.'}, status=status.HTTP_404_NOT_FOUND)

            raw_data = request.data
            data = {}
            for k, v in raw_data.items():
                norm_k = k[4:] if (k.startswith('rti_') and k not in ('rti_id', 'rti_outcome')) else k
                if k in ('rti_assigned_officer', 'rti_assigned_officer_uid'):
                    norm_k = 'assigned_officer_uid'
                data[norm_k] = v

            changed_fields = []

            # Date fields parsing
            date_fields = ('received_date', 'due_date', 'replied_date', 'rejected_date', 'appeal_date', 'transferred_date')
            parsed_dates = {}
            for df in date_fields:
                if df in data:
                    val = data[df]
                    if val is not None and str(val).strip() and str(val).strip().lower() not in ('null', 'none', '-'):
                        parsed_d = _parse_rti_date(val)
                        if not parsed_d:
                            return Response({'error': f'{df} must be a valid date.'}, status=status.HTTP_400_BAD_REQUEST)
                        parsed_dates[df] = parsed_d
                    else:
                        parsed_dates[df] = None

            # Merge validation for due_date >= received_date
            merged_rec = parsed_dates['received_date'] if 'received_date' in data else rti.received_date
            merged_due = parsed_dates['due_date'] if 'due_date' in data else rti.due_date
            if merged_rec and merged_due and merged_due < merged_rec:
                return Response({'error': 'due_date cannot be earlier than received_date.'}, status=status.HTTP_400_BAD_REQUEST)

            # Merge validation for outcome fields
            merged_replied = parsed_dates['replied_date'] if 'replied_date' in data else rti.replied_date
            merged_rejected = parsed_dates['rejected_date'] if 'rejected_date' in data else rti.rejected_date
            merged_transfer = data.get('transferred_to', rti.transferred_to)

            outcome_count = (1 if merged_replied else 0) + (1 if merged_rejected else 0) + (1 if (merged_transfer and str(merged_transfer).strip()) else 0)
            if outcome_count > 1:
                return Response({'error': 'Invalid outcome: Cannot have multiple outcomes (Replied, Rejected, Transferred) filled simultaneously.'}, status=status.HTTP_400_BAD_REQUEST)

            # Outcome radio update if sent
            if 'rti_outcome' in data:
                out_val = str(data['rti_outcome']).strip()
                if out_val == 'Replied':
                    rti.rejected_date = None
                    rti.rejection_reason = None
                    rti.transferred_to = None
                    rti.transferred_date = None
                    data.pop('transferred_date', None)
                elif out_val == 'Rejected':
                    rti.replied_date = None
                    rti.transferred_to = None
                    rti.transferred_date = None
                    data.pop('transferred_date', None)
                elif out_val == 'Transferred':
                    rti.replied_date = None
                    rti.rejected_date = None
                    rti.rejection_reason = None

            # Mobile No. / E-mail on patch (optional; checked only when filled)
            if 'mobile_no' in data:
                mob_str = str(data['mobile_no'] or '').strip()
                if mob_str and not re.match(r'^[0-9]{10}$', mob_str):
                    return Response({'error': 'mobile_no must be exactly 10 digits.'}, status=status.HTTP_400_BAD_REQUEST)
            if 'email' in data:
                email_str = str(data['email'] or '').strip()
                if email_str and not _is_valid_email(email_str):
                    return Response({'error': 'email must be a valid e-mail address.'}, status=status.HTTP_400_BAD_REQUEST)

            # Validation of setting word limits on patch
            if 'remark' in data and data['remark']:
                max_words = _get_setting('max_words_remark', 20)
                if _word_count(str(data['remark'])) > max_words:
                    return Response({'error': f'remark exceeds maximum limit of {max_words} words.'}, status=status.HTTP_400_BAD_REQUEST)

            if 'rejection_reason' in data and data['rejection_reason']:
                max_words = _get_setting('max_words_reason', 20)
                if _word_count(str(data['rejection_reason'])) > max_words:
                    return Response({'error': f'rejection_reason exceeds maximum limit of {max_words} words.'}, status=status.HTTP_400_BAD_REQUEST)

            if 'transferred_to' in data and data['transferred_to']:
                max_words = _get_setting('max_words_transfer', 20)
                if _word_count(str(data['transferred_to'])) > max_words:
                    return Response({'error': f'transferred_to exceeds maximum limit of {max_words} words.'}, status=status.HTTP_400_BAD_REQUEST)

            if 'assigned_officer_uid' in data:
                off_val = data['assigned_officer_uid']
                if off_val is not None and str(off_val).strip() and str(off_val).strip().lower() not in ('null', 'none'):
                    off_val_str = str(off_val).strip()
                    off_name_prefix = off_val_str.split(',')[0].strip()

                    scoped_qs, error_msg = _get_scoped_officers_queryset(user)
                    if scoped_qs is None:
                        return Response({'error': error_msg}, status=status.HTTP_400_BAD_REQUEST)

                    off = scoped_qs.filter(
                        Q(uid=off_val_str) | Q(name__iexact=off_val_str) | Q(name__iexact=off_name_prefix)
                    ).first()

                    if off:
                        rti.assigned_officer_uid = off.uid
                        rti.assigned_officer_name = off.name
                        rti.assigned_officer_designation = off.designation
                        changed_fields.extend(['assigned_officer_uid', 'assigned_officer_name', 'assigned_officer_designation'])
                    else:
                        out_of_scope_msg = _get_setting('officer_out_of_scope_message', 'Assigned officer does not belong to your unit scope.')
                        return Response({'error': out_of_scope_msg}, status=status.HTTP_400_BAD_REQUEST)
                else:
                    rti.assigned_officer_uid = None
                    rti.assigned_officer_name = None
                    rti.assigned_officer_designation = None
                    changed_fields.extend(['assigned_officer_uid', 'assigned_officer_name', 'assigned_officer_designation'])

            for key, value in data.items():
                if key in ('assigned_officer_uid', 'assigned_officer_name', 'assigned_officer_designation'):
                    continue
                if hasattr(rti, key) and key not in ('rti_id', 'serial_year', 'serial_no', 'status', 'station_name'):
                    if key in date_fields:
                        setattr(rti, key, parsed_dates.get(key))
                    elif key in ('is_bpl', 'appealed'):
                        setattr(rti, key, value in (True, 'true', 'True', 1, '1'))
                    elif isinstance(value, str):
                        val_str = value.strip()
                        setattr(rti, key, val_str if val_str else None)
                    else:
                        setattr(rti, key, value)
                    changed_fields.append(key)

            # Check rejection rule: rejected_date requires rejection_reason
            if rti.rejected_date and not (rti.rejection_reason and str(rti.rejection_reason).strip()):
                return Response({'error': 'rejection_reason is required when rejected_date is set.'}, status=status.HTTP_400_BAD_REQUEST)

            # Check appeal rule
            if rti.appealed and not rti.appeal_date:
                return Response({'error': 'appeal_date is required when appealed is True.'}, status=status.HTTP_400_BAD_REQUEST)
            if not rti.appealed and rti.appeal_date:
                rti.appeal_date = None

            rti.save()

            cache.delete(f"rti:counts:{schema}:{station_name}")
            _log_rti_audit(request, 'rti:update', rti.rti_id, changed_fields=changed_fields)

            serializer = RTIApplicationSerializer(rti)
            return Response(serializer.data)


class RTIPdfView(APIView):
    """
    GET /api/rti/<id>/pdf/ - Generate single page PDF report for RTI Application
    """

    @classmethod
    def get_table_rows(cls, rti, schema='public'):
        return get_rti_display_rows(rti, schema=schema)

    def get(self, request, pk):
        schema, err = _resolve_tenant_and_auth(request, 'rti:pdf')
        if err:
            return err

        user = request.user
        station_name = getattr(user, 'station_name', '').strip()

        with TenantContext(schema):
            rti = RTIApplication.objects.filter(pk=pk, station_name__iexact=station_name).first()
            if not rti:
                return Response({'error': 'RTI application not found.'}, status=status.HTTP_404_NOT_FOUND)

        _log_rti_audit(request, 'rti:pdf', rti.rti_id)

        # ReportLab PDF Generation
        from reportlab.lib.pagesizes import A4
        from reportlab.lib import colors
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        import xml.sax.saxutils as saxutils

        # Read state title dynamically from StateRegistry
        state_code = getattr(request, 'state_code', 'MH')
        with TenantContext('public'):
            from apps.public_master.models import StateRegistry
            st_rec = StateRegistry.objects.filter(state_code__iexact=state_code).first()

        if st_rec and st_rec.police_force_title:
            pdf_title = f"{st_rec.police_force_title.strip().upper()} DEPARTMENT"
        elif st_rec and st_rec.state_name:
            pdf_title = f"{st_rec.state_name.strip().upper()} POLICE DEPARTMENT"
        else:
            pdf_title = "POLICE DEPARTMENT"

        pdf_subtitle = _get_setting('pdf_subtitle', 'RTI Application Report')

        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
        story = []

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle('TitleStyle', parent=styles['Heading1'], fontSize=16, leading=20, alignment=1, textColor=colors.HexColor('#1A237E'))
        subtitle_style = ParagraphStyle('SubTitleStyle', parent=styles['Normal'], fontSize=11, leading=14, alignment=1, textColor=colors.HexColor('#37474F'))
        label_style = ParagraphStyle('LabelStyle', parent=styles['Normal'], fontSize=10, leading=12, fontWeight='bold', textColor=colors.HexColor('#263238'))
        value_style = ParagraphStyle('ValueStyle', parent=styles['Normal'], fontSize=10, leading=12, textColor=colors.HexColor('#000000'))

        story.append(Paragraph(f"<b>{pdf_title}</b>", title_style))
        story.append(Paragraph(f"{pdf_subtitle} · Station: {rti.station_name}", subtitle_style))
        story.append(Spacer(1, 15))

        # Single source of truth: no labels, formats, or status words typed in PDF code
        rows = self.get_table_rows(rti, schema=schema)
        table_data = []
        for row in rows:
            lbl_escaped = saxutils.escape(str(row[0] or ''))
            val_escaped = saxutils.escape(str(row[1] or ''))
            table_data.append([
                Paragraph(f"<b>{lbl_escaped}</b>", label_style),
                Paragraph(val_escaped, value_style)
            ])

        t = Table(table_data, colWidths=[180, 340])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#F5F7FA')),
            ('BACKGROUND', (1, 0), (1, -1), colors.HexColor('#FFFFFF')),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CFD8DC')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('PADDING', (0, 0), (-1, -1), 5),
        ]))
        story.append(t)

        doc.build(story)
        pdf_bytes = buffer.getvalue()
        buffer.close()

        response = HttpResponse(pdf_bytes, content_type='application/pdf')
        response['Content-Disposition'] = f'inline; filename="RTI_{rti.serial_year}_{rti.serial_no}.pdf"'
        return response
