// lib/modules/pvr/screens/pvr_hub_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../core/models/base_record.dart';
import '../providers/pvr_provider.dart';
import '../widgets/pvr_status_cards.dart';
import '../widgets/pvr_add_edit_dialog.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/case_visibility.dart';
import '../../../utils/dynamic_map_pdf.dart';
import '../../../utils/excel_export_helper.dart';
import '../../../utils/pdf_unicode_fonts.dart';
import '../../../utils/translation_helper.dart';
import '../../../widgets/module_hub_screen_app_bar.dart';

class PvrGroup {
  final DateTime date;
  final String label;
  final int verifiedCount;
  final int pendingCount;
  final List<ModuleRecord> records;

  PvrGroup({
    required this.date,
    required this.label,
    required this.verifiedCount,
    required this.pendingCount,
    required this.records,
  });

  ModuleRecord get primaryRecord => records.first;
  int get totalCount => verifiedCount + pendingCount;
}

class PvrHubScreen extends StatefulWidget {
  final String stationName;

  const PvrHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<PvrHubScreen> createState() => _PvrHubScreenState();
}

class _PvrHubScreenState extends State<PvrHubScreen> {
  PvrStatusFilter _selectedFilter = PvrStatusFilter.totalReceived;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  DateTimeRange? _selectedDateRange;
  String? _datePresetLabel;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final pvrProv = context.read<PvrProvider>();
      pvrProv.setStationContext(
        stationId:
            auth.stationName.isNotEmpty ? auth.stationName : widget.stationName,
        uid: auth.uid,
        visibilityMode: CaseVisibilityMode.stationWide,
      );
      pvrProv.ensureInitialized(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Date Filter Helpers ───────────────────────────────────────────────────

  void _applyDatePreset(String label, DateTimeRange? range) {
    setState(() {
      _datePresetLabel = range == null ? null : label;
      _selectedDateRange = range;
    });
  }

  void _clearDateFilter() {
    setState(() {
      _datePresetLabel = null;
      _selectedDateRange = null;
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyMid,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final fmt = DateFormat('dd/MM/yyyy');
      final label = '${fmt.format(picked.start)} - ${fmt.format(picked.end)}';
      _applyDatePreset(label, picked);
    }
  }

  // ── Monthly Grouping & Filtering ──────────────────────────────────────────

  List<PvrGroup> _filterGroups(List<ModuleRecord> allRecords) {
    final Map<String, List<ModuleRecord>> map = {};

    for (final r in allRecords) {
      final date = r.incidentDate;
      final key = DateFormat('yyyy-MM').format(date);
      map.putIfAbsent(key, () => []).add(r);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    List<PvrGroup> groups = [];
    for (final key in sortedKeys) {
      final list = map[key]!;
      int v = 0;
      int p = 0;
      for (final r in list) {
        v += PvrProvider.getRecordVerifiedCount(r);
        p += PvrProvider.getRecordPendingCount(r);
      }
      final date = list.first.incidentDate;
      final label = DateFormat('MMMM yyyy').format(date);

      groups.add(PvrGroup(
        date: date,
        label: label,
        verifiedCount: v,
        pendingCount: p,
        records: list,
      ));
    }

    // 1. Status Filter
    if (_selectedFilter == PvrStatusFilter.verified) {
      groups = groups.where((g) => g.verifiedCount > 0).toList();
    } else if (_selectedFilter == PvrStatusFilter.pending) {
      groups = groups.where((g) => g.pendingCount > 0).toList();
    }

    // 2. Search Query (matches month label)
    if (_searchQuery.isNotEmpty) {
      groups = groups.where((g) {
        return g.label.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // 3. Date Filter
    if (_selectedDateRange != null) {
      final start = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
      );
      final end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );
      groups = groups.where((g) {
        final monthStart = DateTime(g.date.year, g.date.month, 1);
        final monthEnd = DateTime(g.date.year, g.date.month + 1, 0, 23, 59, 59);
        return !monthStart.isAfter(end) && !monthEnd.isBefore(start);
      }).toList();
    }

    return groups;
  }

  // ── Exports ───────────────────────────────────────────────────────────────

  void _exportExcel(List<PvrGroup> dataset) {
    if (dataset.isEmpty) return;
    final rows = dataset.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final g = entry.value;
      return [
        '$i',
        g.label,
        '${g.totalCount}',
        '${g.verifiedCount}',
        '${g.pendingCount}',
      ];
    }).toList();

    ExcelExportHelper.exportTableToCsv(
      headers: const ['Sr. No.', 'Month', 'Total', 'Verified', 'Pending'],
      rows: rows,
      filename:
          'PVR_MonthWise_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PVR records exported to Excel successfully.'),
        backgroundColor: Color(0xFF107C41),
      ),
    );
  }

