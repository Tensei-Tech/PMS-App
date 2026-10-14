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
  String _selectedPlatform = 'All';
  String _selectedStatusFilter = 'completed'; // 'completed' or 'not_completed'

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
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    if (_coursesLoading) return;
    setState(() => _coursesLoading = true);
    final courses = await _elearningService.fetchCourses();
    if (mounted) setState(() { _courses = courses; _coursesLoading = false; });
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
      ]);

      if (!mounted) return;
      setState(() {
        _records = results[0] as List<ELearningRecord>;
        _analytics = results[1] as InchargeAnalyticsResponse?;
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
          record.officerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          record.courseName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
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
      return officer.officerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          officer.badgeNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          officer.designation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          officer.stationName.toLowerCase().contains(_searchQuery.toLowerCase());
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
    // Ensure courses are loaded for the catalog
    if (_courses.isEmpty && !_coursesLoading) {
      _loadCourses();
    }
    final pendingCourses = _getOfficerNotCompletedCourses(off);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                          if (off.badgeNumber.isNotEmpty)
                            Text(
                              'Badge: ${off.badgeNumber}',
                              style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
              if (_coursesLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.dangerRed),
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
                        style: GoogleFonts.inter(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    courseName,
                                    style: GoogleFonts.inter(
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
                                        if (catalogEntry.platform.isNotEmpty)
                                          _miniTag(
                                              catalogEntry.platform,
                                              const Color(0xFF1D4ED8),
                                              const Color(0xFFEFF6FF)),
                                        if (catalogEntry.isMandatory)
                                          _miniTag('Mandatory',
                                              const Color(0xFF991B1B),
                                              const Color(0xFFFEF2F2)),
                                        if (catalogEntry.durationHours != null)
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
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showCompletedCoursesPopup(ELearningRecord item) {
    // All completed records for this officer
    final completedRecords = _records.where((r) =>
        r.officerUid == item.officerUid ||
        r.officerName.trim().toLowerCase() ==
            item.officerName.trim().toLowerCase()).toList();

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
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          if (item.badgeNumber.isNotEmpty)
                            Text(
                              'Badge: ${item.badgeNumber}',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.lightSubText),
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
                      style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
    final inbuiltStation = auth.stationName.isNotEmpty ? auth.stationName : 'Current Station';

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
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.navyMid),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Record Course Completion',
                      style: GoogleFonts.inter(
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
                                inbuiltName.isNotEmpty ? inbuiltName[0].toUpperCase() : 'P',
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
                                        style: GoogleFonts.inter(
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
                                          color: AppColors.cyanPrimary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
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
                                    style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                          prefixIcon: const Icon(Icons.menu_book_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Platform of the Course Field (Manual Entry)
                      Text(
                        'Platform of the Course *',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: platformCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter platform name (e.g. iGOT Karmayogi, CDTI, Coursera)',
                          prefixIcon: const Icon(Icons.language_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date of Completion Field
                      Text(
                        'Date of Completion *',
                        style: GoogleFonts.inter(
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.black54),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('yyyy-MM-dd').format(completionDate),
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                              const Spacer(),
                              const Text('Change', style: TextStyle(color: Colors.blue, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Certificate No. Field (Optional)
                      Text(
                        'Certificate Number (Optional)',
                        style: GoogleFonts.inter(
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
                          prefixIcon: const Icon(Icons.verified_outlined, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final courseName = courseNameCtrl.text.trim();
                          if (courseName.isEmpty) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              const SnackBar(content: Text('Please enter course name')),
                            );
                            return;
                          }

                          final platform = platformCtrl.text.trim();
                          if (platform.isEmpty) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              const SnackBar(content: Text('Please enter the platform name')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final dateStr = DateFormat('yyyy-MM-dd').format(completionDate);
                          final ok = await _elearningService.submitCourseCompletion(
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
                                  content: Text('Course recorded successfully for $inbuiltName!'),
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
                                  content: Text('Failed to submit course record. Please try again.'),
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
      'General', 'BNS/BNSS', 'Cyber Crime', 'Forensics',
      'Investigation', 'Traffic', 'Human Rights', 'Anti-Corruption',
      'Women Safety', 'Leadership', 'First Aid', 'Other',
    ];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (modalContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.library_add_rounded, color: AppColors.navyMid),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New Course to Catalog',
                      style: GoogleFonts.inter(
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
                      Text('Course Name *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: courseNameCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Cyber Crime Investigation Fundamentals',
                          prefixIcon: const Icon(Icons.menu_book_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Platform (Manual Entry)
                      Text('Platform *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: platformCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter platform name (e.g. iGOT Karmayogi, CDTI, Coursera)',
                          prefixIcon: const Icon(Icons.language_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Category
                      Text('Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      // Duration
                      Text('Duration (hours)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: durationCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'e.g. 4.5',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          isDense: true,
                          suffixText: 'hrs',
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Description
                      Text('Description', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descriptionCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Brief course overview...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Mandatory toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  Text('Mandatory Course', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text('Officers are required to complete this course', style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightSubText)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isMandatory,
                              activeThumbColor: AppColors.navyMid,
                              onChanged: (val) => setDialogState(() => isMandatory = val),
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.navyMid),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = courseNameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Course name is required'), backgroundColor: AppColors.dangerRed),
                            );
                            return;
                          }
                          final platform = platformCtrl.text.trim();
                          if (platform.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Platform name is required'), backgroundColor: AppColors.dangerRed),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          final duration = double.tryParse(durationCtrl.text.trim());
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
                                content: Text(ok ? 'Course "$name" added to catalog!' : 'Failed to add course. Please try again.'),
                                backgroundColor: ok ? AppColors.successGreen : AppColors.dangerRed,
                              ),
                            );
                            if (ok) _loadCourses();
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

    _initTabController();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-Learning Management System',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Station: ${widget.stationName.isNotEmpty ? widget.stationName : auth.stationName}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.navyMid,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
          onTap: (index) {
            if (index == 1 && _courses.isEmpty) _loadCourses();
          },
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Course Records'),
            Tab(icon: Icon(Icons.library_books_rounded, size: 18), text: 'Manage Courses'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      // FAB: My Course for all users
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navyMid,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('My Course'),
        onPressed: _showAddCourseDialog,
      ),
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Catalog',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDark,
                        ),
                      ),
                      Text(
                        'Manage e-learning courses available to station personnel',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightSubText),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navyMid,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text('Add New Course', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  onPressed: _showAddNewCourseDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_coursesLoading)
              const Center(child: Padding(
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
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.library_books_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No courses in catalog yet',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "Add New Course" to add the first course to the catalog.',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
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
                            child: const Icon(Icons.book_rounded, color: AppColors.navyMid, size: 22),
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
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                    ),
                                    if (course.isMandatory)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          'Mandatory',
                                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _courseBadge(Icons.devices_rounded, course.platform, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
                                    _courseBadge(Icons.category_rounded, course.category, const Color(0xFF0369A1), const Color(0xFFE0F2FE)),
                                    if (course.durationHours != null)
                                      _courseBadge(Icons.timer_outlined, '${course.durationHours}h', const Color(0xFF065F46), const Color(0xFFD1FAE5)),
                                  ],
                                ),
                                if (course.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    course.description,
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightSubText),
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

  Widget _courseBadge(IconData icon, String label, Color textColor, Color bgColor) {
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
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  /// Tab 1: Completed Courses Directory
  Widget _buildCompletedCoursesTableTab() {
    final list = _filteredRecords;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filters Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by officer name, course, badge or platform...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      ),
                  ],
                ),
              ),
            ),
            // 2 Status Filter Options: Total / Completed vs Total / Not Completed
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                final halfWidth = isWide
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                final apiTotal = _analytics?.summary.totalStationPersonnel ?? 0;
                final apiCompleted = _analytics?.summary.personnelCompletedAtLeastOne ?? 0;
                final apiNotCompleted = _analytics?.summary.personnelNotCompletedAny ?? 0;
                final distinctRecordsCount = _records.map((r) => r.officerName.toLowerCase().trim()).toSet().length;

                final completedCount = apiCompleted > 0 ? apiCompleted : distinctRecordsCount;
                final notCompletedOfficersList = _analytics?.officersNotCompleted ?? [];
                final notCompletedCount = apiNotCompleted > 0
                    ? apiNotCompleted
                    : notCompletedOfficersList.length;

                final totalPersonnel = apiTotal > 0
                    ? apiTotal
                    : ((completedCount + notCompletedCount > 0)
                        ? (completedCount + notCompletedCount)
                        : (distinctRecordsCount > 0 ? distinctRecordsCount : 0));

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Option 1: Total / Completed
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _selectedStatusFilter = 'completed');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: halfWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedStatusFilter == 'completed'
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedStatusFilter == 'completed'
                                ? AppColors.navyMid
                                : Colors.grey.shade300,
                            width: _selectedStatusFilter == 'completed' ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_selectedStatusFilter == 'completed'
                                      ? AppColors.navyMid
                                      : Colors.black)
                                  .withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF16A34A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Completed Course',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedStatusFilter == 'completed'
                                          ? AppColors.navyDark
                                          : AppColors.lightSubText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navyDark,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '$completedCount',
                                          style: const TextStyle(color: Color(0xFF16A34A)),
                                        ),
                                        TextSpan(
                                          text: ' / $totalPersonnel',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedStatusFilter == 'completed')
                              const Icon(Icons.radio_button_checked,
                                  color: AppColors.navyMid, size: 20)
                            else
                              Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey.shade400, size: 20),
                          ],
                        ),
                      ),
                    ),

                    // Option 2: Total / Not Completed
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _selectedStatusFilter = 'not_completed');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: halfWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedStatusFilter == 'not_completed'
                              ? const Color(0xFFFEF2F2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedStatusFilter == 'not_completed'
                                ? AppColors.dangerRed
                                : Colors.grey.shade300,
                            width: _selectedStatusFilter == 'not_completed' ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_selectedStatusFilter == 'not_completed'
                                      ? AppColors.dangerRed
                                      : Colors.black)
                                  .withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.dangerRed.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pending_actions_rounded,
                                color: AppColors.dangerRed,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Not Completed',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedStatusFilter == 'not_completed'
                                          ? AppColors.dangerRed
                                          : AppColors.lightSubText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navyDark,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '$notCompletedCount',
                                          style: const TextStyle(color: AppColors.dangerRed),
                                        ),
                                        TextSpan(
                                          text: ' / $totalPersonnel',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedStatusFilter == 'not_completed')
                              const Icon(Icons.radio_button_checked,
                                  color: AppColors.dangerRed, size: 20)
                            else
                              Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey.shade400, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Platform Filter Chips (only relevant when viewing completed course records)
            if (_selectedStatusFilter == 'completed' && _availablePlatforms.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availablePlatforms.map((platform) {
                    final isSelected = _selectedPlatform == platform;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(platform),
                        selected: isSelected,
                        selectedColor: AppColors.navyMid.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.navyMid : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedPlatform = platform);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Records Count and Description
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedStatusFilter == 'completed'
                      ? 'Completed Course Records (${list.length})'
                      : 'Officers Who Have Not Completed Any Course (${_filteredNotCompletedOfficers.length})',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _selectedStatusFilter == 'completed'
                        ? AppColors.navyDark
                        : AppColors.dangerRed,
                  ),
                ),
                Text(
                  _selectedStatusFilter == 'completed'
                      ? 'Auto-synced with Officer Inbuilt Profiles'
                      : 'Pending Training Status',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightSubText),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Table Card
            if (_selectedStatusFilter == 'completed') ...[
              if (list.isEmpty)
                Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No course completion records found',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Click "+ Add Course Completion" below to record a training course.',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 80,
                      headingTextStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: const Color(0xFF334155),
                      ),
                      columns: const [
                        DataColumn(label: Text('Sr. No.')),
                        DataColumn(label: Text('Officer Name')),
                        DataColumn(label: Text('Course Name')),
                        DataColumn(label: Text('Platform of Course')),
                        DataColumn(label: Text('Date of Completion')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: list.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final item = entry.value;

                        return DataRow(
                          cells: [
                            // Serial Number
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$index',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                              ),
                            ),
                            // Name (user inbuilt name)
                            DataCell(
                              GestureDetector(
                                onTap: () => _showCompletedCoursesPopup(item),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.officerName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.navyDark,
                                            decoration: TextDecoration.underline,
                                            decorationColor:
                                                AppColors.navyMid.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        Text(
                                          'Tap to view completed courses',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppColors.lightSubText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: AppColors.navyMid.withValues(alpha: 0.6)),
                                  ],
                                ),
                              ),
                            ),
                            // Course Name
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bookmark_border_rounded,
                                      size: 16, color: Colors.blueGrey),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.courseName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Platform
                            DataCell(
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  item.platform,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ),
                            // Date of Completion
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_outlined,
                                      size: 15, color: Colors.black45),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.dateOfCompletion.isNotEmpty
                                        ? item.dateOfCompletion
                                        : 'N/A',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // Status
                            DataCell(
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 14, color: AppColors.successGreen),
                                    SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.successGreen,
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
            ] else ...[
              if (_filteredNotCompletedOfficers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Personnel Completed Courses',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Every officer in this police station has completed at least one e-learning training course.',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFFEF2F2)),
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 68,
                        headingTextStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF991B1B),
                        ),
                        columns: const [
                          DataColumn(label: Text('Sr. No.')),
                          DataColumn(label: Text('Officer Name')),
                          DataColumn(label: Text('Badge Number')),
                          DataColumn(label: Text('Designation')),
                          DataColumn(label: Text('Station')),
                          DataColumn(label: Text('Training Status')),
                        ],
                        rows: _filteredNotCompletedOfficers.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final off = entry.value;

                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$idx',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () => _showPendingCoursesPopup(off),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            off.officerName,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Colors.red.shade900,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Colors.red.shade300,
                                            ),
                                          ),
                                          Text(
                                            'Tap to view pending courses',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Colors.red.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down_rounded,
                                          size: 16, color: Colors.red.shade400),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                off.badgeNumber.isNotEmpty ? off.badgeNumber : '—',
                                style: GoogleFonts.inter(fontSize: 13),
                              )),
                              DataCell(Text(
                                off.designation.isNotEmpty ? off.designation : 'Officer',
                                style: GoogleFonts.inter(fontSize: 13),
                              )),
                              DataCell(Text(
                                off.stationName.isNotEmpty ? off.stationName : '—',
                                style: GoogleFonts.inter(fontSize: 13),
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.red.shade300),
                                  ),
                                  child: Builder(
                                    builder: (_) {
                                      final completedCount = _records.where((r) =>
                                          r.officerUid == off.officerUid ||
                                          r.officerName.trim().toLowerCase() ==
                                              off.officerName.trim().toLowerCase()).length;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.pending_actions_rounded,
                                              size: 14, color: AppColors.dangerRed),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$completedCount Course${completedCount == 1 ? '' : 's'} Completed',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.dangerRed,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
