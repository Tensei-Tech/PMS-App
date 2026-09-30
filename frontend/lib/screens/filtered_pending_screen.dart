import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/pending_table_firestore_mapper.dart';
import '../widgets/pending_cases_demo_data_table.dart';
import '../modules/core/models/base_record.dart';

class FilteredPendingScreen extends StatefulWidget {
  final String title;
  final String? ioUid;
  final String? startDate;
  final String? endDate;

  const FilteredPendingScreen({
    super.key,
    required this.title,
    this.ioUid,
    this.startDate,
    this.endDate,
  });

  @override
  State<FilteredPendingScreen> createState() => _FilteredPendingScreenState();
}

class _FilteredPendingScreenState extends State<FilteredPendingScreen> {
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
      final dataList = await _backend.fetchPendingCases(
        ioUid: widget.ioUid,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (!mounted) return;

      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final mappedRows =
            pendingModuleRecordsToTableRows(records, DateTime.now());
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
                              child: PendingCasesDemoDataTable(
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
