import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modules/form_iv/providers/form_iv_provider.dart';
import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import '../widgets/module_hub_screen_app_bar.dart';
import 'form_i_v_selection_screen.dart';

/// A dashboard tile that groups "1 to 5" categories as sub-tabs
/// (e.g. Murder: Murder / Attempt to Murder), shown as the same compact cards
/// with case counts as Accident's sub-categories. Each sub-tab opens the same
/// "1 to 5" tab, so the case list and form are shared.
class CategorySubtabsScreen extends StatefulWidget {
  final String title;

  /// (category name in case_categories, icon)
  final List<(String, IconData)> subtabs;

  const CategorySubtabsScreen({
    super.key,
    required this.title,
    required this.subtabs,
  });

  /// Dashboard tiles (by Classification.moduleKey) and their sub-tabs
  static const Map<String, (String, List<(String, IconData)>)> groups = {
    'murder': (
      'Murder',
      [
        ('Murder', Icons.warning_amber_rounded),
        ('Attempt to Murder', Icons.warning_amber_rounded),
      ]
    ),
    'dacoity': (
      'Dacoity',
      [
        ('Dacoity', Icons.lock_outline_rounded),
        ('Robbery', Icons.lock_outline_rounded),
      ]
    ),
    'cheating': (
      'Cheating',
      [
        ('Cheating', Icons.receipt_long_outlined),
        ('CBT', Icons.receipt_long_outlined),
      ]
    ),
  };

  /// The screen for a dashboard tile's moduleKey, or null if it has no sub-tabs.
  static CategorySubtabsScreen? forTile(String moduleKey) {
    final group = groups[moduleKey];
    if (group == null) return null;
    return CategorySubtabsScreen(title: group.$1, subtabs: group.$2);
  }

  @override
  State<CategorySubtabsScreen> createState() => _CategorySubtabsScreenState();
}

class _CategorySubtabsScreenState extends State<CategorySubtabsScreen> {
  @override
  void initState() {
    super.initState();
    // Case counts come from the "1 to 5" records
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FormIVProvider>().ensureInitialized();
    });
  }

  void _open(String category) {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: FormIVSelectionScreen(
          openCategory: category,
          customTitle: category,
          mode: FormIVSelectionMode.browse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<FormIVProvider>().records;
    final width = MediaQuery.of(context).size.width;
    final cols = width > 1200 ? 4 : (width > 850 ? 3 : (width > 550 ? 2 : 1));

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, widget.title),
        subtitle:
            '${TranslationHelper.translate(context, 'I to V')} · ${widget.subtabs.length} types',
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: widget.subtabs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 74,
        ),
        itemBuilder: (context, i) {
          final (name, icon) = widget.subtabs[i];
          return CategoryGridCard(
            category: TranslationHelper.translate(context, name),
            rawCategory: name,
            icon: icon,
            count: records
                .where(
                    (r) => FormIVSelectionScreen.recordMatchesCategory(r, name))
                .length,
            isAll: false,
            onTap: () => _open(name),
          );
        },
      ),
    );
  }
}
