import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../providers/auth_provider.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import '../widgets/my_cases_module_selector.dart';
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
  List<ModuleRecord>? _allCases;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cases = await CaseService().fetchMyCases(scope: 'all');
      if (!mounted) return;
      setState(() {
        _allCases = cases;
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
    final isMobile = MediaQuery.of(context).size.width < 500;
    final tabs = [
      (
        index: 0,
        label: isMobile ? 'All' : 'Total Cases',
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

    Widget tabItem(
        ({
          Color badgeBg,
          Color badgeFg,
          int count,
          int index,
          String label,
        }) item) {
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
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 16,
            vertical: isMobile ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navyDark : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  TranslationHelper.translate(context, item.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 11.5 : 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.lightSubText,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 5 : 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 5 : 7,
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
                    fontSize: isMobile ? 10.5 : 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : item.badgeFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final row = Row(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: tabs.map((item) {
        final w = tabItem(item);
        return isMobile ? Expanded(child: w) : w;
      }).toList(),
    );

    return Center(
      child: isMobile
          ? Container(
              width: double.infinity,
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
              child: row,
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border:
                      Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: row,
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: MyCasesPillsSkeleton(),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ViewEmptyState(
                icon: Icons.cloud_off_rounded,
                iconColor: AppColors.dangerRed,
                title: 'Unable to load cases',
                message: 'Check your connection and pull down to try again.',
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: MyCasesPillsLandingView(
              records: _allCases ?? const [],
            ),
          ),
        ),
      ),
    );
  }
}
