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
import '../utils/case_visibility.dart';
import '../utils/excel_export_helper.dart';
import '../widgets/nafis_cases_data_table.dart';

class NAFISSummaryScreen extends StatelessWidget {
  const NAFISSummaryScreen({
    super.key,
    this.title = 'NAFIS — Fingerprint Pending Summary',
    this.startDate,
    this.endDate,
    this.ioUid,
    this.liveRows,
    this.rawRecords,
    this.stationName = '',
  });

  final String title;
  final String? startDate;
  final String? endDate;
  final String? ioUid;

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
      title: title,
      rows: dataset,
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'NAFIS_Summary.pdf',
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
                  InkWell(
                    onTap: !anyRows
                        ? null
                        : () => ExcelExportHelper.exportNafisToExcel(
                              dataset: dataset,
                            ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.table_chart_rounded,
                              color: Colors.white, size: 16),
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
                  InkWell(
                    onTap: !anyRows ? null : () => _exportPdf(context, dataset),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.navyMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white, size: 16),
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
              const SizedBox(height: 16),
              Expanded(
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
                              'No NAFIS cases found',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: NAFISCasesDataTable(
                          realDataRows: dataset,
                          rawRecords: records,
                        ),
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
        records: rawRecords,
        firedFromFirestoreExclusive: true,
        showDemoNote: false,
      );
    }

    return _LiveNAFISSummaryLoader(
      fallbackStation: stationName,
      startDate: startDate,
      endDate: endDate,
      ioUid: ioUid,
      buildContent: _builtContent,
    );
  }
}

class _LiveNAFISSummaryLoader extends StatefulWidget {
  const _LiveNAFISSummaryLoader({
    required this.fallbackStation,
    required this.buildContent,
    this.startDate,
    this.endDate,
    this.ioUid,
  });

  final String fallbackStation;
  final String? startDate;
  final String? endDate;
  final String? ioUid;
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
  List<Map<String, dynamic>> _rawList = [];
  bool _initialLoad = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final dataList = await _backend.fetchNAFISCases(
        startDate: widget.startDate,
        endDate: widget.endDate,
        ioUid: widget.ioUid,
      );
      if (mounted) {
        if (dataList != null) {
          final mapped = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
          setState(() {
            _modules = mapped;
            _rawList = dataList;
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

    final dataset = <Map<String, dynamic>>[];
    for (var i = 0; i < modules.length; i++) {
      final m = modules[i];
      final raw = (i < _rawList.length) ? _rawList[i] : <String, dynamic>{};
      final r = Map<String, dynamic>.from(raw);
      r['id'] = raw['id'] ?? m.id;
      r['cr'] = raw['case_number'] ?? raw['cr_no'] ?? m.caseNumber;
      r['cr_no'] = r['cr'];
      r['section_act'] = raw['section_act'] ?? m.extraFields['section_act'];
      r['charge_sheet_date'] =
          raw['charge_sheet_date'] ?? m.extraFields['charge_sheet_date'];
      r['io_name'] = raw['assigned_officer'] ??
          (m.assignedOfficer.isNotEmpty
              ? m.assignedOfficer
              : (raw['io_name'] ?? '—'));
      r['nafis_status'] = raw['extra_fields']?['nafis_status'] ??
          raw['nafis_status'] ??
          m.extraFields['nafis_status'] ??
          'Pending';
      r['nafis_status_color'] = raw['extra_fields']?['nafis_status_color'] ??
          raw['nafis_status_color'] ??
          m.extraFields['nafis_status_color'] ??
          'red';
      dataset.add(r);
    }

    return widget.buildContent(
      context,
      dataset: dataset,
      records: modules,
      firedFromFirestoreExclusive: modules.isNotEmpty,
      showDemoNote: false,
    );
  }
}
