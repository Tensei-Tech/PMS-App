// lib/utils/ad_disposal_helper.dart
// Unified disposal identification logic for AD (Accidental Death) and all module cases.

import 'common_form_module.dart' show isAbscondedDisposal;

/// Candidate keys for "AD Summary No." / "मर्ग समरी No." across various form formats.
const List<String> kAdSummaryNoKeys = [
  'adSummaryNo',
  'ad_summary_no',
  'adSummaryNum',
  'ad_summary_num',
  'adSummaryNumber',
  'ad_summary_number',
  'adSummary',
  'ad_summary',
  'summaryNo',
  'summary_no',
  'summaryNum',
  'summary_num',
  'summaryNumber',
  'summary_number',
  'margSummaryNo',
  'marg_summary_no',
  'margSummaryNum',
  'marg_summary_num',
  'margSummaryNumber',
  'marg_summary_number',
  'margSummary',
  'marg_summary',
  'marSummaryNo',
  'mar_summary_no',
  'marSummaryNum',
  'mar_summary_num',
  'adMargSummaryNo',
  'ad_marg_summary_no',
  'मर्ग समरी No.',
  'मर्ग समरी No',
  'मर्ग समरी नं.',
  'मर्ग समरी नं',
  'मर्ग समरी क्रमांक',
  'मर्ग समरी क्र.',
  'मर्ग समरी क्र',
  'मर्ग समरी',
  'AD Summary No.',
  'AD Summary No',
  'AD Summary Number',
  'AD Summary',
];

/// Candidate keys for "AD Summary Date" / "मर्ग समरी दिनांक" across various form formats.
const List<String> kAdSummaryDateKeys = [
  'adSummaryDate',
  'ad_summary_date',
  'adSummaryDt',
  'ad_summary_dt',
  'summaryDate',
  'summary_date',
  'summaryDt',
  'summary_dt',
  'margSummaryDate',
  'marg_summary_date',
  'margSummaryDt',
  'marg_summary_dt',
  'marSummaryDate',
  'mar_summary_date',
  'adMargSummaryDate',
  'ad_marg_summary_date',
  'मर्ग समरी दिनांक',
  'मर्ग समरी तारीख',
  'मर्ग समरी Date',
  'मर्ग समरी Dt',
  'AD Summary Date',
  'AD Summary Dt',
];

