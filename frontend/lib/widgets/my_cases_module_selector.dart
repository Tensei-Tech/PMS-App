import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modules/core/models/base_record.dart';
import '../screens/form_i_v_selection_screen.dart';
import '../screens/form_vi_selection_screen.dart';
import '../theme/app_theme.dart';
import '../utils/category_icon_helper.dart';
import '../utils/category_navigation_helper.dart';
import '../utils/translation_helper.dart';
import 'form_vi_category_button.dart';

/// Item descriptor for the 8 top-level module pills in My Cases.
class MyCasesPillItem {
  final String key;
  final String label;
  final String rawCategory;
  final void Function(BuildContext context) onOpenFullModule;

  const MyCasesPillItem({
    required this.key,
    required this.label,
    required this.rawCategory,
    required this.onOpenFullModule,
  });
}

/// Landing screen widget showing the 8 module cards for My Cases.
/// Tapping any pill takes the user directly into that module's subtab layout screen.
class MyCasesPillsLandingView extends StatelessWidget {
  final List<ModuleRecord> records;

  const MyCasesPillsLandingView({
    super.key,
    required this.records,
  });

  /// The 8 module pills in requested order:
  /// I-V, VI, AD, NC, RTI, Preventive, Prohibition, Gambling.
  static final List<MyCasesPillItem> modules = [
    MyCasesPillItem(
      key: 'form_1_5',
      label: 'Form I-V',
      rawCategory: 'form_1_5',
      onOpenFullModule: (ctx) {
        Navigator.push(
          ctx,
          AppTheme.fadeSlideRoute(
            page: const FormIVSelectionScreen(mode: FormIVSelectionMode.browse),
          ),
        );
      },
    ),
    MyCasesPillItem(
      key: 'form_6',
      label: 'Form VI',
      rawCategory: 'form_6',
      onOpenFullModule: (ctx) {
        Navigator.push(
          ctx,
          AppTheme.fadeSlideRoute(
            page: const FormVISelectionScreen(mode: FormVISelectionMode.browse),
          ),
        );
      },
    ),
    MyCasesPillItem(
      key: 'ad',
      label: 'A.D.',
      rawCategory: 'a.d.',
      onOpenFullModule: (ctx) {
        CategoryNavigationHelper.handleDashboardCategoryTap(
          context: ctx,
          categoryName: 'A.D.',
          moduleKey: 'ad',
          readOnly: false,
        );
      },
    ),
    MyCasesPillItem(
      key: 'nc',
      label: 'N.C.',
      rawCategory: 'n.c.',
      onOpenFullModule: (ctx) {
        CategoryNavigationHelper.handleDashboardCategoryTap(
          context: ctx,
          categoryName: 'N.C.',
          moduleKey: 'nc',
          readOnly: false,
        );
      },
    ),
    MyCasesPillItem(
      key: 'rti',
      label: 'RTI',
      rawCategory: 'rti',
      onOpenFullModule: (ctx) {
        CategoryNavigationHelper.handleDashboardCategoryTap(
          context: ctx,
          categoryName: 'RTI',
          moduleKey: 'rti',
          readOnly: false,
        );
      },
    ),
    MyCasesPillItem(
      key: 'preventive',
      label: 'Preventive',
      rawCategory: 'preventive',
      onOpenFullModule: (ctx) {
        CategoryNavigationHelper.handleDashboardCategoryTap(
          context: ctx,
          categoryName: 'Preventive',
          moduleKey: 'preventive',
          readOnly: false,
        );
      },
    ),
    MyCasesPillItem(
      key: 'prohibition',
      label: 'Prohibition',
      rawCategory: 'prohibition',
      onOpenFullModule: (ctx) {
        CategoryNavigationHelper.handleDashboardCategoryTap(
          context: ctx,
          categoryName: 'Prohibition',
          moduleKey: 'prohibition',
          readOnly: false,
        );
      },
    ),
    MyCasesPillItem(
      key: 'gambling',
      label: 'Gambling',
      rawCategory: 'gambling',
      onOpenFullModule: (ctx) {
        CategoryNavigationHelper.handleDashboardCategoryTap(
          context: ctx,
          categoryName: 'Gambling',
          moduleKey: 'gambling',
          readOnly: false,
        );
      },
    ),
  ];

