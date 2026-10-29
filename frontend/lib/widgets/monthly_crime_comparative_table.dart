import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../modules/core/models/base_record.dart';
import '../screens/module_record_detail_screen.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';

/// Interactive & dynamic widget displaying the official Police Monthly Crime Comparative Report
/// ("STATEMENT SHOWING IPC & SLL CRIMES COMPARITIVE") directly from dynamic database data.
class MonthlyCrimeComparativeTable extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;

  const MonthlyCrimeComparativeTable({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<MonthlyCrimeComparativeTable> createState() =>
      _MonthlyCrimeComparativeTableState();
}

class _MonthlyCrimeComparativeTableState
    extends State<MonthlyCrimeComparativeTable> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;

  // Column width definitions (Total width = 964px)
  static const double _colSrWidth = 44.0;
  static const double _colHeadWidth = 210.0;
  static const double _colDataWidth = 56.0;
  static const double _colIncDecWidth = 66.0;
  static const double _colGroupWidth = _colDataWidth * 2; // 112.0
  static const double _totalTableWidth = _colSrWidth +
      _colHeadWidth +
      (_colDataWidth * 10) +
      (_colIncDecWidth * 2); // 44 + 210 + 560 + 132 = 946.0

  @override
  void initState() {
    super.initState();
    _fetchComparativeData();
  }

  @override
  void didUpdateWidget(covariant MonthlyCrimeComparativeTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.selectedMonth != widget.selectedMonth) {
      _fetchComparativeData();
    }
  }

  Future<void> _fetchComparativeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().get(
        '${ApiConfig.baseUrl}/cases/monthly-comparative/',
        queryParameters: {
          'year': widget.selectedYear,
          'month': widget.selectedMonth,
        },
      );

      if (!mounted) {
        return;
      }

      if (response.isSuccess && response.data != null) {
        final dynamic raw = response.data;
        final Map<String, dynamic> data =
            raw is String ? jsonDecode(raw) : Map<String, dynamic>.from(raw);
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.errorMessage ??
              'Failed to load monthly comparative data (Status: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'An error occurred while loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_reportData == null) {
      return;
    }
    try {
      final doc = pw.Document();
      final metadata = _reportData!['metadata'] as Map<String, dynamic>? ?? {};
      final windows = metadata['windows'] as Map<String, dynamic>? ?? {};
      final allRows = (_reportData!['all_rows'] as List<dynamic>? ?? []);

      final cmLabel = windows['current_month']?['label']?.toString() ?? 'CM';
      final pmLabel = windows['previous_month']?['label']?.toString() ?? 'PM';
      final smlyLabel =
          windows['same_month_previous_year']?['label']?.toString() ?? 'SMLY';
      final cyLabel =
          windows['current_year_ytd']?['label']?.toString() ?? 'CY YTD';
      final pyLabel =
          windows['previous_year_ytd']?['label']?.toString() ?? 'PY YTD';

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'STATEMENT SHOWING IPC & SLL CRIMES COMPARITIVE',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Month: ${metadata['month_name']} ${metadata['year']}   |   Station: ${metadata['station_name']}   |   Total Cases: ${metadata['total_cases_analyzed']}',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(26), // SR
                  1: const pw.FlexColumnWidth(3.0), // HEADS
                  2: const pw.FixedColumnWidth(28), // CM REP
                  3: const pw.FixedColumnWidth(28), // CM DET
                  4: const pw.FixedColumnWidth(28), // PM REP
                  5: const pw.FixedColumnWidth(28), // PM DET
                  6: const pw.FixedColumnWidth(28), // SMLY REP
                  7: const pw.FixedColumnWidth(28), // SMLY DET
                  8: const pw.FixedColumnWidth(30), // INC/DEC
                  9: const pw.FixedColumnWidth(28), // CY REP
                  10: const pw.FixedColumnWidth(28), // CY DET
                  11: const pw.FixedColumnWidth(28), // PY REP
                  12: const pw.FixedColumnWidth(28), // PY DET
                  13: const pw.FixedColumnWidth(30), // INC/DEC
                },
                children: [
                  // Header Row with exactly 14 cells
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _pdfHeaderCell('SR'),
                      _pdfHeaderCell('CRIME HEADS'),
                      _pdfHeaderCell('$cmLabel\nREP'),
                      _pdfHeaderCell('$cmLabel\nDET'),
                      _pdfHeaderCell('$pmLabel\nREP'),
                      _pdfHeaderCell('$pmLabel\nDET'),
                      _pdfHeaderCell('$smlyLabel\nREP'),
                      _pdfHeaderCell('$smlyLabel\nDET'),
                      _pdfHeaderCell('M.\n+/-'),
                      _pdfHeaderCell('$cyLabel\nREP'),
                      _pdfHeaderCell('$cyLabel\nDET'),
                      _pdfHeaderCell('$pyLabel\nREP'),
                      _pdfHeaderCell('$pyLabel\nDET'),
                      _pdfHeaderCell('YTD\n+/-'),
                    ],
                  ),
                  // Data rows (each with exactly 14 cells)
                  ...allRows.map((rawRow) {
                    final row = rawRow as Map<String, dynamic>;
                    final rowType = row['type']?.toString();

                    if (rowType == 'section_header') {
                      final title = row['title']?.toString() ?? '';
                      return pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.blue50),
                        children: [
                          _pdfSpanCell(title,
                              isBold: true, color: PdfColors.blue900),
                          ...List.generate(13, (_) => pw.SizedBox.shrink()),
                        ],
                      );
                    }

                    final bool isTotal =
                        rowType == 'subtotal' || rowType == 'grand_total';
                    final bgColor = rowType == 'grand_total'
                        ? PdfColors.amber100
                        : (rowType == 'subtotal' ? PdfColors.grey100 : null);

                    final sr = row['sr_no']?.toString() ?? '';
                    final head = row['head']?.toString() ?? '';
                    final cmR = row['current_month']?['rep']?.toString() ?? '0';
                    final cmD = row['current_month']?['det']?.toString() ?? '0';
                    final pmR =
                        row['previous_month']?['rep']?.toString() ?? '0';
                    final pmD =
                        row['previous_month']?['det']?.toString() ?? '0';
                    final smlyR =
                        row['same_month_previous_year']?['rep']?.toString() ??
                            '0';
                    final smlyD =
                        row['same_month_previous_year']?['det']?.toString() ??
                            '0';
                    final mInc =
                        row['monthly_inc_dec']?['text']?.toString() ?? '=';
                    final cyR =
                        row['current_year_ytd']?['rep']?.toString() ?? '0';
                    final cyD =
                        row['current_year_ytd']?['det']?.toString() ?? '0';
                    final pyR =
                        row['previous_year_ytd']?['rep']?.toString() ?? '0';
                    final pyD =
                        row['previous_year_ytd']?['det']?.toString() ?? '0';
                    final ytdInc =
                        row['ytd_inc_dec']?['text']?.toString() ?? '=';

                    return pw.TableRow(
                      decoration: bgColor != null
                          ? pw.BoxDecoration(color: bgColor)
                          : null,
                      children: [
                        _pdfDataCell(sr, isBold: isTotal),
                        _pdfDataCell(head, alignLeft: true, isBold: isTotal),
                        _pdfDataCell(cmR, isBold: isTotal),
                        _pdfDataCell(cmD, isBold: isTotal),
                        _pdfDataCell(pmR, isBold: isTotal),
                        _pdfDataCell(pmD, isBold: isTotal),
                        _pdfDataCell(smlyR, isBold: isTotal),
                        _pdfDataCell(smlyD, isBold: isTotal),
                        _pdfDataCell(mInc, isBold: true),
                        _pdfDataCell(cyR, isBold: isTotal),
                        _pdfDataCell(cyD, isBold: isTotal),
                        _pdfDataCell(pyR, isBold: isTotal),
                        _pdfDataCell(pyD, isBold: isTotal),
                        _pdfDataCell(ytdInc, isBold: true),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final pdfBytes = await doc.save();
      final fileName =
          'Crime_Comparative_${widget.selectedMonth}_${widget.selectedYear}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  static List<String> _extractIds(dynamic rawList) {
    if (rawList is List) {
      return rawList
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  void _openAllAnalyzedCases() {
    if (_reportData == null) return;
    final casesLookup =
        _reportData!['cases_lookup'] as Map<String, dynamic>? ?? {};
    final allIds = casesLookup.keys.toList();
    final metadata = _reportData!['metadata'] as Map<String, dynamic>? ?? {};
    _openCasesModal(
      title: 'All Analyzed Cases',
      subtitle:
          '${metadata['month_name']} ${metadata['year']} • Police Station: ${metadata['station_name']}',
      caseIds: allIds,
    );
  }

  void _openCasesModal({
    required String title,
    required String subtitle,
    required List<String> caseIds,
  }) {
    if (caseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No cases registered for "$title" in this reporting window.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: AppColors.navyMid,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final casesLookup =
        _reportData?['cases_lookup'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (ctx) => _MonthlyCasesListDialog(
        title: title,
        subtitle: subtitle,
        caseIds: caseIds,
        casesLookup: casesLookup,
        onSelectCase: (String caseId, Map<String, dynamic>? preloadedData) {
          _fetchAndOpenCaseDetail(caseId, preloadedData);
        },
      ),
    );
  }

  Future<void> _fetchAndOpenCaseDetail(
    String caseId,
    Map<String, dynamic>? preloadedData,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadCtx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.navyMid,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Fetching complete case detail from database...',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Dynamic fetch directly from database backend
      final fullCaseData = await BackendCaseService().fetchCaseById(caseId);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .pop(); // dismiss loading dialog

      final recordMap = fullCaseData ?? preloadedData;
      if (recordMap != null) {
        final record = ModuleRecord.fromMap(recordMap, caseId);
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: ModuleRecordDetailScreen(record: record),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not fetch details for this case from database.'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading case detail: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  static pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Center(
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
      ),
    );
  }

  static pw.Widget _pdfSpanCell(String text,
      {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _pdfDataCell(String text,
      {bool alignLeft = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 2),
      child: pw.Align(
        alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.navyMid,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating Monthly Crime Comparative Report...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.lightSubText,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.dangerRed.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.dangerRed.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.dangerRed, size: 36),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.dangerRed,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _fetchComparativeData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadius.buttonRadius.topLeft.x),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_reportData == null) {
      return const SizedBox.shrink();
    }

    final metadata = _reportData!['metadata'] as Map<String, dynamic>? ?? {};
    final windows = metadata['windows'] as Map<String, dynamic>? ?? {};
    final allRows = (_reportData!['all_rows'] as List<dynamic>? ?? []);

    final cmLabel = windows['current_month']?['label']?.toString() ?? 'CM';
    final pmLabel = windows['previous_month']?['label']?.toString() ?? 'PM';
    final smlyLabel =
        windows['same_month_previous_year']?['label']?.toString() ?? 'SMLY';
    final cyLabel =
        windows['current_year_ytd']?['label']?.toString() ?? 'CY YTD';
    final pyLabel =
        windows['previous_year_ytd']?['label']?.toString() ?? 'PY YTD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action & Report Header Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.navyMid.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata['report_title']?.toString() ??
                          'STATEMENT SHOWING IPC & SLL CRIMES COMPARITIVE',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Station: ${metadata['station_name']}  •  Total Cases Analyzed: ${metadata['total_cases_analyzed']}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.lightSubText,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openAllAnalyzedCases,
                icon: const Icon(Icons.folder_shared_rounded,
                    size: 16, color: AppColors.navyMid),
                label: Text(
                  'View All Cases (${metadata['total_cases_analyzed'] ?? 0})',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyMid,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.navyMid, width: 1.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh live data',
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.navyMid, size: 20),
                onPressed: _fetchComparativeData,
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    size: 16, color: Colors.white),
                label: Text(
                  'Export PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Scrollable Crime Comparative Statement Table with robust custom rows
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: _totalTableWidth > constraints.maxWidth
                        ? _totalTableWidth
                        : constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 2-TIER TABLE HEADER ───────────────────────────
                        _buildTableHeader(
                          cmLabel,
                          pmLabel,
                          smlyLabel,
                          cyLabel,
                          pyLabel,
                        ),

                        // ── DYNAMIC DATA ROWS ─────────────────────────────
                        ...allRows.map((rawRow) {
                          final row = rawRow as Map<String, dynamic>;
                          final rowType = row['type']?.toString();

                          // Section Header Banner (e.g. "I TO V - IPC CRIMES")
                          if (rowType == 'section_header') {
                            return _buildSectionBanner(
                              row['title']?.toString() ?? '',
                            );
                          }

                          final bool isSubtotal = rowType == 'subtotal';
                          final bool isGrandTotal = rowType == 'grand_total';

                          return _buildDataRow(
                            row: row,
                            isSubtotal: isSubtotal,
                            isGrandTotal: isGrandTotal,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 2-Tier Header with visual column spans
  Widget _buildTableHeader(
    String cmLabel,
    String pmLabel,
    String smlyLabel,
    String cyLabel,
    String pyLabel,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark.withValues(alpha: 0.07),
        border: const Border(
          bottom: BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // SR NO
            _buildHeaderCellBox(
              width: _colSrWidth,
              text: 'SR\nNO',
            ),
            _buildCellDivider(),

            // CRIME HEADS
            _buildHeaderCellBox(
              width: _colHeadWidth,
              text: 'CRIME HEADS',
              alignLeft: true,
            ),
            _buildCellDivider(),

            // CURRENT MONTH (Group of 2)
            _buildHeaderGroupBox(
              title: cmLabel,
              subLeft: 'REP',
              subRight: 'DET',
            ),
            _buildCellDivider(),

            // PREVIOUS MONTH (Group of 2)
            _buildHeaderGroupBox(
              title: pmLabel,
              subLeft: 'REP',
              subRight: 'DET',
            ),
            _buildCellDivider(),

            // SAME MONTH PREV YEAR (Group of 2)
            _buildHeaderGroupBox(
              title: smlyLabel,
              subLeft: 'REP',
              subRight: 'DET',
            ),
            _buildCellDivider(),

            // MONTHLY INC/DEC
            _buildHeaderCellBox(
              width: _colIncDecWidth,
              text: 'INC/\nDEC',
            ),
            _buildCellDivider(),

            // CURRENT YEAR YTD (Group of 2)
            _buildHeaderGroupBox(
              title: cyLabel,
              subLeft: 'REP',
              subRight: 'DET',
            ),
            _buildCellDivider(),

            // PREVIOUS YEAR YTD (Group of 2)
            _buildHeaderGroupBox(
              title: pyLabel,
              subLeft: 'REP',
              subRight: 'DET',
            ),
            _buildCellDivider(),

            // YTD INC/DEC
            _buildHeaderCellBox(
              width: _colIncDecWidth,
              text: 'INC/\nDEC',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCellBox({
    required double width,
    required String text,
    bool alignLeft = false,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            text,
            textAlign: alignLeft ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderGroupBox({
    required String title,
    required String subLeft,
    required String subRight,
  }) {
    return SizedBox(
      width: _colGroupWidth,
      child: Column(
        children: [
          // Top Title
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyMid,
                  height: 1.15,
                ),
              ),
            ),
          ),
          const Divider(
              height: 1, thickness: 0.8, color: AppColors.lightBorder),
          // Bottom Sub-columns
          Row(
            children: [
              SizedBox(
                width: _colDataWidth - 0.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    subLeft,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 16, color: AppColors.lightBorder),
              SizedBox(
                width: _colDataWidth - 0.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    subRight,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBanner(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        border: Border(
          bottom: BorderSide(color: AppColors.navyMid, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.goldPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required Map<String, dynamic> row,
    required bool isSubtotal,
    required bool isGrandTotal,
  }) {
    final bool isHighlight = isSubtotal || isGrandTotal;

    Color? rowBg;
    if (isGrandTotal) {
      rowBg = AppColors.goldPrimary.withValues(alpha: 0.16);
    } else if (isSubtotal) {
      rowBg = AppColors.navyMid.withValues(alpha: 0.07);
    }

    final metadata = _reportData?['metadata'] as Map<String, dynamic>? ?? {};
    final windows = metadata['windows'] as Map<String, dynamic>? ?? {};
    final cmLabel = windows['current_month']?['label']?.toString() ?? 'CM';
    final pmLabel = windows['previous_month']?['label']?.toString() ?? 'PM';
    final smlyLabel =
        windows['same_month_previous_year']?['label']?.toString() ?? 'SMLY';
    final cyLabel =
        windows['current_year_ytd']?['label']?.toString() ?? 'CY YTD';
    final pyLabel =
        windows['previous_year_ytd']?['label']?.toString() ?? 'PY YTD';

    final srNo = row['sr_no']?.toString() ?? '';
    final head = row['head']?.toString() ?? '';

    final cmRep = row['current_month']?['rep']?.toString() ?? '0';
    final cmDet = row['current_month']?['det']?.toString() ?? '0';

    final pmRep = row['previous_month']?['rep']?.toString() ?? '0';
    final pmDet = row['previous_month']?['det']?.toString() ?? '0';

    final smlyRep = row['same_month_previous_year']?['rep']?.toString() ?? '0';
    final smlyDet = row['same_month_previous_year']?['det']?.toString() ?? '0';

    final mIncText = row['monthly_inc_dec']?['text']?.toString() ?? '=';

    final cyRep = row['current_year_ytd']?['rep']?.toString() ?? '0';
    final cyDet = row['current_year_ytd']?['det']?.toString() ?? '0';

    final pyRep = row['previous_year_ytd']?['rep']?.toString() ?? '0';
    final pyDet = row['previous_year_ytd']?['det']?.toString() ?? '0';

    final ytdIncText = row['ytd_inc_dec']?['text']?.toString() ?? '=';

    final List<String> cmRepIds =
        _extractIds(row['current_month']?['rep_case_ids']);
    final List<String> cmDetIds =
        _extractIds(row['current_month']?['det_case_ids']);
    final List<String> pmRepIds =
        _extractIds(row['previous_month']?['rep_case_ids']);
    final List<String> pmDetIds =
        _extractIds(row['previous_month']?['det_case_ids']);
    final List<String> smlyRepIds =
        _extractIds(row['same_month_previous_year']?['rep_case_ids']);
    final List<String> smlyDetIds =
        _extractIds(row['same_month_previous_year']?['det_case_ids']);
    final List<String> cyRepIds =
        _extractIds(row['current_year_ytd']?['rep_case_ids']);
    final List<String> cyDetIds =
        _extractIds(row['current_year_ytd']?['det_case_ids']);
    final List<String> pyRepIds =
        _extractIds(row['previous_year_ytd']?['rep_case_ids']);
    final List<String> pyDetIds =
        _extractIds(row['previous_year_ytd']?['det_case_ids']);

    final Set<String> allDistinctRowIds = {
      ...cmRepIds,
      ...cmDetIds,
      ...pmRepIds,
      ...pmDetIds,
      ...smlyRepIds,
      ...smlyDetIds,
      ...cyRepIds,
      ...cyDetIds,
      ...pyRepIds,
      ...pyDetIds,
    };
    final List<String> rowCaseIds = allDistinctRowIds.toList();

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          bottom: BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // SR NO
            _buildDataCellBox(
              width: _colSrWidth,
              text: srNo,
              isBold: isHighlight,
            ),
            _buildCellDivider(),

            // HEAD
            _buildDataCellBox(
              width: _colHeadWidth,
              text: head,
              alignLeft: true,
              isBold: isHighlight,
              textColor: isGrandTotal
                  ? AppColors.navyDark
                  : (isSubtotal ? AppColors.navyMid : null),
              isClickable: rowCaseIds.isNotEmpty,
              tooltip: rowCaseIds.isNotEmpty
                  ? 'Click to view all ${rowCaseIds.length} case(s) for $head'
                  : null,
              onTap: rowCaseIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — All Cases',
                        subtitle:
                            '${rowCaseIds.length} Cases Analyzed in Report',
                        caseIds: rowCaseIds,
                      )
                  : null,
            ),
            _buildCellDivider(),

            // CM REP & DET
            _buildDataCellBox(
              width: _colDataWidth,
              text: cmRep,
              isBold: isHighlight,
              isClickable: cmRepIds.isNotEmpty,
              tooltip: cmRepIds.isNotEmpty
                  ? 'View $cmRep reported case(s) for $head ($cmLabel)'
                  : null,
              onTap: cmRepIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $cmLabel (Reported)',
                        subtitle: '$cmRep Reported Cases',
                        caseIds: cmRepIds,
                      )
                  : null,
            ),
            _buildCellDivider(),
            _buildDataCellBox(
              width: _colDataWidth,
              text: cmDet,
              isBold: isHighlight,
              isClickable: cmDetIds.isNotEmpty,
              tooltip: cmDetIds.isNotEmpty
                  ? 'View $cmDet detected case(s) for $head ($cmLabel)'
                  : null,
              onTap: cmDetIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $cmLabel (Detected)',
                        subtitle: '$cmDet Detected Cases',
                        caseIds: cmDetIds,
                      )
                  : null,
            ),
            _buildCellDivider(),

            // PM REP & DET
            _buildDataCellBox(
              width: _colDataWidth,
              text: pmRep,
              isBold: isHighlight,
              isClickable: pmRepIds.isNotEmpty,
              tooltip: pmRepIds.isNotEmpty
                  ? 'View $pmRep reported case(s) for $head ($pmLabel)'
                  : null,
              onTap: pmRepIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $pmLabel (Reported)',
                        subtitle: '$pmRep Reported Cases',
                        caseIds: pmRepIds,
                      )
                  : null,
            ),
            _buildCellDivider(),
            _buildDataCellBox(
              width: _colDataWidth,
              text: pmDet,
              isBold: isHighlight,
              isClickable: pmDetIds.isNotEmpty,
              tooltip: pmDetIds.isNotEmpty
                  ? 'View $pmDet detected case(s) for $head ($pmLabel)'
                  : null,
              onTap: pmDetIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $pmLabel (Detected)',
                        subtitle: '$pmDet Detected Cases',
                        caseIds: pmDetIds,
                      )
                  : null,
            ),
            _buildCellDivider(),

            // SMLY REP & DET
            _buildDataCellBox(
              width: _colDataWidth,
              text: smlyRep,
              isBold: isHighlight,
              isClickable: smlyRepIds.isNotEmpty,
              tooltip: smlyRepIds.isNotEmpty
                  ? 'View $smlyRep reported case(s) for $head ($smlyLabel)'
                  : null,
              onTap: smlyRepIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $smlyLabel (Reported)',
                        subtitle: '$smlyRep Reported Cases',
                        caseIds: smlyRepIds,
                      )
                  : null,
            ),
            _buildCellDivider(),
            _buildDataCellBox(
              width: _colDataWidth,
              text: smlyDet,
              isBold: isHighlight,
              isClickable: smlyDetIds.isNotEmpty,
              tooltip: smlyDetIds.isNotEmpty
                  ? 'View $smlyDet detected case(s) for $head ($smlyLabel)'
                  : null,
              onTap: smlyDetIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $smlyLabel (Detected)',
                        subtitle: '$smlyDet Detected Cases',
                        caseIds: smlyDetIds,
                      )
                  : null,
            ),
            _buildCellDivider(),

            // MONTHLY INC/DEC
            _buildIncDecCellBox(
              width: _colIncDecWidth,
              text: mIncText,
              isBold: isHighlight,
            ),
            _buildCellDivider(),

            // CY REP & DET
            _buildDataCellBox(
              width: _colDataWidth,
              text: cyRep,
              isBold: isHighlight,
              isClickable: cyRepIds.isNotEmpty,
              tooltip: cyRepIds.isNotEmpty
                  ? 'View $cyRep reported case(s) for $head ($cyLabel)'
                  : null,
              onTap: cyRepIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $cyLabel (Reported)',
                        subtitle: '$cyRep Reported Cases',
                        caseIds: cyRepIds,
                      )
                  : null,
            ),
            _buildCellDivider(),
            _buildDataCellBox(
              width: _colDataWidth,
              text: cyDet,
              isBold: isHighlight,
              isClickable: cyDetIds.isNotEmpty,
              tooltip: cyDetIds.isNotEmpty
                  ? 'View $cyDet detected case(s) for $head ($cyLabel)'
                  : null,
              onTap: cyDetIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $cyLabel (Detected)',
                        subtitle: '$cyDet Detected Cases',
                        caseIds: cyDetIds,
                      )
                  : null,
            ),
            _buildCellDivider(),

            // PY REP & DET
            _buildDataCellBox(
              width: _colDataWidth,
              text: pyRep,
              isBold: isHighlight,
              isClickable: pyRepIds.isNotEmpty,
              tooltip: pyRepIds.isNotEmpty
                  ? 'View $pyRep reported case(s) for $head ($pyLabel)'
                  : null,
              onTap: pyRepIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $pyLabel (Reported)',
                        subtitle: '$pyRep Reported Cases',
                        caseIds: pyRepIds,
                      )
                  : null,
            ),
            _buildCellDivider(),
            _buildDataCellBox(
              width: _colDataWidth,
              text: pyDet,
              isBold: isHighlight,
              isClickable: pyDetIds.isNotEmpty,
              tooltip: pyDetIds.isNotEmpty
                  ? 'View $pyDet detected case(s) for $head ($pyLabel)'
                  : null,
              onTap: pyDetIds.isNotEmpty
                  ? () => _openCasesModal(
                        title: '$head — $pyLabel (Detected)',
                        subtitle: '$pyDet Detected Cases',
                        caseIds: pyDetIds,
                      )
                  : null,
            ),
            _buildCellDivider(),

            // YTD INC/DEC
            _buildIncDecCellBox(
              width: _colIncDecWidth,
              text: ytdIncText,
              isBold: isHighlight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCellBox({
    required double width,
    required String text,
    bool alignLeft = false,
    bool isBold = false,
    Color? textColor,
    bool isClickable = false,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    final bool canClick = isClickable && onTap != null;

    Widget cellContent = Container(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: canClick && !alignLeft
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.navyMid.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyMid,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: alignLeft
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    text,
                    textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: isBold ? 10.5 : 10,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                      color: textColor ??
                          (canClick
                              ? AppColors.navyDark
                              : (isBold
                                  ? AppColors.navyDark
                                  : AppColors.lightText)),
                    ),
                  ),
                ),
                if (canClick && alignLeft) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 11,
                    color: AppColors.navyMid.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
    );

    if (canClick) {
      cellContent = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: cellContent,
        ),
      );
    }

    if (tooltip != null && tooltip.isNotEmpty) {
      cellContent = Tooltip(
        message: tooltip,
        textStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.white),
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: BorderRadius.circular(6),
        ),
        child: cellContent,
      );
    }

    return SizedBox(
      width: width,
      child: cellContent,
    );
  }

  Widget _buildIncDecCellBox({
    required double width,
    required String text,
    bool isBold = false,
  }) {
    Color color;
    if (text.startsWith('+')) {
      color = AppColors.dangerRed;
    } else if (text.startsWith('-')) {
      color = AppColors.successGreen;
    } else {
      color = AppColors.lightSubText;
    }

    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: text == '=' ? 0.05 : 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCellDivider() {
    return Container(
      width: 0.6,
      color: AppColors.lightBorder,
    );
  }
}

/// Interactive Dialog displaying the list of cases for a selected Crime Head or Reporting Period.
/// Clicking any particular case dynamically fetches that case's complete details from the database backend.
class _MonthlyCasesListDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> caseIds;
  final Map<String, dynamic> casesLookup;
  final void Function(String caseId, Map<String, dynamic>? preloadedData)
      onSelectCase;

  const _MonthlyCasesListDialog({
    required this.title,
    required this.subtitle,
    required this.caseIds,
    required this.casesLookup,
    required this.onSelectCase,
  });

  @override
  State<_MonthlyCasesListDialog> createState() =>
      _MonthlyCasesListDialogState();
}

class _MonthlyCasesListDialogState extends State<_MonthlyCasesListDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';
  final Map<String, Map<String, dynamic>> _caseMap = {};
  bool _loadingMissing = false;

  @override
  void initState() {
    super.initState();
    // Populate known cases from lookup
    for (final id in widget.caseIds) {
      if (widget.casesLookup.containsKey(id)) {
        final val = widget.casesLookup[id];
        if (val is Map) {
          _caseMap[id] = Map<String, dynamic>.from(val);
        }
      }
    }

    // If any IDs are missing from lookup, fetch them dynamically from backend
    final missingIds =
        widget.caseIds.where((id) => !_caseMap.containsKey(id)).toList();
    if (missingIds.isNotEmpty) {
      _fetchMissingCases(missingIds);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMissingCases(List<String> missingIds) async {
    setState(() => _loadingMissing = true);
    try {
      final joinedIds = missingIds.take(50).join(',');
      final response = await ApiService().get(
        '${ApiConfig.cases}?ids=$joinedIds',
      );
      if (response.isSuccess && response.data != null) {
        final dynamic raw = response.data;
        List<dynamic> items = [];
        if (raw is List) {
          items = raw;
        } else if (raw is Map &&
            raw.containsKey('results') &&
            raw['results'] is List) {
          items = raw['results'] as List<dynamic>;
        }
        for (final item in items) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              _caseMap[id] = Map<String, dynamic>.from(item);
            }
          }
        }
      }
    } catch (_) {
      // Keep existing map if request fails
    } finally {
      if (mounted) setState(() => _loadingMissing = false);
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('detect') || s.contains('solved')) {
      return AppColors.successGreen;
    }
    if (s.contains('pend') || s.contains('open') || s.contains('active')) {
      return AppColors.goldPrimary;
    }
    if (s.contains('dispos') || s.contains('close') || s.contains('resolved')) {
      return AppColors.navyMid;
    }
    if (s.contains('transfer')) {
      return AppColors.dangerRed;
    }
    return AppColors.lightSubText;
  }

  List<Map<String, dynamic>> get _filteredCases {
    final query = _searchController.text.trim().toLowerCase();

    return widget.caseIds.map((id) {
      if (_caseMap.containsKey(id)) {
        return _caseMap[id]!;
      }
      return <String, dynamic>{
        'id': id,
        'case_number': id,
        'title': 'Case Record $id',
        'status': 'Pending',
      };
    }).where((c) {
      final status = (c['status']?.toString() ?? '').toLowerCase();
      if (_selectedStatusFilter != 'All') {
        if (_selectedStatusFilter == 'Detected' &&
            !status.contains('detect') &&
            !status.contains('solved')) {
          return false;
        }
        if (_selectedStatusFilter == 'Pending' &&
            !status.contains('pend') &&
            !status.contains('open') &&
            !status.contains('active')) {
          return false;
        }
        if (_selectedStatusFilter == 'Disposed' &&
            !status.contains('dispos') &&
            !status.contains('close') &&
            !status.contains('resolved')) {
          return false;
        }
      }

      if (query.isEmpty) return true;

      final caseNum = (c['case_number']?.toString() ?? '').toLowerCase();
      final title = (c['title']?.toString() ?? '').toLowerCase();
      final subCat = (c['sub_category']?.toString() ?? '').toLowerCase();
      final comp = (c['complainant']?.toString() ?? '').toLowerCase();
      final acc = (c['accused']?.toString() ?? '').toLowerCase();
      final io = (c['assigned_officer']?.toString() ?? '').toLowerCase();
      final loc = (c['location']?.toString() ?? '').toLowerCase();

      return caseNum.contains(query) ||
          title.contains(query) ||
          subCat.contains(query) ||
          comp.contains(query) ||
          acc.contains(query) ||
          io.contains(query) ||
          loc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCases;
    final totalCount = widget.caseIds.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 720;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 24,
      ),
      child: Center(
        child: Container(
          width: isDesktop ? 740 : double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── DIALOG HEADER ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.goldPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalCount Cases',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 22),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── SEARCH & FILTER STRIP ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.lightBg,
                  border: Border(
                    bottom: BorderSide(color: AppColors.lightBorder, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'Search by CR / FIR number, accused, complainant, or IO...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.lightSubText,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.navyMid,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.lightBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.navyMid,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status filter pills
                    Row(
                      children: [
                        Text(
                          'Filter:',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightSubText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...['All', 'Pending', 'Detected', 'Disposed'].map(
                          (status) {
                            final isSelected = _selectedStatusFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(status),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(
                                        () => _selectedStatusFilter = status);
                                  }
                                },
                                labelStyle: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.navyDark,
                                ),
                                selectedColor: AppColors.navyMid,
                                backgroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.navyMid
                                        : AppColors.lightBorder,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        if (_loadingMissing)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navyMid,
                            ),
                          )
                        else
                          Text(
                            'Showing ${filtered.length} of $totalCount',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.lightSubText,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── CASES LIST ────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.folder_off_outlined,
                              size: 48,
                              color: AppColors.lightSubText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No matching cases found',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try clearing your search query or status filter.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final caseId = c['id']?.toString() ?? '';
                          final caseNum = c['case_number']?.toString() ?? '';
                          final title = c['title']?.toString() ?? '';
                          final subCat = c['sub_category']?.toString() ?? '';
                          final status = c['status']?.toString() ?? 'Open';
                          final comp = c['complainant']?.toString() ?? '';
                          final acc = c['accused']?.toString() ?? '';
                          final io = c['assigned_officer']?.toString() ?? '';
                          final stName = c['station_name']?.toString() ?? '';
                          final rawDate = c['incident_date']?.toString() ?? '';

                          String dateStr = '—';
                          if (rawDate.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(rawDate);
                              dateStr = DateFormat('dd/MM/yyyy').format(dt);
                            } catch (_) {
                              dateStr = rawDate.split('T')[0];
                            }
                          }

                          final statusColor = _getStatusColor(status);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.lightBorder,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onSelectCase(caseId, c);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top row: Case No + Status Badge + Date
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.navyMid
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              caseNum.isNotEmpty
                                                  ? 'CR No: $caseNum'
                                                  : 'Case: $caseId',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.navyDark,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                size: 13,
                                                color: AppColors.lightSubText,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                dateStr,
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

                                      const SizedBox(height: 8),

                                      // Middle: Title / Crime description & station
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title.isNotEmpty
                                                  ? title
                                                  : (subCat.isNotEmpty
                                                      ? subCat
                                                      : 'Case Record #$caseId'),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.navyDark,
                                              ),
                                            ),
                                          ),
                                          if (stName.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                stName,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.lightSubText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // Bottom row: Details & Click Prompt
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightBg,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Wrap(
                                                spacing: 12,
                                                runSpacing: 4,
                                                children: [
                                                  if (acc.isNotEmpty)
                                                    _infoItem('Accused', acc),
                                                  if (comp.isNotEmpty)
                                                    _infoItem(
                                                        'Complainant', comp),
                                                  if (io.isNotEmpty)
                                                    _infoItem('IO', io),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.navyMid
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'View Details',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.navyMid,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 13,
                                                    color: AppColors.navyMid,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.lightSubText),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.navyDark,
            ),
          ),
        ],
      ),
    );
  }
}
