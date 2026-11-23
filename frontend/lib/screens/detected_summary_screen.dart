// lib/screens/detected_summary_screen.dart
// Detected cases summary — time-period groups match 1-to-5 detected PDF layout.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../modules/core/models/base_record.dart';
import '../providers/auth_provider.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/pdf_unicode_fonts.dart';
import '../utils/detected_table_firestore_mapper.dart';
import '../utils/excel_export_helper.dart';
import '../utils/case_visibility.dart';
import '../widgets/custom_pdf_preview_dialog.dart';
import '../widgets/detected_cases_demo_data_table.dart';

class DetectedSummaryScreen extends StatelessWidget {
  const DetectedSummaryScreen({
    super.key,
    this.liveRows,
    this.stationName = '',
  });

  /// When non-null and non-empty, summary uses only this data (skips Firestore stream).
  final List<Map<String, String>>? liveRows;

  /// Station scope for detected Firestore read (ignored when [liveRows] is used).
  final String stationName;

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
      return <String, dynamic>{
        'Sr. No.': '${idx + 1}',
        'Cr. No.': r['cr']?.trim().isNotEmpty == true ? r['cr']!.trim() : '—',
        'Sec & Act': r['sections']?.trim().isNotEmpty == true
            ? r['sections']!.trim()
            : '—',
        'Head': r['head']?.trim().isNotEmpty == true ? r['head']!.trim() : '—',
        'Accused Name': r['accused']?.trim().isNotEmpty == true
            ? r['accused']!.trim()
            : '—',
        'IO Name': r['io']?.trim().isNotEmpty == true ? r['io']!.trim() : '—',
      };
    }).toList();

    final theme = await PdfUnicodeFonts.openSansTheme();
    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Detected Cases — Summary (all periods)',
      rows: rows,
      prependSerial: false,
      columnOrder: const [
        'Sr. No.',
        'Cr. No.',
        'Sec & Act',
        'Head',
        'Accused Name',
        'IO Name',
      ],
    );
    if (!context.mounted) return;
    await CustomPdfPreviewDialog.show(
      context: context,
      title: 'Detected Cases — Summary Report',
      fileName: 'Detected_Summary_All_Periods.pdf',
      buildPdf: (_) async => doc.save(),
    );
  }

  Widget _builtContent(
    BuildContext context, {
    required List<Map<String, String>> dataset,
    required bool firedFromFirestoreExclusive,
    required bool showDemoNote,
  }) {
    const title = 'Detected Cases — Summary';
    final anyRows = dataset.isNotEmpty;

    Widget sectionBlock(String bucketLabel) {
      final rows = _rowsForBucket(dataset, bucketLabel);
      if (rows.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF0F2F5)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: AppColors.navyMid,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bucketLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${rows.length} ${rows.length == 1 ? 'Case' : 'Cases'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: DetectedCasesDemoDataTable(
                isAd: false,
                realDataRows: rows,
              ),
            ),
          ],
        ),
      );
    }

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
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: !anyRows
                        ? null
                        : () {
                            ExcelExportHelper.exportDetectedToExcel(
                              dataset: dataset,
                              filename: 'Detected_Summary_All_Periods.csv',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Detected Summary exported to Excel successfully.'),
                                backgroundColor: Color(0xFF107C41),
                              ),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: !anyRows
                            ? Colors.grey.shade400
                            : const Color(0xFF107C41),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !anyRows
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF107C41)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: !anyRows ? null : () => _exportPdf(context, dataset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            !anyRows ? Colors.grey.shade400 : AppColors.navyMid,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !anyRows
                            ? []
                            : [
                                BoxShadow(
                                  color:
                                      AppColors.navyMid.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: !anyRows
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.navyMid.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.verified_outlined,
                                  size: 40, color: AppColors.navyMid),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No detected cases',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          for (final label in _getUniqueCategories(dataset))
                            sectionBlock(label),
                        ],
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
      return _builtContent(
        context,
        dataset: liveRows!,
        firedFromFirestoreExclusive: true,
        showDemoNote: false,
      );
    }

    return _LiveDetectedSummaryLoader(
      fallbackStation: stationName,
      buildContent: _builtContent,
    );
  }
}

/// Subscribes to detected Firestore data for [AuthProvider.stationName], re-binding
/// when the active station changes without requiring navigation pop/push.
class _LiveDetectedSummaryLoader extends StatefulWidget {
  const _LiveDetectedSummaryLoader({
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
  State<_LiveDetectedSummaryLoader> createState() =>
      _LiveDetectedSummaryLoaderState();
}

class _LiveDetectedSummaryLoaderState
    extends State<_LiveDetectedSummaryLoader> {
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
      final dataList = await _backend.fetchDetectedCases();

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
                'Could not load detected cases',
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
    final dataset = exclusive
        ? detectedModuleRecordsToTableRows(modules, now)
        : <Map<String, String>>[];
    const showDemoNote = false;

    return widget.buildContent(
      context,
      dataset: dataset,
      firedFromFirestoreExclusive: exclusive,
      showDemoNote: showDemoNote,
    );
  }
}
