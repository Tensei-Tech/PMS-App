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
  final int? groupId;
  final void Function(List<Map<String, dynamic>> records)? onRecordsLoaded;

  const DisposalCaseListView({
    super.key,
    this.ioUid,
    this.startDate,
    this.endDate,
    this.crimeType,
    this.groupId,
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
  Set<String>? _remindedCaseIds = <String>{};
  Set<String>? _sendingCaseIds = <String>{};

  @override
  void initState() {
    super.initState();
    _remindedCaseIds = <String>{};
    _sendingCaseIds = <String>{};
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
        groupId: widget.groupId,
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
        groupId: widget.groupId,
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

  Future<void> _showRemindIoDialog(
    Map<String, dynamic> record,
    String crNo,
    String ioName,
  ) async {
    final caseId = (record['id'] ?? record['pk'] ?? '').toString();
    final effectiveIo = ioName.isNotEmpty && ioName != '—' && ioName != '-'
        ? ioName
        : 'Assigned IO';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Remind to IO',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a supervisory reminder to the Investigating Officer to enter the Court Disposal CC/ST Number?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.navyDark,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.lightText),
                      children: [
                        const TextSpan(
                          text: 'Case (CR No.): ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: crNo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.lightText),
                      children: [
                        const TextSpan(
                          text: 'Assigned IO: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: effectiveIo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(
                        'Reason: CC/ST No. is not entered',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.lightSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Send Reminder',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      (_sendingCaseIds ??= {}).add(caseId);
    });

    try {
      final success = await _backend.sendDisposalReminderToIO(caseId);
      if (!mounted) return;

      if (success) {
        setState(() {
          (_remindedCaseIds ??= {}).add(caseId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder sent to $effectiveIo for case $crNo',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send reminder to $effectiveIo for case $crNo',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reminder: $e'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          (_sendingCaseIds ??= {}).remove(caseId);
        });
      }
    }
  }

  Widget _buildTable(BuildContext context, List<Map<String, dynamic>> records) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double cellFontSize = 11.5;
        const double headerFontSize = 11.5;

        final isMobile = constraints.maxWidth < 650;
        final double tableWidth;
        final Map<int, TableColumnWidth> columnWidths;

        if (isMobile) {
          const srWidth = 48.0;
          final colUnitW = (constraints.maxWidth - srWidth) / 2.5;
          final col4W = math.max(colUnitW * 1.15, 120.0);
          final col5W = math.max(colUnitW * 1.1, 115.0);
          tableWidth = srWidth + (colUnitW * 3) + col4W + col5W;

          columnWidths = <int, TableColumnWidth>{
            0: const FixedColumnWidth(srWidth),
            1: FixedColumnWidth(colUnitW),
            2: FixedColumnWidth(colUnitW),
            3: FixedColumnWidth(colUnitW),
            4: FixedColumnWidth(col4W),
            5: FixedColumnWidth(col5W),
          };
        } else {
          tableWidth = math.max(constraints.maxWidth, 900.0);
          columnWidths = const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.4),
            4: FlexColumnWidth(1.6),
            5: FlexColumnWidth(1.4),
          };
        }

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
          headerCell('Disposal'),
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

          final bool hasCcStNo =
              courtNo.isNotEmpty && courtNo != '—' && courtNo != '-';
          final caseId = (r['id'] ?? r['pk'] ?? '').toString();
          final isReminded = _remindedCaseIds?.contains(caseId) ?? false;
          final isSending = _sendingCaseIds?.contains(caseId) ?? false;

          Widget disposalWidget;
          if (hasCcStNo) {
            disposalWidget = dataCell(courtNo);
          } else {
            disposalWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              alignment: Alignment.center,
              child: isReminded
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEF7EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF31C48D)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 13, color: Color(0xFF0E9F6E)),
                          const SizedBox(width: 4),
                          Text(
                            'Reminded',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0E9F6E),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(85, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: isSending
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.notifications_active_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                      label: Text(
                        isSending ? 'Sending...' : 'Remind to IO',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: isSending
                          ? null
                          : () => _showRemindIoDialog(r, crNo, io),
                    ),
            );
          }

          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell(srNo),
              dataCell(crNo),
              dataCell(secAct),
              dataCell(head),
              disposalWidget,
              dataCell(io),
            ],
          );
        }

        final maxH = constraints.maxHeight;
        final hasFiniteHeight = maxH.isFinite;
        final double estHeight = 44.0 * (records.length + 1) + 20.0;
        final double containerHeight = hasFiniteHeight
            ? maxH
            : math.min(MediaQuery.of(context).size.height * 0.65, estHeight);

        final headerTable = Container(
          decoration: const BoxDecoration(
            color: AppColors.navyDark,
          ),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              verticalInside:
                  BorderSide(color: AppColors.lightBorder, width: 1),
              bottom:
                  BorderSide(color: AppColors.lightBorder, width: 1),
            ),
            children: [
              TableRow(
                decoration:
                    const BoxDecoration(color: AppColors.navyDark),
                children: headers,
              ),
            ],
          ),
        );

        final bodyTable = Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              horizontalInside:
                  BorderSide(color: AppColors.lightBorder, width: 1),
              verticalInside:
                  BorderSide(color: AppColors.lightBorder, width: 1),
            ),
            children: records.isEmpty
                ? [
                    TableRow(
                      children: [
                        for (var c = 0; c < 6; c++)
                          dataCell(c == 0 ? '-' : (c == 2 ? 'No records' : '-')),
                      ],
                    ),
                  ]
                : [
                    for (var i = 0; i < records.length; i++)
                      rowFor(i, records[i]),
                  ],
          ),
        );

        final inner = Container(
          width: tableWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBorder, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerTable,
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      child: bodyTable,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: inner,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            Expanded(
              child: _buildTable(context, _records),
            ),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.navyMid)),
              ),
          ],
        ),
      ),
    );
  }
}
