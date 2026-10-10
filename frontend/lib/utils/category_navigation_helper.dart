// lib/utils/category_navigation_helper.dart
import 'package:flutter/material.dart';

import '../screens/form_i_v_selection_screen.dart';
import '../screens/module_hub_screen.dart';
import '../screens/no_form_configured_screen.dart';
import '../screens/rti/rti_hub_screen.dart';
import '../services/case_service.dart';
import '../services/rti_service.dart';
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

    // 1. Resolve categoryCode dynamically from /api/categories/ if categoryCode is null/empty
    String? resolvedCode = categoryCode;
    Map<String, dynamic>? matchedDbCategory;
    final allCats = await CaseService().fetchAllCategories();
    if (allCats.isNotEmpty) {
      final cleanKey = moduleKey.trim().toLowerCase().replaceAll('-', '_');
      final cleanCatName = cleanName.toLowerCase();

      matchedDbCategory = allCats.firstWhere(
        (c) {
          final cId = c['category_id']?.toString();
          final cCode = c['category_code']?.toString().trim().toLowerCase();
          final cName = c['category_name']?.toString().trim().toLowerCase();
          if (categoryId != null &&
              cId != null &&
              cId == categoryId.toString()) {
            return true;
          }
          if (cCode != null && (cCode == cleanKey || cCode == cleanCatName)) {
            return true;
          }
          if (cName != null && (cName == cleanCatName || cName == cleanKey)) {
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

    // 2. Fetch RTI target_category_code dynamically from /api/rti/config/
    final rtiConfig = await RtiService().fetchConfig();
    final targetRtiCode = rtiConfig['target_category_code']?.toString().trim();

    // 3. If resolved category code matches RTI target_category_code -> open RTIHubScreen
    if (resolvedCode != null &&
        resolvedCode.trim().isNotEmpty &&
        targetRtiCode != null &&
        targetRtiCode.isNotEmpty &&
        resolvedCode.trim().toLowerCase() == targetRtiCode.toLowerCase()) {
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

    // 4. Check if tab is unlinked with no DB category row, no form bundle, and no dedicated screen
    final isLinkedToBaseline = isTabLinkedToCommonFormBaseline(
      moduleKey: moduleKey,
      categoryName: cleanName,
    );
    final isDedicated =
        isDedicatedFormTab(moduleKey) || isDedicatedFormTab(cleanName);
    final children = await getChildren(cleanName, categoryId: categoryId);

    if (!context.mounted) return;

    if (children.isNotEmpty) {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: FormIVSelectionScreen(
            initialCategory: cleanName,
            customTitle: cleanName,
            moduleKey: moduleKey,
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
