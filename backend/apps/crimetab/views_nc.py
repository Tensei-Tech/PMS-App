"""
N.C. (Non-Cognizable) API — independent module, not cases.

  GET  /api/nc/config/          settings for the hub (labels, limits, page size)
  GET  /api/nc/counts/          Total cases / Pending / Disposal (ONE query, cached)
  GET  /api/nc/                 keyset-paginated list (?tab=total|pending|disposal&q=&cursor=)
  POST /api/nc/                 create
  GET  /api/nc/<pk>/            view (display sections + form data for edit)
  PATCH /api/nc/<pk>/           update (merged state validated, children replaced)
  GET  /api/nc/<pk>/pdf/        PDF

Every request runs inside the verified tenant schema and is scoped to the user's
stations. Errors are 400 / 401 / 403 / 404 with a module_settings message, never 500.
"""
import datetime
import hashlib
import io
import logging
import time
import xml.sax.saxutils as saxutils

from django.core.cache import cache
from django.db import DatabaseError, IntegrityError
from django.db.models import Count, Exists, F, OuterRef, Q
from django.http import HttpResponse
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.tenancy import TenantContext
from apps.crimetab.models.nc import NcPerson, NcRecord
from apps.crimetab.services import nc_service as svc
from apps.crimetab.standalone_helpers import log_standalone_audit, resolve_tenant_and_auth

logger = logging.getLogger(__name__)

MODULE = svc.MODULE_KEY
TABS = ('total', 'pending', 'disposal')


# ── Shared request helpers ───────────────────────────────────────────────────
def _user_stations(user):
    main = str(getattr(user, 'station_name', '') or '').strip()
    extra = getattr(user, 'additional_stations', None) or []
    stations = [main] + [str(s).strip() for s in extra if str(s).strip()]
    return [s for s in dict.fromkeys(stations) if s], main


def _err(settings, key, code=status.HTTP_400_BAD_REQUEST, **fmt):
    return Response({'error': settings.text(key, **fmt)}, status=code)


def _counts_version(schema):
    """Generation number per schema; any N.C. save bumps it, invalidating every counts key."""
    return cache.get(f"nc:counts_ver:{schema}") or 0


def _counts_cache_key(schema, stations):
    digest = hashlib.md5('|'.join(sorted(s.lower() for s in stations)).encode('utf-8')).hexdigest()
    return f"nc:counts:{schema}:{_counts_version(schema)}:{digest}"


def _clear_counts_cache(schema, station_name=None):
    # Counts are cached per set of stations (main + additional). Bumping the
    # schema's version makes every cached combination stale in one operation.
    cache.set(f"nc:counts_ver:{schema}", time.time_ns(), timeout=None)


def _scoped(stations):
    return NcRecord.objects.filter(station_name__in=stations)


def _authorise(request, perm):
    """(schema, settings, stations, main_station, error_response)."""
    schema, err = resolve_tenant_and_auth(request, MODULE, perm)
    if err:
        return None, None, None, None, err
    settings = svc.NcSettings()
    stations, main = _user_stations(request.user)
    if not stations:
        return None, settings, None, None, _err(settings, 'no_station_message')
    return schema, settings, stations, main, None


# ── Config ───────────────────────────────────────────────────────────────────
class NcConfigView(APIView):
    def get(self, request):
        schema, settings, _stations, _main, err = _authorise(request, 'nc:view')
        if err:
            return err
        fic_limit = settings.int('first_information_max_length')
        return Response({
            'target_category_code': settings.text('target_category_code'),
            'template_name': settings.text('template_name'),
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
            'pending_definition': settings.text(
                'pending_definition_message',
                date_only_provision=settings.raw('date_only_provision') or ''),
            'field_max_lengths': {'nc_first_information': fic_limit} if fic_limit else {},
            'date_format': settings.text('date_format'),
        })


