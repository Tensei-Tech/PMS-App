import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/arrested_table_firestore_mapper.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/pdf_unicode_fonts.dart';
import '../widgets/juvenile_cases_data_table.dart';
import '../modules/core/models/base_record.dart';

class FilteredJuvenileScreen extends StatefulWidget {
  final String title;
  final String? ioUid;
  final String? startDate;
  final String? endDate;

  const FilteredJuvenileScreen({
    super.key,
    required this.title,
    this.ioUid,
    this.startDate,
    this.endDate,
  });

  @override
  State<FilteredJuvenileScreen> createState() => _FilteredJuvenileScreenState();
}

class _FilteredJuvenileScreenState extends State<FilteredJuvenileScreen> {
  final BackendCaseService _backend = BackendCaseService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, String>> _tableRows = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dataList = await _backend.fetchJuvenileCases(
        ioUid: widget.ioUid,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (!mounted) return;

      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final mappedRows =
            arrestedModuleRecordsToTableRows(records, DateTime.now());
        setState(() {
          _tableRows = mappedRows;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load juvenile cases.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_tableRows.isEmpty) return;
    final theme = await PdfUnicodeFonts.openSansTheme();
    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Juvenile — ${widget.title}',
      rows: _tableRows
          .map((e) => {
                'Cr. No.': e['cr'] ?? '—',
                'Sec/Act': e['sections'] ?? '—',
                'Head': e['head'] ?? '—',
                'Name of juvenile': e['accused_name'] ?? '—',
                'Age': e['age'] ?? '—',
                'IO name': e['io'] ?? '—',
              })
          .toList(),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'Juvenile_${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf',
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _tableRows.isEmpty ? null : _exportPdf,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _tableRows.isEmpty
                            ? Colors.grey.shade400
                            : AppColors.navyMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Export',
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
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.navyMid))
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: GoogleFonts.poppins(color: Colors.red)))
                      : _tableRows.isEmpty
                          ? const Center(child: Text("No cases found"))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: JuvenileCasesDataTable(
                                realDataRows: _tableRows,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
