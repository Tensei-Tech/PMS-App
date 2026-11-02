// lib/screens/fingerprint_hub_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../modules/core/models/base_record.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/arrested_table_firestore_mapper.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/excel_export_helper.dart';
import '../utils/pdf_unicode_fonts.dart';
import '../utils/translation_helper.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';
import '../widgets/nafis_cases_data_table.dart';
import 'nafis_summary_screen.dart';

enum FingerprintFilter {
  all,
  taken,
  pending,
}

class FingerprintHubScreen extends StatefulWidget {
  final String stationName;

  const FingerprintHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<FingerprintHubScreen> createState() => _FingerprintHubScreenState();
}

class _FingerprintHubScreenState extends State<FingerprintHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BackendCaseService _backend = BackendCaseService();

  List<Map<String, dynamic>>? _rawCaseList;
  List<ModuleRecord>? _caseRecords;
  List<Map<String, dynamic>>? _timeWiseData;
  List<Map<String, dynamic>>? _ioWiseData;

  bool _isLoadingCase = false;
  bool _isLoadingTime = false;
  bool _isLoadingIO = false;
  String? _errorCase;
  String? _errorTime;
  String? _errorIO;

  FingerprintFilter _selectedFilter = FingerprintFilter.all;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
    _loadCaseWise();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 0 && _rawCaseList == null && !_isLoadingCase) {
      _loadCaseWise();
    } else if (_tabController.index == 1 &&
        _timeWiseData == null &&
        !_isLoadingTime) {
      _loadTimeWise();
    } else if (_tabController.index == 2 &&
        _ioWiseData == null &&
        !_isLoadingIO) {
      _loadIOWise();
    }
  }

  /// Inspects all possible common form and forensics locations for fingerprint_taken
  static bool isFingerprintTaken(Map<String, dynamic> row, [ModuleRecord? record]) {
    final extra = (row['extra_fields'] is Map)
        ? Map<String, dynamic>.from(row['extra_fields'] as Map)
        : (record?.extraFields ?? {});

    final cf = (extra['commonForm'] is Map)
        ? Map<String, dynamic>.from(extra['commonForm'] as Map)
        : {};
    final inv = (extra['investigationNotes'] is Map)
        ? Map<String, dynamic>.from(extra['investigationNotes'] as Map)
        : (cf['investigationNotes'] is Map
            ? Map<String, dynamic>.from(cf['investigationNotes'] as Map)
            : {});

    // 1. Direct explicit booleans
    if (row['fingerprint_taken'] == true ||
        row['fingerprint_taken']?.toString().toLowerCase() == 'true' ||
        row['fingerprint_taken']?.toString().toLowerCase() == 'yes') {
      return true;
    }
    if (extra['fingerprint_taken'] == true ||
        extra['fingerprint_taken']?.toString().toLowerCase() == 'true' ||
        extra['fingerprint_taken']?.toString().toLowerCase() == 'yes') {
      return true;
    }
    if (cf['fingerprint_taken'] == true ||
        cf['fingerprint_taken']?.toString().toLowerCase() == 'true' ||
        cf['fingerprint_taken']?.toString().toLowerCase() == 'yes') {
      return true;
    }
    if (inv['fingerprint_taken'] == true ||
        inv['fingerprint_taken']?.toString().toLowerCase() == 'true' ||
        inv['fingerprint_taken']?.toString().toLowerCase() == 'yes') {
      return true;
    }

    // 2. Status string checks
    final status = (row['fingerprint_status'] ??
            row['nafis_status'] ??
            extra['fingerprint_status'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    if (status == 'taken' || status == 'done') return true;

    // 3. String values and dates
    final fpVal = (extra['fingerprintVal'] ??
            inv['fingerprintVal'] ??
            cf['fingerprintVal'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    if (fpVal == 'yes' || fpVal == 'true') return true;

    final fpDate = (extra['fingerprintDate'] ??
            inv['fingerprintDate'] ??
            cf['fingerprintDate'] ??
            '')
        .toString()
        .trim();
    if (fpDate.isNotEmpty && fpDate != 'null') return true;

    return false;
  }

  Future<void> _loadCaseWise() async {
    setState(() {
      _isLoadingCase = true;
      _errorCase = null;
    });

    final dataList = await _backend.fetchFingerprintCases();

    if (mounted) {
      if (dataList != null) {
        _rawCaseList = dataList;
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        _caseRecords = records;
        setState(() {
          _isLoadingCase = false;
        });
      } else {
        setState(() {
          _isLoadingCase = false;
          _errorCase = "Failed to load Fingerprint cases.";
        });
      }
    }
  }

  Future<void> _loadTimeWise() async {
    setState(() {
      _isLoadingTime = true;
      _errorTime = null;
    });

    final data = await _backend.fetchNAFISTimeWise();

    if (mounted) {
      setState(() {
        _isLoadingTime = false;
        if (data != null) {
          _timeWiseData = data;
        } else {
          _errorTime = "Failed to load time-wise data from backend.";
        }
      });
    }
  }

  Future<void> _loadIOWise() async {
    setState(() {
      _isLoadingIO = true;
      _errorIO = null;
    });

    final data = await _backend.fetchNAFISIOWise();

    if (mounted) {
      setState(() {
        _isLoadingIO = false;
        if (data != null) {
          _ioWiseData = data;
        } else {
          _errorIO = "Failed to load IO-wise data from backend.";
        }
      });
    }
  }

  List<Map<String, dynamic>> _getProcessedRows() {
    if (_rawCaseList == null) return [];
    final records = _caseRecords ?? [];
    final mappedRows = arrestedTableRowsAll(records, DateTime.now());

    final enrichedRows = <Map<String, dynamic>>[];
    for (var i = 0; i < mappedRows.length; i++) {
      final r = Map<String, dynamic>.from(mappedRows[i]);
      final rawM = i < _rawCaseList!.length ? _rawCaseList![i] : null;
      final m = i < records.length ? records[i] : null;

      final taken = isFingerprintTaken(rawM ?? r, m);
      r['fingerprint_taken'] = taken;
      r['fingerprint_status'] = taken ? 'Taken' : 'Pending';
      r['fingerprint_status_color'] = taken ? 'green' : 'red';
      r['status_label'] = taken ? 'Taken' : 'Pending';

      r['id'] = rawM?['id'] ?? m?.id ?? r['id'];
      r['cr'] = rawM?['case_number'] ?? m?.caseNumber ?? r['cr'];
      r['cr_no'] = r['cr'];
      r['accused_name'] = m?.accused.isNotEmpty == true
          ? m!.accused
          : (rawM?['accused_name'] ?? rawM?['accused'] ?? r['accused_name'] ?? '—');
      r['io_name'] = m?.assignedOfficer.isNotEmpty == true
          ? m!.assignedOfficer
          : (rawM?['assigned_officer'] ?? r['io'] ?? '—');
      r['head'] = rawM?['head'] ??
          rawM?['sub_category'] ??
          (m?.title.isNotEmpty == true ? m!.title : (r['head'] ?? '—'));
      r['section_act'] = rawM?['section_act'] ??
          m?.extraFields['section_act'] ??
          r['section_act'];
      r['charge_sheet_date'] = rawM?['charge_sheet_date'] ??
          m?.extraFields['charge_sheet_date'];
      r['incident_date'] = m?.incidentDate ??
          (rawM?['created_at'] != null
              ? DateTime.tryParse(rawM!['created_at'].toString())
              : null);

      enrichedRows.add(r);
    }

    return enrichedRows;
  }

  List<Map<String, dynamic>> _filterRows(List<Map<String, dynamic>> list) {
    var filtered = list;

    // 1. Status Filter (All, Taken, Pending)
    switch (_selectedFilter) {
      case FingerprintFilter.all:
        break;
      case FingerprintFilter.taken:
        filtered = filtered.where((r) => r['fingerprint_taken'] == true).toList();
        break;
      case FingerprintFilter.pending:
        filtered = filtered.where((r) => r['fingerprint_taken'] != true).toList();
        break;
    }

    // 2. Search Query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final cr = (r['cr'] ?? r['cr_no'] ?? '').toString().toLowerCase();
        final accused = (r['accused_name'] ?? '').toString().toLowerCase();
        final io = (r['io_name'] ?? '').toString().toLowerCase();
        final head = (r['head'] ?? '').toString().toLowerCase();
        final sec = (r['section_act'] ?? '').toString().toLowerCase();
        return cr.contains(_searchQuery) ||
            accused.contains(_searchQuery) ||
            io.contains(_searchQuery) ||
            head.contains(_searchQuery) ||
            sec.contains(_searchQuery);
      }).toList();
    }

    // 3. Date Range Filter
    if (_selectedDateRange != null) {
      final start = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
      );
      final end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );

      filtered = filtered.where((r) {
        final dt = r['incident_date'] as DateTime?;
        if (dt == null) return false;
        return !dt.isBefore(start) && !dt.isAfter(end);
      }).toList();
    }

    return filtered;
  }

  void _openCaseForm(int index, Map<String, dynamic> row) async {
    ModuleRecord? record;
    if (_caseRecords != null && index < _caseRecords!.length) {
      record = _caseRecords![index];
    } else {
      record = ModuleRecord.fromMap(row);
    }
    final head = row['head']?.toString() ?? record.title;

    await Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: DynamicFormScreen(
          categoryId: record.subCategory ?? head,
          moduleLabel: head,
          moduleKey: record.moduleKey.isNotEmpty ? record.moduleKey : 'form_1_5',
          subCategory: record.subCategory ?? head,
          existingRecord: record,
        ),
      ),
    );
    if (mounted) {
      _loadCaseWise();
    }
  }

  void _openTimeWise(String period) {
    final now = DateTime.now();
    DateTime? start, end;

    if (period == 'Under 1 month') {
      start = now.subtract(const Duration(days: 30));
    } else if (period == '1 to 3 months') {
      start = now.subtract(const Duration(days: 90));
      end = now.subtract(const Duration(days: 30));
    } else if (period == '3 to 6 months') {
      start = now.subtract(const Duration(days: 180));
      end = now.subtract(const Duration(days: 90));
    } else if (period == '6 to 12 months') {
      start = now.subtract(const Duration(days: 365));
      end = now.subtract(const Duration(days: 180));
    } else if (period == 'More than 1 year') {
      end = now.subtract(const Duration(days: 365));
    } else if (period == 'Under 3 months (Total)') {
      start = now.subtract(const Duration(days: 90));
    }

    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: NAFISSummaryScreen(
          title: 'Fingerprint — $period',
          startDate: start?.toIso8601String().split('T')[0],
          endDate: end?.toIso8601String().split('T')[0],
          stationName: widget.stationName,
        ),
      ),
    );
  }

  void _openIOWise(Map<String, dynamic> item) {
    final ioName = item['io_name']?.toString() ?? 'Unassigned';
    final ioUid = item['io_uid']?.toString() ?? ioName;

    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: NAFISSummaryScreen(
          title: 'Fingerprint — IO: $ioName',
          ioUid: ioUid,
          stationName: widget.stationName,
        ),
      ),
    );
  }

  // ── Exports ───────────────────────────────────────────────────────────────

  Future<void> _exportPdf(List<Map<String, dynamic>> dataset) async {
    if (dataset.isEmpty) return;
    final theme = await PdfUnicodeFonts.openSansTheme();

    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title: 'Fingerprint Verification Report — ${widget.stationName}',
      rows: dataset,
      columnOrder: [
        'accused_name',
        'cr',
        'section_act',
        'head',
        'io_name',
        'fingerprint_status',
      ],
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Fingerprint_Report.pdf',
    );
  }

  void _exportExcel(List<Map<String, dynamic>> dataset) {
    if (dataset.isEmpty) return;
    final headers = [
      'Sr. No.',
      'Accused Name',
      'CR No.',
      'Section/Act',
      'Head',
      'IO Name',
      'Status',
    ];

    final rows = dataset.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final r = entry.value;
      return [
        '$i',
        r['accused_name']?.toString() ?? '—',
        r['cr']?.toString() ?? '—',
        r['section_act']?.toString() ?? '—',
        r['head']?.toString() ?? '—',
        r['io_name']?.toString() ?? '—',
        r['fingerprint_status']?.toString() ?? 'Pending',
      ];
    }).toList();

    ExcelExportHelper.exportTableToCsv(
      headers: headers,
      rows: rows,
      filename:
          'Fingerprint_${widget.stationName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fingerprint cases exported to Excel successfully.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  // ── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allRows = _getProcessedRows();
    final totalCases = allRows.length;
    final takenCount = allRows.where((r) => r['fingerprint_taken'] == true).length;
    final pendingCount = totalCases - takenCount;

    final visibleRows = _filterRows(allRows);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: Color(0xFF0D9488),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TranslationHelper.translate(context, 'Fingerprint'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    '${widget.stationName} • Fingerprint Verification',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightSubText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Color(0xFF16A34A)),
            tooltip: 'Export to Excel',
            onPressed: visibleRows.isNotEmpty ? () => _exportExcel(visibleRows) : null,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626)),
            tooltip: 'Export PDF',
            onPressed: visibleRows.isNotEmpty ? () => _exportPdf(visibleRows) : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.navyMid,
          unselectedLabelColor: AppColors.lightSubText,
          indicatorColor: AppColors.navyMid,
          indicatorWeight: 3,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: "Case Wise"),
            Tab(text: "Time Wise"),
            Tab(text: "IO Wise"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCaseWiseTab(
            totalCases: totalCases,
            takenCount: takenCount,
            pendingCount: pendingCount,
            visibleRows: visibleRows,
          ),
          _buildTimeWiseTab(),
          _buildIOWiseTab(),
        ],
      ),
    );
  }

  Widget _buildCaseWiseTab({
    required int totalCases,
    required int takenCount,
    required int pendingCount,
    required List<Map<String, dynamic>> visibleRows,
  }) {
    if (_isLoadingCase) {
      return const Center(child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorCase != null) {
      return Center(
        child: Text(_errorCase!, style: GoogleFonts.poppins(color: Colors.red)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Status Cards matching unified UI
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 750;

              final cards = [
                _buildMetricCard(
                  title: 'Total Cases',
                  count: totalCases,
                  filter: FingerprintFilter.all,
                  icon: Icons.fact_check_rounded,
                  accentColor: const Color(0xFF1E40AF),
                  lightBg: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  iconBg: const Color(0xFFDBEAFE),
                  isCompact: isCompact,
                ),
                _buildMetricCard(
                  title: 'Fingerprint Taken',
                  count: takenCount,
                  filter: FingerprintFilter.taken,
                  icon: Icons.verified_user_rounded,
                  accentColor: const Color(0xFF047857),
                  lightBg: const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFA7F3D0),
                  iconBg: const Color(0xFFD1FAE5),
                  isCompact: isCompact,
                ),
                _buildMetricCard(
                  title: 'Fingerprint Pending',
                  count: pendingCount,
                  filter: FingerprintFilter.pending,
                  icon: Icons.hourglass_top_rounded,
                  accentColor: const Color(0xFFDC2626),
                  lightBg: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  iconBg: const Color(0xFFFEE2E2),
                  isCompact: isCompact,
                ),
              ];

              if (isCompact) {
                final double cardWidth;
                if (constraints.maxWidth < 500) {
                  cardWidth = math.max(120.0, (constraints.maxWidth - 16) / 2.45);
                } else {
                  cardWidth = math.max(140.0, (constraints.maxWidth - 24) / 3.45);
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cards
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: cardWidth,
                                child: c,
                              ),
                            ))
                        .toList(),
                  ),
                );
              }

              return Row(
                children: cards
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: c,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ),

        // 2. Secondary Filter & Actions Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFF1F5F9)),
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, filterConstraints) {
              final isNarrow = filterConstraints.maxWidth < 620;

              final searchWidget = SizedBox(
                width: isNarrow ? 170.0 : null,
                height: 38,
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.navyDark),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    hintText: TranslationHelper.translate(context, 'Search...'),
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.lightSubText.withValues(alpha: 0.7),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: AppColors.navyMid),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? InkWell(
                            onTap: _searchCtrl.clear,
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.lightSubText),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                ),
              );

              final actionWidgets = [
                const SizedBox(width: 8),
                _buildDateFilterMenu(context),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: TranslationHelper.translate(context, 'Export PDF'),
                  onPressed: visibleRows.isNotEmpty ? () => _exportPdf(visibleRows) : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: Color(0xFFDC2626), size: 20),
                ),
                IconButton(
                  tooltip: TranslationHelper.translate(context, 'Export Excel'),
                  onPressed: visibleRows.isNotEmpty ? () => _exportExcel(visibleRows) : null,
                  icon: const Icon(Icons.table_chart_outlined,
                      color: Color(0xFF16A34A), size: 20),
                ),
              ];

              if (isNarrow) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      searchWidget,
                      ...actionWidgets,
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(child: searchWidget),
                  ...actionWidgets,
                ],
              );
            },
          ),
        ),

        // 3. Main Data Table
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCaseWise,
            color: AppColors.navyMid,
            child: visibleRows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 48,
                          color: AppColors.navyMid.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Fingerprint cases found',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightSubText,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: NAFISCasesDataTable(
                      realDataRows: visibleRows,
                      rawRecords: _caseRecords,
                      onRowTap: (idx, row) => _openCaseForm(idx, row),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required FingerprintFilter filter,
    required IconData icon,
    required Color accentColor,
    required Color lightBg,
    required Color borderColor,
    required Color iconBg,
    bool isCompact = false,
  }) {
    final isSelected = _selectedFilter == filter;

    final iconBoxSize = isCompact ? 30.0 : 38.0;
    final iconSize = isCompact ? 15.0 : 18.0;
    final cardPaddingH = isCompact ? 8.0 : 12.0;
    final cardPaddingV = isCompact ? 8.0 : 10.0;
    final titleFontSize = isCompact ? 10.5 : 11.5;
    final countFontSize = isCompact ? 15.5 : 18.0;
    final recordsFontSize = isCompact ? 9.0 : 10.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? lightBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFilter = filter;
            });
          },
          borderRadius: BorderRadius.circular(12),
          hoverColor: accentColor.withValues(alpha: 0.04),
          splashColor: accentColor.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: cardPaddingH, vertical: cardPaddingV),
            child: Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                  ),
                  child: Center(
                    child: Icon(icon, color: accentColor, size: iconSize),
                  ),
                ),
                SizedBox(width: isCompact ? 6.0 : 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TranslationHelper.translate(context, title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? accentColor : AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              fontSize: countFontSize,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? accentColor : AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              TranslationHelper.translate(context, 'records'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: recordsFontSize,
                                fontWeight: FontWeight.w400,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: isCompact ? 8.0 : 10.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: TranslationHelper.translate(context, 'Filter by Date'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedDateRange != null
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedDateRange != null
                ? const Color(0xFF3B82F6)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Icon(
          Icons.calendar_today_rounded,
          size: 16,
          color: _selectedDateRange != null
              ? const Color(0xFF3B82F6)
              : AppColors.navyMid,
        ),
      ),
      onSelected: (val) async {
        final now = DateTime.now();
        if (val == 'all') {
          setState(() => _selectedDateRange = null);
        } else if (val == 'today') {
          setState(() => _selectedDateRange =
              DateTimeRange(start: now, end: now));
        } else if (val == 'week') {
          setState(() => _selectedDateRange = DateTimeRange(
                start: now.subtract(const Duration(days: 7)),
                end: now,
              ));
        } else if (val == 'month') {
          setState(() => _selectedDateRange = DateTimeRange(
                start: now.subtract(const Duration(days: 30)),
                end: now,
              ));
        } else if (val == 'custom') {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDateRange: _selectedDateRange,
          );
          if (range != null) {
            setState(() => _selectedDateRange = range);
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('All Dates')),
        const PopupMenuItem(value: 'today', child: Text('Today')),
        const PopupMenuItem(value: 'week', child: Text('Last 7 Days')),
        const PopupMenuItem(value: 'month', child: Text('Last 30 Days')),
        const PopupMenuItem(value: 'custom', child: Text('Custom Range...')),
      ],
    );
  }

  Widget _buildTimeWiseTab() {
    if (_isLoadingTime) {
      return const Center(child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorTime != null) {
      return Center(
        child: Text(_errorTime!, style: GoogleFonts.poppins(color: Colors.red)),
      );
    }
    if (_timeWiseData == null || _timeWiseData!.isEmpty) {
      return const Center(child: Text("No time-wise data found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timeWiseData!.length,
      itemBuilder: (context, index) {
        final item = _timeWiseData![index];
        final period = item['period'] ?? '';
        final count = item['count'] ?? 0;

        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openTimeWise(period),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF0D9488),
                  size: 22,
                ),
              ),
              title: Text(
                period,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.navyDark,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? const Color(0xFFFFEBEE)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: count > 0
                            ? const Color(0xFFEF5350)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: count > 0
                            ? const Color(0xFFC62828)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOWiseTab() {
    if (_isLoadingIO) {
      return const Center(child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorIO != null) {
      return Center(
        child: Text(_errorIO!, style: GoogleFonts.poppins(color: Colors.red)),
      );
    }
    if (_ioWiseData == null || _ioWiseData!.isEmpty) {
      return const Center(child: Text("No IO data found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ioWiseData!.length,
      itemBuilder: (context, index) {
        final item = _ioWiseData![index];
        final ioName = item['io_name'] ?? 'Unassigned';
        final station = item['station_name'] ?? '';
        final count = item['pending_count'] ?? 0;

        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openIOWise(item),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                child: const Icon(Icons.person_rounded, color: Color(0xFF0D9488)),
              ),
              title: Text(
                ioName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.navyDark,
                ),
              ),
              subtitle: Text(
                station,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.lightSubText,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? const Color(0xFFFFEBEE)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: count > 0
                            ? const Color(0xFFEF5350)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '$count Pending',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: count > 0
                            ? const Color(0xFFC62828)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
