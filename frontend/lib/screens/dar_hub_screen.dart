import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../modules/core/models/base_record.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';
import '../widgets/sub_tab_host.dart';
import '../utils/dynamic_map_pdf.dart';
import '../utils/pdf_unicode_fonts.dart';

/// Strongly-typed data model for a DAR case item
class DarCaseItem {
  final String id;
  final String crNo;
  final String actAndSection;
  final String ioName;
  final String ioUid;
  final String status;
  final String statusColor;
  final String stationName;
  final DateTime incidentDate;
  final DateTime createdAt;
  final Map<String, dynamic> rawMap;

  DarCaseItem({
    required this.id,
    required this.crNo,
    required this.actAndSection,
    required this.ioName,
    required this.ioUid,
    required this.status,
    required this.statusColor,
    required this.stationName,
    required this.incidentDate,
    required this.createdAt,
    required this.rawMap,
  });

  factory DarCaseItem.fromMap(Map m) {
    final now = DateTime.now();
    final id = (m['id'] ?? '').toString();
    final crNo = (m['cr_no'] ?? m['case_number'] ?? '—').toString();
    final act = (m['act_and_section'] ??
            m['sub_category'] ??
            m['title'] ??
            'Road Accident')
        .toString()
        .trim();
    final io = (m['io_name'] ?? m['assigned_officer'] ?? 'Unassigned')
        .toString()
        .trim();
    final ioUid = (m['io_uid'] ?? m['assigned_officer_uid'] ?? '').toString();
    final st = (m['status'] ?? 'Pending').toString().trim();
    final stColor = (m['status_color'] ?? '#E74C3C').toString();
    final station = (m['station_name'] ?? '').toString();

    DateTime incDt = now;
    if (m['incident_date'] != null) {
      incDt = DateTime.tryParse(m['incident_date'].toString()) ?? now;
    } else if (m['created_at'] != null) {
      incDt = DateTime.tryParse(m['created_at'].toString()) ?? now;
    }

    DateTime crDt = now;
    if (m['created_at'] != null) {
      crDt = DateTime.tryParse(m['created_at'].toString()) ?? now;
    }

    final raw = <String, dynamic>{};
    m.forEach((k, v) {
      raw[k.toString()] = v;
    });

    return DarCaseItem(
      id: id,
      crNo: crNo.isEmpty ? '—' : crNo,
      actAndSection: act.isEmpty ? 'Road Accident' : act,
      ioName: io.isEmpty ? 'Unassigned' : io,
      ioUid: ioUid,
      status: st,
      statusColor: stColor,
      stationName: station,
      incidentDate: incDt,
      createdAt: crDt,
      rawMap: raw,
    );
  }
}

/// Strongly-typed model for IO groupings
class DarIOItem {
  final String ioName;
  final String ioUid;
  final String stationName;
  final List<DarCaseItem> cases;

  DarIOItem({
    required this.ioName,
    required this.ioUid,
    required this.stationName,
    required this.cases,
  });

  int get count => cases.length;
}

/// Filter option descriptor for DAR categories & statuses
class DarFilterItem {
  final String key;
  final String label;
  final String group;
  final IconData icon;
  final Color? color;

  const DarFilterItem({
    required this.key,
    required this.label,
    required this.group,
    required this.icon,
    this.color,
  });
}

const List<DarFilterItem> kDarFilterItems = [
  // Overview
  DarFilterItem(
    key: 'all',
    label: 'Total',
    group: 'Overview',
    icon: Icons.assignment_rounded,
    color: AppColors.navyMid,
  ),

  // Status
  DarFilterItem(
    key: 'filled',
    label: 'Filled',
    group: 'Status',
    icon: Icons.check_circle_rounded,
    color: AppColors.successGreen,
  ),
  DarFilterItem(
    key: 'pending',
    label: 'Pending',
    group: 'Status',
    icon: Icons.pending_actions_rounded,
    color: AppColors.dangerRed,
  ),

  // Accident Type / Act & Section
  DarFilterItem(
    key: 'road_accident',
    label: 'Road Accident',
    group: 'Accident Category',
    icon: Icons.car_crash_rounded,
    color: AppColors.navyMid,
  ),
  DarFilterItem(
    key: 'normal_accident',
    label: 'Other Accident',
    group: 'Accident Category',
    icon: Icons.minor_crash_rounded,
    color: AppColors.navyMid,
  ),
  DarFilterItem(
    key: 'death_rash_driving',
    label: 'Death Due to Rash Driving',
    group: 'Accident Category',
    icon: Icons.warning_amber_rounded,
    color: AppColors.navyMid,
  ),
  DarFilterItem(
    key: 'hit_and_run',
    label: 'Hit and Run',
    group: 'Accident Category',
    icon: Icons.speed_rounded,
    color: AppColors.navyMid,
  ),
  DarFilterItem(
    key: 'fatal',
    label: 'Fatal Accident',
    group: 'Accident Category',
    icon: Icons.heart_broken_rounded,
    color: AppColors.navyMid,
  ),
  DarFilterItem(
    key: 'non_fatal',
    label: 'Non-Fatal Accident',
    group: 'Accident Category',
    icon: Icons.health_and_safety_rounded,
    color: AppColors.navyMid,
  ),
];

const Set<String> kDarStatusKeys = {'filled', 'pending'};
const Set<String> kDarCategoryKeys = {
  'road_accident',
  'normal_accident',
  'death_rash_driving',
  'hit_and_run',
  'fatal',
  'non_fatal',
};

class DarHubScreen extends StatefulWidget {
  final String? stationName;
  const DarHubScreen({super.key, this.stationName});

  @override
  State<DarHubScreen> createState() => _DarHubScreenState();
}

