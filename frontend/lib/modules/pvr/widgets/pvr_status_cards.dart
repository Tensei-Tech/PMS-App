// lib/modules/pvr/widgets/pvr_status_cards.dart
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
        final isCompact = constraints.maxWidth < 600;

        final cards = [
          _buildCard(
            context: context,
            filter: PvrStatusFilter.totalReceived,
            title: TranslationHelper.translate(context, 'Total'),
            count: totalReceivedCount,
            icon: Icons.fact_check_rounded,
            accentColor: const Color(0xFF1E40AF), // Deep Blue
            lightBg: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
            iconBg: const Color(0xFFDBEAFE),
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
          ),
          _buildCard(
            context: context,
            filter: PvrStatusFilter.pending,
            title: TranslationHelper.translate(context, 'Pending'),
            count: pendingCount,
            icon: Icons.pending_actions_rounded,
            accentColor: const Color(0xFFB45309), // Warm Amber
            lightBg: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            iconBg: const Color(0xFFFEF3C7),
          ),
        ];

        if (isCompact) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
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
  }) {
    final isSelected = selectedFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFilterChanged(filter),
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withValues(alpha: 0.1),
        hoverColor: accentColor.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? lightBg : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : borderColor.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? accentColor : AppColors.lightSubText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? accentColor : AppColors.navyDark,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
