"""
Import Acts, Sections and Subsections from Excel files.

    python manage.py import_acts                      # every .xlsx in backend/data/acts/
    python manage.py import_acts path/to/file.xlsx    # one file (or another folder)
    python manage.py import_acts --dry-run            # show what would be added, write nothing

Writes to the database in DATABASE_URL (Supabase now, AWS later): run it after
`migrate` on any new database and the three tables are filled.

Each sheet is recognised by its header row (case, spaces and '-' ignored; other
columns skipped; rows above the header ignored):

1. Sections (one row per subsection; a section's rows may repeat act / number / title)
       CRIME TYPE   title           (also: SECTION TITLE, TITLE, DESCRIPTION)
       ACT          act name        e.g. BNS 2023
       SECTION      section number  e.g. 101, 304A
       SUB-SECTION  code            e.g. 1, a, 1(a) (blank: the section itself)
       IPC          old IPC section(s), optional
   A row with a SUB-SECTION gives that subsection's title / IPC; a row without
   one gives the section's. Heading rows (no ACT and no SECTION) are skipped.

2. Act name aliases (act_aliases.xlsx): ALIAS | ACT
   Any act name equal to an ALIAS (ignoring case) is stored under ACT, so
   'BNS 2023' in a section file goes to the act's official name.

Safe to run again: acts are matched by name (ignoring case), sections by act +
number, subsections by section + code. Existing rows are never removed and
existing values never overwritten; only empty titles / IPC are filled in.
"""
import re
from collections import OrderedDict
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.db.models import Max

from apps.crimetab.models.common_form import Act, ActSection, ActSubsection

DEFAULT_DIR = Path(settings.BASE_DIR) / 'data' / 'acts'
MAX_COLUMNS = 50  # some sheets report thousands of empty formatted columns

# Section sheets: normalised header -> column role
HEADERS = {
    'act': 'act',
    'actname': 'act',
    'section': 'section',
    'sectionno': 'section',
    'sectionnumber': 'section',
    'subsection': 'subsection',
    'subsectionno': 'subsection',
    'subsectioncode': 'subsection',
    'crimetype': 'title',
    'sectiontitle': 'title',
    'title': 'title',
    'description': 'title',
    'ipc': 'ipc',
    'ipcsection': 'ipc',
    'ipcsectionno': 'ipc',
}
REQUIRED = ('act', 'section')


def _norm_header(value):
    return re.sub(r'[^a-z0-9]', '', str(value or '').lower())


def _cell(value):
    """Cell text: numbers without '.0', inner whitespace collapsed, trimmed."""
    if value is None:
        return ''
    if isinstance(value, float) and value.is_integer():
        value = int(value)
    return re.sub(r'\s+', ' ', str(value).replace('\xa0', ' ')).strip()


def _limit(model, name):
    return model._meta.get_field(name).max_length  # None for text columns


