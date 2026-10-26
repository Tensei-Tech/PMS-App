// lib/screens/mpda/mpda_hub_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/mpda_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/custom_pdf_preview_dialog.dart';
import '../../widgets/dynamic_form/dynamic_form_screen.dart';
import '../../widgets/module_hub_screen_app_bar.dart';
import '../../widgets/pdf_document_view_screen.dart';

/// Dynamic Hub Screen for MPDA Module.
/// Adheres strictly to the NO HARDCODING rule:
/// - Tab & card labels, action labels, empty messages, search placeholders, limits, and page sizes
///   are dynamically read from public.module_settings via GET /api/mpda/config/.
/// - Shows 6 cards that are ALSO tabs (each is both, in order), then Summary:
///   0: total, 1: approved, 2: rejected, 3: proposal_revoked, 4: jail,
///   5: released_next_month.
/// - The card number and its list always agree.
/// - Each row has Edit, View, and PDF action buttons (labels from settings). No Delete anywhere.
class MpdaHubScreen extends StatefulWidget {
  final String categoryName;
  final String categoryCode;
  final String moduleKey;

  const MpdaHubScreen({
    super.key,
    required this.categoryName,
    required this.categoryCode,
    required this.moduleKey,
  });

  @override
  State<MpdaHubScreen> createState() => _MpdaHubScreenState();
}

