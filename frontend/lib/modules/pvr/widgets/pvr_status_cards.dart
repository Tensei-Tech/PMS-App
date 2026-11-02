// lib/modules/pvr/widgets/pvr_status_cards.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

enum PvrStatusFilter {
  totalReceived,
  verified,
  pending,
}

class PvrStatusCards extends StatelessWidget {
  final PvrStatusFilter selectedFilter;
  final int totalReceivedCount;
  final int verifiedCount;
  final int pendingCount;
  final ValueChanged<PvrStatusFilter> onFilterChanged;

  const PvrStatusCards({
    super.key,
    required this.selectedFilter,
    required this.totalReceivedCount,
    required this.verifiedCount,
    required this.pendingCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        final cards = [
          _buildCard(
            context: context,
            filter: PvrStatusFilter.totalReceived,
            title: TranslationHelper.translate(context, 'Total Received'),
            count: totalReceivedCount,
            icon: Icons.fact_check_rounded,
            accentColor: const Color(0xFF1E40AF), // Deep Blue
            lightBg: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
            iconBg: const Color(0xFFDBEAFE),
            isCompact: isCompact,
          ),
          _buildCard(
            context: context,
            filter: PvrStatusFilter.verified,
            title: TranslationHelper.translate(context, 'Verified'),
            count: verifiedCount,
            icon: Icons.verified_user_rounded,
            accentColor: const Color(0xFF047857), // Emerald Green
            lightBg: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
            iconBg: const Color(0xFFD1FAE5),
            isCompact: isCompact,
          ),
          _buildCard(
            context: context,
            filter: PvrStatusFilter.pending,
            title: TranslationHelper.translate(context, 'Pending'),
            count: pendingCount,
            icon: Icons.hourglass_top_rounded,
            accentColor: const Color(0xFFD97706), // Warm Amber
            lightBg: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            iconBg: const Color(0xFFFEF3C7),
            isCompact: isCompact,
          ),
        ];

        if (isCompact) {
          // On mobile screens (< 500), size cards so that 2 full cards + half of the 3rd card
          // (peeking ~45-50%) are visible, clearly signaling horizontal scrollability.
          final double cardWidth;
          if (constraints.maxWidth < 500) {
            cardWidth = math.max(120.0, (constraints.maxWidth - 16) / 2.45);
          } else {
            cardWidth = math.max(140.0, (constraints.maxWidth - 24) / 3.45);
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cards
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: cardWidth,
                          child: c,
                        ),
                      ))
                  .toList(),
            ),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required PvrStatusFilter filter,
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    required Color lightBg,
    required Color borderColor,
    required Color iconBg,
    bool isCompact = false,
  }) {
    final isSelected = selectedFilter == filter;

    final iconBoxSize = isCompact ? 30.0 : 38.0;
    final iconSize = isCompact ? 15.0 : 18.0;
    final cardPaddingH = isCompact ? 8.0 : 12.0;
    final cardPaddingV = isCompact ? 8.0 : 10.0;
    final titleFontSize = isCompact ? 10.5 : 11.5;
    final countFontSize = isCompact ? 15.5 : 18.0;
    final recordsFontSize = isCompact ? 9.0 : 10.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? lightBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onFilterChanged(filter),
          borderRadius: BorderRadius.circular(12),
          hoverColor: accentColor.withValues(alpha: 0.04),
          splashColor: accentColor.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: cardPaddingH, vertical: cardPaddingV),
            child: Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: iconSize,
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 6.0 : 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? accentColor : AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              fontSize: countFontSize,
                              fontWeight: FontWeight.w700,
                              color:
                                  isSelected ? accentColor : AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              TranslationHelper.translate(context, 'records'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: recordsFontSize,
                                fontWeight: FontWeight.w400,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: isCompact ? 8.0 : 10.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
