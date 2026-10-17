import 'dart:convert';
import 'package:csv/csv.dart';

import 'excel_export_stub.dart'
    if (dart.library.js_interop) 'excel_export_web.dart';

class ExcelExportHelper {
  /// Cleans and formats section/act field into a human-readable string.
  /// Handles:
  /// - Plain strings: "302 IPC" -> "302 IPC"
  /// - Python serialized representations: "[{'act': None, ...}]" -> ""
  /// - Lists of maps: [{'act_name': 'BNS', 'section_number': '103'}] -> "BNS 103"
  /// - Maps: {'act': 'IPC', 'section': '302'} -> "IPC 302"
  static String formatSectionAct(dynamic raw) {
    if (raw == null) return '';

    if (raw is List) {
      final items = <String>[];
      for (final item in raw) {
        final f = formatSectionAct(item);
        if (f.isNotEmpty && !items.contains(f)) {
          items.add(f);
        }
      }
      return items.join(', ');
    }

    if (raw is Map) {
      if (raw['otherSections'] != null &&
          raw['otherSections'].toString().trim().isNotEmpty) {
        return raw['otherSections'].toString().trim();
      }

      var act = (raw['act_name'] ?? raw['act'] ?? '').toString().trim();
      if (act == 'null' || act == 'None' || RegExp(r'^\d+$').hasMatch(act)) {
        act = '';
      }

      final actLower = act.toLowerCase();
      if (actLower.contains('bharatiya nyaya') || actLower == 'bns') {
        act = 'BNS';
      } else if (actLower.contains('indian penal') || actLower == 'ipc') {
        act = 'IPC';
      } else if (actLower.contains('nagarik suraksha') ||
          actLower.contains('nagrik suraksha') ||
          actLower == 'bnss') {
        act = 'BNSS';
      } else if (actLower.contains('sakshya') || actLower == 'bsa') {
        act = 'BSA';
      } else if (actLower.contains('protection of children') ||
          actLower == 'pocso') {
        act = 'POCSO';
      }

      var sec = (raw['subsection_code'] ??
              raw['section_number'] ??
              raw['section'] ??
              raw['section_title'] ??
              '')
          .toString()
          .trim();
      if (sec == 'null' || sec == 'None') {
        sec = '';
      }

      final parts = <String>[];
      if (act.isNotEmpty) parts.add(act);
      if (sec.isNotEmpty) {
        if (!sec.toLowerCase().startsWith('sec') && parts.isEmpty) {
          parts.add('Sec. $sec');
        } else {
          parts.add(sec);
        }
      }

      if (parts.isNotEmpty) {
        return parts.join(' ');
      }

      for (final k in ['section', 'act', 'sections']) {
        if (raw[k] != null && raw[k] is! num && raw[k] != raw) {
          final res = formatSectionAct(raw[k]);
          if (res.isNotEmpty) return res;
        }
      }

      return '';
    }

    final str = raw.toString().trim();
    if (str.isEmpty ||
        str == 'null' ||
        str == 'None' ||
        str == '[]' ||
        str == '{}') {
      return '';
    }

    // Check if string is a JSON or Python list/dict representation
    if ((str.startsWith('[') && str.endsWith(']')) ||
        (str.startsWith('{') && str.endsWith('}'))) {
      try {
        final jsonStr = str
            .replaceAll("'", '"')
            .replaceAll(RegExp(r'\bNone\b'), 'null')
            .replaceAll(RegExp(r'\bTrue\b'), 'true')
            .replaceAll(RegExp(r'\bFalse\b'), 'false');
        final parsed = jsonDecode(jsonStr);
        return formatSectionAct(parsed);
      } catch (_) {
        final cleaned = str.replaceAll(RegExp(r'''[\"'\s,:(){}\[\]]'''), '');
        final nonNullWords = cleaned
            .replaceAll('None', '')
            .replaceAll('null', '')
            .replaceAll('act_id', '')
            .replaceAll('act', '')
            .replaceAll('act_name', '')
            .replaceAll('section_id', '')
            .replaceAll('section', '')
            .replaceAll('section_number', '')
            .replaceAll('section_title', '')
            .replaceAll('subsection_id', '')
            .replaceAll('subsection', '')
            .replaceAll('subsection_code', '');
        if (nonNullWords.isEmpty) {
          return '';
        }
      }
    }

    return str;
  }

  static String formatAccused(dynamic raw) {
    if (raw == null) return '';
    if (raw is List) {
      final names = <String>[];
      for (final item in raw) {
        final f = formatAccused(item);
        if (f.isNotEmpty && !names.contains(f)) names.add(f);
      }
      return names.join(', ');
    }
    if (raw is Map) {
      final name = (raw['name'] ?? raw['accused_name'] ?? raw['fullName'] ?? '')
          .toString()
          .trim();
      return (name == 'null' || name == 'None') ? '' : name;
    }
    final s = raw.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'None' || s == '[]' || s == '{}') {
      return '';
    }
    if ((s.startsWith('[') && s.endsWith(']')) ||
        (s.startsWith('{') && s.endsWith('}'))) {
      try {
        final jsonStr = s
            .replaceAll("'", '"')
            .replaceAll(RegExp(r'\bNone\b'), 'null')
            .replaceAll(RegExp(r'\bTrue\b'), 'true')
            .replaceAll(RegExp(r'\bFalse\b'), 'false');
        final parsed = jsonDecode(jsonStr);
        return formatAccused(parsed);
      } catch (_) {}
    }
    return s;
  }

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
      final cr = (r['cr'] ?? r['cr_no'] ?? r['case_number'] ?? r['crNo'] ?? '')
          .toString()
          .trim();
      final extra = r['extra_fields'] is Map ? r['extra_fields'] as Map : {};

      final sectionActRaw = r['section_act'] ??
          r['acts_sections'] ??
          r['sections'] ??
          r['section'] ??
          r['act_section'] ??
          r['sectionAct'] ??
          extra['section_act'] ??
          extra['acts_sections'] ??
          extra['sections'] ??
          extra['section'] ??
          extra['act_section'] ??
          extra['sectionAct'];
      final sectionAct = formatSectionAct(sectionActRaw);

      final accusedRaw = r['accused_name'] ??
          r['accused'] ??
          extra['accused_name'] ??
          extra['accused'];
      final accused = formatAccused(accusedRaw);

      final rawStatus =
          (r['nafis_status'] ?? r['status'] ?? '').toString().trim();
      final isPending = rawStatus.toLowerCase() == 'pending' ||
          rawStatus.toLowerCase() == 'no' ||
          rawStatus.isEmpty;
      final status = isPending ? 'Pending' : 'Done';
      final action = isPending ? 'Remind to IO' : '-';

      rows.add([
        i + 1,
        cr.isEmpty ? '-' : cr,
        sectionAct.isEmpty ? '-' : sectionAct,
        accused.isEmpty ? '-' : accused,
        status,
        action,
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    // Add UTF-8 BOM so Excel opens Hindi, Marathi, and special symbols correctly
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];

    platformDownloadBytes(bytes, filename, 'text/csv;charset=utf-8');
  }

  /// Generic export of tabular data to CSV with UTF-8 BOM.
  static void exportTableToCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
    String filename = 'export.csv',
  }) {
    final List<List<dynamic>> allRows = [headers, ...rows];
    final csvContent = const ListToCsvConverter().convert(allRows);
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];
    platformDownloadBytes(bytes, filename, 'text/csv;charset=utf-8');
  }
}
