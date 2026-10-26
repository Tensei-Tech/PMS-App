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
  /// Sr. No., Accused Name, CR No., Section/Act, Head, IO Name, Status, Action
  static void exportNafisToExcel({
    required List<Map<String, dynamic>> dataset,
    String filename = 'NAFIS_Cases.csv',
  }) {
    final List<List<dynamic>> rows = [
      [
        'Sr. No.',
        'Accused Name',
        'CR No.',
        'Section/Act',
        'Head',
        'IO Name',
        'Status',
        'Action'
      ]
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

      final headRaw = r['head'] ??
          r['sub_category'] ??
          r['subCategory'] ??
          r['title'] ??
          extra['head'] ??
          extra['crime_head'] ??
          '-';
      final head =
          headRaw.toString().trim().isEmpty ? '-' : headRaw.toString().trim();

      final ioName = (r['io_name'] ??
              r['assigned_officer'] ??
              r['io'] ??
              extra['io_name'] ??
              extra['assigned_officer'] ??
              'Unassigned')
          .toString()
          .trim();

      final rawStatus =
          (r['nafis_status'] ?? r['status'] ?? '').toString().trim();
      final isPending = rawStatus.toLowerCase() == 'pending' ||
          rawStatus.toLowerCase() == 'no' ||
          rawStatus.isEmpty;
      final status = isPending ? 'Pending' : 'Done';
      final action = isPending ? 'Remind to IO' : '-';

      rows.add([
        i + 1,
        accused.isEmpty ? '-' : accused,
        cr.isEmpty ? '-' : cr,
        sectionAct.isEmpty ? '-' : sectionAct,
        head,
        ioName.isEmpty ? 'Unassigned' : ioName,
        status,
        action,
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    // Add UTF-8 BOM so Excel opens Hindi, Marathi, and special symbols correctly
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];

    platformDownloadBytes(bytes, filename, 'text/csv;charset=utf-8');
  }

  /// Exports Detected cases to CSV/Excel format with requested columns:
  /// Sr. No., Cr. No., SEC/ACT, Head, Accused Name, IO Name
  /// Example: 1, 233, BNS, Murder, MH, DGP
  static void exportDetectedToExcel({
    required List<Map<String, String>> dataset,
    String filename = 'Detected_Cases.csv',
  }) {
    final List<List<dynamic>> rows = [
      ['Sr. No.', 'Cr. No.', 'SEC/ACT', 'Head', 'Accused Name', 'IO Name']
    ];

    for (var i = 0; i < dataset.length; i++) {
      final r = dataset[i];
      final sr = r['sr']?.isNotEmpty == true ? r['sr']! : '${i + 1}';
      final cr = r['cr']?.trim().isNotEmpty == true ? r['cr']!.trim() : '-';
      final secAct =
          r['sections']?.trim().isNotEmpty == true ? r['sections']!.trim() : '-';
      final head =
          r['head']?.trim().isNotEmpty == true ? r['head']!.trim() : '-';
      final accused =
          r['accused']?.trim().isNotEmpty == true ? r['accused']!.trim() : '-';
      final io = r['io']?.trim().isNotEmpty == true ? r['io']!.trim() : '-';

      rows.add([
        sr,
        cr,
        secAct,
        head,
        accused,
        io,
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    // Add UTF-8 BOM so Excel opens Hindi, Marathi, and special symbols correctly
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];

    platformDownloadBytes(bytes, filename, 'text/csv;charset=utf-8');
  }

  /// Exports Arrested cases to CSV/Excel format with requested columns:
  /// Sr. No., Cr. No., SEC & ACT, Head, Accused Name, Date of Arrest, IO Name
  static void exportArrestedToExcel({
    required List<Map<String, String>> dataset,
    String filename = 'Arrested_Cases.csv',
  }) {
    final List<List<dynamic>> rows = [
      [
        'Sr. No.',
        'Cr. No.',
        'SEC & ACT',
        'Head',
        'Accused Name',
        'Date of Arrest',
        'IO Name'
      ]
    ];

    for (var i = 0; i < dataset.length; i++) {
      final r = dataset[i];
      final sr = r['sr']?.isNotEmpty == true ? r['sr']! : '${i + 1}';
      final cr = r['cr']?.trim().isNotEmpty == true ? r['cr']!.trim() : '-';
      final secAct =
          r['sections']?.trim().isNotEmpty == true ? r['sections']!.trim() : '-';
      final head =
          r['head']?.trim().isNotEmpty == true ? r['head']!.trim() : '-';
      final accused =
          (r['accused_name'] ?? r['accused'])?.trim().isNotEmpty == true
              ? (r['accused_name'] ?? r['accused'])!.trim()
              : '-';
      final arrDate =
          (r['arrest_date'] ?? r['date'])?.trim().isNotEmpty == true
              ? (r['arrest_date'] ?? r['date'])!.trim()
              : '-';
      final io = r['io']?.trim().isNotEmpty == true ? r['io']!.trim() : '-';

      rows.add([
        sr,
        cr,
        secAct,
        head,
        accused,
        arrDate,
        io,
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    // Add UTF-8 BOM so Excel opens Hindi, Marathi, and special symbols correctly
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];

    platformDownloadBytes(bytes, filename, 'text/csv;charset=utf-8');
  }

  /// Extracts Court / Final Summary / AD / Preventive Action numbers for Disposal:
  /// Formatted as "A Final :- 25", "CC No :- 76", showing only the entered ones.
  static String extractDisposalNumbers(Map<String, dynamic> r,
      {bool multiLine = false}) {
    final results = <String>[];
    final seenValues = <String>{};

    final extra = r['extra_fields'] is Map
        ? Map<String, dynamic>.from(r['extra_fields'] as Map)
        : <String, dynamic>{};

    final allMaps = <Map<String, dynamic>>[
      extra,
      if (extra['court'] is Map)
        Map<String, dynamic>.from(extra['court'] as Map),
      if (extra['finalForm'] is Map)
        Map<String, dynamic>.from(extra['finalForm'] as Map),
      if (extra['istegasha'] is Map)
        Map<String, dynamic>.from(extra['istegasha'] as Map),
      if (extra['preventiveForm'] is Map)
        Map<String, dynamic>.from(extra['preventiveForm'] as Map),
      r,
    ];

    String? findValue(List<String> keys) {
      for (final m in allMaps) {
        for (final k in keys) {
          if (m.containsKey(k)) {
            final val = m[k]?.toString().trim() ?? '';
            if (val.isNotEmpty &&
                val.toLowerCase() != 'null' &&
                val.toLowerCase() != 'none' &&
                val.toLowerCase() != 'n/a' &&
                val != '—' &&
                val != '-') {
              return val;
            }
          }
        }
      }
      return null;
    }

    void addResult(String label, String? val) {
      if (val == null) return;
      var cleaned = val.trim();
      if (cleaned.isEmpty ||
          cleaned.toLowerCase() == 'null' ||
          cleaned.toLowerCase() == 'none' ||
          cleaned.toLowerCase() == 'n/a' ||
          cleaned == '—' ||
          cleaned == '-') {
        return;
      }

      if (cleaned.toLowerCase().startsWith(label.toLowerCase())) {
        cleaned = cleaned
            .substring(label.length)
            .replaceFirst(RegExp(r'^[\s:-]+'), '');
      }

      final entry = '$label :- $cleaned';

      if (!seenValues.contains(cleaned) && !results.contains(entry)) {
        seenValues.add(cleaned);
        results.add(entry);
      }
    }

    // 1. Specific CC Number
    final ccVal = findValue(['cc_number', 'ccNumber', 'cc_no']);
    if (ccVal != null) addResult('CC No', ccVal);

    // 2. Specific ST Number
    final stVal = findValue(['st_number', 'stNumber', 'st_no', 'stNo']);
    if (stVal != null) addResult('ST No', stVal);

    // 3. Combined CC/ST Number (only if neither CC nor ST was found)
    if (ccVal == null && stVal == null) {
      final ccStVal = findValue([
        'ccStNumber',
        'cc_st_number',
        'cc_st_no',
        'ccStNo',
        'disposedCcStNumber',
      ]);
      if (ccStVal != null) {
        addResult('CC/ST No', ccStVal);
      } else if (r['cc_st_no'] != null &&
          r['cc_st_no'].toString().trim().isNotEmpty) {
        addResult('CC/ST No', r['cc_st_no'].toString().trim());
      }
    }

    // 4. A Final
    addResult(
        'A Final',
        findValue([
          'aFinalNo',
          'a_final_number',
          'a_final_no',
          'aFinalNumber',
        ]));

    // 5. B Final
    addResult(
        'B Final',
        findValue([
          'bFinalNo',
          'b_final_number',
          'b_final_no',
          'bFinalNumber',
        ]));

    // 6. C Final
    addResult(
        'C Final',
        findValue([
          'cFinalNo',
          'c_final_number',
          'c_final_no',
          'cFinalNumber',
        ]));

    // 7. NC Final
    addResult(
        'NC Final',
        findValue([
          'ncFinalNo',
          'nc_final_number',
          'nc_final_no',
          'ncFinalNumber',
        ]));

    // 8. Abated Summary
    addResult(
        'Abated Summary',
        findValue([
          'abatedSummaryNo',
          'abeted_summary_no',
          'abated_summary_no',
          'abetedSummaryNo',
          'abeted_summary_number',
        ]));

    // 9. AD No / AD Summary No
    addResult(
        'AD No',
        findValue([
          'ad_summary_sent',
          'adSummarySent',
          'ad_summary_sent_no',
          'adSummarySentNo',
          'adSummaryNo',
          'ad_summary_no',
          'adSummaryNum',
          'ad_summary_num',
          'adSummaryNumber',
          'ad_summary_number',
          'ad_no',
          'ad_number',
          'adNumber',
          'adNo',
          'summaryNo',
          'summary_no',
          'margSummaryNo',
          'marg_summary_no',
          'मर्ग समरी No.',
          'मर्ग समरी No',
          'मर्ग समरी नं.',
          'मर्ग समरी नं',
          'मर्ग समरी क्रमांक',
          'मर्ग समरी क्र.',
          'मर्ग समरी क्र',
          'मर्ग समरी',
          'मर्ग समरी पाठविली क्र.',
          'मर्ग समरी पाठविली क्र',
          'मर्ग समरी पाठविली नं.',
          'मर्ग समरी पाठविली नं',
          'मर्ग समरी पाठविली',
          'मर्ग समरी पाठविल्याचा क्र.',
          'मर्ग समरी पाठविल्याचा क्र',
          'मर्ग समरी पाठविल्याचा क्रमांक',
          'AD Summary No.',
          'AD Summary No',
          'AD Summary Number',
          'AD Summary',
        ]));

    // 10. Preventive Action No
    addResult(
        'Preventive No',
        findValue([
          'preventiveNumber',
          'preventive_number',
          'preventiveNo',
          'preventive_no',
          'istegasha_no',
          'istegashaNo',
          'istegasha_number',
          'istegashaNumber',
          'istegasha',
          'preventiveActionNo',
          'preventive_action_no',
          'chapter_case_no',
          'chapterCaseNo',
          'इस्तेगाशा नंबर',
          'इस्तेगाशा नं.',
          'इस्तेगाशा नं',
          'इस्तेगाशा क्र.',
          'इस्तेगाशा क्र',
          'इस्तेगाशा क्रमांक',
          'प्रतिबंधक कारवाई क्र.',
          'प्रतिबंधक कारवाई क्र',
          'प्रतिबंधक क्र.',
          'प्रतिबंधक क्र',
          'प्रतिबंधक क्रमांक',
        ]));

    final outwardVal = findValue([
      'outwardNumber',
      'outward_number',
      'outwardNo',
      'outward_no',
      'preventiveOutwardNumber',
      'preventive_outward_no',
      'preventiveOutwardNo',
      'जावक क्र.',
      'जावक क्र',
      'जावक क्रमांक',
      'जावक नंबर',
    ]);
    if (outwardVal != null && outwardVal.isNotEmpty) {
      addResult('Outward No', outwardVal);
    }

    // 11. No Preventive Reason (Family matter / Other)
    final noPrevReason = findValue([
      'noPreventiveReason',
      'no_preventive_reason',
      'preventiveNotDoneReason',
      'preventive_not_done_reason',
      'reason_for_no_preventive',
      'preventive_reason',
    ]);
    if (noPrevReason != null && noPrevReason.isNotEmpty) {
      final otherDetail =
          findValue(['noPreventiveOtherDetails', 'other_reason_details']);
      final fullReason = (noPrevReason.toLowerCase() == 'other' &&
              otherDetail != null &&
              otherDetail.isNotEmpty)
          ? 'Other ($otherDetail)'
          : noPrevReason;
      addResult('No Preventive', fullReason);
    }

    // 12. Backend disposal_type / disposal_no fallback
    if (results.isEmpty &&
        r['disposal_no'] != null &&
        r['disposal_no'].toString().trim().isNotEmpty &&
        r['disposal_no'].toString().toLowerCase() != 'n/a') {
      final dispType = (r['disposal_type'] ?? '').toString().trim();
      final dispNo = r['disposal_no'].toString().trim();
      if (dispType.isNotEmpty && dispType.toLowerCase() != 'n/a') {
        results.add('$dispType :- $dispNo');
      } else {
        results.add(dispNo);
      }
    }

    if (results.isEmpty) return '—';
    return multiLine ? results.join('\n') : results.join('    ');
  }

  /// Exports Disposal cases to CSV/Excel format with requested columns:
  /// Sr. No., Cr. No., Sec & Act, Head, CC.No/ST.No./A/B/C/NC Final/Abated Summary/AD No./Preventive Action No., IO Name
  static void exportDisposalToExcel({
    required List<Map<String, dynamic>> dataset,
    String filename = 'Disposal_Cases.csv',
  }) {
    final List<List<dynamic>> rows = [
      [
        'Sr. No.',
        'Cr. No.',
        'Sec & Act',
        'Head',
        'Case Summary',
        'IO Name',
      ]
    ];

    for (var i = 0; i < dataset.length; i++) {
      final r = dataset[i];
      final sr = (r['sr_no'] ?? '${i + 1}').toString();
      final cr = (r['case_number'] ?? r['cr_no'] ?? r['cr'] ?? '-')
          .toString()
          .trim();

      final extra = r['extra_fields'] is Map
          ? Map<String, dynamic>.from(r['extra_fields'] as Map)
          : <String, dynamic>{};

      final secActRaw = r['section_act'] ??
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
      var secAct = formatSectionAct(secActRaw);
      if (secAct.isEmpty) {
        final act = (r['act'] ?? extra['act'] ?? '').toString().trim();
        final sec = (r['section'] ?? extra['section'] ?? '').toString().trim();
        if (sec.isNotEmpty || act.isNotEmpty) {
          secAct = '$sec $act'.trim();
        }
      }
      if (secAct.isEmpty || secAct == '—') {
        secAct = '-';
      }

      final head = (r['crime_type_name'] ??
              r['head'] ??
              r['crime_type'] ??
              r['sub_category'] ??
              '-')
          .toString()
          .trim();

      final disposalCourtNumbers = extractDisposalNumbers(r);

      final io = (r['assigned_officer'] ?? r['io_name'] ?? r['io'] ?? '-')
          .toString()
          .trim();

      rows.add([
        sr,
        cr.isEmpty || cr == '—' ? '-' : cr,
        secAct,
        head.isEmpty || head == '—' ? '-' : head,
        disposalCourtNumbers,
        io.isEmpty || io == '—' ? '-' : io,
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
