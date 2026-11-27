import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import 'juvenile_summary_screen.dart';
import 'filtered_juvenile_screen.dart';
import '../modules/core/models/base_record.dart';
import '../utils/translation_helper.dart';
import '../utils/arrested_table_firestore_mapper.dart'; // For converting cases to rows

class JuvenileHubScreen extends StatefulWidget {
  final String stationName;

  const JuvenileHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<JuvenileHubScreen> createState() => _JuvenileHubScreenState();
}

class _JuvenileHubScreenState extends State<JuvenileHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BackendCaseService _backend = BackendCaseService();

  List<Map<String, dynamic>>? _timeWiseData;
  List<Map<String, dynamic>>? _ioWiseData;
  Map<String, List<Map<String, String>>>? _caseWiseData;

  bool _isLoadingTime = false;
  bool _isLoadingIO = false;
  bool _isLoadingCase = false;
  String? _errorTime;
  String? _errorIO;
  String? _errorCase;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadCaseWise();
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
    if (_tabController.index == 0 && _caseWiseData == null && !_isLoadingCase) {
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

  Future<void> _loadCaseWise() async {
    if (_caseWiseData == null) {
      setState(() {
        _isLoadingCase = true;
        _errorCase = null;
      });
    }

    final dataList = await _backend.fetchJuvenileCases();

    if (mounted) {
      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final mappedRows = arrestedTableRowsAll(records, DateTime.now());

        for (var r in mappedRows) {
          if (r['accused_name'] == null || r['accused_name']!.isEmpty) {
            r['accused_name'] = '—';
          }
          if (r['multiple_cr'] == null) {
            r['multiple_cr'] = '—';
          }
        }

        final grouped = <String, List<Map<String, String>>>{};
        for (final r in mappedRows) {
          final head = r['head']?.trim().isNotEmpty == true
              ? r['head']!.trim()
              : 'Other';
          grouped.putIfAbsent(head, () => []).add(r);
        }

        setState(() {
          _isLoadingCase = false;
          _caseWiseData = grouped;
        });
      } else {
        setState(() {
          _isLoadingCase = false;
          if (_caseWiseData == null) {
            _errorCase = "Failed to load case data.";
          }
        });
      }
    }
  }

  Future<void> _loadTimeWise() async {
    if (_timeWiseData == null) {
      setState(() {
        _isLoadingTime = true;
        _errorTime = null;
      });
    }

    final data = await _backend.fetchJuvenileTimeWise();

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

    final data = await _backend.fetchJuvenileIOWise();

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
    bool isCompact = false,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.navyMid,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: isCompact ? 36 : MediaQuery.sizeOf(context).height * 0.15,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 16 : 20),
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: isCompact ? 36 : 44,
                    color: AppColors.navyMid.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isCompact ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: isCompact ? 11.5 : 12.5,
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

  Widget _buildCaseWiseTab(bool isCompact) {
    if (_isLoadingCase) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorCase != null) {
      return Center(
        child: Text(
          _errorCase!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_caseWiseData == null || _caseWiseData!.isEmpty) {
      return _buildEmptyState(
        title: 'No CiCL Cases',
        subtitle: 'Cases involving CiCL will appear here once registered',
        icon: Icons.category_outlined,
        onRefresh: _loadCaseWise,
        isCompact: isCompact,
      );
    }

    final keys = _caseWiseData!.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadCaseWise,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final head = keys[index];
          final cases = _caseWiseData![head] ?? [];

          return Container(
            margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
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
                      page: JuvenileSummaryScreen(
                        liveRows: cases,
                        stationName: widget.stationName,
                        title: head,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 16,
                    vertical: isCompact ? 11 : 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isCompact ? 8 : 10),
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: AppColors.navyMid,
                          size: isCompact ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: isCompact ? 10 : 16),
                      Expanded(
                        child: Text(
                          head,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: isCompact ? 13.5 : 14.5,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 10 : 14,
                          vertical: isCompact ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.navyMid.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '${cases.length} ${cases.length == 1 ? 'Case' : 'Cases'}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isCompact ? 11 : 12,
                            color: AppColors.navyMid,
                          ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 4 : 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.lightSubText,
                        size: isCompact ? 18 : 22,
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

  Widget _buildTimeWiseTab(bool isCompact) {
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
        subtitle: 'Duration-wise CiCL breakdown will appear here',
        icon: Icons.schedule_rounded,
        onRefresh: _loadTimeWise,
        isCompact: isCompact,
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
          final p = item['period']?.toString() ?? '';
          final count = (item['count'] as num?)?.toInt() ?? 0;

          return Container(
            margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
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
                  final now = DateTime.now();
                  DateTime? start, end;

                  if (p == 'Under 1 month') {
                    start = now.subtract(const Duration(days: 30));
                  } else if (p == '1 to 3 months') {
                    start = now.subtract(const Duration(days: 90));
                    end = now.subtract(const Duration(days: 30));
                  } else if (p == '3 to 6 months') {
                    start = now.subtract(const Duration(days: 180));
                    end = now.subtract(const Duration(days: 90));
                  } else if (p == '6 to 12 months') {
                    start = now.subtract(const Duration(days: 365));
                    end = now.subtract(const Duration(days: 180));
                  } else if (p == 'More than 1 year') {
                    end = now.subtract(const Duration(days: 365));
                  } else if (p == 'Under 3 months (Total)') {
                    start = now.subtract(const Duration(days: 90));
                  }

                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: FilteredJuvenileScreen(
                        title: 'CiCL - $p',
                        startDate: start?.toIso8601String().split('T')[0],
                        endDate: end?.toIso8601String().split('T')[0],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 16,
                    vertical: isCompact ? 11 : 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isCompact ? 8 : 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          color: AppColors.navyMid,
                          size: isCompact ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: isCompact ? 10 : 16),
                      Expanded(
                        child: Text(
                          p,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: isCompact ? 13.5 : 14.5,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 10 : 14,
                          vertical: isCompact ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.navyMid.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '$count ${count == 1 ? 'Case' : 'Cases'}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isCompact ? 11 : 12,
                            color: AppColors.navyMid,
                          ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 4 : 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.lightSubText,
                        size: isCompact ? 18 : 22,
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

  Widget _buildIOWiseTab(bool isCompact) {
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
            'CiCL cases mapped to investigating officers will appear here',
        icon: Icons.badge_outlined,
        onRefresh: _loadIOWise,
        isCompact: isCompact,
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
          final count = (item['count'] as num?)?.toInt() ?? 0;

          return Container(
            margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
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
                      page: FilteredJuvenileScreen(
                        title: 'IO Wise - $ioName',
                        ioUid: item['io_uid']?.toString(),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 16,
                    vertical: isCompact ? 11 : 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isCompact ? 38 : 44,
                        height: isCompact ? 38 : 44,
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isCompact ? 10 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ioName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: isCompact ? 13.5 : 14.5,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ioRank.isNotEmpty || stationName.isNotEmpty
                                  ? '$ioRank • $stationName'
                                  : 'Investigating Officer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: isCompact ? 11 : 12,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 10 : 14,
                          vertical: isCompact ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyMid.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.navyMid.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          '$count ${count == 1 ? 'Case' : 'Cases'}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isCompact ? 11 : 12,
                            color: AppColors.navyMid,
                          ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 4 : 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.lightSubText,
                        size: isCompact ? 18 : 22,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          TranslationHelper.translate(context, 'Juvenile'),
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 15 : 16,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isCompact ? 10 : 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: JuvenileSummaryScreen(
                      stationName: widget.stationName,
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: isCompact ? 15 : 16,
              ),
              label: Text(
                'PDF',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 12 : 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                  vertical: isCompact ? 6 : 8,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 12),
            child: TabBar(
              isScrollable: !isCompact,
              tabAlignment: isCompact ? TabAlignment.fill : TabAlignment.start,
              controller: _tabController,
              labelColor: AppColors.navyMid,
              unselectedLabelColor: AppColors.lightSubText,
              indicatorColor: AppColors.navyMid,
              indicatorWeight: 3,
              indicatorSize: isCompact
                  ? TabBarIndicatorSize.tab
                  : TabBarIndicatorSize.label,
              labelPadding: isCompact
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16),
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 12 : 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: isCompact ? 12 : 13,
              ),
              tabs: [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined, size: isCompact ? 14 : 16),
                      SizedBox(width: isCompact ? 4 : 8),
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Case Wise'),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: isCompact ? 14 : 16),
                      SizedBox(width: isCompact ? 4 : 8),
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Time Wise'),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge_outlined, size: isCompact ? 14 : 16),
                      SizedBox(width: isCompact ? 4 : 8),
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('IO Wise'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 12 : 24,
                isCompact ? 10 : 16,
                isCompact ? 12 : 24,
                isCompact ? 10 : 16,
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCaseWiseTab(isCompact),
                  _buildTimeWiseTab(isCompact),
                  _buildIOWiseTab(isCompact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
