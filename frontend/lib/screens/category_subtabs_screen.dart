import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modules/form_iv/providers/form_iv_provider.dart';
import '../modules/licence/screens/licence_hub_screen.dart';
import '../modules/passport/screens/passport_hub_screen.dart';
import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import '../widgets/module_hub_screen_app_bar.dart';
import 'form_i_v_selection_screen.dart';
import 'nafis_hub_screen.dart';

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

/// A dashboard tile whose sub-tabs are separate modules (not "1 to 5"
/// categories), laid out like the Murder tile's sub-tabs. Each card opens its
/// own module's screen, so no case counts are shown here.
class ModuleTabsScreen extends StatelessWidget {
  final String title;

  /// (label, icon, open)
  final List<(String, IconData, void Function(BuildContext))> tabs;

  const ModuleTabsScreen({super.key, required this.title, required this.tabs});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = width > 1200 ? 4 : (width > 850 ? 3 : (width > 550 ? 2 : 1));
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, title),
        subtitle: '${tabs.length} types',
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: tabs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 74,
        ),
        itemBuilder: (context, i) {
          final (name, icon, open) = tabs[i];
          return CategoryGridCard(
            category: TranslationHelper.translate(context, name),
            icon: icon,
            count: 0,
            showCount: false,
            isAll: false,
            onTap: () => open(context),
          );
        },
      ),
    );
  }
}

/// The dashboard's Passport/PVR/Licence tile: Passport/PVR/Licence and Licence,
/// each opening its module's hub.
class PassportLicenceScreen extends StatelessWidget {
  final String stationName;

  const PassportLicenceScreen({super.key, required this.stationName});

  static const String passportLabel = 'Passport/PVR/Licence';
  static const String passportTabLabel = 'Passport/PVR';
  static const String licenceLabel = 'Licence';

  @override
  Widget build(BuildContext context) {
    return ModuleTabsScreen(
      title: passportLabel,
      tabs: [
        (
          passportTabLabel,
          Icons.badge_rounded,
          (context) => Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: PassportHubScreen(stationName: stationName),
                ),
              ),
        ),
        (
          licenceLabel,
          Icons.assignment_ind_rounded,
          (context) => Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: LicenceHubScreen(stationName: stationName),
                ),
              ),
        ),
      ],
    );
  }
}

/// The dashboard's NAFIS tile: NAFIS and Fingerprint.
class NafisFingerprintScreen extends StatelessWidget {
  final String stationName;

  const NafisFingerprintScreen({super.key, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return ModuleTabsScreen(
      title: 'NAFIS',
      tabs: [
        (
          'NAFIS',
          Icons.fingerprint_rounded,
          (context) => Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: NAFISHubScreen(stationName: stationName),
                ),
              ),
        ),
        (
          'Fingerprint',
          Icons.touch_app_rounded,
          (context) => Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: const ComingSoonScreen(title: 'Fingerprint'),
                ),
              ),
        ),
      ],
    );
  }
}

/// A tab whose screen is not built yet.
class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, title),
        subtitle: TranslationHelper.translate(context, 'Coming soon'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_rounded,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                TranslationHelper.translate(context, 'Coming soon'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${TranslationHelper.translate(context, title)} will be available here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.lightSubText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
