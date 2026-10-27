// lib/screens/nafis_summary_screen.dart
// NAFIS summary table showing cases with pending fingerprints in RED
// and an action button for Station Incharge (PI) to send reminders to IOs.

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
import '../utils/excel_export_helper.dart';
import '../widgets/nafis_cases_data_table.dart';

class NAFISSummaryScreen extends StatelessWidget {
  const NAFISSummaryScreen({
    super.key,
    this.liveRows,
    this.rawRecords,
    this.stationName = '',
  });

  /// When non-null and non-empty, summary uses only this data.
  final List<Map<String, dynamic>>? liveRows;
  final List<ModuleRecord>? rawRecords;

  /// Station scope
  final String stationName;

  static bool _usingExplicitLive(List<Map<String, dynamic>>? live) =>
      live != null && live.isNotEmpty;

  Future<void> _exportPdf(
    BuildContext context,
    List<Map<String, dynamic>> dataset,
  ) async {
    if (dataset.isEmpty) return;
    final theme = await PdfUnicodeFonts.openSansTheme();
    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'NAFIS — Fingerprint Pending Summary',
      rows: dataset,
      columnOrder: [
        'accused_name',
        'cr',
        'sections',
        'head',
        'io',
        'nafis_status'
      ],
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'NAFIS_Pending_Summary.pdf',
    );
  }

  Widget _builtContent(
    BuildContext context, {
    required List<Map<String, dynamic>> dataset,
    List<ModuleRecord>? records,
    required bool firedFromFirestoreExclusive,
    required bool showDemoNote,
  }) {
    final anyRows = dataset.isNotEmpty;
    const title = 'NAFIS — Fingerprint Pending Summary';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.navyMid, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          'National Automated Fingerprint Identification System',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: !anyRows
                        ? null
                        : () => ExcelExportHelper.exportNafisToExcel(
                              dataset: dataset,
                            ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.table_chart_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Excel',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.15,
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
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.navyMid,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'PDF',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: dataset.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fingerprint_rounded,
                              size: 48,
                              color: AppColors.navyMid.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No pending NAFIS cases found',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : NAFISCasesDataTable(
                        realDataRows: dataset,
                        rawRecords: records,
                      ),
              ),
            ),
          ],
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
        records: rawRecords,
        firedFromFirestoreExclusive: true,
        showDemoNote: false,
      );
    }

    return _LiveNAFISSummaryLoader(
      fallbackStation: stationName,
      buildContent: _builtContent,
    );
  }
}

class _LiveNAFISSummaryLoader extends StatefulWidget {
  const _LiveNAFISSummaryLoader({
    required this.fallbackStation,
    required this.buildContent,
  });

  final String fallbackStation;
  final Widget Function(
    BuildContext context, {
    required List<Map<String, dynamic>> dataset,
    List<ModuleRecord>? records,
    required bool firedFromFirestoreExclusive,
    required bool showDemoNote,
  }) buildContent;

  @override
  State<_LiveNAFISSummaryLoader> createState() =>
      _LiveNAFISSummaryLoaderState();
}

class _LiveNAFISSummaryLoaderState extends State<_LiveNAFISSummaryLoader> {
  final _backend = BackendCaseService();
  List<ModuleRecord> _modules = [];
  bool _initialLoad = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final dataList = await _backend.fetchNAFISCases();
      if (mounted) {
        if (dataList != null) {
          final mapped = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
          setState(() {
            _modules = mapped;
            _initialLoad = false;
          });
        } else {
          setState(() {
            _initialLoad = false;
            _error = 'Failed to load NAFIS cases';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialLoad = false;
          _error = e;
        });
      }
    }
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
    final rawDataset = exclusive
        ? arrestedTableRowsAll(modules, now)
        : <Map<String, String>>[];

    // Ensure status is Pending and enrich rows
    final dataset = <Map<String, dynamic>>[];
    for (var i = 0; i < rawDataset.length; i++) {
      final r = Map<String, dynamic>.from(rawDataset[i]);
      if (i < modules.length) {
        final m = modules[i];
        r['nafis_status'] = m.extraFields['nafis_status'] ?? 'Pending';
        r['nafis_status_color'] = m.extraFields['nafis_status_color'] ?? 'red';
        r['io_name'] =
            m.assignedOfficer.isNotEmpty ? m.assignedOfficer : (r['io'] ?? '—');
        r['accused_name'] =
            m.accused.isNotEmpty ? m.accused : (r['accused_name'] ?? '—');
      }
      dataset.add(r);
    }

    return widget.buildContent(
      context,
      dataset: dataset,
      records: modules,
      firedFromFirestoreExclusive: exclusive,
      showDemoNote: false,
    );
  }
}
