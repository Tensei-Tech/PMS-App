import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/excel_export_helper.dart';
import '../utils/pdf_unicode_fonts.dart';
import '../utils/translation_helper.dart';
import '../widgets/custom_pdf_preview_dialog.dart';
import 'disposal_case_list_view.dart';
import 'filtered_disposal_screen.dart';
import '../widgets/sub_tab_host.dart';

class DisposalHubScreen extends StatefulWidget {
  final String stationName;
  final int? groupId;
  final String? groupTitle;

  const DisposalHubScreen({
    super.key,
    required this.stationName,
    this.groupId,
    this.groupTitle,
  });

  @override
  State<DisposalHubScreen> createState() => _DisposalHubScreenState();
}

class _DisposalHubScreenState extends State<DisposalHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BackendCaseService _backend = BackendCaseService();

  List<Map<String, dynamic>>? _crimeWiseData;
  List<Map<String, dynamic>>? _timeWiseData;
  List<Map<String, dynamic>>? _ioWiseData;

  bool _isLoadingCrime = false;
  bool _isLoadingTime = false;
  bool _isLoadingIO = false;
  String? _errorCrime;
  String? _errorTime;
  String? _errorIO;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadCrimeWise();
    _loadTimeWise();
    _loadIOWise();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0 &&
        _crimeWiseData == null &&
        !_isLoadingCrime) {
      _loadCrimeWise();
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

  Future<void> _loadCrimeWise() async {
    if (_crimeWiseData == null) {
      setState(() {
        _isLoadingCrime = true;
        _errorCrime = null;
      });
    }

    final data = await _backend.fetchDisposalCrimeTypeWise(
      groupId: widget.groupId,
    );

    if (mounted) {
      setState(() {
        _isLoadingCrime = false;
        if (data != null) {
          _crimeWiseData = data;
        } else if (_crimeWiseData == null) {
          _errorCrime = "Failed to load crime-wise data from backend.";
        }
      });
    }
  }

  Future<void> _loadTimeWise() async {
    if (_timeWiseData == null) {
      setState(() {
        _isLoadingTime = true;
        _errorTime = null;
      });
    }

    final data = await _backend.fetchDisposalTimeWise(
      groupId: widget.groupId,
    );

    if (mounted) {
      setState(() {
        _isLoadingTime = false;
        if (data != null) {
          _timeWiseData = data;
        } else if (_timeWiseData == null) {
          _errorTime = "Failed to load time-wise data from backend.";
        }
      });
    }
  }

  Future<void> _loadIOWise() async {
    if (_ioWiseData == null) {
      setState(() {
        _isLoadingIO = true;
        _errorIO = null;
      });
    }

    final data = await _backend.fetchDisposalIOWise(
      groupId: widget.groupId,
    );

    if (mounted) {
      setState(() {
        _isLoadingIO = false;
        if (data != null) {
          _ioWiseData = data;
        } else if (_ioWiseData == null) {
          _errorIO = "Failed to load IO-wise data from backend.";
        }
      });
    }
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.navyMid,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 44,
                    color: AppColors.navyMid.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.lightSubText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseWiseTab() {
    if (_isLoadingCrime) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorCrime != null) {
      return Center(
        child: Text(
          _errorCrime!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_crimeWiseData == null || _crimeWiseData!.isEmpty) {
      return _buildEmptyState(
        title: 'No Disposal Cases',
        subtitle: 'Disposed cases will appear here once registered',
        icon: Icons.task_alt_rounded,
        onRefresh: _loadCrimeWise,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCrimeWise,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _crimeWiseData!.length,
        itemBuilder: (context, index) {
          final item = _crimeWiseData![index];
          final typeKey = item['crime_type']?.toString() ?? '';
          final typeName = item['crime_type_name']?.toString() ??
              (typeKey.isNotEmpty ? typeKey : 'Other');
          final count = (item['count'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: FilteredDisposalScreen(
                        title: widget.groupTitle != null
                            ? '${widget.groupTitle} — Case Wise - $typeName'
                            : 'Case Wise - $typeName',
                        crimeType: typeKey,
                        groupId: widget.groupId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF2E7D32),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          typeName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$count ${count == 1 ? 'Case' : 'Cases'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.lightSubText,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeWiseTab() {
    if (_isLoadingTime) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorTime != null) {
      return Center(
        child: Text(
          _errorTime!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_timeWiseData == null || _timeWiseData!.isEmpty) {
      return _buildEmptyState(
        title: 'No Time Intervals Found',
        subtitle: 'Disposal breakdown by turnaround will appear here',
        icon: Icons.schedule_rounded,
        onRefresh: _loadTimeWise,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTimeWise,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _timeWiseData!.length,
        itemBuilder: (context, index) {
          final item = _timeWiseData![index];
          final period = item['period']?.toString() ?? '';
          final count = (item['count'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: FilteredDisposalScreen(
                        title: widget.groupTitle != null
                            ? '${widget.groupTitle} — Time Wise - $period'
                            : 'Time Wise - $period',
                        startDate: item['start_date']?.toString(),
                        endDate: item['end_date']?.toString(),
                        groupId: widget.groupId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.navyMid,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          period,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.navyMid.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          '$count Cases',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.navyMid,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.lightSubText,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIOWiseTab() {
    if (_isLoadingIO) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorIO != null) {
      return Center(
        child: Text(
          _errorIO!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_ioWiseData == null || _ioWiseData!.isEmpty) {
      return _buildEmptyState(
        title: 'No Officers Found',
        subtitle:
            'Disposal counts mapped to investigating officers will appear here',
        icon: Icons.badge_outlined,
        onRefresh: _loadIOWise,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIOWise,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _ioWiseData!.length,
        itemBuilder: (context, index) {
          final item = _ioWiseData![index];
          final ioName = item['io_name']?.toString() ?? 'Unknown';
          final ioRank = item['io_rank']?.toString() ?? '';
          final stationName = item['station_name']?.toString() ?? '';
          final count = (item['disposal_count'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: FilteredDisposalScreen(
                        title: widget.groupTitle != null
                            ? '${widget.groupTitle} — IO Wise - $ioName'
                            : 'IO Wise - $ioName',
                        ioUid: item['io_uid']?.toString(),
                        groupId: widget.groupId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ioName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ioRank.isNotEmpty || stationName.isNotEmpty
                                  ? '$ioRank • $stationName'
                                  : 'Investigating Officer',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2E7D32).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                const Color(0xFF2E7D32).withValues(alpha: 0.16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.task_alt_rounded,
                              size: 13,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$count Disposed',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.lightSubText,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportDetailedPdf() async {
    final groupTitle = widget.groupTitle ?? 'Form 1 to 5';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.navyMid),
                SizedBox(height: 16),
                Text('Fetching disposal cases for PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await _backend.fetchDisposalCases(
        groupId: widget.groupId,
        pageSize: 1000,
      );
      if (mounted) Navigator.pop(context);

      final list =
          (res?['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (list.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No disposed case records found to export.'),
            ),
          );
        }
        return;
      }

      final theme = await PdfUnicodeFonts.openSansTheme();
      final rows = list.asMap().entries.map((entry) {
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
        final io = (r['assigned_officer'] ?? r['io_name'] ?? r['io'] ?? '—')
            .toString();
        final crimeDate = r['incident_date'] != null
            ? DateFormat('dd/MM/yyyy').format(
                DateTime.tryParse(r['incident_date'].toString()) ??
                    DateTime.now())
            : (r['crime_date']?.toString() ?? '—');

        return {
          'Sr. No.': srNo,
          'CR No.': crNo,
          'Category': head,
          'Section / Act': secAct.isNotEmpty ? secAct : '—',
          'Disposal No.':
              (courtNo.isNotEmpty && courtNo != '-' && courtNo != '—')
                  ? courtNo
                  : 'Disposed',
          'IO Name': io,
          'Crime Date': crimeDate,
        };
      }).toList();

      final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
        theme: theme,
        title: 'Disposal — $groupTitle (Detailed Cases Report)',
        rows: rows,
        prependSerial: false,
        columnOrder: const [
          'Sr. No.',
          'CR No.',
          'Category',
          'Section / Act',
          'Disposal No.',
          'IO Name',
          'Crime Date',
        ],
      );

      if (mounted) {
        await CustomPdfPreviewDialog.show(
          context: context,
          title: 'Disposal — $groupTitle Cases Report',
          fileName: 'Disposal_${groupTitle}_All_Cases.pdf',
          buildPdf: (_) async => doc.save(),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  Widget _buildPdfButton() {
    return InkWell(
      onTap: _exportDetailedPdf,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 16,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              TranslationHelper.translate(context, 'PDF'),
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          widget.groupTitle != null
              ? 'Disposal — ${widget.groupTitle}'
              : 'Disposal',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _buildPdfButton(),
            ),
          ),
        ],
        // Form 1 to 5 | Form 6 switch above these tabs when opened from the
        // Disposal dashboard tile.
        bottom: SubTabHost.appBarBottomAbove(
          context,
          PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                controller: _tabController,
                labelColor: AppColors.navyMid,
                unselectedLabelColor: AppColors.lightSubText,
                indicatorColor: AppColors.navyMid,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Case Wise'),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Time Wise'),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('IO Wise'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCaseWiseTab(),
              _buildTimeWiseTab(),
              _buildIOWiseTab(),
            ],
          ),
        ),
      ),
    );
  }
}
