import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import 'pending_summary_screen.dart';
import 'filtered_pending_screen.dart';
import '../modules/core/models/base_record.dart';
import '../utils/pending_table_firestore_mapper.dart';

/// Filter option descriptor for victim categories
class VictimFilterItem {
  final String key;
  final String label;
  final String group;
  final IconData icon;
  final Color? color;

  const VictimFilterItem({
    required this.key,
    required this.label,
    required this.group,
    required this.icon,
    this.color,
  });
}

const List<VictimFilterItem> kVictimFilterItems = [
  // Overview
  VictimFilterItem(
    key: 'all',
    label: 'Total Victims',
    group: 'Overview',
    icon: Icons.people_alt_rounded,
    color: AppColors.navyMid,
  ),

  // Gender
  VictimFilterItem(
    key: 'male',
    label: 'Male Victims',
    group: 'Gender',
    icon: Icons.male_rounded,
    color: Color(0xFF1E88E5),
  ),
  VictimFilterItem(
    key: 'female',
    label: 'Female Victims',
    group: 'Gender',
    icon: Icons.female_rounded,
    color: Color(0xFFE91E63),
  ),
  VictimFilterItem(
    key: 'transgender',
    label: 'Transgender Victims',
    group: 'Gender',
    icon: Icons.transgender_rounded,
    color: Color(0xFF9C27B0),
  ),
  VictimFilterItem(
    key: 'other_gender',
    label: 'Other Victims',
    group: 'Gender',
    icon: Icons.person_outline_rounded,
    color: Color(0xFF607D8B),
  ),

  // Special Categories & Vulnerability
  VictimFilterItem(
    key: 'adult',
    label: 'Adult Victims',
    group: 'Special Categories',
    icon: Icons.person_rounded,
    color: Color(0xFF455A64),
  ),
  VictimFilterItem(
    key: 'pwd',
    label: 'Person with Disability (PwD)',
    group: 'Special Categories',
    icon: Icons.accessible_rounded,
    color: Color(0xFF00897B),
  ),
  VictimFilterItem(
    key: 'minor',
    label: 'Child/Minor Under 18',
    group: 'Special Categories',
    icon: Icons.child_care_rounded,
    color: Color(0xFFFB8C00),
  ),
  VictimFilterItem(
    key: 'minor_male',
    label: 'Child/Minor Under 18 — Male',
    group: 'Special Categories',
    icon: Icons.boy_rounded,
    color: Color(0xFF1976D2),
  ),
  VictimFilterItem(
    key: 'minor_female',
    label: 'Child/Minor Under 18 — Female',
    group: 'Special Categories',
    icon: Icons.girl_rounded,
    color: Color(0xFFD81B60),
  ),
  VictimFilterItem(
    key: 'women',
    label: 'Women',
    group: 'Special Categories',
    icon: Icons.woman_rounded,
    color: Color(0xFFC2185B),
  ),
  VictimFilterItem(
    key: 'senior',
    label: 'Senior Citizen Age 60+',
    group: 'Special Categories',
    icon: Icons.elderly_rounded,
    color: Color(0xFF5D4037),
  ),
  VictimFilterItem(
    key: 'senior_male',
    label: 'Senior Citizen Age 60+ — Male',
    group: 'Special Categories',
    icon: Icons.elderly_rounded,
    color: Color(0xFF0288D1),
  ),
  VictimFilterItem(
    key: 'senior_female',
    label: 'Senior Citizen Age 60+ — Female',
    group: 'Special Categories',
    icon: Icons.elderly_woman_rounded,
    color: Color(0xFFAD1457),
  ),
  VictimFilterItem(
    key: 'mentally_vulnerable',
    label: 'Mentally Vulnerable',
    group: 'Special Categories',
    icon: Icons.psychology_rounded,
    color: Color(0xFF673AB7),
  ),

  // Condition & Tracing
  VictimFilterItem(
    key: 'injured',
    label: 'Injured Victims',
    group: 'Condition & Tracing',
    icon: Icons.personal_injury_rounded,
    color: Color(0xFFFF9800),
  ),
  VictimFilterItem(
    key: 'deceased',
    label: 'Deceased Victims',
    group: 'Condition & Tracing',
    icon: Icons.heart_broken_rounded,
    color: Color(0xFFD32F2F),
  ),
  VictimFilterItem(
    key: 'missing',
    label: 'Missing Victims',
    group: 'Condition & Tracing',
    icon: Icons.person_search_rounded,
    color: Color(0xFF7B1FA2),
  ),
  VictimFilterItem(
    key: 'traced',
    label: 'Victims Traced',
    group: 'Condition & Tracing',
    icon: Icons.how_to_reg_rounded,
    color: Color(0xFF2E7D32),
  ),
  VictimFilterItem(
    key: 'pending_tracing',
    label: 'Victims Pending Tracing',
    group: 'Condition & Tracing',
    icon: Icons.pending_actions_rounded,
    color: Color(0xFFE65100),
  ),

  // Age Category (filter)
  VictimFilterItem(
    key: 'age_below_5',
    label: 'Below 5 Years',
    group: 'Age Category',
    icon: Icons.cake_outlined,
    color: Color(0xFF00ACC1),
  ),
  VictimFilterItem(
    key: 'age_5_10',
    label: '5–10 Years',
    group: 'Age Category',
    icon: Icons.child_friendly_rounded,
    color: Color(0xFF43A047),
  ),
  VictimFilterItem(
    key: 'age_11_15',
    label: '11–15 Years',
    group: 'Age Category',
    icon: Icons.school_outlined,
    color: Color(0xFF3949AB),
  ),
  VictimFilterItem(
    key: 'age_16_18',
    label: '16–18 Years',
    group: 'Age Category',
    icon: Icons.face_outlined,
    color: Color(0xFF8E24AA),
  ),
  VictimFilterItem(
    key: 'age_18_59',
    label: '18–59 Years',
    group: 'Age Category',
    icon: Icons.work_outline_rounded,
    color: Color(0xFF00897B),
  ),
  VictimFilterItem(
    key: 'age_60_plus',
    label: '60 Years & Above',
    group: 'Age Category',
    icon: Icons.elderly_rounded,
    color: Color(0xFF6D4C41),
  ),
];

