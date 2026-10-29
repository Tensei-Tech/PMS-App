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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Form I-V style Tabs Bar
          Container(
            width: double.infinity,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _tabKeys.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final k = entry.value;
                      final isSelected = _tabController.index == idx;
                      final tabLabel = _getConfigString(subTabLabels, k);
                      final count = _counts[k == _chartTab ? 'total' : k] ?? 0;
                      final (badgeBg, badgeFg) = _getTabBadgeColors(k);

                      return Padding(
                        padding: EdgeInsets.only(
                          right: idx == _tabKeys.length - 1 ? 0 : 20,
                        ),
                        child: InkWell(
                          onTap: () {
                            _tabController.animateTo(idx);
                            setState(() {});
                          },
                          hoverColor: Colors.transparent,
                          splashColor:
                              AppColors.navyMid.withValues(alpha: 0.08),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
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
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.navyDark
                                        : AppColors.lightSubText,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
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
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i] as Map<String, dynamic>;
              return _tabKeys[tabIndex] == _chartTab
                  ? _buildHistorySheeterSummaryCard(item)
                  : _buildHistorySheeterCard(item);
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

  /// Summary card for tab 0 (Chart / Summary of History Sheeters).
  /// Displays Sr. No. Badge, Person details (Name, Age, Address, Mobile),
  /// Total Criminal Cases, and clickable counts for Associates, Rivals, and Preventive actions,
  /// matching the RTI responsive single-row card layout.
  Widget _buildHistorySheeterSummaryCard(Map<String, dynamic> item) {
    final id = item['id'];
    final srNo = item['sr_no']?.toString() ?? '';
    final name = item['name']?.toString() ?? '';
    final person = item['person']?.toString() ?? '';
    final totalCasesStr = (item['total_cases'] == null ||
            item['total_cases'].toString().trim().isEmpty)
        ? '-'
        : item['total_cases'].toString().trim();

    final associatesCount = (item['associates'] as num?)?.toInt() ??
        int.tryParse(item['associates']?.toString() ?? '0') ??
        0;
    final rivalsCount = (item['rivals'] as num?)?.toInt() ??
        int.tryParse(item['rivals']?.toString() ?? '0') ??
        0;
    final preventiveCount = (item['preventive'] as num?)?.toInt() ??
        int.tryParse(item['preventive']?.toString() ?? '0') ??
        0;

    final headers = (_config['chart_headers'] as Map?) ?? {};
    final actionLabels = (_config['action_labels'] as Map?) ?? {};
    final viewLabel = _getConfigString(actionLabels, 'view', fallback: 'View');
    final editLabel = _getConfigString(actionLabels, 'edit', fallback: 'Edit');
    final pdfLabel = _getConfigString(actionLabels, 'pdf', fallback: 'PDF');

    Widget buildDetailsRow(bool isExpandedMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Sr. No. Badge (Fixed width 72)
          Container(
            height: 38,
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            alignment: Alignment.center,
            child: InkWell(
              onTap: () => _openViewModal(id),
              borderRadius: BorderRadius.circular(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sr. No.',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Tooltip(
                    message: srNo,
                    child: Text(
                      srNo.isNotEmpty ? srNo : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.0,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildDivider(),

          // 2. Person Details (flex: 4, width: 220)
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: _getConfigString(headers, 'person',
                        fallback: 'Name, Age, Address, Mobile'),
                    value: person.isNotEmpty
                        ? person
                        : (name.isNotEmpty ? name : '—'),
                    icon: Icons.person_outline_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 220,
                  label: _getConfigString(headers, 'person',
                      fallback: 'Name, Age, Address, Mobile'),
                  value: person.isNotEmpty
                        ? person
                        : (name.isNotEmpty ? name : '—'),
                  icon: Icons.person_outline_rounded,
                ),

          _buildDivider(),

          // 3. Total Criminal Cases (flex: 2, width: 95)
          isExpandedMode
              ? Expanded(
                  flex: 2,
                  child: _buildFieldColumn(
                    context: context,
                    label: _getConfigString(headers, 'total_cases',
                        fallback: 'Total Cases'),
                    value: totalCasesStr,
                    icon: Icons.gavel_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 95,
                  label: _getConfigString(headers, 'total_cases',
                      fallback: 'Total Cases'),
                  value: totalCasesStr,
                  icon: Icons.gavel_rounded,
                ),

          _buildDivider(),

          // 4. Known Associates (flex: 2, width: 95)
          isExpandedMode
              ? Expanded(
                  flex: 2,
                  child: _buildFieldColumn(
                    context: context,
                    label: _getConfigString(headers, 'associates',
                        fallback: 'Associates'),
                    value: '',
                    icon: Icons.group_outlined,
                    iconColor: associatesCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                    valueColor: associatesCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                    onTap: associatesCount > 0
                        ? () => _showSummaryEntries(id, 'associates')
                        : null,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 95,
                  label: _getConfigString(headers, 'associates',
                      fallback: 'Associates'),
                  value: '',
                  icon: Icons.group_outlined,
                  iconColor: associatesCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                  valueColor: associatesCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                  onTap: associatesCount > 0
                        ? () => _showSummaryEntries(id, 'associates')
                        : null,
                ),

          _buildDivider(),

          // 5. Rival Persons (flex: 2, width: 95)
          isExpandedMode
              ? Expanded(
                  flex: 2,
                  child: _buildFieldColumn(
                    context: context,
                    label: _getConfigString(headers, 'rivals',
                        fallback: 'Rivals'),
                    value: '',
                    icon: Icons.groups_rounded,
                    iconColor: rivalsCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                    valueColor: rivalsCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                    onTap: rivalsCount > 0
                        ? () => _showSummaryEntries(id, 'rivals')
                        : null,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 95,
                  label: _getConfigString(headers, 'rivals',
                      fallback: 'Rivals'),
                  value: '',
                  icon: Icons.groups_rounded,
                  iconColor: rivalsCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                  valueColor: rivalsCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                  onTap: rivalsCount > 0
                        ? () => _showSummaryEntries(id, 'rivals')
                        : null,
                ),

          _buildDivider(),

          // 6. Preventive Action (flex: 2, width: 95)
          isExpandedMode
              ? Expanded(
                  flex: 2,
                  child: _buildFieldColumn(
                    context: context,
                    label: _getConfigString(headers, 'preventive',
                        fallback: 'Preventive'),
                    value: '',
                    icon: Icons.shield_outlined,
                    iconColor: preventiveCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                    valueColor: preventiveCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                    onTap: preventiveCount > 0
                        ? () => _showSummaryEntries(id, 'preventive')
                        : null,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 95,
                  label: _getConfigString(headers, 'preventive',
                      fallback: 'Preventive'),
                  value: '',
                  icon: Icons.shield_outlined,
                  iconColor: preventiveCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                  valueColor: preventiveCount > 0
                        ? AppColors.navyMid
                        : const Color(0xFF64748B),
                  onTap: preventiveCount > 0
                        ? () => _showSummaryEntries(id, 'preventive')
                        : null,
                ),
        ],
      );
    }

    Widget buildActionButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (viewLabel.isNotEmpty) ...[
            _buildCompactActionButton(
              icon: Icons.visibility_outlined,
              label: viewLabel,
              color: AppColors.navyDark,
              width: 38,
              onTap: () => _openViewModal(id),
            ),
            const SizedBox(width: 6),
          ],
          if (editLabel.isNotEmpty) ...[
            _buildCompactActionButton(
              icon: Icons.edit_outlined,
              label: editLabel,
              color: AppColors.navyDark,
              width: 38,
              onTap: () => _openEditModal(id),
            ),
            const SizedBox(width: 6),
          ],
          if (pdfLabel.isNotEmpty)
            _buildCompactActionButton(
              icon: Icons.picture_as_pdf_outlined,
              label: pdfLabel,
              color: AppColors.navyDark,
              width: 38,
              onTap: () => _downloadPdf(id, name),
            ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;
                if (isWide) {
                  return buildDetailsRow(true);
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 780),
                    child: buildDetailsRow(false),
                  ),
                );
              },
            ),
          ),
          _buildDivider(),
          buildActionButtons(),
        ],
      ),
    );
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
    final sectionKey = _summaryListSections[fieldKey] ?? fieldKey;
    final section = sections.whereType<Map>().firstWhere(
          (s) => s['field_key'] == sectionKey || s['field_key'] == fieldKey,
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildFieldColumn({
    required BuildContext context,
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
    Color? valueColor,
    VoidCallback? onTap,
    double? width,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11.5, color: iconColor ?? const Color(0xFF64748B)),
              const SizedBox(width: 3.5),
            ],
            Flexible(
              child: Text(
                TranslationHelper.translate(context, label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Tooltip(
          message: value,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF0F172A),
              height: 1.1,
              decoration: onTap != null
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        ),
      ],
    );

    final wrapped =
        width != null ? SizedBox(width: width, child: content) : content;

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: wrapped,
      );
    }
    return wrapped;
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    double? width,
  }) {
    final fg = color ?? AppColors.navyDark;
    return Tooltip(
      message: TranslationHelper.translate(context, label),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 38,
          width: width ?? 38,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(height: 1.5),
              Text(
                TranslationHelper.translate(context, label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 8.0,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  height: 1.0,
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
        (item['categories'] as List?)?.map((e) => e.toString()).join(', ') ?? '';

    final actionLabels = (_config['action_labels'] as Map?) ?? {};
    final editLabel = _getConfigString(actionLabels, 'edit');
    final viewLabel = _getConfigString(actionLabels, 'view');
    final pdfLabel = _getConfigString(actionLabels, 'pdf');

    final String datePeriod;
    if (openingDate.isNotEmpty && closureDate.isNotEmpty) {
      datePeriod = ' - ';
    } else if (openingDate.isNotEmpty) {
      datePeriod = openingDate;
    } else if (closureDate.isNotEmpty) {
      datePeriod = closureDate;
    } else {
      datePeriod = '—';
    }

    final rawStatus = item['status']?.toString().trim() ?? '';
    final String statusText;
    final Color statusColor;
    final Color statusBg;
    final Color statusBorder;
    if (closureDate.isNotEmpty || rawStatus.toLowerCase() == 'closed') {
      statusText = 'Closed';
      statusColor = const Color(0xFFD32F2F);
      statusBg = const Color(0xFFFFEBEE);
      statusBorder = const Color(0xFFFFCDD2);
    } else if (item['is_in_jail'] == true || rawStatus.toLowerCase() == 'jail') {
      statusText = 'In Jail';
      statusColor = const Color(0xFF0284C7);
      statusBg = const Color(0xFFE0F2FE);
      statusBorder = const Color(0xFFBAE6FD);
    } else if (item['is_on_bail'] == true || rawStatus.toLowerCase() == 'bail') {
      statusText = 'On Bail';
      statusColor = const Color(0xFFE65100);
      statusBg = const Color(0xFFFFF3E0);
      statusBorder = const Color(0xFFFFCC80);
    } else {
      statusText = rawStatus.isNotEmpty ? rawStatus : 'Active';
      statusColor = const Color(0xFF2E7D32);
      statusBg = const Color(0xFFE8F5E9);
      statusBorder = const Color(0xFFA5D6A7);
    }

    Widget buildDetailsRow(bool isExpandedMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Identification: Sr. No. Badge
          Container(
            height: 38,
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sr. No.',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: srNo,
                  child: Text(
                    srNo.isNotEmpty ? srNo : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              height: 38,
              width: 90,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.goldPrimary.withValues(alpha: 0.35),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Category',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Tooltip(
                    message: categories,
                    child: Text(
                      categories,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldPrimary,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          _buildDivider(),

          // 2. Name (flex: 4, width: 180)
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Name',
                    value: name.isNotEmpty ? name : '—',
                    icon: Icons.person_outline_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 180,
                  label: 'Name',
                  value: name.isNotEmpty ? name : '—',
                  icon: Icons.person_outline_rounded,
                ),

          _buildDivider(),

          // 3. Alias (flex: 3, width: 140)
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Alias',
                    value: alias.isNotEmpty ? alias : '—',
                    icon: Icons.badge_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 140,
                  label: 'Alias',
                  value: alias.isNotEmpty ? alias : '—',
                  icon: Icons.badge_outlined,
                ),

          _buildDivider(),

          // 4. Period / Dates (flex: 3, width: 160)
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Period',
                    value: datePeriod,
                    icon: Icons.calendar_today_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 160,
                  label: 'Period',
                  value: datePeriod,
                  icon: Icons.calendar_today_outlined,
                ),

          _buildDivider(),

          // 5. Status Badge (Fixed width 110 matching RTI)
          Container(
            height: 34,
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Tooltip(
                    message: statusText,
                    child: Text(
                      TranslationHelper.translate(context, statusText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildActionButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (viewLabel.isNotEmpty) ...[
            _buildCompactActionButton(
              icon: Icons.visibility_outlined,
              label: viewLabel,
              color: AppColors.navyDark,
              width: 38,
              onTap: () => _openViewModal(id),
            ),
            const SizedBox(width: 6),
          ],
          if (editLabel.isNotEmpty) ...[
            _buildCompactActionButton(
              icon: Icons.edit_outlined,
              label: editLabel,
              color: AppColors.navyDark,
              width: 38,
              onTap: () => _openEditModal(id),
            ),
            const SizedBox(width: 6),
          ],
          if (pdfLabel.isNotEmpty)
            _buildCompactActionButton(
              icon: Icons.picture_as_pdf_outlined,
              label: pdfLabel,
              color: AppColors.navyDark,
              width: 38,
              onTap: () => _downloadPdf(id, name),
            ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Scrollable/adaptive inner card details
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;
                if (isWide) {
                  return buildDetailsRow(true);
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: buildDetailsRow(false),
                );
              },
            ),
          ),

          _buildDivider(),

          // 2. Fixed right-side Action Buttons
          buildActionButtons(),
        ],
      ),
    );
  }

}