import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import 'filtered_disposal_screen.dart';

class DisposalHubScreen extends StatefulWidget {
  final String stationName;

  const DisposalHubScreen({
    super.key,
    required this.stationName,
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

    final data = await _backend.fetchDisposalCrimeTypeWise();

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

    final data = await _backend.fetchDisposalTimeWise();

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

    final data = await _backend.fetchDisposalIOWise();

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
                        title: 'Case Wise - $typeName',
                        crimeType: typeKey,
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
                          color:
                              const Color(0xFF2E7D32).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.task_alt_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
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
                        child: Text(
                          '$count Cases',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: const Color(0xFF2E7D32),
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
                        title: 'Time Wise - $period',
                        startDate: item['start_date']?.toString(),
                        endDate: item['end_date']?.toString(),
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
                        title: 'IO Wise - $ioName',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          'Disposal',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
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
