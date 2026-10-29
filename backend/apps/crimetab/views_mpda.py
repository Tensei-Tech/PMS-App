import datetime
import calendar
import hashlib
import logging
import re
import io
import xml.sax.saxutils as saxutils
from django.http import HttpResponse
from django.db import connection, transaction
from django.db.models import Q, Count, IntegerField, OuterRef, Subquery, Value
from django.db.models.functions import Coalesce, Trim
from django.core.cache import cache
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

from apps.core.tenancy import TenantContext
from apps.crimetab.models.mpda import (
    MpdaProposal,
    MpdaAccusedPerson,
    MpdaGangMember,
    MpdaCrimeChartEntry,
)
from apps.crimetab.models import ModuleSetting, OptionValue
from apps.crimetab.age_limits import MAX_AGE, MIN_AGE
from apps.crimetab.serializers_mpda import (
    MpdaProposalListSerializer,
    MpdaProposalDetailSerializer,
    MpdaAccusedPersonSerializer,
    MpdaGangMemberSerializer,
    MpdaCrimeChartEntrySerializer,
)
from apps.crimetab.standalone_helpers import (
    resolve_tenant_and_auth,
    get_module_setting,
    get_scoped_officers_queryset,
    log_standalone_audit,
    format_display_date,
    parse_display_date,
    build_standalone_pdf,
    get_template_fields_ordered,
    crime_charge_fields,
)

logger = logging.getLogger(__name__)


def _clear_mpda_cache(schema, station_name):
    if station_name:
        st_hash = hashlib.md5(station_name.strip().encode('utf-8')).hexdigest()
        cache.delete(f"mpda:counts:{schema}:{st_hash}")


def _get_yes_value():
    y = OptionValue.objects.filter(option_group='yes_no', is_active=True).first()
    return y.option_value if y else 'Yes'


def _outcome_tab_q(tab, yes_val):
    """
    Approved / Rejected / Total MPDA Revoked cards and tabs: the outcome (or
    Revoked = Yes) AND its date must both be filled. Shared by counts and list.
    """
    if tab == 'approved':
        return Q(proposal_outcome__iexact='Granted', granted_date__isnull=False)
    if tab == 'rejected':
        return Q(proposal_outcome__iexact='Rejected', rejected_date__isnull=False)
    if tab == 'proposal_revoked':
        return Q(proposal_revoked__iexact=yes_val, proposal_revoked_date__isnull=False)
    return None


def _released_days_options():
    """
    Day filters on the "Released in next month" card (module_settings
    released_filter_days, comma separated, e.g. "20,10"). Positive whole
    numbers only, in the configured order.
    """
    raw = get_module_setting('mpda', 'released_filter_days', '') or ''
    days = []
    for part in str(raw).split(','):
        part = part.strip()
        if part.isdigit() and int(part) > 0 and int(part) not in days:
            days.append(int(part))
    return days


def _released_q(yes_val, days=None, ref_date=None):
    """
    Released card: detention completes next calendar month, or (with days)
    from today up to today + days. A revoked detention order is never counted.
    """
    if days:
        today = ref_date or datetime.date.today()
        first_day, last_day = today, today + datetime.timedelta(days=days)
    else:
        first_day, last_day = _get_next_month_range(ref_date)
    return Q(detention_completion_date__gte=first_day,
             detention_completion_date__lte=last_day) & ~Q(detention_order_revoked__iexact=yes_val)


def _get_next_month_range(ref_date=None):
    today = ref_date or datetime.date.today()
    if today.month == 12:
        next_year = today.year + 1
        next_month = 1
    else:
        next_year = today.year
        next_month = today.month + 1

    first_day = datetime.date(next_year, next_month, 1)
    _, last_day_num = calendar.monthrange(next_year, next_month)
    last_day = datetime.date(next_year, next_month, last_day_num)
    return first_day, last_day


def _is_empty_mpda_payload(data):
    ignored = {'station_name', 'created_by', 'id'}
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


def _sanitize_mpda_data(norm, is_patch=False, existing_instance=None):
    """
    Sanitizes raw form field inputs for MPDA proposal creation and update:
    - Strips all string fields; converts empty string "" or whitespace-only to None.
    - Validates accused_mobile format (10 digits) if provided, or sets None.
    - Validates accused_age (integer MIN_AGE..MAX_AGE) if provided, or sets None.
    - Parses numbers (total_crime, serious_crimes) to int or None.
    - Parses date fields and enforces outcome radio exclusivity.
    - Synchronizes proposal_no, proposal_year, and proposal_no_and_year.
    Returns: (cleaned_norm, error_message_or_None)
    """
    for k, v in list(norm.items()):
        if isinstance(v, str):
            v_str = v.strip()
            norm[k] = v_str if v_str else None

    # Stop reading and writing io_uid
    norm.pop('io_uid', None)
    norm.pop('mpda_io_uid', None)

    # A short proposal year means 2001-2100: '03' -> '2003', '00' -> '2100'
    short_yr = str(norm.get('proposal_year') or '')
    if short_yr.isdigit() and len(short_yr) <= 2:
        norm['proposal_year'] = str(2100 if int(short_yr) == 0 else 2000 + int(short_yr))

    # Synchronize proposal_no, proposal_year and proposal_no_and_year
    p_no =norm.get('proposal_no') or (getattr(existing_instance, 'proposal_no', None) if is_patch else None)
    p_yr = norm.get('proposal_year') or (getattr(existing_instance, 'proposal_year', None) if is_patch else None)
    p_comb = norm.get('proposal_no_and_year') or (getattr(existing_instance, 'proposal_no_and_year', None) if is_patch else None)

    if p_no and p_yr:
        norm['proposal_no_and_year'] = f"{p_no}/{p_yr}"
    elif p_no and not p_comb:
        norm['proposal_no_and_year'] = str(p_no)
    elif p_comb and not p_no:
        parts = str(p_comb).split('/')
        if len(parts) == 2:
            norm['proposal_no'] = parts[0].strip() or None
            norm['proposal_year'] = parts[1].strip() or None
        else:
            norm['proposal_no'] = str(p_comb).strip() or None

    # Mobile validation & normalization
    if 'accused_mobile' in norm:
        mob = norm.get('accused_mobile')
        if mob:
            digits = re.sub(r'\D', '', str(mob))
            if len(digits) == 10:
                norm['accused_mobile'] = digits
            else:
                return None, "Accused mobile number must be exactly 10 digits."
        else:
            norm['accused_mobile'] = None

    # Age validation
    if 'accused_age' in norm:
        age_val = norm.get('accused_age')
        if age_val is not None:
            try:
                age_int = int(str(age_val).strip())
                if MIN_AGE <= age_int <= MAX_AGE:
                    norm['accused_age'] = age_int
                else:
                    return None, f"Accused age must be between {MIN_AGE} and {MAX_AGE}."
            except (ValueError, TypeError):
                return None, f"Accused age must be a valid number between {MIN_AGE} and {MAX_AGE}."
        else:
            norm['accused_age'] = None

    # Integer counts
    for num_f in ('total_crime', 'serious_crimes', 'total_misc_crime'):
        if num_f in norm:
            val = norm.get(num_f)
            if val is not None:
                try:
                    norm[num_f] = int(str(val).strip())
                except (ValueError, TypeError):
                    norm[num_f] = None
            else:
                norm[num_f] = None
            if norm[num_f] is not None and norm[num_f] < 0:
                return None, get_module_setting(
                    'mpda', 'crime_count_negative_message', 'Crime counts cannot be negative.')

    # Total Crime = Total Serious Crime + Total Miscellaneous Crime, so the
    # serious count can never be more than the total
    def current(f):
        if f in norm:
            return norm[f]
        return getattr(existing_instance, f, None) if is_patch else None
    serious, misc = current('serious_crimes'), current('total_misc_crime')
    if serious is not None or misc is not None:
        norm['total_crime'] = (serious or 0) + (misc or 0)
    total = current('total_crime')
    if total is not None and serious is not None and serious > total:
        return None, get_module_setting(
            'mpda', 'serious_exceeds_total_message',
            'Total Serious Crime cannot be more than Total Crime.')

    # Date parsing
    date_fields = [
        'granted_date', 'rejected_date', 'detention_date',
        'detention_completion_date', 'govt_confirmation_date', 'order_revoked_date',
        'proposal_revoked_date',
    ]
    for df in date_fields:
        if df in norm:
            norm[df] = parse_display_date(norm[df], 'mpda')

    # Outcome rules
    outcome = norm.get('proposal_outcome') or (getattr(existing_instance, 'proposal_outcome', None) if is_patch else None)
    if outcome == 'Granted':
        norm['rejected_date'] = None
    elif outcome == 'Rejected':
        norm['granted_date'] = None
    elif 'proposal_outcome' in norm or not is_patch:
        norm['granted_date'] = None
        norm['rejected_date'] = None

    # Revoked date is kept only while Revoked is Yes
    if 'proposal_revoked' in norm or not is_patch:
        revoked = norm.get('proposal_revoked')
    else:
        revoked = getattr(existing_instance, 'proposal_revoked', None)
    if str(revoked or '').strip().lower() != str(_get_yes_value()).strip().lower():
        norm['proposal_revoked_date'] = None

    # Detention start / end dates are kept only while Detained is Yes
    def stored(f):
        if f in norm:
            return norm[f]
        return getattr(existing_instance, f, None) if is_patch else None
    if str(stored('detained') or '').strip().lower() != str(_get_yes_value()).strip().lower():
        norm['detention_date'] = None
        norm['detention_completion_date'] = None
    else:
        start, end = stored('detention_date'), stored('detention_completion_date')
        if start and end and end < start:
            return None, get_module_setting(
                'mpda', 'detention_end_before_start_message',
                'Detention End Date cannot be before Detention Start Date.')

    return norm, None


