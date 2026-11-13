import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/excel_export_helper.dart';

void main() {
  group('Pending Excel Export Tests', () {
    test(
        'exportPendingToExcel executes without error for standard pending cases',
        () {
      final sample = [
        {
          'sr': '1',
          'cr': 'CR/1793604345534',
          'sections': '302 IPC',
          'head': 'Tadipar',
          'io': 'DGP Maharashtra',
          'station': 'Maharashtra Police HQ',
        },
        {
          'sr': '2',
          'cr': 'CR/1793604345334',
          'sections': '—',
          'head': 'Tadipar',
          'io': 'DGP Maharashtra',
          'station': 'Maharashtra Police HQ',
        },
      ];

      expect(() => ExcelExportHelper.exportPendingToExcel(dataset: sample),
          returnsNormally);
    });

    test('exportPendingToExcel handles absconded and undetected flags', () {
      final sample = [
        {
          'sr': '1',
          'cr': 'CR/101',
          'sections': '302 IPC',
          'head': 'Murder',
          'accused': 'John Doe',
          'io': 'Officer A',
        }
      ];

      expect(
          () => ExcelExportHelper.exportPendingToExcel(
              dataset: sample, isAbsconded: true),
          returnsNormally);
      expect(
          () => ExcelExportHelper.exportPendingToExcel(
              dataset: sample, isUndetected: true),
          returnsNormally);
    });
  });
}
