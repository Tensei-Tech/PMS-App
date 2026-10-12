// lib/utils/category_navigation_helper.dart
import 'package:flutter/material.dart';

import '../screens/form_i_v_selection_screen.dart';
import '../screens/module_hub_screen.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';

/// Centralized category navigation helper to handle drill-down hierarchies.
///
/// Ensures both Group page and Standalone Dashboard navigation paths use
/// the exact same children-check logic:
/// 1. Call GET /api/categories/{id}/children/
/// 2. If children exist -> navigate to/render sub-tiles ([FormIVSelectionScreen] with [initialCategory])
/// 3. If no children exist -> navigate straight to the case list ([ModuleHubScreen])
class CategoryNavigationHelper {
  static final Map<String, List<Map<String, dynamic>>> _childrenCache = {};

  /// Fetch and cache child categories for a category name or ID.
  static Future<List<Map<String, dynamic>>> getChildren(
    String category, {
    bool forceRefresh = false,
  }) async {
    final key = category.trim().toLowerCase();
    if (!forceRefresh && _childrenCache.containsKey(key)) {
      return _childrenCache[key]!;
    }
    final children = await CaseService().fetchCategoryChildren(
      category.trim(),
      forceRefresh: forceRefresh,
    );
    _childrenCache[key] = children;
    return children;
  }

  /// Synchronously get cached children if available.
  static List<Map<String, dynamic>>? getCachedChildren(String category) {
    return _childrenCache[category.trim().toLowerCase()];
  }

  /// Prime the cache manually if children are already known.
  static void primeCache(String category, List<Map<String, dynamic>> children) {
    _childrenCache[category.trim().toLowerCase()] = children;
  }

  /// Shared navigation handler for standalone dashboard tiles and global search tiles.
  ///
  /// Calls GET /api/categories/{id}/children/.
  /// - If children exist: pushes [FormIVSelectionScreen] configured for [categoryName]
  ///   to display nested sub-tiles.
  /// - If no children exist: pushes [ModuleHubScreen] directly to display the case list.
  static Future<void> handleDashboardCategoryTap({
    required BuildContext context,
    required String categoryName,
    required String moduleKey,
    bool readOnly = false,
  }) async {
    final cleanName = categoryName.replaceAll('\n', ' ').trim();
    final children = await getChildren(cleanName);
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
    } else {
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
}
