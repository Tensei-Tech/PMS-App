// lib/modules/licence/screens/licence_hub_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../core/models/base_record.dart';
import '../constants/licence_noc_types.dart';
import '../providers/licence_provider.dart';
import '../widgets/licence_status_cards.dart';
import '../widgets/licence_add_edit_dialog.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/case_visibility.dart';
import '../../../utils/dynamic_map_pdf.dart';
import '../../../utils/pdf_unicode_fonts.dart';
import '../../../utils/excel_export_helper.dart';
import '../../../utils/translation_helper.dart';
import '../../../widgets/module_hub_screen_app_bar.dart';

class LicenceHubScreen extends StatefulWidget {
  final String stationName;

  const LicenceHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<LicenceHubScreen> createState() => _LicenceHubScreenState();
}

class _LicenceHubScreenState extends State<LicenceHubScreen> {
  LicenceStatusFilter _selectedFilter = LicenceStatusFilter.totalReceived;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  DateTimeRange? _selectedDateRange;
  String? _datePresetLabel;
  LicenceNocOption? _selectedNocFilter;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final licenceProv = context.read<LicenceProvider>();
      licenceProv.setStationContext(
        stationId:
            auth.stationName.isNotEmpty ? auth.stationName : widget.stationName,
        uid: auth.uid,
        visibilityMode: CaseVisibilityMode.stationWide,
      );
      licenceProv.ensureInitialized(forceRefresh: true);
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

  // ── Filtering Logic ───────────────────────────────────────────────────────

  List<ModuleRecord> _filterRecords(List<ModuleRecord> all) {
    var list = all;

    switch (_selectedFilter) {
      case LicenceStatusFilter.totalReceived:
        break;
      case LicenceStatusFilter.approved:
        list = list.where(LicenceProvider.isApprovedRecord).toList();
        break;
      case LicenceStatusFilter.rejected:
        list = list.where(LicenceProvider.isRejectedRecord).toList();
        break;
      case LicenceStatusFilter.returned:
        list = list.where(LicenceProvider.isReturnedRecord).toList();
        break;
      case LicenceStatusFilter.pending:
        list = list.where(LicenceProvider.isPendingRecord).toList();
        break;
    }

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

      list = list.where((r) {
        return (r.incidentDate.isAfter(start) ||
                r.incidentDate.isAtSameMomentAs(start)) &&
            (r.incidentDate.isBefore(end) ||
                r.incidentDate.isAtSameMomentAs(end));
      }).toList();
    }

