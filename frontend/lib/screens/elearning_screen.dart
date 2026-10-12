// lib/screens/elearning_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/elearning_service.dart';
import '../theme/app_theme.dart';
import '../utils/police_hierarchy_helper.dart';

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
  late TabController _tabController;
  final ELearningService _elearningService = ELearningService();

  bool _isLoading = true;
  List<ELearningRecord> _records = [];
  InchargeAnalyticsResponse? _analytics;
  String _searchQuery = '';
  String _selectedPlatform = 'All';

  List<String> get _availablePlatforms {
    final set = <String>{
      'All',
      'iGOT Karmayogi',
      'CDTI',
      'CyberDome',
      'BPR&D',
      'SVP NPA',
      'Coursera',
      'Other',
    };
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
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    } catch (_) {
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

  void _showAddCourseDialog() {
    final auth = context.read<AuthProvider>();
    // User inbuilt name is automatically resolved from current authenticated session
    final inbuiltName = auth.fullName.isNotEmpty
        ? auth.fullName
        : (auth.username.isNotEmpty ? auth.username : 'Police Personnel');
    final inbuiltBadge = auth.badgeNumber.isNotEmpty ? auth.badgeNumber : 'N/A';
    final inbuiltStation = auth.stationName.isNotEmpty ? auth.stationName : 'Current Station';

    final courseNameCtrl = TextEditingController();
    String selectedPlatform = 'iGOT Karmayogi';
    final customPlatformCtrl = TextEditingController();
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

                      // Platform of the Course Field
                      Text(
                        'Platform of the Course *',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPlatform,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.language_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: [
                          'iGOT Karmayogi',
                          'CDTI',
                          'CyberDome',
                          'BPR&D',
                          'SVP NPA',
                          'Coursera',
                          'Other',
                        ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedPlatform = val);
                          }
                        },
                      ),
                      if (selectedPlatform == 'Other') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: customPlatformCtrl,
                          decoration: InputDecoration(
                            hintText: 'Specify platform name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
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

                          final platform = selectedPlatform == 'Other'
                              ? customPlatformCtrl.text.trim()
                              : selectedPlatform;
                          if (platform.isEmpty) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              const SnackBar(content: Text('Please specify the platform')),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isIncharge = PoliceHierarchyHelper.isStationHead(auth.designation, auth.roleId) ||
        auth.isAdmin ||
        auth.isSupervisor;

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
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldPrimary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            const Tab(
              icon: Icon(Icons.table_chart_rounded, size: 20),
              text: 'Completed Courses Directory',
            ),
            Tab(
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
              text: isIncharge
                  ? 'Station Incharge Overview'
                  : 'Station Completion Analytics',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navyMid,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add Course Completion'),
        onPressed: _showAddCourseDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCompletedCoursesTableTab(),
                _buildInchargeAnalyticsTab(isIncharge),
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
            const SizedBox(height: 12),

            // Platform Filter Chips
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
            const SizedBox(height: 16),

            // Records Count and Description
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed Course Records (${list.length})',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                  ),
                ),
                Text(
                  'Auto-synced with Officer Inbuilt Profiles',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightSubText),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Table Card
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
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 68,
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
                              Row(
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
                                    children: [
                                      Text(
                                        item.officerName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                      if (item.badgeNumber.isNotEmpty)
                                        Text(
                                          'Badge: ${item.badgeNumber}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.lightSubText,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Tab 2: Incharge of the Police Station Analytics
  Widget _buildInchargeAnalyticsTab(bool isIncharge) {
    final summary = _analytics?.summary;
    final individual = _analytics?.individualCompletions ?? [];
    final notCompleted = _analytics?.officersNotCompleted ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incharge Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.navyMid,
                    AppColors.navyDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDark.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: AppColors.goldPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Police Station Incharge Control & Monitoring',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track personnel completion progress, individual officer records, and pending officers.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metric Cards Grid: How many personnel have completed courses
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final cardWidth = isWide
                    ? (constraints.maxWidth - 36) / 4
                    : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Total Personnel in Station
                    _buildStatCard(
                      title: 'Total Personnel',
                      value: '${summary?.totalStationPersonnel ?? 0}',
                      subtitle: 'Station Staff',
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF3B82F6),
                      width: cardWidth,
                    ),
                    // Personnel Completed at least one course
                    _buildStatCard(
                      title: 'Personnel Completed',
                      value: '${summary?.personnelCompletedAtLeastOne ?? 0}',
                      subtitle: '${summary?.completionPercentage.toStringAsFixed(1) ?? '0'}% of station',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.successGreen,
                      width: cardWidth,
                    ),
                    // Personnel Who Have Not Done Courses
                    _buildStatCard(
                      title: 'Not Completed Any',
                      value: '${summary?.personnelNotCompletedAny ?? 0}',
                      subtitle: 'Pending Officers',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.dangerRed,
                      width: cardWidth,
                    ),
                    // Total Courses Completed
                    _buildStatCard(
                      title: 'Total Completions',
                      value: '${summary?.totalCourseCompletions ?? 0}',
                      subtitle: 'Course Certificates',
                      icon: Icons.workspace_premium_rounded,
                      color: const Color(0xFF8B5CF6),
                      width: cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 1. How many courses have been completed by officers individually
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.person_outline_rounded, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Courses Completed By Officers Individually',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (individual.isEmpty)
              _buildEmptySectionNotice('No individual course completion data available yet.')
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Officer Inbuilt Name')),
                        DataColumn(label: Text('Badge Number')),
                        DataColumn(label: Text('Designation')),
                        DataColumn(label: Text('Courses Completed Individually')),
                      ],
                      rows: individual.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final off = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.navyMid,
                                    child: Text(
                                      off.officerName.isNotEmpty ? off.officerName[0].toUpperCase() : 'O',
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    off.officerName,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(off.badgeNumber.isNotEmpty ? off.badgeNumber : '—')),
                            DataCell(Text(off.designation.isNotEmpty ? off.designation : 'Officer')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Text(
                                  '${off.completedCoursesCount} Course${off.completedCoursesCount > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.successGreen,
                                    fontSize: 12,
                                  ),
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
            const SizedBox(height: 28),

            // 2. Who has not done the courses
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Officers Who Have Not Done Any Courses',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dangerRed,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notCompleted.length} Pending',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dangerRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (notCompleted.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Outstanding! All officers in this police station have completed at least one e-learning course.',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.successGreen,
                        ),
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
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFFEF2F2)),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Officer Name')),
                        DataColumn(label: Text('Badge Number')),
                        DataColumn(label: Text('Designation')),
                        DataColumn(label: Text('Station')),
                        DataColumn(label: Text('Training Status')),
                      ],
                      rows: notCompleted.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final off = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.red.shade300,
                                    child: Text(
                                      off.officerName.isNotEmpty ? off.officerName[0].toUpperCase() : 'O',
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    off.officerName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(off.badgeNumber.isNotEmpty ? off.badgeNumber : '—')),
                            DataCell(Text(off.designation.isNotEmpty ? off.designation : 'Officer')),
                            DataCell(Text(off.stationName.isNotEmpty ? off.stationName : '—')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: const Text(
                                  '0 Courses Completed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.dangerRed,
                                    fontSize: 11,
                                  ),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightSubText,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightSubText),
        ),
      ),
    );
  }
}
