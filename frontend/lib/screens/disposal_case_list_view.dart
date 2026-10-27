import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/excel_export_helper.dart';

class DisposalCaseListView extends StatefulWidget {
  final String? ioUid;
  final String? startDate;
  final String? endDate;
  final String? crimeType;
  final void Function(List<Map<String, dynamic>> records)? onRecordsLoaded;

  const DisposalCaseListView({
    super.key,
    this.ioUid,
    this.startDate,
    this.endDate,
    this.crimeType,
    this.onRecordsLoaded,
  });

  static String getSectionAct(Map<String, dynamic> record) {
    final extra =
        record['extra_fields'] is Map ? record['extra_fields'] as Map : {};
    final secActRaw = record['section_act'] ??
        record['acts_sections'] ??
        record['sections'] ??
        record['section'] ??
        record['act_section'] ??
        record['sectionAct'] ??
        extra['section_act'] ??
        extra['acts_sections'] ??
        extra['sections'] ??
        extra['section'] ??
        extra['act_section'] ??
        extra['sectionAct'];
    final act = (record['act'] ?? extra['act'] ?? '').toString().trim();
    final sec = (record['section'] ?? extra['section'] ?? '').toString().trim();

    if (secActRaw != null && secActRaw.toString().trim().isNotEmpty) {
      return secActRaw.toString().trim();
    }
    if (sec.isNotEmpty || act.isNotEmpty) {
      return '$sec $act'.trim();
    }
    return '—';
  }

  @override
  State<DisposalCaseListView> createState() => _DisposalCaseListViewState();
}

class _DisposalCaseListViewState extends State<DisposalCaseListView> {
  final BackendCaseService _backend = BackendCaseService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  final int _pageSize = 100;
  bool _hasMore = true;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _records = [];
      _hasMore = true;
    });

    try {
      final dataMap = await _backend.fetchDisposalCases(
        ioUid: widget.ioUid,
        startDate: widget.startDate,
        endDate: widget.endDate,
        crimeType: widget.crimeType,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (dataMap != null && dataMap.containsKey('results')) {
        final results = List<Map<String, dynamic>>.from(dataMap['results']);
        final count = dataMap['count'] ?? results.length;

        setState(() {
          _records = results;
          _totalCount = count as int;
          _hasMore = dataMap['next'] != null || _records.length < _totalCount;
          _isLoading = false;
        });
        widget.onRecordsLoaded?.call(_records);
      } else {
        setState(() {
          _error = "Failed to load disposal cases.";
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

  Future<void> _loadNextPage() async {
    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;

    try {
      final dataMap = await _backend.fetchDisposalCases(
        ioUid: widget.ioUid,
        startDate: widget.startDate,
        endDate: widget.endDate,
        crimeType: widget.crimeType,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (dataMap != null && dataMap.containsKey('results')) {
        final results = List<Map<String, dynamic>>.from(dataMap['results']);

        setState(() {
          _records.addAll(results);
          _hasMore = dataMap['next'] != null || _records.length < _totalCount;
          _isLoadingMore = false;
        });
        widget.onRecordsLoaded?.call(_records);
      } else {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildTable(BuildContext context, List<Map<String, dynamic>> records) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double cellFontSize = 11.5;
        const double headerFontSize = 11.5;

        final columnWidths = <int, TableColumnWidth>{
          0: const IntrinsicColumnWidth(),
          1: const FlexColumnWidth(1.2),
          2: const FlexColumnWidth(1.2),
          3: const FlexColumnWidth(1.4),
          4: const FlexColumnWidth(1.6),
          5: const FlexColumnWidth(1.4),
        };

        Widget headerCell(String s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: AppColors.navyDark,
              alignment: Alignment.center,
              child: Text(
                s,
                textAlign: TextAlign.center,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            );

        Widget dataCell(String s, {Alignment align = Alignment.center}) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              alignment: align,
              child: Text(
                s.isEmpty ? '—' : s,
                textAlign: align == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightText,
                  height: 1.15,
                ),
              ),
            );

        final headers = <Widget>[
          headerCell('Sr. No.'),
          headerCell('Cr. No.'),
          headerCell('Sec & Act'),
          headerCell('Head'),
          headerCell('Case Summary'),
          headerCell('IO Name'),
        ];

        TableRow rowFor(int idx, Map<String, dynamic> r) {
          final bg = idx.isEven ? Colors.white : const Color(0xFFF6F8FF);
          final srNo = r['sr_no']?.toString() ?? '${idx + 1}';
          final crNo =
              (r['case_number'] ?? r['cr_no'] ?? r['cr'] ?? '—').toString();
          final secAct = DisposalCaseListView.getSectionAct(r);
          final head = (r['crime_type_name'] ??
                  r['head'] ??
                  r['crime_type'] ??
                  r['sub_category'] ??
                  '—')
              .toString();
          final courtNo =
              ExcelExportHelper.extractDisposalNumbers(r, multiLine: true);
          final io = (r['assigned_officer'] ?? r['io_name'] ?? r['io'] ?? '—')
              .toString();

          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell(srNo),
              dataCell(crNo),
              dataCell(secAct),
              dataCell(head),
              dataCell(courtNo),
              dataCell(io),
            ],
          );
        }

        final tableWidth = math.max(constraints.maxWidth, 900.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Table(
                  columnWidths: columnWidths,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border:
                      TableBorder.all(color: AppColors.lightBorder, width: 1),
                  children: [
                    TableRow(
                      decoration:
                          const BoxDecoration(color: AppColors.navyDark),
                      children: headers,
                    ),
                    for (var i = 0; i < records.length; i++)
                      rowFor(i, records[i]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _records.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_error != null && _records.isEmpty) {
      return Center(
          child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_records.isEmpty) {
      return const Center(child: Text("No disposal cases found"));
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: AppColors.navyMid,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTable(context, _records),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.navyMid)),
              ),
          ],
        ),
      ),
    );
  }
}
