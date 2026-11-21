import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modules/form_iv/providers/form_iv_provider.dart';
import '../modules/licence/screens/licence_hub_screen.dart';
import '../modules/passport/screens/passport_hub_screen.dart';
import '../modules/pvr/providers/pvr_provider.dart';
import '../modules/pvr/screens/pvr_hub_screen.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/translation_helper.dart';
import '../widgets/module_hub_screen_app_bar.dart';
import '../widgets/sub_tab_host.dart';
import 'dar_hub_screen.dart';
import 'disposal_hub_screen.dart';
import 'form_i_v_selection_screen.dart';
import 'fingerprint_hub_screen.dart';
import 'irad_hub_screen.dart';
import 'nafis_hub_screen.dart';

/// Sub-tab cards per row: at least two, so a phone shows a tile's two
/// sub-tabs side by side in one row.
int subtabColumns(double width) => width > 1200 ? 4 : (width > 850 ? 3 : 2);

/// Card height: a little taller on phones, where narrow cards wrap a long
/// name (e.g. "Attempt to Murder") onto two lines.
double subtabCardHeight(double width) => width > 550 ? 74 : 86;

/// One sub-tab of a dashboard tile, from the dashboard_subtabs table.
class DashboardSubtab {
  final String label;

  /// What it opens: 'category' (the "1 to 5" tab named [label]) or a module
  /// ('passport', 'licence', 'pvr', 'nafis', 'fingerprint', 'dar', 'irad',
  /// 'disposal_form_1_5', 'disposal_form_6'); anything else is "Coming soon".
  final String screenKey;
  final String icon;

  /// For 'category': the linked case category; null = the one named [label]
  final String? categoryName;

  const DashboardSubtab(this.label, this.screenKey, this.icon,
      {this.categoryName});

  /// The "1 to 5" category this sub-tab lists
  String get category => categoryName ?? label;
}

/// Sub-tabs of every dashboard tile, loaded once from the backend (table
/// dashboard_subtabs). A tile with no rows keeps the sub-tabs built into the
/// app, so nothing changes when the backend has no such table yet.
class DashboardSubtabs {
  static Map<String, List<DashboardSubtab>> _byParent = {};

  static Future<void> load() async {
    final rows = await CaseService().fetchDashboardSubtabs();
    if (rows.isNotEmpty) setRows(rows);
  }

  /// Rows as the API sends them (parent_key, label, screen_key, icon,
  /// display_order, is_active).
  static void setRows(List<Map<String, dynamic>> rows) {
    int order(Map<String, dynamic> r) =>
        int.tryParse('${r['display_order']}') ?? 0;
    final active = rows
        .where((r) => r['is_active'] != false)
        .where((r) => (r['label']?.toString() ?? '').isNotEmpty)
        .toList()
      ..sort((a, b) => order(a).compareTo(order(b)));
    final byParent = <String, List<DashboardSubtab>>{};
    for (final r in active) {
      final parent = r['parent_key']?.toString() ?? '';
      if (parent.isEmpty) continue;
      final linked = r['category_name']?.toString().trim() ?? '';
      byParent.putIfAbsent(parent, () => []).add(DashboardSubtab(
            r['label'].toString(),
            r['screen_key']?.toString() ?? 'category',
            r['icon']?.toString() ?? '',
            categoryName: linked.isEmpty ? null : linked,
          ));
    }
    TranslationHelper.registerRowLabels(active, 'label');
    _byParent = byParent;
  }

  static void clear() => _byParent = {};

  /// The tile's sub-tabs, or null when the table has none for it.
  static List<DashboardSubtab>? of(String parentKey) {
    final tabs = _byParent[parentKey];
    return (tabs == null || tabs.isEmpty) ? null : tabs;
  }

  static IconData iconFor(String name) {
    switch (name) {
      case 'gavel_rounded':
        return Icons.gavel_rounded;
      case 'lock_outline_rounded':
        return Icons.lock_outline_rounded;
      case 'receipt_long_outlined':
        return Icons.receipt_long_outlined;
      case 'badge_rounded':
        return Icons.badge_rounded;
      case 'fact_check_rounded':
        return Icons.fact_check_rounded;
      case 'touch_app_rounded':
        return Icons.touch_app_rounded;
      default:
        return ServiceData.resolveIconData(name, '');
    }
  }

