import io
import re
import datetime
import logging
from django.db import connection
from django.db.models import Q
from django.db.models.functions import Trim
from django.http import HttpResponse
from rest_framework import status
from rest_framework.response import Response

from apps.core.tenancy import TenantContext, get_active_tenant_schema
from apps.core.models import AuditLog
from apps.users.models import OfficerProfile
from apps.crimetab.models import ModuleSetting, FieldTemplateField, OptionValue
from apps.crimetab import settings_cache

logger = logging.getLogger(__name__)


def word_count(text):
    if not text:
        return 0
    return len(re.findall(r'\b\w+\b', str(text).strip()))


def get_module_setting(module_key, key, default=None):
    s = ModuleSetting.objects.filter(module_key=module_key, setting_key=key).first()
    if not s or s.setting_value is None:
        s = ModuleSetting.objects.filter(module_key='common', setting_key=key).first()
    if s and s.setting_value is not None:
        val = str(s.setting_value).strip()
        if val.isdigit():
            return int(val)
        return val
    return default


def resolve_tenant_and_auth(request, module_key, perm_key=None):
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
    if module_permissions_enforced(module_key, target_schema) and perm_key:
        if not role_has_permission(getattr(user, 'role_id', ''), perm_key):
            return None, Response({'error': f'Permission {perm_key} is required.'}, status=status.HTTP_403_FORBIDDEN)

    return target_schema, None


def module_permissions_enforced(module_key, schema):
    """module_settings.enforce_permissions == 'true' for the module (cached briefly, see settings_cache)."""
    def compute():
        s = ModuleSetting.objects.filter(module_key=module_key, setting_key='enforce_permissions').first()
        return bool(s and str(s.setting_value or '').strip().lower() == 'true')
    return settings_cache.cached(('enforce', schema, module_key), compute)


def role_has_permission(role_id, perm_key):
    """Whether the role is granted perm_key (role_permissions is global; cached briefly)."""
    from apps.public_master.models import RolePermission
    return settings_cache.cached(('role_perm', role_id, perm_key), lambda: RolePermission.objects.filter(
        role_id=role_id, permission_id=perm_key, is_granted=True).exists())


def get_scoped_officers_queryset(user, module_key='mpda'):
    """
    Evaluates role scope hierarchy for the authenticated user based on module_settings:
    1. Station roles (scope_station_roles): active officers with same station_id or trimmed station_name.
    2. Division roles (scope_division_roles): active officers with same division_id or trimmed division_name.
    3. District roles (scope_district_roles): active officers with same district_id or trimmed district.
    4. State roles (scope_state_roles): all active officers of the state tenant schema.
    5. Other/unconfigured roles: None, no_scope_message.
    
    Reuses the exact scoping rules and fallback messages established by RTI.
    """
    user_role = str(getattr(user, 'role_id', '') or '').strip()

    station_roles_str = str(get_module_setting(module_key, 'scope_station_roles', 'officer,station_admin,station_head'))
    station_roles = [r.strip() for r in station_roles_str.split(',') if r.strip()]

    division_roles_str = str(get_module_setting(module_key, 'scope_division_roles', 'division_admin,supervisor'))
    division_roles = [r.strip() for r in division_roles_str.split(',') if r.strip()]

    district_roles_str = str(get_module_setting(module_key, 'scope_district_roles', 'district_admin'))
    district_roles = [r.strip() for r in district_roles_str.split(',') if r.strip()]

    state_roles_str = str(get_module_setting(module_key, 'scope_state_roles', 'state_super_admin'))
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
            msg = get_module_setting(module_key, 'no_station_message', 'No police station assigned to the logged-in user.')
            return None, msg

    elif user_role in division_roles:
        user_division_id = str(getattr(user, 'division_id', '') or '').strip()
        user_division_name = str(getattr(user, 'division_name', '') or '').strip()
        if user_division_id:
            return qs.filter(division_id=user_division_id), None
        elif user_division_name:
            return qs.filter(trimmed_division__iexact=user_division_name).exclude(trimmed_division=''), None
        else:
            msg = get_module_setting(module_key, 'no_division_message', 'No division assigned to the logged-in user.')
            return None, msg

    elif user_role in district_roles:
        user_district_id = str(getattr(user, 'district_id', '') or '').strip()
        user_district = str(getattr(user, 'district', '') or getattr(user, 'district_name', '') or '').strip()
        if user_district_id:
            return qs.filter(district_id=user_district_id), None
        elif user_district:
            return qs.filter(trimmed_district__iexact=user_district).exclude(trimmed_district=''), None
        else:
            msg = get_module_setting(module_key, 'no_district_message', 'No district assigned to the logged-in user.')
            return None, msg

    elif user_role in state_roles:
        return qs, None

    else:
        msg = get_module_setting(module_key, 'no_scope_message', 'User role does not have an officer assignment scope configured.')
        return None, msg