/// Checks if a record or map represents an AD (Accidental Death) case.
bool isAdCase(dynamic recordOrMap) {
  if (recordOrMap == null) return false;
  if (recordOrMap is Map) {
    final mod = (recordOrMap['moduleKey'] ??
            recordOrMap['module_key'] ??
            recordOrMap['module'] ??
            recordOrMap['caseType'] ??
            recordOrMap['case_type'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    if (mod == 'ad') return true;
    final sub =
        (recordOrMap['subCategory'] ?? recordOrMap['sub_category'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    return sub == 'ad' || sub == 'accidental death';
  }
  // Try dynamic object properties (ModuleRecord, CaseRecord, etc.)
  try {
    final mod = (recordOrMap.moduleKey ?? '').toString().trim().toLowerCase();
    if (mod == 'ad') return true;
  } catch (_) {}
  try {
    final sub = (recordOrMap.subCategory ?? '').toString().trim().toLowerCase();
    if (sub == 'ad' || sub == 'accidental death') return true;
  } catch (_) {}
  return false;
}

/// Recursively searches for any key in [candidateKeys] within [data].
String _extractFirstNonEmptyString(dynamic data, List<String> candidateKeys) {
  if (data == null) return '';
  if (data is Map) {
    // 1. Direct match with candidate keys
    for (final key in candidateKeys) {
      if (data.containsKey(key)) {
        final val = data[key]?.toString().trim() ?? '';
        if (val.isNotEmpty) return val;
      }
    }

    // 2. Case-insensitive / normalized key search
    for (final entry in data.entries) {
      final k = entry.key.toString().trim();
      final kLower = k.toLowerCase().replaceAll(RegExp(r'[\s_.-]'), '');
      for (final cand in candidateKeys) {
        final candLower = cand.toLowerCase().replaceAll(RegExp(r'[\s_.-]'), '');
        if (kLower == candLower) {
          final val = entry.value?.toString().trim() ?? '';
          if (val.isNotEmpty) return val;
        }
      }
    }

    // 3. Search nested maps
    for (final entry in data.entries) {
      if (entry.value is Map) {
        final nestedVal =
            _extractFirstNonEmptyString(entry.value, candidateKeys);
        if (nestedVal.isNotEmpty) return nestedVal;
      }
    }
  }
  return '';
}

/// Extracts the AD Summary No. / मर्ग समरी No. from an AD record or map.
String extractAdSummaryNo(dynamic recordOrMap) {
  if (recordOrMap == null) return '';
  if (recordOrMap is Map) {
    final extra = recordOrMap['extraFields'] ?? recordOrMap['extra_fields'];
    final fromExtra = _extractFirstNonEmptyString(extra, kAdSummaryNoKeys);
    if (fromExtra.isNotEmpty) return fromExtra;
    return _extractFirstNonEmptyString(recordOrMap, kAdSummaryNoKeys);
  }
  try {
    final extra = recordOrMap.extraFields;
    final fromExtra = _extractFirstNonEmptyString(extra, kAdSummaryNoKeys);
    if (fromExtra.isNotEmpty) return fromExtra;
  } catch (_) {}
  return '';
}

/// Extracts the AD Summary Date / मर्ग समरी दिनांक from an AD record or map.
String extractAdSummaryDate(dynamic recordOrMap) {
  if (recordOrMap == null) return '';
  if (recordOrMap is Map) {
    final extra = recordOrMap['extraFields'] ?? recordOrMap['extra_fields'];
    final fromExtra = _extractFirstNonEmptyString(extra, kAdSummaryDateKeys);
    if (fromExtra.isNotEmpty) return fromExtra;
    return _extractFirstNonEmptyString(recordOrMap, kAdSummaryDateKeys);
  }
  try {
    final extra = recordOrMap.extraFields;
    final fromExtra = _extractFirstNonEmptyString(extra, kAdSummaryDateKeys);
    if (fromExtra.isNotEmpty) return fromExtra;
  } catch (_) {}
  return '';
}

/// Returns true if an AD (Accidental Death) case qualifies as Disposal.
/// Specifically: Both "AD Summary No." and "AD Summary Date" must be present and non-empty.
bool isAdDisposalCase(dynamic recordOrMap) {
  if (!isAdCase(recordOrMap)) return false;
  final summaryNo = extractAdSummaryNo(recordOrMap);
  final summaryDate = extractAdSummaryDate(recordOrMap);
  return summaryNo.isNotEmpty && summaryDate.isNotEmpty;
}

/// Unified helper to determine if ANY case record is Disposed.
/// Covers:
/// 1. Status == 'Disposal' / 'Disposed' / 'Closed' / 'Resolved'
/// 2. Absconded disposal rules via [isAbscondedDisposal]
/// 3. AD (Accidental Death) disposal rule: both AD Summary No. & AD Summary Date present
bool isRecordDisposal(dynamic record) {
  if (record == null) return false;
  String s = '';
  if (record is Map) {
    s = (record['status'] ?? '').toString().trim().toLowerCase();
  } else {
    try {
      s = (record.status ?? '').toString().trim().toLowerCase();
    } catch (_) {}
  }
  if (s == 'disposal' || s == 'disposed' || s == 'closed' || s == 'resolved') {
    return true;
  }
  if (isAbscondedDisposal(record)) {
    return true;
  }
  if (isAdDisposalCase(record)) {
    return true;
  }
  return false;
}

/// Unified helper to determine if ANY case record is Pending.
bool isRecordPending(dynamic record) {
  return !isRecordDisposal(record);
}
