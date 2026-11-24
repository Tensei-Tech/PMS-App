"""
A "1 to 5" / Part 6 case as a one-document PDF in the same style as the RTI
report: the force title, a subtitle with the tab and station, then a label /
value table.

The rows come from the case's own form (get_form_definition of its tab), so
labels and their order are the ones the form shows; nothing is typed here.
Values come from the case record, its related tables, its extra fields and
the table-stored template values.
"""
import io
import xml.sax.saxutils as saxutils

from apps.crimetab.models import CaseCategory


def _text(value) -> str:
    if value is None:
        return ''
    if isinstance(value, bool):
        return 'Yes' if value else 'No'
    if isinstance(value, (list, tuple)):
        parts = [_text(v) for v in value if not isinstance(v, dict)]
        return ', '.join(p for p in parts if p)
    if isinstance(value, dict):
        return ''
    return str(value).strip()


def _case_values(data: dict) -> dict:
    """field key -> value from the full case data, first non-empty value wins."""
    values = {}

    def merge(d):
        if not isinstance(d, dict):
            return
        for key, value in d.items():
            if value in (None, '', [], {}):
                continue
            values.setdefault(key, value)

    extra = data.get('extra_fields') if isinstance(data.get('extra_fields'), dict) else {}
    merge(extra)
    for nested in ('commonForm', 'extra_field_values', 'dynamic_extra_fields'):
        merge(extra.get(nested))
    for section in ('registration_info', 'crime_spot', 'responsibility', 'cctv_technical', 'forensics',
                    'preventive_bond', 'scrutiny_pipeline', 'final_verdict'):
        merge(data.get(section))
    merge({k: v for k, v in data.items() if not isinstance(v, (dict, list))})
    if data.get('case_number'):
        values.setdefault('cr_number', data['case_number'])
    return values


def case_category(case):
    """The case's tab: a linked category, else one named like its sub-category ("1 to 5" / Part 6 first)."""
    link = case.category_links.select_related('category').order_by('-is_primary').first()
    if link and link.category_id:
        return link.category
    sub = (case.sub_category or '').strip()
    if not sub:
        return None
    cats = list(CaseCategory.objects.filter(category_name__iexact=sub, is_active=True))
    cats.sort(key=lambda c: (c.group_id not in (1, 2), c.group_id or 99, c.category_id))
    return cats[0] if cats else None


def case_report_rows(case, data: dict):
    """[(kind, label, value)]: kind is 'section' (a heading) or 'row'."""
    from apps.crimetab.services.dynamic_form_service import get_form_definition

    values = _case_values(data)
    rows = []
    category = case_category(case)
    fields = get_form_definition(category.category_id)['fields'] if category else []

    children = {}
    for f in fields:
        if f.get('parent_field_key'):
            children.setdefault(f['parent_field_key'], []).append(f)

    current_section = None
    for f in fields:
        key, ftype = f['field_key'], f.get('field_type')
        if f.get('parent_field_key') or ftype == 'charges':
            continue
        label = (f.get('field_label') or key).strip()
        if ftype == 'repeating_group':
            items = values.get(key) if isinstance(values.get(key), list) else []
            entries = []
            for i, item in enumerate(i for i in items if isinstance(i, dict)):
                cells = [f"{(c.get('field_label') or c['field_key']).strip()}: {_text(item.get(c['field_key']))}"
                         for c in children.get(key, []) if _text(item.get(c['field_key']))]
                if cells:
                    entries.append((f'{label} {i + 1}', '; '.join(cells)))
            new_rows = entries
        else:
            text = _text(values.get(key))
            new_rows = [(label, text)] if text else []
        if new_rows:
            section = (f.get('section') or '').strip()
            if section and section != current_section:
                rows.append(('section', section, ''))
                current_section = section
            rows.extend(('row', lbl, val) for lbl, val in new_rows)

    charges = [c for c in data.get('charges') or [] if isinstance(c, dict)]
    if charges:
        rows.append(('section', 'Acts & Sections', ''))
        for c in charges:
            act = _text(c.get('act_name'))
            section = ' '.join(p for p in (_text(c.get('section_number')), _text(c.get('subsection_code'))) if p)
            rows.append(('row', act or 'Act', ' – '.join(p for p in (section, _text(c.get('section_title'))) if p)))

    persons = [p for p in data.get('persons') or [] if isinstance(p, dict)]
    if persons:
        rows.append(('section', 'Persons', ''))
        counts = {}
        for p in persons:
            role = _text(p.get('role')).replace('_', ' ').title() or 'Person'
            counts[role] = counts.get(role, 0) + 1
            details = [_text(p.get(k)) for k in ('name', 'age', 'gender', 'mobile', 'address')]
            rows.append(('row', f'{role} {counts[role]}', ', '.join(d for d in details if d)))
    return rows


def build_case_report_pdf(case, data: dict, force_title: str) -> bytes:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('TitleStyle', parent=styles['Heading1'], fontSize=16, leading=20, alignment=1,
                                 textColor=colors.HexColor('#1A237E'))
    subtitle_style = ParagraphStyle('SubTitleStyle', parent=styles['Normal'], fontSize=11, leading=14, alignment=1,
                                    textColor=colors.HexColor('#37474F'))
    label_style = ParagraphStyle('LabelStyle', parent=styles['Normal'], fontSize=10, leading=12,
                                 textColor=colors.HexColor('#263238'))
    value_style = ParagraphStyle('ValueStyle', parent=styles['Normal'], fontSize=10, leading=12,
                                 textColor=colors.HexColor('#000000'))
    section_style = ParagraphStyle('SectionStyle', parent=styles['Normal'], fontSize=10.5, leading=13,
                                   textColor=colors.HexColor('#1A237E'))

    tab = (case.sub_category or case.module_key or 'Case').strip()
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
    story = [
        Paragraph(f'<b>{saxutils.escape(force_title)}</b>', title_style),
        Paragraph(saxutils.escape(f'{tab} Case Report · CR No. {case.case_number or "—"} · Station: '
                                  f'{case.station_name or "—"}'), subtitle_style),
        Spacer(1, 15),
    ]

    table_data, style = [], [
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#F5F7FA')),
        ('BACKGROUND', (1, 0), (1, -1), colors.HexColor('#FFFFFF')),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CFD8DC')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('PADDING', (0, 0), (-1, -1), 5),
    ]
    rows = case_report_rows(case, data) or [('row', 'CR Number', case.case_number or '—')]
    for kind, label, value in rows:
        i = len(table_data)
        if kind == 'section':
            table_data.append([Paragraph(f'<b>{saxutils.escape(label)}</b>', section_style), ''])
            style += [('SPAN', (0, i), (1, i)), ('BACKGROUND', (0, i), (1, i), colors.HexColor('#E8EAF6'))]
        else:
            table_data.append([Paragraph(f'<b>{saxutils.escape(label)}</b>', label_style),
                               Paragraph(saxutils.escape(value), value_style)])
    table = Table(table_data, colWidths=[180, 340], repeatRows=0)
    table.setStyle(TableStyle(style))
    story.append(table)
    doc.build(story)
    return buffer.getvalue()
