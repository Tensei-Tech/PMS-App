import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../modules/form_iv/providers/form_iv_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_iv_category_button.dart';
import '../widgets/module_hub_screen_app_bar.dart';
import '../utils/translation_helper.dart';
import '../widgets/read_only_module_record_hub_card.dart';
import 'common_form_screen.dart';
import 'module_record_detail_screen.dart';

/// Controls where a Form I-V category tap navigates.
enum FormIVSelectionMode {
  /// Home grid browse — filter bar + cases list on this screen.
  browse,

  /// Drawer / FAB add-entry — same layout; New Case opens Form I-V entry.
  add,

  /// Read-only hub browse.
  readOnly,
}

class FormIVSelectionScreen extends StatefulWidget {
  static const allFilterLabel = 'All';

  final FormIVSelectionMode mode;

  const FormIVSelectionScreen({
    super.key,
    this.mode = FormIVSelectionMode.add,
  });

  @override
  State<FormIVSelectionScreen> createState() => _FormIVSelectionScreenState();
}

class _FormIVSelectionScreenState extends State<FormIVSelectionScreen> {
  String _selectedCategory = FormIVSelectionScreen.allFilterLabel;
  late final PageController _pageController;

  bool get _readOnly => widget.mode == FormIVSelectionMode.readOnly;
  bool get _showNewCaseFab => !_readOnly;

  List<String> get _filterOptions =>
      [FormIVSelectionScreen.allFilterLabel, ...kFormIVCaseCategories];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<ModuleRecord> _filteredRecordsForCategory(
    List<ModuleRecord> records,
    String category,
  ) {
    final filtered = category == FormIVSelectionScreen.allFilterLabel
        ? records
        : records.where((r) => r.subCategory == category).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  void _onCategoryTapped(String category) {
    final index = _filterOptions.indexOf(category);
    if (index != -1) {
      setState(() => _selectedCategory = category);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    if (index >= 0 && index < _filterOptions.length) {
      setState(() {
        _selectedCategory = _filterOptions[index];
      });
    }
  }

  void _openForm(String category, {ModuleRecord? existingRecord}) {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: CommonFormScreen(
          moduleLabel: category,
          moduleKey: 'form_1_5',
          subCategory: category,
          existingRecord: existingRecord,
          readOnly: _readOnly && existingRecord != null,
        ),
      ),
    );
  }

