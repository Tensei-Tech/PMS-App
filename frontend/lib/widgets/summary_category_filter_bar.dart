import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Horizontal category filter bar with a `More` overflow menu for long lists.
class SummaryCategoryFilterBar extends StatelessWidget {
  const SummaryCategoryFilterBar({
    super.key,
    required this.totalCount,
    required this.categoryCounts,
    required this.selectedCategory,
    required this.onSelected,
    this.maxVisiblePills = 5,
  });

  final int totalCount;
  final Map<String, int> categoryCounts;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final int maxVisiblePills;

  @override
  Widget build(BuildContext context) {
    if (categoryCounts.length <= 1) {
      return const SizedBox.shrink();
    }

    final hasOverflow = categoryCounts.length > maxVisiblePills + 1;
    final List<String> visibleCats;
    final List<String> overflowCats;

    if (!hasOverflow) {
      visibleCats = categoryCounts.keys.toList()..sort();
      overflowCats = const [];
    } else {
      // Pin the largest categories as quick pills; put the rest in alphabetical overflow.
      final byCount = categoryCounts.entries.toList()
        ..sort((a, b) {
          final cmp = b.value.compareTo(a.value);
          return cmp != 0 ? cmp : a.key.compareTo(b.key);
        });
      visibleCats = byCount.take(maxVisiblePills).map((e) => e.key).toList()
        ..sort();
      overflowCats = byCount.skip(maxVisiblePills).map((e) => e.key).toList()
        ..sort();
    }

    final isOverflowSelected = overflowCats.contains(selectedCategory);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipPill(
                    label: 'All',
                    count: totalCount,
                    isSelected: selectedCategory == 'All',
                    onTap: () => onSelected('All'),
                  ),
                  for (final cat in visibleCats) ...[
                    const SizedBox(width: 8),
                    _FilterChipPill(
                      label: cat,
                      count: categoryCounts[cat] ?? 0,
                      isSelected: selectedCategory == cat,
                      onTap: () => onSelected(cat),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (overflowCats.isNotEmpty) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'More categories',
              offset: const Offset(0, 38),
              color: Colors.white,
              elevation: 6,
              constraints: const BoxConstraints(
                maxHeight: 360,
                minWidth: 220,
                maxWidth: 300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              onSelected: onSelected,
              itemBuilder: (context) => [
                for (final cat in overflowCats)
                  PopupMenuItem<String>(
                    value: cat,
                    height: 38,
                    child: Row(
                      children: [
                        Icon(
                          cat == selectedCategory
                              ? Icons.check_rounded
                              : Icons.circle,
                          size: cat == selectedCategory ? 16 : 6,
                          color: cat == selectedCategory
                              ? AppColors.navyMid
                              : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: cat == selectedCategory
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: cat == selectedCategory
                                  ? AppColors.navyDark
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: cat == selectedCategory
                                ? AppColors.navyMid.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${categoryCounts[cat] ?? 0}',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: cat == selectedCategory
                                  ? AppColors.navyMid
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: _FilterChipPill(
                  label: isOverflowSelected ? selectedCategory : 'More',
                  count: isOverflowSelected
                      ? (categoryCounts[selectedCategory] ?? 0)
                      : overflowCats.length,
                  isSelected: isOverflowSelected,
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.count,
    required this.isSelected,
    this.onTap,
    this.trailingIcon,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.navyDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.navyDark : const Color(0xFFCBD5E1),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.navyDark.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 2),
            Icon(
              trailingIcon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return pill;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: pill),
    );
  }
}
