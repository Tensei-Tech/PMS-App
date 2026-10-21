import datetime
import calendar
import hashlib
import io
import json
import logging
import xml.sax.saxutils as saxutils
from django.http import HttpResponse
from django.db import connection, transaction, IntegrityError
from django.db.models import Q, Max, Count, IntegerField, OuterRef, Subquery, Value
from django.db.models.functions import Coalesce, Trim
from django.core.cache import cache
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

from apps.core.tenancy import TenantContext
from apps.crimetab.views_mpda import MpdaNumberedCanvas, resolve_pdf_dept_title
from apps.crimetab.models.history_sheeter import (
    HistorySheeter,
    HistorySheeterRelatedPerson,
    HistorySheeterPreventiveAction,
    HistorySheeterCrime,
)
from apps.crimetab.models import ModuleSetting, FieldTemplateField
from apps.crimetab.serializers_history_sheeter import (
    HistorySheeterListSerializer,
    HistorySheeterDetailSerializer,
)
from apps.crimetab.standalone_helpers import (
    resolve_tenant_and_auth,
    get_module_setting,
    log_standalone_audit,
    format_display_date,
    parse_display_date,
    word_count,
    get_template_fields_ordered,
    crime_charge_fields,
)

logger = logging.getLogger(__name__)


def _get_active_cutoff_date(ref_date=None):
    """
    Computes the Active status cutoff date as N months back from today (default 12),
    reading the period dynamically from module_settings ('active_period_months').
    Handles variable month lengths and leap years safely.
    """
    months = int(get_module_setting('history_sheeter', 'active_period_months', 12))
    today = ref_date or datetime.date.today()
    year = today.year - (months // 12)
    month = today.month - (months % 12)
    if month <= 0:
        month += 12
        year -= 1
    max_day = calendar.monthrange(year, month)[1]
    day = min(today.day, max_day)
    return datetime.date(year, month, day)


# ── Tabs: one filter per tab, shared by the counts and the list ───────────────
def _hs_yes_value():
    """The 'Yes' option of the yes_no group (Currently in Jail / on Bail)."""
    from apps.crimetab.models import OptionValue
    opt = OptionValue.objects.filter(option_group='yes_no', is_active=True) \
        .order_by('display_order', 'id').first()
    return opt.option_value if opt else None


def _hs_tab_q(tab, today, yes_val):
    """
    Q for a tab (None = no filter):
      total  : every history sheet
      open   : opened in the current year (Date of Opening; created date when blank)
      closed : closed in the current year (Date of Closure)
      jail   : Currently in Jail = Yes
      bail   : Currently on Bail = Yes
    'active' needs the crimes join and is handled by the callers.
    """
    year = today.year
    if tab == 'open':
        return Q(opening_date__year=year) | Q(opening_date__isnull=True, created_at__year=year)
    if tab == 'closed':
        return Q(closure_date__year=year)
    if tab == 'jail':
        return Q(currently_in_jail__iexact=yes_val) if yes_val else Q(pk__in=[])
    if tab == 'bail':
        return Q(currently_on_bail__iexact=yes_val) if yes_val else Q(pk__in=[])
    return None


def _clear_hs_cache(schema, station_name):
    if station_name:
        st_hash = hashlib.md5(station_name.strip().encode('utf-8')).hexdigest()
        cache.delete(f"history_sheeter:counts:{schema}:{st_hash}")


# Real history_sheeters columns a form may write. Excludes reverse relations
# (related_persons, crimes, ...) and server-managed columns.
_HS_EDITABLE_COLUMNS = {
    f.name for f in HistorySheeter._meta.concrete_fields
} - {'id', 'station_name', 'sr_no', 'created_by', 'created_at', 'updated_at'}


def _crime_rows(entries):
    """Model kwargs for every Crime Chart row (built in memory, saved with one insert)."""
    rows = []
    for c in entries or []:
        if not isinstance(c, dict):
            continue
        kw = {
            'cr_no': c.get('hs_crime_cr_no') or c.get('cr_no') or '',
            'crime_head': c.get('hs_crime_head') or c.get('crime_head') or '',
            'register_date': parse_display_date(
                c.get('hs_crime_register_date') or c.get('register_date'), 'history_sheeter'),
            'police_station': c.get('hs_crime_police_station') or c.get('police_station') or '',
        }
        kw.update(crime_charge_fields(c.get('hs_crime_act_section', c.get('act_section'))))
        rows.append(kw)
    return rows


def _expand_preventive_actions(entries):
    """
    One (action_type, action_other) per selected action. "Action Taken" is a
    multi-select, so an entry may carry a list (or a comma-joined string) of
    actions; each becomes its own row. The "Other" details text is kept only on
    the action that reveals that field (its depends_on_value in the template).
    """
    other_trigger = (
        FieldTemplateField.objects.filter(field_key='hs_preventive_action_other')
        .values_list('depends_on_value', flat=True).first()
    )
    rows = []
    for pa in entries or []:
        if not isinstance(pa, dict):
            continue
        raw = pa.get('hs_preventive_action_type') or pa.get('action_type') or ''
        if isinstance(raw, (list, tuple)):
            types = [str(t).strip() for t in raw if str(t).strip()]
        else:
            types = [t.strip() for t in str(raw).split(',') if t.strip()]
        other = (pa.get('hs_preventive_action_other') or pa.get('action_other') or '').strip()
        if not types and other:
            types = ['']
        for t in types:
            keep_other = not other_trigger or t.lower() == str(other_trigger).strip().lower()
            rows.append((t, other if keep_other else ''))
    return rows


def _clean_hs_scalars(norm):
    """Coerce form strings into values the history_sheeters columns accept."""
    # Form key hs_category_type_other maps to the category_other column
    if 'category_type_other' in norm:
        norm['category_other'] = norm.pop('category_type_other')

    for num_f in ['age', 'total_cases', 'convicted_cases', 'pending_cases', 'acquitted_discharged_cases']:
        if num_f in norm:
            val = norm[num_f]
            norm[num_f] = int(val) if (val is not None and str(val).strip().isdigit()) else None

    # mobile_no CHECK constraint allows NULL or 10 digits, never ''
    if 'mobile_no' in norm:
        norm['mobile_no'] = str(norm['mobile_no'] or '').strip() or None

    if 'same_as_above' in norm:
        val = norm['same_as_above']
        norm['same_as_above'] = val is True or str(val).strip().lower() in ('true', 'yes', '1')


def _is_empty_hs_payload(data):
    ignored = {'station_name', 'created_by', 'sr_no', 'id'}
    for k, v in data.items():
        if k in ignored:
            continue
        if isinstance(v, list) and len(v) > 0:
            for item in v:
                if isinstance(item, dict) and any(str(val).strip() for val in item.values() if val is not None):
                    return False
        elif v is not None and str(v).strip() != '':
            return False
    return True


def get_hs_display_rows(hs, schema='public'):
    """
    Constructs ordered (label, display_value) rows based on field_template_fields.
    """
    tmpl_name = get_module_setting('history_sheeter', 'template_name')
    ftfs = get_template_fields_ordered(tmpl_name) if tmpl_name else []
    attr_map = _hs_attr_map(hs)

    rows = [('Sr. No.', f"HS-{hs.station_name}/{hs.sr_no}")]
    for ftf in ftfs:
        if not _is_hs_scalar_visible(ftf, attr_map):
            continue
        disp_val = attr_map.get(ftf.field_key, '')
        rows.append((ftf.field_label, disp_val))

    return rows


def _is_hs_scalar_visible(ftf, attr_map):
    """True for a non-repeating field whose depends_on condition (if any) is met."""
    if ftf.field_type == 'repeating_group' or ftf.parent_field_key:
        return False
    if ftf.depends_on_field_key:
        parent_val = attr_map.get(ftf.depends_on_field_key, '')
        dep_target = str(ftf.depends_on_value or '').strip()
        if dep_target.lower() not in parent_val.lower():
            return False
    return True


def _hs_attr_map(hs):
    """field_key -> display string for every scalar History Sheeter field."""
    return {
        'hs_name': hs.name or '',
        'hs_alias': hs.alias or '',
        'hs_nickname': hs.nickname or '',
        'hs_age': str(hs.age) if hs.age is not None else '',
        'hs_gender': hs.gender or '',
        'hs_mobile_no': hs.mobile_no or '',
        'hs_address': hs.address or '',
        'hs_permanent_address': hs.permanent_address or '',
        'hs_present_address': hs.present_address or '',
        'hs_same_as_above': 'Yes' if hs.same_as_above else 'No',
        'hs_native_place': hs.native_place or '',
        'hs_occupation': hs.occupation or '',
        'hs_aadhaar_id_details': hs.aadhaar_id_details or '',
        'hs_history_sheet_no': hs.history_sheet_no or '',
        'hs_opening_date': format_display_date(hs.opening_date, 'history_sheeter'),
        'hs_order_date': format_display_date(hs.order_date, 'history_sheeter'),
        'hs_category_type': ", ".join(hs.categories) if hs.categories else '',
        'hs_category_type_other': hs.category_other or '',
        'hs_modus_operandi': hs.modus_operandi or '',
        'hs_total_cases': str(hs.total_cases) if hs.total_cases is not None else '',
        'hs_convicted_cases': str(hs.convicted_cases) if hs.convicted_cases is not None else '',
        'hs_pending_cases': str(hs.pending_cases) if hs.pending_cases is not None else '',
        'hs_acquitted_discharged_cases': str(hs.acquitted_discharged_cases) if hs.acquitted_discharged_cases is not None else '',
        'hs_whereabouts': hs.whereabouts or '',
        'hs_last_verification_date': format_display_date(hs.last_verification_date, 'history_sheeter'),
        'hs_verification_remarks': hs.verification_remarks or '',
        'hs_currently_in_jail': hs.currently_in_jail or '',
        'hs_currently_on_bail': hs.currently_on_bail or '',
        'hs_closure_date': format_display_date(hs.closure_date, 'history_sheeter'),
        'hs_closure_reason': hs.closure_reason or '',
        'hs_closure_remarks': hs.closure_remarks or '',
    }


def get_hs_repeating_sections(hs, ftfs=None):
    """
    Constructs ordered repeating sections based on field_template_fields:
    Returns list of tuples: (section_title, headers, rows, field_key)
    """
    if ftfs is None:
        tmpl_name = get_module_setting('history_sheeter', 'template_name')
        ftfs = get_template_fields_ordered(tmpl_name) if tmpl_name else []

    rep_groups = [f for f in ftfs if f.field_type == 'repeating_group']
    sections = []

    for rg in rep_groups:
        child_fields = [f for f in ftfs if f.parent_field_key == rg.field_key]
        headers = [f.field_label for f in child_fields]
        rows = []

        if rg.field_key == 'hs_associates':
            for p in hs.related_persons.filter(person_type='associate').order_by('pk'):
                rows.append([
                    p.name or '', p.alias or '', p.nickname or '',
                    str(p.age or ''), p.gender or '', p.mobile_no or '', p.address or ''
                ])
        elif rg.field_key == 'hs_rivals':
            for p in hs.related_persons.filter(person_type='rival').order_by('pk'):
                rows.append([
                    p.name or '', p.alias or '', p.nickname or '',
                    str(p.age or ''), p.gender or '', p.mobile_no or '', p.address or ''
                ])
        elif rg.field_key == 'hs_sureties':
            for p in hs.related_persons.filter(person_type='surety').order_by('pk'):
                rows.append([
                    p.name or '', p.alias or '', p.nickname or '',
                    str(p.age or ''), p.gender or '', p.mobile_no or '', p.address or ''
                ])
        elif rg.field_key == 'hs_preventive_actions':
            for pa in hs.preventive_actions.all().order_by('pk'):
                rows.append([pa.action_type or '', pa.action_other or ''])
        elif rg.field_key == 'hs_crime_chart':
            for c in hs.crimes.all().order_by('register_date', 'pk'):
                rows.append([
                    c.cr_no or '', c.crime_head or '', c.act_section or '',
                    format_display_date(c.register_date, 'history_sheeter'), c.police_station or ''
                ])

        sections.append((rg.field_label, headers, rows, rg.field_key))

    return sections


class HistorySheeterConfigView(APIView):
    """
    GET /api/history-sheeter/config/ - Dynamic configuration from module_settings
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'history_sheeter', 'history_sheeter:view')
        if err:
            return err

        settings_qs = ModuleSetting.objects.filter(Q(module_key='history_sheeter') | Q(module_key='common'))
        smap = {s.setting_key: s.setting_value for s in settings_qs}

        copy_rules_val = smap.get('copy_on_tick_rules', '')
        copy_rules = []
        if copy_rules_val:
            try:
                loaded = json.loads(copy_rules_val)
                copy_rules = loaded if isinstance(loaded, list) else [loaded]
            except Exception:
                copy_rules = []

        data = {
            'target_category_code': smap.get('target_category_code', ''),
            'sub_tab_labels': {
                'total': smap.get('tab_total_label', ''),
                'active': smap.get('tab_active_label', ''),
                'open': smap.get('tab_open_label', ''),
                'closed': smap.get('tab_closed_label', ''),
                'jail': smap.get('tab_jail_label', ''),
                'bail': smap.get('tab_bail_label', ''),
                'chart': smap.get('tab_chart_label', ''),
            },
            'chart_headers': {
                k: smap.get(f'chart_header_{k}', '') for k in _CHART_COLUMNS
            },
            'action_labels': {
                'add': smap.get('btn_add_label', ''),
                'edit': smap.get('btn_edit_label', ''),
                'view': smap.get('btn_view_label', ''),
                'pdf': smap.get('btn_pdf_label', ''),
            },
            'search_placeholder': smap.get('search_placeholder', ''),
            'empty_request_message': smap.get('empty_request_message', ''),
            'word_limits': {
                'modus_operandi': int(smap.get('word_limit_modus_operandi', 25)),
                'whereabouts': int(smap.get('word_limit_whereabouts', 25)),
            },
            'max_serial_retries': int(smap.get('max_serial_retries', 5)),
            'active_period_months': int(smap.get('active_period_months', 12)),
            'date_format': smap.get('date_format', '%d/%m/%Y'),
            'page_size': int(smap.get('page_size', 20)),
            'copy_on_tick_rules': copy_rules,
        }
        return Response(data)


# Chart tab columns, in display order (header text: module_settings chart_header_<key>)
_CHART_COLUMNS = ('sr_no', 'person', 'total_cases', 'associates', 'rivals', 'preventive', 'actions')


def _render_person_line(hs, template, separator):
    """
    Combined Name / Age / Gender / Address / Mobile text from the module_settings
    template. The template is split on '|' into parts; a part whose placeholders
    are all empty is skipped. Aadhaar is never part of it.
    """
    values = {
        'name': (hs.name or '').strip(),
        'age': str(hs.age) if hs.age is not None else '',
        'gender': (hs.gender or '').strip(),
        'address': (hs.address or hs.present_address or hs.permanent_address or '').strip(),
        'mobile': (hs.mobile_no or '').strip(),
    }
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


class HistorySheeterChartView(APIView):
    """
    GET /api/history-sheeter/chart/?page=&q= - Chart tab: ALL history sheets of the
    user's station (open and closed), one row per sheet, with counts of associate,
    rival and preventive-action rows. ONE query for the page (counts are
    correlated subqueries), plus one COUNT for pagination.
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'history_sheeter', 'history_sheeter:view')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()
        if not station_name:
            return Response({'error': get_module_setting('history_sheeter', 'no_station_message') or ''},
                            status=status.HTTP_400_BAD_REQUEST)

        settings_map = {
            s_.setting_key: s_.setting_value for s_ in ModuleSetting.objects.filter(
                module_key='history_sheeter',
                setting_key__in=['chart_person_template', 'chart_person_separator', 'page_size'],
            )
        }
        try:
            page_size = int(settings_map.get('page_size') or 20)
            page = max(int(request.query_params.get('page', 1)), 1)
        except ValueError:
            page_size, page = 20, 1

        def count_of(qs):
            return Coalesce(Subquery(
                qs.order_by().values('history_sheeter_id').annotate(c=Count('id')).values('c')[:1],
                output_field=IntegerField()), Value(0))

        with TenantContext(schema):
            qs = HistorySheeter.objects.filter(station_name__iexact=station_name)
            q = request.query_params.get('q', '').strip()
            if q:
                if q.isdigit():
                    qs = qs.filter(Q(sr_no=int(q)) | Q(name__icontains=q) | Q(alias__icontains=q) | Q(history_sheet_no__icontains=q))
                else:
                    qs = qs.filter(Q(name__icontains=q) | Q(alias__icontains=q) | Q(history_sheet_no__icontains=q) | Q(nickname__icontains=q))

            total_count = qs.count()
            persons = HistorySheeterRelatedPerson.objects.filter(history_sheeter=OuterRef('pk'))
            rows = list(
                qs.annotate(
                    associates_count=count_of(persons.filter(person_type='associate')),
                    rivals_count=count_of(persons.filter(person_type='rival')),
                    preventive_count=count_of(
                        HistorySheeterPreventiveAction.objects.filter(history_sheeter=OuterRef('pk'))),
                ).order_by('sr_no', 'id')[(page - 1) * page_size: page * page_size]
            )

        template = settings_map.get('chart_person_template')
        separator = settings_map.get('chart_person_separator')
        if template is None:
            logger.warning("[HistorySheeter] module_settings missing: history_sheeter.chart_person_template")
        results = [{
            'id': hs.id,
            'sr_no': hs.sr_no,
            'name': hs.name or '',
            'person': _render_person_line(hs, template, separator),
            'total_cases': hs.total_cases,
            'associates': hs.associates_count,
            'rivals': hs.rivals_count,
            'preventive': hs.preventive_count,
        } for hs in rows]
        return Response({'count': total_count, 'page': page, 'page_size': page_size, 'results': results})


