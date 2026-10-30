// lib/utils/category_navigation_helper.dart
import 'package:flutter/material.dart';

import '../screens/ad/ad_hub_screen.dart';
import '../screens/form_i_v_selection_screen.dart';
import '../screens/form_vi_selection_screen.dart';
import '../screens/history_sheeter/history_sheeter_hub_screen.dart';
import '../screens/module_hub_screen.dart';
import '../screens/mpda/mpda_hub_screen.dart';
import '../screens/nc/nc_hub_screen.dart';
import '../screens/no_form_configured_screen.dart';
import '../screens/rti/rti_hub_screen.dart';
import '../services/ad_service.dart';
import '../screens/juvenile_hub_screen.dart';
import '../screens/victim_hub_screen.dart';
import '../screens/itsso_hub_screen.dart';
import '../screens/dar_hub_screen.dart';
import '../screens/irad_hub_screen.dart';
import '../modules/passport/screens/passport_hub_screen.dart';
import '../modules/licence/screens/licence_hub_screen.dart';
import '../services/case_service.dart';
import '../services/history_sheeter_service.dart';
import '../services/mpda_service.dart';
import '../services/nc_service.dart';
import '../services/rti_service.dart';
import '../modules/muddemal/screens/muddemal_main_screen.dart';
import '../theme/app_theme.dart';
import 'common_form_module.dart';

/// Centralized category navigation helper to handle drill-down hierarchies.
///
/// Ensures both Group page and Standalone Dashboard navigation paths use
/// the exact same children-check logic:
/// 1. Call GET /api/categories/{id}/children/
/// 2. If categoryCode matches target_category_code from /api/rti/config/ -> navigate to [RTIHubScreen]
/// 3. If category has no DB row or form bundle -> navigate to [NoFormConfiguredScreen]
/// 4. If children exist -> navigate to/render sub-tiles ([FormIVSelectionScreen] with [initialCategory])
/// 5. If legitimate case tab -> navigate to [ModuleHubScreen]
class CategoryNavigationHelper {
  static final Map<String, List<Map<String, dynamic>>> _childrenCache = {};

  /// Fetch and cache child categories for a category name or ID.
  static Future<List<Map<String, dynamic>>> getChildren(
    dynamic category, {
    dynamic categoryId,
    bool forceRefresh = false,
  }) async {
    final target = categoryId ?? category;
    final key = target.toString().trim().toLowerCase();
    if (!forceRefresh && _childrenCache.containsKey(key)) {
      return _childrenCache[key]!;
    }
    final children = await CaseService().fetchCategoryChildren(
      target,
      forceRefresh: forceRefresh,
    );
    _childrenCache[key] = children;
    if (category != null) {
      _childrenCache[category.toString().trim().toLowerCase()] = children;
    }
    return children;
  }

  /// Synchronously get cached children if available.
  static List<Map<String, dynamic>>? getCachedChildren(dynamic category) {
    return _childrenCache[category.toString().trim().toLowerCase()];
  }

  /// Prime the cache manually if children are already known.
  static void primeCache(
      dynamic category, List<Map<String, dynamic>> children) {
    _childrenCache[category.toString().trim().toLowerCase()] = children;
  }

  /// Clear in-memory children cache.
  static void clearCache() {
    _childrenCache.clear();
  }

  static int? _groupIdOf(Map<String, dynamic> cat) {
    final g = cat['group'] ?? cat['group_id'];
    if (g is Map) return int.tryParse('${g['group_id'] ?? g['id']}');
    return g == null ? null : int.tryParse(g.toString());
  }

  /// The top-level "1 to 5" (group 1) or "Part 6" (group 2) category that a
  /// dashboard tile label refers to, if any. Names are compared ignoring case,
  /// spaces and punctuation ("COIN" = "Coin", "Crime against\nWomen" =
  /// "Crime Against Women"); labels written differently but with the same
  /// section numbers ("CRPC 156(3) / BNSS 175(3)" = "Sec 156(3)/175(3)(BNSS)")
  /// also match.
  static Map<String, dynamic>? findGroupTwin(
    List<Map<String, dynamic>> allCats,
    String label,
  ) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    String digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
    final n = norm(label);
    final d = digits(label);
    if (n.isEmpty) return null;

    final groupRows = allCats.where((c) {
      final gid = _groupIdOf(c);
      return (gid == 1 || gid == 2) &&
          c['parent_category'] == null &&
          c['is_active'] != false &&
          (c['category_name']?.toString().trim().isNotEmpty ?? false);
    }).toList();

