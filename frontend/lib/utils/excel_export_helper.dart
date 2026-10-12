import 'dart:convert';
import 'package:csv/csv.dart';

import 'excel_export_stub.dart'
    if (dart.library.js_interop) 'excel_export_web.dart';

class ExcelExportHelper {
  /// Exports NAFIS cases to CSV/Excel format with requested columns:
  /// Sr. No., CR No., Section/Act, Accused Name, Status, Action
  static void exportNafisToExcel({
    required List<Map<String, dynamic>> dataset,
    String filename = 'NAFIS_Cases.csv',
  }) {
    final List<List<dynamic>> rows = [
      ['Sr. No.', 'CR No.', 'Section/Act', 'Accused Name', 'Status', 'Action']
    ];

    for (var i = 0; i < dataset.length; i++) {
      final r = dataset[i];
      final cr = (r['cr'] ?? r['cr_no'] ?? r['case_number'] ?? r['crNo'] ?? '').toString();
      final sectionAct = (r['section_act'] ??
              r['sections'] ??
              r['section'] ??
              r['act_section'] ??
              r['acts_sections'] ??
              '')
          .toString();

      final extra = r['extra_fields'] is Map ? r['extra_fields'] as Map : {};
      final accused = (r['accused_name'] ??
              r['accused'] ??
              extra['accused_name'] ??
              extra['accused'] ??
              '')
          .toString();

      final rawStatus = (r['nafis_status'] ?? r['status'] ?? '').toString().trim();
      final isPending = rawStatus.toLowerCase() == 'pending' ||
          rawStatus.toLowerCase() == 'no' ||
          rawStatus.isEmpty;
      final status = isPending ? 'Pending' : 'Chargesheeted';
      final action = isPending ? 'Remind to IO' : '-';

      rows.add([
        i + 1,
        cr,
        sectionAct,
        accused,
        status,
        action,
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    // Add UTF-8 BOM so Excel opens Hindi, Marathi, and special symbols correctly
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];

    platformDownloadBytes(bytes, filename, 'text/csv;charset=utf-8');
  }
}