# ── Officers of the user's police station (IO / Registered By pickers) ──────────
class NcOfficersView(APIView):
    """GET /api/nc/officers/ - active officers of the user's station(s), ONE query."""

    def get(self, request):
        schema, settings, stations, _main, err = _authorise(request, 'nc:view')
        if err:
            return err
        from django.db.models.functions import Lower, Trim
        from apps.users.models import OfficerProfile
        try:
            with TenantContext(schema):
                rows = list(
                    OfficerProfile.objects.annotate(st=Lower(Trim('station_name')))
                    .filter(account_status='active', st__in=[s.lower() for s in stations])
                    .exclude(name__isnull=True).exclude(name='')
                    .order_by('name')
                    .values('uid', 'name', 'designation')
                )
        except DatabaseError as e:
            logger.warning("[NC] officers failed: %s", e)
            return _err(settings, 'request_failed_message')
        # 'label' is what the picker stores, so it is the name only
        return Response([
            {'uid': r['uid'], 'name': r['name'], 'designation': r['designation'] or '', 'label': r['name']}
            for r in rows
        ])


# ── Counts (ONE query, cached) ──────────────────────────────────────────────────
def _compute_counts(stations, settings):
    agg = svc.with_status(_scoped(stations), settings).aggregate(
        total=Count('id'),
        disposal=Count('id', filter=svc.disposal_q()),
    )
    total = agg['total'] or 0
    disposal = agg['disposal'] or 0
    return {'total': total, 'pending': total - disposal, 'disposal': disposal}


class NcCountsView(APIView):
    def get(self, request):
        schema, settings, stations, _main, err = _authorise(request, 'nc:view')
        if err:
            return err
        key = _counts_cache_key(schema, stations)
        cached = cache.get(key)
        if cached is not None:
            return Response(cached)
        try:
            with TenantContext(schema):
                data = _compute_counts(stations, settings)
        except DatabaseError as e:
            logger.warning("[NC] counts failed: %s", e)
            return _err(settings, 'request_failed_message')
        cache.set(key, data, timeout=settings.int('counts_cache_timeout') or 0)
        return Response(data)


# ── List / Create ─────────────────────────────────────────────────────────────
def _parse_cursor(raw):
    """cursor = '<YYYY-MM-DD or empty>|<id>'; returns (date|None, id) or raises ValueError."""
    date_part, _, id_part = str(raw).partition('|')
    last_id = int(id_part)
    last_date = datetime.date.fromisoformat(date_part) if date_part else None
    return last_date, last_id


def _after_cursor_q(last_date, last_id):
    # ORDER BY registered_date DESC NULLS LAST, id DESC
    if last_date is None:
        return Q(registered_date__isnull=True, id__lt=last_id)
    return (
        Q(registered_date__lt=last_date)
        | Q(registered_date=last_date, id__lt=last_id)
        | Q(registered_date__isnull=True)
    )


