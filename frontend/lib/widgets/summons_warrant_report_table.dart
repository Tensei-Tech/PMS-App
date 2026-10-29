import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../modules/core/models/base_record.dart';
import '../screens/module_record_detail_screen.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import 'add_warrant_case_dialog.dart';

/// Summons & Warrant dynamic report table widget.
/// Fetches all data dynamically from backend database (/cases/summons-warrant/).
/// Renders 3 sections: Summons (समंस), NBW (पकड वारंट), BW (जमानती वारंट)
/// with dynamic columns: Previous Month, Current Month, Total, Executed, Executed %, Unserved, Pending.
/// Supports Section-level view and Station-wise breakdown, drill-down case viewing, and PDF export.
class SummonsWarrantReportTable extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;

  const SummonsWarrantReportTable({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<SummonsWarrantReportTable> createState() =>
      _SummonsWarrantReportTableState();
}

class _SummonsWarrantReportTableState extends State<SummonsWarrantReportTable> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  String _selectedSectionKey = 'all'; // 'all', 'summons', 'nbw', 'bw'
  bool _showStationBreakdown = false;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  @override
  void didUpdateWidget(covariant SummonsWarrantReportTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.selectedMonth != widget.selectedMonth) {
      _fetchReport();
    }
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().get(
        '${ApiConfig.baseUrl}/cases/summons-warrant/',
        queryParameters: {
          'year': widget.selectedYear,
          'month': widget.selectedMonth,
        },
      );

      if (!mounted) return;

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
              'Failed to load report (Status: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading report: $e';
        _isLoading = false;
      });
    }
  }

  void _openCaseDetail(String caseId) async {
    final casesLookup =
        _reportData?['cases_lookup'] as Map<String, dynamic>? ?? {};
    final caseDict = casesLookup[caseId] as Map<String, dynamic>?;

    try {
      final fullCaseData = await BackendCaseService().fetchCaseById(caseId);
      final recordMap = fullCaseData ?? caseDict;

      if (!mounted) return;
      if (recordMap != null) {
        final rec = ModuleRecord.fromMap(recordMap, caseId);
        Navigator.push(
          context,
          AppTheme.fadeSlideRoute(
            page: ModuleRecordDetailScreen(record: rec),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case details not found for ID: $caseId'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading case detail: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  void _openAllAnalyzedCases() {
    if (_reportData == null) return;
    final casesLookup =
        _reportData!['cases_lookup'] as Map<String, dynamic>? ?? {};
    final allIds = casesLookup.keys.toList();
    final meta = _reportData!['metadata'] as Map<String, dynamic>? ?? {};
    _showCaseListDialog(
      'All Warrant & Summons Cases (${meta['month']}/${meta['year']})',
      allIds,
    );
  }

  void _showCaseListDialog(String title, List<dynamic> caseIds) {
    if (caseIds.isEmpty) return;
    final idList = caseIds.map((e) => e.toString()).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.list_alt_rounded, color: AppColors.navyMid),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title (${idList.length})',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          height: 340,
          child: ListView.separated(
            itemCount: idList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final cid = idList[i];
              final casesLookup =
                  _reportData?['cases_lookup'] as Map<String, dynamic>? ?? {};
              final item = casesLookup[cid] as Map<String, dynamic>?;
              final crimeNo = item?['case_number'] ??
                  item?['crime_number'] ??
                  item?['title'] ??
                  cid;
              final status = item?['status'] ?? item?['execution_status'] ?? '';
              final stName = item?['station_name'] ?? '';

              return ListTile(
                dense: true,
                title: Text(
                  crimeNo.toString(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: Text(
                  [
                    if (stName.isNotEmpty) stName,
                    if (status.isNotEmpty) status.toUpperCase()
                  ].join(' • '),
                  style: GoogleFonts.poppins(fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCaseDetail(cid);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_reportData == null) return;
    try {
      final doc = pw.Document();
      final meta = _reportData!['metadata'] as Map<String, dynamic>? ?? {};
      final sections = _reportData!['sections'] as List<dynamic>? ?? [];
      final grandTotal =
          _reportData!['grand_total'] as Map<String, dynamic>? ?? {};

      final month = meta['month'] ?? widget.selectedMonth;
      final year = meta['year'] ?? widget.selectedYear;
      final station = meta['station_name'] ?? 'ALL';
      const months = [
        'JANUARY',
        'FEBRUARY',
        'MARCH',
        'APRIL',
        'MAY',
        'JUNE',
        'JULY',
        'AUGUST',
        'SEPTEMBER',
        'OCTOBER',
        'NOVEMBER',
        'DECEMBER'
      ];
      final monthName = (month >= 1 && month <= 12) ? months[month - 1] : '';
      final defaultTitle =
          'SUMMONS & WARRANT MONTHLY REPORT $monthName $year'.trim();
      final title = meta['report_title_en'] ?? defaultTitle;

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Month: $month/$year   |   Station: $station   |   Total Warrant Cases: ${meta['total_warrant_records_analyzed'] ?? 0}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _pdfCell('SR', isBold: true),
                      _pdfCell('SECTION / CATEGORY',
                          alignLeft: true, isBold: true),
                      _pdfCell('PREVIOUS', isBold: true),
                      _pdfCell('CURRENT', isBold: true),
                      _pdfCell('TOTAL', isBold: true),
                      _pdfCell('EXECUTED', isBold: true),
                      _pdfCell('EXEC %', isBold: true),
                      _pdfCell('UNSERVED', isBold: true),
                      _pdfCell('PENDING', isBold: true),
                    ],
                  ),
                  ...sections.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final sec = entry.value as Map<String, dynamic>;
                    final sum = sec['summary'] as Map<String, dynamic>? ?? {};
                    final title = '${sec['code']} (${sec['title_mr']})';

                    return pw.TableRow(
                      children: [
                        _pdfCell('$idx'),
                        _pdfCell(title, alignLeft: true, isBold: true),
                        _pdfCell('${sum['previous_month'] ?? 0}'),
                        _pdfCell('${sum['current_month'] ?? 0}'),
                        _pdfCell('${sum['total'] ?? 0}', isBold: true),
                        _pdfCell('${sum['executed'] ?? 0}'),
                        _pdfCell('${sum['executed_percent'] ?? "0%"}'),
                        _pdfCell('${sum['unserved'] ?? 0}'),
                        _pdfCell('${sum['pending'] ?? 0}', isBold: true),
                      ],
                    );
                  }),
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.amber100),
                    children: [
                      _pdfCell(''),
                      _pdfCell('GRAND TOTAL (एकूण)',
                          alignLeft: true, isBold: true),
                      _pdfCell('${grandTotal['previous_month'] ?? 0}',
                          isBold: true),
                      _pdfCell('${grandTotal['current_month'] ?? 0}',
                          isBold: true),
                      _pdfCell('${grandTotal['total'] ?? 0}', isBold: true),
                      _pdfCell('${grandTotal['executed'] ?? 0}', isBold: true),
                      _pdfCell('${grandTotal['executed_percent'] ?? "0%"}',
                          isBold: true),
                      _pdfCell('${grandTotal['unserved'] ?? 0}', isBold: true),
                      _pdfCell('${grandTotal['pending'] ?? 0}', isBold: true),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final pdfBytes = await doc.save();
      final fileName =
          'Summons_Warrant_Report_${widget.selectedMonth}_${widget.selectedYear}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  static pw.Widget _pdfCell(String text,
      {bool isBold = false, bool alignLeft = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Align(
        alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3, color: AppColors.navyMid),
            SizedBox(height: 12),
            Text('Calculating Summons & Warrant Report from Database...',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red),
              onPressed: _fetchReport,
            ),
          ],
        ),
      );
    }

    final sections = _reportData?['sections'] as List<dynamic>? ?? [];
    final grandTotal =
        _reportData?['grand_total'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSectionPills(sections),
          const SizedBox(height: 16),
          _buildSummaryCards(sections, grandTotal),
          const SizedBox(height: 16),
          _buildReportTable(sections, grandTotal),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final meta = _reportData?['metadata'] as Map<String, dynamic>? ?? {};
    final month = meta['month'] ?? widget.selectedMonth;
    final year = meta['year'] ?? widget.selectedYear;
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];
    final monthName = (month >= 1 && month <= 12) ? months[month - 1] : '';
    final defaultTitle =
        'SUMMONS & WARRANT MONTHLY REPORT $monthName $year'.trim();
    final title = meta['report_title_en'] ?? defaultTitle;
    final totalAnalyzed = meta['total_warrant_records_analyzed'] ?? 0;
    final stName = meta['station_name'] ?? 'ALL';

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Station: $stName  •  Month: $month/$year  •  Total Warrants: $totalAnalyzed',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final added = await AddWarrantCaseDialog.show(
                  context,
                  initialYear: widget.selectedYear,
                  initialMonth: widget.selectedMonth,
                );
                if (added == true) {
                  _fetchReport();
                }
              },
              icon:
                  const Icon(Icons.add_rounded, size: 15, color: Colors.white),
              label: Text(
                'Add Case',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _openAllAnalyzedCases,
              icon: const Icon(Icons.folder_shared_rounded,
                  size: 15, color: AppColors.navyMid),
              label: Text(
                'View All Cases ($totalAnalyzed)',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyMid),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.navyMid, width: 1.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Station-wise breakdown toggle
            OutlinedButton.icon(
              onPressed: () => setState(
                  () => _showStationBreakdown = !_showStationBreakdown),
              icon: Icon(
                _showStationBreakdown
                    ? Icons.table_chart_rounded
                    : Icons.location_city_rounded,
                size: 15,
                color: _showStationBreakdown
                    ? AppColors.goldPrimary
                    : AppColors.navyMid,
              ),
              label: Text(
                _showStationBreakdown ? 'Section View' : 'Station Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _showStationBreakdown
                      ? AppColors.goldPrimary
                      : AppColors.navyMid,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _showStationBreakdown
                      ? AppColors.goldPrimary
                      : AppColors.navyMid,
                  width: 1.2,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Refresh Report',
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.navyMid),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded,
                  size: 15, color: Colors.white),
              label: Text('Export PDF',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionPills(List<dynamic> sections) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _pillButton('All Sections (सर्व)', 'all'),
          ...sections.map((s) {
            final key = s['key']?.toString() ?? '';
            final titleMr = s['title_mr']?.toString() ?? '';
            final titleEn = s['code']?.toString() ?? '';
            return _pillButton('$titleEn ($titleMr)', key);
          }),
        ],
      ),
    );
  }

  Widget _pillButton(String label, String key) {
    final isSelected = _selectedSectionKey == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedSectionKey = key),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navyMid : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.navyMid : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.navyDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
      List<dynamic> sections, Map<String, dynamic> grandTotal) {
    Map<String, dynamic> targetSummary = grandTotal;
    if (_selectedSectionKey != 'all') {
      final match = sections.firstWhere(
        (s) => s['key'] == _selectedSectionKey,
        orElse: () => null,
      );
      if (match != null) {
        targetSummary = match['summary'] as Map<String, dynamic>? ?? {};
      }
    }

    final total = targetSummary['total'] ?? 0;
    final executed = targetSummary['executed'] ?? 0;
    final executedPct = targetSummary['executed_percent'] ?? '0%';
    final unserved = targetSummary['unserved'] ?? 0;
    final pending = targetSummary['pending'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _summaryCard('Total (बेरीज)', '$total',
              const Color(0xFF1E293B), const Color(0xFFF8FAFC)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard('Executed (तामील)', '$executed ($executedPct)',
              Colors.green.shade800, Colors.green.shade50),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard('Unserved (अदम)', '$unserved',
              Colors.orange.shade800, Colors.orange.shade50),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard('Pending (अखेर)', '$pending', AppColors.dangerRed,
              const Color(0xFFFEF2F2)),
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable(
      List<dynamic> sections, Map<String, dynamic> grandTotal) {
    if (_showStationBreakdown) {
      return _buildStationBreakdownTable(sections);
    }

    // Standard Section-level Table
    final activeSections = _selectedSectionKey == 'all'
        ? sections
        : sections.where((s) => s['key'] == _selectedSectionKey).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
        headingRowHeight: 48,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 46,
        columnSpacing: 18,
        border: TableBorder.all(color: AppColors.lightBorder, width: 1),
        columns: [
          _tblCol('अ.क्र.\nSr.'),
          _tblCol('प्रवर्ग / प्रकार\nCategory'),
          _tblCol('मागील\nPrev'),
          _tblCol('चालू\nCurr'),
          _tblCol('बेरीज\nTotal'),
          _tblCol('तामील\nExec'),
          _tblCol('तामील %\nExec %'),
          _tblCol('अदम\nUnserved'),
          _tblCol('अखेर\nPending'),
        ],
        rows: [
          ...activeSections.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final sec = entry.value;
            final sum = sec['summary'] as Map<String, dynamic>? ?? {};
            final caseIds = sum['case_ids'] as Map<String, dynamic>? ?? {};

            final title = '${sec['code']} (${sec['title_mr']})';

            return DataRow(
              cells: [
                DataCell(Center(
                    child: Text('$idx',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)))),
                DataCell(Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark))),
                _clickableCell('${sum['previous_month'] ?? 0}',
                    caseIds['previous_month'] as List<dynamic>? ?? [], title),
                _clickableCell('${sum['current_month'] ?? 0}',
                    caseIds['current_month'] as List<dynamic>? ?? [], title),
                DataCell(Center(
                  child: Text(
                    '${sum['total'] ?? 0}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                )),
                _clickableCell(
                  '${sum['executed'] ?? 0}',
                  caseIds['executed'] as List<dynamic>? ?? [],
                  '$title - Executed',
                  color: Colors.green.shade700,
                ),
                DataCell(Center(
                  child: Text(
                    '${sum['executed_percent'] ?? "0%"}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                )),
                _clickableCell(
                  '${sum['unserved'] ?? 0}',
                  caseIds['unserved'] as List<dynamic>? ?? [],
                  '$title - Unserved',
                  color: Colors.orange.shade800,
                ),
                _clickableCell(
                  '${sum['pending'] ?? 0}',
                  caseIds['pending'] as List<dynamic>? ?? [],
                  '$title - Pending',
                  color: AppColors.dangerRed,
                ),
              ],
            );
          }),
          // Grand Total row if 'all' is selected
          if (_selectedSectionKey == 'all')
            DataRow(
              color: WidgetStateProperty.all(const Color(0xFFEDF2F7)),
              cells: [
                const DataCell(Center(child: Text(''))),
                DataCell(Text('एकूण (Grand Total)',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark))),
                _clickableCell(
                  '${grandTotal['previous_month'] ?? 0}',
                  grandTotal['case_ids']?['previous_month'] as List<dynamic>? ??
                      [],
                  'Grand Total Previous',
                  isBold: true,
                ),
                _clickableCell(
                  '${grandTotal['current_month'] ?? 0}',
                  grandTotal['case_ids']?['current_month'] as List<dynamic>? ??
                      [],
                  'Grand Total Current',
                  isBold: true,
                ),
                DataCell(Center(
                  child: Text(
                    '${grandTotal['total'] ?? 0}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )),
                _clickableCell(
                  '${grandTotal['executed'] ?? 0}',
                  grandTotal['case_ids']?['executed'] as List<dynamic>? ?? [],
                  'Grand Total Executed',
                  color: Colors.green.shade800,
                  isBold: true,
                ),
                DataCell(Center(
                  child: Text(
                    '${grandTotal['executed_percent'] ?? "0%"}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.green.shade900),
                  ),
                )),
                _clickableCell(
                  '${grandTotal['unserved'] ?? 0}',
                  grandTotal['case_ids']?['unserved'] as List<dynamic>? ?? [],
                  'Grand Total Unserved',
                  color: Colors.orange.shade800,
                  isBold: true,
                ),
                _clickableCell(
                  '${grandTotal['pending'] ?? 0}',
                  grandTotal['case_ids']?['pending'] as List<dynamic>? ?? [],
                  'Grand Total Pending',
                  color: AppColors.dangerRed,
                  isBold: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStationBreakdownTable(List<dynamic> sections) {
    final targetSections = _selectedSectionKey == 'all'
        ? sections
        : sections.where((s) => s['key'] == _selectedSectionKey).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: targetSections.map((sec) {
        final title = '${sec['code']} (${sec['title_mr']})';
        final stations = sec['stations'] as List<dynamic>? ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                ),
                child: Text(
                  '$title — Station Breakdown',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingRowHeight: 40,
                  dataRowMinHeight: 38,
                  dataRowMaxHeight: 42,
                  columnSpacing: 16,
                  border:
                      TableBorder.all(color: AppColors.lightBorder, width: 0.8),
                  columns: [
                    _tblCol('Sr.'),
                    _tblCol('Police Station'),
                    _tblCol('Prev'),
                    _tblCol('Curr'),
                    _tblCol('Total'),
                    _tblCol('Exec'),
                    _tblCol('Exec %'),
                    _tblCol('Unserved'),
                    _tblCol('Pending'),
                  ],
                  rows: stations.map((st) {
                    final sr = st['sr_no'] ?? '';
                    final stName = st['station_name'] ?? '';
                    final caseIds =
                        st['case_ids'] as Map<String, dynamic>? ?? {};

                    return DataRow(
                      cells: [
                        DataCell(Center(child: Text('$sr'))),
                        DataCell(Text(stName.toString(),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600))),
                        _clickableCell(
                            '${st['previous_month'] ?? 0}',
                            caseIds['previous_month'] as List<dynamic>? ?? [],
                            '$stName - Prev'),
                        _clickableCell(
                            '${st['current_month'] ?? 0}',
                            caseIds['current_month'] as List<dynamic>? ?? [],
                            '$stName - Curr'),
                        DataCell(Center(
                            child: Text('${st['total'] ?? 0}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)))),
                        _clickableCell(
                          '${st['executed'] ?? 0}',
                          caseIds['executed'] as List<dynamic>? ?? [],
                          '$stName - Executed',
                          color: Colors.green.shade700,
                        ),
                        DataCell(Center(
                            child: Text('${st['executed_percent'] ?? "0%"}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800)))),
                        _clickableCell(
                          '${st['unserved'] ?? 0}',
                          caseIds['unserved'] as List<dynamic>? ?? [],
                          '$stName - Unserved',
                          color: Colors.orange.shade800,
                        ),
                        _clickableCell(
                          '${st['pending'] ?? 0}',
                          caseIds['pending'] as List<dynamic>? ?? [],
                          '$stName - Pending',
                          color: AppColors.dangerRed,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  DataColumn _tblCol(String label) {
    return DataColumn(
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.navyDark,
        ),
      ),
    );
  }

  DataCell _clickableCell(
    String val,
    List<dynamic> caseIds,
    String title, {
    Color? color,
    bool isBold = false,
  }) {
    final count = int.tryParse(val) ?? 0;
    return DataCell(
      Center(
        child: InkWell(
          onTap: count > 0 ? () => _showCaseListDialog(title, caseIds) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              val,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: count > 0 ? (color ?? AppColors.navyDark) : Colors.grey,
                decoration: count > 0 ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
