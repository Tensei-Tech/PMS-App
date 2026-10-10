// lib/utils/common_form_module.dart
// Routing + storage key for the shared crime registration form (CommonForm).

import '../constants/case_status_constants.dart';

/// Firestore / [ModuleRecord.extraFields] key for the full common form payload.
const String kCommonFormExtraFieldsKey = 'commonForm';

/// Modules linked to "Common Form Baseline Template" in category_field_templates.
/// A tab opens the Common Form ONLY if it is in this verified set.
const Set<String> _kCommonFormBaselineModules = {
  'form_1_5',
  'form_6',
  'forms',
  'murder',
  'attempt_to_murder',
  'dacoity',
  'robbery',
  'hbt',
  'theft',
  'sand_theft',
  'two_four_wheeler',
  'two_wheeler',
  'four_wheeler',
  'hurt',
  'kidnapping',
  'crime_against_women',
  'crime_women',
  'accident',
  'normal_accident',
  'death_due_to_rash_driving',
  'other_road_accident',
  'sec_156_175',
  'bnss_sec',
  'coin',
  'st_drugs',
  'prohibition',
  'gambling',
  'pocso',
  'ndps',
  'gowansh',
  'gowans',
  'it_act',
  'mv_act',
  'm_v_act',
  'uapa',
  'absconded',
  'arrested',
  'juvenile',
  'victim',
  'traffic',
  'sam_warrant',
  'muddemal',
  'bnss',
};

/// Standalone category display names linked to "Common Form Baseline Template"
/// in public.category_field_templates.
const Set<String> _kCommonFormBaselineCategoryNames = {
  'murder',
  'attempt to murder',
  'dacoity',
  'robbery',
  'hbt',
  'theft',
  'sand theft',
  'two/four wheeler theft',
  'two wheeler theft',
  'four wheeler theft',
  'two/four wheeler',
  'riot',
  'unlawful assembly',
  'kidnapping',
  'cbt',
  'cheating',
  'mischief',
  'hurt',
  'assault on public servant',
  'rape',
  'molestation',
  'extortion',
  'ipc (a) 304',
  '498 (a) ipc',
  'other ipc',
  'chain snatching',
  'crime against women',
  'accident',
  'normal accident',
  'death due to rash driving',
  'other road accident',
  'sec 156(3)/175(3)(bnss)',
  'sec 156(3)/175 (3)(bnss)',
  'coin',
  'st drugs',
  'prohibition',
  'gambling',
  'pocso',
  'ndps',
  'gowansh',
  'gowans',
  'it act',
  'm.v act',
  'mv act',
  'uapa',
};

/// Checks if a module/category is linked to "Common Form Baseline Template".
/// Returns false for unlinked tabs (such as RTI, or any new standalone tab).
bool isTabLinkedToCommonFormBaseline({
  required String moduleKey,
  String? categoryName,
}) {
  if (categoryName != null && categoryName.trim().isNotEmpty) {
    final cleanCat = categoryName.trim().toLowerCase().replaceAll('\n', ' ').trim();
    return _kCommonFormBaselineCategoryNames.contains(cleanCat);
  }
  final cleanKey = moduleKey.trim().toLowerCase().replaceAll('-', '_');
  return _kCommonFormBaselineModules.contains(cleanKey);
}

/// Checks if a tab has a dedicated form screen (A.D., N.C., Missing, Preventive, MPDA).
bool isDedicatedFormTab(String? moduleKeyOrCategory) {
  if (moduleKeyOrCategory == null) return false;
  final clean = moduleKeyOrCategory
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll('.', '');
  return clean == 'ad' ||
      clean == 'nc' ||
      clean == 'missing' ||
      clean == 'preventive' ||
      clean == 'mpda';
}

/// Only returns true if the tab is linked to "Common Form Baseline Template".
/// Never defaults to true for new or unlinked tabs.
bool moduleUsesCommonCrimeForm(String moduleKey, [String? categoryName]) =>
    isTabLinkedToCommonFormBaseline(
      moduleKey: moduleKey,
      categoryName: categoryName,
    );

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
  if (status == CaseStatus.disposal.toLowerCase()) {
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
