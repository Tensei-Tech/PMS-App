"""
A.D. (Accidental Death) API - one hub per sub-tab (Suicide / Other ...).

  GET  /api/ad/config/                     labels, sub-tabs, limits (module_settings 'ad')
  GET  /api/ad/counts/?category=<code>     Total / Pending / Disposal of one sub-tab (cached)
  GET  /api/ad/?category=<code>&tab=&q=&cursor=   keyset-paginated list with card boxes
  POST /api/ad/?category=<code>            create
  GET  /api/ad/<id>/                       view (display sections + form data for edit)
  PATCH /api/ad/<id>/                      update
  GET  /api/ad/<id>/pdf/                   PDF

Cases are case records with module_key 'ad'; status comes from CaseRecord.save()
(Disposal = SDM Granted Yes with its date). Every request runs inside the
verified tenant schema and is scoped to the user's stations. Errors are 400 /
401 / 403 / 404 with a module_settings message, never 500.
"""
import datetime
import hashlib
import logging
import time

from django.core.cache import cache
from django.db import DatabaseError, IntegrityError
from django.db.models import Count, Q, TextField
from django.db.models.functions import Cast
from django.http import HttpResponse
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.services import ad_service as svc
from apps.crimetab.standalone_helpers import log_standalone_audit, resolve_tenant_and_auth
from apps.crimetab.views_nc import _sections_json, _user_stations, render_record_pdf

logger = logging.getLogger(__name__)

MODULE = svc.MODULE_KEY
TABS = ('total', 'pending', 'disposal')
DISPOSAL_Q = Q(status__iexact=svc.STATUS_DISPOSAL)


def _err(settings, key, code=status.HTTP_400_BAD_REQUEST, **fmt):
    return Response({'error': settings.text(key, **fmt)}, status=code)


def _counts_cache_key(schema, stations, category_code):
    version = cache.get(f"ad:counts_ver:{schema}") or 0
    digest = hashlib.md5('|'.join(sorted(s.lower() for s in stations)).encode('utf-8')).hexdigest()
    return f"ad:counts:{schema}:{version}:{category_code.upper()}:{digest}"


def _clear_counts_cache(schema):
    cache.set(f"ad:counts_ver:{schema}", time.time_ns(), timeout=None)


def _scoped(stations, category_name=None):
    qs = CaseRecord.objects.filter(module_key=MODULE, station_name__in=stations)
    if category_name is not None:
        qs = qs.filter(sub_category__iexact=category_name)
    return qs


def _authorise(request, perm):
    """(schema, settings, stations, main_station, error_response)."""
    schema, err = resolve_tenant_and_auth(request, MODULE, perm)
    if err:
        return None, None, None, None, err
    settings = svc.AdSettings()
    stations, main = _user_stations(request.user)
    if not stations:
        return None, settings, None, None, _err(settings, 'no_station_message')
    return schema, settings, stations, main, None


def _category(request, settings):
    """The sub-tab named by ?category=<code>, or None."""
    return svc.find_sub_category(settings, request.query_params.get('category'))


# ── Config ───────────────────────────────────────────────────────────────────
class AdConfigView(APIView):
    def get(self, request):
        schema, settings, _stations, _main, err = _authorise(request, 'ad:view')
        if err:
            return err
        with TenantContext(schema):
            subs = svc.sub_categories(settings)
        return Response({
            'target_category_code': settings.text('target_category_code'),
            'template_name': settings.text('template_name'),
            'sub_categories': subs,
            'sub_tab_labels': {t: settings.text(f'tab_{t}_label') for t in TABS},
            'action_labels': {
                'add': settings.text('add_button_label'),
                'edit': settings.text('btn_edit_label'),
                'view': settings.text('btn_view_label'),
                'pdf': settings.text('btn_pdf_label'),
            },
            'search_placeholder': settings.text('search_placeholder'),
            'empty_list_message': settings.text('empty_list_message'),
            'messages': {
                k: settings.text(k) for k in (
                    'save_success_message', 'update_success_message',
                    'pdf_failed_message', 'empty_request_message',
                )
            },
            'page_size': settings.int('page_size'),
            'serial_label': settings.text('list_serial_label'),
            'pending_definition': settings.text('pending_definition_message'),
        })


