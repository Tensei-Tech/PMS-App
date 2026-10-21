// lib/utils/ad_disposal_helper.dart
// Unified disposal identification logic for AD (Accidental Death) and all module cases.

import 'common_form_module.dart' show isAbscondedDisposal;
import '../constants/case_status_constants.dart';

/// A.D. cases get their Disposal status from the backend (CaseRecord.save,
/// rule from module_settings 'ad'); the app only reads that saved status.

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

/// Unified helper to determine if ANY case record is Disposed.
/// Covers:
/// 1. Status == CaseStatus.disposal / 'Disposed' / 'Closed' / 'Resolved'
/// 2. Absconded disposal rules via [isAbscondedDisposal]
/// (A.D. cases are covered by 1: the backend saves their Disposal status)
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
  final disposalStatuses = {
    CaseStatus.disposal.toLowerCase(),
    CaseStatus.closed.toLowerCase(),
    CaseStatus.disposed.toLowerCase(),
    CaseStatus.resolved.toLowerCase(),
  };
  if (disposalStatuses.contains(s)) {
    return true;
  }
  if (isAbscondedDisposal(record)) {
    return true;
  }
  return false;
}

/// Unified helper to determine if ANY case record is Pending.
bool isRecordPending(dynamic record) {
  return !isRecordDisposal(record);
}
