// lib/modules/passport/widgets/passport_status_cards.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';

enum PassportStatusFilter {
  totalReceived,
  verified,
  pending,
}

class PassportStatusCards extends StatelessWidget {
  final PassportStatusFilter selectedFilter;
  final int totalReceivedCount;
  final int verifiedCount;
  final int pendingCount;
  final ValueChanged<PassportStatusFilter> onFilterChanged;

  const PassportStatusCards({
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
        final isCompact = constraints.maxWidth < 600;

        final cards = [
          _buildCard(
            context: context,
            filter: PassportStatusFilter.totalReceived,
            title: TranslationHelper.translate(context, 'Total Verification'),
            count: totalReceivedCount,
            icon: Icons.badge_rounded,
            accentColor: const Color(0xFF1E40AF), // Deep Blue
            lightBg: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
            iconBg: const Color(0xFFDBEAFE),
          ),
          _buildCard(
            context: context,
            filter: PassportStatusFilter.verified,
            title: TranslationHelper.translate(
              context,
              'Verified / Report Submitted',
            ),
            count: verifiedCount,
            icon: Icons.verified_user_rounded,
            accentColor: const Color(0xFF047857), // Emerald Green
            lightBg: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
            iconBg: const Color(0xFFD1FAE5),
          ),
          _buildCard(
            context: context,
            filter: PassportStatusFilter.pending,
            title: TranslationHelper.translate(context, 'Pending'),
            count: pendingCount,
            icon: Icons.hourglass_top_rounded,
            accentColor: const Color(0xFFD97706), // Amber / Warm Orange
            lightBg: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            iconBg: const Color(0xFFFEF3C7),
          ),
        ];

        if (isCompact) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: c,
                    ))
                .toList(),
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
    required PassportStatusFilter filter,
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    required Color lightBg,
    required Color borderColor,
    required Color iconBg,
  }) {
    final isSelected = selectedFilter == filter;

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? accentColor : AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color:
                                  isSelected ? accentColor : AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            TranslationHelper.translate(context, 'records'),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.lightSubText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
