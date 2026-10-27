import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/excel_export_helper.dart';
import '../utils/pdf_unicode_fonts.dart';
import 'disposal_case_list_view.dart';

class FilteredDisposalScreen extends StatefulWidget {
  final String title;
  final String? ioUid;
  final String? startDate;
  final String? endDate;
  final String? crimeType;

  const FilteredDisposalScreen({
    super.key,
    required this.title,
    this.ioUid,
    this.startDate,
    this.endDate,
    this.crimeType,
  });

  @override
  State<FilteredDisposalScreen> createState() => _FilteredDisposalScreenState();
}

class _FilteredDisposalScreenState extends State<FilteredDisposalScreen> {
  List<Map<String, dynamic>> _records = [];

  void _exportExcel() {
    if (_records.isEmpty) return;
    final sanitizedTitle = widget.title
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    ExcelExportHelper.exportDisposalToExcel(
      dataset: _records,
      filename: 'Disposal_$sanitizedTitle.csv',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.title} exported to Excel successfully.'),
        backgroundColor: const Color(0xFF107C41),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_records.isEmpty) return;
    final theme = await PdfUnicodeFonts.openSansTheme();

    final rows = _records.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final r = entry.value;
      final srNo = r['sr_no']?.toString() ?? '$i';
      final crNo =
          (r['case_number'] ?? r['cr_no'] ?? r['cr'] ?? '—').toString();
      final secAct = DisposalCaseListView.getSectionAct(r);
      final head = (r['crime_type_name'] ??
              r['head'] ??
              r['crime_type'] ??
              r['sub_category'] ??
              '—')
          .toString();
      final courtNo = ExcelExportHelper.extractDisposalNumbers(r);
      final io =
          (r['assigned_officer'] ?? r['io_name'] ?? r['io'] ?? '—').toString();

      return {
        'Sr. No.': srNo,
        'Cr. No.': crNo,
        'Sec & Act': secAct,
        'Head': head,
        'Case Summary': (courtNo.isNotEmpty && courtNo != '-') ? courtNo : '—',
        'IO Name': io,
      };
    }).toList();

    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Disposal — ${widget.title}',
      rows: rows,
      prependSerial: false,
      columnOrder: const [
        'Sr. No.',
        'Cr. No.',
        'Sec & Act',
        'Head',
        'Case Summary',
        'IO Name',
      ],
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'Disposal_${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
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
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _records.isEmpty ? null : _exportExcel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _records.isEmpty
                            ? Colors.grey.shade400
                            : const Color(0xFF107C41),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _records.isEmpty
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF107C41)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.table_chart_rounded,
                              color: Colors.white, size: 17),
                          const SizedBox(width: 5),
                          Text(
                            'Excel',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
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
                    onTap: _records.isEmpty ? null : _exportPdf,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _records.isEmpty
                            ? Colors.grey.shade400
                            : AppColors.navyMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white, size: 17),
                          const SizedBox(width: 5),
                          Text(
                            'PDF',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
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
            ),
            Expanded(
              child: DisposalCaseListView(
                ioUid: widget.ioUid,
                startDate: widget.startDate,
                endDate: widget.endDate,
                crimeType: widget.crimeType,
                onRecordsLoaded: (records) {
                  setState(() => _records = records);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