class NcListCreateView(APIView):
    def get(self, request):
        schema, settings, stations, _main, err = _authorise(request, 'nc:view')
        if err:
            return err
        page_size = settings.int('page_size')
        if not page_size:
            return _err(settings, 'request_failed_message')

        tab = str(request.query_params.get('tab', 'total')).strip().lower()
        if tab not in TABS:
            return _err(settings, 'invalid_request_message')
        q = str(request.query_params.get('q', '')).strip()
        cursor_raw = request.query_params.get('cursor')

        try:
            with TenantContext(schema):
                # The total tab needs no status in WHERE: page by index first, then
                # evaluate the shared Disposal expression for the page rows only.
                qs = _scoped(stations)
                if tab != 'total':
                    qs = svc.with_status(qs, settings)
                    qs = qs.filter(svc.disposal_q() if tab == 'disposal' else svc.pending_q())
                if q:
                    qs = qs.annotate(person_hit=Exists(
                        NcPerson.objects.filter(nc=OuterRef('pk'), name__icontains=q)
                    )).filter(
                        Q(nc_no__icontains=q) | Q(spot_village__icontains=q)
                        | Q(spot_area__icontains=q) | Q(spot_address__icontains=q)
                        | Q(person_hit=True)
                    )
                if cursor_raw:
                    try:
                        last_date, last_id = _parse_cursor(cursor_raw)
                    except (TypeError, ValueError):
                        return _err(settings, 'invalid_request_message')
                    qs = qs.filter(_after_cursor_q(last_date, last_id))

                page = list(
                    qs.order_by(F('registered_date').desc(nulls_last=True), '-id')[:page_size + 1]
                )
                has_more = len(page) > page_size
                page = page[:page_size]
                page_ids = [r.id for r in page]
                disposal = svc.disposal_map(page_ids, settings)
                children = svc.load_children(page_ids)
                field_defs = svc.load_field_defs(settings) if page_ids else []
        except DatabaseError as e:
            logger.warning("[NC] list failed: %s", e)
            return _err(settings, 'request_failed_message')

        results = []
        for r in page:
            kids = children[r.id]
            is_disposal = disposal.get(r.id, False)
            results.append({
                'id': r.id,
                'nc_no': r.nc_no or '',
                'registered_date': svc._fmt_date(r.registered_date, settings),
                'station_name': r.station_name,
                'complainants': [p.name for p in kids['persons']
                                 if p.person_type == svc.PERSON_TYPE_COMPLAINANT and p.name],
                'non_applicants': [p.name for p in kids['persons']
                                   if p.person_type == svc.PERSON_TYPE_NON_APPLICANT and p.name],
                'crime_spot': ', '.join(x for x in (r.spot_village, r.spot_area) if x),
                'is_disposal': is_disposal,
                'status_label': svc.record_status_label(is_disposal, settings),
                **svc.build_list_card(r, kids, field_defs, settings),
            })
        next_cursor = None
        if has_more and page:
            last = page[-1]
            next_cursor = f"{last.registered_date.isoformat() if last.registered_date else ''}|{last.id}"
        return Response({'results': results, 'next_cursor': next_cursor, 'page_size': page_size})

    def post(self, request):
        schema, settings, stations, main, err = _authorise(request, 'nc:create')
        if err:
            return err
        if not main:
            return _err(settings, 'no_station_message')
        try:
            with TenantContext(schema):
                field_defs = svc.load_field_defs(settings)
                options = svc.load_options(field_defs)
                plan = svc.build_plan(request.data, settings, field_defs, options)
                created_by = str(getattr(request.user, 'uid', '') or getattr(request.user, 'id', '') or '')
                record = svc.save_plan(plan, station_name=main, created_by=created_by or None)
                _clear_counts_cache(schema, main)
                log_standalone_audit(request, 'nc:create', MODULE, record.id)
                return Response({'id': record.id, 'message': settings.text('save_success_message')},
                                status=status.HTTP_201_CREATED)
        except svc.NcValidationError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except (IntegrityError, DatabaseError) as e:
            logger.warning("[NC] create failed: %s", e)
            return _err(settings, 'request_failed_message')


# ── Detail / Update ───────────────────────────────────────────────────────────
def _load_one(pk, stations, settings):
    record = svc.with_status(_scoped(stations).filter(pk=pk), settings).first()
    if record is None:
        return None, None
    return record, svc.load_children([record.id])[record.id]


class NcDetailView(APIView):
    def get(self, request, pk):
        schema, settings, stations, _main, err = _authorise(request, 'nc:view')
        if err:
            return err
        try:
            with TenantContext(schema):
                record, children = _load_one(pk, stations, settings)
                if record is None:
                    return _err(settings, 'not_found_message', status.HTTP_404_NOT_FOUND)
                field_defs = svc.load_field_defs(settings)
                is_disposal = svc.is_disposal(record)
                return Response({
                    'id': record.id,
                    'station_name': record.station_name,
                    'is_disposal': is_disposal,
                    'status_label': svc.record_status_label(is_disposal, settings),
                    'sections': _sections_json(svc.build_display_sections(record, children, field_defs, settings)),
                    'form_data': svc.record_form_data(record, children, settings),
                })
        except DatabaseError as e:
            logger.warning("[NC] detail failed: %s", e)
            return _err(settings, 'request_failed_message')

    def patch(self, request, pk):
        schema, settings, stations, _main, err = _authorise(request, 'nc:update')
        if err:
            return err
        try:
            with TenantContext(schema):
                record, children = _load_one(pk, stations, settings)
                if record is None:
                    return _err(settings, 'not_found_message', status.HTTP_404_NOT_FOUND)
                # Validate the MERGED state: stored values overlaid with the request
                merged = svc.record_form_data(record, children, settings)
                merged.update(svc._normalise_payload(request.data))
                field_defs = svc.load_field_defs(settings)
                options = svc.load_options(field_defs)
                plan = svc.build_plan(merged, settings, field_defs, options)
                svc.save_plan(plan, station_name=record.station_name, record=record)
                _clear_counts_cache(schema, record.station_name)
                changed = sorted(k for k in request.data.keys() if str(k).startswith('nc_'))
                log_standalone_audit(request, 'nc:update', MODULE, record.id, changed_fields=changed)
                return Response({'id': record.id, 'message': settings.text('update_success_message')})
        except svc.NcValidationError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except (IntegrityError, DatabaseError) as e:
            logger.warning("[NC] update failed: %s", e)
            return _err(settings, 'request_failed_message')


