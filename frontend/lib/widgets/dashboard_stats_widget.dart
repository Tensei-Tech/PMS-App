// lib/widgets/dashboard_stats_widget.dart
// Client-side dashboard stats — visibility-filtered counts from Firestore streams.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/state_language_helper.dart';
import 'package:provider/provider.dart';
import '../screens/my_cases_screen.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';
import '../utils/case_visibility.dart';

/// Summary cards: total active, pending cases, disposed — filtered by role/visibility.
class DashboardStatsWidget extends StatefulWidget {
  const DashboardStatsWidget({super.key, required this.auth});

  final AuthProvider auth;

  @override
  State<DashboardStatsWidget> createState() => _DashboardStatsWidgetState();
}

class _DashboardStatsWidgetState extends State<DashboardStatsWidget> {
  CaseService get _caseService => CaseService();
  Timer? _pollTimer;

  int _totalActive = 0;
  int _pendingAction = 0;
  int _disposed = 0;
  bool _casesLoaded = false;
  bool _pendingLoaded = false;
  bool _disposalLoaded = false;
  String? _subscribedKey;

  @override
  void didUpdateWidget(covariant DashboardStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureSync();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSync());
  }

  void _ensureSync() {
    if (!widget.auth.isSessionActive) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _subscribedKey = null;
      return;
    }

    final station = widget.auth.activeStation.trim();
    final mode = CaseVisibility.resolveFor(widget.auth);
    final key =
        '$station|${mode.name}|${widget.auth.uid}|${widget.auth.designation}|${widget.auth.zone}';
    if (_subscribedKey == key && _pollTimer != null) return;
    _subscribedKey = key;
    _fetchStats(station);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchStats(station),
    );
  }

  Future<void> _fetchStats(String station) async {
    if (station.isEmpty) {
      if (mounted) {
        setState(() {
          _totalActive = 0;
          _pendingAction = 0;
          _disposed = 0;
          _casesLoaded = true;
          _pendingLoaded = true;
          _disposalLoaded = true;
        });
      }
      return;
    }

    final mode = CaseVisibility.resolveFor(widget.auth);
    final uid = widget.auth.uid;

    try {
      final fetched = await _caseService.fetchStationCases(station);
      final filtered = CaseVisibility.filterRecords(
        fetched,
        uid: uid,
        mode: mode,
      );

      final total = filtered
          .where(
            (r) =>
                r.status.toLowerCase() != 'closed' &&
                r.status.toLowerCase() != 'resolved',
          )
          .length;
      final pending = filtered
          .where(
            (r) =>
                r.status.toLowerCase() == 'pending' ||
                r.status.toLowerCase() == 'open',
          )
          .length;
      final disposed = filtered
          .where(
            (r) =>
                r.status.toLowerCase() == 'disposal' ||
                r.status.toLowerCase() == 'closed' ||
                r.status.toLowerCase() == 'resolved',
          )
          .length;

      if (!mounted) return;
      setState(() {
        _totalActive = total;
        _pendingAction = pending;
        _disposed = disposed;
        _casesLoaded = true;
        _pendingLoaded = true;
        _disposalLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _casesLoaded = true;
          _pendingLoaded = true;
          _disposalLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _openActiveCases() {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: const MyCasesScreen(initialTab: MyCasesTab.active),
      ),
    );
  }

  void _openPendingCases() {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: const MyCasesScreen(initialTab: MyCasesTab.pending),
      ),
    );
  }

  void _openDisposedCases() {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: const MyCasesScreen(initialTab: MyCasesTab.disposal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.auth.isSessionActive) {
      return const SizedBox.shrink();
    }

    final settings = context.watch<SettingsProvider>();
    final lang = settings.locale.languageCode;

    final cards = [
      _StatCardData(
        label: MenuLocalizations.get(lang, 'totalCases'),
        value: _totalActive,
        icon: Icons.folder_rounded,
        accent: AppColors.infoBlue,
        loading: !_casesLoaded,
        onTap: _openActiveCases,
      ),
      _StatCardData(
        label: MenuLocalizations.get(lang, 'pendingCases'),
        value: _pendingAction,
        icon: Icons.schedule_rounded,
        accent: AppColors.warningOrange,
        loading: !_pendingLoaded,
        onTap: _openPendingCases,
      ),
      _StatCardData(
        label: MenuLocalizations.get(lang, 'disposalCases'),
        value: _disposed,
        icon: Icons.check_circle_rounded,
        accent: AppColors.successGreen,
        loading: !_disposalLoaded,
        onTap: _openDisposedCases,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _SummaryStatCard(data: cards[i])),
          ],
        ],
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final bool loading;
  final VoidCallback onTap;
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = !kIsWeb || (screenWidth < 600);
    final isSmallMobile = screenWidth < 400;

    final labelFontSize = isSmallMobile ? 8.5 : (isMobile ? 9.0 : 10.0);
    final valueFontSize = isSmallMobile ? 15.0 : (isMobile ? 16.0 : 20.0);
    final verticalPadding = isMobile ? 6.0 : 12.0;

    return Material(
      elevation: 2,
      shadowColor: data.accent.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 4,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: data.accent.withValues(alpha: 0.15)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [data.accent.withValues(alpha: 0.06), Colors.white],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: data.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(data.icon, color: data.accent, size: 20),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightSubText,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 2 : 4),
              data.loading
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: data.accent,
                      ),
                    )
                  : Text(
                      '${data.value}',
                      style: GoogleFonts.poppins(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                        height: 1.1,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