  static bool isRtiRecord(String mod, String sub, String title, String cat) {
    return mod == 'rti' ||
        mod == 'stand_rti' ||
        sub.contains('rti') ||
        title.contains('rti') ||
        cat.contains('rti');
  }

  static bool isAdRecord(String mod, String sub, String title, String cat) {
    return mod == 'ad' ||
        mod == 'accidental_death' ||
        sub.contains('a.d') ||
        sub.contains('accidental death') ||
        sub.contains('suicide') ||
        sub == 'ad' ||
        sub.startsWith('ad ') ||
        sub.startsWith('ad/') ||
        title.contains('a.d.') ||
        title.contains('accidental death') ||
        title.contains('suicide') ||
        title.startsWith('ad ') ||
        title.startsWith('ad/') ||
        cat.contains('accidental death') ||
        cat.contains('suicide') ||
        cat.contains('a.d') ||
        cat.startsWith('ad ') ||
        cat.startsWith('ad/');
  }

  static bool isNcRecord(String mod, String sub, String title, String cat) {
    return mod == 'nc' ||
        mod == 'stand_nc' ||
        sub.contains('n.c') ||
        sub.contains('non-cognizable') ||
        sub.contains('non cognizable') ||
        sub == 'nc' ||
        sub.startsWith('nc ') ||
        sub.startsWith('nc/') ||
        title.contains('n.c.') ||
        title.startsWith('nc ') ||
        title.startsWith('nc/') ||
        cat.contains('n.c') ||
        cat.contains('non-cognizable') ||
        cat.contains('non cognizable') ||
        cat.startsWith('nc ') ||
        cat.startsWith('nc/');
  }

  static bool isPreventiveRecord(
      String mod, String sub, String title, String cat) {
    return mod == 'preventive' ||
        mod == 'stand_preventive' ||
        mod == 'tadipar' ||
        mod == 'mpda' ||
        mod == 'chapter' ||
        sub.contains('preventive') ||
        sub.contains('tadipar') ||
        sub.contains('mpda') ||
        sub.contains('chapter') ||
        title.contains('tadipar') ||
        title.contains('preventive') ||
        title.contains('chapter') ||
        title.contains('mpda') ||
        cat.contains('tadipar') ||
        cat.contains('preventive') ||
        cat.contains('chapter') ||
        cat.contains('mpda');
  }

  static bool isProhibitionRecord(
      String mod, String sub, String title, String cat) {
    return mod == 'prohibition' ||
        sub.contains('prohibition') ||
        title.contains('prohibition') ||
        cat.contains('prohibition');
  }

  static bool isGamblingRecord(
      String mod, String sub, String title, String cat) {
    return mod == 'gambling' ||
        sub.contains('gambling') ||
        title.contains('gambling') ||
        cat.contains('gambling');
  }

  static bool isForm6Record(String mod, String sub, String title, String cat) {
    return mod == 'form_6' ||
        mod == 'form_vi' ||
        mod == 'part_6' ||
        isProhibitionRecord(mod, sub, title, cat) ||
        isGamblingRecord(mod, sub, title, cat) ||
        kFormVICaseCategories
            .any((c) => c.toLowerCase() == sub || c.toLowerCase() == cat);
  }

  static bool isForm15Record(String mod, String sub, String title, String cat) {
    if (isAdRecord(mod, sub, title, cat) ||
        isNcRecord(mod, sub, title, cat) ||
        isRtiRecord(mod, sub, title, cat) ||
        isPreventiveRecord(mod, sub, title, cat) ||
        isForm6Record(mod, sub, title, cat)) {
      return false;
    }
    return true;
  }