def log_standalone_audit(request, event, module_key, record_id, changed_fields=None, details=None):
    try:
        user = getattr(request, 'user', None)
        uid = getattr(user, 'uid', None) or getattr(user, 'id', 'anonymous')
        name = getattr(user, 'name', None) or getattr(user, 'full_name', '')
        email = getattr(user, 'email', '')
        role = getattr(user, 'role_id', '')
        station = getattr(user, 'station_name', '')

        meta = {'record_id': str(record_id)}
        if changed_fields:
            meta['changed_fields'] = [str(f) for f in changed_fields]

        action_desc = details or f"{module_key.upper()} event '{event}' on ID {record_id}"

        AuditLog.objects.create(
            event=event,
            category=module_key,
            uid=str(uid),
            user_name=str(name),
            user_email=str(email),
            user_role=str(role),
            station_name=str(station),
            action_details=action_desc,
            metadata=meta
        )
    except Exception as e:
        logger.warning(f"[{module_key.upper()} AuditLog] Exception writing audit log: {e}")


def format_display_date(date_val, module_key='common'):
    if not date_val:
        return ""
    fmt = get_module_setting(module_key, 'date_format', '%d/%m/%Y')
    try:
        if isinstance(date_val, (datetime.date, datetime.datetime)):
            return date_val.strftime(fmt)
        # Parse ISO string if needed
        d_str = str(date_val).strip()
        d_obj = datetime.date.fromisoformat(d_str[:10])
        return d_obj.strftime(fmt)
    except Exception:
        return str(date_val)


def parse_display_date(val_str, module_key='common'):
    if not val_str or str(val_str).strip().lower() in ('none', 'null', '', '-'):
        return None
    val_str = str(val_str).strip()
    fmt = get_module_setting(module_key, 'date_format', '%d/%m/%Y')
    # Try custom setting format first
    try:
        return datetime.datetime.strptime(val_str, fmt).date()
    except Exception:
        pass
    # Try standard YYYY-MM-DD
    try:
        return datetime.date.fromisoformat(val_str[:10])
    except Exception:
        pass
    # Try DD/MM/YYYY
    try:
        return datetime.datetime.strptime(val_str, '%d/%m/%Y').date()
    except Exception:
        pass
    return None


def get_template_fields_ordered(template_name):
    if not template_name:
        return []
    with TenantContext('public'):
        return list(FieldTemplateField.objects.filter(template__template_name=template_name).order_by('display_order', 'pk'))


def crime_charge_fields(raw):
    """
    Act / Section / Subsection of a Crime Chart row (History Sheeter and MPDA).
    The picker sends a list with one charge dict (act_id, act_name, section_id,
    section_number, section_title, subsection_id, subsection_code); older records
    send plain text. Returns the columns plus the combined act_section text used
    by the view and the PDF.
    """
    if isinstance(raw, list):
        raw = next((r for r in raw if isinstance(r, dict)), None)
    if not isinstance(raw, dict):
        return {'act_section': str(raw or '').strip()}

    def _int(v):
        try:
            return int(v) if v not in (None, '') else None
        except (TypeError, ValueError):
            return None

    def _txt(v):
        v = str(v or '').strip()
        return v or None

    fields = {
        'act_id': _int(raw.get('act_id')),
        'section_id': _int(raw.get('section_id')),
        'subsection_id': _int(raw.get('subsection_id')),
        'act_name': _txt(raw.get('act_name')),
        'section_number': _txt(raw.get('section_number')),
        'section_title': _txt(raw.get('section_title')),
        'subsection_code': _txt(raw.get('subsection_code')),
    }
    fields['act_section'] = ' / '.join(
        x for x in (fields['act_name'], fields['section_number'], fields['subsection_code']) if x
    )
    return fields


