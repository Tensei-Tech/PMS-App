// lib/screens/pending_summary_screen.dart
// Pending cases summary — time-period groups match 1-to-5 pending PDF layout.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../modules/core/models/base_record.dart';
import '../providers/auth_provider.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/excel_export_helper.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/pdf_unicode_fonts.dart';
import '../utils/pending_table_firestore_mapper.dart';
import '../utils/case_visibility.dart';
import '../widgets/custom_pdf_preview_dialog.dart';
import '../widgets/pending_cases_demo_data_table.dart';
import 'pending_hub_screen.dart';

class PendingSummaryScreen extends StatefulWidget {
  const PendingSummaryScreen({
    super.key,
    this.liveRows,
    this.stationName = '',
    this.title = 'Pending Cases — Summary',
    this.isAbsconded = false,
    this.isVictim = false,
    this.isUndetected = false,
  });

  /// When non-null and non-empty, summary uses only this data (skips Firestore stream).
  final List<Map<String, String>>? liveRows;

  /// Station scope for pending Firestore read (ignored when [liveRows] is used).
  final String stationName;

  /// Header title for the screen
  final String title;

  /// Whether this screen displays absconded cases
  final bool isAbsconded;

  /// Whether this screen displays victim cases
  final bool isVictim;

  /// Whether this screen displays undetected cases
  final bool isUndetected;

  @override
  State<PendingSummaryScreen> createState() => _PendingSummaryScreenState();
}

class _PendingSummaryScreenState extends State<PendingSummaryScreen> {
  String _selectedCategory = 'All';

  static bool _usingExplicitLive(List<Map<String, String>>? live) =>
      live != null && live.isNotEmpty;

  static String _bucketForRow(Map<String, String> row) {
    return row['head']?.trim().isNotEmpty == true
        ? row['head']!.trim()
        : 'Other';
  }

  List<Map<String, String>> _rowsForBucket(
    List<Map<String, String>> data,
    String bucketLabel,
  ) {
    return data.where((r) => _bucketForRow(r) == bucketLabel).toList();
  }

