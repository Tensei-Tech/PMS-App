import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import 'pending_summary_screen.dart';
import 'filtered_pending_screen.dart';
import '../modules/core/models/base_record.dart';
import '../utils/pending_table_firestore_mapper.dart';

class AbscondedHubScreen extends StatefulWidget {
  final String stationName;

  const AbscondedHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<AbscondedHubScreen> createState() => _AbscondedHubScreenState();
}

class _AbscondedHubScreenState extends State<AbscondedHubScreen>
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
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

    final dataList = await _backend.fetchAbscondedCases();

    if (mounted) {
      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final mappedRows =
            pendingModuleRecordsToTableRows(records, DateTime.now());

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
          _errorCase = "Failed to load Absconded case data.";
        });
      }
    }
  }

  Future<void> _loadTimeWise() async {
    setState(() {
      _isLoadingTime = true;
      _errorTime = null;
    });

    final data = await _backend.fetchAbscondedTimeWise();

    if (mounted) {
      setState(() {
        _isLoadingTime = false;
        if (data != null) {
          _timeWiseData = data;
        } else {
          _errorTime = "Failed to load time-wise Absconded data.";
        }
      });
    }
  }

  Future<void> _loadIOWise() async {
    setState(() {
      _isLoadingIO = true;
      _errorIO = null;
    });

    final data = await _backend.fetchAbscondedIOWise();

    if (mounted) {
      setState(() {
        _isLoadingIO = false;
        if (data != null) {
          _ioWiseData = data;
        } else {
          _errorIO = "Failed to load IO-wise Absconded data.";
        }
      });
    }
  }

  Widget _buildCaseWiseTab() {
    if (_isLoadingCase) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorCase != null) {
      return Center(
          child:
              Text(_errorCase!, style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_caseWiseData == null || _caseWiseData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "No Absconded cases found",
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final keys = _caseWiseData!.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final head = keys[index];
        final cases = _caseWiseData![head]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.lightBorder),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: PendingSummaryScreen(
                    title: 'Absconded Cases — Summary',
                    isAbsconded: true,
                    liveRows: cases,
                    stationName: widget.stationName,
                  ),
                ),
              );
            },
            title: Text(
              head,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${cases.length} Cases',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyMid,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeWiseTab() {
    if (_isLoadingTime) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorTime != null) {
      return Center(
          child:
              Text(_errorTime!, style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_timeWiseData == null || _timeWiseData!.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timeWiseData!.length,
      itemBuilder: (context, index) {
        final item = _timeWiseData![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.lightBorder),
          ),
          child: ListTile(
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
                  page: FilteredPendingScreen(
                    title: 'Absconded - $p',
                    startDate: start?.toIso8601String().split('T')[0],
                    endDate: end?.toIso8601String().split('T')[0],
                    isAbsconded: true,
                  ),
                ),
              );
            },
            title: Text(
              item['period'] ?? '',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item['count'] ?? 0} Cases',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyMid,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOWiseTab() {
    if (_isLoadingIO) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navyMid));
    }
    if (_errorIO != null) {
      return Center(
          child:
              Text(_errorIO!, style: GoogleFonts.poppins(color: Colors.red)));
    }
    if (_ioWiseData == null || _ioWiseData!.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ioWiseData!.length,
      itemBuilder: (context, index) {
        final item = _ioWiseData![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.lightBorder),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                AppTheme.fadeSlideRoute(
                  page: FilteredPendingScreen(
                    title: 'Absconded - ${item['io_name'] ?? 'Unknown'}',
                    ioUid: item['io_uid']?.toString(),
                    isAbsconded: true,
                  ),
                ),
              );
            },
            title: Text(
              item['io_name'] ?? 'Unknown',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${item['io_rank'] ?? ''} - ${item['station_name'] ?? ''}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item['Absconded_count'] ?? item['pending_count'] ?? 0} Cases',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyMid,
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
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          'Absconded',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.navyMid,
          unselectedLabelColor: AppColors.lightSubText,
          indicatorColor: AppColors.navyMid,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Case Wise'),
            Tab(text: 'Time Wise'),
            Tab(text: 'IO Wise'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildCaseWiseTab(),
          _buildTimeWiseTab(),
          _buildIOWiseTab(),
        ],
      ),
    );
  }
}
