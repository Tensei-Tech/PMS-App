// lib/modules/licence/widgets/licence_status_cards.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../providers/licence_provider.dart';

class LicenceStatusCards extends StatelessWidget {
  final LicenceStatusFilter selectedFilter;
  final int totalReceivedCount;
  final int approvedCount;
  final int rejectedCount;
  final int returnedCount;
  final int pendingCount;
  final ValueChanged<LicenceStatusFilter> onFilterChanged;

  const LicenceStatusCards({
    super.key,
    required this.selectedFilter,
    required this.totalReceivedCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.returnedCount,
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
            filter: LicenceStatusFilter.totalReceived,
            title: TranslationHelper.translate(context, 'Total Received'),
            count: totalReceivedCount,
            icon: Icons.assignment_ind_rounded,
            accentColor: const Color(0xFF1E40AF), // Deep Blue
            lightBg: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
            iconBg: const Color(0xFFDBEAFE),
          ),
          _buildCard(
            context: context,
            filter: LicenceStatusFilter.approved,
            title: TranslationHelper.translate(context, 'Approved'),
            count: approvedCount,
            icon: Icons.verified_rounded,
            accentColor: const Color(0xFF047857), // Emerald Green
            lightBg: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
            iconBg: const Color(0xFFD1FAE5),
          ),
          _buildCard(
            context: context,
            filter: LicenceStatusFilter.rejected,
            title: TranslationHelper.translate(context, 'Rejected'),
            count: rejectedCount,
            icon: Icons.cancel_rounded,
            accentColor: const Color(0xFFDC2626), // Crimson Red
            lightBg: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
            iconBg: const Color(0xFFFEE2E2),
          ),
          _buildCard(
            context: context,
            filter: LicenceStatusFilter.returned,
            title: TranslationHelper.translate(context, 'Returned'),
            count: returnedCount,
            icon: Icons.assignment_return_rounded,
            accentColor: const Color(0xFF7C3AED), // Purple
            lightBg: const Color(0xFFF5F3FF),
            borderColor: const Color(0xFFDDD6FE),
            iconBg: const Color(0xFFEDE9FE),
          ),
          _buildCard(
            context: context,
            filter: LicenceStatusFilter.pending,
            title: TranslationHelper.translate(context, 'Pending'),
            count: pendingCount,
            icon: Icons.hourglass_top_rounded,
            accentColor: const Color(0xFFD97706), // Warm Amber
            lightBg: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            iconBg: const Color(0xFFFEF3C7),
          ),
        ];

        if (isCompact) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cards
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 200,
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
    required LicenceStatusFilter filter,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                          fontSize: 11.5,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color:
                                  isSelected ? accentColor : AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TranslationHelper.translate(context, 'records'),
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
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
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
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