  List<String> _getUniqueCategories(List<Map<String, String>> data) {
    final Set<String> categories = {};
    for (final r in data) {
      categories.add(_bucketForRow(r));
    }
    final list = categories.toList()..sort();
    return list;
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<Map<String, String>> dataset,
  ) async {
    final flat = <Map<String, String>>[];
    final categories = _getUniqueCategories(dataset);
    for (final section in categories) {
      flat.addAll(_rowsForBucket(dataset, section));
    }
    if (flat.isEmpty) return;

    final rows = flat.asMap().entries.map((entry) {
      final idx = entry.key;
      final r = entry.value;
      final rowMap = <String, dynamic>{
        'Sr. No.': '${idx + 1}',
        'Cr. No.': r['cr']?.trim().isNotEmpty == true ? r['cr']!.trim() : '—',
        'Sec & Act': r['sections']?.trim().isNotEmpty == true
            ? r['sections']!.trim()
            : '—',
        'Head': r['head']?.trim().isNotEmpty == true ? r['head']!.trim() : '—',
      };
      if (widget.isAbsconded) {
        rowMap['Accused Name (फरार आरोपी)'] =
            r['accused']?.trim().isNotEmpty == true
                ? r['accused']!.trim()
                : '—';
      }
      if (widget.isVictim) {
        rowMap['Name'] = r['victim_name']?.trim().isNotEmpty == true
            ? r['victim_name']!.trim()
            : '—';
        rowMap['Injured/Deceased'] =
            r['injured_deceased']?.trim().isNotEmpty == true
                ? r['injured_deceased']!.trim()
                : '—';
      }
      rowMap['IO Name'] =
          r['io']?.trim().isNotEmpty == true ? r['io']!.trim() : '—';
      if (!widget.isUndetected && !widget.isAbsconded) {
        rowMap['Police Station'] = r['station']?.trim().isNotEmpty == true
            ? r['station']!.trim()
            : '—';
      }
      return rowMap;
    }).toList();

    final columnOrder = <String>[
      'Sr. No.',
      'Cr. No.',
      'Sec & Act',
      'Head',
      if (widget.isAbsconded) 'Accused Name (फरार आरोपी)',
      if (widget.isVictim) 'Name',
      if (widget.isVictim) 'Injured/Deceased',
      'IO Name',
      if (!widget.isUndetected && !widget.isAbsconded) 'Police Station',
    ];

    final theme = await PdfUnicodeFonts.openSansTheme();
    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Pending Cases — Summary (all periods)',
      rows: rows,
      prependSerial: false,
      columnOrder: columnOrder,
    );
    if (!context.mounted) return;
    await CustomPdfPreviewDialog.show(
      context: context,
      title: 'Pending Cases — Summary Report',
      fileName: 'Pending_Summary_All_Periods.pdf',
      buildPdf: (_) async => doc.save(),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navyDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.navyDark : const Color(0xFFCBD5E1),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar(List<Map<String, String>> dataset) {
    final categories = _getUniqueCategories(dataset);
    if (categories.isEmpty || categories.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All',
              count: dataset.length,
              isSelected: _selectedCategory == 'All',
              onTap: () => setState(() => _selectedCategory = 'All'),
            ),
            for (final cat in categories) ...[
              const SizedBox(width: 8),
              _buildFilterChip(
                label: cat,
                count: _rowsForBucket(dataset, cat).length,
                isSelected: _selectedCategory == cat,
                onTap: () => setState(() => _selectedCategory = cat),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _builtContent(
    BuildContext context, {
    required List<Map<String, String>> dataset,
    required bool firedFromFirestoreExclusive,
    required bool showDemoNote,
  }) {
    final categories = _getUniqueCategories(dataset);
    final isFiltered =
        _selectedCategory != 'All' && categories.contains(_selectedCategory);
    final visibleDataset =
        isFiltered ? _rowsForBucket(dataset, _selectedCategory) : dataset;
    final anyRows = visibleDataset.isNotEmpty;

    final Map<String, List<Map<String, String>>> groupedMap = {};
    if (!isFiltered) {
      for (final cat in categories) {
        final catRows = _rowsForBucket(dataset, cat);
        if (catRows.isNotEmpty) {
          groupedMap[cat] = catRows;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            final backButton = MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.navyDark, size: 20),
                ),
              ),
            );

            final totalBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isFiltered
                    ? '${visibleDataset.length} of ${dataset.length}'
                    : '${dataset.length} Total',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyMid,
                ),
              ),
            );

            final excelButton = MouseRegion(
              cursor: !anyRows
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: !anyRows
                    ? null
                    : () {
                        ExcelExportHelper.exportPendingToExcel(
                          dataset: visibleDataset,
                          filename: 'Pending_Summary_Export.csv',
                          isAbsconded: widget.isAbsconded,
                          isVictim: widget.isVictim,
                          isUndetected: widget.isUndetected,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Pending Summary exported to Excel successfully.'),
                            backgroundColor: Color(0xFF107C41),
                          ),
                        );
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: !anyRows
                        ? Colors.grey.shade400
                        : const Color(0xFF107C41),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.table_chart_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Excel',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            final pdfButton = MouseRegion(
              cursor: !anyRows
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: GestureDetector(
                onTap:
                    !anyRows ? null : () => _exportPdf(context, visibleDataset),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: !anyRows ? Colors.grey.shade400 : AppColors.navyMid,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'PDF',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            final headerWidget = isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          backButton,
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          totalBadge,
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          excelButton,
                          const SizedBox(width: 8),
                          pdfButton,
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      backButton,
                      const SizedBox(width: 14),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            totalBadge,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      excelButton,
                      const SizedBox(width: 8),
                      pdfButton,
                    ],
                  );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 14 : 24,
                isMobile ? 12 : 20,
                isMobile ? 14 : 24,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerWidget,
                  const SizedBox(height: 14),
                  _buildCategoryFilterBar(dataset),
                  Expanded(
                    child: !anyRows
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.navyMid
                                        .withValues(alpha: 0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: AppColors.navyMid,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Cases Found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'There are currently no cases matching this category.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.lightSubText,
                                  ),
                                ),
                                if (isFiltered) ...[
                                  const SizedBox(height: 14),
                                  TextButton.icon(
                                    onPressed: () => setState(
                                        () => _selectedCategory = 'All'),
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 16),
                                    label: const Text('View All Categories'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFCBD5E1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: PendingCasesDemoDataTable(
                              isAd: false,
                              realDataRows: isFiltered ? visibleDataset : null,
                              groupedData: isFiltered ? null : groupedMap,
                              isAbsconded: widget.isAbsconded,
                              isVictim: widget.isVictim,
                              isUndetected: widget.isUndetected,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usingExplicitLive(widget.liveRows)) {
      return _builtContent(
        context,
        dataset: widget.liveRows!,
        firedFromFirestoreExclusive: true,
        showDemoNote: false,
      );
    }

    return _LivePendingSummaryLoader(
      fallbackStation: widget.stationName,
      buildContent: _builtContent,
    );
  }
}

/// Subscribes to pending Firestore data for [AuthProvider.stationName], re-binding
/// when the active station changes without requiring navigation pop/push.
class _LivePendingSummaryLoader extends StatefulWidget {
  const _LivePendingSummaryLoader({
    required this.fallbackStation,
    required this.buildContent,
  });

  final String fallbackStation;
  final Widget Function(
    BuildContext context, {
    required List<Map<String, String>> dataset,
    required bool firedFromFirestoreExclusive,
    required bool showDemoNote,
  }) buildContent;

  @override
  State<_LivePendingSummaryLoader> createState() =>
      _LivePendingSummaryLoaderState();
}

class _LivePendingSummaryLoaderState extends State<_LivePendingSummaryLoader> {
  final _backend = BackendCaseService();
  String _boundStation = '';
  List<ModuleRecord> _modules = const [];
  bool _initialLoad = true;
  Object? _error;

  @override
  void dispose() {
    super.dispose();
  }

  String _effectiveStation() {
    final active = Provider.of<AuthProvider>(context).stationName;
    return active.isNotEmpty ? active : widget.fallbackStation;
  }

  void _bindStation(String station) async {
    if (station == _boundStation && !_initialLoad) return;
    _boundStation = station;
    _error = null;

    if (station.isEmpty) {
      if (mounted) {
        setState(() {
          _modules = const [];
          _initialLoad = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _initialLoad = true);
    }

    try {
      final dataList = await _backend.fetchPendingCases();

      if (!mounted) return;

      if (dataList != null) {
        final records = dataList
            .map((m) => ModuleRecord.fromMap(m))
            .where((r) => !PendingHubScreen.isExcludedPendingCrimeType(
                r.subCategory ?? r.moduleKey, r))
            .toList();
        final auth = Provider.of<AuthProvider>(context, listen: false);

        setState(() {
          _modules = CaseVisibility.filterForAuth(records, auth);
          _initialLoad = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = "Failed to load cases from backend";
          _initialLoad = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initialLoad = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindStation(_effectiveStation());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final modules = CaseVisibility.filterForAuth(_modules, auth);

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.lightBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load pending cases',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightSubText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_initialLoad && modules.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.lightBg,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.navyMid),
          ),
        ),
      );
    }

    final exclusive = modules.isNotEmpty;
    final now = DateTime.now();
    final dataset =
        exclusive ? pendingTableRowsAll(modules, now) : <Map<String, String>>[];
    const showDemoNote = false;

    return widget.buildContent(
      context,
      dataset: dataset,
      firedFromFirestoreExclusive: exclusive,
      showDemoNote: showDemoNote,
    );
  }
}