def build_standalone_pdf(request, subtitle, station_name, single_rows, repeating_sections, filename, module_key, title=None):
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    import xml.sax.saxutils as saxutils

    # Resolve state code dynamically from verified token / user credentials - do NOT default or guess
    user = getattr(request, 'user', None)
    state_code = getattr(request, 'state_code', None) or getattr(user, 'state_code', None)
    if not state_code and hasattr(request, 'auth') and isinstance(request.auth, dict):
        state_code = request.auth.get('state_code')

    if not state_code or not str(state_code).strip():
        missing_state_msg = get_module_setting(module_key, 'missing_state_message', 'State code could not be resolved from authenticated user credentials.')
        return Response({'error': missing_state_msg}, status=status.HTTP_400_BAD_REQUEST)

    state_code = str(state_code).strip().upper()

    with TenantContext('public'):
        from apps.public_master.models import StateRegistry
        st_rec = StateRegistry.objects.filter(state_code__iexact=state_code).first()

    # Read department wording (suffixes and fallback) from module_settings, not hardcoded in Python
    dept_suffix = str(get_module_setting(module_key, 'pdf_department_suffix', 'DEPARTMENT') or '').strip()
    police_dept_suffix = str(get_module_setting(module_key, 'pdf_police_department_suffix', 'POLICE DEPARTMENT') or '').strip()
    fallback_title = str(get_module_setting(module_key, 'pdf_fallback_title', 'POLICE DEPARTMENT') or '').strip()

    if st_rec and st_rec.police_force_title:
        pft = st_rec.police_force_title.strip().upper()
        dept_title = f"{pft} {dept_suffix}".strip() if dept_suffix else pft
    elif st_rec and st_rec.state_name:
        sname = st_rec.state_name.strip().upper()
        dept_title = f"{sname} {police_dept_suffix}".strip() if police_dept_suffix else sname
    else:
        dept_title = fallback_title

    main_title = title or dept_title

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
    story = []

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('TitleStyle', parent=styles['Heading1'], fontSize=16, leading=20, alignment=1, textColor=colors.HexColor('#1A237E'))
    subtitle_style = ParagraphStyle('SubTitleStyle', parent=styles['Normal'], fontSize=11, leading=14, alignment=1, textColor=colors.HexColor('#37474F'))
    section_style = ParagraphStyle('SectionStyle', parent=styles['Heading2'], fontSize=12, leading=16, textColor=colors.HexColor('#1A237E'), spaceBefore=10, spaceAfter=6)
    label_style = ParagraphStyle('LabelStyle', parent=styles['Normal'], fontSize=9, leading=12, fontWeight='bold', textColor=colors.HexColor('#263238'))
    value_style = ParagraphStyle('ValueStyle', parent=styles['Normal'], fontSize=9, leading=12, textColor=colors.HexColor('#000000'))
    th_style = ParagraphStyle('THStyle', parent=styles['Normal'], fontSize=9, leading=12, fontWeight='bold', textColor=colors.HexColor('#FFFFFF'), alignment=1)

    story.append(Paragraph(f"<b>{saxutils.escape(str(main_title))}</b>", title_style))
    story.append(Paragraph(f"{subtitle} · Station: {station_name}", subtitle_style))
    story.append(Spacer(1, 15))

    # Single-value fields table
    if single_rows:
        table_data = []
        for lbl, val in single_rows:
            lbl_escaped = saxutils.escape(str(lbl or ''))
            val_escaped = saxutils.escape(str(val or ''))
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
            ('PADDING', (0, 0), (-1, -1), 4),
        ]))
        story.append(t)
        story.append(Spacer(1, 12))

    # Repeating table sections
    if repeating_sections:
        for sec_title, headers, rows in repeating_sections:
            if not rows:
                continue
            story.append(Paragraph(f"<b>{sec_title}</b>", section_style))
            col_count = len(headers)
            col_width = 520 / max(col_count, 1)

            t_data = [[Paragraph(f"<b>{saxutils.escape(h)}</b>", th_style) for h in headers]]
            for r in rows:
                row_cells = []
                for cell in r:
                    cell_escaped = saxutils.escape(str(cell or ''))
                    row_cells.append(Paragraph(cell_escaped, value_style))
                t_data.append(row_cells)

            rep_t = Table(t_data, colWidths=[col_width] * col_count)
            rep_t.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#283593')),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CFD8DC')),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('PADDING', (0, 0), (-1, -1), 4),
            ]))
            story.append(rep_t)
            story.append(Spacer(1, 10))

    doc.build(story)
    pdf_bytes = buffer.getvalue()
    buffer.close()

    response = HttpResponse(pdf_bytes, content_type='application/pdf')
    response['Content-Disposition'] = f'inline; filename="{filename}"'
    return response