  void _onNewCase() {
    final category = _selectedCategory != FormIVSelectionScreen.allFilterLabel
        ? _selectedCategory
        : kFormIVCaseCategories.first;
    _openForm(category);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormIVProvider>();
    final allRecords = provider.records;
    final visibleRecords =
        _filteredRecordsForCategory(allRecords, _selectedCategory);
    final String subtitle;
    if (_selectedCategory == FormIVSelectionScreen.allFilterLabel) {
      final transCases = TranslationHelper.translate(context, 'cases');
      final transTypes = TranslationHelper.translate(context, 'types');
      subtitle = '${visibleRecords.length} $transCases · ${kFormIVCaseCategories.length} $transTypes';
    } else {
      final transCategory = TranslationHelper.translate(context, _selectedCategory);
      final transCases = TranslationHelper.translate(context, 'cases');
      subtitle = '$transCategory · ${visibleRecords.length} $transCases';
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, 'Form I-V Cases'),
        subtitle: subtitle,
        badgeLabel: TranslationHelper.translate(context, 'i to v').toUpperCase(),
      ),
      floatingActionButton: _showNewCaseFab
          ? FloatingActionButton.extended(
              onPressed: _onNewCase,
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              elevation: 6,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                TranslationHelper.translate(context, 'New Case'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryFilterBar(
            options: _filterOptions,
            selected: _selectedCategory,
            records: allRecords,
            onSelected: _onCategoryTapped,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _filterOptions.length,
              itemBuilder: (context, pageIndex) {
                final currentCategory = _filterOptions[pageIndex];
                final recordsForPage =
                    _filteredRecordsForCategory(allRecords, currentCategory);

                if (recordsForPage.isEmpty) {
                  return _EmptyCasesState(
                    category: currentCategory,
                    readOnly: _readOnly,
                    onNewCase: _showNewCaseFab ? _onNewCase : null,
                  );
                }

                return ListView.builder(
                  key: PageStorageKey('category_$currentCategory'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    88,
                  ),
                  itemCount: recordsForPage.length,
                  itemBuilder: (context, index) {
                    final record = recordsForPage[index];
                    if (_readOnly) {
                      return ReadOnlyModuleRecordHubCard(record: record);
                    }
                    return _FormIVCaseCard(
                      record: record,
                      onEdit: () => _openForm(
                        record.subCategory ?? record.title,
                        existingRecord: record,
                      ),
                      onView: () {
                        Navigator.push(
                          context,
                          AppTheme.fadeSlideRoute(
                            page: ModuleRecordDetailScreen(record: record),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends StatefulWidget {
  const _CategoryFilterBar({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.records = const [],
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final List<ModuleRecord> records;

  @override
  State<_CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<_CategoryFilterBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _CategoryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    final index = widget.options.indexOf(widget.selected);
    if (index != -1 && _scrollController.hasClients) {
      // Estimated pill width ~ 110px
      final targetOffset = (index * 110.0) - 80.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  int _countFor(String option) {
    if (option == FormIVSelectionScreen.allFilterLabel) {
      return widget.records.length;
    }
    return widget.records.where((r) => r.subCategory == option).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: AppColors.navyMid,
                ),
                const SizedBox(width: 6),
                Text(
                  TranslationHelper.translate(context, 'Filter by Case Type'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ScrollConfiguration(
              behavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.options.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final isSelected = option == widget.selected;
                  final count = _countFor(option);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onSelected(option),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.navyDark
                              : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.navyDark
                                : AppColors.lightBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.navyDark.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TranslationHelper.translate(context, option),
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.navyDark,
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : AppColors.navyMid.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                ),
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.navyMid,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormIVCaseCard extends StatelessWidget {
  const _FormIVCaseCard({
    required this.record,
    required this.onEdit,
    required this.onView,
  });

  final ModuleRecord record;
  final VoidCallback onEdit;
  final VoidCallback onView;

  Color _statusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.warningOrange;
      case 'Active':
        return AppColors.infoBlue;
      case 'Resolved':
        return AppColors.successGreen;
      case 'Closed':
        return const Color(0xFF607D8B);
      default:
        return AppColors.lightSubText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record.status);
    final categoryLabel = record.subCategory?.trim().isNotEmpty == true
        ? TranslationHelper.translate(context, record.subCategory!.trim())
        : TranslationHelper.translate(context, record.firestoreCategoryDisplayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (record.caseNumber.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record.caseNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.infoBlue,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        TranslationHelper.translate(context, record.status),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  record.title.trim().isNotEmpty
                      ? record.title.trim()
                      : TranslationHelper.translate(context, 'Untitled Case'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                if (categoryLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    categoryLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_rounded,
                        size: 13, color: AppColors.lightSubText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        record.assignedOfficer.trim().isNotEmpty
                            ? record.assignedOfficer
                            : TranslationHelper.translate(context, 'Unassigned'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.lightSubText,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.lightSubText),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(record.incidentDate),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.lightSubText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.lightBorder),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded,
                            size: 16, color: AppColors.infoBlue),
                        const SizedBox(width: 6),
                        Text(
                          TranslationHelper.translate(context, 'Edit'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.infoBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.lightBorder),
              Expanded(
                child: InkWell(
                  onTap: onView,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_rounded,
                            size: 16, color: AppColors.goldPrimary),
                        const SizedBox(width: 6),
                        Text(
                          TranslationHelper.translate(context, 'View'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCasesState extends StatelessWidget {
  const _EmptyCasesState({
    required this.category,
    required this.readOnly,
    this.onNewCase,
  });

  final String category;
  final bool readOnly;
  final VoidCallback? onNewCase;

  @override
  Widget build(BuildContext context) {
    final isAll = category == FormIVSelectionScreen.allFilterLabel;
    final transCategory = TranslationHelper.translate(context, category);
    final titleText = isAll
        ? TranslationHelper.translate(context, 'No Form I-V cases yet')
        : '${TranslationHelper.translate(context, 'No')} $transCategory ${TranslationHelper.translate(context, 'cases yet')}';
    final descText = readOnly
        ? TranslationHelper.translate(context, 'Cases will appear here once registered.')
        : TranslationHelper.translate(context, 'Tap New Case to register the first case.');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.lightSubText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
            if (onNewCase != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onNewCase,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  TranslationHelper.translate(context, 'New Case'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
