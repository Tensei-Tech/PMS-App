import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import 'detected_summary_screen.dart';
import 'filtered_detected_screen.dart';
import '../modules/core/models/base_record.dart';
import '../utils/detected_table_firestore_mapper.dart';

class DetectedHubScreen extends StatefulWidget {
  final String stationName;

  const DetectedHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<DetectedHubScreen> createState() => _DetectedHubScreenState();
}

class _DetectedHubScreenState extends State<DetectedHubScreen>
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
    setState(() {
      _isLoadingCase = true;
      _errorCase = null;
    });

    final dataList = await _backend.fetchDetectedCases();

    if (mounted) {
      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final mappedRows =
            detectedModuleRecordsToTableRows(records, DateTime.now());

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
          _errorCase = "Failed to load case data.";
        });
      }
    }
  }

  Future<void> _loadTimeWise() async {
    setState(() {
      _isLoadingTime = true;
      _errorTime = null;
    });

    final data = await _backend.fetchDetectedTimeWise();

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

    final data = await _backend.fetchDetectedIOWise();

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
        title: 'No Detected Cases',
        subtitle: 'Cases detected by investigators will appear here',
        icon: Icons.check_circle_outline_rounded,
        onRefresh: _loadCaseWise,
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
          final cases = _caseWiseData![head]!;
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
                      page: DetectedSummaryScreen(
                        liveRows: cases,
                        stationName: widget.stationName,
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
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF2E7D32),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              head,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Category detected cases breakdown',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
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
                              '${cases.length} ${cases.length == 1 ? 'Case' : 'Cases'}',
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
        subtitle: 'Duration-wise detected breakdown will appear here',
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
          final count = item['count'] ?? 0;
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
                  final now = DateTime.now();
                  DateTime? start, end;
                  final p = item['period'] ?? '';

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
                      page: FilteredDetectedScreen(
                        title: 'Time Wise - $p',
                        startDate: start?.toIso8601String().split('T')[0],
                        endDate: end?.toIso8601String().split('T')[0],
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
                          color: const Color(0xFFF0F2FA),
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
                          item['period'] ?? '',
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
                            color: AppColors.navyMid.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '$count ${count == 1 ? 'Case' : 'Cases'}',
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
        title: 'No IO Data Found',
        subtitle: 'Investigating officer detections will appear here',
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
          final detectedCount = item['detected_count'] ?? 0;
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
                      page: FilteredDetectedScreen(
                        title: 'IO Wise - ${item['io_name'] ?? 'Unknown'}',
                        ioUid: item['io_uid']?.toString(),
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
                              item['io_name'] ?? 'Unknown Officer',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['io_rank'] ?? 'IO'} • ${item['station_name'] ?? 'Station'}',
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
                              '$detectedCount Detected',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          'Detected',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: DetectedSummaryScreen(
                      stationName: widget.stationName,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.assessment_outlined,
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                'Summary',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
