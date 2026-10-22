import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/excel_export_helper.dart';

void main() {
  group('ExcelExportHelper formatSectionAct tests', () {
    test(
        'Cleans up Python stringified empty acts_sections dict from Excel export',
        () {
      const rawUserIssue =
          "[{'act': None, 'act_id': None, 'section': None, 'act_name': None, 'section_id': None, 'subsection': None, 'section_title': None, 'subsection_id': None, 'section_number': None, 'subsection_code': None}]";

      final result = ExcelExportHelper.formatSectionAct(rawUserIssue);
      expect(result, equals(''));
    });

    test('Parses and formats Python stringified valid acts_sections dict', () {
      const rawValidPythonStr =
          "[{'act_name': 'Indian Penal Code', 'section_number': '302'}]";

      final result = ExcelExportHelper.formatSectionAct(rawValidPythonStr);
      expect(result, equals('IPC 302'));
    });

    test('Formats Dart list of maps with BNS charges', () {
      final list = [
        {
          'act_name': 'Bharatiya Nyaya Sanhita, 2023',
          'section_number': '103',
          'subsection_code': '103(1)'
        }
      ];

      final result = ExcelExportHelper.formatSectionAct(list);
      expect(result, equals('BNS 103(1)'));
    });

    test('Formats Dart map with plain sections', () {
      final map = {'otherSections': 'IPC 302, 34'};
      final result = ExcelExportHelper.formatSectionAct(map);
      expect(result, equals('IPC 302, 34'));
    });

    test('Returns normal text as is', () {
      expect(ExcelExportHelper.formatSectionAct('302 IPC'), equals('302 IPC'));
      expect(ExcelExportHelper.formatSectionAct(''), equals(''));
      expect(ExcelExportHelper.formatSectionAct(null), equals(''));
    });

    test('formatAccused cleans nulls and stringified lists', () {
      expect(ExcelExportHelper.formatAccused(null), equals(''));
      expect(ExcelExportHelper.formatAccused('None'), equals(''));
      expect(ExcelExportHelper.formatAccused('John Doe'), equals('John Doe'));
      expect(
        ExcelExportHelper.formatAccused([
          {'name': 'Ramesh'},
          {'name': 'Suresh'}
        ]),
        equals('Ramesh, Suresh'),
      );
    });
  });
}
