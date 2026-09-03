import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../modules/form_iv/providers/form_iv_provider.dart';
import '../theme/app_theme.dart';
import '../utils/common_form_module.dart';
import '../utils/translation_helper.dart';
import '../widgets/common_form_document_view.dart';
import '../widgets/form_iv_category_button.dart';
import '../widgets/module_hub_screen_app_bar.dart';
import '../utils/module_pdf_helper.dart';
import '../utils/pdf_auth_gate.dart';
import '../widgets/module_record_dynamic_document_view.dart';
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

/// Status filter tabs matching dashboard metrics.
enum FormIVStatusTab { total, pending, disposal }

class FormIVSelectionScreen extends StatefulWidget {
  static const allFilterLabel = 'All';

  final FormIVSelectionMode mode;

  const FormIVSelectionScreen({super.key, this.mode = FormIVSelectionMode.add});

  @override
  State<FormIVSelectionScreen> createState() => _FormIVSelectionScreenState();
}

class _FormIVSelectionScreenState extends State<FormIVSelectionScreen> {
  FormIVStatusTab _selectedStatusTab = FormIVStatusTab.total;
  String? _selectedCategory;

  bool get _readOnly => widget.mode == FormIVSelectionMode.readOnly;
  bool get _showNewCaseFab => !_readOnly;

  List<String> get _filterOptions => kFormIVCaseCategories;

  bool _isDisposalRecord(ModuleRecord r) {
    final s = r.status.trim().toLowerCase();
    return s == 'disposal' ||
        s == 'disposed' ||
        s == 'closed' ||
        s == 'resolved';
  }

  bool _isPendingRecord(ModuleRecord r) {
    return !_isDisposalRecord(r);
  }