def get_mpda_display_rows(prop, schema='public', with_keys=False):
    """
    Constructs ordered (label, display_value) rows based on field_template_fields for MPDA.
    with_keys=True returns dicts {field_key, label, value, section} instead.
    """
    tmpl_name = get_module_setting('mpda', 'template_name')
    ftfs = get_template_fields_ordered(tmpl_name) if tmpl_name else []
    attr_map = {
        'mpda_proposal_no': prop.proposal_no or '',
        'mpda_proposal_year': prop.proposal_year or '',
        'mpda_proposal_no_and_year': prop.proposal_no_and_year or '',
        'mpda_io_name': prop.io_name or '',
        'mpda_io_post': prop.io_post or '',
        'mpda_proposal_outcome': prop.proposal_outcome or '',
        'mpda_granted_date': format_display_date(prop.granted_date, 'mpda'),
        'mpda_rejected_date': format_display_date(prop.rejected_date, 'mpda'),
        'mpda_proposal_revoked': prop.proposal_revoked or '',
        'mpda_proposal_revoked_date': format_display_date(prop.proposal_revoked_date, 'mpda'),
        'mpda_detaining_authority': prop.detaining_authority or '',
        'mpda_detaining_authority_other': prop.detaining_authority_other or '',
        'mpda_accused_name': prop.accused_name or '',
        'mpda_accused_aadhaar': prop.accused_aadhaar or '',
        'mpda_accused_mobile': prop.accused_mobile or '',
        'mpda_accused_address': prop.accused_address or '',
        'mpda_accused_age': str(prop.accused_age) if prop.accused_age is not None else '',
        'mpda_accused_gender': prop.accused_gender or '',
        'mpda_detained': prop.detained or '',
        'mpda_detention_date': format_display_date(prop.detention_date, 'mpda'),
        'mpda_detention_completion_date': format_display_date(prop.detention_completion_date, 'mpda'),
        'mpda_jail_name': prop.jail_name or '',
        'mpda_transfer_jail_name': prop.transfer_jail_name or '',
        'mpda_govt_confirmation': prop.government_confirmation or '',
        'mpda_govt_confirmation_date': format_display_date(prop.govt_confirmation_date, 'mpda'),
        'mpda_order_revoked': prop.detention_order_revoked or '',
        'mpda_order_revoked_date': format_display_date(prop.order_revoked_date, 'mpda'),
        'mpda_category': prop.mpda_category or '',
        'mpda_category_other': prop.mpda_category_other or '',
        'mpda_total_crime': str(prop.total_crime) if prop.total_crime is not None else '',
        'mpda_serious_crimes': str(prop.serious_crimes) if prop.serious_crimes is not None else '',
        'mpda_total_misc_crime': str(prop.total_misc_crime) if prop.total_misc_crime is not None else '',
    }

    rows = []
    for ftf in ftfs:
        if ftf.field_type == 'repeating_group' or ftf.parent_field_key:
            continue
        if ftf.depends_on_field_key:
            parent_val = attr_map.get(ftf.depends_on_field_key, '')
            dep_target = str(ftf.depends_on_value or '').strip()
            if dep_target.lower() != parent_val.strip().lower():
                continue
        disp_val = attr_map.get(ftf.field_key, '')
        if with_keys:
            rows.append({'field_key': ftf.field_key, 'label': ftf.field_label,
                         'value': disp_val, 'section': ftf.section or ''})
        else:
            rows.append((ftf.field_label, disp_val))

    return rows


# Gang member form field key -> mpda_gang_members column
_GANG_COLUMNS = {
    'mpda_gang_member_name': 'name',
    'mpda_gang_member_age': 'age',
    'mpda_gang_member_gender': 'gender',
    'mpda_gang_member_mobile': 'mobile',
    'mpda_gang_member_aadhaar': 'aadhaar',
    'mpda_gang_member_address': 'address',
    'mpda_gang_member_occupation': 'occupation',
    'mpda_gang_member_pan': 'pan',
    'mpda_gang_member_cast': 'cast',
    'mpda_gang_member_religion': 'religion',
}


def _gang_member_rows(prop, entries):
    """
    Unsaved MpdaGangMember objects for every entry with at least one value
    (saved together with one bulk insert). Accepts the form keys
    (mpda_gang_member_*) and plain column names. Age must be a whole number,
    mobile 10 digits; anything else is stored empty instead of failing the save.
    """
    rows = []
    for idx, gm in enumerate(entries or [], 1):
        if not isinstance(gm, dict):
            continue
        vals = {}
        for key, col in _GANG_COLUMNS.items():
            raw = gm.get(key, gm.get(col))
            vals[col] = str(raw).strip() if raw not in (None, '') else ''
        age = None
        if vals['age']:
            try:
                age = int(vals['age'])
            except ValueError:
                age = None
            if age is not None and not MIN_AGE <= age <= MAX_AGE:
                age = None
        mobile = vals['mobile'] if re.fullmatch(r'\d{10}', vals['mobile'] or '') else None
        data = {col: (vals[col] or None) for col in _GANG_COLUMNS.values()
                if col not in ('age', 'mobile')}
        data.update(age=age, mobile=mobile)
        if any(v is not None for v in data.values()):
            rows.append(MpdaGangMember(proposal=prop, display_order=idx, **data))
    return rows


def _crime_chart_rows(prop, entries):
    """
    Unsaved MpdaCrimeChartEntry objects (saved together with one bulk insert).
    Accepts the form keys (mpda_crime_*) and plain column names; a row is kept
    when it has a CR No., date, police station or Act / Section / Subsection.
    """
    rows = []
    for ce in entries or []:
        if not isinstance(ce, dict):
            continue
        c_type = str(ce.get('mpda_crime_type') or ce.get('crime_type') or '').strip()
        custom_type = str(ce.get('mpda_crime_other_type') or ce.get('other_crime_type') or '').strip()
        if custom_type:
            c_type = custom_type
        cr_no = str(ce.get('mpda_crime_cr_no') or ce.get('mpda_cr_no') or ce.get('cr_no') or '').strip()
        ps = str(ce.get('mpda_crime_police_station') or ce.get('mpda_police_station') or ce.get('police_station') or '').strip()
        c_date = parse_display_date(ce.get('mpda_crime_date') or ce.get('crime_date'), 'mpda')
        charge = crime_charge_fields(ce.get('mpda_crime_act_section', ce.get('act_section')))
        if cr_no or c_date or ps or charge.get('act_section'):
            rows.append(MpdaCrimeChartEntry(
                proposal=prop, crime_type=c_type, cr_no=cr_no,
                crime_date=c_date, police_station=ps, **charge,
            ))
    return rows


