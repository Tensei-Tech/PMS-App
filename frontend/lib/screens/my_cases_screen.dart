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
            child: Padding(
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