# ── Counts ───────────────────────────────────────────────────────────────────
class AdCountsView(APIView):
    def get(self, request):
        schema, settings, stations, _main, err = _authorise(request, 'ad:view')
        if err:
            return err
        try:
            with TenantContext(schema):
                cat = _category(request, settings)
                if cat is None:
                    return _err(settings, 'invalid_request_message')
                key = _counts_cache_key(schema, stations, cat['code'])
                cached = cache.get(key)
                if cached is not None:
                    return Response(cached)
                agg = _scoped(stations, cat['name']).aggregate(
                    total=Count('id'), disposal=Count('id', filter=DISPOSAL_Q))
        except DatabaseError as e:
            logger.warning("[AD] counts failed: %s", e)
            return _err(settings, 'request_failed_message')
        total, disposal = agg['total'] or 0, agg['disposal'] or 0
        data = {'total': total, 'pending': total - disposal, 'disposal': disposal}
        cache.set(key, data, timeout=settings.int('counts_cache_timeout') or 0)
        return Response(data)


# ── List / Create ─────────────────────────────────────────────────────────────
def _parse_cursor(raw):
    """cursor = '<created_at ISO>|<id>'; raises ValueError."""
    created, _, rid = str(raw).partition('|')
    if not rid:
        raise ValueError('cursor')
    return datetime.datetime.fromisoformat(created), rid


def _save(record, values, category, settings, station_name=None, created_by=None):
    no_key = settings.raw('number_field_key') or ''
    number = str(values.get(no_key) or '') if no_key else ''
    record.module_key = MODULE
    record.sub_category = category['name']
    record.case_number = number
    record.title = ' '.join(x for x in (category['name'], number) if x)
    record.extra_fields = values
    if station_name:
        record.station_name = station_name
    if created_by:
        record.created_by = created_by
    record.save()
    return record


class AdListCreateView(APIView):
    def get(self, request):
        schema, settings, stations, _main, err = _authorise(request, 'ad:view')
        if err:
            return err
        page_size = settings.int('page_size')
        tab = str(request.query_params.get('tab', 'total')).strip().lower()
        if not page_size or tab not in TABS:
            return _err(settings, 'invalid_request_message')
        q = str(request.query_params.get('q', '')).strip()
        cursor_raw = request.query_params.get('cursor')
        try:
            with TenantContext(schema):
                cat = _category(request, settings)
                if cat is None:
                    return _err(settings, 'invalid_request_message')
                qs = _scoped(stations, cat['name'])
                if tab == 'disposal':
                    qs = qs.filter(DISPOSAL_Q)
                elif tab == 'pending':
                    qs = qs.exclude(DISPOSAL_Q)
                if q:
                    qs = qs.annotate(extra_text=Cast('extra_fields', TextField())).filter(
                        Q(case_number__icontains=q) | Q(extra_text__icontains=q))
                if cursor_raw:
                    try:
                        last_created, last_id = _parse_cursor(cursor_raw)
                    except (TypeError, ValueError):
                        return _err(settings, 'invalid_request_message')
                    qs = qs.filter(Q(created_at__lt=last_created)
                                   | Q(created_at=last_created, id__lt=last_id))
                page = list(qs.order_by('-created_at', '-id')[:page_size + 1])
                field_defs = svc.load_field_defs(settings) if page else []
        except DatabaseError as e:
            logger.warning("[AD] list failed: %s", e)
            return _err(settings, 'request_failed_message')

        has_more = len(page) > page_size
        page = page[:page_size]
        results = []
        for r in page:
            values = svc.record_form_data(r, field_defs)
            disposal = svc.is_disposal(r)
            results.append({
                'id': r.id,
                'case_number': r.case_number or '',
                'station_name': r.station_name,
                'is_disposal': disposal,
                'status_label': svc.record_status_label(disposal, settings),
                'card_rows': svc.build_list_card(values, field_defs, settings),
            })
        next_cursor = None
        if has_more and page:
            last = page[-1]
            next_cursor = f"{last.created_at.isoformat()}|{last.id}"
        return Response({'results': results, 'next_cursor': next_cursor, 'page_size': page_size})

    def post(self, request):
        schema, settings, _stations, main, err = _authorise(request, 'ad:create')
        if err:
            return err
        if not main:
            return _err(settings, 'no_station_message')
        try:
            with TenantContext(schema):
                cat = _category(request, settings)
                if cat is None:
                    return _err(settings, 'invalid_request_message')
                field_defs = svc.load_field_defs(settings)
                values = svc.clean_form_data(request.data, field_defs, settings)
                if not values:
                    return _err(settings, 'empty_request_message')
                created_by = str(getattr(request.user, 'uid', '') or getattr(request.user, 'id', '') or '')
                record = _save(CaseRecord(), values, cat, settings,
                               station_name=main, created_by=created_by or None)
                _clear_counts_cache(schema)
                log_standalone_audit(request, 'ad:create', MODULE, record.id)
                # A new record's id is still the uuid default object until reloaded
                return Response({'id': str(record.id), 'message': settings.text('save_success_message')},
                                status=status.HTTP_201_CREATED)
        except svc.AdValidationError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except (IntegrityError, DatabaseError) as e:
            logger.warning("[AD] create failed: %s", e)
            return _err(settings, 'request_failed_message')