  List<ModuleRecord> _recordsForStatus(
    List<ModuleRecord> records,
    FormIVStatusTab tab,
  ) {
    switch (tab) {
      case FormIVStatusTab.total:
        return records;
      case FormIVStatusTab.pending:
        return records.where(_isPendingRecord).toList();
      case FormIVStatusTab.disposal:
        return records.where(_isDisposalRecord).toList();
    }
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
    final category =
        (_selectedCategory != null &&
            _selectedCategory != FormIVSelectionScreen.allFilterLabel)
        ? _selectedCategory!
        : kFormIVCaseCategories.first;
    _openForm(category);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormIVProvider>();
    final allRecords = provider.records;

    final totalCount = allRecords.length;
    final pendingCount = allRecords.where(_isPendingRecord).length;
    final disposalCount = allRecords.where(_isDisposalRecord).length;

    final statusRecords = _recordsForStatus(allRecords, _selectedStatusTab);
    final visibleRecords = _selectedCategory != null
        ? _filteredRecordsForCategory(statusRecords, _selectedCategory!)
        : <ModuleRecord>[];

    final String subtitle;
    if (_selectedCategory == null) {
      final transCases = TranslationHelper.translate(context, 'cases');
      final transTypes = TranslationHelper.translate(context, 'types');
      subtitle =
          '${statusRecords.length} $transCases · ${kFormIVCaseCategories.length} $transTypes';
    } else if (_selectedCategory == FormIVSelectionScreen.allFilterLabel) {
      final transCases = TranslationHelper.translate(context, 'cases');
      subtitle = 'All Cases · ${statusRecords.length} $transCases';
    } else {
      final transCategory = TranslationHelper.translate(
        context,
        _selectedCategory!,
      );
      final transCases = TranslationHelper.translate(context, 'cases');
      subtitle = '$transCategory · ${visibleRecords.length} $transCases';
    }

    return PopScope(
      canPop: _selectedCategory == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedCategory != null) {
          setState(() => _selectedCategory = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: ModuleHubScreenAppBar(
          title: TranslationHelper.translate(context, 'Form I-V Cases'),
          subtitle: subtitle,
          badgeLabel: TranslationHelper.translate(
            context,
            'i to v',
          ).toUpperCase(),
          onBackPressed: () {
            if (_selectedCategory != null) {
              setState(() => _selectedCategory = null);
            } else {
              Navigator.pop(context);
            }
          },
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
            _StatusTabBar(
              selectedTab: _selectedStatusTab,
              totalCount: totalCount,
              pendingCount: pendingCount,
              disposalCount: disposalCount,
              onTabChanged: (tab) {
                setState(() => _selectedStatusTab = tab);
              },
            ),
            if (_selectedCategory == null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: AppColors.navyMid,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TranslationHelper.translate(
                        context,
                        'Filter by Case Type',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _CategoryGridView(
                  categories: _filterOptions,
                  records: statusRecords,
                  onCategorySelected: (cat) {
                    setState(() => _selectedCategory = cat);
                  },
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _selectedCategory = null),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              size: 14,
                              color: AppColors.navyDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              TranslationHelper.translate(
                                context,
                                'Back to Categories',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '/',
                            style: GoogleFonts.poppins(
                              color: AppColors.lightSubText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              TranslationHelper.translate(
                                context,
                                _selectedCategory!,
                              ),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FC),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              '${visibleRecords.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleRecords.isEmpty
                    ? _EmptyCasesState(
                        category: _selectedCategory!,
                        readOnly: _readOnly,
                        statusTab: _selectedStatusTab,
                        onNewCase: _showNewCaseFab ? _onNewCase : null,
                      )
                    : ListView.builder(
                        key: PageStorageKey(
                          'category_${_selectedCategory}_${_selectedStatusTab.name}',
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          88,
                        ),
                        itemCount: visibleRecords.length,
                        itemBuilder: (context, index) {
                          final record = visibleRecords[index];
                          return _FormIVCaseCard(
                            record: record,
                            readOnly: _readOnly,
                            onEdit: () => _openForm(
                              record.subCategory?.isNotEmpty == true
                                  ? record.subCategory!
                                  : record.title,
                              existingRecord: record,
                            ),
                            onView: () {
                              Navigator.push(
                                context,
                                AppTheme.fadeSlideRoute(
                                  page: ModuleRecordDetailScreen(
                                    record: record,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusTabBar extends StatelessWidget {
  const _StatusTabBar({
    required this.selectedTab,
    required this.totalCount,
    required this.pendingCount,
    required this.disposalCount,
    required this.onTabChanged,
  });

  final FormIVStatusTab selectedTab;
  final int totalCount;
  final int pendingCount;
  final int disposalCount;
  final ValueChanged<FormIVStatusTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (
        tab: FormIVStatusTab.total,
        label: 'Total Cases',
        count: totalCount,
        badgeBg: const Color(0xFFE8F1FC),
        badgeFg: const Color(0xFF1976D2),
      ),
      (
        tab: FormIVStatusTab.pending,
        label: 'Pending',
        count: pendingCount,
        badgeBg: const Color(0xFFFFF3E0),
        badgeFg: const Color(0xFFE65100),
      ),
      (
        tab: FormIVStatusTab.disposal,
        label: 'Disposal',
        count: disposalCount,
        badgeBg: const Color(0xFFE8F5E9),
        badgeFg: const Color(0xFF2E7D32),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: tabs.map((item) {
            final isSelected = selectedTab == item.tab;
            return Padding(
              padding: const EdgeInsets.only(right: 24),
              child: InkWell(
                onTap: () => onTabChanged(item.tab),
                hoverColor: Colors.transparent,
                splashColor: AppColors.navyMid.withValues(alpha: 0.08),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TranslationHelper.translate(context, item.label),
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.navyDark
                              : AppColors.lightSubText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.badgeBg,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${item.count}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryGridView extends StatelessWidget {
  const _CategoryGridView({
    required this.categories,
    required this.records,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final List<ModuleRecord> records;
  final ValueChanged<String> onCategorySelected;

  int _countFor(String category) {
    if (category == FormIVSelectionScreen.allFilterLabel) {
      return records.length;
    }
    return records.where((r) => r.subCategory == category).length;
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'murder':
      case 'attempt to murder':
        return Icons.warning_amber_rounded;
      case 'dacoity':
      case 'robbery':
      case 'thefts':
      case 'hbt':
        return Icons.lock_outline_rounded;
      case 'kidnapping':
        return Icons.person_search_rounded;
      case 'cheating':
      case 'cbt':
      case 'extortion':
        return Icons.receipt_long_outlined;
      case 'riot':
      case 'unlawful assembly':
        return Icons.groups_rounded;
      case 'rape':
      case 'molestation':
        return Icons.shield_outlined;
      case 'suicide':
      case 'death due to rash driving':
        return Icons.medical_services_outlined;
      case 'hurts':
      case 'assault on public servant':
        return Icons.healing_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = width > 1200 ? 4 : (width > 850 ? 3 : (width > 550 ? 2 : 1));

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 74,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = _countFor(category);
        final isAll = category == FormIVSelectionScreen.allFilterLabel;
        final transCategory = TranslationHelper.translate(context, category);

        return _CategoryGridCard(
          category: transCategory,
          icon: isAll ? Icons.ballot_outlined : _iconForCategory(category),
          count: count,
          isAll: isAll,
          onTap: () => onCategorySelected(category),
        );
      },
    );
  }
}

class _CategoryGridCard extends StatefulWidget {
  const _CategoryGridCard({
    required this.category,
    required this.icon,
    required this.count,
    required this.isAll,
    required this.onTap,
  });

  final String category;
  final IconData icon;
  final int count;
  final bool isAll;
  final VoidCallback onTap;

  @override
  State<_CategoryGridCard> createState() => _CategoryGridCardState();
}

class _CategoryGridCardState extends State<_CategoryGridCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasCases = widget.count > 0;

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
            color: _hovered ? const Color(0xFF1976D2) : const Color(0xFFE2E8F0),
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0xFF1976D2).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _hovered ? 10 : 3,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.isAll
                          ? const Color(0xFF1976D2).withValues(alpha: 0.1)
                          : (hasCases
                                ? const Color(0xFF0284C7).withValues(alpha: 0.1)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: widget.isAll
                          ? const Color(0xFF1976D2)
                          : (hasCases
                                ? const Color(0xFF0284C7)
                                : AppColors.lightSubText),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
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
                            fontSize: 11,
                            color: hasCases
                                ? const Color(0xFF1976D2)
                                : AppColors.lightSubText,
                            fontWeight: hasCases
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: hasCases
                          ? const Color(0xFFE8F1FC)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasCases
                            ? const Color(0xFF1976D2)
                            : AppColors.lightSubText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _hovered
                        ? const Color(0xFF1976D2)
                        : const Color(0xFFCBD5E1),
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

class _FormIVCaseCard extends StatefulWidget {
  const _FormIVCaseCard({
    required this.record,
    required this.onEdit,
    required this.onView,
    this.readOnly = false,
  });

  final ModuleRecord record;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final bool readOnly;

  @override
  State<_FormIVCaseCard> createState() => _FormIVCaseCardState();
}

class _FormIVCaseCardState extends State<_FormIVCaseCard> {
  bool _expanded = false;

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

  Map<String, dynamic> _getDoc(ModuleRecord record) {
    if (record.extraFields[kCommonFormExtraFieldsKey] is Map) {
      return Map<String, dynamic>.from(
        record.extraFields[kCommonFormExtraFieldsKey] as Map,
      );
    }
    return record.extraFields;
  }

  String _getCrNo(ModuleRecord record, Map<String, dynamic> doc) {
    if (record.caseNumber.trim().isNotEmpty) {
      return record.caseNumber.trim();
    }
    final cr = doc['crNo']?.toString().trim();
    if (cr != null && cr.isNotEmpty) return cr;
    final parts = record.title.split('—');
    if (parts.length > 1 && parts.last.trim().isNotEmpty) {
      return parts.last.trim();
    }
    return record.title.isNotEmpty ? record.title : '—';
  }

  String _getSectionAct(ModuleRecord record, Map<String, dynamic> doc) {
    final charges = doc['charges'] ?? record.extraFields['charges'];
    if (charges is Map && charges.isNotEmpty) {
      final parts = <String>[];
      for (final val in charges.values) {
        if (val is Map) {
          final act = val['act']?.toString().trim() ?? '';
          final sections = val['sections'];
          String secStr = '';
          if (sections is List && sections.isNotEmpty) {
            secStr = sections
                .map((s) => s.toString().trim())
                .where((s) => s.isNotEmpty && s != '{}' && s != '[]')
                .join(', ');
          }
          if (secStr.isNotEmpty && act.isNotEmpty) {
            parts.add('$act $secStr');
          } else if (secStr.isNotEmpty) {
            parts.add(secStr);
          } else if (act.isNotEmpty) {
            parts.add(act);
          }
        } else if (val is String) {
          final s = val.trim();
          if (s.isNotEmpty && s != '{}' && s != '[]') {
            parts.add(s);
          }
        }
      }
      if (parts.isNotEmpty) {
        return parts.join(' | ');
      }
    }

    for (final key in [
      'bnsSection',
      'kalam',
      'sections',
      'act',
      'ipc_sections',
      'section',
    ]) {
      final val = doc[key] ?? record.extraFields[key];
      if (val != null) {
        final s = val.toString().trim();
        if (s.isNotEmpty && s != '{}' && s != '[]') {
          return s;
        }
      }
    }

    return '—';
  }

  String _getNameOfAccused(ModuleRecord record, Map<String, dynamic> doc) {
    if (record.accused.trim().isNotEmpty) {
      return record.accused.trim();
    }
    if (doc['isUnknownUntraced'] == true) {
      return 'Unknown / Untraced';
    }
    final accList = doc['accused'];
    if (accList is List && accList.isNotEmpty) {
      final names = <String>[];
      for (final item in accList) {
        if (item is Map && item['name'] != null) {
          final n = item['name'].toString().trim();
          if (n.isNotEmpty) names.add(n);
        }
      }
      if (names.isNotEmpty) return names.join(', ');
    }
    for (final key in [
      'accusedName',
      'm1AccusedName',
      'm_accusedName',
      'eArrestedName',
      'accusedNameAddress',
    ]) {
      final val = doc[key] ?? record.extraFields[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return '—';
  }

  String _getCrimeDate(ModuleRecord record, Map<String, dynamic> doc) {
    final regDate = doc['regDate']?.toString().trim();
    if (regDate != null && regDate.isNotEmpty) {
      return regDate;
    }
    try {
      return DateFormat('dd/MM/yyyy').format(record.incidentDate);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(record.incidentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final doc = _getDoc(record);
    final crNo = _getCrNo(record, doc);
    final sectionAct = _getSectionAct(record, doc);
    final accusedName = _getNameOfAccused(record, doc);
    final crimeDate = _getCrimeDate(record, doc);

    final extra = record.extraFields;
    Map<String, dynamic>? commonFormMap;
    final extraSansCommon = Map<String, dynamic>.from(extra);
    final nested = extra[kCommonFormExtraFieldsKey];
    if (nested is Map) {
      commonFormMap = Map<String, dynamic>.from(nested);
      extraSansCommon.remove(kCommonFormExtraFieldsKey);
    } else if (extra.containsKey('charges') ||
        extra.containsKey('complainant') ||
        extra.containsKey('crNo') ||
        extra.containsKey('spotVillage')) {
      commonFormMap = Map<String, dynamic>.from(extra);
    }

    final statusColor = _statusColor(record.status);
    final categoryLabel = record.subCategory?.trim().isNotEmpty == true
        ? TranslationHelper.translate(context, record.subCategory!.trim())
        : TranslationHelper.translate(
            context,
            record.firestoreCategoryDisplayName,
          );

    final headerStyle = GoogleFonts.poppins(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1E293B),
      letterSpacing: 0.4,
    );

    final valueBoldStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
    );

    final valueRegularStyle = GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1E293B),
    );

    Widget buildButton(String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF64748B), width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            TranslationHelper.translate(context, label),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top pill row: Category & Status
              Row(
                children: [
                  if (categoryLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        categoryLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      TranslationHelper.translate(context, record.status),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // The 4-Column Notepad Table Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF94A3B8),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    // Table Header Row
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8.8),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 1.2,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              TranslationHelper.translate(context, 'CR NO.'),
                              style: headerStyle,
                            ),
                          ),
                          Container(
                            width: 1.2,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Text(
                              TranslationHelper.translate(
                                context,
                                'SECTION/ACT',
                              ),
                              style: headerStyle,
                            ),
                          ),
                          Container(
                            width: 1.2,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: Text(
                              TranslationHelper.translate(
                                context,
                                'NAME OF ACCUSED',
                              ),
                              style: headerStyle,
                            ),
                          ),
                          Container(
                            width: 1.2,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Text(
                              TranslationHelper.translate(
                                context,
                                'CRIME DATE',
                              ),
                              style: headerStyle,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Values Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(crNo, style: valueBoldStyle),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            flex: 4,
                            child: Text(sectionAct, style: valueRegularStyle),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            flex: 5,
                            child: Text(accusedName, style: valueRegularStyle),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            flex: 4,
                            child: Text(crimeDate, style: valueRegularStyle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Centered Expand Chevron
              Center(
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 28,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),

              // Expanded details drawer showing all form fields
              if (_expanded) ...[
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: commonFormMap != null
                      ? CommonFormDocumentView(
                          commonMap: commonFormMap,
                          extraMap: extraSansCommon,
                          record: record,
                          readOnly: widget.readOnly,
                        )
                      : ModuleRecordDynamicDocumentView(
                          record: record,
                          moduleLabel: categoryLabel,
                        ),
                ),
              ],
              const SizedBox(height: 8),

              // Centered 3 Action Buttons: Edit, View, PDF
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!widget.readOnly) ...[
                    buildButton('Edit', widget.onEdit),
                    const SizedBox(width: 16),
                  ],
                  buildButton('View', widget.onView),
                  const SizedBox(width: 16),
                  buildButton(
                    'PDF',
                    () => runWithPdfAuthGate(
                      context,
                      () => ModulePdfHelper.generatePdf(record),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCasesState extends StatelessWidget {
  const _EmptyCasesState({
    required this.category,
    required this.readOnly,
    this.statusTab = FormIVStatusTab.total,
    this.onNewCase,
  });

  final String category;
  final bool readOnly;
  final FormIVStatusTab statusTab;
  final VoidCallback? onNewCase;

  @override
  Widget build(BuildContext context) {
    final isAll = category == FormIVSelectionScreen.allFilterLabel;
    final transCategory = TranslationHelper.translate(context, category);

    String statusLabel = '';
    if (statusTab == FormIVStatusTab.pending) {
      statusLabel = '${TranslationHelper.translate(context, 'pending')} ';
    } else if (statusTab == FormIVStatusTab.disposal) {
      statusLabel = '${TranslationHelper.translate(context, 'disposed')} ';
    }

    final titleText = isAll
        ? (statusTab == FormIVStatusTab.total
              ? TranslationHelper.translate(context, 'No Form I-V cases yet')
              : '${TranslationHelper.translate(context, 'No')} $statusLabel${TranslationHelper.translate(context, 'Form I-V cases yet')}')
        : '${TranslationHelper.translate(context, 'No')} $statusLabel$transCategory ${TranslationHelper.translate(context, 'cases yet')}';
    final descText = readOnly
        ? TranslationHelper.translate(
            context,
            'Cases will appear here once registered.',
          )
        : TranslationHelper.translate(
            context,
            'Tap New Case to register the first case.',
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 72,
              color: Colors.grey.shade300,
            ),
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