def _sections_json(sections):
    out = []
    for s in sections:
        if s['kind'] == 'table':
            out.append({'title': s['title'], 'kind': 'table',
                        'headers': s.get('headers', []), 'rows': s['rows']})
        else:
            out.append({'title': s['title'], 'kind': 'fields',
                        'rows': [{'label': lbl, 'value': val} for lbl, val in s['rows']]})
    return out


# ── PDF ───────────────────────────────────────────────────────────────────────
class NcPdfView(APIView):
    def get(self, request, pk):
        schema, settings, stations, _main, err = _authorise(request, 'nc:pdf')
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
                record, children = _load_one(pk, stations, settings)
                if record is None:
                    return _err(settings, 'not_found_message', status.HTTP_404_NOT_FOUND)
                field_defs = svc.load_field_defs(settings)
                sections = svc.build_display_sections(record, children, field_defs, settings)
                is_disposal = svc.is_disposal(record)
            pdf_bytes = _render_pdf(record, sections, is_disposal, settings, state_code)
        except DatabaseError as e:
            logger.warning("[NC] pdf failed: %s", e)
            return _err(settings, 'request_failed_message')
        log_standalone_audit(request, 'nc:pdf', MODULE, record.id)
        prefix = settings.text('pdf_filename_prefix')
        clean_no = str(record.nc_no or record.id).replace('/', '_').replace(' ', '_')
        response = HttpResponse(pdf_bytes, content_type='application/pdf')
        response['Content-Disposition'] = f'inline; filename="{prefix}_{clean_no}.pdf"'
        return response


def _render_pdf(record, sections, is_disposal, settings, state_code):
    return render_record_pdf(MODULE, record.nc_no, record.station_name,
                             svc.record_status_label(is_disposal, settings),
                             sections, settings, state_code)