class _DarHubScreenState extends State<DarHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final GlobalKey _dropdownButtonKey = GlobalKey();

  bool _isLoading = true;
  String? _errorMessage;

  // Raw typed cases
  List<DarCaseItem> _rawCases = [];
  Map<String, int> _filterCounts = {};

  // Multi-select active filter state
  Set<String> _selectedFilterKeys = {'all'};

  // Presentation data for tabs
  Map<String, List<DarCaseItem>>? _caseWiseData;
  List<Map<String, dynamic>>? _timeWiseData;
  List<DarIOItem>? _ioWiseData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDarData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // FILTERING LOGIC
  // ---------------------------------------------------------------------------

  bool _caseMatchesSingleFilter(DarCaseItem c, String key) {
    final st = c.status.toLowerCase().trim();
    final isFilled = st == 'filled' || st == 'completed';
    final isPending = !isFilled;

    final sub = (c.rawMap['sub_category'] ?? '').toString().toLowerCase();
    final title = (c.rawMap['title'] ?? '').toString().toLowerCase();
    final desc = (c.rawMap['description'] ?? '').toString().toLowerCase();
    final combined = '${c.actAndSection.toLowerCase()} $sub $title $desc';

    switch (key) {
      case 'all':
        return true;
      case 'filled':
        return isFilled;
      case 'pending':
        return isPending;
      case 'road_accident':
        return combined.contains('road') || combined.contains('accident');
      case 'normal_accident':
        return combined.contains('normal') || combined.contains('other');
      case 'death_rash_driving':
        return combined.contains('rash') ||
            combined.contains('death') ||
            combined.contains('304') ||
            combined.contains('106');
      case 'hit_and_run':
        return combined.contains('hit') && combined.contains('run');
      case 'fatal':
        return combined.contains('fatal') ||
            combined.contains('death') ||
            combined.contains('मृत्यू');
      case 'non_fatal':
        return !combined.contains('fatal') &&
            !combined.contains('death') &&
            !combined.contains('मृत्यू');
    }
    return false;
  }

  bool _caseMatchesMultipleFilters(DarCaseItem c, Set<String> keys) {
    if (keys.isEmpty || (keys.length == 1 && keys.contains('all'))) {
      return true;
    }

    final activeKeys = keys.where((k) => k != 'all').toSet();
    if (activeKeys.isEmpty) return true;

    final selectedStatus = activeKeys.intersection(kDarStatusKeys);
    final selectedCategories = activeKeys.intersection(kDarCategoryKeys);

    if (selectedStatus.isNotEmpty) {
      if (!selectedStatus.any((k) => _caseMatchesSingleFilter(c, k))) {
        return false;
      }
    }

    if (selectedCategories.isNotEmpty) {
      if (!selectedCategories.any((k) => _caseMatchesSingleFilter(c, k))) {
        return false;
      }
    }

    return true;
  }

  void _recomputeFilterCounts(List<DarCaseItem> cases) {
    final counts = <String, int>{};
    counts['all'] = cases.length;
    for (final item in kDarFilterItems) {
      if (item.key == 'all') continue;
      counts[item.key] =
          cases.where((c) => _caseMatchesSingleFilter(c, item.key)).length;
    }
    _filterCounts = counts;
  }

  // ---------------------------------------------------------------------------
  // DATA FETCHING & TAB DATA DERIVATION
  // ---------------------------------------------------------------------------

  bool _isAccidentCategoryCase(DarCaseItem c) {
    final combined = '${c.actAndSection} ${c.rawMap['sub_category'] ?? ''} ${c.rawMap['title'] ?? ''} ${c.rawMap['category_name'] ?? ''} ${c.rawMap['module_key'] ?? ''}'.toLowerCase();
    return combined.contains('accident') || combined.contains('rash');
  }

  Future<void> _fetchDarData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final qp = <String>[];
      if (widget.stationName != null &&
          widget.stationName!.isNotEmpty &&
          widget.stationName != 'All Stations') {
        qp.add('station_name=${Uri.encodeComponent(widget.stationName!)}');
      }

      final queryStr = qp.isNotEmpty ? '?${qp.join('&')}' : '';
      final url = '${ApiConfig.cases}dar/$queryStr';

      final res = await _apiService.get(url);

      if (res.isSuccess && res.data != null) {
        final data = res.data;
        final rawList = <DarCaseItem>[];

        if (data is Map) {
          final results = data['results'] ?? data['cases'];
          if (results is Iterable) {
            for (final item in results) {
              if (item is Map) {
                final c = DarCaseItem.fromMap(item);
                if (_isAccidentCategoryCase(c)) {
                  rawList.add(c);
                }
              }
            }
          }
        } else if (data is Iterable) {
          for (final item in data) {
            if (item is Map) {
              final c = DarCaseItem.fromMap(item);
              if (_isAccidentCategoryCase(c)) {
                rawList.add(c);
              }
            }
          }
        }

        if (mounted) {
          _rawCases = rawList;
          _recomputeFilterCounts(rawList);
          _applyCurrentFilter();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _errorMessage = res.errorMessage ?? 'Failed to load DAR cases';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilterKeys(Set<String> newKeys) {
    setState(() {
      if (newKeys.isEmpty) {
        _selectedFilterKeys = {'all'};
      } else {
        _selectedFilterKeys = Set<String>.from(newKeys);
      }
      _applyCurrentFilter();
    });
  }

  void _applyCurrentFilter() {
    final activeCases = _selectedFilterKeys.contains('all')
        ? _rawCases
        : _rawCases
            .where((c) => _caseMatchesMultipleFilters(c, _selectedFilterKeys))
            .toList();

    // 1. Group for Case Wise
    final grouped = <String, List<DarCaseItem>>{};
    for (final c in activeCases) {
      final head =
          c.actAndSection.isNotEmpty ? c.actAndSection : 'Road Accident';
      if (!grouped.containsKey(head)) {
        grouped[head] = <DarCaseItem>[];
      }
      grouped[head]!.add(c);
    }

    // 2. Derive Time Wise breakdown
    final now = DateTime.now();
    final month1 = now.subtract(const Duration(days: 30));
    final months3 = now.subtract(const Duration(days: 90));
    final months6 = now.subtract(const Duration(days: 180));
    final year1 = now.subtract(const Duration(days: 365));

    int under1 = 0;
    int m1to3 = 0;
    int m3to6 = 0;
    int m6to12 = 0;
    int moreThan1Yr = 0;

    for (final c in activeCases) {
      final dt = c.incidentDate;
      if (dt.isAfter(month1)) {
        under1++;
      } else if (dt.isAfter(months3)) {
        m1to3++;
      } else if (dt.isAfter(months6)) {
        m3to6++;
      } else if (dt.isAfter(year1)) {
        m6to12++;
      } else {
        moreThan1Yr++;
      }
    }

    final timeWise = <Map<String, dynamic>>[
      {'period': 'Under 1 month', 'count': under1},
      {'period': '1 to 3 months', 'count': m1to3},
      {'period': '3 to 6 months', 'count': m3to6},
      {'period': '6 to 12 months', 'count': m6to12},
      {'period': 'More than 1 year', 'count': moreThan1Yr},
      {'period': 'Under 3 months (Total)', 'count': under1 + m1to3},
    ];

    // 3. Derive IO Wise breakdown
    final ioMap = <String, DarIOItem>{};
    for (final c in activeCases) {
      final key = '${c.ioName}|${c.stationName}';
      if (!ioMap.containsKey(key)) {
        ioMap[key] = DarIOItem(
          ioName: c.ioName,
          ioUid: c.ioUid,
          stationName: c.stationName,
          cases: <DarCaseItem>[],
        );
      }
      ioMap[key]!.cases.add(c);
    }

    final sortedIOs = ioMap.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    setState(() {
      _isLoading = false;
      _caseWiseData = grouped;
      _timeWiseData = timeWise;
      _ioWiseData = sortedIOs;
    });
  }

  List<DarCaseItem> _getActiveFilteredCases() {
    return _selectedFilterKeys.contains('all')
        ? _rawCases
        : _rawCases
            .where((c) => _caseMatchesMultipleFilters(c, _selectedFilterKeys))
            .toList();
  }

  String _getActiveFilterLabels() {
    if (_selectedFilterKeys.contains('all') || _selectedFilterKeys.isEmpty) {
      return 'Total';
    }
    return kDarFilterItems
        .where((i) => _selectedFilterKeys.contains(i.key))
        .map((i) => i.label)
        .join(', ');
  }

  // ---------------------------------------------------------------------------
  // REMIND IO ACTION & CASE FORM NAVIGATION
  // ---------------------------------------------------------------------------

  Future<void> _sendReminderToIO(
      String caseId, String crNo, String ioName) async {
    try {
      final url = '${ApiConfig.cases}dar/$caseId/remind/';
      final res = await _apiService.post(url, body: {});

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder sent to IO for case $crNo',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.errorMessage ?? 'Failed to send reminder',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reminder: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  Future<void> _openNewCaseForm() async {
    await Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: const DynamicFormScreen(
          moduleLabel: 'DAR',
          moduleKey: 'dar',
          subCategory: 'Road Accident',
        ),
      ),
    );
    if (mounted) {
      _fetchDarData();
    }
  }

  Future<void> _openCaseForm(DarCaseItem item) async {
    final caseData = item.rawMap;
    final caseId = item.id;
    final crNo = item.crNo;
    final existingExtra = (caseData['extra_fields'] is Map)
        ? Map<String, dynamic>.from(caseData['extra_fields'])
        : (caseData['fields'] is Map
            ? Map<String, dynamic>.from(caseData['fields'])
            : <String, dynamic>{});

    await Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: DynamicFormScreen(
          moduleLabel: 'DAR',
          moduleKey: (caseData['module_key']?.toString().isNotEmpty == true)
              ? caseData['module_key'].toString()
              : 'dar',
          subCategory: (caseData['sub_category']?.toString().isNotEmpty == true)
              ? caseData['sub_category'].toString()
              : 'Road Accident',
          existingRecord: ModuleRecord(
            id: caseId,
            caseNumber: crNo,
            title: item.actAndSection,
            moduleKey: (caseData['module_key']?.toString().isNotEmpty == true)
                ? caseData['module_key'].toString()
                : 'dar',
            description: caseData['description']?.toString() ?? '',
            complainant: caseData['complainant']?.toString() ?? '',
            accused: caseData['accused']?.toString() ?? '',
            location: caseData['location']?.toString() ?? '',
            incidentDate: item.incidentDate,
            priority: 'Medium',
            assignedOfficer: item.ioName,
            assignedOfficerUid: item.ioUid,
            status: item.status,
            createdAt: item.createdAt,
            subCategory:
                (caseData['sub_category']?.toString().isNotEmpty == true)
                    ? caseData['sub_category'].toString()
                    : 'Road Accident',
            extraFields: existingExtra,
            createdBy: '',
            stationName: item.stationName.isNotEmpty
                ? item.stationName
                : (widget.stationName ?? ''),
          ),
          readOnly: true,
        ),
      ),
    );
    if (mounted) {
      _fetchDarData();
    }
  }

  void _openDetailScreen({
    required String title,
    required List<DarCaseItem> cases,
  }) {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: DarCasesDetailScreen(
          title: title,
          cases: cases,
          stationName: widget.stationName ?? '',
          onOpenCaseForm: _openCaseForm,
          onSendReminderToIO: _sendReminderToIO,
          onRefreshData: _fetchDarData,
          onOpenNewCaseForm: _openNewCaseForm,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MULTI-SELECT DROPDOWN MENU
  // ---------------------------------------------------------------------------

  void _openMultiSelectDropdown() {
    final renderBox =
        _dropdownButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final offset =
        renderBox?.localToGlobal(Offset.zero) ?? const Offset(20, 120);
    final size = renderBox?.size ?? const Size(220, 38);

    final groups = [
      'Overview',
      'Status',
      'Accident Category',
    ];

    final tempSelected = Set<String>.from(_selectedFilterKeys);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Multi-Select',
      barrierColor: Colors.black.withValues(alpha: 0.14),
      pageBuilder: (dialogContext, anim1, anim2) {
        String searchQuery = '';

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final media = MediaQuery.of(dialogContext);
            final dialogWidth =
                math.min(350.0, math.max(280.0, media.size.width - 24.0));
            final maxLeft =
                math.max(12.0, media.size.width - dialogWidth - 12.0);
            final isSmallScreen = media.size.width < 420;
            final leftPos = isSmallScreen
                ? ((media.size.width - dialogWidth) / 2).clamp(12.0, maxLeft)
                : offset.dx.clamp(12.0, maxLeft);
            final maxTop = math.max(12.0, media.size.height - 520.0);
            final idealTop = offset.dy + size.height + 4.0;
            final topPos = idealTop.clamp(12.0, maxTop);
            final maxModalHeight = math.min(
                480.0, math.max(260.0, media.size.height - topPos - 16.0));

            final filteredItems = kDarFilterItems.where((item) {
              if (searchQuery.isEmpty) return true;
              return item.label
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  item.group.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            final selectedCount =
                tempSelected.contains('all') ? 0 : tempSelected.length;

            return SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: leftPos,
                    top: topPos,
                    width: dialogWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        constraints: BoxConstraints(maxHeight: maxModalHeight),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.filter_alt_rounded,
                                    size: 18,
                                    color: AppColors.navyMid,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Filter DAR Cases',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyDark,
                                      ),
                                    ),
                                  ),
                                  if (!tempSelected.contains('all'))
                                    InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          tempSelected.clear();
                                          tempSelected.add('all');
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        child: Text(
                                          'Reset',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.dangerRed,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => Navigator.pop(dialogContext),
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.lightSubText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Search bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              child: Container(
                                height: 34,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F8FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          Colors.grey.withValues(alpha: 0.2)),
                                ),
                                child: TextField(
                                  onChanged: (val) {
                                    setModalState(() {
                                      searchQuery = val.trim();
                                    });
                                  },
                                  style: GoogleFonts.poppins(fontSize: 12),
                                  decoration: InputDecoration(
                                    icon: const Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                      color: AppColors.lightSubText,
                                    ),
                                    hintText: 'Search categories...',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.lightSubText,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ),

                            const Divider(height: 12),

                            // Checkbox List
                            Flexible(
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                children: groups.map((group) {
                                  final itemsInGroup = filteredItems
                                      .where((i) => i.group == group)
                                      .toList();
                                  if (itemsInGroup.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            6, 6, 6, 4),
                                        child: Text(
                                          group.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                            color: AppColors.lightSubText,
                                          ),
                                        ),
                                      ),
                                      ...itemsInGroup.map((item) {
                                        final isChecked =
                                            tempSelected.contains(item.key);
                                        final count =
                                            _filterCounts[item.key] ?? 0;

                                        return InkWell(
                                          onTap: () {
                                            setModalState(() {
                                              if (item.key == 'all') {
                                                tempSelected.clear();
                                                tempSelected.add('all');
                                              } else {
                                                tempSelected.remove('all');
                                                if (isChecked) {
                                                  tempSelected.remove(item.key);
                                                  if (tempSelected.isEmpty) {
                                                    tempSelected.add('all');
                                                  }
                                                } else {
                                                  tempSelected.add(item.key);
                                                }
                                              }
                                            });
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 6),
                                            margin: const EdgeInsets.only(
                                                bottom: 2),
                                            decoration: BoxDecoration(
                                              color: isChecked
                                                  ? AppColors.navyMid
                                                      .withValues(alpha: 0.08)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                // Checkbox
                                                SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: Checkbox(
                                                    value: isChecked,
                                                    activeColor:
                                                        AppColors.navyMid,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    onChanged: (_) {
                                                      setModalState(() {
                                                        if (item.key == 'all') {
                                                          tempSelected.clear();
                                                          tempSelected
                                                              .add('all');
                                                        } else {
                                                          tempSelected
                                                              .remove('all');
                                                          if (isChecked) {
                                                            tempSelected.remove(
                                                                item.key);
                                                            if (tempSelected
                                                                .isEmpty) {
                                                              tempSelected
                                                                  .add('all');
                                                            }
                                                          } else {
                                                            tempSelected
                                                                .add(item.key);
                                                          }
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Icon
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: (item.color ??
                                                            AppColors.navyMid)
                                                        .withValues(
                                                            alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Icon(
                                                    item.icon,
                                                    size: 13,
                                                    color: item.color ??
                                                        AppColors.navyMid,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Label
                                                Expanded(
                                                  child: Text(
                                                    item.label,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12.5,
                                                      fontWeight: isChecked
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      color: isChecked
                                                          ? AppColors.navyDark
                                                          : const Color(
                                                              0xFF2C3E50),
                                                    ),
                                                  ),
                                                ),

                                                // Count
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: isChecked
                                                        ? AppColors.navyMid
                                                        : Colors.grey
                                                            .withValues(
                                                                alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Text(
                                                    '$count',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isChecked
                                                          ? Colors.white
                                                          : AppColors.navyDark,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),

                            const Divider(height: 1),

                            // Bottom Action Bar
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                              child: Row(
                                children: [
                                  Text(
                                    selectedCount == 0
                                        ? 'All cases'
                                        : '$selectedCount selected',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightSubText,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.lightSubText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      _applyFilterKeys(tempSelected);
                                    },
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Apply Filters',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navyMid,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER BAR (DROPDOWN BUTTON + CLEAR ACTION)
  // ---------------------------------------------------------------------------

  Widget _buildFilterDropdownButton() {
    final isFiltered =
        !_selectedFilterKeys.contains('all') && _selectedFilterKeys.isNotEmpty;
    final activeCases = _getActiveFilteredCases();
    final count = activeCases.length;

    String labelText;
    IconData leadingIcon = Icons.assignment_rounded;

    if (_selectedFilterKeys.contains('all') || _selectedFilterKeys.isEmpty) {
      labelText = 'Total';
      leadingIcon = Icons.assignment_rounded;
    } else if (_selectedFilterKeys.length == 1) {
      final item = kDarFilterItems.firstWhere(
        (i) => i.key == _selectedFilterKeys.first,
        orElse: () => kDarFilterItems.first,
      );
      labelText = item.label;
      leadingIcon = item.icon;
    } else {
      labelText = '${_selectedFilterKeys.length} Filters Selected';
      leadingIcon = Icons.filter_alt_rounded;
    }

    return InkWell(
      key: _dropdownButtonKey,
      onTap: _openMultiSelectDropdown,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppColors.navyMid.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFiltered
                ? AppColors.navyMid
                : Colors.grey.withValues(alpha: 0.3),
            width: isFiltered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              leadingIcon,
              size: 16,
              color: isFiltered ? AppColors.navyMid : const Color(0xFF5D7285),
            ),
            const SizedBox(width: 8),
            Text(
              'Filter: $labelText',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isFiltered
                    ? AppColors.navyMid
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isFiltered ? Colors.white : AppColors.navyDark,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.navyMid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final isFiltered =
        !_selectedFilterKeys.contains('all') && _selectedFilterKeys.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildFilterDropdownButton(),
          const Spacer(),
          if (isFiltered)
            InkWell(
              onTap: () => _applyFilterKeys({'all'}),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.dangerRed.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.dangerRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Clear Filter',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIVE FILTER BANNER
  // ---------------------------------------------------------------------------

  Widget _buildActiveFilterBanner() {
    if (_selectedFilterKeys.contains('all') || _selectedFilterKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeItems = kDarFilterItems
        .where((i) => _selectedFilterKeys.contains(i.key))
        .toList();
    final filterLabels = activeItems.map((i) => i.label).join(', ');
    final activeCases = _getActiveFilteredCases();
    final count = activeCases.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navyMid.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.navyMid.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_rounded,
            size: 16,
            color: AppColors.navyMid,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Filtered by: ',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.lightSubText,
                ),
                children: [
                  TextSpan(
                    text: filterLabels,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                  TextSpan(
                    text: ' • $count ${count == 1 ? 'Case' : 'Cases'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyMid,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _applyFilterKeys({'all'}),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Clear',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dangerRed,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: AppColors.dangerRed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE HELPER
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isFiltered =
        !_selectedFilterKeys.contains('all') && _selectedFilterKeys.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _fetchDarData,
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
                if (isFiltered) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _applyFilterKeys({'all'}),
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: Text(
                      'Clear Filter',
                      style: GoogleFonts.poppins(fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyMid,
                      side: BorderSide(
                        color: AppColors.navyMid.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: CASE WISE
  // ---------------------------------------------------------------------------

  Widget _buildCaseWiseTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_caseWiseData == null || _caseWiseData!.isEmpty) {
      return _buildEmptyState(
        title: _selectedFilterKeys.contains('all')
            ? 'No DAR Cases Found'
            : 'No Cases for Selected Filters',
        subtitle: _selectedFilterKeys.contains('all')
            ? 'Road accident DAR cases will appear here once registered'
            : 'Try adjusting your filter selection above',
        icon: Icons.category_outlined,
      );
    }

    final keys = _caseWiseData!.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _fetchDarData,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: keys.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildActiveFilterBanner();
          }

          final head = keys[index - 1];
          final cases = _caseWiseData![head] ?? [];

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
                  _openDetailScreen(
                    title: _selectedFilterKeys.contains('all')
                        ? 'DAR Cases — $head'
                        : 'DAR ($head) — ${_getActiveFilterLabels()}',
                    cases: cases,
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
                          Icons.car_crash_rounded,
                          color: AppColors.navyMid,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          head,
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
                          '${cases.length} ${cases.length == 1 ? 'Case' : 'Cases'}',
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

  // ---------------------------------------------------------------------------
  // TAB 2: TIME WISE
  // ---------------------------------------------------------------------------

  Widget _buildTimeWiseTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_timeWiseData == null || _timeWiseData!.isEmpty) {
      return _buildEmptyState(
        title: 'No Time Intervals Found',
        subtitle: 'Duration-wise DAR breakdown will appear here',
        icon: Icons.schedule_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDarData,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _timeWiseData!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildActiveFilterBanner();
          }

          final item = _timeWiseData![index - 1];
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
                  final month1 = now.subtract(const Duration(days: 30));
                  final months3 = now.subtract(const Duration(days: 90));
                  final months6 = now.subtract(const Duration(days: 180));
                  final year1 = now.subtract(const Duration(days: 365));

                  final activeCases = _getActiveFilteredCases();
                  final filteredByTime = activeCases.where((c) {
                    final dt = c.incidentDate;

                    if (p == 'Under 1 month') {
                      return dt.isAfter(month1);
                    } else if (p == '1 to 3 months') {
                      return dt.isAfter(months3) && !dt.isAfter(month1);
                    } else if (p == '3 to 6 months') {
                      return dt.isAfter(months6) && !dt.isAfter(months3);
                    } else if (p == '6 to 12 months') {
                      return dt.isAfter(year1) && !dt.isAfter(months6);
                    } else if (p == 'More than 1 year') {
                      return !dt.isAfter(year1);
                    } else if (p == 'Under 3 months (Total)') {
                      return dt.isAfter(months3);
                    }
                    return true;
                  }).toList();

                  _openDetailScreen(
                    title: _selectedFilterKeys.contains('all')
                        ? 'DAR — $p'
                        : 'DAR ($p) — ${_getActiveFilterLabels()}',
                    cases: filteredByTime,
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

  // ---------------------------------------------------------------------------
  // TAB 3: IO WISE
  // ---------------------------------------------------------------------------

  Widget _buildIOWiseTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_ioWiseData == null || _ioWiseData!.isEmpty) {
      return _buildEmptyState(
        title: 'No Investigating Officers Found',
        subtitle: 'Officer-wise DAR assignment will appear here',
        icon: Icons.badge_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDarData,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _ioWiseData!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildActiveFilterBanner();
          }

          final item = _ioWiseData![index - 1];
          final ioName = item.ioName;
          final stationName = item.stationName;
          final count = item.count;
          final ioCases = item.cases;

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
                  _openDetailScreen(
                    title: _selectedFilterKeys.contains('all')
                        ? 'DAR — $ioName'
                        : 'DAR ($ioName) — ${_getActiveFilterLabels()}',
                    cases: ioCases,
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
                              stationName.isNotEmpty
                                  ? 'Investigating Officer • $stationName'
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

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          'DAR (Detailed Accident Report)',
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          // Add Case Button
          ElevatedButton.icon(
            onPressed: _openNewCaseForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'Add Case',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Summary Button (like Victim tab)
          ElevatedButton.icon(
            onPressed: () {
              _openDetailScreen(
                title: _selectedFilterKeys.contains('all')
                    ? 'DAR Cases — Summary'
                    : 'DAR Summary — ${_getActiveFilterLabels()}',
                cases: _getActiveFilteredCases(),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(width: 6),

          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navyMid),
            tooltip: 'Refresh',
            onPressed: _fetchDarData,
          ),
          const SizedBox(width: 8),
        ],
        bottom: SubTabHost.appBarBottomAbove(
          context,
          PreferredSize(
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar with multi-select dropdown button
            _buildFilterBar(),

            // Tab Views
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DAR DETAILED CASES SCREEN (TABLE WITH REMIND TO IO & FORM EDITING)
// =============================================================================

class DarCasesDetailScreen extends StatefulWidget {
  final String title;
  final List<DarCaseItem> cases;
  final String stationName;
  final Future<void> Function(DarCaseItem caseItem) onOpenCaseForm;
  final Future<void> Function(String caseId, String crNo, String ioName)
      onSendReminderToIO;
  final Future<void> Function() onRefreshData;
  final VoidCallback? onOpenNewCaseForm;

  const DarCasesDetailScreen({
    super.key,
    required this.title,
    required this.cases,
    required this.stationName,
    required this.onOpenCaseForm,
    required this.onSendReminderToIO,
    required this.onRefreshData,
    this.onOpenNewCaseForm,
  });

  @override
  State<DarCasesDetailScreen> createState() => _DarCasesDetailScreenState();
}

class _DarCasesDetailScreenState extends State<DarCasesDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<DarCaseItem> _displayCases;
  DateTimeRange? _selectedDateRange;
  String? _datePresetLabel;
  String _statusFilter = 'all'; // 'all', 'filled', 'pending'

  @override
  void initState() {
    super.initState();
    _displayCases = List<DarCaseItem>.from(widget.cases);
  }

  @override
  void didUpdateWidget(covariant DarCasesDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cases != widget.cases) {
      _applySearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    final q = _searchQuery.toLowerCase().trim();
    setState(() {
      _displayCases = widget.cases.where((c) {
        if (q.isNotEmpty) {
          final cr = c.crNo.toLowerCase();
          final io = c.ioName.toLowerCase();
          final act = c.actAndSection.toLowerCase();
          if (!cr.contains(q) && !io.contains(q) && !act.contains(q)) {
            return false;
          }
        }

        if (_selectedDateRange != null) {
          final dt = c.incidentDate;
          final start = _selectedDateRange!.start;
          final end = _selectedDateRange!.end.add(const Duration(days: 1));
          if (dt.isBefore(start) || dt.isAfter(end)) {
            return false;
          }
        }

        if (_statusFilter == 'filled') {
          final st = c.status.toLowerCase();
          if (st != 'filled' && st != 'completed') {
            return false;
          }
        } else if (_statusFilter == 'pending') {
          final st = c.status.toLowerCase();
          if (st == 'filled' || st == 'completed') {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _setStatusFilter(String status) {
    setState(() {
      if (_statusFilter == status && status != 'all') {
        _statusFilter = 'all';
      } else {
        _statusFilter = status;
      }
      _applySearch();
    });
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _datePresetLabel = null;
      _applySearch();
    });
  }

  void _applyDatePreset(String label, DateTimeRange range) {
    setState(() {
      _selectedDateRange = range;
      _datePresetLabel = label;
      _applySearch();
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      _applyDatePreset(
        '${DateFormat('dd/MM/yy').format(picked.start)} - ${DateFormat('dd/MM/yy').format(picked.end)}',
        picked,
      );
    }
  }

  Future<void> _exportPdf() async {
    if (_displayCases.isEmpty) return;
    final theme = await PdfUnicodeFonts.openSansTheme();

    final rows = _displayCases.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final c = entry.value;
      return <String, dynamic>{
        'Sr. No.': '$i',
        'CR No.': c.crNo,
        'Act and Section': c.actAndSection,
        'IO Name': c.ioName,
        'Status': c.status,
      };
    }).toList();

    final columnOrder = [
      'Sr. No.',
      'CR No.',
      'Act and Section',
      'IO Name',
      'Status',
    ];

    final doc = DynamicMapPdf.buildLandscapeDataTableDocument(
      theme: theme,
      title:
          '${widget.title} — ${widget.stationName.isNotEmpty ? widget.stationName : 'All Stations'}',
      rows: rows,
      prependSerial: false,
      columnOrder: columnOrder,
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          '${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf',
    );
  }

  Widget _buildDateFilterMenu(BuildContext context) {
    final hasFilter = _selectedDateRange != null;
    final now = DateTime.now();

    return PopupMenuButton<String>(
      tooltip: 'Filter by Date',
      onSelected: (val) {
        switch (val) {
          case 'all':
            _clearDateFilter();
            break;
          case 'under_1_month':
            _applyDatePreset(
              'Under 1 month',
              DateTimeRange(
                start: now.subtract(const Duration(days: 30)),
                end: now,
              ),
            );
            break;
          case '1_to_3_months':
            _applyDatePreset(
              '1 to 3 months',
              DateTimeRange(
                start: now.subtract(const Duration(days: 90)),
                end: now.subtract(const Duration(days: 30)),
              ),
            );
            break;
          case '3_to_6_months':
            _applyDatePreset(
              '3 to 6 months',
              DateTimeRange(
                start: now.subtract(const Duration(days: 180)),
                end: now.subtract(const Duration(days: 90)),
              ),
            );
            break;
          case '6_to_12_months':
            _applyDatePreset(
              '6 to 12 months',
              DateTimeRange(
                start: now.subtract(const Duration(days: 365)),
                end: now.subtract(const Duration(days: 180)),
              ),
            );
            break;
          case 'more_than_1_year':
            _applyDatePreset(
              'More than 1 year',
              DateTimeRange(
                start: DateTime(2000),
                end: now.subtract(const Duration(days: 365)),
              ),
            );
            break;
          case 'under_3_months_total':
            _applyDatePreset(
              'Under 3 months (Total)',
              DateTimeRange(
                start: now.subtract(const Duration(days: 90)),
                end: now,
              ),
            );
            break;
          case 'custom':
            _pickCustomDateRange();
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'all',
          child: Row(
            children: [
              Icon(
                _selectedDateRange == null
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 16,
                color: _selectedDateRange == null
                    ? AppColors.navyMid
                    : AppColors.lightSubText,
              ),
              const SizedBox(width: 8),
              Text(
                'All Dates',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: _selectedDateRange == null
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        _buildDateMenuItem('under_1_month', 'Under 1 month'),
        _buildDateMenuItem('1_to_3_months', '1 to 3 months'),
        _buildDateMenuItem('3_to_6_months', '3 to 6 months'),
        _buildDateMenuItem('6_to_12_months', '6 to 12 months'),
        _buildDateMenuItem('more_than_1_year', 'More than 1 year'),
        _buildDateMenuItem('under_3_months_total', 'Under 3 months (Total)'),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'custom',
          child: Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                size: 16,
                color: AppColors.navyMid,
              ),
              const SizedBox(width: 8),
              Text(
                'Custom Date Range...',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyMid,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasFilter ? AppColors.navyMid.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasFilter ? AppColors.navyMid : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: hasFilter ? AppColors.navyMid : AppColors.lightSubText,
            ),
            const SizedBox(width: 6),
            Text(
              _datePresetLabel ?? 'Date Filter',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                color: hasFilter ? AppColors.navyMid : AppColors.navyDark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: hasFilter ? AppColors.navyMid : AppColors.lightSubText,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildDateMenuItem(String value, String label) {
    final isSelected = _datePresetLabel == label;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isSelected ? AppColors.navyMid : AppColors.lightSubText,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.navyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? color : AppColors.lightSubText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase().trim();
    int totalCount = 0;
    int filledCount = 0;
    int pendingCount = 0;
    for (final c in widget.cases) {
      if (q.isNotEmpty) {
        final cr = c.crNo.toLowerCase();
        final io = c.ioName.toLowerCase();
        final act = c.actAndSection.toLowerCase();
        if (!cr.contains(q) && !io.contains(q) && !act.contains(q)) {
          continue;
        }
      }
      if (_selectedDateRange != null) {
        final dt = c.incidentDate;
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end.add(const Duration(days: 1));
        if (dt.isBefore(start) || dt.isAfter(end)) {
          continue;
        }
      }
      totalCount++;
      final st = c.status.toLowerCase();
      if (st == 'filled' || st == 'completed') {
        filledCount++;
      } else {
        pendingCount++;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyDark),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: AppColors.navyDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          if (widget.onOpenNewCaseForm != null)
            ElevatedButton.icon(
              onPressed: widget.onOpenNewCaseForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add Case',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navyMid),
            tooltip: 'Refresh',
            onPressed: () async {
              await widget.onRefreshData();
              _applySearch();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: widget.onOpenNewCaseForm != null
          ? FloatingActionButton.extended(
              onPressed: widget.onOpenNewCaseForm,
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Add Case',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top 3 Stat Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 650;
                  final cards = [
                    _buildStatCard(
                      title: 'Total',
                      count: totalCount,
                      icon: Icons.assignment_outlined,
                      color: AppColors.navyMid,
                      bgColor: AppColors.navyMid.withValues(alpha: 0.08),
                      isSelected: _statusFilter == 'all',
                      onTap: () => _setStatusFilter('all'),
                    ),
                    _buildStatCard(
                      title: 'Filled',
                      count: filledCount,
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.successGreen,
                      bgColor: AppColors.successGreen.withValues(alpha: 0.1),
                      isSelected: _statusFilter == 'filled',
                      onTap: () => _setStatusFilter('filled'),
                    ),
                    _buildStatCard(
                      title: 'Pending',
                      count: pendingCount,
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.dangerRed,
                      bgColor: AppColors.dangerRed.withValues(alpha: 0.1),
                      isSelected: _statusFilter == 'pending',
                      onTap: () => _setStatusFilter('pending'),
                    ),
                  ];

                  return Row(
                    children: cards
                        .map((c) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: c,
                              ),
                            ))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Search, Date Filter & PDF Row (matching Screenshot 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by CR No. or IO Name...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.lightSubText,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.navyMid,
                            size: 18,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _applySearch();
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          _searchQuery = val;
                          _applySearch();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Date Filter Menu (matching Screenshot 1)
                    _buildDateFilterMenu(context),
                    const SizedBox(width: 8),

                    // PDF Export Button (matching Screenshot 1)
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Export PDF',
                        onPressed: _displayCases.isNotEmpty ? _exportPdf : null,
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Cases Table
              Expanded(
                child: _displayCases.isEmpty
                    ? Center(
                        child: Text(
                          'No cases found matching your criteria.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.lightSubText,
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const minWidth = 780.0;
                              final tableWidth = constraints.maxWidth > minWidth
                                  ? constraints.maxWidth
                                  : minWidth;

                              const columnWidths = <int, TableColumnWidth>{
                                0: FixedColumnWidth(65),
                                1: FlexColumnWidth(1.4),
                                2: FlexColumnWidth(2.0),
                                3: FlexColumnWidth(1.6),
                                4: FixedColumnWidth(100),
                                5: FixedColumnWidth(140),
                              };

                              Widget headerCell(String text,
                                  {Alignment align = Alignment.centerLeft}) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  alignment: align,
                                  child: Text(
                                    text,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }

                              Widget dataCell(Widget child,
                                  {Alignment align = Alignment.centerLeft}) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  alignment: align,
                                  child: child,
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: tableWidth,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // ── Sticky Fixed Blue Header ──
                                      Container(
                                        color: AppColors.navyMid,
                                        child: Table(
                                          columnWidths: columnWidths,
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          children: [
                                            TableRow(
                                              decoration: const BoxDecoration(
                                                  color: AppColors.navyMid),
                                              children: [
                                                headerCell('Sr. No.'),
                                                headerCell('CR No.'),
                                                headerCell('Act and Section'),
                                                headerCell('IO Name'),
                                                headerCell('Status',
                                                    align: Alignment.center),
                                                headerCell('Action',
                                                    align: Alignment.center),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ── Scrollable Case List ──
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: Table(
                                            columnWidths: columnWidths,
                                            defaultVerticalAlignment:
                                                TableCellVerticalAlignment
                                                    .middle,
                                            border: const TableBorder(
                                              horizontalInside: BorderSide(
                                                color: Color(0xFFEDF2F7),
                                                width: 1,
                                              ),
                                            ),
                                            children: List<TableRow>.generate(
                                              _displayCases.length,
                                              (index) {
                                                final c = _displayCases[index];
                                                final crNo = c.crNo;
                                                final act = c.actAndSection;
                                                final io = c.ioName;
                                                final statusStr = c.status;
                                                final isFilled = statusStr
                                                            .toLowerCase() ==
                                                        'filled' ||
                                                    statusStr.toLowerCase() ==
                                                        'completed';
                                                final caseId = c.id;
                                                final bg = index.isEven
                                                    ? Colors.white
                                                    : const Color(0xFFF9FAFF);

                                                return TableRow(
                                                  decoration:
                                                      BoxDecoration(color: bg),
                                                  children: [
                                                    dataCell(
                                                      Text(
                                                        '${index + 1}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: AppColors
                                                              .navyDark,
                                                        ),
                                                      ),
                                                    ),
                                                    dataCell(
                                                      InkWell(
                                                        onTap: () => widget
                                                            .onOpenCaseForm(c),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                crNo,
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  color: AppColors
                                                                      .navyMid,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 12,
                                                                  decoration:
                                                                      TextDecoration
                                                                          .underline,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            const Icon(
                                                              Icons
                                                                  .open_in_new_rounded,
                                                              size: 13,
                                                              color: AppColors
                                                                  .navyMid,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    dataCell(
                                                      Text(
                                                        act,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: AppColors
                                                              .navyDark,
                                                        ),
                                                      ),
                                                    ),
                                                    dataCell(
                                                      Text(
                                                        io,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: AppColors
                                                              .navyDark,
                                                        ),
                                                      ),
                                                    ),
                                                    dataCell(
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isFilled
                                                              ? AppColors
                                                                  .successGreen
                                                              : AppColors
                                                                  .dangerRed,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          isFilled
                                                              ? 'Filled'
                                                              : 'Pending',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      align: Alignment.center,
                                                    ),
                                                    dataCell(
                                                      isFilled
                                                          ? Text(
                                                              'Completed',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: AppColors
                                                                    .successGreen,
                                                              ),
                                                            )
                                                          : ElevatedButton.icon(
                                                              onPressed: () {
                                                                widget
                                                                    .onSendReminderToIO(
                                                                        caseId,
                                                                        crNo,
                                                                        io);
                                                              },
                                                              icon: const Icon(
                                                                Icons
                                                                    .notifications_active_rounded,
                                                                size: 14,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              label: Text(
                                                                'Remind to IO',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize:
                                                                      11.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    AppColors
                                                                        .dangerRed,
                                                                elevation: 0,
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        6),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              6),
                                                                ),
                                                              ),
                                                            ),
                                                      align: Alignment.center,
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
