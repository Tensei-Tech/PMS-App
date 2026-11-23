// lib/screens/elearning_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/elearning_service.dart';
import '../theme/app_theme.dart';
import '../utils/police_rbac_helper.dart';

class ELearningScreen extends StatefulWidget {
  final String stationName;

  const ELearningScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<ELearningScreen> createState() => _ELearningScreenState();
}

class _ELearningScreenState extends State<ELearningScreen>
    with SingleTickerProviderStateMixin {
  final ELearningService _elearningService = ELearningService();

  TabController? _tabController;

  bool _isLoading = true;
  List<ELearningRecord> _records = [];
  InchargeAnalyticsResponse? _analytics;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedPlatform = 'All';
  String _selectedStatusFilter = 'completed'; // 'completed' or 'not_completed'
  bool _preferTableView = false;

  // Course catalog (Manage Courses tab)
  List<CourseEntry> _courses = [];
  bool _coursesLoading = false;

  List<String> get _availablePlatforms {
    final set = <String>{'All'};
    for (final r in _records) {
      if (r.platform.trim().isNotEmpty) {
        set.add(r.platform.trim());
      }
    }
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _initTabController() {
    _tabController ??= TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    if (_coursesLoading) return;
    setState(() => _coursesLoading = true);
    final courses = await _elearningService.fetchCourses();
    if (mounted) {
      setState(() {
        _courses = courses;
        _coursesLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final station = widget.stationName.isNotEmpty
        ? widget.stationName
        : context.read<AuthProvider>().stationName;

    try {
      final results = await Future.wait([
        _elearningService.fetchRecords(station: station),
        _elearningService.fetchInchargeAnalytics(station: station),
        _elearningService.fetchCourses(),
      ]);

      if (!mounted) return;
      setState(() {
        _records = results[0] as List<ELearningRecord>;
        _analytics = results[1] as InchargeAnalyticsResponse?;
        _courses = results[2] as List<CourseEntry>;
        _coursesLoading = false;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[ELearningScreen] _loadData error: $e\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ELearningRecord> get _filteredRecords {
    return _records.where((record) {
      final matchesSearch = _searchQuery.isEmpty ||
          record.officerName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          record.courseName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          record.platform.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          record.badgeNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesPlatform = _selectedPlatform == 'All' ||
          record.platform.toLowerCase() == _selectedPlatform.toLowerCase();

      return matchesSearch && matchesPlatform;
    }).toList();
  }

  List<OfficerNotDoneStat> get _filteredNotCompletedOfficers {
    final list = _analytics?.officersNotCompleted ?? [];
    if (_searchQuery.isEmpty) return list;
    return list.where((officer) {
      return officer.officerName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          officer.badgeNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          officer.designation
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          officer.stationName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  /// Returns course names from the catalog that the officer has NOT completed.
  List<String> _getOfficerNotCompletedCourses(OfficerNotDoneStat off) {
    if (_courses.isEmpty) {
      // Fallback: use unique course names from all records as the "catalog"
      final allCourseNames = _records.map((r) => r.courseName).toSet();
      final completedByOfficer = _records
          .where((r) =>
              r.officerUid == off.officerUid ||
              r.officerName.trim().toLowerCase() ==
                  off.officerName.trim().toLowerCase())
          .map((r) => r.courseName)
          .toSet();
      return allCourseNames
          .where((c) => !completedByOfficer.contains(c))
          .toList()
        ..sort();
    }
    final completedByOfficer = _records
        .where((r) =>
            r.officerUid == off.officerUid ||
            r.officerName.trim().toLowerCase() ==
                off.officerName.trim().toLowerCase())
        .map((r) => r.courseName.trim().toLowerCase())
        .toSet();
    return _courses
        .where((c) => !completedByOfficer.contains(c.name.trim().toLowerCase()))
        .map((c) => c.name)
        .toList()
      ..sort();
  }

  void _showPendingCoursesPopup(OfficerNotDoneStat off) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (_courses.isEmpty && !_coursesLoading) {
            _coursesLoading = true;
            _elearningService.fetchCourses().then((fetched) {
              if (mounted) {
                setState(() {
                  _courses = fetched;
                  _coursesLoading = false;
                });
                setDialogState(() {});
              }
            }).catchError((_) {
              if (mounted) {
                setState(() => _coursesLoading = false);
                setDialogState(() {});
              }
            });
          }

          final pendingCourses = _getOfficerNotCompletedCourses(off);

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.red.shade400,
                          child: Text(
                            off.officerName.isNotEmpty
                                ? off.officerName[0].toUpperCase()
                                : 'O',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                off.officerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                              if (off.badgeNumber.isNotEmpty)
                                Text(
                                  'Badge: ${off.badgeNumber}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.red.shade700),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                  // Sub-heading
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.pending_actions_rounded,
                            size: 16, color: AppColors.dangerRed),
                        const SizedBox(width: 6),
                        Text(
                          'Pending / Not Completed Courses',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            '${pendingCourses.length} course${pendingCourses.length == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dangerRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Course list
                  if (_coursesLoading && pendingCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child:
                          CircularProgressIndicator(color: AppColors.dangerRed),
                    )
                  else if (pendingCourses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 40, color: Colors.green.shade400),
                          const SizedBox(height: 10),
                          Text(
                            _courses.isEmpty
                                ? 'No course catalog found.\nAdd courses to track progress.'
                                : 'All courses completed!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shrinkWrap: true,
                        itemCount: pendingCourses.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (_, i) {
                          final courseName = pendingCourses[i];
                          // Find catalog entry for more details
                          final catalogEntry = _courses
                              .where((c) =>
                                  c.name.trim().toLowerCase() ==
                                  courseName.trim().toLowerCase())
                              .firstOrNull;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.book_outlined,
                                      size: 16, color: AppColors.dangerRed),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        courseName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                      if (catalogEntry != null) ...[
                                        const SizedBox(height: 3),
                                        Wrap(
                                          spacing: 6,
                                          children: [
                                            if (catalogEntry
                                                .platform.isNotEmpty)
                                              _miniTag(
                                                  catalogEntry.platform,
                                                  const Color(0xFF1D4ED8),
                                                  const Color(0xFFEFF6FF)),
                                            if (catalogEntry.isMandatory)
                                              _miniTag(
                                                  'Mandatory',
                                                  const Color(0xFF991B1B),
                                                  const Color(0xFFFEF2F2)),
                                            if (catalogEntry.durationHours !=
                                                null)
                                              _miniTag(
                                                  '${catalogEntry.durationHours}h',
                                                  const Color(0xFF065F46),
                                                  const Color(0xFFD1FAE5)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.radio_button_unchecked_rounded,
                                    size: 18, color: AppColors.dangerRed),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniTag(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showCompletedCoursesPopup(ELearningRecord item) {
    // All completed records for this officer
    final completedRecords = _records
        .where((r) =>
            r.officerUid == item.officerUid ||
            r.officerName.trim().toLowerCase() ==
                item.officerName.trim().toLowerCase())
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.navyMid,
                      child: Text(
                        item.officerName.isNotEmpty
                            ? item.officerName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.officerName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          if (item.badgeNumber.isNotEmpty)
                            Text(
                              'Badge: ${item.badgeNumber}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.lightSubText),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      color: AppColors.navyDark,
                    ),
                  ],
                ),
              ),
              // Sub-heading
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: AppColors.successGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Completed Courses',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '${completedRecords.length} course${completedRecords.length == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Course list
              if (completedRecords.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No completed courses found.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shrinkWrap: true,
                    itemCount: completedRecords.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (_, i) {
                      final rec = completedRecords[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.school_rounded,
                                  size: 16, color: AppColors.successGreen),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.courseName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (rec.platform.isNotEmpty)
                                        _miniTag(
                                            rec.platform,
                                            const Color(0xFF1D4ED8),
                                            const Color(0xFFEFF6FF)),
                                      if (rec.dateOfCompletion.isNotEmpty)
                                        _miniTag(
                                            rec.dateOfCompletion,
                                            const Color(0xFF065F46),
                                            const Color(0xFFD1FAE5)),
                                      if (rec.certificateNo.isNotEmpty)
                                        _miniTag(
                                            'Cert: ${rec.certificateNo}',
                                            const Color(0xFF7C3AED),
                                            const Color(0xFFF5F3FF)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded,
                                size: 18, color: AppColors.successGreen),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCourseDialog() {
    final auth = context.read<AuthProvider>();
    // User inbuilt name is automatically resolved from current authenticated session
    final inbuiltName = auth.fullName.isNotEmpty
        ? auth.fullName
        : (auth.username.isNotEmpty ? auth.username : 'Police Personnel');
    final inbuiltBadge = auth.badgeNumber.isNotEmpty ? auth.badgeNumber : 'N/A';
    final inbuiltStation =
        auth.stationName.isNotEmpty ? auth.stationName : 'Current Station';

    final courseNameCtrl = TextEditingController();
    final platformCtrl = TextEditingController();
    DateTime completionDate = DateTime.now();
    final certificateNoCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (modalContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: AppColors.navyMid),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Record Course Completion',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Inbuilt Officer Info Card (Auto-filled)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.navyMid,
                              child: Text(
                                inbuiltName.isNotEmpty
                                    ? inbuiltName[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        inbuiltName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.cyanPrimary
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Inbuilt Profile Name',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.cyanDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Badge: $inbuiltBadge • Station: $inbuiltStation',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.lightSubText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Course Name Field
                      Text(
                        'Course Name *',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: courseNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Cyber Crime First Responder',
                          prefixIcon:
                              const Icon(Icons.menu_book_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Platform of the Course Field (Manual Entry)
                      Text(
                        'Platform of the Course *',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: platformCtrl,
                        decoration: InputDecoration(
                          hintText:
                              'Enter platform name (e.g. iGOT Karmayogi, CDTI, Coursera)',
                          prefixIcon:
                              const Icon(Icons.language_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date of Completion Field
                      Text(
                        'Date of Completion *',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: modalContext,
                            initialDate: completionDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => completionDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: Colors.black54),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('yyyy-MM-dd').format(completionDate),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                              const Spacer(),
                              const Text('Change',
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Certificate No. Field (Optional)
                      Text(
                        'Certificate Number (Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: certificateNoCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. IGOT-2026-98124',
                          prefixIcon:
                              const Icon(Icons.verified_outlined, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final courseName = courseNameCtrl.text.trim();
                          if (courseName.isEmpty) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter course name')),
                            );
                            return;
                          }

                          final platform = platformCtrl.text.trim();
                          if (platform.isEmpty) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please enter the platform name')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final dateStr =
                              DateFormat('yyyy-MM-dd').format(completionDate);
                          final ok =
                              await _elearningService.submitCourseCompletion(
                            courseName: courseName,
                            platform: platform,
                            dateOfCompletion: dateStr,
                            certificateNo: certificateNoCtrl.text.trim(),
                            remarks: remarksCtrl.text.trim(),
                          );

                          if (!modalContext.mounted) return;
                          if (ok) {
                            Navigator.pop(dialogContext);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Course recorded successfully for $inbuiltName!'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                              _loadData();
                            }
                          } else {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Failed to submit course record. Please try again.'),
                                  backgroundColor: AppColors.dangerRed,
                                ),
                              );
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(isSubmitting ? 'Saving...' : 'Save Completion'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddNewCourseDialog() {
    final courseNameCtrl = TextEditingController();
    final platformCtrl = TextEditingController(text: 'iGOT Karmayogi');
    final descriptionCtrl = TextEditingController();
    String selectedCategory = 'General';
    final durationCtrl = TextEditingController();
    bool isMandatory = true;
    bool isSubmitting = false;

    const categories = [
      'General',
      'BNS/BNSS',
      'Cyber Crime',
      'Forensics',
      'Investigation',
      'Traffic',
      'Human Rights',
      'Anti-Corruption',
      'Women Safety',
      'Leadership',
      'First Aid',
      'Other',
    ];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (modalContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.library_add_rounded,
                        color: AppColors.navyMid),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New Course to Catalog',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      // Course Name
                      Text('Course Name *',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: courseNameCtrl,
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Cyber Crime Investigation Fundamentals',
                          prefixIcon:
                              const Icon(Icons.menu_book_rounded, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Platform (Manual Entry)
                      Text('Platform *',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: platformCtrl,
                        decoration: InputDecoration(
                          hintText:
                              'Enter platform name (e.g. iGOT Karmayogi, CDTI, Coursera)',
                          prefixIcon:
                              const Icon(Icons.language_rounded, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Category
                      Text('Category',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                        items: categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      // Duration
                      Text('Duration (hours)',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: durationCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: 'e.g. 4.5',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                          suffixText: 'hrs',
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Description
                      Text('Description',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descriptionCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Brief course overview...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Mandatory toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mandatory Course',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      'Officers are required to complete this course',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.lightSubText)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isMandatory,
                              activeThumbColor: AppColors.navyMid,
                              onChanged: (val) =>
                                  setDialogState(() => isMandatory = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navyMid),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = courseNameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Course name is required'),
                                  backgroundColor: AppColors.dangerRed),
                            );
                            return;
                          }
                          final platform = platformCtrl.text.trim();
                          if (platform.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Platform name is required'),
                                  backgroundColor: AppColors.dangerRed),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          final duration =
                              double.tryParse(durationCtrl.text.trim());
                          final ok = await _elearningService.createCourse(
                            name: name,
                            platform: platform,
                            description: descriptionCtrl.text.trim(),
                            category: selectedCategory,
                            durationHours: duration,
                            isMandatory: isMandatory,
                          );
                          if (!modalContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Course "$name" added to catalog!'
                                    : 'Failed to add course. Please try again.'),
                                backgroundColor: ok
                                    ? AppColors.successGreen
                                    : AppColors.dangerRed,
                              ),
                            );
                            if (ok) _loadCourses();
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.library_add_rounded, size: 18),
                  label: Text(isSubmitting ? 'Saving...' : 'Add to Catalog'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tier = PoliceRbacHelper.getTier(auth);
    final isHighPrivilege = auth.isSupervisor ||
        tier == PoliceRoleTier.stationIncharge ||
        tier == PoliceRoleTier.divisionHead ||
        tier == PoliceRoleTier.districtLeadership ||
        tier == PoliceRoleTier.superAdmin;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    _initTabController();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.navyDark,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: Navigator.canPop(context) ? 0 : 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'E-Learning',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            Text(
              'Station: ${widget.stationName.isNotEmpty ? widget.stationName : auth.stationName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.lightSubText,
              ),
            ),
          ],
        ),
        actions: [
          if (!isMobile) ...[
            OutlinedButton(
              onPressed: _loadData,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _showAddCourseDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                'Add course record',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ] else ...[
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.navyDark, size: 20),
              onPressed: _loadData,
            ),
            IconButton(
              tooltip: 'Add course record',
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.navyDark, size: 22),
              onPressed: _showAddCourseDialog,
            ),
            const SizedBox(width: 4),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.navyDark,
          indicatorWeight: 3,
          labelColor: AppColors.navyDark,
          unselectedLabelColor: AppColors.lightSubText,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
          onTap: (index) {
            if (index == 1 && _courses.isEmpty) _loadCourses();
          },
          tabs: const [
            Tab(text: 'Course records'),
            Tab(text: 'Manage courses'),
          ],
        ),
      ),
      // FAB: My Course for mobile users (desktop uses top-right action button)
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.navyDark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: Text(
                'My Course',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onPressed: _showAddCourseDialog,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCompletedCoursesTableTab(),
                _buildManageCoursesTab(isHighPrivilege: isHighPrivilege),
              ],
            ),
    );
  }

  /// Tab 2: Course Catalog — visible to all; Add New Course only for high-privilege
  Widget _buildManageCoursesTab({bool isHighPrivilege = false}) {
    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Add button
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 500;
                if (isSmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Course Catalog',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navyMid,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text('Add Course',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, fontSize: 12)),
                            onPressed: _showAddNewCourseDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Manage courses available to personnel',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.lightSubText),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Course Catalog',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            'Manage e-learning courses available to station personnel',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.lightSubText),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navyMid,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text('Add New Course',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      onPressed: _showAddNewCourseDialog,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            if (_coursesLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ))
            else if (_courses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.library_books_outlined,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No courses in catalog yet',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "Add New Course" to add the first course to the catalog.',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _courses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final course = _courses[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.navyMid.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.book_rounded,
                                color: AppColors.navyMid, size: 22),
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        course.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                    ),
                                    if (course.isMandatory)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          'Mandatory',
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1D4ED8)),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _courseBadge(
                                        Icons.devices_rounded,
                                        course.platform,
                                        const Color(0xFF7C3AED),
                                        const Color(0xFFF5F3FF)),
                                    _courseBadge(
                                        Icons.category_rounded,
                                        course.category,
                                        const Color(0xFF0369A1),
                                        const Color(0xFFE0F2FE)),
                                    if (course.durationHours != null)
                                      _courseBadge(
                                          Icons.timer_outlined,
                                          '${course.durationHours}h',
                                          const Color(0xFF065F46),
                                          const Color(0xFFD1FAE5)),
                                  ],
                                ),
                                if (course.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    course.description,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.lightSubText),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _courseBadge(
      IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildMobileCompletedCard(int index, ELearningRecord item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showCompletedCoursesPopup(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.navyMid,
                      child: Text(
                        item.officerName.isNotEmpty
                            ? item.officerName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.officerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            'Tap to view all courses',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.lightSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 13, color: AppColors.successGreen),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.lightBorder),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bookmark_border_rounded,
                        size: 16, color: AppColors.navyMid),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.courseName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        item.platform,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_outlined,
                            size: 13, color: AppColors.lightSubText),
                        const SizedBox(width: 4),
                        Text(
                          item.dateOfCompletion.isNotEmpty
                              ? item.dateOfCompletion
                              : 'N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.lightSubText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNotCompletedCard(int index, OfficerNotDoneStat off) {
    final completedCount = _records
        .where((r) =>
            r.officerUid == off.officerUid ||
            r.officerName.trim().toLowerCase() ==
                off.officerName.trim().toLowerCase())
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPendingCoursesPopup(off),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.red.shade400,
                      child: Text(
                        off.officerName.isNotEmpty
                            ? off.officerName[0].toUpperCase()
                            : 'O',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            off.officerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.red.shade900,
                            ),
                          ),
                          Text(
                            'Tap to view pending courses',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending_actions_rounded,
                              size: 13, color: AppColors.dangerRed),
                          SizedBox(width: 4),
                          Text(
                            'Not Completed',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dangerRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.lightBorder),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Badge: ${off.badgeNumber.isNotEmpty ? off.badgeNumber : "—"} • ${off.designation.isNotEmpty ? off.designation : "Officer"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.lightSubText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$completedCount Done',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dangerRed,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCompletionDate(String dateStr) {
    if (dateStr.trim().isEmpty) return '—';
    try {
      final parsed = DateTime.tryParse(dateStr.trim());
      if (parsed != null) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
      }
    } catch (_) {}
    return dateStr;
  }

  Widget _buildStatusMetricCard({
    required double width,
    required bool isNarrow,
    required String title,
    required int count,
    required int total,
    IconData? icon,
    String? customIconText,
    required Color iconColor,
    required Color iconBg,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 12 : 18,
          vertical: isNarrow ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFE2E8F0),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? activeColor : Colors.black)
                  .withValues(alpha: isActive ? 0.08 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isNarrow ? 36 : 40,
              height: isNarrow ? 36 : 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: customIconText != null
                  ? Text(
                      customIconText,
                      style: GoogleFonts.poppins(
                        color: iconColor,
                        fontWeight: FontWeight.w800,
                        fontSize: isNarrow ? 18 : 20,
                      ),
                    )
                  : Icon(
                      icon ?? Icons.check_rounded,
                      color: iconColor,
                      size: isNarrow ? 20 : 22,
                    ),
            ),
            SizedBox(width: isNarrow ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: isNarrow ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: isNarrow ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                      children: [
                        TextSpan(
                          text: '$count',
                          style: TextStyle(
                            color: activeColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' / $total',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: isNarrow ? 13 : 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformDropdown({double? width, bool isExpanded = true}) {
    final currentPlatform = _availablePlatforms.contains(_selectedPlatform)
        ? _selectedPlatform
        : 'All';

    final dropdownWidget = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _selectedPlatform != 'All'
              ? AppColors.navyMid
              : const Color(0xFFCBD5E1),
          width: _selectedPlatform != 'All' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            Icons.layers_outlined,
            size: 16,
            color: _selectedPlatform != 'All'
                ? AppColors.navyMid
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentPlatform,
                isDense: true,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.navyDark,
                ),
                borderRadius: BorderRadius.circular(8),
                dropdownColor: Colors.white,
                elevation: 3,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navyDark,
                ),
                items: _availablePlatforms.map((platform) {
                  final isAll = platform == 'All';
                  return DropdownMenuItem<String>(
                    value: platform,
                    child: Text(
                      isAll ? 'All platforms' : platform,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isAll && _selectedPlatform == 'All'
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColors.navyDark,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPlatform = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: dropdownWidget);
    }
    return dropdownWidget;
  }

  Widget _buildCompactSearchBar({double? width}) {
    final searchWidget = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? AppColors.navyMid
              : const Color(0xFFCBD5E1),
          width: _searchQuery.isNotEmpty ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 18,
            color: _searchQuery.isNotEmpty
                ? AppColors.navyMid
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.navyDark,
              ),
              decoration: InputDecoration(
                hintText: 'Search records...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: searchWidget);
    }
    return searchWidget;
  }

  /// Tab 1: Completed Courses Directory
  Widget _buildCompletedCoursesTableTab() {
    final list = _filteredRecords;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final isCompactToolbar = screenWidth < 768;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Metric Overview Cards (Completed vs Not Completed)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final halfWidth = constraints.maxWidth >= 300
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                final apiTotal = _analytics?.summary.totalStationPersonnel ?? 0;
                final apiCompleted =
                    _analytics?.summary.personnelCompletedAtLeastOne ?? 0;
                final apiNotCompleted =
                    _analytics?.summary.personnelNotCompletedAny ?? 0;
                final distinctRecordsCount = _records
                    .map((r) => r.officerName.toLowerCase().trim())
                    .toSet()
                    .length;

                final completedCount =
                    apiCompleted > 0 ? apiCompleted : distinctRecordsCount;
                final notCompletedOfficersList =
                    _analytics?.officersNotCompleted ?? [];
                final notCompletedCount = apiNotCompleted > 0
                    ? apiNotCompleted
                    : notCompletedOfficersList.length;

                final totalPersonnel = apiTotal > 0
                    ? apiTotal
                    : ((completedCount + notCompletedCount > 0)
                        ? (completedCount + notCompletedCount)
                        : (distinctRecordsCount > 0
                            ? distinctRecordsCount
                            : 0));

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Card 1: Completed Courses
                    _buildStatusMetricCard(
                      width: halfWidth,
                      isNarrow: isNarrow,
                      title: 'Completed courses',
                      count: completedCount,
                      total: totalPersonnel,
                      icon: Icons.check_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFFDCFCE7),
                      isActive: _selectedStatusFilter == 'completed',
                      activeColor: const Color(0xFF16A34A),
                      onTap: () =>
                          setState(() => _selectedStatusFilter = 'completed'),
                    ),
                    // Card 2: Not Completed
                    _buildStatusMetricCard(
                      width: halfWidth,
                      isNarrow: isNarrow,
                      title: 'Not completed',
                      count: notCompletedCount,
                      total: totalPersonnel,
                      customIconText: '!',
                      iconColor: const Color(0xFFDC2626),
                      iconBg: const Color(0xFFFEE2E2),
                      isActive: _selectedStatusFilter == 'not_completed',
                      activeColor: const Color(0xFFDC2626),
                      onTap: () => setState(
                          () => _selectedStatusFilter = 'not_completed'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            // 2. Section Header & Controls Toolbar
            if (!isCompactToolbar)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedStatusFilter == 'completed'
                              ? 'Completed records (${list.length})'
                              : 'Not completed records (${_filteredNotCompletedOfficers.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedStatusFilter == 'completed'
                              ? 'Auto-synced with officer profiles'
                              : 'Pending training status',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedStatusFilter == 'completed' &&
                      _availablePlatforms.length > 1) ...[
                    _buildPlatformDropdown(width: 175, isExpanded: true),
                    const SizedBox(width: 12),
                  ],
                  _buildCompactSearchBar(width: 340),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedStatusFilter == 'completed'
                                  ? 'Completed records (${list.length})'
                                  : 'Not completed records (${_filteredNotCompletedOfficers.length})',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedStatusFilter == 'completed'
                                  ? 'Auto-synced with officer profiles'
                                  : 'Pending training status',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMobile)
                        IconButton(
                          icon: Icon(
                            _preferTableView
                                ? Icons.view_agenda_rounded
                                : Icons.table_chart_rounded,
                            color: AppColors.navyMid,
                            size: 20,
                          ),
                          tooltip: _preferTableView
                              ? 'Switch to Cards'
                              : 'Switch to Table',
                          onPressed: () => setState(
                              () => _preferTableView = !_preferTableView),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_selectedStatusFilter == 'completed' &&
                          _availablePlatforms.length > 1) ...[
                        Expanded(
                          flex: 2,
                          child: _buildPlatformDropdown(isExpanded: true),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        flex: 3,
                        child: _buildCompactSearchBar(),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 14),

            // 3. Data Content
            if (_selectedStatusFilter == 'completed') ...[
              if (list.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No course completion records found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Click "+ My Course" to record a training course.',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              else if (isMobile && !_preferTableView)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) =>
                      _buildMobileCompletedCard(i + 1, list[i]),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth),
                                child: DataTable(
                                  horizontalMargin: 20,
                                  columnSpacing: 24,
                                  headingRowHeight: 46,
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 56,
                                  headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFFF8FAFC),
                                  ),
                                  headingTextStyle: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: const Color(0xFF475569),
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        '#',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Officer',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Course',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Platform',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Completed on',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_downward_rounded,
                                            size: 13,
                                            color: Color(0xFF475569),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: list.asMap().entries.map((entry) {
                                    final index = entry.key + 1;
                                    final item = entry.value;

                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith<
                                          Color?>(
                                        (states) => entry.key.isEven
                                            ? Colors.white
                                            : const Color(0xFFFBFBFD),
                                      ),
                                      cells: [
                                        DataCell(
                                          Text(
                                            '$index',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: AppColors.navyDark,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          InkWell(
                                            onTap: () =>
                                                _showCompletedCoursesPopup(
                                                    item),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: Text(
                                                item.officerName,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: AppColors.navyDark,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      AppColors.navyDark,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            item.courseName,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppColors.navyDark,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.platform.isNotEmpty
                                                  ? item.platform
                                                  : '—',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            _formatCompletionDate(
                                                item.dateOfCompletion),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              color: AppColors.navyDark,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check_rounded,
                                                  size: 13,
                                                  color: Color(0xFF16A34A),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Completed',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF16A34A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 12, left: 4, right: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${list.length} of ${_records.length} records',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Rows per page: 25',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ] else ...[
              if (_filteredNotCompletedOfficers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF16A34A), size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Personnel Completed Courses',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Every officer in this police station has completed at least one e-learning training course.',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (isMobile && !_preferTableView)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredNotCompletedOfficers.length,
                  itemBuilder: (ctx, i) => _buildMobileNotCompletedCard(
                      i + 1, _filteredNotCompletedOfficers[i]),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final notDoneList = _filteredNotCompletedOfficers;
                    final totalNotDone =
                        _analytics?.summary.personnelNotCompletedAny ??
                            notDoneList.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth),
                                child: DataTable(
                                  horizontalMargin: 20,
                                  columnSpacing: 24,
                                  headingRowHeight: 46,
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 56,
                                  headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFFF8FAFC),
                                  ),
                                  headingTextStyle: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: const Color(0xFF475569),
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        '#',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Officer',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Badge Number',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Designation',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Station',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows:
                                      notDoneList.asMap().entries.map((entry) {
                                    final idx = entry.key + 1;
                                    final off = entry.value;

                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith<
                                          Color?>(
                                        (states) => entry.key.isEven
                                            ? Colors.white
                                            : const Color(0xFFFBFBFD),
                                      ),
                                      cells: [
                                        DataCell(
                                          Text(
                                            '$idx',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: AppColors.navyDark,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          InkWell(
                                            onTap: () =>
                                                _showPendingCoursesPopup(off),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: Text(
                                                off.officerName,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: AppColors.navyDark,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      AppColors.navyDark,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            off.badgeNumber.isNotEmpty
                                                ? off.badgeNumber
                                                : '—',
                                            style: GoogleFonts.poppins(
                                                fontSize: 13),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            off.designation.isNotEmpty
                                                ? off.designation
                                                : 'Officer',
                                            style: GoogleFonts.poppins(
                                                fontSize: 13),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            off.stationName.isNotEmpty
                                                ? off.stationName
                                                : '—',
                                            style: GoogleFonts.poppins(
                                                fontSize: 13),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEE2E2),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.pending_actions_rounded,
                                                  size: 13,
                                                  color: AppColors.dangerRed,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Not Completed',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.dangerRed,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 12, left: 4, right: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${notDoneList.length} of $totalNotDone records',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Rows per page: 25',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