  /// The page a sub-tab opens.
  static WidgetBuilder pageFor(DashboardSubtab tab, String stationName) {
    switch (tab.screenKey) {
      case 'category':
        return (_) => FormIVSelectionScreen(
              openCategory: tab.category,
              customTitle: tab.label,
              mode: FormIVSelectionMode.browse,
            );
      case 'passport':
        return (_) => PassportHubScreen(stationName: stationName);
      case 'licence':
        return (_) => LicenceHubScreen(stationName: stationName);
      case 'pvr':
        return (context) {
          PvrProvider? existing;
          try {
            existing = context.read<PvrProvider>();
          } catch (_) {}
          return existing != null
              ? PvrHubScreen(stationName: stationName)
              : ChangeNotifierProvider(
                  create: (_) => PvrProvider(),
                  child: PvrHubScreen(stationName: stationName),
                );
        };
      case 'nafis':
        return (_) => NAFISHubScreen(stationName: stationName);
      case 'fingerprint':
        return (_) => FingerprintHubScreen(stationName: stationName);
      case 'dar':
        return (_) => DarHubScreen(stationName: stationName);
      case 'irad':
        return (_) => IradHubScreen(stationName: stationName);
      case 'disposal_form_1_5':
        return (_) => DisposalHubScreen(
            stationName: stationName, groupId: 1, groupTitle: tab.label);
      case 'disposal_form_6':
        return (_) => DisposalHubScreen(
            stationName: stationName, groupId: 2, groupTitle: tab.label);
      default:
        return (_) => ComingSoonScreen(title: tab.label);
    }
  }

  /// A module tile's tabs from the table, else [builtIn].
  static List<(String, IconData, WidgetBuilder)> moduleTabs(
    String parentKey,
    String stationName,
    List<(String, IconData, WidgetBuilder)> builtIn,
  ) {
    final tabs = of(parentKey);
    if (tabs == null) return builtIn;
    return [
      for (final t in tabs) (t.label, iconFor(t.icon), pageFor(t, stationName)),
    ];
  }
}

/// A dashboard tile that groups "1 to 5" categories as sub-tabs
/// (e.g. Murder: Murder / Attempt to Murder), shown as the same compact cards
/// with case counts as Accident's sub-categories. Each sub-tab opens the same
/// "1 to 5" tab, so the case list and form are shared.
class CategorySubtabsScreen extends StatefulWidget {
  final String title;

  /// (category name in case_categories, icon)
  final List<(String, IconData)> subtabs;

  /// Name shown for a category, when the sub-tab is named differently
  final Map<String, String> labels;

  const CategorySubtabsScreen({
    super.key,
    required this.title,
    required this.subtabs,
    this.labels = const {},
  });

