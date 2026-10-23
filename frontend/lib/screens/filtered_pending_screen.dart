import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/pending_table_firestore_mapper.dart';
import '../widgets/pending_cases_demo_data_table.dart';
import '../modules/core/models/base_record.dart';
import '../utils/pending_io_wise_logic.dart';

class FilteredPendingScreen extends StatefulWidget {
  final String title;
  final String? ioUid;
  final String? category;
  final String? startDate;
  final String? endDate;
  final bool isUndetected;
  final bool isAbsconded;
  final bool isVictim;

  const FilteredPendingScreen({
    super.key,
    required this.title,
    this.ioUid,
    this.category,
    this.startDate,
    this.endDate,
    this.isUndetected = false,
    this.isAbsconded = false,
    this.isVictim = false,
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
      List<Map<String, dynamic>>? dataList;

      if (widget.isAbsconded) {
        dataList = await _backend.fetchAbscondedCases(
          ioUid: widget.ioUid,
          category: widget.category,
          startDate: widget.startDate,
          endDate: widget.endDate,
        );
      } else if (widget.isUndetected) {
        dataList = await _backend.fetchUndetectedCases(
          ioUid: widget.ioUid,
          category: widget.category,
          startDate: widget.startDate,
          endDate: widget.endDate,
        );
      } else if (widget.isVictim) {
        dataList = await _backend.fetchVictimCases(
          category: widget.category,
          startDate: widget.startDate,
          endDate: widget.endDate,
        );
      } else {
        dataList = await _backend.fetchPendingCases(
          ioUid: widget.ioUid,
          category: widget.category,
          startDate: widget.startDate,
          endDate: widget.endDate,
        );
      }

      if (!mounted) return;

      if (dataList != null) {
        var records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        if (widget.isVictim && widget.ioUid != null && widget.ioUid!.isNotEmpty) {
          final target = widget.ioUid!.trim().toLowerCase();
          records = records.where((r) {
            final assigned = (r.assignedOfficer.isNotEmpty
                    ? r.assignedOfficer
                    : (r.extraFields['assigned_officer']?.toString() ?? ''))
                .trim()
                .toLowerCase();
            final ioUid = (r.assignedOfficerUid ?? '').trim().toLowerCase();
            final ioDisplay = (pendingIoWiseIoDisplayName(r) ?? '').trim().toLowerCase();
            return assigned == target || ioUid == target || ioDisplay == target;
          }).toList();
        }
        if (widget.category != null && widget.category!.isNotEmpty) {
          records = records
              .where((r) => pendingRecordMatchesDashboardCategory(
                    r: r,
                    dashboardCategory: widget.category!,
                  ))
              .toList();
        }
        if (widget.startDate != null) {
          final sDate = DateTime.tryParse(widget.startDate!);
          if (sDate != null) {
            records = records
                .where((r) => !r.incidentDate.isBefore(sDate))
                .toList();
          }
        }
        if (widget.endDate != null) {
          final eDate = DateTime.tryParse(widget.endDate!);
          if (eDate != null) {
            records = records
                .where((r) => !r.incidentDate.isAfter(eDate))
                .toList();
          }
        }
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
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ),
                            if (!_isLoading && _error == null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.navyMid
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_tableRows.length} Cases',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navyMid,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.navyMid),
                          )
                        : _error != null
                            ? Center(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.poppins(
                                      color: AppColors.dangerRed),
                                ),
                              )
                            : _tableRows.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: AppColors.navyMid
                                                .withValues(alpha: 0.06),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.schedule_rounded,
                                            size: 48,
                                            color: AppColors.navyMid,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No Cases Found',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navyDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'There are no cases matching this timeframe.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.lightSubText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                            color: Colors.grey
                                                .withValues(alpha: 0.2)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: PendingCasesDemoDataTable(
                                        isAd: false,
                                        realDataRows: _tableRows,
                                        isAbsconded: widget.isAbsconded,
                                        isVictim: widget.isVictim,
                                      ),
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
