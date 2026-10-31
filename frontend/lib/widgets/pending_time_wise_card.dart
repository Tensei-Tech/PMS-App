import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../screens/filtered_pending_screen.dart';
import '../theme/app_theme.dart';
import 'date_range_sheet.dart';

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

  const PendingTimeWiseCard({
    super.key,
    required this.period,
    required this.count,
    this.vertical = false,
    this.showTitlePrefix = true,
  }) : isCustom = false;

  const PendingTimeWiseCard.custom({
    super.key,
    this.vertical = true,
    this.showTitlePrefix = true,
  })  : period = 'Custom',
        count = 0,
        isCustom = true;

  Future<void> _openCustomRange(BuildContext context) async {
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

  void _open(BuildContext context) {
    if (isCustom) {
      _openCustomRange(context);
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

  Widget _buildVerticalContent() {
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
                  color: AppColors.navyMid.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCustom ? Icons.date_range_rounded : Icons.schedule_rounded,
                  color: AppColors.navyMid,
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
                              color: AppColors.navyMid,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: vertical ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
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
  }
}