class HistorySheeterCountsView(APIView):
    """
    GET /api/history-sheeter/counts/ - Single query aggregated counts cached dynamically
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'history_sheeter', 'history_sheeter:view')
        if err:
            return err

        user = request.user
        station_name = getattr(user, 'station_name', '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        st_hash = hashlib.md5(station_name.encode('utf-8')).hexdigest()
        cache_key = f"history_sheeter:counts:{schema}:{st_hash}"
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        today = datetime.date.today()
        with TenantContext(schema):
            cutoff = _get_active_cutoff_date()
            yes_val = _hs_yes_value()
            counts = HistorySheeter.objects.filter(station_name__iexact=station_name).aggregate(
                total=Count('id', distinct=True),
                total_open=Count('id', filter=_hs_tab_q('open', today, yes_val), distinct=True),
                total_closed=Count('id', filter=_hs_tab_q('closed', today, yes_val), distinct=True),
                total_jail=Count('id', filter=_hs_tab_q('jail', today, yes_val), distinct=True),
                total_bail=Count('id', filter=_hs_tab_q('bail', today, yes_val), distinct=True),
                total_active=Count('id', filter=Q(closure_date__isnull=True, crimes__register_date__gte=cutoff), distinct=True),
            )

        data = {
            'total': counts['total'] or 0,
            'active': counts['total_active'] or 0,
            'open': counts['total_open'] or 0,
            'closed': counts['total_closed'] or 0,
            'jail': counts['total_jail'] or 0,
            'bail': counts['total_bail'] or 0,
        }
        cache_ttl = int(get_module_setting('history_sheeter', 'counts_cache_timeout', 45))
        cache.set(cache_key, data, timeout=cache_ttl)
        return Response(data)


class HistorySheeterListCreateView(APIView):
    """
    GET /api/history-sheeter/ - Paginated list filtered by tab (active, open, closed) or category
    POST /api/history-sheeter/ - Create new History Sheeter
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'history_sheeter', 'history_sheeter:view')
        if err:
            return err

        user = request.user
        station_name = getattr(user, 'station_name', '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        with TenantContext(schema):
            qs = HistorySheeter.objects.filter(station_name__iexact=station_name)

            tab = request.query_params.get('tab', '').strip().lower()
            if tab == 'active':
                cutoff = _get_active_cutoff_date()
                qs = qs.filter(closure_date__isnull=True, crimes__register_date__gte=cutoff).distinct()
            elif tab in ('open', 'closed', 'jail', 'bail'):
                qs = qs.filter(_hs_tab_q(tab, datetime.date.today(), _hs_yes_value()))

            cat = request.query_params.get('category', '').strip()
            if cat:
                if connection.vendor == 'postgresql':
                    qs = qs.filter(categories__contains=[cat])
                else:
                    # SQLite test fallback
                    qs = qs.filter(categories__contains=cat)

            q = request.query_params.get('q', '').strip()
            if q:
                if q.isdigit():
                    qs = qs.filter(Q(sr_no=int(q)) | Q(name__icontains=q) | Q(alias__icontains=q) | Q(history_sheet_no__icontains=q))
                else:
                    qs = qs.filter(Q(name__icontains=q) | Q(alias__icontains=q) | Q(history_sheet_no__icontains=q) | Q(nickname__icontains=q))

            page_size = int(get_module_setting('history_sheeter', 'page_size', 20))
            try:
                page = int(request.query_params.get('page', 1))
            except ValueError:
                page = 1

            total_count = qs.count()
            start = (page - 1) * page_size
            end = start + page_size
            results = list(qs.order_by('-sr_no')[start:end])

            serializer = HistorySheeterListSerializer(results, many=True)
            return Response({
                'count': total_count,
                'page': page,
                'page_size': page_size,
                'results': serializer.data,
            })

    def post(self, request):
        schema, err = resolve_tenant_and_auth(request, 'history_sheeter', 'history_sheeter:create')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        raw_data = request.data
        if _is_empty_hs_payload(raw_data):
            empty_msg = get_module_setting('history_sheeter', 'empty_request_message', 'Cannot save empty record. At least one field must be filled.')
            return Response({'error': empty_msg}, status=status.HTTP_400_BAD_REQUEST)

        # Word limit validation
        limit_mo = int(get_module_setting('history_sheeter', 'word_limit_modus_operandi', 25))
        if word_count(raw_data.get('hs_modus_operandi') or raw_data.get('modus_operandi')) > limit_mo:
            return Response({'error': f'Criminal Activities / Modus Operandi exceeds word limit of {limit_mo} words.'}, status=status.HTTP_400_BAD_REQUEST)

        limit_wh = int(get_module_setting('history_sheeter', 'word_limit_whereabouts', 25))
        if word_count(raw_data.get('hs_whereabouts') or raw_data.get('whereabouts')) > limit_wh:
            return Response({'error': f'Current Whereabouts exceeds word limit of {limit_wh} words.'}, status=status.HTTP_400_BAD_REQUEST)

        # Field mapping
        norm = {}
        for k, v in raw_data.items():
            key = k[3:] if k.startswith('hs_') else k
            norm[key] = v

        # Date parsing
        date_fields = ['opening_date', 'order_date', 'last_verification_date', 'closure_date']
        for df in date_fields:
            if df in norm:
                norm[df] = parse_display_date(norm[df], 'history_sheeter')

        # Handle categories text[]
        cats = norm.get('category_type') or norm.get('categories') or []
        if isinstance(cats, str):
            cats = [c.strip() for c in cats.split(',') if c.strip()]
        norm['categories'] = list(cats)

        _clean_hs_scalars(norm)

        # Extract repeating groups
        associates_data = norm.pop('associates', []) or []
        rivals_data = norm.pop('rivals', []) or []
        sureties_data = norm.pop('sureties', []) or []
        prev_actions_data = norm.pop('preventive_actions', []) or []
        crimes_data = norm.pop('crime_chart', []) or []

        # Read serial retry limit from module_settings (NO HARDCODING)
        max_retries = int(get_module_setting('history_sheeter', 'max_serial_retries', 5))

        with TenantContext(schema):
            hs = None
            for attempt in range(max_retries):
                try:
                    with transaction.atomic():
                        max_sr = HistorySheeter.objects.filter(station_name__iexact=station_name).aggregate(Max('sr_no'))['sr_no__max']
                        sr_no = (max_sr or 0) + 1

                        main_kwargs = {k: norm[k] for k in norm if k in _HS_EDITABLE_COLUMNS}
                        hs = HistorySheeter.objects.create(
                            station_name=station_name,
                            sr_no=sr_no,
                            created_by=str(getattr(user, 'uid', '') or getattr(user, 'name', '') or ''),
                            **main_kwargs
                        )

                        # Save repeating associates
                        for a in associates_data:
                            a_age = a.get('hs_assoc_age') or a.get('age')
                            HistorySheeterRelatedPerson.objects.create(
                                history_sheeter=hs,
                                person_type='associate',
                                name=a.get('hs_assoc_name') or a.get('name') or '',
                                alias=a.get('hs_assoc_alias') or a.get('alias') or '',
                                nickname=a.get('hs_assoc_nickname') or a.get('nickname') or '',
                                age=int(a_age) if str(a_age or '').isdigit() else None,
                                gender=a.get('hs_assoc_gender') or a.get('gender') or '',
                                mobile_no=a.get('hs_assoc_mobile') or a.get('mobile_no') or None,
                                address=a.get('hs_assoc_address') or a.get('address') or '',
                            )

                        # Save repeating rivals
                        for r in rivals_data:
                            r_age = r.get('hs_rival_age') or r.get('age')
                            HistorySheeterRelatedPerson.objects.create(
                                history_sheeter=hs,
                                person_type='rival',
                                name=r.get('hs_rival_name') or r.get('name') or '',
                                alias=r.get('hs_rival_alias') or r.get('alias') or '',
                                nickname=r.get('hs_rival_nickname') or r.get('nickname') or '',
                                age=int(r_age) if str(r_age or '').isdigit() else None,
                                gender=r.get('hs_rival_gender') or r.get('gender') or '',
                                mobile_no=r.get('hs_rival_mobile') or r.get('mobile_no') or None,
                                address=r.get('hs_rival_address') or r.get('address') or '',
                            )

                        # Save repeating sureties
                        for s in sureties_data:
                            s_age = s.get('hs_surety_age') or s.get('age')
                            HistorySheeterRelatedPerson.objects.create(
                                history_sheeter=hs,
                                person_type='surety',
                                name=s.get('hs_surety_name') or s.get('name') or '',
                                alias=s.get('hs_surety_alias') or s.get('alias') or '',
                                nickname=s.get('hs_surety_nickname') or s.get('nickname') or '',
                                age=int(s_age) if str(s_age or '').isdigit() else None,
                                gender=s.get('hs_surety_gender') or s.get('gender') or '',
                                mobile_no=s.get('hs_surety_mobile') or s.get('mobile_no') or None,
                                address=s.get('hs_surety_address') or s.get('address') or '',
                            )

                        # Save repeating preventive actions
                        HistorySheeterPreventiveAction.objects.bulk_create([
                            HistorySheeterPreventiveAction(history_sheeter=hs, action_type=t, action_other=o)
                            for t, o in _expand_preventive_actions(prev_actions_data)
                        ])

                        # Save repeating crimes
                        HistorySheeterCrime.objects.bulk_create([
                            HistorySheeterCrime(history_sheeter=hs, **kw) for kw in _crime_rows(crimes_data)
                        ])
                        break
                except IntegrityError:
                    if attempt == max_retries - 1:
                        raise

            _clear_hs_cache(schema, station_name)
            log_standalone_audit(request, 'history_sheeter:create', 'history_sheeter', hs.id)

            serializer = HistorySheeterDetailSerializer(hs)
            return Response(serializer.data, status=status.HTTP_201_CREATED)


class HistorySheeterDetailView(APIView):
    """
    GET /api/history-sheeter/<pk>/ - View History Sheeter with display rows
    PATCH /api/history-sheeter/<pk>/ - Update History Sheeter
    """
    def get(self, request, pk):
        schema, err = resolve_tenant_and_auth(request, 'history_sheeter', 'history_sheeter:view')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()

        with TenantContext(schema):
            hs = HistorySheeter.objects.annotate(trimmed_station=Trim('station_name')).filter(
                pk=pk, trimmed_station__iexact=station_name
            ).first()
            if not hs:
                not_found_msg = get_module_setting('history_sheeter', 'not_found_message') or 'Record not found.'
                return Response({'error': not_found_msg}, status=status.HTTP_404_NOT_FOUND)

            serializer = HistorySheeterDetailSerializer(hs)
            data = serializer.data
            tmpl_name = get_module_setting('history_sheeter', 'template_name')
            ftfs = get_template_fields_ordered(tmpl_name) if tmpl_name else []
            data['display_rows'] = get_hs_display_rows(hs, schema=schema)

            rep_sections = get_hs_repeating_sections(hs, ftfs=ftfs)
            data['repeating_sections'] = [
                {'field_key': k, 'section_title': t, 'headers': h, 'rows': r}
                for (t, h, r, k) in rep_sections
            ]
            data['associates'] = [
                r for r in data.get('related_persons', []) if r.get('person_type') == 'associate'
            ]
            data['rivals'] = [
                r for r in data.get('related_persons', []) if r.get('person_type') == 'rival'
            ]
            data['sureties'] = [
                r for r in data.get('related_persons', []) if r.get('person_type') == 'surety'
            ]
            data['preventive_actions'] = data.get('preventive_actions', [])
            data['crime_chart'] = data.get('crimes', [])
            return Response(data)

    def patch(self, request, pk):
        schema, err = resolve_tenant_and_auth(request, 'history_sheeter', 'history_sheeter:update')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()

        with TenantContext(schema):
            hs = HistorySheeter.objects.annotate(trimmed_station=Trim('station_name')).filter(
                pk=pk, trimmed_station__iexact=station_name
            ).first()
            if not hs:
                not_found_msg = get_module_setting('history_sheeter', 'not_found_message') or 'Record not found.'
                return Response({'error': not_found_msg}, status=status.HTTP_404_NOT_FOUND)

            raw_data = request.data
            norm = {}
            for k, v in raw_data.items():
                key = k[3:] if k.startswith('hs_') else k
                norm[key] = v

            # Word limit checks on merged state
            limit_mo = int(get_module_setting('history_sheeter', 'word_limit_modus_operandi', 25))
            merged_mo = norm.get('modus_operandi', hs.modus_operandi)
            if word_count(merged_mo) > limit_mo:
                return Response({'error': f'Criminal Activities / Modus Operandi exceeds word limit of {limit_mo} words.'}, status=status.HTTP_400_BAD_REQUEST)

            limit_wh = int(get_module_setting('history_sheeter', 'word_limit_whereabouts', 25))
            merged_wh = norm.get('whereabouts', hs.whereabouts)
            if word_count(merged_wh) > limit_wh:
                return Response({'error': f'Current Whereabouts exceeds word limit of {limit_wh} words.'}, status=status.HTTP_400_BAD_REQUEST)

            date_fields = ['opening_date', 'order_date', 'last_verification_date', 'closure_date']
            for df in date_fields:
                if df in norm:
                    norm[df] = parse_display_date(norm[df], 'history_sheeter')

            if 'category_type' in norm or 'categories' in norm:
                cats = norm.get('category_type') or norm.get('categories') or []
                if isinstance(cats, str):
                    cats = [c.strip() for c in cats.split(',') if c.strip()]
                norm['categories'] = list(cats)

            _clean_hs_scalars(norm)

            changed_fields = []
            with transaction.atomic():
                for k, v in norm.items():
                    if k in _HS_EDITABLE_COLUMNS:
                        setattr(hs, k, v)
                        changed_fields.append(k)

                hs.save()

                # Update repeating groups if supplied in payload
                if 'associates' in norm:
                    hs.related_persons.filter(person_type='associate').delete()
                    for a in norm['associates']:
                        a_age = a.get('hs_assoc_age') or a.get('age')
                        HistorySheeterRelatedPerson.objects.create(
                            history_sheeter=hs, person_type='associate',
                            name=a.get('hs_assoc_name') or a.get('name') or '',
                            alias=a.get('hs_assoc_alias') or a.get('alias') or '',
                            nickname=a.get('hs_assoc_nickname') or a.get('nickname') or '',
                            age=int(a_age) if str(a_age or '').isdigit() else None,
                            gender=a.get('hs_assoc_gender') or a.get('gender') or '',
                            mobile_no=a.get('hs_assoc_mobile') or a.get('mobile_no') or None,
                            address=a.get('hs_assoc_address') or a.get('address') or '',
                        )

                if 'rivals' in norm:
                    hs.related_persons.filter(person_type='rival').delete()
                    for r in norm['rivals']:
                        r_age = r.get('hs_rival_age') or r.get('age')
                        HistorySheeterRelatedPerson.objects.create(
                            history_sheeter=hs, person_type='rival',
                            name=r.get('hs_rival_name') or r.get('name') or '',
                            alias=r.get('hs_rival_alias') or r.get('alias') or '',
                            nickname=r.get('hs_rival_nickname') or r.get('nickname') or '',
                            age=int(r_age) if str(r_age or '').isdigit() else None,
                            gender=r.get('hs_rival_gender') or r.get('gender') or '',
                            mobile_no=r.get('hs_rival_mobile') or r.get('mobile_no') or None,
                            address=r.get('hs_rival_address') or r.get('address') or '',
                        )

                if 'sureties' in norm:
                    hs.related_persons.filter(person_type='surety').delete()
                    for s in norm['sureties']:
                        s_age = s.get('hs_surety_age') or s.get('age')
                        HistorySheeterRelatedPerson.objects.create(
                            history_sheeter=hs, person_type='surety',
                            name=s.get('hs_surety_name') or s.get('name') or '',
                            alias=s.get('hs_surety_alias') or s.get('alias') or '',
                            nickname=s.get('hs_surety_nickname') or s.get('nickname') or '',
                            age=int(s_age) if str(s_age or '').isdigit() else None,
                            gender=s.get('hs_surety_gender') or s.get('gender') or '',
                            mobile_no=s.get('hs_surety_mobile') or s.get('mobile_no') or None,
                            address=s.get('hs_surety_address') or s.get('address') or '',
                        )

                if 'preventive_actions' in norm:
                    hs.preventive_actions.all().delete()
                    HistorySheeterPreventiveAction.objects.bulk_create([
                        HistorySheeterPreventiveAction(history_sheeter=hs, action_type=t, action_other=o)
                        for t, o in _expand_preventive_actions(norm['preventive_actions'])
                    ])

                if 'crime_chart' in norm:
                    hs.crimes.all().delete()
                    HistorySheeterCrime.objects.bulk_create([
                        HistorySheeterCrime(history_sheeter=hs, **kw) for kw in _crime_rows(norm['crime_chart'])
                    ])

            _clear_hs_cache(schema, station_name)
            log_standalone_audit(request, 'history_sheeter:update', 'history_sheeter', hs.id, changed_fields=changed_fields)

            serializer = HistorySheeterDetailSerializer(hs)
            return Response(serializer.data)


def build_hs_pdf(request, hs, ftfs, filename):
    """
    Builds the History Sheeter PDF in the same layout as the MPDA proposal PDF:
    - State police department header, subtitle and meta bar
    - One numbered section per template section (from field_template_fields)
    - Scalar fields as a 4-column label/value grid, long text spanning the row
    - Repeating groups as navy-header tables
    - Numbered footer with official confidentiality marking
    """
    user = getattr(request, 'user', None)
    state_code = getattr(request, 'state_code', None) or getattr(user, 'state_code', None)
    if not state_code and hasattr(request, 'auth') and isinstance(request.auth, dict):
        state_code = request.auth.get('state_code')

    if not state_code or not str(state_code).strip():
        missing_state_msg = get_module_setting('history_sheeter', 'missing_state_message', 'State code could not be resolved from authenticated user credentials.')
        return Response({'error': missing_state_msg}, status=status.HTTP_400_BAD_REQUEST)

    dept_title = resolve_pdf_dept_title('history_sheeter', state_code)
    subtitle = get_module_setting('history_sheeter', 'pdf_subtitle') or 'HISTORY SHEET'

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, leftMargin=36, rightMargin=36, topMargin=36, bottomMargin=42)

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('HsDocTitle', parent=styles['Heading1'], fontName='Helvetica-Bold', fontSize=15,
                                 leading=18, alignment=1, textColor=colors.HexColor('#1E293B'), spaceAfter=3)
    subtitle_style = ParagraphStyle('HsDocSubtitle', parent=styles['Normal'], fontName='Helvetica', fontSize=10,
                                    leading=13, alignment=1, textColor=colors.HexColor('#475569'), spaceAfter=8)
    badge_style = ParagraphStyle('HsDocBadge', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=9,
                                 leading=12, alignment=1, textColor=colors.HexColor('#1E3A8A'))
    sec_heading_style = ParagraphStyle('HsSecHeading', parent=styles['Heading2'], fontName='Helvetica-Bold', fontSize=11,
                                       leading=15, textColor=colors.HexColor('#1E3A8A'), spaceBefore=10, spaceAfter=4)
    sub_heading_style = ParagraphStyle('HsSubHeading', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=9.5,
                                       leading=13, textColor=colors.HexColor('#334155'), spaceBefore=4, spaceAfter=3)
    lbl_style = ParagraphStyle('HsGridLabel', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=8.5,
                               leading=11, textColor=colors.HexColor('#334155'))
    val_style = ParagraphStyle('HsGridVal', parent=styles['Normal'], fontName='Helvetica', fontSize=8.5,
                               leading=11, textColor=colors.HexColor('#0F172A'))
    th_style = ParagraphStyle('HsTableTh', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=8.5,
                              leading=11, alignment=1, textColor=colors.white)

    def esc(v):
        return saxutils.escape(str(v)) if v not in (None, '') else '-'

    grid_style = TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#F8FAFC')),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 3.5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3.5),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
    ])

    def build_grid(items):
        """items: [(label, value, full_width)] -> 4-column grid; full_width rows span cols 1-3."""
        data, extra = [], []
        pending = None
        for label, value, full in items:
            cells = [Paragraph(f'<b>{saxutils.escape(label)}</b>', lbl_style), Paragraph(esc(value), val_style)]
            if full:
                if pending:
                    data.append(pending + ['', ''])
                    pending = None
                data.append(cells + ['', ''])
                extra.append(('SPAN', (1, len(data) - 1), (3, len(data) - 1)))
            elif pending:
                data.append(pending + cells)
                extra.append(('BACKGROUND', (2, len(data) - 1), (2, len(data) - 1), colors.HexColor('#F8FAFC')))
                pending = None
            else:
                pending = cells
        if pending:
            data.append(pending + ['', ''])
        t = Table(data, colWidths=[115, 145, 115, 145])
        t.setStyle(grid_style)
        if extra:
            t.setStyle(TableStyle(extra))
        return t

    def build_table(headers, rows):
        widths = [30] + [490 / max(len(headers), 1)] * len(headers)
        data = [[Paragraph('<b>Sr. No.</b>', th_style)] + [Paragraph(f'<b>{saxutils.escape(h)}</b>', th_style) for h in headers]]
        for idx, r in enumerate(rows, 1):
            data.append([Paragraph(str(idx), val_style)] + [Paragraph(esc(v), val_style) for v in r])
        t = Table(data, colWidths=widths, repeatRows=1)
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1E3A8A')),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
            ('ALIGN', (0, 1), (0, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 3.5),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 3.5),
            ('LEFTPADDING', (0, 0), (-1, -1), 4),
            ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ]))
        return t

    story = []

    # 1. Main header + meta bar
    story.append(Paragraph(f'<b>{saxutils.escape(dept_title)}</b>', title_style))
    story.append(Paragraph(saxutils.escape(subtitle), subtitle_style))

    status_str = 'Closed' if hs.closure_date else 'Open'
    no_cell = (f'<b>History Sheet No:</b> {saxutils.escape(str(hs.history_sheet_no))}'
               if hs.history_sheet_no else f'<b>Sr. No:</b> {hs.sr_no}')
    t_meta = Table([[
        Paragraph(no_cell, badge_style),
        Paragraph(f'<b>Station:</b> {esc(hs.station_name)}', badge_style),
        Paragraph(f'<b>Status:</b> {status_str}', badge_style),
    ]], colWidths=[174, 173, 173])
    t_meta.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#EEF2FF')),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#C7D2FE')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
    ]))
    story.append(t_meta)
    story.append(Spacer(1, 8))

    # 2. Sections in template order
    attr_map = _hs_attr_map(hs)
    rep_by_key = {k: (t, h, r) for (t, h, r, k) in get_hs_repeating_sections(hs, ftfs=ftfs)}

    sections = []  # [(section_title, [ftf, ...])]
    for ftf in ftfs:
        if ftf.parent_field_key:
            continue
        sec = (ftf.section or 'Details').strip()
        if not sections or sections[-1][0] != sec:
            sections.append((sec, []))
        sections[-1][1].append(ftf)

    sec_no = 0
    for sec_title, fields in sections:
        flowables = []
        grid_items = []

        def flush_grid():
            if grid_items:
                flowables.append(build_grid(list(grid_items)))
                flowables.append(Spacer(1, 6))
                grid_items.clear()

        for ftf in fields:
            if ftf.field_type == 'repeating_group':
                flush_grid()
                title, headers, rows = rep_by_key.get(ftf.field_key, (ftf.field_label, [], []))
                if len(fields) > 1:
                    flowables.append(Paragraph(f'<b>{saxutils.escape(title)}</b>', sub_heading_style))
                if rows:
                    flowables.append(build_table(headers, rows))
                else:
                    flowables.append(Paragraph(f'No {saxutils.escape(title.lower())} recorded.', val_style))
                flowables.append(Spacer(1, 6))
            elif _is_hs_scalar_visible(ftf, attr_map):
                # Copy-on-tick helper checkboxes add nothing to a printed record
                if ftf.field_type == 'checkbox':
                    continue
                grid_items.append((ftf.field_label, attr_map.get(ftf.field_key, ''), ftf.field_type == 'textarea'))
        flush_grid()

        if not flowables:
            continue
        sec_no += 1
        heading = Paragraph(f'<b>{sec_no}. {saxutils.escape(sec_title.upper())}</b>', sec_heading_style)
        story.append(KeepTogether([heading, flowables[0]]))
        story.extend(flowables[1:])

    doc.build(story, canvasmaker=MpdaNumberedCanvas)
    pdf_bytes = buffer.getvalue()
    buffer.close()

    response = HttpResponse(pdf_bytes, content_type='application/pdf')
    response['Content-Disposition'] = f'inline; filename="{filename}"'
    return response


class HistorySheeterPDFView(APIView):
    """
    GET /api/history-sheeter/<pk>/pdf/ - Downloadable / inline PDF
    """
    def get(self, request, pk):
        schema, err = resolve_tenant_and_auth(request, 'history_sheeter', 'history_sheeter:pdf')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()

        with TenantContext(schema):
            hs = HistorySheeter.objects.annotate(trimmed_station=Trim('station_name')).filter(
                pk=pk, trimmed_station__iexact=station_name
            ).first()
            if not hs:
                not_found_msg = get_module_setting('history_sheeter', 'not_found_message') or 'Record not found.'
                return Response({'error': not_found_msg}, status=status.HTTP_404_NOT_FOUND)

            log_standalone_audit(request, 'history_sheeter:pdf', 'history_sheeter', hs.id)

            tmpl_name = get_module_setting('history_sheeter', 'template_name')
            ftfs = get_template_fields_ordered(tmpl_name) if tmpl_name else []

            pdf_prefix = get_module_setting('history_sheeter', 'pdf_filename_prefix') or 'Document'
            filename = f"{pdf_prefix}_{hs.station_name}_{hs.sr_no}.pdf"

            return build_hs_pdf(request, hs, ftfs, filename)
