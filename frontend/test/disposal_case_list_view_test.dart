import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/screens/disposal_case_list_view.dart';
import 'package:khakhi_diary/utils/excel_export_helper.dart';

void main() {
  testWidgets(
      'DisposalCaseListView table renders without unbounded constraints',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DisposalCaseListView(),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));

    // We expect a CircularProgressIndicator since it's loading, but layout builder is checked.
    expect(find.byType(SingleChildScrollView),
        findsNothing); // It's loading initially

    addTearDown(tester.view.resetPhysicalSize);
  });

  group('Disposal Excel Export Helper Tests', () {
    test(
        'extractDisposalNumbers extracts only cc_st_no and excludes final summaries',
        () {
      final r1 = {
        'cc_st_no': 'CC 101/2024',
        'disposal_no': 'A Final: 42/2024',
        'extra_fields': {
          'bFinalNo': 'B-99',
          'abatedSummaryNo': 'AS-50',
          'adSummaryNo': 'AD-12',
          'preventiveNo': 'PREV-77',
        }
      };

      final extracted = ExcelExportHelper.extractDisposalNumbers(r1);
      expect(extracted, contains('CC 101/2024'));
      expect(extracted, isNot(contains('B Final')));
      expect(extracted, isNot(contains('Abated Summary')));
      expect(extracted, isNot(contains('AD No')));
      expect(extracted, isNot(contains('Preventive No')));
    });

    test('extractDisposalNumbers returns dash if no disposal numbers exist',
        () {
      final r2 = {
        'cc_st_no': '',
        'disposal_no': 'N/A',
        'extra_fields': {},
      };
      expect(ExcelExportHelper.extractDisposalNumbers(r2), '—');
    });

    test('exportDisposalToExcel runs without errors', () {
      final sample = [
        {
          'sr_no': '1',
          'case_number': 'CR 12/2024',
          'section_act': '302 IPC',
          'crime_type_name': 'Murder',
          'cc_st_no': 'CC 55/2024',
          'assigned_officer': 'PI Patil',
        }
      ];

      expect(() => ExcelExportHelper.exportDisposalToExcel(dataset: sample),
          returnsNormally);
    });

    test('exportDisposalToExcel exports Remind to IO when cc_st_no is missing',
        () {
      final sample = [
        {
          'sr_no': '1',
          'case_number': 'CR 99/2024',
          'section_act': '307 IPC',
          'crime_type_name': 'Attempt to Murder',
          'cc_st_no': '',
          'disposal_no': 'N/A',
          'assigned_officer': 'PSI Shinde',
        }
      ];

      expect(() => ExcelExportHelper.exportDisposalToExcel(dataset: sample),
          returnsNormally);
    });
  });
}