    for (final c in groupRows) {
      if (norm(c['category_name'].toString()) == n) return c;
    }
    if (d.length >= 4) {
      for (final c in groupRows) {
        if (digits(c['category_name'].toString()) == d) return c;
      }
    }
    return null;
  }

  /// Shared navigation handler for standalone dashboard tiles and global search tiles.
  static Future<void> handleDashboardCategoryTap({
    required BuildContext context,
    required String categoryName,
    required String moduleKey,
    dynamic categoryId,
    String? categoryCode,
    bool readOnly = false,
  }) async {
    final cleanName = categoryName.replaceAll('\n', ' ').trim();

    if (cleanName.toLowerCase().contains('passport') ||
        moduleKey.toLowerCase() == 'passport') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const PassportHubScreen(stationName: ''),
        ),
      );
      return;
    }

    if (cleanName.toLowerCase() == 'licence' ||
        cleanName.toLowerCase() == 'license' ||
        moduleKey.toLowerCase() == 'licence') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const LicenceHubScreen(stationName: ''),
        ),
      );
      return;
    }

    if (cleanName.toLowerCase() == 'sam/warrant' ||
        cleanName.toLowerCase() == 'sam warrant' ||
        cleanName.toLowerCase() == 'summons/warrant' ||
        cleanName.toLowerCase() == 'summons & warrant' ||
        moduleKey.toLowerCase() == 'sam_warrant' ||
        moduleKey.toLowerCase() == 'samwarrant') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: ModuleHubScreen(
            moduleLabel: cleanName,
            moduleKey: 'sam_warrant',
            readOnly: readOnly,
          ),
        ),
      );
      return;
    }

    if (cleanName.toLowerCase() == 'victim' ||
        moduleKey.toLowerCase() == 'victim') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const VictimHubScreen(
            stationName: 'Current Station',
          ),
        ),
      );
      return;
    }

    // 1. Resolve categoryCode dynamically from database categories
    String? resolvedCode = categoryCode;
    Map<String, dynamic>? matchedDbCategory;
    final allCats = await CaseService().fetchAllCategories();
    if (allCats.isNotEmpty) {
      final cleanKey = moduleKey.trim().toLowerCase().replaceAll('-', '_');

      matchedDbCategory = allCats.firstWhere(
        (c) {
          final cId = c['category_id']?.toString();
          final cCode = c['category_code']?.toString().trim();
          final cName = c['category_name']?.toString().trim();

          // 1a. Primary: Match by categoryId if provided
          if (categoryId != null &&
              cId != null &&
              cId == categoryId.toString()) {
            return true;
          }
          // 1b. Secondary: Match by categoryCode if provided
          if (categoryCode != null &&
              cCode != null &&
              cCode.toUpperCase() == categoryCode.toUpperCase()) {
            return true;
          }
          // 1c. Match by moduleKey if moduleKey matches categoryCode
          if (cCode != null && cCode.toLowerCase() == cleanKey) {
            return true;
          }
          // 1d. Legacy fallback for other existing tabs (Requirement 4)
          if (cName != null &&
              cleanName.isNotEmpty &&
              cName.toLowerCase() == cleanName.toLowerCase()) {
            return true;
          }
          return false;
        },
        orElse: () => <String, dynamic>{},
      );

      if (matchedDbCategory.isNotEmpty &&
          matchedDbCategory['category_code'] != null) {
        resolvedCode = matchedDbCategory['category_code'].toString();
      }
    }

    // 2. Fetch target_category_codes dynamically from config endpoints
    final rtiConfig = await RtiService().fetchConfig();
    final targetRtiCode = rtiConfig['target_category_code']?.toString().trim();

    final hsConfig = await HistorySheeterService().fetchConfig();
    final targetHsCode = hsConfig['target_category_code']?.toString().trim();

    final mpdaConfig = await MpdaService().fetchConfig();
    final targetMpdaCode =
        mpdaConfig['target_category_code']?.toString().trim();

    final ncConfig = await NcService().fetchConfig();
    final targetNcCode = ncConfig['target_category_code']?.toString().trim();

    final adConfig = await AdService().fetchConfig();
    final targetAdCode = adConfig['target_category_code']?.toString().trim();

    // A tile label may be written differently from its DB row ("A.D" vs
    // "A.D.", "N.C" vs "N.C."). If nothing matched exactly, accept a name
    // match that ignores case, spaces and punctuation.
    if ((matchedDbCategory == null || matchedDbCategory.isEmpty) &&
        resolvedCode == null &&
        allCats.isNotEmpty) {
      String norm(String s) =>
          s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final target = norm(cleanName);
      if (target.isNotEmpty) {
        final row = allCats.firstWhere(
          (c) => norm(c['category_name']?.toString() ?? '') == target,
          orElse: () => <String, dynamic>{},
        );
        if (row.isNotEmpty) {
          matchedDbCategory = row;
          final code = row['category_code']?.toString().trim();
          if (code != null && code.isNotEmpty) resolvedCode = code;
        }
      }
    }

    // 3. Dynamic hub routing strictly by matching database category_code to backend target_category_code
    if (resolvedCode != null && resolvedCode.trim().isNotEmpty) {
      final codeUpper = resolvedCode.trim().toUpperCase();

      // 3a. RTI Hub
      if (targetRtiCode != null &&
          targetRtiCode.isNotEmpty &&
          codeUpper == targetRtiCode.toUpperCase()) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: RTIHubScreen(
              categoryName: cleanName,
              categoryCode: resolvedCode,
              moduleKey: moduleKey,
            ),
          ),
        );
        return;
      }

      // 3b. History Sheeter Hub
      if (targetHsCode != null &&
          targetHsCode.isNotEmpty &&
          codeUpper == targetHsCode.toUpperCase()) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: HistorySheeterHubScreen(
              categoryName: cleanName,
              categoryCode: resolvedCode,
              moduleKey: moduleKey,
            ),
          ),
        );
        return;
      }

      // 3d. N.C. Hub (independent module)
      if (targetNcCode != null &&
          targetNcCode.isNotEmpty &&
          codeUpper == targetNcCode.toUpperCase()) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: NcHubScreen(
              categoryName: cleanName,
              categoryCode: resolvedCode,
              moduleKey: moduleKey,
            ),
          ),
        );
        return;
      }

      // 3e. A.D. Hub (Suicide / Other sub-tabs, each with its own list)
      if (targetAdCode != null &&
          targetAdCode.isNotEmpty &&
          codeUpper == targetAdCode.toUpperCase()) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: AdHubScreen(
              categoryName: cleanName,
              moduleKey: moduleKey,
            ),
          ),
        );
        return;
      }

      // 3c. MPDA Hub
      if (targetMpdaCode != null &&
          targetMpdaCode.isNotEmpty &&
          codeUpper == targetMpdaCode.toUpperCase()) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: MpdaHubScreen(
              categoryName: cleanName,
              categoryCode: resolvedCode,
              moduleKey: moduleKey,
            ),
          ),
        );
        return;
      }
    }

    // 4. Check if tab is unlinked with no DB category row, no form bundle, and no dedicated screen
    final isLinkedToBaseline = isTabLinkedToCommonFormBaseline(
      moduleKey: moduleKey,
      categoryName: cleanName,
    );
    final isDedicated =
        isDedicatedFormTab(moduleKey) || isDedicatedFormTab(cleanName);
    // Ask by the matched row's id: a tile label like "A.D" does not match the
    // DB name "A.D." on the server, so its sub-tabs would not be found.
    final childrenOf = categoryId ??
        matchedDbCategory?['category_id'] ??
        matchedDbCategory?['id'];
    final children = await getChildren(cleanName, categoryId: childrenOf);
    if (!context.mounted) return;

    if (cleanName.toUpperCase() == 'ITSSO' ||
        moduleKey.toLowerCase() == 'itsso') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const ItssoHubScreen(stationName: 'All Stations'),
        ),
      );
      return;
    }
    if (cleanName.toUpperCase() == 'DAR' || moduleKey.toLowerCase() == 'dar') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const DarHubScreen(stationName: 'All Stations'),
        ),
      );
      return;
    }
    if (cleanName.toUpperCase() == 'IRAD' ||
        cleanName.toUpperCase() == 'IRDA' ||
        moduleKey.toLowerCase() == 'irad' ||
        moduleKey.toLowerCase() == 'irda') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const IradHubScreen(stationName: 'All Stations'),
        ),
      );
      return;
    }
    if (cleanName.toLowerCase() == 'muddemal' ||
        moduleKey.toLowerCase() == 'muddemal') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const MuddemalMainScreen(),
        ),
      );
      return;
    }
    if (children.isNotEmpty) {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: FormIVSelectionScreen(
            initialCategory: cleanName,
            customTitle: cleanName,
            moduleKey: moduleKey,
            categoryId: childrenOf,
            mode: readOnly
                ? FormIVSelectionMode.readOnly
                : FormIVSelectionMode.browse,
          ),
        ),
      );
      return;
    }

    // Juvenile has its own hub
    if (moduleKey == 'juvenile') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: const JuvenileHubScreen(
            stationName: 'Current Station',
          ),
        ),
      );
      return;
    }

    // 5. Same category also exists in "1 to 5" / "Part 6": open that group's
    //    sub-tab so the dashboard tile and the group tab share one case list
    //    and one save path (cases added here appear under the group tab).
    final twin = findGroupTwin(allCats, cleanName);
    if (twin != null) {
      final groupId = _groupIdOf(twin);
      final twinName = twin['category_name'].toString().trim();
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: groupId == 2
              ? FormVISelectionScreen(
                  openCategory: twinName,
                  mode: readOnly
                      ? FormVISelectionMode.readOnly
                      : FormVISelectionMode.browse,
                )
              : FormIVSelectionScreen(
                  openCategory: twinName,
                  customTitle: twinName,
                  mode: readOnly
                      ? FormIVSelectionMode.readOnly
                      : FormIVSelectionMode.browse,
                ),
        ),
      );
      return;
    }

    // If tab has no DB row OR is unlinked with no form bundle and no dedicated screen -> NoFormConfiguredScreen
    final hasNoDbRow = matchedDbCategory == null || matchedDbCategory.isEmpty;
    if ((hasNoDbRow && resolvedCode == null) ||
        (!isLinkedToBaseline && !isDedicated)) {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: NoFormConfiguredScreen(
            moduleLabel: cleanName,
          ),
        ),
      );
      return;
    }

    // Legitimate case tab -> ModuleHubScreen
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: ModuleHubScreen(
          moduleLabel: cleanName,
          moduleKey: moduleKey,
          readOnly: readOnly,
        ),
      ),
    );
  }
}
