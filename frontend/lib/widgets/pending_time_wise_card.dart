import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../screens/filtered_pending_screen.dart';
import '../theme/app_theme.dart';
import 'date_range_sheet.dart';
import 'hover_lift.dart';

/// Colour for a pending-duration bucket on the navy summary header: white and
/// light navy for recent cases, gold for older ones (app theme colours).
Color pendingPeriodColorOnDark(String period) {
  switch (period) {
    case 'Under 1 month':
      return Colors.white;
    case '1 to 3 months':
      return const Color(0xFFC5CAE9);
    case '3 to 6 months':
      return const Color(0xFF9FA8DA);
    case '6 to 12 months':
      return AppColors.goldLight;
    case 'More than 1 year':
      return AppColors.goldDark;
    default:
      return Colors.white;
  }
}

/// Asks for a date range and opens the pending cases registered in it.
Future<void> openPendingCustomRange(
  BuildContext context, {
  bool showTitlePrefix = true,
}) async {
  final range = await showDateRangeSheet(context);
  if (range == null || !context.mounted) return;

  final label = DateFormat('dd MMM yyyy');
  final param = DateFormat('yyyy-MM-dd');
  Navigator.push(
    context,
    AppTheme.fadeSlideRoute(
      page: FilteredPendingScreen(
        title: '${showTitlePrefix ? 'Custom - ' : ''}'
            '${label.format(range.start)} to ${label.format(range.end)}',
        startDate: param.format(range.start),
        endDate: param.format(range.end),
      ),
    ),
  );
}

/// One pending-duration row ("Under 1 month · 122 Cases ›"). Tapping it opens
/// the pending cases registered in that period. Shared by the Pending hub's
/// Time Wise tab and the dashboard Calendar tab so both look the same.
class PendingTimeWiseCard extends StatelessWidget {
  final String period;
  final int count;

  /// Stacks icon, period and count top-to-bottom so several cards can sit
  /// side by side in a grid (dashboard Calendar tab).
  final bool vertical;

  /// "Custom" card: asks for a date range instead of showing a count.
  final bool isCustom;

  /// Prefixes the opened list's title with "Time Wise - " / "Custom - ".
  /// The Calendar tab turns it off to show just the period or dates.
  final bool showTitlePrefix;

  /// Vertical cards only: this card's share (0–1) of all pending cases,
  /// shown as a small bar. Null hides the bar.
  final double? share;

  /// Vertical cards only: a shorter layout so the Calendar tab fits on one
  /// phone screen without scrolling.
  final bool compact;

  const PendingTimeWiseCard({
    super.key,
    required this.period,
    required this.count,
    this.vertical = false,
    this.showTitlePrefix = true,
    this.share,
    this.compact = false,
  }) : isCustom = false;

  const PendingTimeWiseCard.custom({
    super.key,
    this.vertical = true,
    this.showTitlePrefix = true,
    this.compact = false,
  })  : period = 'Custom',
        count = 0,
        isCustom = true,
        share = null;

  static const Color _accent = AppColors.navyMid;

  void _open(BuildContext context) {
    if (isCustom) {
      openPendingCustomRange(context, showTitlePrefix: showTitlePrefix);
      return;
    }
    final now = DateTime.now();
    DateTime? start, end;

    if (period == 'Under 1 month') {
      start = now.subtract(const Duration(days: 30));
    } else if (period == '1 to 3 months') {
      start = now.subtract(const Duration(days: 90));
      end = now.subtract(const Duration(days: 30));
    } else if (period == '3 to 6 months') {
      start = now.subtract(const Duration(days: 180));
      end = now.subtract(const Duration(days: 90));
    } else if (period == '6 to 12 months') {
      start = now.subtract(const Duration(days: 365));
      end = now.subtract(const Duration(days: 180));
    } else if (period == 'More than 1 year') {
      end = now.subtract(const Duration(days: 365));
    } else if (period == 'Under 3 months (Total)') {
      start = now.subtract(const Duration(days: 90));
    }

    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: FilteredPendingScreen(
          title: showTitlePrefix ? 'Time Wise - $period' : period,
          startDate: start?.toIso8601String().split('T')[0],
          endDate: end?.toIso8601String().split('T')[0],
        ),
      ),
    );
  }

  Widget _buildCompactContent() {
    final pct = share == null ? null : (share! * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCustom ? Icons.date_range_rounded : Icons.schedule_rounded,
                  color: _accent,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              // Fixed height so the Custom card matches the count cards.
              Expanded(
                child: SizedBox(
                  height: 26,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: isCustom
                        ? Text(
                            'Pick dates',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: _accent,
                            ),
                          )
                        : Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$count',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                                TextSpan(
                                  text: count == 1 ? ' Case' : ' Cases',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                    color: _accent,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.lightSubText,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCustom ? 'Custom range' : period,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 6),
          // Both bottom rows share one height so every card in the grid
          // lines up.
          if (isCustom || pct == null)
            SizedBox(
              height: 16,
              child: Text(
                isCustom ? 'Any start and end date' : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.lightSubText,
                ),
              ),
            )
          else
            SizedBox(
              height: 16,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: share!.clamp(0.0, 1.0),
                        minHeight: 4,
                        color: _accent,
                        backgroundColor: _accent.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$pct%',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightSubText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalContent() {
    if (compact) return _buildCompactContent();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCustom ? Icons.date_range_rounded : Icons.schedule_rounded,
                  color: _accent,
                  size: 16,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.lightSubText,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fixed height so the Custom card lines up with the count cards.
          SizedBox(
            height: 27,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: isCustom
                  ? Text(
                      'Pick dates',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.navyMid,
                      ),
                    )
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$count',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.navyDark,
                            ),
                          ),
                          TextSpan(
                            text: count == 1 ? ' Case' : ' Cases',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                              color: _accent,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
          const SizedBox(height: 2),
          // Room for two lines so cards in a row stay the same height.
          SizedBox(
            height: 32,
            child: Text(
              period,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.navyDark,
              ),
            ),
          ),
          // Share bar, or a matching note on the Custom card, at one fixed
          // height so every card in the row is the same size.
          if (share != null || isCustom) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              child: isCustom
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Any date range',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.lightSubText,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: share!.clamp(0.0, 1.0),
                            minHeight: 5,
                            color: _accent,
                            backgroundColor: _accent.withValues(alpha: 0.12),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(share! * 100).round()}% of pending',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.lightSubText,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
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
          onTap: () => _open(context),
          child: vertical
              ? _buildVerticalContent()
              : Padding(
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
                          Icons.schedule_rounded,
                          color: AppColors.navyMid,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          period,
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
                              color: AppColors.navyMid.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          '$count Cases',
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
    return Padding(
      padding: vertical ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      child: HoverLift(child: card),
    );
  }
}
