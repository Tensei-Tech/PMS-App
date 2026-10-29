// ignore_for_file: unused_element, unused_field, unused_local_variable, dead_code, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'pending_summary_screen.dart';
import 'filtered_pending_screen.dart';
import '../services/backend_case_service.dart';
import '../modules/core/models/base_record.dart';
import '../utils/pending_io_wise_logic.dart';
import '../utils/pending_table_firestore_mapper.dart';
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

    final dataList = await _backend.fetchPendingCases();

    if (mounted) {
      if (dataList != null) {
        final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
        final mappedRows =
            pendingModuleRecordsToTableRows(records, DateTime.now());

        final grouped = <String, List<Map<String, String>>>{};
        for (int i = 0; i < mappedRows.length; i++) {
          final r = mappedRows[i];
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
          _errorCase = "Failed to load pending case data from database.";
        });
      }
    }
  }

  Future<void> _loadTimeWise() async {
    setState(() {
      _isLoadingTime = true;
      _errorTime = null;
    });

    final data = await _backend.fetchPendingTimeWise();

    if (mounted) {
      setState(() {
        _isLoadingTime = false;
        if (data != null) {
          _timeWiseData = data;
        } else {
          _errorTime = "Failed to load time-wise pending data from database.";
        }
      });
    }
  }

  Future<void> _loadIOWise() async {
    setState(() {
      _isLoadingIO = true;
      _errorIO = null;
    });

    final data = await _backend.fetchPendingIOWise();

    if (mounted) {
      setState(() {
        _isLoadingIO = false;
        if (data != null) {
          _ioWiseData = data;
        } else {
          _errorIO = "Failed to load IO-wise pending data from database.";
        }
      });
    }
  }

  Widget _buildCaseWiseTab() {
    if (_isLoadingCase) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorCase != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorCase!, style: GoogleFonts.poppins(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadCaseWise,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyMid),
            ),
          ],
        ),
      );
    }
    if (_caseWiseData == null || _caseWiseData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "No pending cases found",
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
                    liveRows: cases,
                    stationName: widget.stationName,
                    title: 'Pending Cases — $head',
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
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorTime != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorTime!, style: GoogleFonts.poppins(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadTimeWise,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyMid),
            ),
          ],
        ),
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
                    title: 'Pending - $p',
                    startDate: start?.toIso8601String().split('T')[0],
                    endDate: end?.toIso8601String().split('T')[0],
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
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorIO != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorIO!, style: GoogleFonts.poppins(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadIOWise,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyMid),
            ),
          ],
        ),
      );
    }
    if (_ioWiseData == null || _ioWiseData!.isEmpty) {
      return const Center(child: Text("No IO-wise data found"));
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
                    title: 'Pending - ${item['io_name'] ?? 'Unknown'}',
                    ioUid: item['io_uid']?.toString(),
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
                '${item['pending_count'] ?? item['count'] ?? 0} Cases',
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
          'Pending',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navyMid),
            onPressed: () {
              if (_tabController.index == 0) _loadCaseWise();
              if (_tabController.index == 1) _loadTimeWise();
              if (_tabController.index == 2) _loadIOWise();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: PendingSummaryScreen(stationName: widget.stationName),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
              label: Text(
                'Summary',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
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
        children: [
          _buildCaseWiseTab(),
          _buildTimeWiseTab(),
          _buildIOWiseTab(),
        ],
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