  /// Calculates case count for a given module [key] from [list].
  static int countForPill(List<ModuleRecord> list, String key) {
    return list.where((r) {
      final mod = r.moduleKey.toLowerCase().trim();
      final sub = (r.subCategory ?? '').toLowerCase().trim();
      final title = r.title.toLowerCase().trim();
      final cat = r.firestoreCategoryDisplayName.toLowerCase().trim();

      switch (key) {
        case 'form_1_5':
          return isForm15Record(mod, sub, title, cat);
        case 'form_6':
          return isForm6Record(mod, sub, title, cat);
        case 'ad':
          return isAdRecord(mod, sub, title, cat);
        case 'nc':
          return isNcRecord(mod, sub, title, cat);
        case 'rti':
          return isRtiRecord(mod, sub, title, cat);
        case 'preventive':
          return isPreventiveRecord(mod, sub, title, cat);
        case 'prohibition':
          return isProhibitionRecord(mod, sub, title, cat);
        case 'gambling':
          return isGamblingRecord(mod, sub, title, cat);
        default:
          return false;
      }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final int cols;
        if (availableWidth >= 1100) {
          cols = 4;
        } else if (availableWidth >= 750) {
          cols = 3;
        } else {
          cols = 2;
        }
        final isCompact = availableWidth < 600;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: isCompact ? 10 : 14,
            mainAxisSpacing: isCompact ? 10 : 14,
            mainAxisExtent: isCompact ? 76 : 80,
          ),
          itemBuilder: (context, index) {
            final pill = modules[index];
            final count = countForPill(records, pill.key);

            return MyCasesPillCard(
              pill: pill,
              count: count,
              isCompact: isCompact,
              onTap: () => pill.onOpenFullModule(context),
            );
          },
        );
      },
    );
  }
}

/// Visual card for the module pill.
class MyCasesPillCard extends StatefulWidget {
  final MyCasesPillItem pill;
  final int count;
  final bool isCompact;
  final VoidCallback onTap;

  const MyCasesPillCard({
    super.key,
    required this.pill,
    required this.count,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  State<MyCasesPillCard> createState() => _MyCasesPillCardState();
}

class _MyCasesPillCardState extends State<MyCasesPillCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasCases = widget.count > 0;
    final isCompact = widget.isCompact;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? AppColors.navyMid : const Color(0xFFE2E8F0),
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppColors.navyMid.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _hovered ? 8 : 3,
              offset: Offset(0, _hovered ? 3 : 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: isCompact ? 8 : 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: isCompact ? 38 : 42,
                    height: isCompact ? 38 : 42,
                    decoration: BoxDecoration(
                      color: hasCases
                          ? AppColors.navyMid.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: CategoryIconHelper.buildWidget(
                        widget.pill.rawCategory,
                        size: isCompact ? 19 : 20,
                        color: hasCases
                            ? AppColors.navyMid
                            : AppColors.lightSubText,
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 9 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          TranslationHelper.translate(
                            context,
                            widget.pill.label,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: isCompact ? 12.0 : 13.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.count == 1
                              ? '1 case'
                              : '${widget.count} cases',
                          style: GoogleFonts.poppins(
                            fontSize: isCompact ? 10.5 : 11.5,
                            color: hasCases
                                ? AppColors.navyMid
                                : AppColors.lightSubText,
                            fontWeight:
                                hasCases ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: isCompact ? 15 : 18,
                    color:
                        _hovered ? AppColors.navyMid : const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton grid displayed while cases are loading.
class MyCasesPillsSkeleton extends StatelessWidget {
  const MyCasesPillsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final int cols;
        if (availableWidth >= 1100) {
          cols = 4;
        } else if (availableWidth >= 750) {
          cols = 3;
        } else {
          cols = 2;
        }
        final isCompact = availableWidth < 600;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: isCompact ? 10 : 14,
            mainAxisSpacing: isCompact ? 10 : 14,
            mainAxisExtent: isCompact ? 76 : 80,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: isCompact ? 8 : 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: isCompact ? 38 : 42,
                    height: isCompact ? 38 : 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(width: isCompact ? 9 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isCompact ? 60 : 80,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 40,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: isCompact ? 15 : 18,
                    color: const Color(0xFFE2E8F0),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