def get_mpda_repeating_sections(prop, ftfs=None):
    """
    Constructs ordered repeating sections based on field_template_fields for MPDA:
    Returns list of tuples: (section_title, headers, rows, field_key)
    """
    if ftfs is None:
        tmpl_name = get_module_setting('mpda', 'template_name')
        ftfs = get_template_fields_ordered(tmpl_name) if tmpl_name else []

    rep_groups = [f for f in ftfs if f.field_type == 'repeating_group']
    sections = []

    for rg in rep_groups:
        child_fields = [f for f in ftfs if f.parent_field_key == rg.field_key]
        rows = []

        if rg.field_key == 'mpda_gang_members':
            headers = ['Sr. No.'] + [f.field_label for f in child_fields]
            for gm in prop.gang_members.all().order_by('display_order', 'pk'):
                rows.append([str(gm.display_order)] + [
                    '' if getattr(gm, _GANG_COLUMNS.get(f.field_key, ''), None) is None
                    else str(getattr(gm, _GANG_COLUMNS[f.field_key]))
                    for f in child_fields
                ])
        elif rg.field_key == 'mpda_crime_chart':
            headers = [f.field_label for f in child_fields]
            for e in prop.crime_chart_entries.all().order_by('crime_type', '-crime_date', 'pk'):
                val_map = {
                    'mpda_crime_type': e.crime_type or '',
                    'mpda_crime_cr_no': e.cr_no or '',
                    'mpda_crime_date': format_display_date(e.crime_date, 'mpda'),
                    'mpda_crime_police_station': e.police_station or '',
                    'mpda_crime_act_section': e.act_section or '',
                }
                rows.append([val_map.get(f.field_key, '') for f in child_fields])
        elif rg.field_key == 'mpda_accused':
            headers = ['Sr. No.'] + [f.field_label for f in child_fields]
            for acc in prop.accused_persons.all().order_by('display_order', 'pk'):
                val_map = {
                    'mpda_accused_name': acc.name or '',
                    'mpda_accused_age': str(acc.age) if acc.age is not None else '',
                    'mpda_accused_gender': acc.gender or '',
                    'mpda_accused_mobile': acc.mobile or '',
                    'mpda_accused_aadhaar': acc.aadhaar or '',
                    'mpda_accused_address': acc.address or '',
                    'mpda_accused_occupation': acc.occupation or '',
                    'mpda_accused_pan': acc.pan or '',
                    'mpda_accused_cast': acc.cast or '',
                    'mpda_accused_religion': acc.religion or '',
                }
                row_vals = [str(acc.display_order)] + [val_map.get(f.field_key, '') for f in child_fields]
                rows.append(row_vals)
        else:
            headers = [f.field_label for f in child_fields]

        sections.append((rg.field_label, headers, rows, rg.field_key))

    return sections


# Summary columns, in display order (header text: module_settings summary_header_<key>)
_SUMMARY_COLUMNS = ('sr_no', 'accused', 'gang_members', 'outcome', 'category', 'actions')


def _render_template_parts(values, template, separator):
    """
    Render a module_settings template split on '|'. A part whose placeholders
    are all empty is skipped; the remaining parts are joined with separator.
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


class MpdaSummaryView(APIView):
    """
    GET /api/mpda/summary/?page=&q= - Summary: every MPDA proposal of the user's
    station, one row each: serial, accused (name, age, gender, mobile, address of
    every accused), gang member count, outcome with its own date, MPDA category.
    Constant queries per page: settings, COUNT, the page (gang count as a
    correlated subquery) and ONE query for the page's accused persons.
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()
        if not station_name:
            return Response({'error': get_module_setting('mpda', 'no_station_message') or ''},
                            status=status.HTTP_400_BAD_REQUEST)

        smap = {
            s_.setting_key: s_.setting_value for s_ in ModuleSetting.objects.filter(
                module_key='mpda',
                setting_key__in=['summary_accused_template', 'summary_accused_separator',
                                 'summary_outcome_template', 'page_size'],
            )
        }
        try:
            page_size = int(smap.get('page_size') or 20)
            page = max(int(request.query_params.get('page', 1)), 1)
        except ValueError:
            page_size, page = 20, 1

        with TenantContext(schema):
            qs = MpdaProposal.objects.filter(station_name__iexact=station_name)
            q = request.query_params.get('q', '').strip()
            if q:
                qs = qs.filter(
                    Q(accused_name__icontains=q) |
                    Q(proposal_no__icontains=q) |
                    Q(proposal_year__icontains=q) |
                    Q(proposal_no_and_year__icontains=q) |
                    Q(accused_mobile__icontains=q) |
                    Q(io_name__icontains=q) |
                    Q(accused_persons__name__icontains=q)
                ).distinct()

            total_count = qs.count()
            start = (page - 1) * page_size
            gang_count = Coalesce(Subquery(
                MpdaGangMember.objects.filter(proposal=OuterRef('pk')).order_by()
                .values('proposal_id').annotate(c=Count('id')).values('c')[:1],
                output_field=IntegerField()), Value(0))
            rows = list(qs.annotate(gang_count=gang_count)
                        .order_by('created_at', 'id')[start:start + page_size])

            accused_by_prop = {}
            for a in MpdaAccusedPerson.objects.filter(proposal_id__in=[r.id for r in rows]) \
                    .order_by('proposal_id', 'display_order', 'id'):
                accused_by_prop.setdefault(a.proposal_id, []).append(a)

        tmpl = smap.get('summary_accused_template')
        sep = smap.get('summary_accused_separator')
        outcome_tmpl = smap.get('summary_outcome_template')
        if tmpl is None or outcome_tmpl is None:
            logger.warning("[MPDA] module_settings missing: mpda.summary_accused_template / summary_outcome_template")

        def accused_lines(prop):
            people = accused_by_prop.get(prop.id) or []
            raw = [
                {'name': a.name, 'age': a.age, 'gender': a.gender, 'mobile': a.mobile, 'address': a.address}
                for a in people
            ] or [{
                'name': prop.accused_name, 'age': prop.accused_age, 'gender': prop.accused_gender,
                'mobile': prop.accused_mobile, 'address': prop.accused_address,
            }]
            lines = []
            for r in raw:
                values = {k: ('' if v is None else str(v).strip()) for k, v in r.items()}
                line = _render_template_parts(values, tmpl, sep)
                if line:
                    lines.append(line)
            return lines

        today = datetime.date.today()
        yes_val = _get_yes_value()
        results = []
        for i, prop in enumerate(rows, start=start + 1):
            # Only one of granted_date / rejected_date is kept, matching the outcome
            outcome_date = prop.granted_date or prop.rejected_date
            outcome = _render_template_parts(
                {'outcome': (prop.proposal_outcome or '').strip(),
                 'date': format_display_date(outcome_date, 'mpda') if outcome_date else ''},
                outcome_tmpl, ' ')
            category = (prop.mpda_category or '').strip()
            other = (prop.mpda_category_other or '').strip()
            if other and other.lower() != category.lower():
                category = f"{category} ({other})" if category else other
            results.append({
                'id': prop.id,
                'sr_no': i,
                'proposal_no': prop.proposal_no_and_year or '',
                'accused': accused_lines(prop),
                'gang_members': prop.gang_count,
                'outcome': outcome,
                'category': category,
                # "Send Reminder" is offered until the Detention End Date (order not revoked)
                'can_remind': bool(
                    prop.detention_completion_date and prop.detention_completion_date >= today
                    and (prop.detention_order_revoked or '').strip().lower() != yes_val.strip().lower()
                ),
            })
        return Response({'count': total_count, 'page': page, 'page_size': page_size, 'results': results})


MPDA_MANUAL_REMINDER_CATEGORY = 'mpda_reminder'

_MPDA_REMINDER_SETTING_KEYS = [
    'detention_reminder_days', 'detention_reminder_first_days', 'detention_reminder_second_days',
    'detention_reminder_daily_from_days', 'detention_reminder_title', 'detention_reminder_message',
    'detention_reminder_banner', 'detention_reminder_tab_label', 'date_format',
    'manual_reminder_title', 'manual_reminder_message', 'manual_reminder_sent_message',
    'manual_reminder_no_officers_message', 'manual_reminder_ended_message', 'not_found_message',
]


def _mpda_reminder_settings():
    return {s_.setting_key: s_.setting_value for s_ in ModuleSetting.objects.filter(
        module_key='mpda', setting_key__in=_MPDA_REMINDER_SETTING_KEYS)}


def _setting_int(smap, key, default):
    try:
        return max(int(str(smap.get(key)).strip()), 0)
    except (TypeError, ValueError):
        return default


def _reminder_schedule(smap):
    """
    (first, second, daily_from) days before the Detention End Date: one reminder
    on the first and second day, then every day from daily_from until the end
    date (module settings; default 30, 20, 10).
    """
    first = _setting_int(smap, 'detention_reminder_first_days',
                         _setting_int(smap, 'detention_reminder_days', 30))
    second = _setting_int(smap, 'detention_reminder_second_days', 20)
    daily_from = _setting_int(smap, 'detention_reminder_daily_from_days', 10)
    return first, second, daily_from


def _safe_format(template, values):
    try:
        return (template or '').format(**values)
    except (KeyError, IndexError, ValueError):
        return template or ''


def _accused_names(prop):
    names = [a.name.strip() for a in sorted(prop.accused_persons.all(),
                                             key=lambda a: (a.display_order, a.pk))
             if (a.name or '').strip()]
    if not names and (prop.accused_name or '').strip():
        names = [prop.accused_name.strip()]
    return ', '.join(names)


def _reminder_active_q(yes_val, today):
    """Reminders run until the Detention End Date, never for a revoked order."""
    return Q(detention_completion_date__gte=today) & ~Q(detention_order_revoked__iexact=yes_val)


