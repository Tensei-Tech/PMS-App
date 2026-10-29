// lib/screens/rti/rti_hub_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/rti_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/dynamic_form/dynamic_form_screen.dart';
import '../../widgets/custom_pdf_preview_dialog.dart';
import '../../widgets/module_hub_screen_app_bar.dart';
import '../../widgets/pdf_document_view_screen.dart';

class RTIHubScreen extends StatefulWidget {
  final String categoryName;
  final String categoryCode;
  final String moduleKey;

  const RTIHubScreen({
    super.key,
    required this.categoryName,
    required this.categoryCode,
    required this.moduleKey,
  });

  @override
  State<RTIHubScreen> createState() => _RTIHubScreenState();
}

class _RTIHubScreenState extends State<RTIHubScreen>
    with SingleTickerProviderStateMixin {
  final RtiService _rtiService = RtiService();
  late TabController _tabController;

  Map<String, dynamic> _config = {};
  Map<String, dynamic> _counts = {'total': 0, 'pending': 0, 'disposal': 0};

  // Search & Pagination per tab index (0=all, 1=summary chart)
  final List<String> _statuses = ['all', 'chart'];
  static const String _chartTab = 'chart';
  final Map<int, List<dynamic>> _itemsMap = {0: [], 1: []};
  final Map<int, int> _pageMap = {0: 1, 1: 1};
  final Map<int, int> _totalCountMap = {0: 0, 1: 0};
  final Map<int, bool> _loadingMap = {0: true, 1: true};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
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
    _fetchItemsForTab(_tabController.index);
  }

  Future<void> _initializeData() async {
    final config = await _rtiService.fetchConfig();
    final counts = await _rtiService.fetchCounts();
    if (!mounted) return;
    setState(() {
      _config = config;
      _counts = counts;
    });
    for (int i = 0; i < _statuses.length; i++) {
      _fetchItemsForTab(i);
    }
  }

  Future<void> _refreshCounts() async {
    final counts = await _rtiService.fetchCounts();
    if (!mounted) return;
    setState(() {
      _counts = counts;
    });
  }

  Future<void> _fetchItemsForTab(int tabIndex, {int? page}) async {
    final status = _statuses[tabIndex];
    final currentPage = page ?? _pageMap[tabIndex] ?? 1;

    setState(() {
      _loadingMap[tabIndex] = true;
    });

    final data = status == _chartTab
        ? await _rtiService.fetchChart(page: currentPage, q: _searchQuery)
        : await _rtiService.fetchApplications(
            status: status,
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

  void _openAddModal() async {
    final result = await Navigator.push<bool>(
      context,
      AppTheme.fadeSlideRoute(
        page: DynamicFormScreen(
          categoryId: widget.categoryCode,
          moduleLabel: widget.categoryName,
          moduleKey: widget.moduleKey,
          dateOffsetRules: _config['date_offset_rules'] as List?,
          onSubmitCustom: (payload, isEdit) async {
            final res = await _rtiService.createApplication(payload);
            if (res.isSuccess) {
              return null;
            }
            return {
              'error': res.errorMessage ?? 'Failed to create application.'
            };
          },
        ),
      ),
    );

    if (result == true) {
      await _refreshCounts();
      _fetchItemsForTab(_tabController.index, page: 1);
    }
  }

  void _openEditModal(dynamic rtiId) async {
    final detail = await _rtiService.fetchApplicationDetail(rtiId);
    if (!mounted) return;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load application details.')),
      );
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
          dateOffsetRules: _config['date_offset_rules'] as List?,
          onSubmitCustom: (payload, isEdit) async {
            final res = await _rtiService.updateApplication(rtiId, payload);
            if (res.isSuccess) {
              return null;
            }
            return {
              'error': res.errorMessage ?? 'Failed to update application.'
            };
          },
        ),
      ),
    );

    if (result == true) {
      await _refreshCounts();
      _fetchItemsForTab(_tabController.index);
    }
  }

  /// View shows the application exactly as its PDF looks, read-only.
  void _openViewModal(dynamic rtiId) async {
    final pdfBytes = await _rtiService.fetchPdfBytes(rtiId);
    if (!mounted) return;
    if (pdfBytes == null || pdfBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load application details.')),
      );
      return;
    }
    PdfDocumentViewScreen.open(context,
        pdfBytes: pdfBytes, moduleName: widget.categoryName);
  }

  void _downloadPdf(dynamic rtiId, [String? serial]) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generating RTI PDF report...',
          style: GoogleFonts.poppins(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final pdfBytes = await _rtiService.fetchPdfBytes(rtiId);
    if (!mounted) return;

    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      final docTitle = [widget.categoryName, serial ?? '']
          .where((x) => x.isNotEmpty && x != '-')
          .join(' - ');
      await CustomPdfPreviewDialog.show(
        context: context,
        title: docTitle,
        fileName: '${docTitle.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.pdf',
        buildPdf: (_) async => pdfBytes,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to generate PDF report.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subTabLabels = (_config['sub_tab_labels'] as Map?) ?? {};
    final labelAll = subTabLabels['all']?.toString() ?? 'Total';
    final labelChart = subTabLabels['chart']?.toString() ?? '';

    final addButtonLabel =
        _config['add_button_label']?.toString() ?? 'Add RTI Application';

    final actionWidget = ElevatedButton.icon(
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
        TranslationHelper.translate(context, addButtonLabel),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, widget.categoryName),
        subtitle: '${_counts['total'] ?? 0} Applications Registered',
        actionWidget: actionWidget,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // Tab Bar with Dynamic Labels & Counts
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.navyMid,
              indicatorWeight: 3,
              labelColor: AppColors.navyDark,
              unselectedLabelColor: AppColors.lightSubText,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(TranslationHelper.translate(context, labelAll)),
                      const SizedBox(width: 6),
                      _buildCountBadge(
                          _counts['total'] ?? 0, AppColors.navyDark),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_chart_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(TranslationHelper.translate(context, labelChart)),
                    ],
                  ),
                ),
              ],
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
                  'Search by Sr. No. or Applicant Name...',
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

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (int i = 0; i < _statuses.length; i++)
                  _buildTabListContent(i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
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

    final emptyMsg = _config['empty_list_message']?.toString() ??
        'No RTI applications found';

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
              final displayIndex = (currentPage - 1) * pageSize + i + 1;
              return _statuses[tabIndex] == _chartTab
                  ? _buildRTISummaryCard(item, displayIndex)
                  : _buildRTIApplicationCard(item, displayIndex);
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
                'Page $currentPage of $maxPage ($total total)',
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

  /// Summary "Send Reminder": notify the assigned officer now.
  Future<void> _sendReminder(dynamic rtiId) async {
    final res = await _rtiService.sendReminder(rtiId);
    if (!mounted) return;
    final data = res.data is Map ? res.data as Map : const {};
    final message = res.isSuccess
        ? data['message']?.toString() ?? ''
        : (data['error']?.toString() ?? res.errorMessage ?? '');
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor:
            res.isSuccess ? AppColors.successGreen : AppColors.dangerRed,
      ),
    );
  }

  /// Popup with only one cell's information (column header + value).
  void _showChartCellInfo(String header, String value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          TranslationHelper.translate(context, header),
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark),
        ),
        content: SelectableText(
          value,
          style: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.navyDark),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
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
              Icon(icon,
                  size: 11.5, color: iconColor ?? const Color(0xFF64748B)),
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

  Widget _buildSendReminderButton({
    required BuildContext context,
    required VoidCallback onTap,
    String? label,
  }) {
    return _buildLabeledActionButton(
      context: context,
      icon: Icons.notifications_active_outlined,
      label: 'Remind',
      color: AppColors.navyDark,
      onTap: onTap,
    );
  }

  Widget _buildLabeledActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final fgColor = color ?? const Color(0xFF1E293B);
    return Tooltip(
      message: TranslationHelper.translate(context, label),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 38,
          width: 38,
          padding: const EdgeInsets.symmetric(vertical: 2),
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
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(height: 1.5),
              Text(
                TranslationHelper.translate(context, label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dedicated horizontal single-row case card for RTI Summary (matching Preventive module UI)
  Widget _buildRTISummaryCard(Map<String, dynamic> item, int index) {
    final rtiId = item['rti_id'];
    final srNo = (item['sr_no'] ?? '-').toString().trim();
    final person = (item['person'] ?? '-').toString().trim();
    final receivedDate = (item['received_date'] ?? '-').toString().trim();
    final dueDate = (item['due_date'] ?? '-').toString().trim();
    final infoType = (item['info_type'] ?? '-').toString().trim();
    final assignedOfficer = (item['assigned_officer'] ?? '-').toString().trim();
    final infoGiven = (item['info_given'] ?? '-').toString().trim();

    final isReplied = infoGiven.toLowerCase().contains('replied');
    final isTransferred = infoGiven.toLowerCase().contains('transferred');
    final isRejected = infoGiven.toLowerCase().contains('rejected');

    final Color statusColor;
    final Color statusBg;
    final Color statusBorder;
    final String statusText;

    if (isReplied) {
      statusColor = const Color(0xFF2E7D32);
      statusBg = const Color(0xFFE8F5E9);
      statusBorder = const Color(0xFFA5D6A7);
      statusText = infoGiven.isNotEmpty ? infoGiven : 'Replied';
    } else if (isTransferred) {
      statusColor = const Color(0xFF0284C7);
      statusBg = const Color(0xFFE0F2FE);
      statusBorder = const Color(0xFFBAE6FD);
      statusText = 'Transferred';
    } else if (isRejected) {
      statusColor = const Color(0xFFD32F2F);
      statusBg = const Color(0xFFFFEBEE);
      statusBorder = const Color(0xFFFFCDD2);
      statusText = 'Rejected';
    } else {
      statusColor = const Color(0xFFD32F2F);
      statusBg = const Color(0xFFFFEBEE);
      statusBorder = const Color(0xFFFFCDD2);
      statusText = 'Pending';
    }

    final headers = (_config['chart_headers'] as Map?) ?? {};
    final rowActionLabels = (_config['row_action_labels'] as Map?) ?? {};
    final editLabel = rowActionLabels['edit']?.toString() ?? 'Edit';
    final viewLabel = rowActionLabels['view']?.toString() ?? 'View';
    final pdfLabel = rowActionLabels['pdf']?.toString() ?? 'PDF';
    final remindLabel =
        rowActionLabels['remind']?.toString() ?? 'Send Reminder';

    Widget buildDetailsRow(bool isExpandedMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 0. Sr. No. Badge (Fixed width 46) - Neutral slate styling
          Container(
            height: 38,
            width: 46,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sr.No',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$index',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 1. RTI No. Badge (Fixed width 95)
          InkWell(
            onTap: () => _openViewModal(rtiId),
            borderRadius: BorderRadius.circular(6),
            child: Tooltip(
              message:
                  TranslationHelper.translate(context, 'Click to see info'),
              child: Container(
                height: 38,
                width: 95,
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
                      'RTI No.',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      srNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildDivider(),

          // 2. Type of Information (flex: 3)
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Type of Info',
                    value:
                        (infoType.isEmpty || infoType == '-') ? '—' : infoType,
                    icon: Icons.info_outline_rounded,
                    onTap: (infoType.isEmpty || infoType == '-')
                        ? null
                        : () => _showChartCellInfo(
                            headers['info_type']?.toString() ??
                                'Type of Information',
                            infoType),
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 140,
                  label: 'Type of Info',
                  value: (infoType.isEmpty || infoType == '-') ? '—' : infoType,
                  icon: Icons.info_outline_rounded,
                  onTap: (infoType.isEmpty || infoType == '-')
                      ? null
                      : () => _showChartCellInfo(
                          headers['info_type']?.toString() ??
                              'Type of Information',
                          infoType),
                ),

          _buildDivider(),

          // 3. Person / Applicant Name, Age, Mobile, Address (flex: 4)
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Applicant Details',
                    value: (person.isEmpty || person == '-') ? '—' : person,
                    icon: Icons.person_outline_rounded,
                    onTap: (person.isEmpty || person == '-')
                        ? null
                        : () => _showChartCellInfo(
                            headers['person']?.toString() ??
                                'Name, Age, Mobile No., Address',
                            person),
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 220,
                  label: 'Applicant Details',
                  value: (person.isEmpty || person == '-') ? '—' : person,
                  icon: Icons.person_outline_rounded,
                  onTap: (person.isEmpty || person == '-')
                      ? null
                      : () => _showChartCellInfo(
                          headers['person']?.toString() ??
                              'Name, Age, Mobile No., Address',
                          person),
                ),

          _buildDivider(),

          // 4. Received Date (flex: 2)
          isExpandedMode
              ? Expanded(
                  flex: 2,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Received Date',
                    value: (receivedDate.isEmpty || receivedDate == '-')
                        ? '—'
                        : receivedDate,
                    icon: Icons.calendar_today_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 110,
                  label: 'Received Date',
                  value: (receivedDate.isEmpty || receivedDate == '-')
                      ? '—'
                      : receivedDate,
                  icon: Icons.calendar_today_outlined,
                ),

          _buildDivider(),

          // 5. Due Date (flex: 2)
          isExpandedMode
              ? Expanded(
                  flex: 2,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Due Date',
                    value: (dueDate.isEmpty || dueDate == '-') ? '—' : dueDate,
                    icon: Icons.event_available_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 105,
                  label: 'Due Date',
                  value: (dueDate.isEmpty || dueDate == '-') ? '—' : dueDate,
                  icon: Icons.event_available_outlined,
                ),

          _buildDivider(),

          // 6. Assigned Officer (flex: 3)
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Assigned Officer',
                    value: (assignedOfficer.isEmpty || assignedOfficer == '-')
                        ? '—'
                        : assignedOfficer,
                    icon: Icons.badge_outlined,
                    onTap: (assignedOfficer.isEmpty || assignedOfficer == '-')
                        ? null
                        : () => _showChartCellInfo(
                            headers['assigned_officer']?.toString() ??
                                'Assigned Officer',
                            assignedOfficer),
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 160,
                  label: 'Assigned Officer',
                  value: (assignedOfficer.isEmpty || assignedOfficer == '-')
                      ? '—'
                      : assignedOfficer,
                  icon: Icons.badge_outlined,
                  onTap: (assignedOfficer.isEmpty || assignedOfficer == '-')
                      ? null
                      : () => _showChartCellInfo(
                          headers['assigned_officer']?.toString() ??
                              'Assigned Officer',
                          assignedOfficer),
                ),

          _buildDivider(),

          // 7. Status / Information Given Badge (Fixed width 110)
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
          if (remindLabel.isNotEmpty) ...[
            _buildSendReminderButton(
              context: context,
              label: remindLabel,
              onTap: () => _sendReminder(rtiId),
            ),
            const SizedBox(width: 6),
          ],
          _buildLabeledActionButton(
            context: context,
            icon: Icons.edit_outlined,
            label: editLabel,
            color: AppColors.navyDark,
            onTap: () => _openEditModal(rtiId),
          ),
          const SizedBox(width: 6),
          _buildLabeledActionButton(
            context: context,
            icon: Icons.visibility_outlined,
            label: viewLabel,
            color: AppColors.navyDark,
            onTap: () => _openViewModal(rtiId),
          ),
          const SizedBox(width: 6),
          _buildLabeledActionButton(
            context: context,
            icon: Icons.picture_as_pdf_outlined,
            label: pdfLabel,
            color: AppColors.navyDark,
            onTap: () => _downloadPdf(rtiId, srNo),
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
                final isWide = constraints.maxWidth >= 1050;
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

          // Divider between scrollable details and fixed actions
          _buildDivider(),

          // 2. Fixed action buttons
          buildActionButtons(),
        ],
      ),
    );
  }

  /// Dedicated horizontal single-row case card for RTI Applications list (Total tab)
  Widget _buildRTIApplicationCard(Map<String, dynamic> item, int index) {
    final rtiId = item['rti_id'];
    final serialDisplay = (item['serial_display'] ?? '-').toString().trim();
    final applicantName = (item['applicant_name'] ?? '-').toString().trim();
    final receivedDate = (item['received_date'] ?? '-').toString().trim();
    final dueDate = (item['due_date'] ?? '-').toString().trim();
    final infoType = (item['info_type'] ?? '-').toString().trim();
    final status = (item['status'] ?? 'Pending').toString().trim();

    final actionLabels = (_config['row_action_labels'] as Map?) ?? {};
    final editLabel = actionLabels['edit']?.toString() ?? 'Edit';
    final viewLabel = actionLabels['view']?.toString() ?? 'View';
    final pdfLabel = actionLabels['pdf']?.toString() ?? 'PDF';

    final isDisposal = status.toLowerCase() == 'disposal' ||
        status.toLowerCase() == 'closed' ||
        status.toLowerCase() == 'resolved';
    final Color statusColor =
        isDisposal ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final Color statusBg =
        isDisposal ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final Color statusBorder =
        isDisposal ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2);

    Widget buildDetailsRow(bool isExpandedMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 0. Sr. No. Badge (Fixed width 46) - Neutral slate styling
          Container(
            height: 38,
            width: 46,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sr.No',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$index',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 1. RTI No. Badge (Fixed width 95)
          InkWell(
            onTap: () => _openViewModal(rtiId),
            borderRadius: BorderRadius.circular(6),
            child: Tooltip(
              message:
                  TranslationHelper.translate(context, 'Click to see info'),
              child: Container(
                height: 38,
                width: 95,
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
                      'RTI No.',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serialDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildDivider(),

          // 2. Type of Info (Fixed width 140)
          isExpandedMode
              ? Expanded(
                  flex: 3,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Type of Info',
                    value:
                        (infoType.isEmpty || infoType == '-') ? '—' : infoType,
                    icon: Icons.info_outline_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 140,
                  label: 'Type of Info',
                  value: (infoType.isEmpty || infoType == '-') ? '—' : infoType,
                  icon: Icons.info_outline_rounded,
                ),

          _buildDivider(),

          // 3. Applicant Name (flex: 4)
          isExpandedMode
              ? Expanded(
                  flex: 4,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Applicant Name',
                    value: (applicantName.isEmpty || applicantName == '-')
                        ? '—'
                        : applicantName,
                    icon: Icons.person_outline_rounded,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 200,
                  label: 'Applicant Name',
                  value: (applicantName.isEmpty || applicantName == '-')
                      ? '—'
                      : applicantName,
                  icon: Icons.person_outline_rounded,
                ),

          _buildDivider(),

          // 4. Received Date (flex: 2)
          isExpandedMode
              ? Expanded(
                  flex: 2,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Received Date',
                    value: (receivedDate.isEmpty || receivedDate == '-')
                        ? '—'
                        : receivedDate,
                    icon: Icons.calendar_today_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 110,
                  label: 'Received Date',
                  value: (receivedDate.isEmpty || receivedDate == '-')
                      ? '—'
                      : receivedDate,
                  icon: Icons.calendar_today_outlined,
                ),

          _buildDivider(),

          // 5. Due Date (flex: 2)
          isExpandedMode
              ? Expanded(
                  flex: 2,
                  child: _buildFieldColumn(
                    context: context,
                    label: 'Due Date',
                    value: (dueDate.isEmpty || dueDate == '-') ? '—' : dueDate,
                    icon: Icons.event_available_outlined,
                  ),
                )
              : _buildFieldColumn(
                  context: context,
                  width: 105,
                  label: 'Due Date',
                  value: (dueDate.isEmpty || dueDate == '-') ? '—' : dueDate,
                  icon: Icons.event_available_outlined,
                ),

          _buildDivider(),

          // 6. Status Badge (Fixed width 110)
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
                    message: status,
                    child: Text(
                      TranslationHelper.translate(context, status),
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
          _buildLabeledActionButton(
            context: context,
            icon: Icons.edit_outlined,
            label: editLabel,
            color: AppColors.navyDark,
            onTap: () => _openEditModal(rtiId),
          ),
          const SizedBox(width: 6),
          _buildLabeledActionButton(
            context: context,
            icon: Icons.visibility_outlined,
            label: viewLabel,
            color: AppColors.navyDark,
            onTap: () => _openViewModal(rtiId),
          ),
          const SizedBox(width: 6),
          _buildLabeledActionButton(
            context: context,
            icon: Icons.picture_as_pdf_outlined,
            label: pdfLabel,
            color: AppColors.navyDark,
            onTap: () => _downloadPdf(rtiId, serialDisplay),
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
                final isWide = constraints.maxWidth >= 860;
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

          // Divider between scrollable details and fixed actions
          _buildDivider(),

          // 2. Fixed 3 Action Buttons (Edit, View, PDF)
          buildActionButtons(),
        ],
      ),
    );
  }
}