  Future<void> _exportPdf(List<PvrGroup> dataset) async {
    if (dataset.isEmpty) return;
    final theme = await PdfUnicodeFonts.openSansTheme();

    final showTotal = _selectedFilter == PvrStatusFilter.totalReceived;
    final showVerified = _selectedFilter != PvrStatusFilter.pending;
    final showPending = _selectedFilter != PvrStatusFilter.verified;

    final rows = dataset.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final g = entry.value;

      final row = <String, String>{
        'Sr. No.': '$i',
        'Month': g.label,
      };
      if (showTotal) row['Total'] = '${g.totalCount}';
      if (showVerified) row['Verified'] = '${g.verifiedCount}';
      if (showPending) row['Pending'] = '${g.pendingCount}';
      return row;
    }).toList();

    final columnOrder = [
      'Sr. No.',
      'Month',
      if (showTotal) 'Total',
      if (showVerified) 'Verified',
      if (showPending) 'Pending',
    ];

    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'PVR (Police Verification Report) — ${widget.stationName}',
      rows: rows,
      prependSerial: false,
      columnOrder: columnOrder,
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'PVR_Verification_MonthWise.pdf',
    );
  }

  // ── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PvrProvider>();
    final allRecords = provider.records;

    final totalReceivedCount = provider.totalReceivedCount;
    final verifiedCount = provider.verifiedCount;
    final pendingCount = provider.pendingCount;

    final visibleGroups = _filterGroups(allRecords);

    final transFilterLabel = switch (_selectedFilter) {
      PvrStatusFilter.totalReceived =>
        TranslationHelper.translate(context, 'Total'),
      PvrStatusFilter.verified =>
        TranslationHelper.translate(context, 'Verified'),
      PvrStatusFilter.pending =>
        TranslationHelper.translate(context, 'Pending'),
    };

    final countLabel = visibleGroups.length == 1
        ? '1 ${TranslationHelper.translate(context, 'Month')}'
        : '${visibleGroups.length} ${TranslationHelper.translate(context, 'Months')}';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, 'PVR'),
        subtitle: '${widget.stationName} • $countLabel ($transFilterLabel)',
        actionWidget: ElevatedButton.icon(
          onPressed: () => PvrAddEditDialog.show(context, provider: provider),
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
            TranslationHelper.translate(context, 'Add PVR Entry'),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Metric Cards (Total, Verified, Pending)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: PvrStatusCards(
              selectedFilter: _selectedFilter,
              totalReceivedCount: totalReceivedCount,
              verifiedCount: verifiedCount,
              pendingCount: pendingCount,
              onFilterChanged: (filter) {
                setState(() => _selectedFilter = filter);
              },
            ),
          ),

          // 2. Secondary Filter & Actions Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, filterConstraints) {
                final isNarrow = filterConstraints.maxWidth < 620;

                final searchWidget = SizedBox(
                  width: isNarrow ? 170.0 : null,
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, color: AppColors.navyDark),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      hintText: TranslationHelper.translate(
                        context,
                        'Search...',
                      ),
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.lightSubText.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: AppColors.navyMid),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? InkWell(
                              onTap: _searchCtrl.clear,
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.lightSubText),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF3B82F6), width: 1.5),
                      ),
                    ),
                  ),
                );

                final actionWidgets = [
                  const SizedBox(width: 8),
                  _buildDateFilterMenu(context),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: TranslationHelper.translate(context, 'Export PDF'),
                    onPressed: visibleGroups.isNotEmpty
                        ? () => _exportPdf(visibleGroups)
                        : null,
                    icon: const Icon(Icons.picture_as_pdf_outlined,
                        color: Color(0xFFDC2626), size: 20),
                  ),
                  IconButton(
                    tooltip:
                        TranslationHelper.translate(context, 'Export Excel'),
                    onPressed: visibleGroups.isNotEmpty
                        ? () => _exportExcel(visibleGroups)
                        : null,
                    icon: const Icon(Icons.table_chart_outlined,
                        color: Color(0xFF16A34A), size: 20),
                  ),
                ];

                if (isNarrow) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        searchWidget,
                        ...actionWidgets,
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchWidget),
                    ...actionWidgets,
                  ],
                );
              },
            ),
          ),

          // 3. Main Data Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => provider.refresh(),
              color: AppColors.navyMid,
              child: !provider.hasFetched && allRecords.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.navyMid),
                    )
                  : allRecords.isEmpty
                      ? _buildEmptyState(context, provider)
                      : visibleGroups.isEmpty
                          ? _buildNoFilterMatchState(context)
                          : _buildTable(context, visibleGroups, provider),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => PvrAddEditDialog.show(context, provider: provider),
        backgroundColor: AppColors.navyMid,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          TranslationHelper.translate(context, 'Add PVR Entry'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterMenu(BuildContext context) {
    final hasFilter = _selectedDateRange != null;
    final now = DateTime.now();

    return PopupMenuButton<String>(
      tooltip: TranslationHelper.translate(context, 'Filter by Date'),
      onSelected: (val) {
        switch (val) {
          case 'all':
            _clearDateFilter();
            break;
          case 'under_1_month':
            _applyDatePreset(
              'Under 1 month',
              DateTimeRange(
                start: now.subtract(const Duration(days: 30)),
                end: now,
              ),
            );
            break;
          case '1_to_3_months':
            _applyDatePreset(
              '1 to 3 months',
              DateTimeRange(
                start: now.subtract(const Duration(days: 90)),
                end: now.subtract(const Duration(days: 30)),
              ),
            );
            break;
          case '3_to_6_months':
            _applyDatePreset(
              '3 to 6 months',
              DateTimeRange(
                start: now.subtract(const Duration(days: 180)),
                end: now.subtract(const Duration(days: 90)),
              ),
            );
            break;
          case '6_to_12_months':
            _applyDatePreset(
              '6 to 12 months',
              DateTimeRange(
                start: now.subtract(const Duration(days: 365)),
                end: now.subtract(const Duration(days: 180)),
              ),
            );
            break;
          case 'more_than_1_year':
            _applyDatePreset(
              'More than 1 year',
              DateTimeRange(
                start: DateTime(2000),
                end: now.subtract(const Duration(days: 365)),
              ),
            );
            break;
          case 'under_3_months_total':
            _applyDatePreset(
              'Under 3 months (Total)',
              DateTimeRange(
                start: now.subtract(const Duration(days: 90)),
                end: now,
              ),
            );
            break;
          case 'custom':
            _pickCustomDateRange();
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'all',
          child: Row(
            children: [
              Icon(
                _selectedDateRange == null
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 16,
                color: _selectedDateRange == null
                    ? AppColors.navyMid
                    : AppColors.lightSubText,
              ),
              const SizedBox(width: 8),
              Text(
                TranslationHelper.translate(ctx, 'All Dates'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: _selectedDateRange == null
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        _buildDateMenuItem(
          ctx,
          value: 'under_1_month',
          label: 'Under 1 month',
        ),
        _buildDateMenuItem(
          ctx,
          value: '1_to_3_months',
          label: '1 to 3 months',
        ),
        _buildDateMenuItem(
          ctx,
          value: '3_to_6_months',
          label: '3 to 6 months',
        ),
        _buildDateMenuItem(
          ctx,
          value: '6_to_12_months',
          label: '6 to 12 months',
        ),
        _buildDateMenuItem(
          ctx,
          value: 'more_than_1_year',
          label: 'More than 1 year',
        ),
        _buildDateMenuItem(
          ctx,
          value: 'under_3_months_total',
          label: 'Under 3 months (Total)',
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'custom',
          child: Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                size: 16,
                color: AppColors.navyMid,
              ),
              const SizedBox(width: 8),
              Text(
                TranslationHelper.translate(ctx, 'Custom Date Range...'),
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyMid,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasFilter ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFilter ? const Color(0xFF3B82F6) : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color:
                  hasFilter ? const Color(0xFF1E40AF) : AppColors.lightSubText,
            ),
            const SizedBox(width: 8),
            Text(
              _datePresetLabel ??
                  TranslationHelper.translate(context, 'Date Filter'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                color: hasFilter ? const Color(0xFF1E40AF) : AppColors.navyDark,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: _clearDateFilter,
                child: const Icon(Icons.close_rounded,
                    size: 15, color: Color(0xFFDC2626)),
              ),
            ] else ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded,
                  size: 20, color: AppColors.lightSubText),
            ],
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildDateMenuItem(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    final isSelected = _datePresetLabel == label;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isSelected ? AppColors.navyMid : AppColors.lightSubText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              TranslationHelper.translate(context, label),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, PvrProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(
                Icons.fact_check_rounded,
                size: 38,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              TranslationHelper.translate(context, 'No PVR Records Found'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              TranslationHelper.translate(
                context,
                'Start by adding a new PVR verification record.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  PvrAddEditDialog.show(context, provider: provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                TranslationHelper.translate(context, 'Add PVR Entry'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterMatchState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.lightSubText),
            const SizedBox(height: 12),
            Text(
              TranslationHelper.translate(context, 'No matching PVR records'),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              TranslationHelper.translate(
                context,
                'Try clearing your search term or active date range filter.',
              ),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _clearDateFilter();
                setState(() => _selectedFilter = PvrStatusFilter.totalReceived);
              },
              child: Text(
                TranslationHelper.translate(context, 'Reset All Filters'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Data Table View ───────────────────────────────────────────────────────

  Widget _buildTable(
      BuildContext context, List<PvrGroup> groups, PvrProvider provider) {
    final showTotal = _selectedFilter == PvrStatusFilter.totalReceived;
    final showVerified = _selectedFilter != PvrStatusFilter.pending;
    final showPending = _selectedFilter != PvrStatusFilter.verified;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = math.max(450.0, constraints.maxWidth - 32);

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: tableMinWidth,
                    ),
                    child: DataTable(
                      showCheckboxColumn: false,
                      columnSpacing: 28,
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingTextStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 64,
                      dataTextStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.navyDark,
                      ),
                      columns: [
                        DataColumn(
                          label:
                              Text(TranslationHelper.translate(context, 'Sr.')),
                        ),
                        DataColumn(
                          label: Text(
                            TranslationHelper.translate(context, 'Month'),
                          ),
                        ),
                        if (showTotal)
                          DataColumn(
                            label: Text(
                                TranslationHelper.translate(context, 'Total')),
                          ),
                        if (showVerified)
                          DataColumn(
                            label: Text(TranslationHelper.translate(
                                context, 'Verified')),
                          ),
                        if (showPending)
                          DataColumn(
                            label: Text(TranslationHelper.translate(
                                context, 'Pending')),
                          ),
                      ],
                      rows: groups.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final g = entry.value;

                        return DataRow(
                          onSelectChanged: (_) {
                            PvrAddEditDialog.show(
                              context,
                              existingRecord: g.primaryRecord,
                              groupedRecords: g.records,
                              initialVerified: g.verifiedCount,
                              initialPending: g.pendingCount,
                              provider: provider,
                            );
                          },
                          cells: [
                            DataCell(
                              Text(
                                '$idx',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 15,
                                    color: AppColors.navyMid,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('MMMM').format(g.date),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                      Text(
                                        '${g.date.year}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.lightSubText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (showTotal)
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.inventory_2_outlined,
                                          size: 14, color: Color(0xFF1D4ED8)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${g.totalCount}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (showVerified)
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          size: 14, color: Color(0xFF047857)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${g.verifiedCount}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (showPending)
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.hourglass_top_rounded,
                                          size: 14, color: Color(0xFFD97706)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${g.pendingCount}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