class _MpdaHubScreenState extends State<MpdaHubScreen>
    with SingleTickerProviderStateMixin {
  final MpdaService _mpdaService = MpdaService();
  late TabController _tabController;

  Map<String, dynamic> _config = {};
  Map<String, dynamic> _counts = {
    'total': 0,
    'approved': 0,
    'rejected': 0,
    'proposal_revoked': 0,
    'jail': 0,
    'released_next_month': 0,
  };

  // 6 status tabs/cards in order, then the Summary card (all proposals):
  static const List<String> _tabKeys = [
    'total',
    'approved',
    'rejected',
    'proposal_revoked',
    'jail',
    'released_next_month',
    'summary',
  ];
  static const String _summaryTab = 'summary';
  static const String _releasedTab = 'released_next_month';

  /// Day filter picked inside the Released card (null = next month)
  int? _releasedDays;

  // Form fields shown when the Summary outcome / category cell is tapped
  static const Set<String> _outcomeFieldKeys = {
    'mpda_proposal_outcome',
    'mpda_granted_date',
    'mpda_rejected_date',
    'mpda_proposal_revoked',
    'mpda_proposal_revoked_date',
  };
  static const String _categoryFieldKey = 'mpda_category';

  final Map<int, List<dynamic>> _itemsMap = {
    0: [],
    1: [],
    2: [],
    3: [],
    4: [],
    5: [],
    6: [],
  };
  final Map<int, int> _pageMap = {0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1};
  final Map<int, int> _totalCountMap = {
    0: 0,
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
  };
  final Map<int, bool> _loadingMap = {
    0: true,
    1: true,
    2: true,
    3: true,
    4: true,
    5: true,
    6: true,
  };

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _cardsScrollController = ScrollController();
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
    _cardsScrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // Updates active card highlight
    _fetchItemsForTab(_tabController.index);
    _scrollToCard(_tabController.index);
  }

  void _scrollToCard(int index) {
    if (!_cardsScrollController.hasClients) return;
    const cardWidthWithMargin = 104.0;
    final targetOffset = (index * cardWidthWithMargin) - 16;
    final clampedOffset = targetOffset.clamp(
      0.0,
      _cardsScrollController.position.maxScrollExtent,
    );
    _cardsScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeData() async {
    final config = await _mpdaService.fetchConfig(forceRefresh: true);
    final counts = await _mpdaService.fetchCounts();
    if (!mounted) return;
    setState(() {
      _config = config;
      _counts = counts;
    });

    for (int i = 0; i < _tabKeys.length; i++) {
      _fetchItemsForTab(i);
    }
    _loadReminders();
  }

  Future<void> _refreshCounts() async {
    final counts = await _mpdaService.fetchCounts();
    if (!mounted) return;
    setState(() {
      _counts = counts;
    });
    _loadReminders();
  }

  /// Detention end reminders of this station (backend decides which: from one
  /// month before the Detention End Date until that date).
  Map<String, dynamic> _reminders = const {};

  Future<void> _loadReminders() async {
    final data = await _mpdaService.fetchDetentionReminders();
    if (!mounted) return;
    setState(() => _reminders = data);
  }

  Widget _buildReminderBanner() {
    // Station detentions only; "Send Reminder" messages show in Notifications
    final items = ((_reminders['results'] as List?) ?? const [])
        .whereType<Map>()
        .where((r) => r['kind'] != 'manual')
        .toList();
    final labels = (_reminders['labels'] as Map?) ?? const {};
    final text = (labels['banner']?.toString() ?? '')
        .replaceAll('{count}', '${items.length}')
        .replaceAll('{days}', '${_reminders['days'] ?? ''}');
    if (items.isEmpty || text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Material(
        color: AppColors.dangerRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showInfoDialog(
            title: labels['tab']?.toString() ?? text,
            proposalNo: '',
            maxWidth: 560,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in items)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${r['message'] ?? ''}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5, color: AppColors.navyDark)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _openViewModal(r['id']);
                          },
                          child: Text(
                              TranslationHelper.translate(
                                  context,
                                  _getConfigString(
                                      (_config['action_labels'] as Map?) ?? {},
                                      'view')),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    size: 18, color: AppColors.dangerRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(TranslationHelper.translate(context, text),
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dangerRed)),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.dangerRed),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Released card count for the active day filter (next month when none)
  int _releasedCount() {
    if (_releasedDays == null) {
      return (_counts[_releasedTab] as num?)?.toInt() ?? 0;
    }
    final byDays = _counts['released_in_days'];
    return byDays is Map ? (byDays['$_releasedDays'] as num?)?.toInt() ?? 0 : 0;
  }

  /// Day filter chips inside the Released card (released_filter_days from
  /// config). Tapping one makes it active and opens the card; tapping the
  /// active one again goes back to next month.
  Widget _buildReleasedDayChips(int tabIdx) {
    final options = ((_config['released_filter_days'] as List?) ?? const [])
        .map((e) => int.tryParse('$e'))
        .whereType<int>()
        .toList();
    final labelTemplate = _config['released_filter_label']?.toString() ?? '';
    if (options.isEmpty || labelTemplate.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((d) {
          final active = _releasedDays == d;
          final chip = InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _releasedDays = active ? null : d);
              if (_tabController.index != tabIdx) {
                // The tab listener fetches the list with the new filter
                _tabController.animateTo(tabIdx);
              } else {
                _fetchItemsForTab(tabIdx, page: 1);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.navyMid
                    : AppColors.navyMid.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? AppColors.navyMid
                      : AppColors.navyMid.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (active) ...[
                    const Icon(Icons.check_rounded,
                        size: 10, color: Colors.white),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    TranslationHelper.translate(
                        context, labelTemplate.replaceAll('{days}', '$d')),
                    style: GoogleFonts.poppins(
                      fontSize: 9.0,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.navyMid,
                    ),
                  ),
                ],
              ),
            ),
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: chip,
          );
        }).toList(),
      ),
    );
  }

  Future<void> _fetchItemsForTab(int tabIndex, {int? page}) async {
    if (tabIndex < 0 || tabIndex >= _tabKeys.length) return;
    final tabKey = _tabKeys[tabIndex];
    final currentPage = page ?? _pageMap[tabIndex] ?? 1;

    setState(() {
      _loadingMap[tabIndex] = true;
    });

    final data = tabKey == _summaryTab
        ? await _mpdaService.fetchSummary(page: currentPage, q: _searchQuery)
        : await _mpdaService.fetchProposals(
            tab: tabKey,
            page: currentPage,
            q: _searchQuery,
            days: tabKey == _releasedTab ? _releasedDays : null,
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
      debugPrint('[MpdaHubScreen] Warning: missing config value for key: $key');
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
          onSubmitCustom: (payload, isEdit) async {
            final res = await _mpdaService.createProposal(payload);
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
    final detail = await _mpdaService.fetchProposalDetail(id);
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
          onSubmitCustom: (payload, isEdit) async {
            final res = await _mpdaService.updateProposal(id, payload);
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

  /// View shows the proposal exactly as its PDF looks, read-only.
  void _openViewModal(dynamic id) async {
    final pdfBytes = await _mpdaService.fetchPdfBytes(id);
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

  void _downloadPdf(dynamic id, [String? proposalNo]) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Loading MPDA Report...',
          style: GoogleFonts.poppins(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final pdfBytes = await _mpdaService.fetchPdfBytes(id);
    if (!mounted) return;

    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      final docTitle = proposalNo != null && proposalNo.isNotEmpty
          ? 'MPDA Proposal - $proposalNo'
          : 'MPDA Proposal';
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
    final cardLabels = (_config['card_labels'] as Map?) ?? {};
    final actionLabels = (_config['action_labels'] as Map?) ?? {};

    final addLabel = _getConfigString(actionLabels, 'add',
        fallback: _config['add_button_label']?.toString() ?? '');
    final searchPlaceholder = _config['search_placeholder']?.toString() ?? '';

    final isMobile = MediaQuery.of(context).size.width < 500;
    Widget? actionWidget;
    if (addLabel.isNotEmpty) {
      actionWidget = ElevatedButton.icon(
        onPressed: _openAddModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyMid,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 14,
            vertical: isMobile ? 6 : 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.add_rounded, size: isMobile ? 14 : 16),
        label: Text(
          TranslationHelper.translate(context, addLabel),
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, widget.categoryName),
        subtitle:
            '${_counts['total'] ?? 0} ${TranslationHelper.translate(context, 'Total Proposals')}',
        actionWidget: actionWidget,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          _buildReminderBanner(),
          // CARDS (single row: expands on wide screens, scrolls horizontally on small screens)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;
                if (isWide) {
                  return Row(
                    children: List.generate(_tabKeys.length, (idx) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: idx < _tabKeys.length - 1 ? 8 : 0,
                          ),
                          child: SizedBox(
                            height: 72,
                            child: _buildCardItem(idx, cardLabels),
                          ),
                        ),
                      );
                    }),
                  );
                }

                final cardWidth = constraints.maxWidth < 420
                    ? 108.0
                    : (constraints.maxWidth < 600 ? 116.0 : 130.0);

                return SizedBox(
                  height: 72,
                  child: ListView.separated(
                    controller: _cardsScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      return SizedBox(
                        width: cardWidth,
                        child: _buildCardItem(idx, cardLabels),
                      );
                    },
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
                hintText: TranslationHelper.translate(
                  context,
                  searchPlaceholder.isNotEmpty
                      ? searchPlaceholder
                      : 'Search MPDA Proposals...',
                ),
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

  Widget _buildCardItem(int idx, Map cardLabels) {
    final k = _tabKeys[idx];
    final label = _getConfigString(cardLabels, k);
    final count = k == _releasedTab ? _releasedCount() : (_counts[k] ?? 0);
    final isSelected = _tabController.index == idx;

    return InkWell(
      onTap: () {
        _tabController.animateTo(idx);
        _scrollToCard(idx);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.navyMid.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.navyMid : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (k == _summaryTab)
                  Icon(
                    Icons.table_chart_rounded,
                    size: 22,
                    color:
                        isSelected ? AppColors.navyDark : AppColors.lightText,
                  )
                else
                  Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? AppColors.navyDark : AppColors.lightText,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  TranslationHelper.translate(context, label),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.navyDark
                        : AppColors.lightSubText,
                  ),
                ),
                if (k == _releasedTab) _buildReleasedDayChips(idx),
              ],
            ),
          ),
        ),
      ),
    );
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
      final tabKey = _tabKeys[tabIndex];
      String defaultTitle = 'No MPDA Proposals';
      String defaultSubtitle =
          'Proposals will appear here once submitted or updated';
      if (_searchQuery.isNotEmpty) {
        defaultTitle = 'No Matching Proposals';
        defaultSubtitle = 'No MPDA proposals match "$_searchQuery"';
      } else if (tabKey == 'approved') {
        defaultTitle = 'No Approved MPDA Proposals';
      } else if (tabKey == 'rejected') {
        defaultTitle = 'No Rejected MPDA Proposals';
      } else if (tabKey == 'proposal_revoked') {
        defaultTitle = 'No Revoked MPDA Proposals';
      } else if (tabKey == 'jail') {
        defaultTitle = 'No Persons in Jail under MPDA';
      } else if (tabKey == 'released_next_month') {
        defaultTitle = 'No Persons Scheduled for Release';
      } else if (tabKey == _summaryTab) {
        defaultTitle = 'No MPDA Summary Records';
      }

      final displayMsg = emptyMsg.isNotEmpty
          ? TranslationHelper.translate(context, emptyMsg)
          : TranslationHelper.translate(context, defaultTitle);

      return RefreshIndicator(
        onRefresh: () => _fetchItemsForTab(tabIndex, page: 1),
        color: AppColors.navyMid,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.folder_off_rounded,
                      size: 44,
                      color: AppColors.navyMid.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayMsg,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TranslationHelper.translate(context, defaultSubtitle),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.lightSubText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _fetchItemsForTab(tabIndex, page: 1),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      TranslationHelper.translate(context, 'Refresh'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyMid,
                      side: BorderSide(
                        color: AppColors.navyMid.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _tabKeys[tabIndex] == _summaryTab
              ? RefreshIndicator(
                  onRefresh: () =>
                      _fetchItemsForTab(tabIndex, page: currentPage),
                  color: AppColors.navyMid,
                  child: _buildSummaryTable(items),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      _fetchItemsForTab(tabIndex, page: currentPage),
                  color: AppColors.navyMid,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = items[i] as Map<String, dynamic>;
                      return _buildMpdaCard(item);
                    },
                  ),
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

  /// Summary: one row per proposal. Headers come from config
  /// (summary_headers); accused lines and the outcome text are rendered by the
  /// backend. Sr. No. and View open the full record; every other cell opens
  /// its details (accused, gang members, outcome, category).
  /// Summary "Send Reminder": notify every officer of the police station now
  /// (until the end date).
  Future<void> _sendReminder(dynamic id) async {
    final res = await _mpdaService.sendReminder(id);
    if (!mounted) return;
    final data = res.data is Map ? res.data as Map : const {};
    final message = res.isSuccess
        ? data['message']?.toString() ?? ''
        : (data['error']?.toString() ?? res.errorMessage ?? '');
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          TranslationHelper.translate(context, message),
          style: GoogleFonts.poppins(),
        ),
        backgroundColor:
            res.isSuccess ? AppColors.successGreen : AppColors.dangerRed,
      ),
    );
  }

  Widget _buildSummaryTable(List<dynamic> items) {
    final headers = (_config['summary_headers'] as Map?) ?? {};
    final actionLabels = (_config['action_labels'] as Map?) ?? {};
    final viewLabel = _getConfigString(actionLabels, 'view');
    final remindLabel = _getConfigString(actionLabels, 'remind');

    final headStyle = GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.25);
    final textStyle = GoogleFonts.poppins(
        fontSize: 12.5, color: AppColors.navyDark, height: 1.35);
    const border = Color(0xFFE2E8F0);

    String text(dynamic v) {
      final s = v == null ? '' : v.toString().trim();
      return s.isEmpty ? '-' : s;
    }

    Widget header(String key, {TextAlign align = TextAlign.center}) => Text(
          TranslationHelper.translate(context, _getConfigString(headers, key)),
          style: headStyle,
          textAlign: align,
        );

    Widget pad(Widget child, {Alignment align = Alignment.center}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Align(alignment: align, child: child),
        );

    Widget clickable(Widget child, VoidCallback onTap) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Tooltip(
              message:
                  TranslationHelper.translate(context, 'Click to see info'),
              child: child,
            ),
          ),
        );

    // A whole table cell that opens details when tapped anywhere in it
    Widget tapCell(Widget child, VoidCallback onTap,
            {Alignment align = Alignment.center}) =>
        clickable(pad(child, align: align), onTap);

    TableRow dataRow(int i) {
      final row = Map<String, dynamic>.from(items[i] as Map);
      final id = row['id'];
      final accused = ((row['accused'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      final gang = text(row['gang_members']);
      final hasGang = gang != '-' && gang != '0';
      return TableRow(
        decoration: BoxDecoration(
          color: i.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
          border: const Border(top: BorderSide(color: border)),
        ),
        children: [
          pad(clickable(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(text(row['sr_no']),
                  style: textStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyMid,
                      decoration: TextDecoration.underline)),
            ),
            () => _openViewModal(id),
          )),
          tapCell(
              accused.isEmpty
                  ? Text('-', style: textStyle)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var j = 0; j < accused.length; j++)
                          Padding(
                            padding: EdgeInsets.only(top: j == 0 ? 0 : 6),
                            child: Text(
                              accused.length > 1
                                  ? '${j + 1}. ${accused[j]}'
                                  : accused[j],
                              style: textStyle,
                              softWrap: true,
                            ),
                          ),
                      ],
                    ),
              () => _showRepeatingSection(id, 'mpda_accused'),
              align: Alignment.centerLeft),
          tapCell(() {
            final pill = Container(
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasGang
                    ? AppColors.navyMid.withValues(alpha: 0.10)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                gang,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: hasGang ? AppColors.navyDark : AppColors.lightSubText,
                  decoration:
                      hasGang ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            );
            return pill;
          }(), () => _showRepeatingSection(id, 'mpda_gang_members')),
          tapCell(
            Text(text(row['outcome']),
                style: textStyle, textAlign: TextAlign.center),
            () => _showFields(id, _getConfigString(headers, 'outcome'),
                (f, _) => _outcomeFieldKeys.contains(f['field_key'])),
          ),
          tapCell(
            Text(text(row['category']),
                style: textStyle, textAlign: TextAlign.center),
            () => _showFields(id, _getConfigString(headers, 'category'),
                (f, all) {
              // Every field in the same form section as the category
              final cat = all.firstWhere(
                  (x) => x['field_key'] == _categoryFieldKey,
                  orElse: () => const {});
              return f['section'] == cat['section'];
            }),
          ),
          // View and Send Reminder side by side on one line; left-aligned so
          // View sits in the same place on every row
          pad(
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (viewLabel.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => _openViewModal(id),
                        icon: const Icon(Icons.visibility_rounded, size: 15),
                        label: Text(
                          TranslationHelper.translate(context, viewLabel),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyMid,
                          side: const BorderSide(color: AppColors.navyMid),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    // Until the Detention End Date (backend sends can_remind)
                    if (viewLabel.isNotEmpty &&
                        remindLabel.isNotEmpty &&
                        row['can_remind'] == true)
                      const SizedBox(width: 6),
                    if (remindLabel.isNotEmpty && row['can_remind'] == true)
                      ElevatedButton.icon(
                        onPressed: () => _sendReminder(id),
                        icon: const Icon(Icons.notifications_active_rounded,
                            size: 15),
                        label: Text(
                          TranslationHelper.translate(context, remindLabel),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyMid,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),
              align: Alignment.centerLeft),
        ],
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth - 28;
      final tableWidth = available < 1090 ? 1090.0 : available;
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
                1: FlexColumnWidth(3.4),
                2: FlexColumnWidth(1.3),
                3: FlexColumnWidth(1.6),
                4: FlexColumnWidth(1.5),
                5: FixedColumnWidth(300),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.navyMid),
                  children: [
                    pad(header('sr_no')),
                    pad(header('accused', align: TextAlign.left),
                        align: Alignment.centerLeft),
                    pad(header('gang_members')),
                    pad(header('outcome')),
                    pad(header('category')),
                    pad(header('actions', align: TextAlign.left),
                        align: Alignment.centerLeft),
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

  /// One repeating section of a proposal (accused, gang members ...): title,
  /// headers and rows come from the detail API's repeating_sections, i.e. the
  /// MPDA form setup.
  Future<void> _showRepeatingSection(dynamic id, String fieldKey) async {
    final detail = await _mpdaService.fetchProposalDetail(id);
    if (!mounted || detail == null) return;
    final sections = (detail['repeating_sections'] as List?) ?? const [];
    final section = sections.whereType<Map>().firstWhere(
          (s) => s['field_key'] == fieldKey,
          orElse: () => const {},
        );
    if (section.isEmpty) return;
    final headers =
        ((section['headers'] as List?) ?? const []).map((e) => '$e').toList();
    final rows = ((section['rows'] as List?) ?? const [])
        .whereType<List>()
        .map((r) => r.map((c) {
              final v = c?.toString().trim() ?? '';
              return v.isEmpty ? '-' : v;
            }).toList())
        .toList();

    final cellStyle =
        GoogleFonts.poppins(fontSize: 12.5, color: AppColors.lightText);
    await _showInfoDialog(
      title: section['section_title']?.toString() ?? '',
      proposalNo: detail['proposal_no_and_year']?.toString() ?? '',
      maxWidth: 900,
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              AppColors.navyMid.withValues(alpha: 0.07)),
          columnSpacing: 24,
          dataRowMaxHeight: double.infinity,
          columns: [
            for (final h in headers)
              DataColumn(
                label: Text(TranslationHelper.translate(context, h),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark)),
              ),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                for (var i = 0; i < headers.length; i++)
                  DataCell(ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(i < r.length ? r[i] : '-', style: cellStyle),
                    ),
                  )),
              ]),
          ],
        ),
      ),
    );
  }

  /// Label / value list of the proposal's form fields that [include] picks
  /// (labels, values and order come from the detail API's display_fields).
  Future<void> _showFields(dynamic id, String title,
      bool Function(Map field, List<Map> all) include) async {
    final detail = await _mpdaService.fetchProposalDetail(id);
    if (!mounted || detail == null) return;
    final all = ((detail['display_fields'] as List?) ?? const [])
        .whereType<Map>()
        .toList();
    final fields = all.where((f) => include(f, all)).toList();
    await _showInfoDialog(
      title: title,
      proposalNo: detail['proposal_no_and_year']?.toString() ?? '',
      maxWidth: 520,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < fields.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: i.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
                border:
                    const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                        TranslationHelper.translate(
                            context, '${fields[i]['label'] ?? ''}'),
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyDark)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(() {
                      final v = '${fields[i]['value'] ?? ''}'.trim();
                      return v.isEmpty ? '-' : v;
                    }(),
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, color: AppColors.lightText)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showInfoDialog({
    required String title,
    required String proposalNo,
    required double maxWidth,
    required Widget body,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 560),
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
                          if (proposalNo.isNotEmpty)
                            Text(proposalNo,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.white70)),
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
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMpdaCard(Map<String, dynamic> item) {
    final id = item['id'];
    final proposalNo = item['proposal_no_and_year']?.toString() ?? '';
    final accusedName = item['accused_name']?.toString() ?? '';
    final outcome = item['proposal_outcome']?.toString() ?? '';
    final category = item['mpda_category']?.toString() ?? '';
    final detentionDate = item['detention_date_display']?.toString() ?? '';
    final completionDate =
        item['detention_completion_date_display']?.toString() ?? '';
    final jailName = item['jail_name']?.toString() ?? '';

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
                if (proposalNo.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      proposalNo,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                const Spacer(),
                if (outcome.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      outcome,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              accusedName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            if (category.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.lightSubText,
                ),
              ),
            ],
            if (jailName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                jailName,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: AppColors.navyDark,
                ),
              ),
            ],
            if (detentionDate.isNotEmpty || completionDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (detentionDate.isNotEmpty)
                    Text(
                      detentionDate,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.lightSubText,
                      ),
                    ),
                  if (detentionDate.isNotEmpty && completionDate.isNotEmpty)
                    const Text('  -  '),
                  if (completionDate.isNotEmpty)
                    Text(
                      completionDate,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.lightSubText,
                      ),
                    ),
                ],
              ),
            ],
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
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
                  if (editLabel.isNotEmpty)
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
                  if (pdfLabel.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _downloadPdf(id, proposalNo),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