# ── Detail / Update ───────────────────────────────────────────────────────────
def _load_one(pk, stations):
    return _scoped(stations).filter(pk=pk).first()


def _record_category(record, settings):
    name = str(record.sub_category or '').strip().lower()
    return next((c for c in svc.sub_categories(settings) if c['name'].strip().lower() == name), None)


class AdDetailView(APIView):
    def get(self, request, pk):
        schema, settings, stations, _main, err = _authorise(request, 'ad:view')
        if err:
            return err
        try:
            with TenantContext(schema):
                record = _load_one(pk, stations)
                if record is None:
                    return _err(settings, 'not_found_message', status.HTTP_404_NOT_FOUND)
                field_defs = svc.load_field_defs(settings)
                values = svc.record_form_data(record, field_defs)
                disposal = svc.is_disposal(record)
                cat = _record_category(record, settings)
                return Response({
                    'id': record.id,
                    'case_number': record.case_number or '',
                    'category_code': cat['code'] if cat else '',
                    'station_name': record.station_name,
                    'is_disposal': disposal,
                    'status_label': svc.record_status_label(disposal, settings),
                    'sections': _sections_json(svc.build_display_sections(values, field_defs, settings)),
                    'form_data': values,
                })
        except DatabaseError as e:
            logger.warning("[AD] detail failed: %s", e)
            return _err(settings, 'request_failed_message')

    def patch(self, request, pk):
        schema, settings, stations, _main, err = _authorise(request, 'ad:update')
        if err:
            return err
        try:
            with TenantContext(schema):
                record = _load_one(pk, stations)
                if record is None:
                    return _err(settings, 'not_found_message', status.HTTP_404_NOT_FOUND)
                cat = _record_category(record, settings)
                if cat is None:
                    return _err(settings, 'invalid_request_message')
                field_defs = svc.load_field_defs(settings)
                # The form sends every answer; keys it leaves out keep their stored value
                merged = svc.record_form_data(record, field_defs)
                merged.update(request.data if isinstance(request.data, dict) else {})
                values = svc.clean_form_data(merged, field_defs, settings)
                if not values:
                    return _err(settings, 'empty_request_message')
                _save(record, values, cat, settings)
                _clear_counts_cache(schema)
                changed = sorted(str(k) for k in (request.data or {}).keys())
                log_standalone_audit(request, 'ad:update', MODULE, record.id, changed_fields=changed)
                return Response({'id': record.id, 'message': settings.text('update_success_message')})
        except svc.AdValidationError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except (IntegrityError, DatabaseError) as e:
            logger.warning("[AD] update failed: %s", e)
            return _err(settings, 'request_failed_message')


# ── PDF ───────────────────────────────────────────────────────────────────────
class AdPdfView(APIView):
    def get(self, request, pk):
        schema, settings, stations, _main, err = _authorise(request, 'ad:pdf')
        if err:
            return err
        user = request.user
        state_code = getattr(request, 'state_code', None) or getattr(user, 'state_code', None)
        if not state_code and isinstance(getattr(request, 'auth', None), dict):
            state_code = request.auth.get('state_code')
        if not state_code or not str(state_code).strip():
            return _err(settings, 'missing_state_message')
        try:
            with TenantContext(schema):
                record = _load_one(pk, stations)
                if record is None:
                    return _err(settings, 'not_found_message', status.HTTP_404_NOT_FOUND)
                field_defs = svc.load_field_defs(settings)
                values = svc.record_form_data(record, field_defs)
                sections = svc.build_display_sections(values, field_defs, settings)
                label = svc.record_status_label(svc.is_disposal(record), settings)
            pdf_bytes = render_record_pdf(MODULE, record.case_number or '', record.station_name,
                                          label, sections, settings, state_code)
        except DatabaseError as e:
            logger.warning("[AD] pdf failed: %s", e)
            return _err(settings, 'request_failed_message')
        log_standalone_audit(request, 'ad:pdf', MODULE, record.id)
        prefix = settings.text('pdf_filename_prefix')
        clean_no = str(record.case_number or record.id).replace('/', '_').replace(' ', '_')
        response = HttpResponse(pdf_bytes, content_type='application/pdf')
        response['Content-Disposition'] = f'inline; filename="{prefix}_{clean_no}.pdf"'
        return response
