import 'package:flutter/foundation.dart';

import '../services/case_service.dart';
import '../services/history_sheeter_service.dart';
import '../services/mpda_service.dart';
import '../services/rti_service.dart';
import 'category_navigation_helper.dart';

/// In-memory caches of per-tenant settings: the category list, category
/// children and the RTI / MPDA / History Sheeter configs.
///
/// The dashboard used to clear them every time it opened, so every visit
/// downloaded them again. They are now cleared only when the signed-in user,
/// state or station changes, when they are older than [maxAge], and on login
/// and logout, so one account never sees another account's settings.
class AppDataCache {
  AppDataCache._();

  /// Admin changes to categories or module settings show up within this time.
  static const Duration maxAge = Duration(minutes: 10);

  static String? _scope;
  static DateTime? _filledAt;

  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  @visibleForTesting
  static void Function() clearCaches = _clearServiceCaches;

  static String scopeFor({
    required String uid,
    required String stateCode,
    required String station,
  }) =>
      '$uid|$stateCode|$station';

  /// Clears the caches if [scope] differs from the last call or they are older
  /// than [maxAge]. Returns true when it cleared them.
  static bool ensureFresh(String scope) {
    final current = now();
    final filledAt = _filledAt;
    final fresh = _scope == scope &&
        filledAt != null &&
        current.difference(filledAt) <= maxAge;
    if (fresh) return false;
    clearCaches();
    _scope = scope;
    _filledAt = current;
    return true;
  }

  /// Login and logout: drop everything so the next screen reloads.
  static void clearAll() {
    clearCaches();
    _scope = null;
    _filledAt = null;
  }

  @visibleForTesting
  static void resetForTest() {
    _scope = null;
    _filledAt = null;
    now = DateTime.now;
    clearCaches = _clearServiceCaches;
  }

  static void _clearServiceCaches() {
    CaseService().clearCategoryCache();
    CategoryNavigationHelper.clearCache();
    RtiService().clearConfigCache();
    HistorySheeterService().clearConfigCache();
    MpdaService().clearConfigCache();
  }
}