def render_record_pdf(module_key, record_no, station_name, status_label, sections, settings, state_code):
    """
    Official PDF of one record: state title, subtitle, a number / station /
    status bar, then each display section (fields or table). Every text comes
    from the module's settings (pdf_* keys). Shared by N.C. and A.D.
    """
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.platypus import KeepTogether, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

    from reportlab.pdfgen import canvas as rl_canvas

    from apps.crimetab.views_mpda import resolve_pdf_dept_title

    footer_text = settings.text('pdf_footer_text')
    generated_tpl = settings.text('pdf_generated_label')
    page_tpl = settings.text('pdf_page_label')
    gen_time = datetime.datetime.now().strftime(settings.raw('datetime_format') or '%Y-%m-%d %H:%M')

    class NcNumberedCanvas(rl_canvas.Canvas):
        """Two-pass canvas: footer text and page numbering from module_settings."""

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self._saved = []

        def showPage(self):
            self._saved.append(dict(self.__dict__))
            self._startPage()

        def save(self):
            total = len(self._saved)
            for state in self._saved:
                self.__dict__.update(state)
                self.saveState()
                self.setFont('Helvetica', 8)
                self.setFillColor(colors.HexColor('#64748B'))
                left = ' · '.join(x for x in (generated_tpl.replace('{time}', gen_time), footer_text) if x)
                self.drawString(36, 18, left)
                self.drawRightString(A4[0] - 36, 18, page_tpl.replace('{page}', str(self._pageNumber))
                                     .replace('{total}', str(total)))
                self.setStrokeColor(colors.HexColor('#CBD5E1'))
                self.setLineWidth(0.5)
                self.line(36, 28, A4[0] - 36, 28)
                self.restoreState()
                super().showPage()
            super().save()

    esc = lambda v: saxutils.escape(str(v)) if v not in (None, '') else '-'  # noqa: E731
    styles = getSampleStyleSheet()
    title_st = ParagraphStyle('NcTitle', parent=styles['Heading1'], fontName='Helvetica-Bold', fontSize=15,
                              leading=18, alignment=1, textColor=colors.HexColor('#1E293B'), spaceAfter=3)
    sub_st = ParagraphStyle('NcSub', parent=styles['Normal'], fontSize=10, leading=13, alignment=1,
                            textColor=colors.HexColor('#475569'), spaceAfter=8)
    badge_st = ParagraphStyle('NcBadge', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=9,
                              leading=12, alignment=1, textColor=colors.HexColor('#1E3A8A'))
    sec_st = ParagraphStyle('NcSec', parent=styles['Heading2'], fontName='Helvetica-Bold', fontSize=11,
                            leading=15, textColor=colors.HexColor('#1E3A8A'), spaceBefore=10, spaceAfter=4)
    lbl_st = ParagraphStyle('NcLbl', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=8.5,
                            leading=11, textColor=colors.HexColor('#334155'))
    val_st = ParagraphStyle('NcVal', parent=styles['Normal'], fontSize=8.5, leading=11,
                            textColor=colors.HexColor('#0F172A'))
    th_st = ParagraphStyle('NcTh', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=8.5,
                           leading=11, alignment=1, textColor=colors.white)
    grid = [('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 3.5), ('BOTTOMPADDING', (0, 0), (-1, -1), 3.5),
            ('LEFTPADDING', (0, 0), (-1, -1), 5), ('RIGHTPADDING', (0, 0), (-1, -1), 5)]

    story = [
        Paragraph(f'<b>{esc(resolve_pdf_dept_title(module_key, state_code))}</b>', title_st),
        Paragraph(esc(settings.text('pdf_subtitle')), sub_st),
    ]
    meta = Table([[
        Paragraph(esc(record_no), badge_st),
        Paragraph(esc(station_name), badge_st),
        Paragraph(esc(status_label), badge_st),
    ]], colWidths=[174, 173, 173])
    meta.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#EEF2FF')),
                              ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#C7D2FE')),
                              ('TOPPADDING', (0, 0), (-1, -1), 5), ('BOTTOMPADDING', (0, 0), (-1, -1), 5)]))
    story += [meta, Spacer(1, 8)]

    none_msg = settings.text('pdf_no_rows_message')
    for idx, sec in enumerate(sections, 1):
        heading = Paragraph(f'<b>{idx}. {esc(str(sec["title"]).upper())}</b>', sec_st)
        if sec['kind'] == 'table':
            headers = sec.get('headers') or []
            if not sec['rows'] or not headers:
                story += [heading, Paragraph(esc(none_msg), val_st)]
                continue
            data = [[Paragraph(f'<b>{esc(h)}</b>', th_st) for h in headers]]
            data += [[Paragraph(esc(c), val_st) for c in row] for row in sec['rows']]
            t = Table(data, colWidths=[520 / len(headers)] * len(headers), repeatRows=1)
            t.setStyle(TableStyle(grid + [('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1E3A8A'))]))
        else:
            data = [[Paragraph(f'<b>{esc(lbl)}</b>', lbl_st), Paragraph(esc(val), val_st)]
                    for lbl, val in sec['rows']]
            if not data:
                continue
            t = Table(data, colWidths=[150, 370])
            t.setStyle(TableStyle(grid + [('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#F8FAFC'))]))
        story += [KeepTogether([heading, t]), Spacer(1, 6)]

    buf = io.BytesIO()
    SimpleDocTemplate(buf, pagesize=A4, leftMargin=36, rightMargin=36, topMargin=36,
                      bottomMargin=42).build(story, canvasmaker=NcNumberedCanvas)
    return buf.getvalue()