const Set<String> kGenderKeys = {
  'male',
  'female',
  'transgender',
  'other_gender',
};

const Set<String> kSpecialKeys = {
  'adult',
  'pwd',
  'minor',
  'minor_male',
  'minor_female',
  'women',
  'senior',
  'senior_male',
  'senior_female',
  'mentally_vulnerable',
};

const Set<String> kConditionKeys = {
  'injured',
  'deceased',
  'missing',
  'traced',
  'pending_tracing',
};

const Set<String> kAgeKeys = {
  'age_below_5',
  'age_5_10',
  'age_11_15',
  'age_16_18',
  'age_18_59',
  'age_60_plus',
};

class VictimHubScreen extends StatefulWidget {
  final String stationName;

  const VictimHubScreen({
    super.key,
    required this.stationName,
  });

  @override
  State<VictimHubScreen> createState() => _VictimHubScreenState();
}

class _VictimHubScreenState extends State<VictimHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BackendCaseService _backend = BackendCaseService();
  final GlobalKey _dropdownButtonKey = GlobalKey();

  // Raw data from backend
  List<ModuleRecord>? _allRecords;
  Map<String, int> _filterCounts = {};

  // Multi-select active filter state
  Set<String> _selectedFilterKeys = {'all'};

  // Presentation data for tabs
  List<Map<String, dynamic>>? _timeWiseData;
  List<Map<String, dynamic>>? _ioWiseData;
  Map<String, List<Map<String, String>>>? _caseWiseData;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DATA PARSING & FILTERING HELPERS
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _extractVictimsFromRecord(ModuleRecord r) {
    final extra = r.extraFields;
    final rawCf = extra['commonForm'] ?? extra['common_form'];
    final cf = rawCf is Map<String, dynamic>
        ? rawCf
        : (rawCf is Map
            ? Map<String, dynamic>.from(rawCf)
            : <String, dynamic>{});

    final mod = r.moduleKey.toLowerCase().trim();
    final sub = (r.subCategory ?? '').toLowerCase().trim();
    final statusStr = r.status.toLowerCase().trim();

    final isMissing = mod == 'missing' ||
        mod == 'kidnapping' ||
        sub.contains('missing') ||
        sub.contains('kidnapping');
    final isTraced = isMissing &&
        (statusStr == 'detected' ||
            statusStr == 'disposal' ||
            statusStr == 'disposed' ||
            statusStr == 'closed' ||
            statusStr == 'resolved' ||
            statusStr == 'traced');
    final isPendingTracing = isMissing && !isTraced;

    String parseGender(dynamic val) {
      final g = (val ?? '').toString().toLowerCase().trim();
      if (g == 'male' || g == 'm' || g == 'पुरुष') return 'male';
      if (g == 'female' || g == 'f' || g == 'स्त्री' || g == 'महिला') {
        return 'female';
      }
      if (g == 'transgender' || g == 'trans' || g == 'tg' || g == 'तृतीयपंथी') {
        return 'transgender';
      }
      if (g.isNotEmpty) return 'other';
      return '';
    }

    int? parseAge(dynamic val) {
      if (val == null || val.toString().trim().isEmpty) return null;
      final match = RegExp(r'\d+').firstMatch(val.toString());
      if (match != null) {
        return int.tryParse(match.group(0)!);
      }
      return null;
    }

    bool parseBool(dynamic val) {
      if (val == true) return true;
      final s = (val ?? '').toString().toLowerCase().trim();
      return s == 'yes' || s == 'y' || s == 'true' || s == '1';
    }

    String parseCondition(dynamic val) {
      final s = (val ?? '').toString().toLowerCase().trim();
      if (s.contains('injur') || s.contains('जखमी')) return 'injured';
      if (s.contains('deceas') ||
          s.contains('dead') ||
          s.contains('मयत') ||
          s.contains('मृत')) {
        return 'deceased';
      }
      return '';
    }

    final victims = <Map<String, dynamic>>[];
    final dynamic candidates = cf['victims'] ??
        extra['victims'] ??
        extra['cheating_victims'] ??
        extra['pocso_victims'] ??
        cf['persons'] ??
        extra['persons'];

    if (candidates is List && candidates.isNotEmpty) {
      for (final v in candidates) {
        if (v is! Map) continue;
        final role = (v['role'] ?? v['person_type'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        if (candidates.toString().contains('person') &&
            role.isNotEmpty &&
            !role.contains('victim')) {
          continue;
        }

        var g = parseGender(
            v['gender'] ?? v['victim_gender'] ?? v['cheating_victim_gender']);
        var age =
            parseAge(v['age'] ?? v['victim_age'] ?? v['cheating_victim_age']);
        final pwd = parseBool(v['pwd'] ?? v['victim_pwd'] ?? v['disability']);
        final mv =
            parseBool(v['mentally_vulnerable'] ?? v['is_mentally_vulnerable']);
        final cond = parseCondition(v['status'] ??
            v['condition'] ??
            v['injured_deceased'] ??
            v['health_status']);

        if (g.isEmpty &&
            (mod == 'crime_women' ||
                mod == '498_a_ipc' ||
                sub.contains('women'))) {
          g = 'female';
        }
        if (age == null && (mod == 'pocso' || sub.contains('pocso'))) {
          age = 15;
        }

        victims.add({
          'gender': g,
          'age': age,
          'pwd': pwd,
          'mentally_vulnerable': mv,
          'condition': cond,
          'is_missing': isMissing,
          'is_traced': isTraced,
          'is_pending_tracing': isPendingTracing,
        });
      }
    }

    if (victims.isEmpty) {
      var g = parseGender(cf['victim_gender'] ??
          extra['victim_gender'] ??
          extra['pocso_victim_gender'] ??
          extra['caw_victim_gender'] ??
          extra['cheating_victim_gender'] ??
          extra['missing_person_gender']);
      var age = parseAge(cf['victim_age'] ??
          extra['victim_age'] ??
          extra['pocso_victim_age'] ??
          extra['caw_victim_age'] ??
          extra['cheating_victim_age'] ??
          extra['missing_person_age']);
      final pwd = parseBool(cf['pwd'] ?? extra['pwd'] ?? extra['victim_pwd']);
      final mv =
          parseBool(cf['mentally_vulnerable'] ?? extra['mentally_vulnerable']);
      final cond = parseCondition(cf['injured_deceased'] ??
          extra['injured_deceased'] ??
          cf['condition'] ??
          extra['condition'] ??
          cf['victim_condition'] ??
          extra['victim_condition']);

      if (g.isEmpty &&
          (mod == 'crime_women' ||
              mod == '498_a_ipc' ||
              sub.contains('women'))) {
        g = 'female';
      }
      if (age == null && (mod == 'pocso' || sub.contains('pocso'))) {
        age = 15;
      }

      victims.add({
        'gender': g,
        'age': age,
        'pwd': pwd,
        'mentally_vulnerable': mv,
        'condition': cond,
        'is_missing': isMissing,
        'is_traced': isTraced,
        'is_pending_tracing': isPendingTracing,
      });
    }

    return victims;
  }

  bool _victimMatchesSingleFilter(Map<String, dynamic> v, String k) {
    final g = v['gender'] as String? ?? '';
    final age = v['age'] as int?;
    final pwd = v['pwd'] as bool? ?? false;
    final mv = v['mentally_vulnerable'] as bool? ?? false;
    final cond = v['condition'] as String? ?? '';
    final isMissing = v['is_missing'] as bool? ?? false;
    final isTraced = v['is_traced'] as bool? ?? false;
    final isPendingTracing = v['is_pending_tracing'] as bool? ?? false;

    switch (k) {
      case 'male':
        return g == 'male';
      case 'female':
        return g == 'female';
      case 'transgender':
        return g == 'transgender';
      case 'other_gender':
      case 'other':
        return g == 'other';
      case 'adult':
        return age != null && age >= 18 && age < 60;
      case 'pwd':
        return pwd;
      case 'minor':
        return age != null && age < 18;
      case 'minor_male':
        return age != null && age < 18 && g == 'male';
      case 'minor_female':
        return age != null && age < 18 && g == 'female';
      case 'women':
        return g == 'female' && (age == null || age >= 18);
      case 'senior':
        return age != null && age >= 60;
      case 'senior_male':
        return age != null && age >= 60 && g == 'male';
      case 'senior_female':
        return age != null && age >= 60 && g == 'female';
      case 'mentally_vulnerable':
        return mv;
      case 'injured':
        return cond == 'injured';
      case 'deceased':
        return cond == 'deceased';
      case 'missing':
        return isMissing;
      case 'traced':
        return isTraced;
      case 'pending_tracing':
        return isPendingTracing;
      case 'age_below_5':
        return age != null && age < 5;
      case 'age_5_10':
        return age != null && age >= 5 && age <= 10;
      case 'age_11_15':
        return age != null && age >= 11 && age <= 15;
      case 'age_16_18':
        return age != null && age >= 16 && age <= 18;
      case 'age_18_59':
        return age != null && age >= 18 && age <= 59;
      case 'age_60_plus':
        return age != null && age >= 60;
    }
    return false;
  }

  bool _recordMatchesMultipleFilters(ModuleRecord r, Set<String> keys) {
    if (keys.isEmpty || (keys.length == 1 && keys.contains('all'))) {
      return true;
    }

    final activeKeys = keys.where((k) => k != 'all').toSet();
    if (activeKeys.isEmpty) return true;

    final victims = _extractVictimsFromRecord(r);
    if (victims.isEmpty) return false;

    final selectedGender = activeKeys.intersection(kGenderKeys);
    final selectedSpecial = activeKeys.intersection(kSpecialKeys);
    final selectedCondition = activeKeys.intersection(kConditionKeys);
    final selectedAge = activeKeys.intersection(kAgeKeys);

    // 1. Check if any single victim satisfies all active groups
    for (final v in victims) {
      if (selectedGender.isNotEmpty &&
          !selectedGender.any((k) => _victimMatchesSingleFilter(v, k))) {
        continue;
      }
      if (selectedSpecial.isNotEmpty &&
          !selectedSpecial.any((k) => _victimMatchesSingleFilter(v, k))) {
        continue;
      }
      if (selectedCondition.isNotEmpty &&
          !selectedCondition.any((k) => _victimMatchesSingleFilter(v, k))) {
        continue;
      }
      if (selectedAge.isNotEmpty &&
          !selectedAge.any((k) => _victimMatchesSingleFilter(v, k))) {
        continue;
      }
      return true;
    }

    // 2. Also check if the case as a whole satisfies each group across its victims
    if (selectedGender.isNotEmpty &&
        !victims.any((v) =>
            selectedGender.any((k) => _victimMatchesSingleFilter(v, k)))) {
      return false;
    }
    if (selectedSpecial.isNotEmpty &&
        !victims.any((v) =>
            selectedSpecial.any((k) => _victimMatchesSingleFilter(v, k)))) {
      return false;
    }
    if (selectedCondition.isNotEmpty &&
        !victims.any((v) =>
            selectedCondition.any((k) => _victimMatchesSingleFilter(v, k)))) {
      return false;
    }
    if (selectedAge.isNotEmpty &&
        !victims.any(
            (v) => selectedAge.any((k) => _victimMatchesSingleFilter(v, k)))) {
      return false;
    }

    return true;
  }

  void _recomputeFilterCounts(List<ModuleRecord> records) {
    final counts = <String, int>{};
    counts['all'] = records.length;
    for (final item in kVictimFilterItems) {
      if (item.key == 'all') continue;
      counts[item.key] = records.where((r) {
        final victims = _extractVictimsFromRecord(r);
        return victims.any((v) => _victimMatchesSingleFilter(v, item.key));
      }).length;
    }
    _filterCounts = counts;
  }

  // ---------------------------------------------------------------------------
  // DATA LOADING & TAB DERIVATION
  // ---------------------------------------------------------------------------

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dataList = await _backend.fetchVictimCases();

      if (mounted) {
        if (dataList != null) {
          final records = dataList.map((m) => ModuleRecord.fromMap(m)).toList();
          _allRecords = records;
          _recomputeFilterCounts(records);
          _applyCurrentFilter();
        } else {
          setState(() {
            _isLoading = false;
            _error = "Failed to load Victim case data.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "An error occurred while loading victim cases.";
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
    if (_allRecords == null) {
      _isLoading = false;
      return;
    }

    final activeRecords = _selectedFilterKeys.contains('all')
        ? _allRecords!
        : _allRecords!
            .where((r) => _recordMatchesMultipleFilters(r, _selectedFilterKeys))
            .toList();

    // 1. Group for Case Wise
    final mappedRows =
        pendingModuleRecordsToTableRows(activeRecords, DateTime.now());
    final grouped = <String, List<Map<String, String>>>{};
    for (final r in mappedRows) {
      final head = r['victim_head']?.trim().isNotEmpty == true
          ? r['victim_head']!.trim()
          : 'Other';
      grouped.putIfAbsent(head, () => []).add(r);
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

    for (final r in activeRecords) {
      final d = r.incidentDate;
      if (d.isAfter(month1)) {
        under1++;
      } else if (d.isAfter(months3)) {
        m1to3++;
      } else if (d.isAfter(months6)) {
        m3to6++;
      } else if (d.isAfter(year1)) {
        m6to12++;
      } else {
        moreThan1Yr++;
      }
    }

    final timeWise = [
      {'period': 'Under 1 month', 'count': under1},
      {'period': '1 to 3 months', 'count': m1to3},
      {'period': '3 to 6 months', 'count': m3to6},
      {'period': '6 to 12 months', 'count': m6to12},
      {'period': 'More than 1 year', 'count': moreThan1Yr},
      {'period': 'Under 3 months (Total)', 'count': under1 + m1to3},
    ];

    // 3. Derive IO Wise breakdown
    final ioGroups = <String, Map<String, dynamic>>{};
    for (final r in activeRecords) {
      final io = r.assignedOfficer.trim().isEmpty
          ? 'Unassigned'
          : r.assignedOfficer.trim();
      final st = r.stationName.trim();
      final key = '$io|$st';
      if (!ioGroups.containsKey(key)) {
        ioGroups[key] = {
          'io_uid': io,
          'io_name': io,
          'io_rank': '',
          'station_name': st,
          'victim_count': 0,
          'pending_count': 0,
        };
      }
      ioGroups[key]!['victim_count'] =
          (ioGroups[key]!['victim_count'] as int) + 1;
      ioGroups[key]!['pending_count'] =
          (ioGroups[key]!['pending_count'] as int) + 1;
    }
    final sortedIOs = ioGroups.values.toList()
      ..sort((a, b) =>
          (b['victim_count'] as int).compareTo(a['victim_count'] as int));

    setState(() {
      _isLoading = false;
      _caseWiseData = grouped;
      _timeWiseData = timeWise;
      _ioWiseData = sortedIOs;
    });
  }

  List<Map<String, String>> _getAllFilteredRows() {
    if (_allRecords == null) return [];
    final activeRecords = _selectedFilterKeys.contains('all')
        ? _allRecords!
        : _allRecords!
            .where((r) => _recordMatchesMultipleFilters(r, _selectedFilterKeys))
            .toList();
    return pendingModuleRecordsToTableRows(activeRecords, DateTime.now());
  }

  String _getActiveFilterLabels() {
    if (_selectedFilterKeys.contains('all') || _selectedFilterKeys.isEmpty) {
      return 'Total Victims';
    }
    return kVictimFilterItems
        .where((i) => _selectedFilterKeys.contains(i.key))
        .map((i) => i.label)
        .join(', ');
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
      'Gender',
      'Special Categories',
      'Condition & Tracing',
      'Age Category',
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
            final leftPos = offset.dx.clamp(12.0, media.size.width - 365.0);
            final topPos = (offset.dy + size.height + 4.0)
                .clamp(12.0, media.size.height - 520.0);

            final filteredItems = kVictimFilterItems.where((item) {
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
                    width: 350,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 480),
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
                                      'Filter Victims',
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
  // FILTER BAR (MULTI-SELECT DROPDOWN + CLEAR ACTION)
  // ---------------------------------------------------------------------------

  Widget _buildFilterDropdownButton() {
    final isFiltered =
        !_selectedFilterKeys.contains('all') && _selectedFilterKeys.isNotEmpty;
    final count = _selectedFilterKeys.contains('all')
        ? (_filterCounts['all'] ?? 0)
        : (_allRecords
                ?.where((r) =>
                    _recordMatchesMultipleFilters(r, _selectedFilterKeys))
                .length ??
            0);

    String labelText;
    IconData leadingIcon = Icons.people_alt_rounded;
    if (_selectedFilterKeys.contains('all') || _selectedFilterKeys.isEmpty) {
      labelText = 'Total Victims';
      leadingIcon = Icons.people_alt_rounded;
    } else if (_selectedFilterKeys.length == 1) {
      final item = kVictimFilterItems.firstWhere(
        (i) => i.key == _selectedFilterKeys.first,
        orElse: () => kVictimFilterItems.first,
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
          // Dropdown Menu Selector
          _buildFilterDropdownButton(),

          const Spacer(),

          // Clear action if active filter
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

    final activeItems = kVictimFilterItems
        .where((i) => _selectedFilterKeys.contains(i.key))
        .toList();
    final filterLabels = activeItems.map((i) => i.label).join(', ');
    final activeRecords = _allRecords
            ?.where(
                (r) => _recordMatchesMultipleFilters(r, _selectedFilterKeys))
            .toList() ??
        [];
    final count = activeRecords.length;

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
    required Future<void> Function() onRefresh,
  }) {
    final isFiltered =
        !_selectedFilterKeys.contains('all') && _selectedFilterKeys.isNotEmpty;

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
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_caseWiseData == null || _caseWiseData!.isEmpty) {
      return _buildEmptyState(
        title: _selectedFilterKeys.contains('all')
            ? 'No Victim Cases Found'
            : 'No Cases for Selected Filters',
        subtitle: _selectedFilterKeys.contains('all')
            ? 'Victim related cases will appear here once registered'
            : 'Try adjusting your filter selection above',
        icon: Icons.category_outlined,
        onRefresh: _loadAllData,
      );
    }

    final keys = _caseWiseData!.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadAllData,
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
                  Navigator.push(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: PendingSummaryScreen(
                        title: _selectedFilterKeys.contains('all')
                            ? 'Victim Cases — $head'
                            : 'Victim ($head) — ${_getActiveFilterLabels()}',
                        isVictim: true,
                        liveRows: cases,
                        stationName: widget.stationName,
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
                          Icons.category_outlined,
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
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_timeWiseData == null || _timeWiseData!.isEmpty) {
      return _buildEmptyState(
        title: 'No Time Intervals Found',
        subtitle: 'Duration-wise victim breakdown will appear here',
        icon: Icons.schedule_rounded,
        onRefresh: _loadAllData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
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
                        title: _selectedFilterKeys.contains('all')
                            ? 'Victim - $p'
                            : 'Victim ($p) - ${_getActiveFilterLabels()}',
                        startDate: start?.toIso8601String().split('T')[0],
                        endDate: end?.toIso8601String().split('T')[0],
                        isVictim: true,
                        victimFilter: _selectedFilterKeys.contains('all')
                            ? null
                            : _selectedFilterKeys.join(','),
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

  // ---------------------------------------------------------------------------
  // TAB 3: IO WISE
  // ---------------------------------------------------------------------------

  Widget _buildIOWiseTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.poppins(color: AppColors.dangerRed),
        ),
      );
    }
    if (_ioWiseData == null || _ioWiseData!.isEmpty) {
      return _buildEmptyState(
        title: 'No Officers Found',
        subtitle:
            'Victim cases mapped to investigating officers will appear here',
        icon: Icons.badge_outlined,
        onRefresh: _loadAllData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.navyMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _ioWiseData!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildActiveFilterBanner();
          }

          final item = _ioWiseData![index - 1];
          final ioName = item['io_name']?.toString() ?? 'Unknown';
          final ioRank = item['io_rank']?.toString() ?? '';
          final stationName = item['station_name']?.toString() ?? '';
          final count = (item['victim_count'] ??
                      item['pending_count'] ??
                      item['count'] as num?)
                  ?.toInt() ??
              0;

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
                        title: _selectedFilterKeys.contains('all')
                            ? 'Victim - $ioName'
                            : 'Victim ($ioName) - ${_getActiveFilterLabels()}',
                        ioUid: item['io_uid']?.toString(),
                        isVictim: true,
                        victimFilter: _selectedFilterKeys.contains('all')
                            ? null
                            : _selectedFilterKeys.join(','),
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

  // ---------------------------------------------------------------------------
  // MAIN SCAFFOLD BUILD
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
          'Victim',
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
                      title: _selectedFilterKeys.contains('all')
                          ? 'Victim Cases — Summary'
                          : 'Victim Summary — ${_getActiveFilterLabels()}',
                      isVictim: true,
                      liveRows: _getAllFilteredRows(),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
