// lib/screens/rti/rti_hub_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/rti_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/dynamic_form/dynamic_form_screen.dart';
import '../../widgets/module_hub_screen_app_bar.dart';

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

  // Search & Pagination per tab index (0=all, 1=pending, 2=disposal)
  final List<String> _statuses = ['all', 'pending', 'disposal'];
  final Map<int, List<dynamic>> _itemsMap = {0: [], 1: [], 2: []};
  final Map<int, int> _pageMap = {0: 1, 1: 1, 2: 1};
  final Map<int, int> _totalCountMap = {0: 0, 1: 0, 2: 0};
  final Map<int, bool> _loadingMap = {0: true, 1: true, 2: true};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _fetchItemsForTab(0);
    _fetchItemsForTab(1);
    _fetchItemsForTab(2);
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

    final data = await _rtiService.fetchApplications(
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

  void _openViewModal(dynamic rtiId) async {
    final detail = await _rtiService.fetchApplicationDetail(rtiId);
    if (!mounted) return;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load application details.')),
      );
      return;
    }

    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: DynamicFormScreen(
          categoryId: widget.categoryCode,
          moduleLabel: widget.categoryName,
          moduleKey: widget.moduleKey,
          initialData: detail,
          readOnly: true,
        ),
      ),
    );
  }

  void _downloadPdf(dynamic rtiId) async {
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'RTI Report Generated',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'PDF generated successfully (${pdfBytes.length} bytes).',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
          ],
        ),
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
    final labelPending = subTabLabels['pending']?.toString() ?? 'Pending';
    final labelDisposal = subTabLabels['disposal']?.toString() ?? 'Disposal';

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
                      Text(TranslationHelper.translate(context, labelPending)),
                      const SizedBox(width: 6),
                      _buildCountBadge(
                          _counts['pending'] ?? 0, Colors.amber.shade800),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(TranslationHelper.translate(context, labelDisposal)),
                      const SizedBox(width: 6),
                      _buildCountBadge(
                          _counts['disposal'] ?? 0, AppColors.successGreen),
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
                _buildTabListContent(0),
                _buildTabListContent(1),
                _buildTabListContent(2),
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
              return _buildRTIApplicationCard(item);
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

  Widget _buildRTIApplicationCard(Map<String, dynamic> item) {
    final rtiId = item['rti_id'];
    final serialDisplay = item['serial_display']?.toString() ?? '-';
    final applicantName = item['applicant_name']?.toString() ?? '-';
    final receivedDate = item['received_date']?.toString() ?? '-';
    final dueDate = item['due_date']?.toString() ?? '-';
    final status = item['status']?.toString() ?? 'Pending';

    final serialLabel = _config['serial_label']?.toString() ?? 'Sr. No.';
    final actionLabels = (_config['row_action_labels'] as Map?) ?? {};
    final editLabel = actionLabels['edit']?.toString() ?? 'Edit';
    final viewLabel = actionLabels['view']?.toString() ?? 'View';
    final pdfLabel = actionLabels['pdf']?.toString() ?? 'PDF';

    final isDisposal = status.toLowerCase() == 'disposal';
    final statusColor =
        isDisposal ? AppColors.successGreen : Colors.amber.shade800;

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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.navyDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$serialLabel $serialDisplay',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    TranslationHelper.translate(context, status),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              applicantName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Received: $receivedDate',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppColors.lightSubText,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Due: $dueDate',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppColors.lightSubText,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openViewModal(rtiId),
                  icon: const Icon(Icons.visibility_rounded, size: 14),
                  label: Text(
                    TranslationHelper.translate(context, viewLabel),
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _openEditModal(rtiId),
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: Text(
                    TranslationHelper.translate(context, editLabel),
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _downloadPdf(rtiId),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                  label: Text(
                    TranslationHelper.translate(context, pdfLabel),
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