class Command(BaseCommand):
    help = 'Import Acts / Sections / Subsections from Excel files (see module docstring).'

    def add_arguments(self, parser):
        parser.add_argument('paths', nargs='*', help=f'.xlsx files or folders (default: {DEFAULT_DIR})')
        parser.add_argument('--dry-run', action='store_true', help='Show what would be added; write nothing.')

    def handle(self, *args, **opts):
        try:
            import openpyxl
        except ImportError as e:
            raise CommandError('openpyxl is required: pip install openpyxl') from e

        files = self._collect_files(opts['paths'] or [str(DEFAULT_DIR)])
        if not files:
            raise CommandError('No .xlsx files found.')

        self.aliases, self.rows, problems = {}, [], []
        for path in files:
            wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
            for ws in wb.worksheets:
                problems += self._read_sheet(ws, f'{path.name} [{ws.title}]')
            wb.close()
        problems += self._check_limits()

        if problems:
            for p in problems:
                self.stderr.write(self.style.ERROR(p))
            raise CommandError(f'{len(problems)} problem(s) found; nothing was imported. Fix the files and run again.')

        dry = opts['dry_run']
        with transaction.atomic():
            added = self._import()
            if dry:
                transaction.set_rollback(True)

        prefix = '[dry run] would add' if dry else 'Added'
        self.stdout.write(self.style.SUCCESS(
            f"{prefix} {added['acts']} act(s), {added['sections']} section(s), "
            f"{added['subsections']} subsection(s) from {len(self.rows)} row(s) in {len(files)} file(s)."
        ))
        if added['updated']:
            self.stdout.write(f"{'[dry run] would fill' if dry else 'Filled'} empty values on "
                              f"{added['updated']} existing row(s).")

    # ── reading ──────────────────────────────────────────────────────────────
    def _collect_files(self, paths):
        files = []
        for p in map(Path, paths):
            if p.is_dir():
                files += sorted(f for f in p.glob('*.xlsx') if not f.name.startswith('~$'))
            elif p.is_file() and p.suffix.lower() == '.xlsx':
                files.append(p)
            else:
                raise CommandError(f'Not an .xlsx file or folder: {p}')
        return files

    def _read_sheet(self, ws, where):
        """Reads one sheet into aliases / rows; returns problems."""
        problems, kind, cols = [], None, None
        for line_no, raw in enumerate(ws.iter_rows(values_only=True, max_col=MAX_COLUMNS), 1):
            values = [_cell(v) for v in raw]
            if not any(values):
                continue
            get = (lambda role: values[cols[role]] if cols.get(role) is not None
                   and cols[role] < len(values) else '')
            if kind is None:
                kind, cols = self._detect(values)
                continue  # rows before (and the) header row
            if kind == 'alias':
                if get('alias') and get('act'):
                    self.aliases[get('alias').lower()] = get('act')
            else:
                act, section = get('act'), get('section')
                if not act and not section:
                    continue  # heading row, e.g. 'Rape 63 (crime against women)'
                if not act or not section:
                    problems.append(f'{where} row {line_no}: ACT and SECTION are required.')
                    continue
                self.rows.append({'where': f'{where} row {line_no}', 'act': act, 'section': section,
                                  'title': get('title'), 'sub': get('subsection'), 'ipc': get('ipc')})
        if kind is None:
            self.stderr.write(self.style.WARNING(f'{where}: no recognised header row; skipped.'))
        return problems

    def _detect(self, values):
        """(kind, {role: column index}) for a header row, or (None, None)."""
        norm = [_norm_header(v) for v in values]
        if 'alias' in norm and 'act' in norm:
            return 'alias', {'alias': norm.index('alias'), 'act': norm.index('act')}
        found = {}
        for i, h in enumerate(norm):
            if h in HEADERS:
                found.setdefault(HEADERS[h], i)
        if all(r in found for r in REQUIRED):
            return 'sections', found
        return None, None

    def _act_name(self, name):
        return self.aliases.get(name.strip().lower(), name.strip())

    def _check_limits(self):
        problems = []
        checks = [('act', Act, 'act_name'), ('section', ActSection, 'section_number'),
                  ('sub', ActSubsection, 'subsection_code'), ('ipc', ActSection, 'ipc_section')]
        for row in self.rows:
            row['act'] = self._act_name(row['act'])
            for key, model, field in checks:
                limit = _limit(model, field)
                if limit and len(row[key]) > limit:
                    problems.append(f"{row['where']}: {key} longer than {limit} characters: {row[key]!r}")
        return problems

    # ── writing ──────────────────────────────────────────────────────────────
    def _import(self):
        added = {'acts': 0, 'sections': 0, 'subsections': 0, 'updated': 0}

        # Acts, in the order they first appear in the files
        acts = {a.act_name.strip().lower(): a for a in Act.objects.all()}
        order = (Act.objects.aggregate(m=Max('display_order'))['m'] or 0) + 10
        wanted = list(OrderedDict.fromkeys(r['act'] for r in self.rows))
        new_acts = []
        for name in wanted:
            if name.lower() not in acts:
                act = Act(act_name=name, display_order=order)
                acts[name.lower()] = act
                new_acts.append(act)
                order += 10
        Act.objects.bulk_create(new_acts)
        added['acts'] = len(new_acts)
        acts = {a.act_name.strip().lower(): a for a in Act.objects.all()}


        # Sections: rows without a subsection first, so they give the section's title
        act_ids = {acts[r['act'].lower()].pk for r in self.rows}
        sections = {(s.act_id, s.section_number.lower()): s
                    for s in ActSection.objects.filter(act_id__in=act_ids)}
        new_sections, changed = {}, {}
        for r in sorted(self.rows, key=lambda r: bool(r['sub'])):
            key = (acts[r['act'].lower()].pk, r['section'].lower())
            sec = sections.get(key) or new_sections.get(key)
            if sec is None:
                sec = ActSection(act_id=key[0], section_number=r['section'], section_title='')
                new_sections[key] = sec
            if self._fill(sec, {'section_title': r['title'], 'ipc_section': r['ipc']}) and sec.pk:
                changed[sec.pk] = sec
        ActSection.objects.bulk_create(list(new_sections.values()))
        if changed:
            ActSection.objects.bulk_update(list(changed.values()), ['section_title', 'ipc_section'])
        added['sections'] = len(new_sections)
        added['updated'] += len(changed)
        sections = {(s.act_id, s.section_number.lower()): s
                    for s in ActSection.objects.filter(act_id__in=act_ids)}

        # Subsections
        subs = {(s.section_id, s.subsection_code): s
                for s in ActSubsection.objects.filter(section__act_id__in=act_ids)}
        new_subs, changed = {}, {}
        for r in self.rows:
            if not r['sub']:
                continue
            sec = sections[(acts[r['act'].lower()].pk, r['section'].lower())]
            key = (sec.pk, r['sub'])
            sub = subs.get(key) or new_subs.get(key)
            if sub is None:
                sub = ActSubsection(section=sec, subsection_code=r['sub'])
                new_subs[key] = sub
            # A title equal to the section's (repeated on every row) adds nothing
            title = r['title'] if r['title'] != sec.section_title else ''
            if self._fill(sub, {'subsection_title': title, 'ipc_section': r['ipc']}) and sub.pk:
                changed[sub.pk] = sub
        ActSubsection.objects.bulk_create(list(new_subs.values()))
        if changed:
            ActSubsection.objects.bulk_update(list(changed.values()), ['subsection_title', 'ipc_section'])
        added['subsections'] = len(new_subs)
        added['updated'] += len(changed)
        return added

    @staticmethod
    def _fill(obj, values):
        """Sets each non-empty value whose field is still empty; True if anything changed."""
        changed = False
        for field, value in values.items():
            if value and not getattr(obj, field):
                setattr(obj, field, value)
                changed = True
        return changed
