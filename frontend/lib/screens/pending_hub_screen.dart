// ignore_for_file: unused_element, unused_field, unused_local_variable, dead_code, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'pending_summary_screen.dart';
import 'filtered_pending_screen.dart';
import '../services/backend_case_service.dart';
import '../modules/core/models/base_record.dart';
import '../utils/pending_io_wise_logic.dart';
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

class _PendingHubScreenState extends State<PendingHubScreen> {
  List<String> get categories => [
        'I to V',
        'Class VI',
        'Prohibition',
        'Gambling',
        'AD',
        'Missing',
        'Application',
        'MV Act',
        'RTI',
        'Preventive',
        'IT Act/Cyber',
      ];

  void _showCategoryMenu(
      BuildContext context, String category, TapDownDetails details) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy + 20,
        details.globalPosition.dx,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'all',
          child: Text('All Cases',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: AppColors.navyDark)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          enabled: false,
          child: Text('Select time range',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightSubText,
                  fontSize: 12)),
        ),
        PopupMenuItem<String>(
            value: 'time_1',
            child: Text('Under 1 month',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.navyDark))),
        PopupMenuItem<String>(
            value: 'time_2',
            child: Text('1 to 3 months',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.navyDark))),
        PopupMenuItem<String>(
            value: 'time_3',
            child: Text('3 to 6 months',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.navyDark))),
        PopupMenuItem<String>(
            value: 'time_4',
            child: Text('6 to 12 months',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.navyDark))),
        PopupMenuItem<String>(
            value: 'time_5',
            child: Text('More than 1 year',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.navyDark))),
        PopupMenuItem<String>(
            value: 'time_6',
            child: Text('Under 3 months (Total)',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.navyDark))),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
            value: 'io_wise',
            child: Text('IO wise',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppColors.navyDark))),
      ],
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(context, category, value);
      }
    });
  }

  void _handleMenuSelection(
      BuildContext context, String category, String value) {
    if (value == 'all') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: FilteredPendingScreen(
            title: category,
            category: category,
          ),
        ),
      );
      return;
    }

    if (value == 'io_wise') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: PendingCategoryIOWiseScreen(category: category),
        ),
      );
      return;
    }

    if (value.startsWith('time_')) {
      final now = DateTime.now();
      DateTime? start, end;
      String p = '';

      if (value == 'time_1') {
        p = 'Under 1 month';
        start = now.subtract(const Duration(days: 30));
      } else if (value == 'time_2') {
        p = '1 to 3 months';
        start = now.subtract(const Duration(days: 90));
        end = now.subtract(const Duration(days: 30));
      } else if (value == 'time_3') {
        p = '3 to 6 months';
        start = now.subtract(const Duration(days: 180));
        end = now.subtract(const Duration(days: 90));
      } else if (value == 'time_4') {
        p = '6 to 12 months';
        start = now.subtract(const Duration(days: 365));
        end = now.subtract(const Duration(days: 180));
      } else if (value == 'time_5') {
        p = 'More than 1 year';
        end = now.subtract(const Duration(days: 365));
      } else if (value == 'time_6') {
        p = 'Under 3 months (Total)';
        start = now.subtract(const Duration(days: 90));
      }

      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: FilteredPendingScreen(
            title: '$category - $p',
            category: category,
            startDate: start?.toIso8601String().split('T')[0],
            endDate: end?.toIso8601String().split('T')[0],
          ),
        ),
      );
    }
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Reports',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a category',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                          page: PendingSummaryScreen(
                              stationName: widget.stationName),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded,
                        color: Colors.white, size: 18),
                    label: Text(
                      'Summary',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2875),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 75,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return GestureDetector(
                      onTapDown: (details) {
                        _showCategoryMenu(context, cat, details);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.folder_open_rounded,
                                  color: Color(0xFF334195), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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
