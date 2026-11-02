import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../providers/auth_provider.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import '../widgets/view_case_card.dart';

/// Tab indices for [MyCasesScreen].
abstract final class MyCasesTab {
  static const int total = 0;
  static const int active = 0;
  static const int pending = 1;
  static const int disposal = 2;
  static const int closed = 2;
}

/// Case list opened from dashboard summary cards or the drawer.
///
/// Displays only cases created by the signed-in officer.
class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key, this.initialTab = MyCasesTab.total});

  final int initialTab;

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<ModuleRecord>? _allCases;
  List<ModuleRecord>? _pendingCases;
  List<ModuleRecord>? _disposalCases;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTab.clamp(0, 2);
    _loadCases();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        CaseService().fetchMyCases(scope: 'all'),
        CaseService().fetchMyCases(scope: 'pending'),
        CaseService().fetchMyCases(scope: 'disposal'),
      ]);
      if (!mounted) return;
      setState(() {
        _allCases = results[0];
        _pendingCases = results[1];
        _disposalCases = results[2];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ModuleRecord> _getCurrentList() {
    switch (_selectedTabIndex) {
      case 1:
        return _pendingCases ?? const [];
      case 2:
        return _disposalCases ?? const [];
      case 0:
      default:
        return _allCases ?? const [];
    }
  }

  static String _safeTrim(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    final s = val.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  List<ModuleRecord> _filter(List<ModuleRecord> list) {
    final q = _safeTrim(_query).toLowerCase();
    if (q.isEmpty) return list;
    return list.where((r) {
      try {
        final t = _safeTrim(r.title).toLowerCase();
        final c = _safeTrim(r.caseNumber).toLowerCase();
        final comp = _safeTrim(r.complainant).toLowerCase();
        final loc = _safeTrim(r.location).toLowerCase();
        final off = _safeTrim(r.assignedOfficer).toLowerCase();
        final cat = _safeTrim(r.firestoreCategoryDisplayName).toLowerCase();
        return t.contains(q) ||
            c.contains(q) ||
            comp.contains(q) ||
            loc.contains(q) ||
            off.contains(q) ||
            cat.contains(q);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName.isNotEmpty ? auth.displayName : 'Officer';
    final role = auth.designation.isNotEmpty ? ' (${auth.designation})' : '';
    final station = auth.stationName.isNotEmpty ? ' · ${auth.stationName}' : '';
    final subtitle = '$name$role$station';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TranslationHelper.translate(context, 'My Cases'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightSubText,
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.navyMid,
        onRefresh: _loadCases,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildStatusTabBar() {
    final tabs = [
      (
        index: 0,
        label: 'Total Cases',
        count: _allCases?.length ?? 0,
        badgeBg: const Color(0xFFE8F1FC),
        badgeFg: const Color(0xFF1976D2),
      ),
      (
        index: 1,
        label: 'Pending',
        count: _pendingCases?.length ?? 0,
        badgeBg: const Color(0xFFFFF3E0),
        badgeFg: const Color(0xFFE65100),
      ),
      (
        index: 2,
        label: 'Disposal',
        count: _disposalCases?.length ?? 0,
        badgeBg: const Color(0xFFE8F5E9),
        badgeFg: const Color(0xFF2E7D32),
      ),
    ];

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: tabs.map((item) {
              final isSelected = _selectedTabIndex == item.index;
              return InkWell(
                onTap: () {
                  if (_selectedTabIndex != item.index) {
                    setState(() => _selectedTabIndex = item.index);
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navyDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TranslationHelper.translate(context, item.label),
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.lightSubText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.22)
                              : item.badgeBg,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${item.count}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : item.badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      _buildStatusTabBar(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1600),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    children:
                        List.generate(6, (_) => const ViewCaseCardSkeleton()),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      _buildStatusTabBar(),
                      const SizedBox(height: 24),
                      const ViewEmptyState(
                        icon: Icons.cloud_off_rounded,
                        iconColor: AppColors.dangerRed,
                        title: 'Unable to load cases',
                        message:
                            'Check your connection and pull down to try again.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final rawList = _getCurrentList();
    final filtered = _filter(rawList);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusTabBar(),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: GoogleFonts.poppins(
                          fontSize: 13.5, color: AppColors.navyDark),
                      decoration: InputDecoration(
                        hintText: TranslationHelper.translate(
                          context,
                          'Search by FIR, title, location...',
                        ),
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.lightSubText,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.lightSubText, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                              color: AppColors.navyMid, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _query.isNotEmpty
                          ? 'Found ${filtered.length} of ${rawList.length} records'
                          : 'Total: ${rawList.length} records',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightSubText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ViewEmptyState(
              icon: Icons.folder_open_rounded,
              iconColor: AppColors.lightSubText,
              title: _query.isNotEmpty ? 'No matching cases' : 'No cases found',
              message: _query.isNotEmpty
                  ? 'Try searching with a different case number, title, or officer name.'
                  : (_selectedTabIndex == 1
                      ? 'No pending cases under your station/jurisdiction.'
                      : (_selectedTabIndex == 2
                          ? 'No disposed cases recorded yet.'
                          : 'No cases recorded under this station.')),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      return ViewCaseCard(
                        record: filtered[i],
                        index: i + 1,
                        isDisposedTab: _selectedTabIndex == 2,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
