import tempfile
from io import StringIO
from pathlib import Path

import openpyxl
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase

from apps.crimetab.models.common_form import Act, ActSection, ActSubsection

DATA = Path(__file__).resolve().parents[3] / 'data' / 'acts'
SAMPLE = DATA / 'Murder sections.xlsx'
ALIASES = DATA / 'act_aliases.xlsx'
BNS = 'THE BHARATIYA NYAYA SANHITA (BNS), 2023'
HEADER = ['CRIME TYPE', 'ACT', 'SECTION', 'SUB-SECTION', 'IPC']


def _xlsx(folder, name, rows, sheet='Sheet1'):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = sheet
    for r in rows:
        ws.append(r)
    path = Path(folder) / name
    wb.save(path)
    return path


def _run(*args):
    out, err = StringIO(), StringIO()
    call_command('import_acts', *map(str, args), stdout=out, stderr=err)
    return out.getvalue()


class ImportActsTests(TestCase):
    def test_sample_file_fills_all_three_tables_and_is_safe_to_rerun(self):
        out = _run(SAMPLE, ALIASES)
        self.assertIn('Added 1 act(s), 11 section(s), 10 subsection(s)', out)
        act = Act.objects.get(act_name=BNS)  # 'BNS 2023' stored under the alias's official name
        murder = ActSection.objects.get(act=act, section_number='101')
        self.assertEqual((murder.section_title, murder.ipc_section), ('Murder', '300'))
        self.assertEqual(sorted(murder.subsections.values_list('subsection_code', flat=True)),
                         ['a', 'b', 'c', 'd'])  # 'b ' and 'c  ' trimmed
        self.assertEqual(ActSection.objects.get(act=act, section_number='108').ipc_section, '306')  # number cell
        self.assertFalse(ActSection.objects.get(act=act, section_number='100').subsections.exists())

        self.assertIn('Added 0 act(s), 0 section(s), 0 subsection(s)', _run(SAMPLE, ALIASES))
        self.assertEqual(ActSubsection.objects.count(), 10)

    def test_ipc_and_title_per_subsection(self):
        with tempfile.TemporaryDirectory() as d:
            _xlsx(d, 'a.xlsx', [
                ['TEST heading row (no act, no section)'],
                HEADER,
                ['TEST Endangering', 'TEST Act', 125, 'a', '337'],   # subsection before its section row
                ['TEST Endangering', 'TEST Act', 125, None, 336],
                ['TEST Endangering', 'TEST Act', 125, 'b', '338'],
                ['TEST Manufacture liquor', 'TEST Act', 12, 'a', None],
                ['TEST Prohibition of manufacture', 'TEST Act', 12, None, None],
            ])
            _run(d)
        sec = ActSection.objects.get(section_number='125')
        self.assertEqual((sec.section_title, sec.ipc_section), ('TEST Endangering', '336'))
        self.assertEqual(dict(sec.subsections.values_list('subsection_code', 'ipc_section')),
                         {'a': '337', 'b': '338'})
        self.assertIsNone(sec.subsections.get(subsection_code='a').subsection_title)  # same as section's
        liquor = ActSection.objects.get(section_number='12')
        self.assertEqual(liquor.section_title, 'TEST Prohibition of manufacture')
        self.assertEqual(liquor.subsections.get().subsection_title, 'TEST Manufacture liquor')

    def test_folder_of_files_shares_acts_by_name(self):
        with tempfile.TemporaryDirectory() as d:
            _xlsx(d, 'a.xlsx', [HEADER, ['TEST Theft', 'TEST Act', 303, 2, None]])
            _xlsx(d, 'b.xlsx', [['Section Title', 'Act Name', 'Section No', 'Subsection'],
                                ['TEST Robbery', 'test act', '309', '4'],
                                ['TEST Theft', 'TEST ACT', 303.0, '2']])
            _run(d)
        self.assertEqual(Act.objects.filter(act_name__iexact='test act').count(), 1)
        self.assertEqual(ActSection.objects.count(), 2)
        self.assertEqual(ActSubsection.objects.count(), 2)

    def test_fills_only_empty_values_of_existing_rows(self):
        act = Act.objects.create(act_name=BNS)
        ActSection.objects.create(act=act, section_number='101', section_title='TEST old title')
        _run(SAMPLE, ALIASES)
        sec = ActSection.objects.get(act=act, section_number='101')
        self.assertEqual((sec.section_title, sec.ipc_section), ('TEST old title', '300'))

    def test_every_file_in_the_data_folder_imports(self):
        out = _run(DATA)
        self.assertIn('Added 5 act(s)', out)
        names = set(Act.objects.values_list('act_name', flat=True))
        self.assertEqual(names, {BNS, 'THE MOTOR VEHICLES ACT, 1988', 'THE MAHARASHTRA POLICE ACT, 1951',
                                 'THE MAHARASHTRA PROHIBITION ACT, 1949',
                                 'THE MAHARASHTRA PREVENTION OF GAMBLING ACT, 1887'})
        gambling = ActSection.objects.get(act__act_name__startswith='THE MAHARASHTRA PREVENTION',
                                          section_number='4')
        self.assertEqual(sorted(gambling.subsections.values_list('subsection_code', flat=True)),
                         ['1(a)', '1(b)', '1(c)', '1(d)'])
        self.assertIn('Added 0 act(s), 0 section(s), 0 subsection(s)', _run(DATA))

    def test_dry_run_writes_nothing(self):
        out = _run(SAMPLE, '--dry-run')
        self.assertIn('[dry run] would add 1 act(s)', out)
        self.assertFalse(Act.objects.exists())

    def test_bad_rows_stop_the_whole_import(self):
        with tempfile.TemporaryDirectory() as d:
            _xlsx(d, 'bad.xlsx', [HEADER,
                                  ['TEST ok', 'TEST Act', '1', '', ''],
                                  ['TEST no section', 'TEST Act', '', '', ''],
                                  ['TEST too long', 'TEST Act', '12345678901', '', '']])
            with self.assertRaises(CommandError):
                _run(d)
        self.assertFalse(Act.objects.exists())
