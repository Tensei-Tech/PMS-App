// lib/screens/repeat_offender_summary_screen.dart
// Repeat Offender summary table

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../modules/core/models/base_record.dart';
import '../providers/auth_provider.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/pdf_unicode_fonts.dart';
import '../utils/arrested_table_firestore_mapper.dart';
import '../utils/case_visibility.dart';
import '../widgets/repeat_offender_cases_data_table.dart';
import '../utils/excel_export_helper.dart';
import '../services/ui_config_service.dart';

class RepeatOffenderSummaryScreen extends StatelessWidget {
  const RepeatOffenderSummaryScreen({
    super.key,
    this.liveRows,
    this.stationName = '',
  });

  /// When non-null and non-empty, summary uses only this data (skips Firestore stream).
  final List<Map<String, String>>? liveRows;

  /// Station scope
  final String stationName;

  static bool _usingExplicitLive(List<Map<String, String>>? live) =>
      live != null && live.isNotEmpty;

  Future<void> _exportPdf(
    BuildContext context,
    List<Map<String, String>> dataset,
  ) async {
    if (dataset.isEmpty) return;
    final dittoRows =
        RepeatOffenderCasesDataTable.applyDittoFormatting(dataset);
    final theme = await PdfUnicodeFonts.openSansTheme();
    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Repeat Offender — Summary (all periods)',
      rows: dittoRows.map((e) => Map<String, dynamic>.from(e)).toList(),
      columnOrder: ['accused_name', 'cr', 'sections', 'head', 'station'],
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Repeat_Offender_Summary.pdf',
    );
  }

  void _exportExcel(
    BuildContext context,
    List<Map<String, String>> dataset,
  ) {
    if (dataset.isEmpty) return;
    final dittoRows =
        RepeatOffenderCasesDataTable.applyDittoFormatting(dataset);
    ExcelExportHelper.exportRepeatOffenderToExcel(
      dataset: dittoRows,
      filename: 'Repeat_Offender_Summary.csv',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exported Repeat Offender summary to Excel (.csv) successfully.'),
        backgroundColor: Color(0xFF107C41),
      ),
    );
  }

  Widget _builtContent(
    BuildContext context, {
    required List<Map<String, String>> dataset,
    required bool firedFromFirestoreExclusive,
    required bool showDemoNote,
  }) {
    final title = UiConfigService.repeatOffenderSummary['title'];
    final anyRows = dataset.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.navyMid.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${dataset.length} Total',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyMid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    enabled: anyRows,
                    tooltip: 'Export',
                    onSelected: (val) {
                      if (val == 'excel') {
                        _exportExcel(context, dataset);
                      } else if (val == 'pdf') {
                        _exportPdf(context, dataset);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'excel',
                        child: Row(
                          children: [
                            const Icon(Icons.table_chart_outlined,
                                color: Color(0xFF107C41), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Export to Excel (CSV)',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined,
                                color: Color(0xFFD32F2F), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Export to PDF',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: anyRows ? AppColors.navyMid : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Export',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down_rounded,
                              size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: dataset.isEmpty
                    ? Center(
                        child: Text(
                          UiConfigService
                              .repeatOffenderSummary['no_cases_label'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightSubText,
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: RepeatOffenderCasesDataTable(
                            realDataRows: dataset),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usingExplicitLive(liveRows)) {
      final sortedLive = List<Map<String, String>>.from(liveRows!)
        ..sort((a, b) {
          final comp = (a['accused_name'] ?? '')
              .toLowerCase()
              .compareTo((b['accused_name'] ?? '').toLowerCase());
          if (comp != 0) return comp;
          return (a['cr'] ?? '').compareTo(b['cr'] ?? '');
        });
      return _builtContent(
        context,
        dataset: sortedLive,
        firedFromFirestoreExclusive: true,
        showDemoNote: false,
      );
    }

    return _LiveRepeatOffenderSummaryLoader(
      fallbackStation: stationName,
      buildContent: _builtContent,
    );
  }
}

class _LiveRepeatOffenderSummaryLoader extends StatefulWidget {
  const _LiveRepeatOffenderSummaryLoader({
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
  State<_LiveRepeatOffenderSummaryLoader> createState() =>
      _LiveRepeatOffenderSummaryLoaderState();
}

class _LiveRepeatOffenderSummaryLoaderState
    extends State<_LiveRepeatOffenderSummaryLoader> {
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
      final dataList = await _backend.fetchRepeatOffenderCases();

      if (!mounted) return;

      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final auth = Provider.of<AuthProvider>(context, listen: false);

        setState(() {
          _modules = CaseVisibility.filterForAuth(records, auth);
          _initialLoad = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = UiConfigService.repeatOffenderSummary['error_message'];
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
        backgroundColor: const Color(0xFFF6F8FF),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error.toString(),
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
        backgroundColor: Color(0xFFF6F8FF),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.navyMid),
          ),
        ),
      );
    }

    final exclusive = modules.isNotEmpty;
    final now = DateTime.now();
    final rawDataset = exclusive
        ? arrestedTableRowsAll(modules, now)
        : <Map<String, String>>[];

    // Fetch all repeat offender cases
    final dataset = <Map<String, String>>[];
    for (var row in rawDataset) {
      final name = (row['accused_name'] ?? '').trim();
      final cr = (row['cr'] ?? '').trim();
      final multipleCr = (row['multiple_cr'] ?? '').trim();

      // Exclude invalid/empty CR or cases without other repeat CRs
      if (cr.isEmpty || cr == '—' || cr == '-') {
        continue;
      }
      if (multipleCr.isEmpty || multipleCr == '—' || multipleCr == '-') {
        continue;
      }

      final lowerName = name.toLowerCase();
      if (lowerName == 'default accused' ||
          name.isEmpty ||
          name ==
              UiConfigService.repeatOffenderSummary['unknown_offender_label']) {
        continue;
      }

      dataset.add(row);
    }

    dataset.sort((a, b) {
      final comp = (a['accused_name'] ?? '')
          .toLowerCase()
          .compareTo((b['accused_name'] ?? '').toLowerCase());
      if (comp != 0) return comp;
      return (a['cr'] ?? '').compareTo(b['cr'] ?? '');
    });

    const showDemoNote = false;

    return widget.buildContent(
      context,
      dataset: dataset,
      firedFromFirestoreExclusive: exclusive,
      showDemoNote: showDemoNote,
    );
  }
}
