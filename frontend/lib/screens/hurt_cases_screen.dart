import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../modules/hurt/providers/hurt_provider.dart';
import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import '../widgets/module_hub_screen_app_bar.dart';
import 'common_form_screen.dart';
import 'form_i_v_selection_screen.dart';
import 'module_record_detail_screen.dart';

class HurtCasesScreen extends StatefulWidget {
  final bool readOnly;

  const HurtCasesScreen({super.key, this.readOnly = false});

  @override
  State<HurtCasesScreen> createState() => _HurtCasesScreenState();
}

class _HurtCasesScreenState extends State<HurtCasesScreen> {
  FormIVStatusTab _selectedStatusTab = FormIVStatusTab.total;

  // Date filtering & sorting state
  DateTimeRange? _selectedDateRange;
  String? _datePresetLabel;
  FormIVDateField _dateField = FormIVDateField.incidentDate;
  FormIVDateSortOrder _dateSortOrder = FormIVDateSortOrder.newestFirst;

  bool get _readOnly => widget.readOnly;
  bool get _showNewCaseFab => !_readOnly;

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

  List<ModuleRecord> _filteredAndSortedRecords(List<ModuleRecord> records) {
    final filtered = records.where(_recordMatchesDate).toList();
    filtered.sort((a, b) {
      final dateA = _recordTargetDate(a);
      final dateB = _recordTargetDate(b);
      return _dateSortOrder == FormIVDateSortOrder.newestFirst
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });
    return filtered;
  }

  void _openForm({ModuleRecord? existingRecord}) {
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: CommonFormScreen(
          moduleLabel: 'Hurt',
          moduleKey: 'hurt',
          subCategory: 'Hurt',
          existingRecord: existingRecord,
          readOnly: _readOnly && existingRecord != null,
        ),
      ),
    );
  }

  void _onNewCase() {
    _openForm();
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
    final provider = context.watch<HurtProvider>();
    final allRecords = provider.records;

    final totalCount = allRecords.length;
    final pendingCount = allRecords.where(_isPendingRecord).length;
    final disposalCount = allRecords.where(_isDisposalRecord).length;

    final statusRecords = _recordsForStatus(
      allRecords,
      _selectedStatusTab,
    );
    final visibleRecords = _filteredAndSortedRecords(statusRecords);

    final dateSuffix = _selectedDateRange != null
        ? ' · ${_datePresetLabel ?? _formatDateRangeShort(_selectedDateRange!)}'
        : '';

    final transCases = TranslationHelper.translate(context, 'cases');
    final subtitle = '${visibleRecords.length} $transCases$dateSuffix';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: TranslationHelper.translate(context, 'Hurt'),
        subtitle: subtitle,
        badgeLabel: TranslationHelper.translate(
          context,
          'hurt',
        ).toUpperCase(),
        onBackPressed: () => Navigator.pop(context),
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
          FormIVStatusTabBar(
            selectedTab: _selectedStatusTab,
            totalCount: totalCount,
            pendingCount: pendingCount,
            disposalCount: disposalCount,
            onTabChanged: (tab) {
              setState(() => _selectedStatusTab = tab);
            },
          ),
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
                const Icon(
                  Icons.healing_outlined,
                  size: 16,
                  color: AppColors.navyMid,
                ),
                const SizedBox(width: 8),
                Text(
                  TranslationHelper.translate(context, 'Hurt Cases'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
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
                    borderRadius: BorderRadius.circular(AppRadius.full),
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
                const Spacer(),
                _buildDateAndSortControls(),
              ],
            ),
          ),
          if (_selectedDateRange != null)
            _buildActiveDateFilterBanner(visibleRecords.length),
          Expanded(
            child: visibleRecords.isEmpty
                ? FormIVEmptyCasesState(
                    category: 'Hurt',
                    readOnly: _readOnly,
                    statusTab: _selectedStatusTab,
                    onNewCase: _showNewCaseFab ? _onNewCase : null,
                    selectedDateRange: _selectedDateRange,
                    onClearDateFilter: _clearDateFilter,
                  )
                : ListView.builder(
                    key: PageStorageKey(
                      'hurt_${_selectedStatusTab.name}',
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
                      return FormIVCaseCard(
                        record: record,
                        readOnly: _readOnly,
                        onEdit: () => _openForm(existingRecord: record),
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
      ),
    );
  }
}
