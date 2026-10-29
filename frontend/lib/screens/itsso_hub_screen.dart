import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'filtered_pending_screen.dart';

class ItssoHubScreen extends StatefulWidget {
  final String stationName;
  const ItssoHubScreen({super.key, required this.stationName});

  @override
  State<ItssoHubScreen> createState() => _ItssoHubScreenState();
}

class _ItssoHubScreenState extends State<ItssoHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> caseWiseData = [];
  List<dynamic> timeWiseData = [];
  List<dynamic> ioWiseData = [];

  bool isLoading = true;
  String? error;

  String get baseUrl => ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    fetchAllData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
  }

  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final apiService = ApiService();

      final caseRes = await apiService.get('$baseUrl/itsso/cases/');
      if (caseRes.isSuccess && caseRes.data != null) {
        var decoded = caseRes.data;
        caseWiseData = decoded is Map ? (decoded['results'] ?? []) : decoded;
      }

      final timeRes = await apiService.get('$baseUrl/itsso/time-wise/');
      if (timeRes.isSuccess && timeRes.data != null) {
        timeWiseData = timeRes.data is List ? timeRes.data : [];
      }

      final ioRes = await apiService.get('$baseUrl/itsso/io-wise/');
      if (ioRes.isSuccess && ioRes.data != null) {
        ioWiseData = ioRes.data is List ? ioRes.data : [];
      }
    } catch (e) {
      debugPrint("Error fetching ITSSO data: $e");
      error = "Failed to load ITSSO data.";
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return RefreshIndicator(
      onRefresh: fetchAllData,
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
    if (caseWiseData.isEmpty) {
      return _buildEmptyState(
        title: "No POCSO Cases Found",
        subtitle: "Cases registered under POCSO will appear here",
        icon: Icons.category_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAllData,
      color: AppColors.navyMid,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.navyDark),
                  headingTextStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 11.5,
                  ),
                  dataTextStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightText,
                    fontSize: 11.5,
                  ),
                  horizontalMargin: 12,
                  columnSpacing: 18,
                  columns: const [
                    DataColumn(label: Text('Sr. No.')),
                    DataColumn(label: Text('CR No.')),
                    DataColumn(label: Text('Section/Act')),
                    DataColumn(label: Text('Charge Sheet Date')),
                    DataColumn(label: Text('IO Name')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: List.generate(caseWiseData.length, (index) {
                    final caseItem = caseWiseData[index];
                    final isGreen = caseItem['itsso_status_color']
                            ?.toString()
                            .toLowerCase() ==
                        'green';
                    final bg =
                        index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFD);

                    return DataRow(
                      color: WidgetStateProperty.all(bg),
                      cells: [
                        DataCell(Text(
                            caseItem['sr_no']?.toString() ?? '${index + 1}')),
                        DataCell(
                            Text(caseItem['case_number']?.toString() ?? '—')),
                        DataCell(
                            Text(caseItem['section_act']?.toString() ?? '—')),
                        DataCell(Text(
                            caseItem['charge_sheet_date']?.toString() ??
                                'Pending')),
                        DataCell(Text(
                            caseItem['assigned_officer']?.toString() ??
                                'Unassigned')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isGreen
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.15)
                                  : const Color(0xFFEF4444)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isGreen
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.4)
                                    : const Color(0xFFEF4444)
                                        .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              caseItem['itsso_status']?.toString() ?? 'Pending',
                              style: GoogleFonts.poppins(
                                color: isGreen
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB91C1C),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          (caseItem['action_required'] == true)
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    minimumSize: const Size(70, 28),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () async {
                                    try {
                                      await ApiService().post(
                                        '$baseUrl/itsso/cases/${caseItem['id']}/action/',
                                        body: {},
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "Reminder sent to IO for case ${caseItem['case_number']}"),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "Reminder sent to IO for case ${caseItem['case_number']}"),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    'Remind IO',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : const Text('—'),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeWiseTab() {
    if (timeWiseData.isEmpty) {
      return _buildEmptyState(
        title: "No Time Intervals Found",
        subtitle: "Duration-wise breakdown will appear here",
        icon: Icons.schedule_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAllData,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: timeWiseData.length,
        itemBuilder: (context, index) {
          final item = timeWiseData[index];
          final p = item['period']?.toString() ?? '';
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
                      page: FilteredPendingScreen(
                        title: 'ITSSO (POCSO) - $p',
                        category: 'pocso',
                        startDate: start?.toIso8601String().split('T')[0],
                        endDate: end?.toIso8601String().split('T')[0],
                        isVictim: true,
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
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          p,
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
                            color: AppColors.navyMid.withValues(alpha: 0.15),
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
    if (ioWiseData.isEmpty) {
      return _buildEmptyState(
        title: "No Officers Found",
        subtitle:
            "POCSO cases mapped to investigating officers will appear here",
        icon: Icons.badge_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAllData,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: ioWiseData.length,
        itemBuilder: (context, index) {
          final item = ioWiseData[index];
          final ioName = item['io_name']?.toString() ?? 'Unassigned';
          final ioRank = item['io_rank']?.toString() ?? '';
          final stationName = item['station_name']?.toString() ?? '';
          final count =
              (item['itsso_count'] ?? item['count'] as num?)?.toInt() ?? 0;

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
                        title: 'ITSSO (POCSO) - $ioName',
                        category: 'pocso',
                        ioUid: item['io_uid']?.toString() ?? ioName,
                        isVictim: true,
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
                            horizontal: 14, vertical: 6),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          'ITSSO',
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
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.navyMid),
              )
            : Padding(
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