class MpdaDetentionRemindersView(APIView):
    """
    GET /api/mpda/reminders/ - Detention end reminders.

    Automatic (user's station): a proposal (Detained = Yes, order not revoked)
    is listed on the day its Detention End Date is `first` days away, again at
    `second` days, then every day from `daily_from` days until the end date
    (module settings, default 30 / 20 / 10). Computed on every request, so no
    scheduler is needed.
    Manual: unread "Send Reminder" notifications sent to the logged-in officer,
    while that detention has not ended. Title and message come from module
    settings (placeholders {proposal_no} {accused} {end_date} {days_left}).
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err

        station_name = str(getattr(request.user, 'station_name', '') or '').strip()
        uid = str(getattr(request.user, 'uid', '') or '').strip()
        smap = _mpda_reminder_settings()
        first, second, daily_from = _reminder_schedule(smap)
        title = smap.get('detention_reminder_title') or ''
        message_tmpl = smap.get('detention_reminder_message') or ''
        date_fmt = smap.get('date_format') or '%d/%m/%Y'
        labels = {'banner': smap.get('detention_reminder_banner') or '',
                  'tab': smap.get('detention_reminder_tab_label') or ''}
        if not station_name and not uid:
            return Response({'count': 0, 'days': first, 'labels': labels, 'results': []})

        today = datetime.date.today()
        yes_val = _get_yes_value()
        rows, manual = [], []
        with TenantContext(schema):
            if station_name:
                rows = list(
                    MpdaProposal.objects.filter(station_name__iexact=station_name, detained__iexact=yes_val)
                    .filter(_reminder_active_q(yes_val, today))
                    .filter(Q(detention_completion_date=today + datetime.timedelta(days=first)) |
                            Q(detention_completion_date=today + datetime.timedelta(days=second)) |
                            Q(detention_completion_date__lte=today + datetime.timedelta(days=daily_from)))
                    .prefetch_related('accused_persons')
                    .order_by('detention_completion_date', 'id')
                )
            if uid:
                from apps.users.models import NotificationRecord
                manual = list(NotificationRecord.objects.filter(
                    category=MPDA_MANUAL_REMINDER_CATEGORY, target_user_uid=uid, is_read=False,
                ).order_by('-created_at')[:50])
                # Manual reminders stop with the detention too
                ids = {int(m.registration_uid) for m in manual if str(m.registration_uid or '').isdigit()}
                active = set(
                    MpdaProposal.objects.filter(id__in=ids).filter(_reminder_active_q(yes_val, today))
                    .values_list('id', flat=True)
                ) if ids else set()
                manual = [m for m in manual
                          if str(m.registration_uid or '').isdigit() and int(m.registration_uid) in active]

        results = [{
            'id': f'manual-{m.id}', 'kind': 'manual', 'title': m.title, 'message': m.body,
            'end_date': '', 'days_left': None,
        } for m in manual]
        for prop in rows:
            values = {
                'proposal_no': prop.proposal_no_and_year or '',
                'accused': _accused_names(prop),
                'end_date': prop.detention_completion_date.strftime(date_fmt),
                'days_left': str((prop.detention_completion_date - today).days),
            }
            results.append({
                'id': prop.id,
                'kind': 'auto',
                'title': title,
                'message': _safe_format(message_tmpl, values),
                'end_date': values['end_date'],
                'days_left': int(values['days_left']),
                **{k: values[k] for k in ('proposal_no', 'accused')},
            })
        return Response({'count': len(results), 'days': first, 'labels': labels, 'results': results})


class MpdaRemindersSeenView(APIView):
    """POST /api/mpda/reminders/seen/ - mark the officer's manual MPDA reminders as read."""
    def post(self, request):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err
        uid = str(getattr(request.user, 'uid', '') or '').strip()
        updated = 0
        if uid:
            from apps.users.models import NotificationRecord
            with TenantContext(schema):
                updated = NotificationRecord.objects.filter(
                    category=MPDA_MANUAL_REMINDER_CATEGORY, target_user_uid=uid, is_read=False,
                ).update(is_read=True)
        return Response({'updated': updated})


def _station_officer_uids(user, station_name):
    """
    UIDs of every active officer of the police station (same station_id as the
    sender, or the same station name).
    """
    from apps.users.models import OfficerProfile
    station_id = str(getattr(user, 'station_id', '') or '').strip()
    match = Q(trimmed_station__iexact=station_name)
    if station_id:
        match |= Q(station_id=station_id)
    uids = OfficerProfile.objects.annotate(trimmed_station=Trim('station_name')) \
        .filter(account_status='active').filter(match) \
        .values_list('uid', flat=True)
    return sorted({str(u).strip() for u in uids if str(u or '').strip()})


class MpdaSendReminderView(APIView):
    """
    POST /api/mpda/<pk>/remind/ - Summary action: send a detention reminder now
    to every officer of the proposal's police station. Allowed until the
    Detention End Date and never for a revoked detention order.
    """
    def post(self, request, pk):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()
        if not station_name:
            return Response({'error': get_module_setting('mpda', 'no_station_message') or ''},
                            status=status.HTTP_400_BAD_REQUEST)

        smap = _mpda_reminder_settings()
        date_fmt = smap.get('date_format') or '%d/%m/%Y'
        today = datetime.date.today()
        yes_val = _get_yes_value()

        from apps.users.models import NotificationRecord
        with TenantContext(schema):
            prop = MpdaProposal.objects.filter(pk=pk, station_name__iexact=station_name) \
                .prefetch_related('accused_persons').first()
            if not prop:
                return Response({'error': smap.get('not_found_message') or ''},
                                status=status.HTTP_404_NOT_FOUND)
            if not MpdaProposal.objects.filter(pk=prop.pk).filter(_reminder_active_q(yes_val, today)).exists():
                return Response({'error': smap.get('manual_reminder_ended_message') or ''},
                                status=status.HTTP_400_BAD_REQUEST)
            uids = _station_officer_uids(user, station_name)
            if not uids:
                return Response({'error': smap.get('manual_reminder_no_officers_message') or ''},
                                status=status.HTTP_400_BAD_REQUEST)
            values = {
                'proposal_no': prop.proposal_no_and_year or '',
                'accused': _accused_names(prop),
                'end_date': prop.detention_completion_date.strftime(date_fmt),
                'days_left': str((prop.detention_completion_date - today).days),
                'sender': str(getattr(user, 'name', '') or '').strip(),
                'io': (prop.io_name or '').strip(),
                'station': station_name,
                'count': str(len(uids)),
            }
            title = _safe_format(smap.get('manual_reminder_title'), values)
            body = _safe_format(smap.get('manual_reminder_message'), values)
            NotificationRecord.objects.bulk_create([
                NotificationRecord(
                    target_user_uid=uid,
                    target_station_name=station_name,
                    title=title,
                    body=body,
                    category=MPDA_MANUAL_REMINDER_CATEGORY,
                    registration_uid=str(prop.id),
                    status='sent',
                ) for uid in uids
            ])

        log_standalone_audit(request, 'mpda:remind', 'mpda', prop.id)
        return Response({'message': _safe_format(smap.get('manual_reminder_sent_message'), values),
                         'sent_to': len(uids)},
                        status=status.HTTP_201_CREATED)