    if (_selectedNocFilter != null) {
      list = list.where((r) {
        final rawType = (r.extraFields['licence_type'] ?? r.title).toString();
        final matched = findLicenceNocOption(rawType);
        if (matched != null) {
          return matched.number == _selectedNocFilter!.number;
        }
        return rawType
            .toLowerCase()
            .contains(_selectedNocFilter!.name.toLowerCase());
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((r) {
        final applicantName = (r.extraFields['applicant_name'] ?? r.complainant)
            .toString()
            .toLowerCase();
        final businessName = (r.extraFields['business_name'] ?? r.accused)
            .toString()
            .toLowerCase();
        final licenceType =
            (r.extraFields['licence_type'] ?? r.title).toString().toLowerCase();
        final dateStr = DateFormat('dd/MM/yyyy').format(r.incidentDate);
        final status = r.status.toLowerCase();
        final remarks = (r.extraFields['remarks'] ?? r.description)
            .toString()
            .toLowerCase();

        return applicantName.contains(_searchQuery) ||
            businessName.contains(_searchQuery) ||
            licenceType.contains(_searchQuery) ||
            dateStr.contains(_searchQuery) ||
            status.contains(_searchQuery) ||
            remarks.contains(_searchQuery);
      }).toList();
    }

    return list;
  }

  // ── Exports ───────────────────────────────────────────────────────────────

  Future<void> _exportPdf(List<ModuleRecord> dataset) async {
    if (dataset.isEmpty) return;
    final theme = await PdfUnicodeFonts.openSansTheme();

    final rows = dataset.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final r = entry.value;
      final applicantName =
          (r.extraFields['applicant_name'] ?? r.complainant).toString();
      final businessName =
          (r.extraFields['business_name'] ?? r.accused).toString();
      final licenceType = (r.extraFields['licence_type'] ?? r.title).toString();
      final statusLabel = LicenceProvider.isApprovedRecord(r)
          ? 'Approved'
          : LicenceProvider.isRejectedRecord(r)
              ? 'Rejected'
              : LicenceProvider.isReturnedRecord(r)
                  ? 'Returned'
                  : 'Pending';

      return {
        'Sr. No.': '$i',
        'Applicant Name': applicantName.isNotEmpty ? applicantName : '—',
        'Business Name': businessName.isNotEmpty ? businessName : '—',
        'Licence / NOC Type': licenceType.isNotEmpty ? licenceType : '—',
        'Received Date': DateFormat('dd/MM/yyyy').format(r.incidentDate),
        'Status': statusLabel,
      };
    }).toList();

    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Licence Report — ${widget.stationName}',
      rows: rows,
      prependSerial: false,
      columnOrder: [
        'Sr. No.',
        'Applicant Name',
        'Business Name',
        'Licence / NOC Type',
        'Received Date',
        'Status',
      ],
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Licence_Report.pdf',
    );
  }

  Future<void> _exportExcel(List<ModuleRecord> dataset) async {
    if (dataset.isEmpty) return;

    final headers = [
      'Sr. No.',
      'Applicant Name',
      'Business Name',
      'Licence / NOC Type',
      'Received Date',
      'Status',
    ];

    final rows = dataset.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final r = entry.value;
      final applicantName =
          (r.extraFields['applicant_name'] ?? r.complainant).toString();
      final businessName =
          (r.extraFields['business_name'] ?? r.accused).toString();
      final licenceType = (r.extraFields['licence_type'] ?? r.title).toString();
      final statusLabel = LicenceProvider.isApprovedRecord(r)
          ? 'Approved'
          : LicenceProvider.isRejectedRecord(r)
              ? 'Rejected'
              : LicenceProvider.isReturnedRecord(r)
                  ? 'Returned'
                  : 'Pending';

      return [
        i,
        applicantName.isNotEmpty ? applicantName : '—',
        businessName.isNotEmpty ? businessName : '—',
        licenceType.isNotEmpty ? licenceType : '—',
        DateFormat('dd/MM/yyyy').format(r.incidentDate),
        statusLabel,
      ];
    }).toList();

    ExcelExportHelper.exportTableToCsv(
      headers: headers,
      rows: rows,
      filename: 'Licence_${widget.stationName}.csv',
    );
  }

  // ── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LicenceProvider>();
    final allRecords = provider.records;

    final totalReceivedCount = provider.totalReceivedCount;
    final approvedCount = provider.approvedCount;
    final rejectedCount = provider.rejectedCount;
    final returnedCount = provider.returnedCount;
    final pendingCount = provider.pendingCount;

    final visibleRecords = _filterRecords(allRecords);

    final transFilterLabel = switch (_selectedFilter) {
      LicenceStatusFilter.totalReceived =>
        TranslationHelper.translate(context, 'Total Received'),
      LicenceStatusFilter.approved =>
        TranslationHelper.translate(context, 'Approved'),
      LicenceStatusFilter.rejected =>
        TranslationHelper.translate(context, 'Rejected'),
      LicenceStatusFilter.returned =>
        TranslationHelper.translate(context, 'Returned'),
      LicenceStatusFilter.pending =>
        TranslationHelper.translate(context, 'Pending'),
    };

    final subtitle =
        '${visibleRecords.length} ${TranslationHelper.translate(context, 'records')} · $transFilterLabel${_selectedNocFilter != null ? ' · ${_selectedNocFilter!.displayName}' : ''}';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, 'Licence'),
        subtitle: subtitle,
        actionWidget: ElevatedButton.icon(
          onPressed: () => LicenceAddEditDialog.show(context),
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
            TranslationHelper.translate(context, 'Add Licence'),
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
          // 1. Top Metric Cards (Total Received, Approved, Rejected, Returned, Pending)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: LicenceStatusCards(
              selectedFilter: _selectedFilter,
              totalReceivedCount: totalReceivedCount,
              approvedCount: approvedCount,
              rejectedCount: rejectedCount,
              returnedCount: returnedCount,
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
                          'Search by applicant, business, type, date...',
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

                // NOC Type Filter Menu
                _buildNocTypeFilterMenu(context),
                const SizedBox(width: 8),

                // Date Presets Menu
                _buildDateFilterMenu(context),
                const SizedBox(width: 8),

                // PDF Export
                IconButton(
                  tooltip: TranslationHelper.translate(context, 'Export PDF'),
                  onPressed: visibleRecords.isNotEmpty
                      ? () => _exportPdf(visibleRecords)
                      : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: Color(0xFFDC2626), size: 20),
                ),

                // Excel Export
                IconButton(
                  tooltip: TranslationHelper.translate(context, 'Export Excel'),
                  onPressed: visibleRecords.isNotEmpty
                      ? () => _exportExcel(visibleRecords)
                      : null,
                  icon: const Icon(Icons.table_chart_outlined,
                      color: Color(0xFF16A34A), size: 20),
                ),
              ],
            ),
          ),

          // 3. Main Data Area
          Expanded(
            child: allRecords.isEmpty
                ? _buildEmptyState(context)
                : visibleRecords.isEmpty
                    ? _buildNoFilterMatchState(context)
                    : _buildTable(context, visibleRecords),
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

  // ── NOC Type Filter Menu Widget ───────────────────────────────────────────

  Widget _buildNocTypeFilterMenu(BuildContext context) {
    final hasFilter = _selectedNocFilter != null;

    return PopupMenuButton<String>(
      tooltip:
          TranslationHelper.translate(context, 'Filter by Licence / NOC Type'),
      constraints: const BoxConstraints(maxHeight: 450, maxWidth: 360),
      onSelected: (val) {
        if (val == 'all') {
          setState(() => _selectedNocFilter = null);
        } else {
          final num = int.tryParse(val);
          final opt = kLicenceNocOptions.cast<LicenceNocOption?>().firstWhere(
                (o) => o?.number == num,
                orElse: () => null,
              );
          setState(() => _selectedNocFilter = opt);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'all',
          child: Row(
            children: [
              Icon(
                _selectedNocFilter == null
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 16,
                color: _selectedNocFilter == null
                    ? AppColors.navyMid
                    : AppColors.lightSubText,
              ),
              const SizedBox(width: 8),
              Text(
                TranslationHelper.translate(ctx, 'All NOC / Licence Types'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: _selectedNocFilter == null
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...kLicenceNocOptions.map((opt) {
          final isSelected = _selectedNocFilter?.number == opt.number;
          return PopupMenuItem<String>(
            value: '${opt.number}',
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 16,
                  color:
                      isSelected ? AppColors.navyMid : AppColors.lightSubText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    opt.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.navyDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
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
              Icons.category_outlined,
              size: 16,
              color:
                  hasFilter ? const Color(0xFF1E40AF) : AppColors.lightSubText,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                _selectedNocFilter?.displayName ??
                    TranslationHelper.translate(context, 'NOC Type'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                  color:
                      hasFilter ? const Color(0xFF1E40AF) : AppColors.navyDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => setState(() => _selectedNocFilter = null),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Color(0xFFDC2626)),
              ),
            ] else ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down,
                  size: 16, color: AppColors.lightSubText),
            ],
          ],
        ),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: const Icon(
                Icons.assignment_ind_rounded,
                size: 48,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              TranslationHelper.translate(context, 'No Licence Records Yet'),
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              TranslationHelper.translate(
                context,
                'Start by adding a new licence verification record.',
              ),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.lightSubText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => LicenceAddEditDialog.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                TranslationHelper.translate(context, 'Add Licence'),
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
                  context, 'No matching licence applications'),
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
                    () => _selectedFilter = LicenceStatusFilter.totalReceived);
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

  Widget _buildTable(BuildContext context, List<ModuleRecord> records) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = math.max(880.0, constraints.maxWidth - 32);

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
                          label: Text(TranslationHelper.translate(
                              context, 'Applicant Name')),
                        ),
                        DataColumn(
                          label: Text(TranslationHelper.translate(
                              context, 'Business Name')),
                        ),
                        DataColumn(
                          label: Text(TranslationHelper.translate(
                              context, 'Licence / NOC Type')),
                        ),
                        DataColumn(
                          label: Text(TranslationHelper.translate(
                              context, 'Received Date')),
                        ),
                        DataColumn(
                          label: Text(
                              TranslationHelper.translate(context, 'Status')),
                        ),
                      ],
                      rows: records.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final r = entry.value;

                        final applicantName =
                            (r.extraFields['applicant_name'] ?? r.complainant)
                                .toString();
                        final businessName =
                            (r.extraFields['business_name'] ?? r.accused)
                                .toString();
                        final licenceType =
                            (r.extraFields['licence_type'] ?? r.title)
                                .toString();
                        final receivedDateStr =
                            DateFormat('dd/MM/yyyy').format(r.incidentDate);

                        final (statusBg, statusBorder, statusFg, statusIcon) =
                            _getStatusStyle(r);
                        final statusLabel = LicenceProvider.isApprovedRecord(r)
                            ? 'Approved'
                            : LicenceProvider.isRejectedRecord(r)
                                ? 'Rejected'
                                : LicenceProvider.isReturnedRecord(r)
                                    ? 'Returned'
                                    : 'Pending';

                        return DataRow(
                          onSelectChanged: (_) {
                            LicenceAddEditDialog.show(context,
                                existingRecord: r);
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
                              Text(
                                applicantName.isNotEmpty ? applicantName : '—',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                businessName.isNotEmpty ? businessName : '—',
                                style: GoogleFonts.poppins(
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  licenceType.isNotEmpty ? licenceType : '—',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.navyMid,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 13, color: AppColors.navyMid),
                                  const SizedBox(width: 6),
                                  Text(
                                    receivedDateStr,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
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
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 14, color: statusFg),
                                    const SizedBox(width: 6),
                                    Text(
                                      TranslationHelper.translate(
                                          context, statusLabel),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: statusFg,
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

  (Color, Color, Color, IconData) _getStatusStyle(ModuleRecord r) {
    if (LicenceProvider.isApprovedRecord(r)) {
      return (
        const Color(0xFFECFDF5),
        const Color(0xFFA7F3D0),
        const Color(0xFF047857),
        Icons.verified_rounded,
      );
    } else if (LicenceProvider.isRejectedRecord(r)) {
      return (
        const Color(0xFFFEF2F2),
        const Color(0xFFFECACA),
        const Color(0xFFDC2626),
        Icons.cancel_rounded,
      );
    } else if (LicenceProvider.isReturnedRecord(r)) {
      return (
        const Color(0xFFF5F3FF),
        const Color(0xFFDDD6FE),
        const Color(0xFF7C3AED),
        Icons.assignment_return_rounded,
      );
    } else {
      return (
        const Color(0xFFFFFBEB),
        const Color(0xFFFDE68A),
        const Color(0xFFD97706),
        Icons.hourglass_top_rounded,
      );
    }
  }
}
