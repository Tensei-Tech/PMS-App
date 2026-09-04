import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../modules/form_iv/providers/form_iv_provider.dart';
import '../theme/app_theme.dart';
import '../utils/common_form_module.dart';
import '../utils/module_pdf_helper.dart';
import '../utils/pdf_auth_gate.dart';
import '../utils/translation_helper.dart';
import '../widgets/common_form_document_view.dart';
import '../widgets/form_iv_category_button.dart';
import '../widgets/module_hub_screen_app_bar.dart';
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

/// Target date field for filtering and sorting cases.
enum FormIVDateField { incidentDate, createdAt }

/// Date sorting direction.
enum FormIVDateSortOrder { newestFirst, oldestFirst }

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

  // Date filtering & sorting state
  DateTimeRange? _selectedDateRange;
  String? _datePresetLabel;
  FormIVDateField _dateField = FormIVDateField.incidentDate;
  FormIVDateSortOrder _dateSortOrder = FormIVDateSortOrder.newestFirst;

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

  DateTime _recordTargetDate(ModuleRecord r) {
    return _dateField == FormIVDateField.incidentDate
        ? r.incidentDate
        : r.createdAt;
  }

  bool _recordMatchesDate(ModuleRecord r) {
    if (_selectedDateRange == null) return true;
    final date = _recordTargetDate(r);
    final start = DateTime(
      _selectedDateRange!.start.year,
      _selectedDateRange!.start.month,
      _selectedDateRange!.start.day,
    );
    final end = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
      23,
      59,
      59,
      999,
    );
    return !date.isBefore(start) && !date.isAfter(end);
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _datePresetLabel = null;
    });
  }

  void _applyDatePreset(String label, DateTimeRange? range) {
    setState(() {
      _selectedDateRange = range;
      _datePresetLabel = range == null ? null : label;
    });
  }

  // ignore: unused_element
  void _toggleSortOrder() {
    setState(() {
      _dateSortOrder = _dateSortOrder == FormIVDateSortOrder.newestFirst
          ? FormIVDateSortOrder.oldestFirst
          : FormIVDateSortOrder.newestFirst;
    });
  }

  String _formatDateRangeShort(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return DateFormat('dd MMM yyyy').format(start);
    }
    if (start.year == end.year) {
      return '${DateFormat('dd MMM').format(start)} – ${DateFormat('dd MMM yyyy').format(end)}';
    }
    return '${DateFormat('dd/MM/yy').format(start)} – ${DateFormat('dd/MM/yy').format(end)}';
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _selectedDateRange,
      helpText: TranslationHelper.translate(context, 'Select Date Range'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyMid,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _datePresetLabel = null;
      });
    }
  }

  Future<void> _pickSingleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange?.start ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      helpText: TranslationHelper.translate(context, 'Select Specific Date'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyMid,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(start: picked, end: picked);
        _datePresetLabel = null;
      });
    }
  }

  void _showDateFilterDialog() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasFilter = _selectedDateRange != null;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    TranslationHelper.translate(
                                      context,
                                      'Date Calendar & Sort',
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                  Text(
                                    TranslationHelper.translate(
                                      context,
                                      'Filter cases by date and change sort order',
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: AppColors.lightSubText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: AppColors.lightSubText,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),

                        // Section 1: Quick Presets
                        Text(
                          TranslationHelper.translate(
                            context,
                            'QUICK DATE PRESETS',
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPresetChip(
                              label: 'All Dates',
                              isSelected: _selectedDateRange == null,
                              onTap: () {
                                _clearDateFilter();
                                setModalState(() {});
                              },
                            ),
                            _buildPresetChip(
                              label: 'Today',
                              isSelected: _datePresetLabel == 'Today',
                              onTap: () {
                                _applyDatePreset(
                                  'Today',
                                  DateTimeRange(start: today, end: today),
                                );
                                setModalState(() {});
                              },
                            ),
                            _buildPresetChip(
                              label: 'Yesterday',
                              isSelected: _datePresetLabel == 'Yesterday',
                              onTap: () {
                                final yest = today.subtract(
                                  const Duration(days: 1),
                                );
                                _applyDatePreset(
                                  'Yesterday',
                                  DateTimeRange(start: yest, end: yest),
                                );
                                setModalState(() {});
                              },
                            ),
                            _buildPresetChip(
                              label: 'This Week',
                              isSelected: _datePresetLabel == 'This Week',
                              onTap: () {
                                final startOfWeek = today.subtract(
                                  Duration(days: today.weekday - 1),
                                );
                                _applyDatePreset(
                                  'This Week',
                                  DateTimeRange(start: startOfWeek, end: today),
                                );
                                setModalState(() {});
                              },
                            ),
                            _buildPresetChip(
                              label: 'This Month',
                              isSelected: _datePresetLabel == 'This Month',
                              onTap: () {
                                final startOfMonth = DateTime(
                                  now.year,
                                  now.month,
                                  1,
                                );
                                _applyDatePreset(
                                  'This Month',
                                  DateTimeRange(
                                    start: startOfMonth,
                                    end: today,
                                  ),
                                );
                                setModalState(() {});
                              },
                            ),
                            _buildPresetChip(
                              label: 'Last 30 Days',
                              isSelected: _datePresetLabel == 'Last 30 Days',
                              onTap: () {
                                final start = today.subtract(
                                  const Duration(days: 30),
                                );
                                _applyDatePreset(
                                  'Last 30 Days',
                                  DateTimeRange(start: start, end: today),
                                );
                                setModalState(() {});
                              },
                            ),
                            _buildPresetChip(
                              label: 'This Year',
                              isSelected: _datePresetLabel == 'This Year',
                              onTap: () {
                                final startOfYear = DateTime(now.year, 1, 1);
                                _applyDatePreset(
                                  'This Year',
                                  DateTimeRange(start: startOfYear, end: today),
                                );
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Custom Pickers
                        Text(
                          TranslationHelper.translate(
                            context,
                            'CUSTOM CALENDAR PICKER',
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _pickCustomDateRange();
                                },
                                icon: const Icon(
                                  Icons.date_range_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  TranslationHelper.translate(
                                    context,
                                    'Date Range',
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navyMid,
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _pickSingleDate();
                                },
                                icon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  TranslationHelper.translate(
                                    context,
                                    'Single Date',
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navyMid,
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 3: Target Date Field
                        Text(
                          TranslationHelper.translate(
                            context,
                            'FILTER & SORT BY',
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceTile(
                                title: 'Incident Date',
                                subtitle: 'Crime date',
                                isSelected:
                                    _dateField == FormIVDateField.incidentDate,
                                onTap: () {
                                  setState(() {
                                    _dateField = FormIVDateField.incidentDate;
                                  });
                                  setModalState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildChoiceTile(
                                title: 'Registration Date',
                                subtitle: 'Filing date',
                                isSelected:
                                    _dateField == FormIVDateField.createdAt,
                                onTap: () {
                                  setState(() {
                                    _dateField = FormIVDateField.createdAt;
                                  });
                                  setModalState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 4: Sort Order
                        Text(
                          TranslationHelper.translate(context, 'SORT ORDER'),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceTile(
                                title: 'Newest First',
                                subtitle: 'Descending (↓)',
                                isSelected: _dateSortOrder ==
                                    FormIVDateSortOrder.newestFirst,
                                onTap: () {
                                  setState(() {
                                    _dateSortOrder =
                                        FormIVDateSortOrder.newestFirst;
                                  });
                                  setModalState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildChoiceTile(
                                title: 'Oldest First',
                                subtitle: 'Ascending (↑)',
                                isSelected: _dateSortOrder ==
                                    FormIVDateSortOrder.oldestFirst,
                                onTap: () {
                                  setState(() {
                                    _dateSortOrder =
                                        FormIVDateSortOrder.oldestFirst;
                                  });
                                  setModalState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Dialog Footer Actions
                        Row(
                          children: [
                            if (hasFilter)
                              TextButton.icon(
                                onPressed: () {
                                  _clearDateFilter();
                                  Navigator.pop(ctx);
                                },
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                label: Text(
                                  TranslationHelper.translate(
                                    context,
                                    'Clear Filter',
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyMid,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                TranslationHelper.translate(context, 'Apply'),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1976D2) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          TranslationHelper.translate(context, label),
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.navyDark,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F1FC) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1976D2) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 14,
                  color: isSelected
                      ? const Color(0xFF1976D2)
                      : AppColors.lightSubText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    TranslationHelper.translate(context, title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1976D2)
                          : AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.lightSubText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final categoryRecords = category == FormIVSelectionScreen.allFilterLabel
        ? records.toList()
        : records.where((r) => r.subCategory == category).toList();

    final filtered = categoryRecords.where(_recordMatchesDate).toList();

    filtered.sort((a, b) {
      final dateA = _recordTargetDate(a);
      final dateB = _recordTargetDate(b);
      return _dateSortOrder == FormIVDateSortOrder.newestFirst
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });
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
    final category = (_selectedCategory != null &&
            _selectedCategory != FormIVSelectionScreen.allFilterLabel)
        ? _selectedCategory!
        : kFormIVCaseCategories.first;
    _openForm(category);
  }

  Widget _buildDateAndSortControls() {
    final hasDateFilter = _selectedDateRange != null;
    final dateText = hasDateFilter
        ? (_datePresetLabel ?? _formatDateRangeShort(_selectedDateRange!))
        : TranslationHelper.translate(context, 'Date Filter');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Calendar Date Picker Button
        InkWell(
          onTap: _showDateFilterDialog,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.fromLTRB(
              hasDateFilter ? 8 : 10,
              6,
              hasDateFilter ? 4 : 10,
              6,
            ),
            decoration: BoxDecoration(
              color: hasDateFilter ? const Color(0xFFE8F1FC) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasDateFilter
                    ? const Color(0xFF1976D2)
                    : const Color(0xFFCBD5E1),
                width: hasDateFilter ? 1.3 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasDateFilter
                      ? const Color(0xFF1976D2).withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 15,
                  color: hasDateFilter
                      ? const Color(0xFF1976D2)
                      : AppColors.navyMid,
                ),
                const SizedBox(width: 6),
                Text(
                  dateText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        hasDateFilter ? FontWeight.w600 : FontWeight.w500,
                    color: hasDateFilter
                        ? const Color(0xFF1976D2)
                        : AppColors.navyDark,
                  ),
                ),
                if (hasDateFilter) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _clearDateFilter,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Sort by Date Toggle & Menu Button
        PopupMenuButton<String>(
          tooltip: TranslationHelper.translate(context, 'Sort by Date'),
          onSelected: (val) {
            setState(() {
              switch (val) {
                case 'newest_incident':
                  _dateField = FormIVDateField.incidentDate;
                  _dateSortOrder = FormIVDateSortOrder.newestFirst;
                  break;
                case 'oldest_incident':
                  _dateField = FormIVDateField.incidentDate;
                  _dateSortOrder = FormIVDateSortOrder.oldestFirst;
                  break;
                case 'newest_created':
                  _dateField = FormIVDateField.createdAt;
                  _dateSortOrder = FormIVDateSortOrder.newestFirst;
                  break;
                case 'oldest_created':
                  _dateField = FormIVDateField.createdAt;
                  _dateSortOrder = FormIVDateSortOrder.oldestFirst;
                  break;
              }
            });
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'newest_incident',
              child: Row(
                children: [
                  Icon(
                    _dateField == FormIVDateField.incidentDate &&
                            _dateSortOrder == FormIVDateSortOrder.newestFirst
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Incident Date (Newest first)',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'oldest_incident',
              child: Row(
                children: [
                  Icon(
                    _dateField == FormIVDateField.incidentDate &&
                            _dateSortOrder == FormIVDateSortOrder.oldestFirst
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Incident Date (Oldest first)',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'newest_created',
              child: Row(
                children: [
                  Icon(
                    _dateField == FormIVDateField.createdAt &&
                            _dateSortOrder == FormIVDateSortOrder.newestFirst
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filing Date (Newest first)',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'oldest_created',
              child: Row(
                children: [
                  Icon(
                    _dateField == FormIVDateField.createdAt &&
                            _dateSortOrder == FormIVDateSortOrder.oldestFirst
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: const Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filing Date (Oldest first)',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  _dateSortOrder == FormIVDateSortOrder.newestFirst
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 14,
                  color: AppColors.navyMid,
                ),
                const SizedBox(width: 4),
                Text(
                  _dateSortOrder == FormIVDateSortOrder.newestFirst
                      ? TranslationHelper.translate(context, 'Newest')
                      : TranslationHelper.translate(context, 'Oldest'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 16,
                  color: AppColors.lightSubText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDateFilterBanner(int count) {
    if (_selectedDateRange == null) return const SizedBox.shrink();
    final fieldName = _dateField == FormIVDateField.incidentDate
        ? TranslationHelper.translate(context, 'incident date')
        : TranslationHelper.translate(context, 'registration date');
    final label =
        _datePresetLabel ?? _formatDateRangeShort(_selectedDateRange!);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_rounded,
            size: 14,
            color: Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Filtered by $fieldName: $label ($count cases found)',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ),
          InkWell(
            onTap: _clearDateFilter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    TranslationHelper.translate(context, 'Reset'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

    final dateSuffix = (_selectedCategory != null && _selectedDateRange != null)
        ? ' · ${_datePresetLabel ?? _formatDateRangeShort(_selectedDateRange!)}'
        : '';

    final String subtitle;
    if (_selectedCategory == null) {
      final transCases = TranslationHelper.translate(context, 'cases');
      final transTypes = TranslationHelper.translate(context, 'types');
      subtitle =
          '${statusRecords.length} $transCases · ${kFormIVCaseCategories.length} $transTypes';
    } else if (_selectedCategory == FormIVSelectionScreen.allFilterLabel) {
      final transCases = TranslationHelper.translate(context, 'cases');
      subtitle = 'All Cases · ${visibleRecords.length} $transCases$dateSuffix';
    } else {
      final transCategory = TranslationHelper.translate(
        context,
        _selectedCategory!,
      );
      final transCases = TranslationHelper.translate(context, 'cases');
      subtitle =
          '$transCategory · ${visibleRecords.length} $transCases$dateSuffix';
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
                    _buildDateAndSortControls(),
                  ],
                ),
              ),
              if (_selectedDateRange != null)
                _buildActiveDateFilterBanner(visibleRecords.length),
              Expanded(
                child: visibleRecords.isEmpty
                    ? _EmptyCasesState(
                        category: _selectedCategory!,
                        readOnly: _readOnly,
                        statusTab: _selectedStatusTab,
                        onNewCase: _showNewCaseFab ? _onNewCase : null,
                        selectedDateRange: _selectedDateRange,
                        onClearDateFilter: _clearDateFilter,
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

typedef _StatusTabBar = FormIVStatusTabBar;

class FormIVStatusTabBar extends StatelessWidget {
  const FormIVStatusTabBar({
    super.key,
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
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
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
                            fontWeight:
                                hasCases ? FontWeight.w600 : FontWeight.w400,
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

typedef _FormIVCaseCard = FormIVCaseCard;

class FormIVCaseCard extends StatefulWidget {
  const FormIVCaseCard({
    super.key,
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
  State<FormIVCaseCard> createState() => _FormIVCaseCardState();
}

class _FormIVCaseCardState extends State<FormIVCaseCard> {
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

    final station = (doc['policeStation'] ??
            record.extraFields['policeStation'] ??
            record.stationName)
        .toString()
        .trim();
    final dynamic compRaw = doc['complainant'] is Map
        ? doc['complainant']['name']
        : (doc['complainantName'] ??
            record.extraFields['complainantName'] ??
            record.complainant);
    final complainant = compRaw?.toString().trim() ?? '—';
    final ioName = (doc['ioName'] ??
            doc['investigatingOfficer'] ??
            record.extraFields['investigatingOfficer'] ??
            record.assignedOfficer)
        .toString()
        .trim();
    final spotVillage = (doc['spotVillage'] ??
            doc['crimeSpot'] ??
            record.extraFields['spotVillage'] ??
            record.location)
        .toString()
        .trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  _expanded ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
              width: _expanded ? 1.4 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clickable Header Row: All fields in one clean line
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 820;

                      if (!isWide) {
                        return _buildMobileCompactHeader(
                          crNo: crNo,
                          categoryLabel: categoryLabel,
                          sectionAct: sectionAct,
                          accusedName: accusedName,
                          crimeDate: crimeDate,
                          statusColor: statusColor,
                          record: record,
                        );
                      }

                      return Row(
                        children: [
                          // 1. CR No. Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'CR ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  crNo,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (categoryLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.goldPrimary.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                categoryLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.goldPrimary,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 10),

                          // Vertical Divider
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(width: 10),

                          // 2. Section / Act
                          Expanded(
                            flex: 3,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.gavel_rounded,
                                  size: 13,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sec: ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    sectionAct,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Vertical Divider
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(width: 10),

                          // 3. Name of Accused
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Accused: ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    accusedName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Vertical Divider
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(width: 10),

                          // 4. Crime Date
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 12.5,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                crimeDate,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),

                          // 5. Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
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
                              TranslationHelper.translate(
                                context,
                                record.status,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 6. Action Buttons: Edit, View, PDF
                          if (!widget.readOnly) ...[
                            _buildCompactActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              onTap: widget.onEdit,
                            ),
                            const SizedBox(width: 6),
                          ],
                          _buildCompactActionButton(
                            icon: Icons.visibility_outlined,
                            label: 'View',
                            onTap: widget.onView,
                          ),
                          const SizedBox(width: 6),
                          _buildCompactActionButton(
                            icon: Icons.picture_as_pdf_outlined,
                            label: 'PDF',
                            onTap: () => runWithPdfAuthGate(
                              context,
                              () => ModulePdfHelper.generatePdf(record),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 7. Dropdown Arrow
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _expanded
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _expanded
                                    ? const Color(0xFFCBD5E1)
                                    : Colors.transparent,
                              ),
                            ),
                            child: AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Expanded details drawer showing all form fields & highlights
              if (_expanded) ...[
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header of details drawer
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.subject_rounded,
                              size: 15,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            TranslationHelper.translate(
                              context,
                              'Case Details & Full Record',
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => setState(() => _expanded = false),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    TranslationHelper.translate(
                                      context,
                                      'Close',
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick summary highlights
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          children: [
                            _buildDetailInfoItem(
                              icon: Icons.local_police_outlined,
                              label: 'Police Station',
                              value: station.isNotEmpty ? station : '—',
                            ),
                            _buildDetailInfoItem(
                              icon: Icons.person_pin_circle_outlined,
                              label: 'Complainant',
                              value: complainant.isNotEmpty ? complainant : '—',
                            ),
                            _buildDetailInfoItem(
                              icon: Icons.badge_outlined,
                              label: 'Investigating Officer',
                              value: ioName.isNotEmpty ? ioName : '—',
                            ),
                            _buildDetailInfoItem(
                              icon: Icons.place_outlined,
                              label: 'Crime Spot',
                              value: spotVillage.isNotEmpty ? spotVillage : '—',
                            ),
                            _buildDetailInfoItem(
                              icon: Icons.event_note_outlined,
                              label: 'Registration Date',
                              value: DateFormat(
                                'dd/MM/yyyy, hh:mm a',
                              ).format(record.createdAt),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Full Document View
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                      const SizedBox(height: 12),

                      // Bottom action bar inside expanded panel
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!widget.readOnly) ...[
                            FilledButton.icon(
                              onPressed: widget.onEdit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.navyMid,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 15),
                              label: Text(
                                TranslationHelper.translate(
                                  context,
                                  'Edit Case',
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: widget.onView,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navyDark,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 15,
                            ),
                            label: Text(
                              TranslationHelper.translate(
                                context,
                                'Full View',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => runWithPdfAuthGate(
                              context,
                              () => ModulePdfHelper.generatePdf(record),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC53030),
                              side: const BorderSide(color: Color(0xFFFEB2B2)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 15,
                            ),
                            label: Text(
                              TranslationHelper.translate(
                                context,
                                'Download PDF',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final fg = color ?? const Color(0xFF1E293B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
            Text(
              TranslationHelper.translate(context, label),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1976D2)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TranslationHelper.translate(context, label),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileCompactHeader({
    required String crNo,
    required String categoryLabel,
    required String sectionAct,
    required String accusedName,
    required String crimeDate,
    required Color statusColor,
    required ModuleRecord record,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'CR $crNo',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (categoryLabel.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                TranslationHelper.translate(context, record.status),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _expanded
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Sec: $sectionAct',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Accused: $accusedName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              crimeDate,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!widget.readOnly) ...[
              _buildCompactActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: widget.onEdit,
              ),
              const SizedBox(width: 6),
            ],
            _buildCompactActionButton(
              icon: Icons.visibility_outlined,
              label: 'View',
              onTap: widget.onView,
            ),
            const SizedBox(width: 6),
            _buildCompactActionButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              onTap: () => runWithPdfAuthGate(
                context,
                () => ModulePdfHelper.generatePdf(record),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

typedef _EmptyCasesState = FormIVEmptyCasesState;

class FormIVEmptyCasesState extends StatelessWidget {
  const FormIVEmptyCasesState({
    super.key,
    required this.category,
    required this.readOnly,
    this.statusTab = FormIVStatusTab.total,
    this.onNewCase,
    this.selectedDateRange,
    this.onClearDateFilter,
  });

  final String category;
  final bool readOnly;
  final FormIVStatusTab statusTab;
  final VoidCallback? onNewCase;
  final DateTimeRange? selectedDateRange;
  final VoidCallback? onClearDateFilter;

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

    final hasDateFilter = selectedDateRange != null;
    final titleText = hasDateFilter
        ? (isAll
            ? TranslationHelper.translate(
                context,
                'No Form I-V cases in selected date range',
              )
            : '${TranslationHelper.translate(context, 'No')} $statusLabel$transCategory ${TranslationHelper.translate(context, 'cases in date range')}')
        : (isAll
            ? (statusTab == FormIVStatusTab.total
                ? TranslationHelper.translate(
                    context,
                    'No Form I-V cases yet',
                  )
                : '${TranslationHelper.translate(context, 'No')} $statusLabel${TranslationHelper.translate(context, 'Form I-V cases yet')}')
            : '${TranslationHelper.translate(context, 'No')} $statusLabel$transCategory ${TranslationHelper.translate(context, 'cases yet')}');

    final descText = hasDateFilter
        ? TranslationHelper.translate(
            context,
            'Try clearing or expanding the date filter to see more cases.',
          )
        : (readOnly
            ? TranslationHelper.translate(
                context,
                'Cases will appear here once registered.',
              )
            : TranslationHelper.translate(
                context,
                'Tap New Case to register the first case.',
              ));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasDateFilter
                  ? Icons.event_busy_rounded
                  : Icons.folder_open_rounded,
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
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (hasDateFilter && onClearDateFilter != null)
                  OutlinedButton.icon(
                    onPressed: onClearDateFilter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
                      side: const BorderSide(color: Color(0xFF1976D2)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      TranslationHelper.translate(context, 'Clear Date Filter'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (onNewCase != null)
                  FilledButton.icon(
                    onPressed: onNewCase,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navyMid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      TranslationHelper.translate(context, 'New Case'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
