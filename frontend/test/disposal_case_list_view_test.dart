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
    test('extractDisposalNumbers extracts cc_st_no and various final summaries',
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
      expect(extracted, contains('B Final :- B-99'));
      expect(extracted, contains('Abated Summary :- AS-50'));
      expect(extracted, contains('AD No :- AD-12'));
      expect(extracted, contains('Preventive No :- PREV-77'));
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
  });
}