  /// Dashboard tiles (by Classification.moduleKey) and their sub-tabs
  static const Map<String, (String, List<(String, IconData)>)> groups = {
    'murder': (
      'Murder',
      [
        ('Murder', Icons.gavel_rounded),
        ('Attempt to Murder', Icons.gavel_rounded),
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
  /// Sub-tabs come from the dashboard_subtabs table when it has "1 to 5"
  /// category rows for the tile, else from [groups].
  static CategorySubtabsScreen? forTile(String moduleKey, {String? title}) {
    final rows = DashboardSubtabs.of(moduleKey);
    if (rows != null && rows.every((t) => t.screenKey == 'category')) {
      return CategorySubtabsScreen(
        title: groups[moduleKey]?.$1 ?? title ?? moduleKey,
        subtabs: [
          for (final t in rows) (t.category, DashboardSubtabs.iconFor(t.icon)),
        ],
        labels: {for (final t in rows) t.category: t.label},
      );
    }
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

  String _label(String category) => widget.labels[category] ?? category;

  Widget _page(String category) => FormIVSelectionScreen(
        openCategory: category,
        customTitle: _label(category),
        mode: FormIVSelectionMode.browse,
      );

  void _open(String category) {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(page: _page(category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Two sub-tabs: open the first right away, with a switch to the other.
    if (widget.subtabs.length == 2) {
      return SubTabHost(
        tabs: [
          for (final (name, icon) in widget.subtabs)
            SubTab(_label(name), icon, (_) => _page(name)),
        ],
      );
    }

    final records = context.watch<FormIVProvider>().records;
    final width = MediaQuery.of(context).size.width;
    final cols = subtabColumns(width);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, widget.title),
        subtitle:
            '${TranslationHelper.translate(context, 'I to V')} · ${widget.subtabs.length} types',
      ),
      body: GridView.builder(
        padding: (cols >= 3 && width < 550)
            ? EdgeInsets.fromLTRB(
                width < 380 ? 6 : 8, 16, width < 380 ? 6 : 8, 24)
            : const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: widget.subtabs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing:
              (cols >= 3 && width < 550) ? (width < 380 ? 4.0 : 6.0) : 12.0,
          mainAxisSpacing: 12,
          mainAxisExtent:
              (cols >= 3 && width < 550) ? 76.0 : subtabCardHeight(width),
        ),
        itemBuilder: (context, i) {
          final (name, icon) = widget.subtabs[i];
          return CategoryGridCard(
            category: TranslationHelper.translate(context, _label(name)),
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
/// categories). With two sub-tabs the first opens right away, with a switch to
/// the other; with more, they are laid out like the Murder tile's sub-tabs and
/// each card opens its own module's screen (no case counts shown here).
class ModuleTabsScreen extends StatelessWidget {
  final String title;

  /// (label, icon, page)
  final List<(String, IconData, WidgetBuilder)> tabs;

  /// When set, overrides the default column count from [subtabColumns].
  final int? columnsOverride;

  const ModuleTabsScreen({
    super.key,
    required this.title,
    required this.tabs,
    this.columnsOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (tabs.isNotEmpty) {
      return SubTabHost(
        tabs: [
          for (final (name, icon, page) in tabs) SubTab(name, icon, page),
        ],
      );
    }

    final width = MediaQuery.of(context).size.width;
    final cols = columnsOverride ??
        (tabs.length >= 3 && width < 550 ? tabs.length : subtabColumns(width));
    final isCompactRow = cols >= 3 && width < 550;
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, title),
        subtitle: '${tabs.length} types',
      ),
      body: GridView.builder(
        padding: isCompactRow
            ? const EdgeInsets.fromLTRB(10, 16, 10, 24)
            : const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: tabs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: isCompactRow ? 8.0 : 12.0,
          mainAxisSpacing: 12.0,
          mainAxisExtent: isCompactRow ? 92.0 : subtabCardHeight(width),
        ),
        itemBuilder: (context, i) {
          final (name, icon, page) = tabs[i];
          return CategoryGridCard(
            category: TranslationHelper.translate(context, name),
            rawCategory: name,
            icon: icon,
            count: 0,
            showCount: false,
            isAll: false,
            onTap: () => Navigator.push(
              context,
              AppTheme.fadeSlideRoute(page: Builder(builder: page)),
            ),
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
  static const String passportTabLabel = 'Passport';
  static const String licenceLabel = 'Licence';
  static const String pvrLabel = 'PVR';

  @override
  Widget build(BuildContext context) {
    return ModuleTabsScreen(
      title: passportLabel,
      columnsOverride: 3,
      tabs: DashboardSubtabs.moduleTabs('passport', stationName, [
        (
          passportTabLabel,
          Icons.badge_rounded,
          (_) => PassportHubScreen(stationName: stationName),
        ),
        (
          pvrLabel,
          Icons.fact_check_rounded,
          (context) {
            PvrProvider? existing;
            try {
              existing = context.read<PvrProvider>();
            } catch (_) {}
            return existing != null
                ? PvrHubScreen(stationName: stationName)
                : ChangeNotifierProvider(
                    create: (_) => PvrProvider(),
                    child: PvrHubScreen(stationName: stationName),
                  );
          },
        ),
        (
          licenceLabel,
          Icons.assignment_ind_rounded,
          (_) => LicenceHubScreen(stationName: stationName),
        ),
      ]),
    );
  }
}

/// The dashboard's NAFIS/Fingerprint tile: NAFIS and Fingerprint.
class NafisFingerprintScreen extends StatelessWidget {
  final String stationName;

  const NafisFingerprintScreen({super.key, required this.stationName});

  static const String title = 'NAFIS/Fingerprint';

  @override
  Widget build(BuildContext context) {
    return ModuleTabsScreen(
      title: title,
      tabs: DashboardSubtabs.moduleTabs('nafis', stationName, [
        (
          'NAFIS',
          Icons.fingerprint_rounded,
          (_) => NAFISHubScreen(stationName: stationName),
        ),
        (
          'Fingerprint',
          Icons.touch_app_rounded,
          (_) => FingerprintHubScreen(stationName: stationName),
        ),
      ]),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...SubTabHost.strip(context),
          Expanded(child: _buildMessage(context)),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Center(
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
              style:
                  const TextStyle(fontSize: 13, color: AppColors.lightSubText),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashboard's DAR/IRAD tile: DAR and IRAD, each opening its hub.
class DarIradScreen extends StatelessWidget {
  final String stationName;

  const DarIradScreen({super.key, required this.stationName});

  static const String title = 'DAR/IRAD';

  @override
  Widget build(BuildContext context) {
    return ModuleTabsScreen(
      title: title,
      tabs: DashboardSubtabs.moduleTabs('dar', stationName, [
        (
          'DAR',
          Icons.folder_rounded,
          (_) => DarHubScreen(stationName: stationName),
        ),
        (
          'IRAD',
          Icons.analytics_rounded,
          (_) => IradHubScreen(stationName: stationName),
        ),
      ]),
    );
  }
}
