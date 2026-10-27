// lib/screens/history_sheeter/history_sheeter_hub_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/history_sheeter_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/custom_pdf_preview_dialog.dart';
import '../../widgets/dynamic_form/dynamic_form_screen.dart';
import '../../widgets/module_hub_screen_app_bar.dart';
import '../../widgets/pdf_document_view_screen.dart';

/// Dynamic Hub Screen for History Sheeter Module.
/// Adheres strictly to the NO HARDCODING rule:
/// - Tab labels, action labels, empty messages, search placeholders, limits, and page sizes
///   are dynamically read from public.module_settings via GET /api/history-sheeter/config/.
/// - Shows 3 tabs (Active, Open, Closed) with aggregate counts from /api/history-sheeter/counts/.
/// - Has NO number cards.
/// - Each row has Edit, View, and PDF action buttons (labels from settings). No Delete anywhere.
class HistorySheeterHubScreen extends StatefulWidget {
  final String categoryName;
  final String categoryCode;
  final String moduleKey;

  const HistorySheeterHubScreen({
    super.key,
    required this.categoryName,
    required this.categoryCode,
    required this.moduleKey,
  });

  @override
  State<HistorySheeterHubScreen> createState() =>
      _HistorySheeterHubScreenState();
}

class _HistorySheeterHubScreenState extends State<HistorySheeterHubScreen>
    with SingleTickerProviderStateMixin {
  final HistorySheeterService _hsService = HistorySheeterService();
  late TabController _tabController;

  Map<String, dynamic> _config = {};
  Map<String, dynamic> _counts = {
    'total': 0,
    'active': 0,
    'open': 0,
    'closed': 0,
    'jail': 0,
    'bail': 0,
  };

  // Tabs by key: chart (summary table of all sheets, shown first), active,
  // open / closed (in the current year), jail / bail (currently in jail / on bail)
  static const List<String> _tabKeys = [
    'chart',
    'active',
    'open',
    'closed',
    'jail',
    'bail',
  ];
  static const String _chartTab = 'chart';
  late final Map<int, List<dynamic>> _itemsMap = {
    for (int i = 0; i < _tabKeys.length; i++) i: <dynamic>[]
  };
  late final Map<int, int> _pageMap = {
    for (int i = 0; i < _tabKeys.length; i++) i: 1
  };
  late final Map<int, int> _totalCountMap = {
    for (int i = 0; i < _tabKeys.length; i++) i: 0
  };
  late final Map<int, bool> _loadingMap = {
    for (int i = 0; i < _tabKeys.length; i++) i: true
  };

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabKeys.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    _fetchItemsForTab(_tabController.index);
  }

  Future<void> _initializeData() async {
    final config = await _hsService.fetchConfig();
    final counts = await _hsService.fetchCounts();
    if (!mounted) return;
    setState(() {
      _config = config;
      _counts = counts;
    });

    for (int i = 0; i < _tabKeys.length; i++) {
      _fetchItemsForTab(i);
    }
  }

  Future<void> _refreshCounts() async {
    final counts = await _hsService.fetchCounts();
    if (!mounted) return;
    setState(() {
      _counts = counts;
    });
  }

  Future<void> _fetchItemsForTab(int tabIndex, {int? page}) async {
    if (tabIndex < 0 || tabIndex >= _tabKeys.length) return;
    final tabKey = _tabKeys[tabIndex];
    final currentPage = page ?? _pageMap[tabIndex] ?? 1;

    setState(() {
      _loadingMap[tabIndex] = true;
    });

    final data = tabKey == _chartTab
        ? await _hsService.fetchChart(page: currentPage, q: _searchQuery)
        : await _hsService.fetchHistorySheeters(
            tab: tabKey,
            page: currentPage,
            q: _searchQuery,
          );

    if (!mounted) return;

    final results = (data['results'] as List?) ?? [];
    final total = (data['count'] as num?)?.toInt() ?? 0;

    setState(() {
      _itemsMap[tabIndex] = results;
      _pageMap[tabIndex] = currentPage;
      _totalCountMap[tabIndex] = total;
      _loadingMap[tabIndex] = false;
    });
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = val.trim();
      });
      _fetchItemsForTab(_tabController.index, page: 1);
    });
  }

  String _getConfigString(dynamic parentMap, String key,
      {String fallback = ''}) {
    if (parentMap is Map && parentMap.containsKey(key)) {
      final v = parentMap[key]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    if (kDebugMode && fallback.isEmpty && _config.isNotEmpty) {
      debugPrint(
          '[HistorySheeterHubScreen] Warning: missing config value for key: $key');
    }
    return fallback;
  }

  void _openAddModal() async {
    final result = await Navigator.push<bool>(
      context,
      AppTheme.fadeSlideRoute(
        page: DynamicFormScreen(
          categoryId: widget.categoryCode,
          moduleLabel: widget.categoryName,
          moduleKey: widget.moduleKey,
          copyOnTickRules: _config['copy_on_tick_rules'] as List?,
          onSubmitCustom: (payload, isEdit) async {
            final res = await _hsService.createHistorySheeter(payload);
            if (res.isSuccess) {
              return null;
            }
            return {'error': res.errorMessage ?? ''};
          },
        ),
      ),
    );

    if (result == true) {
      await _refreshCounts();
      _fetchItemsForTab(_tabController.index, page: 1);
    }
  }

  void _openEditModal(dynamic id) async {
    final detail = await _hsService.fetchHistorySheeterDetail(id);
    if (!mounted) return;
    if (detail == null) {
      final notFoundMsg = _config['not_found_message']?.toString() ?? '';
      if (notFoundMsg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notFoundMsg)),
        );
      }
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      AppTheme.fadeSlideRoute(
        page: DynamicFormScreen(
          categoryId: widget.categoryCode,
          moduleLabel: widget.categoryName,
          moduleKey: widget.moduleKey,
          initialData: detail,
          copyOnTickRules: _config['copy_on_tick_rules'] as List?,
          onSubmitCustom: (payload, isEdit) async {
            final res = await _hsService.updateHistorySheeter(id, payload);
            if (res.isSuccess) {
              return null;
            }
            return {'error': res.errorMessage ?? ''};
          },
        ),
      ),
    );

    if (result == true) {
      await _refreshCounts();
      _fetchItemsForTab(_tabController.index);
    }
  }

  /// View shows the record exactly as its PDF looks, read-only (no print or
  /// download; the PDF button still offers those).
  void _openViewModal(dynamic id) async {
    final pdfBytes = await _hsService.fetchPdfBytes(id);
    if (!mounted) return;
    if (pdfBytes == null || pdfBytes.isEmpty) {
      final notFoundMsg = _config['not_found_message']?.toString() ?? '';
      if (notFoundMsg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notFoundMsg)),
        );
      }
      return;
    }

    PdfDocumentViewScreen.open(context,
        pdfBytes: pdfBytes, moduleName: widget.categoryName);
  }

  void _downloadPdf(dynamic id, [String? name]) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Loading History Sheeter Report...',
          style: GoogleFonts.poppins(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final pdfBytes = await _hsService.fetchPdfBytes(id);
    if (!mounted) return;

    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      final docTitle = name != null && name.isNotEmpty
          ? 'History Sheeter - $name'
          : 'History Sheeter';
      final fileName =
          '${docTitle.replaceAll(' ', '_').replaceAll('/', '_')}.pdf';
      await CustomPdfPreviewDialog.show(
        context: context,
        title: docTitle,
        fileName: fileName,
        buildPdf: (_) async => pdfBytes,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to generate PDF. Please try again.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subTabLabels = (_config['sub_tab_labels'] as Map?) ?? {};
    final actionLabels = (_config['action_labels'] as Map?) ?? {};

    final addLabel = _getConfigString(actionLabels, 'add',
        fallback: _config['add_button_label']?.toString() ?? '');
    final searchPlaceholder = _config['search_placeholder']?.toString() ?? '';

    Widget? actionWidget;
    if (addLabel.isNotEmpty) {
      actionWidget = ElevatedButton.icon(
        onPressed: _openAddModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyMid,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(
          TranslationHelper.translate(context, addLabel),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, widget.categoryName),
        subtitle: '${_counts['total'] ?? 0}',
        actionWidget: actionWidget,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // Form I-V style Tabs Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Row(
                    children: _tabKeys.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final k = entry.value;
                      final isSelected = _tabController.index == idx;
                      final tabLabel = _getConfigString(subTabLabels, k);
                      final count = _counts[k == _chartTab ? 'total' : k] ?? 0;
                      final (badgeBg, badgeFg) = _getTabBadgeColors(k);

                      return Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: InkWell(
                          onTap: () {
                            _tabController.animateTo(idx);
                            setState(() {});
                          },
                          hoverColor: Colors.transparent,
                          splashColor:
                              AppColors.navyMid.withValues(alpha: 0.08),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF1976D2)
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  TranslationHelper.translate(
                                      context, tabLabel),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.navyDark
                                        : AppColors.lightSubText,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: badgeFg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText:
                    TranslationHelper.translate(context, searchPlaceholder),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.navyMid),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          _fetchItemsForTab(_tabController.index, page: 1);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.navyMid, width: 1.5),
                ),
              ),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabKeys.asMap().entries.map((entry) {
                return _buildTabListContent(entry.key);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getTabBadgeColors(String key) {
    switch (key) {
      case 'active':
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case 'open':
        return (const Color(0xFFFFF3E0), const Color(0xFFE65100));
      case 'closed':
        return (const Color(0xFFF1F5F9), const Color(0xFF475569));
      case 'jail':
        return (const Color(0xFFFFEBEE), const Color(0xFFC62828));
      case 'bail':
        return (const Color(0xFFEDE7F6), const Color(0xFF6A1B9A));
      case 'chart':
      default:
        return (const Color(0xFFE8F1FC), const Color(0xFF1976D2));
    }
  }

  Widget _buildTabListContent(int tabIndex) {
    final isLoading = _loadingMap[tabIndex] ?? true;
    final items = _itemsMap[tabIndex] ?? [];
    final currentPage = _pageMap[tabIndex] ?? 1;
    final total = _totalCountMap[tabIndex] ?? 0;
    final pageSize = (_config['page_size'] as num?)?.toInt() ?? 20;
    final maxPage =
        (total / pageSize).ceil() == 0 ? 1 : (total / pageSize).ceil();

    final emptyMsg = _config['empty_list_message']?.toString() ?? '';

    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_rounded,
                size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            if (emptyMsg.isNotEmpty)
              Text(
                TranslationHelper.translate(context, emptyMsg),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightSubText,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _tabKeys[tabIndex] == _chartTab
              ? _buildChartTable(items)
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = items[i] as Map<String, dynamic>;
                    return _buildHistorySheeterCard(item);
                  },
                ),
        ),

        // Pagination Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                '$currentPage / $maxPage ($total)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.lightSubText,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: currentPage > 1
                    ? () => _fetchItemsForTab(tabIndex, page: currentPage - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: currentPage < maxPage
                    ? () => _fetchItemsForTab(tabIndex, page: currentPage + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Summary tab: one row per history sheet (open and closed). Headers come
  /// from config (chart_headers), the combined person text is rendered by the
  /// backend, and each row has View / Edit / PDF actions.
  Widget _buildChartTable(List<dynamic> items) {
    const numericColumns = [
      'total_cases',
      'associates',
      'rivals',
      'preventive'
    ];
    final headers = (_config['chart_headers'] as Map?) ?? {};
    final actionLabels = (_config['action_labels'] as Map?) ?? {};
    final viewLabel = _getConfigString(actionLabels, 'view');
    final editLabel = _getConfigString(actionLabels, 'edit');
    final pdfLabel = _getConfigString(actionLabels, 'pdf');

    final headStyle = GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.25);
    final textStyle = GoogleFonts.poppins(
        fontSize: 12.5, color: AppColors.navyDark, height: 1.35);
    const border = Color(0xFFE2E8F0);

    String text(Map<String, dynamic> row, String key) {
      final v = row[key];
      final s = v == null ? '' : v.toString().trim();
      return s.isEmpty ? '-' : s;
    }

    Widget header(String key, {TextAlign align = TextAlign.center}) => Text(
          TranslationHelper.translate(context, _getConfigString(headers, key)),
          style: headStyle,
          textAlign: align,
        );

    Widget countPill(String value, {VoidCallback? onTap}) {
      final muted = value == '0' || value == '-';
      final clickable = onTap != null && !muted;
      final pill = Container(
        constraints: const BoxConstraints(minWidth: 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: muted
              ? const Color(0xFFF1F5F9)
              : AppColors.navyMid.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: muted ? AppColors.lightSubText : AppColors.navyDark,
            decoration:
                clickable ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      );
      return Center(
        child: clickable
            ? MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onTap,
                  child: Tooltip(
                    message: TranslationHelper.translate(
                        context, 'Click to see info'),
                    child: pill,
                  ),
                ),
              )
            : pill,
      );
    }

    Widget pad(Widget child, {Alignment align = Alignment.center}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Align(alignment: align, child: child),
        );

    Widget actionButton(IconData icon, String label, VoidCallback onPressed,
        {bool filled = false}) {
      final style = ButtonStyle(
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        minimumSize: WidgetStateProperty.all(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      );
      final text = Text(
        TranslationHelper.translate(context, label),
        style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600),
      );
      return filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 14),
              label: text,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                foregroundColor: Colors.white,
                elevation: 0,
              ).merge(style),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 14),
              label: text,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navyMid,
                side: const BorderSide(color: AppColors.navyMid),
              ).merge(style),
            );
    }

    TableRow dataRow(int i) {
      final row = Map<String, dynamic>.from(items[i] as Map);
      return TableRow(
        decoration: BoxDecoration(
          color: i.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
          border: const Border(top: BorderSide(color: border)),
        ),
        children: [
          pad(MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openViewModal(row['id']),
              child: Tooltip(
                message:
                    TranslationHelper.translate(context, 'Click to see info'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(text(row, 'sr_no'),
                      style: textStyle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyMid,
                          decoration: TextDecoration.underline)),
                ),
              ),
            ),
          )),
          pad(Text(text(row, 'person'), style: textStyle, softWrap: true),
              align: Alignment.centerLeft),
          for (final k in numericColumns)
            pad(countPill(
              text(row, k),
              onTap: _summaryListSections.containsKey(k)
                  ? () =>
                      _showSummaryEntries(row['id'], _summaryListSections[k]!)
                  : null,
            )),
          pad(Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (viewLabel.isNotEmpty)
                actionButton(Icons.visibility_rounded, viewLabel,
                    () => _openViewModal(row['id'])),
              if (editLabel.isNotEmpty)
                actionButton(Icons.edit_rounded, editLabel,
                    () => _openEditModal(row['id'])),
              if (pdfLabel.isNotEmpty)
                actionButton(Icons.picture_as_pdf_rounded, pdfLabel,
                    () => _downloadPdf(row['id'], row['name']?.toString()),
                    filled: true),
            ],
          )),
        ],
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Fill the available width; scroll sideways only on narrow screens
      final available = constraints.maxWidth - 28;
      final tableWidth = available < 1040 ? 1040.0 : available;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: tableWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(72),
                1: FlexColumnWidth(3.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.3),
                5: FlexColumnWidth(1.2),
                6: FixedColumnWidth(250),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.navyMid),
                  children: [
                    pad(header('sr_no')),
                    pad(header('person', align: TextAlign.left),
                        align: Alignment.centerLeft),
                    for (final k in numericColumns) pad(header(k)),
                    pad(header('actions')),
                  ],
                ),
                for (var i = 0; i < items.length; i++) dataRow(i),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Summary column -> repeating group of the History Sheeter form whose
  /// entries the count represents.
  static const Map<String, String> _summaryListSections = {
    'associates': 'hs_associates',
    'rivals': 'hs_rivals',
    'preventive': 'hs_preventive_actions',
  };

  /// Shows the entries of one repeating section of a sheet (title, headers and
  /// rows come from the detail API's repeating_sections, i.e. the form setup).
  Future<void> _showSummaryEntries(dynamic id, String fieldKey) async {
    final detail = await _hsService.fetchHistorySheeterDetail(id);
    if (!mounted || detail == null) return;
    final sections = (detail['repeating_sections'] as List?) ?? const [];
    final section = sections.whereType<Map>().firstWhere(
          (s) => s['field_key'] == fieldKey,
          orElse: () => const {},
        );
    if (section.isEmpty) return;
    final title = section['section_title']?.toString() ?? '';
    final headers =
        ((section['headers'] as List?) ?? const []).map((e) => '$e').toList();
    final rows = ((section['rows'] as List?) ?? const [])
        .whereType<List>()
        .map((r) => r.map((c) {
              final v = c?.toString().trim() ?? '';
              return v.isEmpty ? '-' : v;
            }).toList())
        .toList();
    final name = detail['name']?.toString() ?? '';
    final srNo = detail['sr_no']?.toString() ?? '';

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: const BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(TranslationHelper.translate(context, title),
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          if (srNo.isNotEmpty || name.isNotEmpty)
                            Text(
                              [srNo, name]
                                  .where((x) => x.isNotEmpty)
                                  .join(' · '),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.navyMid.withValues(alpha: 0.07)),
                      columnSpacing: 24,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 64,
                      columns: [
                        for (final h in headers)
                          DataColumn(
                            label: Text(
                              TranslationHelper.translate(context, h),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark),
                            ),
                          ),
                      ],
                      rows: [
                        for (final r in rows)
                          DataRow(cells: [
                            for (var i = 0; i < headers.length; i++)
                              DataCell(ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 260),
                                child: Text(
                                  i < r.length ? r[i] : '-',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: AppColors.lightText),
                                ),
                              )),
                          ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySheeterCard(Map<String, dynamic> item) {
    final id = item['id'];
    final srNo = item['sr_no']?.toString() ?? '';
    final name = item['name']?.toString() ?? '';
    final alias = item['alias']?.toString() ?? '';
    final openingDate = item['opening_date_display']?.toString() ?? '';
    final closureDate = item['closure_date_display']?.toString() ?? '';
    final categories =
        (item['categories'] as List?)?.map((e) => e.toString()).join(', ') ??
            '';

    final actionLabels = (_config['action_labels'] as Map?) ?? {};
    final editLabel = _getConfigString(actionLabels, 'edit');
    final viewLabel = _getConfigString(actionLabels, 'view');
    final pdfLabel = _getConfigString(actionLabels, 'pdf');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (srNo.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      srNo,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                const Spacer(),
                if (openingDate.isNotEmpty)
                  Text(
                    openingDate,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.lightSubText,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            if (alias.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                alias,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.lightSubText,
                ),
              ),
            ],
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                categories,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: AppColors.navyMid,
                ),
              ),
            ],
            if (closureDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                closureDate,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.dangerRed,
                ),
              ),
            ],
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (viewLabel.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openViewModal(id),
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: Text(
                      TranslationHelper.translate(context, viewLabel),
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (editLabel.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openEditModal(id),
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: Text(
                      TranslationHelper.translate(context, editLabel),
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
                if (pdfLabel.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _downloadPdf(id, name),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                    label: Text(
                      TranslationHelper.translate(context, pdfLabel),
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyMid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
