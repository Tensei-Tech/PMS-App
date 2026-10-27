import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/detected_table_firestore_mapper.dart';
import '../utils/excel_export_helper.dart';
import '../widgets/detected_cases_demo_data_table.dart';
import '../modules/core/models/base_record.dart';

class FilteredDetectedScreen extends StatefulWidget {
  final String title;
  final String? ioUid;
  final String? startDate;
  final String? endDate;

  const FilteredDetectedScreen({
    super.key,
    required this.title,
    this.ioUid,
    this.startDate,
    this.endDate,
  });

  @override
  State<FilteredDetectedScreen> createState() => _FilteredDetectedScreenState();
}

class _FilteredDetectedScreenState extends State<FilteredDetectedScreen> {
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
      final dataList = await _backend.fetchDetectedCases(
        ioUid: widget.ioUid,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (!mounted) return;

      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final mappedRows =
            detectedModuleRecordsToTableRows(records, DateTime.now());
        setState(() {
          _tableRows = mappedRows;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load cases.";
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
                    onTap: _tableRows.isEmpty
                        ? null
                        : () {
                            final sanitizedTitle = widget.title
                                .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
                                .replaceAll(RegExp(r'_+'), '_');
                            ExcelExportHelper.exportDetectedToExcel(
                              dataset: _tableRows,
                              filename: '${sanitizedTitle}_Cases.csv',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${widget.title} exported to Excel successfully.'),
                                backgroundColor: const Color(0xFF107C41),
                              ),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _tableRows.isEmpty
                            ? Colors.grey.shade400
                            : const Color(0xFF107C41),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _tableRows.isEmpty
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
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
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
                              child: DetectedCasesDemoDataTable(
                                isAd: false,
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
