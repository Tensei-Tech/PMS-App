// ignore_for_file: unused_element, unused_field, unused_local_variable, dead_code, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'pending_summary_screen.dart';
import 'filtered_pending_screen.dart';
import '../services/backend_case_service.dart';
import '../modules/core/models/base_record.dart';
import '../utils/pending_io_wise_logic.dart';
import '../utils/category_icon_helper.dart';
import '../widgets/read_only_module_record_hub_card.dart';

class PendingHubScreen extends StatefulWidget {
  final String stationName;

  const PendingHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<PendingHubScreen> createState() => _PendingHubScreenState();
}

class _PendingHubScreenState extends State<PendingHubScreen>
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

    try {
      final dataList = await _backend.fetchPendingCases(pageSize: 1000);

      if (mounted) {
        if (dataList != null) {
          final grouped = <String, Map<String, dynamic>>{};
          for (final m in dataList) {
            final r = ModuleRecord.fromMap(m);
            final rawKey = r.subCategory?.trim().isNotEmpty == true
                ? r.subCategory!.trim()
                : (r.firestoreCategoryDisplayName.trim().isNotEmpty
                    ? r.firestoreCategoryDisplayName.trim()
                    : (r.moduleKey.trim().isNotEmpty
                        ? r.moduleKey.trim()
                        : 'Other'));

            if (!grouped.containsKey(rawKey)) {
              grouped[rawKey] = {
                'crime_type': rawKey,
                'crime_type_name': rawKey,
                'count': 0,
              };
            }
            grouped[rawKey]!['count'] = (grouped[rawKey]!['count'] as int) + 1;
          }

          final results = grouped.values.toList()
            ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

          setState(() {
            _isLoadingCrime = false;
            _crimeWiseData = results;
          });
        } else {
          setState(() {
            _isLoadingCrime = false;
            if (_crimeWiseData == null) {
              _errorCrime = "Failed to load crime-wise pending cases.";
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCrime = false;
          _errorCrime = e.toString();
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

    try {
      final data = await _backend.fetchPendingTimeWise();

      if (mounted) {
        setState(() {
          _isLoadingTime = false;
          if (data != null) {
            _timeWiseData = data;
          } else if (_timeWiseData == null) {
            _errorTime = "Failed to load time-wise pending data.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTime = false;
          _errorTime = e.toString();
        });
      }
    }
  }

  Future<void> _loadIOWise() async {
    if (_ioWiseData == null) {
      setState(() {
        _isLoadingIO = true;
        _errorIO = null;
      });
    }

    try {
      final data = await _backend.fetchPendingIOWise();

      if (mounted) {
        setState(() {
          _isLoadingIO = false;
          if (data != null) {
            _ioWiseData = data;
          } else if (_ioWiseData == null) {
            _errorIO = "Failed to load IO-wise pending data.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingIO = false;
          _errorIO = e.toString();
        });
      }
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
        title: 'No Pending Cases',
        subtitle: 'Pending cases will appear here once registered',
        icon: Icons.hourglass_empty_rounded,
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
                      page: FilteredPendingScreen(
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFE65100).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CategoryIconHelper.buildWidget(
                          typeName,
                          color: const Color(0xFFE65100),
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
                              const Color(0xFFE65100).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                const Color(0xFFE65100).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '$count Cases',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: const Color(0xFFE65100),
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
        subtitle: 'Pending duration breakdown will appear here',
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
                      page: FilteredPendingScreen(
                        title: 'Time Wise - $period',
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
            'Pending counts mapped to investigating officers will appear here',
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
          final count =
              (item['pending_count'] ?? item['count'] as num?)?.toInt() ?? 0;

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
                      page: FilteredPendingScreen(
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
                                  ? [
                                      if (ioRank.isNotEmpty) ioRank,
                                      if (stationName.isNotEmpty) stationName
                                    ].join(' • ')
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
                              const Color(0xFFE65100).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                const Color(0xFFE65100).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hourglass_top_rounded,
                              size: 13,
                              color: Color(0xFFE65100),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$count Pending',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: const Color(0xFFE65100),
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
          'Pending',
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
                    page: PendingSummaryScreen(
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
                elevation: 0,
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
                      SizedBox(width: 6),
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
                      SizedBox(width: 6),
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
                      SizedBox(width: 6),
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

class PendingCategoryIOWiseScreen extends StatefulWidget {
  final String category;
  const PendingCategoryIOWiseScreen({super.key, required this.category});

  @override
  State<PendingCategoryIOWiseScreen> createState() =>
      _PendingCategoryIOWiseScreenState();
}

class _PendingCategoryIOWiseScreenState
    extends State<PendingCategoryIOWiseScreen> {
  final _backend = BackendCaseService();
  bool _isLoading = true;
  String? _error;
  List<ModuleRecord> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dataList =
          await _backend.fetchPendingCases(category: widget.category);
      if (!mounted) return;

      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();

        setState(() {
          _filtered = records;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = "Failed to load cases from backend";
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
    final title = 'IO Wise Pending - ${widget.category}';

    Widget buildBody() {
      if (_isLoading) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.navyMid));
      }
      if (_error != null) {
        return Center(
          child: Text(
            _error!,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightSubText),
          ),
        );
      }

      final buckets = <String, List<ModuleRecord>>{};
      for (final r in _filtered) {
        final io = pendingIoWiseIoDisplayName(r) ?? 'Unknown';
        buckets.putIfAbsent(io, () => []).add(r);
      }

      final names = buckets.keys.toList()..sort((a, b) => a.compareTo(b));

      if (names.isEmpty) {
        return Center(
          child: Text(
            'No IO Wise pending cases for this category',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightSubText),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: names.length,
        itemBuilder: (_, i) {
          final io = names[i];
          final ioCases = buckets[io]!;
          final count = ioCases.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: PendingCategoryIOWiseDetailScreen(
                        ioDisplayName: io,
                        category: widget.category,
                        cases: ioCases,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'IO Name: $io',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      Text(
                        'Cases: $count',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: buildBody()),
          ],
        ),
      ),
    );
  }
}

class PendingCategoryIOWiseDetailScreen extends StatelessWidget {
  const PendingCategoryIOWiseDetailScreen({
    super.key,
    required this.ioDisplayName,
    required this.category,
    required this.cases,
  });

  final String ioDisplayName;
  final String category;
  final List<ModuleRecord> cases;

  @override
  Widget build(BuildContext context) {
    final mine = List<ModuleRecord>.from(cases);
    mine.sort((a, b) => b.incidentDate.compareTo(a.incidentDate));

    final title = '$ioDisplayName - $category';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: mine.isEmpty
                  ? Center(
                      child: Text(
                        'No cases match this officer',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightSubText,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: mine.length,
                      itemBuilder: (_, i) =>
                          ReadOnlyModuleRecordHubCard(record: mine[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