class MpdaConfigView(APIView):
    """
    GET /api/mpda/config/ - Dynamic configuration from module_settings
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err

        settings_qs = ModuleSetting.objects.filter(Q(module_key='mpda') | Q(module_key='common'))
        smap = {s.setting_key: s.setting_value for s in settings_qs}

        data = {
            'target_category_code': smap.get('target_category_code', ''),
            'card_labels': {
                'total': smap.get('card_total_label', ''),
                'approved': smap.get('card_approved_label', ''),
                'rejected': smap.get('card_rejected_label', ''),
                'proposal_revoked': smap.get('card_proposal_revoked_label', ''),
                'jail': smap.get('card_jail_label', ''),
                'released_next_month': smap.get('card_released_next_month_label', ''),
                'summary': smap.get('card_summary_label', ''),
            },
            'summary_headers': {
                k: smap.get(f'summary_header_{k}', '') for k in _SUMMARY_COLUMNS
            },
            'sub_tab_labels': {
                'total': smap.get('tab_total_label', ''),
                'approved': smap.get('tab_approved_label', ''),
                'rejected': smap.get('tab_rejected_label', ''),
                'proposal_revoked': smap.get('tab_proposal_revoked_label', ''),
                'jail': smap.get('tab_jail_label', ''),
                'released_next_month': smap.get('tab_released_next_month_label', ''),
            },
            'action_labels': {
                'add': smap.get('btn_add_label', ''),
                'edit': smap.get('btn_edit_label', ''),
                'view': smap.get('btn_view_label', ''),
                'pdf': smap.get('btn_pdf_label', ''),
                'remind': smap.get('btn_remind_label', ''),
            },
            'search_placeholder': smap.get('search_placeholder', ''),
            'empty_request_message': smap.get('empty_request_message', ''),
            'max_gang_members': int(smap.get('max_gang_members', 5)),
            'crime_chart_group_by_field': smap.get('crime_chart_group_by_field', 'mpda_crime_type'),
            'date_format': smap.get('date_format', '%d/%m/%Y'),
            'page_size': int(smap.get('page_size', 20)),
            'released_filter_days': _released_days_options(),
            'released_filter_label': smap.get('released_filter_label', ''),
        }
        return Response(data)


class MpdaCountsView(APIView):
    """
    GET /api/mpda/counts/ - Single query aggregated counts cached for 45s
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err

        user = request.user
        station_name = getattr(user, 'station_name', '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        st_hash = hashlib.md5(station_name.encode('utf-8')).hexdigest()
        cache_key = f"mpda:counts:{schema}:{st_hash}"
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        yes_val = _get_yes_value()
        released_days = _released_days_options()

        with TenantContext(schema):
            counts = MpdaProposal.objects.filter(station_name__iexact=station_name).aggregate(
                total_count=Count('id'),
                approved_count=Count('id', filter=_outcome_tab_q('approved', yes_val)),
                rejected_count=Count('id', filter=_outcome_tab_q('rejected', yes_val)),
                jail_count=Count('id', filter=Q(
                    detained__iexact=yes_val,
                    jail_name__isnull=False
                ) & ~Q(jail_name__exact='') & ~Q(detention_order_revoked__iexact=yes_val)),
                revoked_count=Count('id', filter=Q(detention_order_revoked__iexact=yes_val)),
                # Proposal-level "Revoked" (mpda_proposal_revoked), not the detention order
                proposal_revoked_count=Count('id', filter=_outcome_tab_q('proposal_revoked', yes_val)),
                released_next_month_count=Count('id', filter=_released_q(yes_val)),
                **{f'released_{d}_days_count': Count('id', filter=_released_q(yes_val, d))
                   for d in released_days},
            )

        data = {
            'total': counts['total_count'] or 0,
            'approved': counts['approved_count'] or 0,
            'rejected': counts['rejected_count'] or 0,
            'jail': counts['jail_count'] or 0,
            'revoked': counts['revoked_count'] or 0,
            'proposal_revoked': counts['proposal_revoked_count'] or 0,
            'released_next_month': counts['released_next_month_count'] or 0,
            # Released card day filters: {"<days>": count}
            'released_in_days': {
                str(d): counts[f'released_{d}_days_count'] or 0 for d in released_days
            },
        }
        cache_ttl = int(get_module_setting('mpda', 'counts_cache_timeout', 45))
        cache.set(cache_key, data, timeout=cache_ttl)
        return Response(data)


class MpdaOfficersView(APIView):
    """
    GET /api/mpda/officers/ - Scoped active officers for IO picker dropdown
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err

        user = request.user
        with TenantContext(schema):
            scoped_qs, error_msg = get_scoped_officers_queryset(user, 'mpda')
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


class MpdaListCreateView(APIView):
    """
    GET /api/mpda/ - Paginated list filtered by the 6 card/tab rules
    POST /api/mpda/ - Create new MPDA proposal
    """
    def get(self, request):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err

        user = request.user
        station_name = getattr(user, 'station_name', '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        with TenantContext(schema):
            qs = MpdaProposal.objects.filter(station_name__iexact=station_name)

            yes_val = _get_yes_value()

            tab = request.query_params.get('tab', 'total').strip().lower()
            if tab in ('approved', 'rejected', 'proposal_revoked'):
                qs = qs.filter(_outcome_tab_q(tab, yes_val))
            elif tab == 'jail':
                qs = qs.filter(
                    detained__iexact=yes_val,
                    jail_name__isnull=False
                ).exclude(jail_name__exact='').exclude(detention_order_revoked__iexact=yes_val)
            elif tab == 'revoked':
                qs = qs.filter(detention_order_revoked__iexact=yes_val)
            elif tab == 'released_next_month':
                # Optional ?days=N (one of released_filter_days): today .. today + N
                days = request.query_params.get('days', '').strip()
                days = int(days) if days.isdigit() and int(days) in _released_days_options() else None
                qs = qs.filter(_released_q(yes_val, days))

            q = request.query_params.get('q', '').strip()
            if q:
                qs = qs.filter(
                    Q(accused_name__icontains=q) |
                    Q(proposal_no__icontains=q) |
                    Q(proposal_year__icontains=q) |
                    Q(proposal_no_and_year__icontains=q) |
                    Q(accused_aadhaar__icontains=q) |
                    Q(accused_mobile__icontains=q) |
                    Q(io_name__icontains=q)
                )

            page_size = int(get_module_setting('mpda', 'page_size', 20))
            try:
                page = int(request.query_params.get('page', 1))
            except ValueError:
                page = 1

            total_count = qs.count()
            start = (page - 1) * page_size
            end = start + page_size
            results = list(qs.order_by('-created_at')[start:end])

            serializer = MpdaProposalListSerializer(results, many=True)
            return Response({
                'count': total_count,
                'page': page,
                'page_size': page_size,
                'results': serializer.data,
            })

    def post(self, request):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:create')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()
        if not station_name:
            return Response({'error': 'User does not belong to a valid police station.'}, status=status.HTTP_400_BAD_REQUEST)

        raw_data = request.data
        if _is_empty_mpda_payload(raw_data):
            empty_msg = get_module_setting('mpda', 'empty_request_message', 'Cannot save empty record. At least one field must be filled.')
            return Response({'error': empty_msg}, status=status.HTTP_400_BAD_REQUEST)

        norm = {}
        for k, v in raw_data.items():
            key = k[5:] if k.startswith('mpda_') else k
            norm[key] = v

        if 'govt_confirmation' in norm and 'government_confirmation' not in norm:
            norm['government_confirmation'] = norm['govt_confirmation']
        if 'order_revoked' in norm and 'detention_order_revoked' not in norm:
            norm['detention_order_revoked'] = norm['order_revoked']

        accused_data = norm.pop('accused', None)
        if accused_data is None:
            accused_data = norm.pop('mpda_accused', None)
        if accused_data is None:
            accused_data = norm.pop('accused_persons', None)
        if not accused_data:
            legacy_name = norm.pop('accused_name', None) or norm.pop('name', None)
            legacy_aadhaar = norm.pop('accused_aadhaar', None)
            legacy_mobile = norm.pop('accused_mobile', None)
            legacy_address = norm.pop('accused_address', None)
            legacy_age = norm.pop('accused_age', None)
            legacy_gender = norm.pop('accused_gender', None)
            if any([legacy_name, legacy_aadhaar, legacy_mobile, legacy_address, legacy_age, legacy_gender]):
                accused_data = [{
                    'name': legacy_name,
                    'aadhaar': legacy_aadhaar,
                    'mobile': legacy_mobile,
                    'address': legacy_address,
                    'age': legacy_age,
                    'gender': legacy_gender,
                }]
            else:
                accused_data = []

        # Gang members (unlimited rows per Requirement 8)
        gang_members_data = norm.pop('gang_members', None)
        if gang_members_data is None:
            gang_members_data = norm.pop('mpda_gang_members', None)
        if gang_members_data is None:
            gang_members_data = []

        crime_entries_data = norm.pop('crime_chart', None)
        if crime_entries_data is None:
            crime_entries_data = norm.pop('mpda_crime_chart', None)
        if crime_entries_data is None:
            crime_entries_data = norm.pop('crime_chart_entries', None)
        if crime_entries_data is None:
            crime_entries_data = []

        norm, err_msg = _sanitize_mpda_data(norm)
        if err_msg:
            return Response({'error': err_msg}, status=status.HTTP_400_BAD_REQUEST)

        try:
            with TenantContext(schema):
                with transaction.atomic():
                    # Stop reading and writing old accused columns (Requirement 6)
                    old_accused_cols = {'accused_name', 'accused_aadhaar', 'accused_mobile', 'accused_address', 'accused_age', 'accused_gender'}
                    main_kwargs = {
                        k: norm[k] for k in norm
                        if hasattr(MpdaProposal, k) and k not in ('id', 'station_name', 'created_at', 'updated_at', 'io_uid') and k not in old_accused_cols
                    }
                    prop = MpdaProposal.objects.create(
                        station_name=station_name,
                        created_by=str(getattr(user, 'uid', '') or getattr(user, 'name', '') or ''),
                        **main_kwargs
                    )

                    for idx, acc in enumerate(accused_data, 1):
                        name = str(acc.get('mpda_accused_name') or acc.get('name') or '').strip()
                        age_raw = acc.get('mpda_accused_age') or acc.get('age')
                        age = None
                        if age_raw not in ('', None):
                            try:
                                age = int(str(age_raw).strip())
                            except (ValueError, TypeError):
                                pass
                        gender = str(acc.get('mpda_accused_gender') or acc.get('gender') or '').strip() or None
                        mob_raw = str(acc.get('mpda_accused_mobile') or acc.get('mobile') or '').strip()
                        mobile = mob_raw if mob_raw else None
                        aadhaar = str(acc.get('mpda_accused_aadhaar') or acc.get('aadhaar') or '').strip() or None
                        address = str(acc.get('mpda_accused_address') or acc.get('address') or '').strip() or None
                        occupation = str(acc.get('mpda_accused_occupation') or acc.get('occupation') or '').strip() or None
                        pan = str(acc.get('mpda_accused_pan') or acc.get('pan') or '').strip() or None
                        cast = str(acc.get('mpda_accused_cast') or acc.get('cast') or '').strip() or None
                        religion = str(acc.get('mpda_accused_religion') or acc.get('religion') or '').strip() or None

                        if name or age is not None or gender or mobile or aadhaar or address or occupation or pan or cast or religion:
                            MpdaAccusedPerson.objects.create(
                                proposal=prop,
                                display_order=idx,
                                name=name or None,
                                age=age,
                                gender=gender,
                                occupation=occupation,
                                mobile=mobile,
                                aadhaar=aadhaar,
                                pan=pan,
                                cast=cast,
                                religion=religion,
                                address=address,
                            )

                    MpdaGangMember.objects.bulk_create(
                        _gang_member_rows(prop, gang_members_data)
                    )

                    MpdaCrimeChartEntry.objects.bulk_create(
                        _crime_chart_rows(prop, crime_entries_data)
                    )

                serializer = MpdaProposalDetailSerializer(prop)
                resp_data = serializer.data

            _clear_mpda_cache(schema, station_name)
            log_standalone_audit(request, 'mpda:create', 'mpda', prop.id)

            return Response(resp_data, status=status.HTTP_201_CREATED)
        except Exception as e:
            logger.exception(f"Error creating MPDA proposal in {schema}: {e}")
            return Response({'error': f"Failed to save MPDA proposal: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)


class MpdaDetailView(APIView):
    """
    GET /api/mpda/<pk>/ - View MPDA proposal with display rows
    PATCH /api/mpda/<pk>/ - Update MPDA proposal
    """
    def get(self, request, pk):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:view')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()

        with TenantContext(schema):
            prop = MpdaProposal.objects.annotate(trimmed_station=Trim('station_name')).filter(
                pk=pk, trimmed_station__iexact=station_name
            ).first()
            if not prop:
                not_found_msg = get_module_setting('mpda', 'not_found_message') or 'Record not found.'
                return Response({'error': not_found_msg}, status=status.HTTP_404_NOT_FOUND)

            serializer = MpdaProposalDetailSerializer(prop)
            data = serializer.data
            tmpl_name = get_module_setting('mpda', 'template_name')
            ftfs = get_template_fields_ordered(tmpl_name) if tmpl_name else []
            data['display_rows'] = get_mpda_display_rows(prop, schema=schema)
            data['display_fields'] = get_mpda_display_rows(prop, schema=schema, with_keys=True)

            rep_sections = get_mpda_repeating_sections(prop, ftfs=ftfs)
            data['repeating_sections'] = [
                {'field_key': k, 'section_title': t, 'headers': h, 'rows': r}
                for (t, h, r, k) in rep_sections
            ]
            data['gang_members'] = MpdaGangMemberSerializer(prop.gang_members.all().order_by('display_order', 'pk'), many=True).data
            data['crime_chart'] = MpdaCrimeChartEntrySerializer(prop.crime_chart_entries.all().order_by('crime_type', '-crime_date', 'pk'), many=True).data
            return Response(data)

    def patch(self, request, pk):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:update')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()

        with TenantContext(schema):
            prop = MpdaProposal.objects.annotate(trimmed_station=Trim('station_name')).filter(
                pk=pk, trimmed_station__iexact=station_name
            ).first()
            if not prop:
                not_found_msg = get_module_setting('mpda', 'not_found_message') or 'Record not found.'
                return Response({'error': not_found_msg}, status=status.HTTP_404_NOT_FOUND)

            raw_data = request.data
            norm = {}
            for k, v in raw_data.items():
                key = k[5:] if k.startswith('mpda_') else k
                norm[key] = v

            if 'govt_confirmation' in norm and 'government_confirmation' not in norm:
                norm['government_confirmation'] = norm['govt_confirmation']
            if 'order_revoked' in norm and 'detention_order_revoked' not in norm:
                norm['detention_order_revoked'] = norm['order_revoked']

            accused_data = norm.pop('accused', None)
            if accused_data is None:
                accused_data = norm.pop('mpda_accused', None)
            if accused_data is None:
                accused_data = norm.pop('accused_persons', None)

            gang_members_data = norm.pop('gang_members', None)
            if gang_members_data is None:
                gang_members_data = norm.pop('mpda_gang_members', None)

            crime_entries_data = norm.pop('crime_chart', None)
            if crime_entries_data is None:
                crime_entries_data = norm.pop('mpda_crime_chart', None)
            if crime_entries_data is None:
                crime_entries_data = norm.pop('crime_chart_entries', None)

            norm, err_msg = _sanitize_mpda_data(norm, is_patch=True, existing_instance=prop)
            if err_msg:
                return Response({'error': err_msg}, status=status.HTTP_400_BAD_REQUEST)

            changed_fields = []
            try:
                with transaction.atomic():
                    for k, v in norm.items():
                        if hasattr(prop, k) and k not in ('id', 'station_name', 'created_at', 'updated_at', 'gang_members', 'crime_chart_entries', 'io_uid', 'accused_persons', 'accused'):
                            setattr(prop, k, v)
                            changed_fields.append(k)

                    prop.save()

                    if accused_data is not None:
                        acc_list = accused_data or []
                        prop.accused_persons.all().delete()
                        for idx, acc in enumerate(acc_list, 1):
                            name = str(acc.get('mpda_accused_name') or acc.get('name') or '').strip()
                            age_raw = acc.get('mpda_accused_age') or acc.get('age')
                            age = None
                            if age_raw is not None and str(age_raw).strip() != '':
                                try:
                                    age = int(age_raw)
                                except (ValueError, TypeError):
                                    pass
                            gender = str(acc.get('mpda_accused_gender') or acc.get('gender') or '').strip() or None
                            mob_raw = str(acc.get('mpda_accused_mobile') or acc.get('mobile') or '').strip()
                            mobile = mob_raw if mob_raw else None
                            aadhaar = str(acc.get('mpda_accused_aadhaar') or acc.get('aadhaar') or '').strip() or None
                            address = str(acc.get('mpda_accused_address') or acc.get('address') or '').strip() or None
                            occupation = str(acc.get('mpda_accused_occupation') or acc.get('occupation') or '').strip() or None
                            pan = str(acc.get('mpda_accused_pan') or acc.get('pan') or '').strip() or None
                            cast = str(acc.get('mpda_accused_cast') or acc.get('cast') or '').strip() or None
                            religion = str(acc.get('mpda_accused_religion') or acc.get('religion') or '').strip() or None

                            if name or age is not None or gender or mobile or aadhaar or address or occupation or pan or cast or religion:
                                MpdaAccusedPerson.objects.create(
                                    proposal=prop,
                                    display_order=idx,
                                    name=name or None,
                                    age=age,
                                    gender=gender,
                                    occupation=occupation,
                                    mobile=mobile,
                                    aadhaar=aadhaar,
                                    pan=pan,
                                    cast=cast,
                                    religion=religion,
                                    address=address,
                                )

                    if gang_members_data is not None:
                        gm_list = gang_members_data or []
                        prop.gang_members.all().delete()
                        MpdaGangMember.objects.bulk_create(_gang_member_rows(prop, gm_list))

                    if crime_entries_data is not None:
                        ce_list = crime_entries_data or []
                        prop.crime_chart_entries.all().delete()
                        MpdaCrimeChartEntry.objects.bulk_create(_crime_chart_rows(prop, ce_list))

                _clear_mpda_cache(schema, station_name)
                log_standalone_audit(request, 'mpda:update', 'mpda', prop.id, changed_fields=changed_fields)

                serializer = MpdaProposalDetailSerializer(prop)
                return Response(serializer.data)
            except Exception as e:
                logger.exception(f"Error updating MPDA proposal in {schema}: {e}")
                return Response({'error': f"Failed to update MPDA proposal: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)


class MpdaNumberedCanvas(canvas.Canvas):
    """
    Two-pass canvas to dynamically compute total pages and render running footer.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont('Helvetica', 8)
        self.setFillColor(colors.HexColor('#64748B'))
        footer_text = f'Page {self._pageNumber} of {page_count}'
        self.drawRightString(A4[0] - 36, 18, footer_text)
        gen_time = datetime.datetime.now().strftime('%d/%m/%Y %H:%M')
        self.drawString(36, 18, f'Generated on {gen_time} · CONFIDENTIAL - FOR OFFICIAL USE ONLY')
        self.setStrokeColor(colors.HexColor('#CBD5E1'))
        self.setLineWidth(0.5)
        self.line(36, 28, A4[0] - 36, 28)
        self.restoreState()


def resolve_pdf_dept_title(module_key, state_code):
    """Header title for official PDFs, e.g. 'MAHARASHTRA POLICE DEPARTMENT'."""
    state_code = str(state_code).strip().upper()

    with TenantContext('public'):
        from apps.public_master.models import StateRegistry
        st_rec = StateRegistry.objects.filter(state_code__iexact=state_code).first()

    dept_suffix = str(get_module_setting(module_key, 'pdf_department_suffix', 'DEPARTMENT') or '').strip()
    police_dept_suffix = str(get_module_setting(module_key, 'pdf_police_department_suffix', 'POLICE DEPARTMENT') or '').strip()
    fallback_title = str(get_module_setting(module_key, 'pdf_fallback_title', 'POLICE DEPARTMENT') or '').strip()

    if st_rec and st_rec.police_force_title:
        pft = st_rec.police_force_title.strip().upper()
        return f"{pft} {dept_suffix}".strip() if dept_suffix else pft
    if st_rec and st_rec.state_name:
        sname = st_rec.state_name.strip().upper()
        return f"{sname} {police_dept_suffix}".strip() if police_dept_suffix else sname
    return fallback_title


def build_mpda_pdf(request, prop, filename):
    """
    Builds a professional, government-grade MPDA proposal PDF with:
    - Dynamic state police force header
    - Formatted proposal meta bar
    - Structured 4-column proposal details grid
    - Clean Accused Profile Cards (preventing truncated/squashed columns)
    - Proportional Gang Member and Crime Chart tables
    - Numbered footer with official confidentiality marking
    """
    user = getattr(request, 'user', None)
    state_code = getattr(request, 'state_code', None) or getattr(user, 'state_code', None)
    if not state_code and hasattr(request, 'auth') and isinstance(request.auth, dict):
        state_code = request.auth.get('state_code')

    if not state_code or not str(state_code).strip():
        missing_state_msg = get_module_setting('mpda', 'missing_state_message', 'State code could not be resolved from authenticated user credentials.')
        return Response({'error': missing_state_msg}, status=status.HTTP_400_BAD_REQUEST)

    dept_title = resolve_pdf_dept_title('mpda', state_code)

    subtitle = get_module_setting('mpda', 'pdf_subtitle', 'MPDA DETENTION PROPOSAL (PREVENTION OF DANGEROUS ACTIVITIES)')

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=42
    )

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'MpdaDocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=15,
        leading=18,
        alignment=1,
        textColor=colors.HexColor('#1E293B'),
        spaceAfter=3
    )
    subtitle_style = ParagraphStyle(
        'MpdaDocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=13,
        alignment=1,
        textColor=colors.HexColor('#475569'),
        spaceAfter=8
    )
    badge_style = ParagraphStyle(
        'MpdaDocBadge',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=12,
        alignment=1,
        textColor=colors.HexColor('#1E3A8A'),
    )
    sec_heading_style = ParagraphStyle(
        'MpdaSecHeading',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor('#1E3A8A'),
        spaceBefore=10,
        spaceAfter=4
    )
    card_hdr_style = ParagraphStyle(
        'MpdaCardHdr',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=12,
        textColor=colors.white
    )
    lbl_style = ParagraphStyle(
        'MpdaGridLabel',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor('#334155')
    )
    val_style = ParagraphStyle(
        'MpdaGridVal',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor('#0F172A')
    )
    th_style = ParagraphStyle(
        'MpdaTableTh',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        alignment=1,
        textColor=colors.white
    )

    story = []

    # 1. Main Header
    story.append(Paragraph(f'<b>{saxutils.escape(dept_title)}</b>', title_style))
    story.append(Paragraph(saxutils.escape(subtitle), subtitle_style))

    # Meta banner bar
    prop_no_str = str(prop.proposal_no_and_year or prop.id or '-')
    station_str = str(prop.station_name or '-')
    status_str = str(prop.proposal_outcome or 'Under Process')
    meta_bar = [
        [
            Paragraph(f'<b>Proposal No:</b> {saxutils.escape(prop_no_str)}', badge_style),
            Paragraph(f'<b>Station:</b> {saxutils.escape(station_str)}', badge_style),
            Paragraph(f'<b>Status:</b> {saxutils.escape(status_str)}', badge_style)
        ]
    ]
    t_meta = Table(meta_bar, colWidths=[174, 173, 173])
    t_meta.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#EEF2FF')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#C7D2FE')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_meta)
    story.append(Spacer(1, 8))

    # 2. Proposal Details Table
    story.append(Paragraph('<b>1. PROPOSAL & DETENTION DETAILS</b>', sec_heading_style))
    # Revoked / detention date labels come from the form definition
    tmpl_name = get_module_setting('mpda', 'template_name')
    form_labels = {f.field_key: f.field_label
                   for f in (get_template_fields_ordered(tmpl_name) if tmpl_name else [])}
    revoked_label = form_labels.get('mpda_proposal_revoked', 'Revoked')
    revoked_date_label = form_labels.get('mpda_proposal_revoked_date', 'Revoked Date')
    det_start_label = form_labels.get('mpda_detention_date', 'Detention Start Date')
    det_end_label = form_labels.get('mpda_detention_completion_date', 'Detention End Date')
    p_data = [
        [
            Paragraph('<b>Proposal No. & Year</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.proposal_no_and_year or '-')), val_style),
            Paragraph('<b>Proposal Outcome</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.proposal_outcome or '-')), val_style),
        ],
        [
            Paragraph('<b>IO Name</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.io_name or '-')), val_style),
            Paragraph('<b>Designation</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.io_post or '-')), val_style),
        ],
        [
            Paragraph(f'<b>{saxutils.escape(revoked_label)}</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.proposal_revoked or '-')), val_style),
            Paragraph(f'<b>{saxutils.escape(revoked_date_label)}</b>', lbl_style),
            Paragraph(saxutils.escape(format_display_date(prop.proposal_revoked_date, 'mpda') or '-'), val_style),
        ],
        [
            Paragraph('<b>Detaining Authority</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.detaining_authority or prop.detaining_authority_other or '-')), val_style),
            Paragraph('<b>Detained Status</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.detained or '-')), val_style),
        ],
        [
            Paragraph(f'<b>{saxutils.escape(det_start_label)}</b>', lbl_style),
            Paragraph(saxutils.escape(format_display_date(prop.detention_date, 'mpda') or '-'), val_style),
            Paragraph(f'<b>{saxutils.escape(det_end_label)}</b>', lbl_style),
            Paragraph(saxutils.escape(format_display_date(prop.detention_completion_date, 'mpda') or '-'), val_style),
        ],
        [
            Paragraph('<b>Jail Name</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.jail_name or '-')), val_style),
            Paragraph('<b>Transfer Jail</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.transfer_jail_name or '-')), val_style),
        ],
        [
            Paragraph('<b>Govt. Confirmation</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.government_confirmation or '-')), val_style),
            Paragraph('<b>Confirmation Date</b>', lbl_style),
            Paragraph(saxutils.escape(format_display_date(prop.govt_confirmation_date, 'mpda') or '-'), val_style),
        ],
        [
            Paragraph('<b>MPDA Category</b>', lbl_style),
            Paragraph(saxutils.escape(str(prop.mpda_category or prop.mpda_category_other or '-')), val_style),
            Paragraph('<b>Misc / Serious / Total Crimes</b>', lbl_style),
            Paragraph(saxutils.escape(f"{prop.total_misc_crime or '0'} misc / {prop.serious_crimes or '0'} serious / {prop.total_crime or '0'} total"), val_style),
        ],
    ]
    t_prop = Table(p_data, colWidths=[115, 145, 115, 145])
    t_prop.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (0,-1), colors.HexColor('#F8FAFC')),
        ('BACKGROUND', (2,0), (2,-1), colors.HexColor('#F8FAFC')),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_prop)
    story.append(Spacer(1, 8))

    # 3. Accused Person(s) Profile Card
    story.append(Paragraph('<b>2. ACCUSED PERSON(S) DETAILS</b>', sec_heading_style))
    accused_list = list(prop.accused_persons.all().order_by('display_order', 'pk'))
    if not accused_list and prop.accused_name:
        class PseudoAccused:
            display_order = 1
            name = prop.accused_name
            age = prop.accused_age
            gender = prop.accused_gender
            mobile = prop.accused_mobile
            aadhaar = prop.accused_aadhaar
            pan = ''
            cast = ''
            religion = ''
            occupation = ''
            address = prop.accused_address
        accused_list = [PseudoAccused()]

    if not accused_list:
        story.append(Paragraph('No accused persons recorded for this proposal.', val_style))
    else:
        for idx, acc in enumerate(accused_list, 1):
            acc_name_str = saxutils.escape(str(acc.name or "").upper())
            disp_order = getattr(acc, 'display_order', idx) or idx
            acc_hdr = [[
                Paragraph(f'<b>ACCUSED PERSON #{idx}: {acc_name_str}</b>', card_hdr_style),
                Paragraph(f'<b>Order:</b> {disp_order}', card_hdr_style)
            ]]
            t_acc_hdr = Table(acc_hdr, colWidths=[420, 100])
            t_acc_hdr.setStyle(TableStyle([
                ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#1E3A8A')),
                ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
                ('ALIGN', (1,0), (1,-1), 'RIGHT'),
                ('TOPPADDING', (0,0), (-1,-1), 4),
                ('BOTTOMPADDING', (0,0), (-1,-1), 4),
                ('LEFTPADDING', (0,0), (-1,-1), 6),
                ('RIGHTPADDING', (0,0), (-1,-1), 6),
            ]))

            gender_age = f'{acc.age} Yrs' if acc.age else ''
            if acc.gender:
                gender_age = f'{gender_age} / {acc.gender}' if gender_age else str(acc.gender)
            if not gender_age:
                gender_age = '-'

            acc_body = [
                [
                    Paragraph('<b>Full Name</b>', lbl_style),
                    Paragraph(saxutils.escape(str(acc.name or '-')), val_style),
                    Paragraph('<b>Age / Gender</b>', lbl_style),
                    Paragraph(saxutils.escape(gender_age), val_style),
                ],
                [
                    Paragraph('<b>Mobile No.</b>', lbl_style),
                    Paragraph(saxutils.escape(str(acc.mobile or '-')), val_style),
                    Paragraph('<b>Aadhaar No.</b>', lbl_style),
                    Paragraph(saxutils.escape(str(acc.aadhaar or '-')), val_style),
                ],
                [
                    Paragraph('<b>PAN Card</b>', lbl_style),
                    Paragraph(saxutils.escape(str(getattr(acc, "pan", "") or '-')), val_style),
                    Paragraph('<b>Occupation</b>', lbl_style),
                    Paragraph(saxutils.escape(str(getattr(acc, "occupation", "") or '-')), val_style),
                ],
                [
                    Paragraph('<b>Caste</b>', lbl_style),
                    Paragraph(saxutils.escape(str(getattr(acc, "cast", "") or '-')), val_style),
                    Paragraph('<b>Religion</b>', lbl_style),
                    Paragraph(saxutils.escape(str(getattr(acc, "religion", "") or '-')), val_style),
                ],
                [
                    Paragraph('<b>Residential Address</b>', lbl_style),
                    Paragraph(saxutils.escape(str(acc.address or '-')), val_style),
                    '',
                    '',
                ],
            ]
            t_acc_body = Table(acc_body, colWidths=[115, 145, 115, 145])
            t_acc_body.setStyle(TableStyle([
                ('SPAN', (1, 4), (3, 4)),
                ('BACKGROUND', (0,0), (0,-1), colors.HexColor('#F8FAFC')),
                ('BACKGROUND', (2,0), (2,-2), colors.HexColor('#F8FAFC')),
                ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
                ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
                ('TOPPADDING', (0,0), (-1,-1), 3.5),
                ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
                ('LEFTPADDING', (0,0), (-1,-1), 5),
                ('RIGHTPADDING', (0,0), (-1,-1), 5),
            ]))

            card_flowables = [t_acc_hdr, t_acc_body, Spacer(1, 6)]
            story.append(KeepTogether(card_flowables))

    # 4. Gang Members Section
    story.append(Paragraph('<b>3. GANG / GROUP MEMBERS</b>', sec_heading_style))
    gang_list = list(prop.gang_members.all().order_by('display_order', 'pk'))
    if not gang_list:
        story.append(Paragraph('No gang / group members recorded.', val_style))
        story.append(Spacer(1, 6))
    else:
        g_rows = [[
            Paragraph('<b>Sr. No.</b>', th_style),
            Paragraph('<b>Member Name</b>', th_style),
            Paragraph('<b>Age / Gender</b>', th_style),
            Paragraph('<b>Mobile</b>', th_style),
            Paragraph('<b>Occupation</b>', th_style),
            Paragraph('<b>Address</b>', th_style),
        ]]
        for g in gang_list:
            age_gender = ' / '.join(x for x in (f'{g.age} Yrs' if g.age else '', g.gender or '') if x)
            g_rows.append([
                Paragraph(str(g.display_order), val_style),
                Paragraph(saxutils.escape(str(g.name or '-')), val_style),
                Paragraph(saxutils.escape(age_gender or '-'), val_style),
                Paragraph(saxutils.escape(str(g.mobile or '-')), val_style),
                Paragraph(saxutils.escape(str(g.occupation or '-')), val_style),
                Paragraph(saxutils.escape(str(g.address or '-')), val_style),
            ])
        t_gang = Table(g_rows, colWidths=[40, 110, 70, 75, 80, 145], repeatRows=1)
        t_gang.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1E3A8A')),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
            ('ALIGN', (0,1), (0,-1), 'CENTER'),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 3.5),
            ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
            ('LEFTPADDING', (0,0), (-1,-1), 5),
            ('RIGHTPADDING', (0,0), (-1,-1), 5),
        ]))
        story.append(t_gang)
        story.append(Spacer(1, 8))

    # 5. Crime Chart Section
    story.append(Paragraph('<b>4. CRIME CHART / CRIMINAL HISTORY</b>', sec_heading_style))
    crimes_list = list(prop.crime_chart_entries.all().order_by('crime_type', '-crime_date', 'pk'))
    if not crimes_list:
        story.append(Paragraph('No criminal cases recorded.', val_style))
    else:
        c_rows = [[
            Paragraph('<b>Sr. No.</b>', th_style),
            Paragraph('<b>Crime Type</b>', th_style),
            Paragraph('<b>CR No.</b>', th_style),
            Paragraph('<b>Date</b>', th_style),
            Paragraph('<b>Police Station</b>', th_style),
            Paragraph('<b>Act / Section / Subsection</b>', th_style),
        ]]
        for idx, c in enumerate(crimes_list, 1):
            c_rows.append([
                Paragraph(str(idx), val_style),
                Paragraph(saxutils.escape(str(c.crime_type or '-')), val_style),
                Paragraph(saxutils.escape(str(c.cr_no or '-')), val_style),
                Paragraph(saxutils.escape(format_display_date(c.crime_date, 'mpda') or '-'), val_style),
                Paragraph(saxutils.escape(str(c.police_station or '-')), val_style),
                Paragraph(saxutils.escape(str(c.act_section or '-')), val_style),
            ])
        t_crime = Table(c_rows, colWidths=[30, 110, 80, 65, 100, 135])
        t_crime.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1E3A8A')),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
            ('ALIGN', (0,1), (0,-1), 'CENTER'),
            ('ALIGN', (3,1), (3,-1), 'CENTER'),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('TOPPADDING', (0,0), (-1,-1), 3.5),
            ('BOTTOMPADDING', (0,0), (-1,-1), 3.5),
            ('LEFTPADDING', (0,0), (-1,-1), 5),
            ('RIGHTPADDING', (0,0), (-1,-1), 5),
        ]))
        story.append(t_crime)

    doc.build(story, canvasmaker=MpdaNumberedCanvas)
    pdf_bytes = buffer.getvalue()
    buffer.close()

    response = HttpResponse(pdf_bytes, content_type='application/pdf')
    response['Content-Disposition'] = f'inline; filename="{filename}"'
    return response


class MpdaPDFView(APIView):
    """
    GET /api/mpda/<pk>/pdf/ - Downloadable / inline PDF
    """
    def get(self, request, pk):
        schema, err = resolve_tenant_and_auth(request, 'mpda', 'mpda:pdf')
        if err:
            return err

        user = request.user
        station_name = str(getattr(user, 'station_name', '') or '').strip()

        with TenantContext(schema):
            prop = MpdaProposal.objects.annotate(trimmed_station=Trim('station_name')).filter(
                pk=pk, trimmed_station__iexact=station_name
            ).first()
            if not prop:
                not_found_msg = get_module_setting('mpda', 'not_found_message') or 'Record not found.'
                return Response({'error': not_found_msg}, status=status.HTTP_404_NOT_FOUND)

            log_standalone_audit(request, 'mpda:pdf', 'mpda', prop.id)

            pdf_prefix = get_module_setting('mpda', 'pdf_filename_prefix') or 'MPDA_Proposal'
            clean_prop_no = str(prop.proposal_no_and_year or prop.id).replace('/', '_').replace(' ', '_')
            filename = f"{pdf_prefix}_{prop.station_name}_{clean_prop_no}.pdf"

            return build_mpda_pdf(request, prop, filename)

