// lib/modules/passport/screens/passport_hub_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../core/models/base_record.dart';
import '../providers/passport_provider.dart';
import '../widgets/passport_status_cards.dart';
import '../widgets/passport_add_edit_dialog.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/case_visibility.dart';
import '../../../utils/dynamic_map_pdf.dart';
import '../../../utils/pdf_unicode_fonts.dart';
import '../../../utils/translation_helper.dart';
import '../../../widgets/module_hub_screen_app_bar.dart';

class PassportDateGroup {
  final DateTime date;
  final int verifiedCount;
  final int pendingCount;
  final List<ModuleRecord> records;

  PassportDateGroup({
    required this.date,
    required this.verifiedCount,
    required this.pendingCount,
    required this.records,
  });

  ModuleRecord get primaryRecord => records.first;
  int get totalCount => verifiedCount + pendingCount;
}

class PassportHubScreen extends StatefulWidget {
  final String stationName;

  const PassportHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<PassportHubScreen> createState() => _PassportHubScreenState();
}

class _PassportHubScreenState extends State<PassportHubScreen> {
  PassportStatusFilter _selectedFilter = PassportStatusFilter.totalReceived;
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
      final passportProv = context.read<PassportProvider>();
      passportProv.setStationContext(
        stationId:
            auth.stationName.isNotEmpty ? auth.stationName : widget.stationName,
        uid: auth.uid,
        visibilityMode: CaseVisibilityMode.stationWide,
      );
      passportProv.ensureInitialized(forceRefresh: true);
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
      lastDate: DateTime(now.year + 2),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _datePresetLabel =
            '${DateFormat('dd MMM').format(picked.start)} – ${DateFormat('dd MMM yyyy').format(picked.end)}';
      });
    }
  }

  // ── Record Grouping & Filtering ──────────────────────────────────────────

  List<PassportDateGroup> _groupRecordsByDate(List<ModuleRecord> records) {
    final Map<String, List<ModuleRecord>> map = {};
    for (final r in records) {
      final key = DateFormat('yyyy-MM-dd').format(r.incidentDate);
      map.putIfAbsent(key, () => []).add(r);
    }

    final groups = map.entries.map((e) {
      final recs = e.value;
      int v = 0;
      int p = 0;
      for (final r in recs) {
        v += PassportProvider.getRecordVerifiedCount(r);
        p += PassportProvider.getRecordPendingCount(r);
      }
      return PassportDateGroup(
        date: recs.first.incidentDate,
        verifiedCount: v,
        pendingCount: p,
        records: recs,
      );
    }).toList();

    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  List<PassportDateGroup> _filterGroups(List<ModuleRecord> all) {
    List<PassportDateGroup> groups = _groupRecordsByDate(all);

    // 1. Status Filter
    switch (_selectedFilter) {
      case PassportStatusFilter.totalReceived:
        break;
      case PassportStatusFilter.verified:
        groups = groups.where((g) => g.verifiedCount > 0).toList();
        break;
      case PassportStatusFilter.pending:
        groups = groups.where((g) => g.pendingCount > 0).toList();
        break;
    }

    // 2. Search Query
    if (_searchQuery.isNotEmpty) {
      groups = groups.where((g) {
        final dateStr = DateFormat('dd/MM/yyyy').format(g.date);
        if (dateStr.contains(_searchQuery)) return true;
        return g.records.any((r) {
          final fileNo = (r.caseNumber.isNotEmpty
                  ? r.caseNumber
                  : (r.extraFields['file_number'] ?? ''))
              .toString()
              .toLowerCase();
          final name = (r.accused.isNotEmpty
                  ? r.accused
                  : (r.extraFields['applicant_name'] ?? r.title))
              .toString()
              .toLowerCase();
          final officer = r.assignedOfficer.toLowerCase();
          final address = (r.location.isNotEmpty
                  ? r.location
                  : (r.extraFields['applicant_address'] ?? ''))
              .toString()
              .toLowerCase();
          return fileNo.contains(_searchQuery) ||
              name.contains(_searchQuery) ||
              officer.contains(_searchQuery) ||
              address.contains(_searchQuery);
        });
      }).toList();
    }

    // 3. Date Filter (on incidentDate / received date)
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
        final d = g.date;
        return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }

    return groups;
  }

  // ── Exports ───────────────────────────────────────────────────────────────

  Future<void> _exportPdf(List<PassportDateGroup> dataset) async {
    if (dataset.isEmpty) return;
    final theme = await PdfUnicodeFonts.openSansTheme();

    final rows = dataset.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final g = entry.value;

      return {
        'Sr. No.': '$i',
        'Date': DateFormat('dd/MM/yyyy').format(g.date),
        'Total': '${g.totalCount}',
        'Verified': '${g.verifiedCount}',
        'Pending': '${g.pendingCount}',
      };
    }).toList();

    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Passport Verification Report — ${widget.stationName}',
      rows: rows,
      prependSerial: false,
      columnOrder: ['Sr. No.', 'Date', 'Total', 'Verified', 'Pending'],
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Passport_Verification_Report.pdf',
    );
  }

  // ── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PassportProvider>();
    final allRecords = provider.records;

    final totalReceivedCount = provider.totalReceivedCount;
    final verifiedCount = provider.verifiedCount;
    final pendingCount = provider.pendingCount;

    final visibleGroups = _filterGroups(allRecords);

    final transFilterLabel = switch (_selectedFilter) {
      PassportStatusFilter.totalReceived =>
        TranslationHelper.translate(context, 'Total Verification'),
      PassportStatusFilter.verified =>
        TranslationHelper.translate(context, 'Verified / Report Submitted'),
      PassportStatusFilter.pending =>
        TranslationHelper.translate(context, 'Pending'),
    };

    final subtitle =
        '${visibleGroups.length} ${TranslationHelper.translate(context, 'entries')} · $transFilterLabel';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, 'Passport Verification'),
        subtitle: subtitle,
        actionWidget: ElevatedButton.icon(
          onPressed: () => PassportAddEditDialog.show(context),
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
            TranslationHelper.translate(context, 'Add Verification'),
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
          // 1. Top Metric Cards (Total Received, Verified / Report Submitted, Pending)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: PassportStatusCards(
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
            child: Row(
              children: [
                // Search Input
                Expanded(
                  child: SizedBox(
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
                          'Search by App No, Name, Officer...',
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
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF3B82F6), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Date Presets Menu
                _buildDateFilterMenu(context),
                const SizedBox(width: 8),

                // PDF Export
                IconButton(
                  tooltip: TranslationHelper.translate(context, 'Export PDF'),
                  onPressed: visibleGroups.isNotEmpty
                      ? () => _exportPdf(visibleGroups)
                      : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: Color(0xFFDC2626), size: 20),
                ),
              ],
            ),
          ),

          // 3. Main Data Area
          Expanded(
            child: allRecords.isEmpty
                ? _buildEmptyState(context)
                : visibleGroups.isEmpty
                    ? _buildNoFilterMatchState(context)
                    : _buildTable(context, visibleGroups),
          ),
        ],
      ),
    );
  }

  // ── Date Preset Menu Widget ───────────────────────────────────────────────

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
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasFilter ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                hasFilter ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color:
                  hasFilter ? const Color(0xFF1E40AF) : AppColors.lightSubText,
            ),
            const SizedBox(width: 6),
            Text(
              _datePresetLabel ??
                  TranslationHelper.translate(context, 'Date Filter'),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                color: hasFilter ? const Color(0xFF1E40AF) : AppColors.navyDark,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: _clearDateFilter,
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Color(0xFFDC2626)),
              ),
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
                color: isSelected ? AppColors.navyMid : AppColors.navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
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
                Icons.badge_rounded,
                size: 38,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              TranslationHelper.translate(
                  context, 'No Passport Applications Recorded'),
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
                'Start by adding a new passport verification record.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => PassportAddEditDialog.show(context),
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
                TranslationHelper.translate(context, 'Add Verification'),
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
              TranslationHelper.translate(
                  context, 'No matching passport applications'),
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
                setState(
                    () => _selectedFilter = PassportStatusFilter.totalReceived);
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

  Widget _buildTable(BuildContext context, List<PassportDateGroup> groups) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = math.max(620.0, constraints.maxWidth - 32);

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
                              TranslationHelper.translate(context, 'Date')),
                        ),
                        DataColumn(
                          label: Text(
                              TranslationHelper.translate(context, 'Total')),
                        ),
                        DataColumn(
                          label: Text(TranslationHelper.translate(
                              context, 'Verified / Report Submitted')),
                        ),
                        DataColumn(
                          label: Text(
                              TranslationHelper.translate(context, 'Pending')),
                        ),
                      ],
                      rows: groups.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final g = entry.value;
                        final receivedDateStr =
                            DateFormat('dd/MM/yyyy').format(g.date);

                        return DataRow(
                          onSelectChanged: (_) {
                            PassportAddEditDialog.show(
                              context,
                              existingRecord: g.primaryRecord,
                              groupedRecords: g.records,
                              initialVerified: g.verifiedCount,
                              initialPending: g.pendingCount,
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
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 14, color: AppColors.navyMid),
                                  const SizedBox(width: 6),
                                  Text(
                                    receivedDateStr,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
