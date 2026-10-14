// lib/screens/juvenile_summary_screen.dart
// Juvenile summary table

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
import '../widgets/juvenile_cases_data_table.dart';
import '../services/ui_config_service.dart';

class JuvenileSummaryScreen extends StatelessWidget {
  const JuvenileSummaryScreen({
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

  static String _bucketForRow(Map<String, String> row) {
    return row['head']?.trim().isNotEmpty == true
        ? row['head']!.trim()
        : UiConfigService.juvenileSummary['other_bucket_label'];
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
    final theme = await PdfUnicodeFonts.openSansTheme();
    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Juvenile â€” Summary (all periods)',
      rows: flat.map((e) => {
        'Cr. No.': e['cr'] ?? '—',
        'Name of juvenile': e['accused_name'] ?? '—',
        'Age': e['age'] ?? '—',
        'Police station name': e['station'] ?? '—',
      }).toList(),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Juvenile_Summary.pdf',
    );
  }

  Widget _builtContent(
    BuildContext context, {
    required List<Map<String, String>> dataset,
    required bool firedFromFirestoreExclusive,
    required bool showDemoNote,
  }) {
    final title = UiConfigService.juvenileSummary['title'];
    final anyRows = dataset.isNotEmpty;


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
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.15,
                      ),
                    ),
                  ),

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
                          const Icon(Icons.download_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Export',
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
                        child: Text(
                          UiConfigService.juvenileSummary['no_cases_label'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightSubText,
                          ),
                        ),
                      )
                    : JuvenileCasesDataTable(realDataRows: dataset),
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
        firedFromFirestoreExclusive: true,
        showDemoNote: false,
      );
    }

    return _LiveJuvenileSummaryLoader(
      fallbackStation: stationName,
      buildContent: _builtContent,
    );
  }
}

class _LiveJuvenileSummaryLoader extends StatefulWidget {
  const _LiveJuvenileSummaryLoader({
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
  State<_LiveJuvenileSummaryLoader> createState() =>
      _LiveJuvenileSummaryLoaderState();
}

class _LiveJuvenileSummaryLoaderState extends State<_LiveJuvenileSummaryLoader> {
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
      final dataList = await _backend.fetchJuvenileCases();

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
          _error = UiConfigService.juvenileSummary['error_message'];
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
    // We'll reuse the arrestedTableRowsAll for now, but we'll map fields properly in the caller if needed
    final now = DateTime.now();
    final rawDataset =
        exclusive ? arrestedTableRowsAll(modules, now) : <Map<String, String>>[];
        
    // Deduplicate by accused_name so each offender only appears once
    final dataset = <Map<String, String>>[];
    final seenAccused = <String>{};
    for (var row in rawDataset) {
      final name = row['accused_name'] ?? '';
      if (name.isNotEmpty && name != UiConfigService.juvenileSummary['unknown_offender_label']) {
        if (seenAccused.contains(name)) continue;
        seenAccused.add(name);
      }
      dataset.add(row);
    }
    
    const showDemoNote = false;

    return widget.buildContent(
      context,
      dataset: dataset,
      firedFromFirestoreExclusive: exclusive,
      showDemoNote: showDemoNote,
    );
  }
}
