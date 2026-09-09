// lib/utils/common_form_module.dart
// Routing + storage key for the shared crime registration form (CommonForm).

/// Firestore / [ModuleRecord.extraFields] key for the full common form payload.
const String kCommonFormExtraFieldsKey = 'commonForm';

const Set<String> _kModulesWithoutCommonForm = {
  'pending',
  'monthly',
  'disposal',
  'detected',
  'undetected',
  'ad',
  'nc',
  'missing',
};

/// Dashboard / hub modules that use [CommonForm] instead of [ModuleFormScreen].
bool moduleUsesCommonCrimeForm(String moduleKey) =>
    !_kModulesWithoutCommonForm.contains(moduleKey);

/// Checks if a Form I-V (or CommonForm) case is "unarrested":
/// Checks the Arrest & Release Status section (§9) — if Arrest Date/Time is empty/null,
/// that case is unarrested and belongs in the Absconded section.
bool isCaseUnarrested(dynamic record) {
  if (record == null) return true;
  final extraFields = record.extraFields;
  if (extraFields is! Map) return true;
  final cf = extraFields[kCommonFormExtraFieldsKey];
  if (cf is Map) {
    final ar = cf['arrestRelease'];
    if (ar is List && ar.isNotEmpty) {
      final hasArrestDate = ar.any((row) {
        if (row is Map) {
          final dt = row['arrestDt']?.toString().trim();
          return dt != null && dt.isNotEmpty;
        }
        return false;
      });
      return !hasArrestDate;
    }
    return true;
  }
  return true;
}

/// Checks if an Absconded case is Disposed:
/// If date is mentioned (in arrest date, release date, or disposal/court),
/// or if status is Disposed/Closed/Resolved, it belongs in the Disposal tab.
/// Otherwise (no date mentioned), it belongs in the Pending tab.
bool isAbscondedDisposal(dynamic record) {
  if (record == null) return false;
  final status = (record.status ?? '').toString().toLowerCase().trim();
  if (status == 'disposal' || status == 'closed' || status == 'resolved') {
    return true;
  }
  final extraFields = record.extraFields;
  if (extraFields is Map) {
    final cf = extraFields[kCommonFormExtraFieldsKey];
    if (cf is Map) {
      final ar = cf['arrestRelease'];
      if (ar is List && ar.isNotEmpty) {
        final hasDate = ar.any((row) {
          if (row is Map) {
            final arrestDt = row['arrestDt']?.toString().trim() ?? '';
            final releaseDt = row['releaseDt']?.toString().trim() ?? '';
            return arrestDt.isNotEmpty || releaseDt.isNotEmpty;
          }
          return false;
        });
        if (hasDate) return true;
      }
      final court = cf['court'];
      if (court is Map) {
        final quash = court['quashedHighCourt']?.toString().trim() ?? '';
        if (quash.isNotEmpty) return true;
      }
      final prev = cf['preventive'];
      if (prev is Map) {
        final bondDate = prev['bondDate']?.toString().trim() ?? '';
        final bondCancel = prev['bondCancellation']?.toString().trim() ?? '';
        if (bondDate.isNotEmpty || bondCancel.isNotEmpty) return true;
      }
    }
  }
  return false;
}
