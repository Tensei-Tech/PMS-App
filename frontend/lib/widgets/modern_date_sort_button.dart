import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';

/// Single option definition for [ModernDateSortButton].
class ModernSortOption {
  final String key;
  final String label;
  final String shortLabel;
  final IconData icon;

  const ModernSortOption({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.icon,
  });
}

/// Modern, streamlined sort dropdown matching the PMS1 design system.
/// Replaces legacy radio-button PopupMenuButtons with clean, accessible
/// rounded popup menus with highlight states and checkmarks.
class ModernDateSortButton extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<String> onSelected;
  final List<ModernSortOption> options;
  final double height;
  final double fontSize;

  static const List<ModernSortOption> defaultDateOptions = [
    ModernSortOption(
      key: 'newest_incident',
      label: 'Newest first',
      shortLabel: 'Newest',
      icon: Icons.arrow_downward_rounded,
    ),
    ModernSortOption(
      key: 'oldest_incident',
      label: 'Oldest first',
      shortLabel: 'Oldest',
      icon: Icons.arrow_upward_rounded,
    ),
    ModernSortOption(
      key: 'newest_created',
      label: 'Recently added',
      shortLabel: 'Recent',
      icon: Icons.history_rounded,
    ),
  ];

  const ModernDateSortButton({
    super.key,
    required this.selectedKey,
    required this.onSelected,
    this.options = defaultDateOptions,
    this.height = 38.0,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final activeOption = options.firstWhere(
      (o) => o.key == selectedKey,
      orElse: () => options.first,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        tooltip: TranslationHelper.translate(context, 'Sort by Date'),
        onSelected: onSelected,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (ctx) => options.map((opt) {
          final isSelected = opt.key == selectedKey;
          return PopupMenuItem<String>(
            value: opt.key,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    opt.icon,
                    size: 15,
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : AppColors.navyMid,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      TranslationHelper.translate(ctx, opt.label),
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1D4ED8)
                            : AppColors.navyDark,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFF1D4ED8),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
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
            children: [
              Icon(
                activeOption.icon,
                size: 14,
                color: AppColors.navyMid,
              ),
              const SizedBox(width: 5),
              Text(
                TranslationHelper.translate(context, activeOption.shortLabel),
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: AppColors.lightSubText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
