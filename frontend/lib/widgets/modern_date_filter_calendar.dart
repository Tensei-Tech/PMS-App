import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khakhi_diary/theme/app_theme.dart';
import 'package:khakhi_diary/utils/translation_helper.dart';

/// Available date selection modes for the modern date filter.
enum ModernDateFilterMode {
  today,
  range,
  custom,
}

/// A streamlined, modern calendar filter widget inspired by modern web and mobile popovers.
/// Features:
/// 1. Compact trigger button displaying current active date filter.
/// 2. Anchored popover (desktop/tablet) and modal sheet (mobile).
/// 3. Exactly 3 streamlined options: Today, Range (week, month, etc.), and Custom date picker.
/// 4. Trash/clear icon to reset filters.
/// 5. Full inline interactive month calendar with rich range highlighting.
/// 6. Optional companion sort order (Newest / Oldest).
class ModernDateFilterCalendar extends StatefulWidget {
  final DateTimeRange? selectedDateRange;
  final String? datePresetLabel;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final ValueChanged<String?>? onPresetLabelChanged;

  // Optional Sort Order companion
  final bool? isNewestFirst;
  final ValueChanged<bool>? onSortOrderChanged;
  final bool showSortCompanion;

  // Button styling
  final double height;
  final double fontSize;
  final String? customEmptyLabel;

  /// Optional dates that have cases filed, shown as a subtle dot under the day.
  final Set<DateTime>? activeDates;

  const ModernDateFilterCalendar({
    super.key,
    required this.selectedDateRange,
    this.datePresetLabel,
    required this.onDateRangeChanged,
    this.onPresetLabelChanged,
    this.isNewestFirst,
    this.onSortOrderChanged,
    this.showSortCompanion = false,
    this.height = 38.0,
    this.fontSize = 12.0,
    this.customEmptyLabel,
    this.activeDates,
  });

  @override
  State<ModernDateFilterCalendar> createState() =>
      _ModernDateFilterCalendarState();
}

class _ModernDateFilterCalendarState extends State<ModernDateFilterCalendar> {
  final GlobalKey _buttonKey = GlobalKey();

  String _formatRangeShort(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return DateFormat('dd MMM yyyy').format(start);
    }
    if (start.year == end.year) {
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
    }
    return '${DateFormat('dd MMM yy').format(start)} - ${DateFormat('dd MMM yy').format(end)}';
  }

  String get _displayButtonText {
    if (widget.datePresetLabel != null && widget.datePresetLabel!.isNotEmpty) {
      return 'Date: ${widget.datePresetLabel}';
    }
    if (widget.selectedDateRange != null) {
      return 'Date: ${_formatRangeShort(widget.selectedDateRange!)}';
    }
    return widget.customEmptyLabel ??
        TranslationHelper.translate(context, 'Date Filter');
  }

  void _openPopover() {
    final screenSize = MediaQuery.of(context).size;
    final isNarrow = screenSize.width < 600;

    if (isNarrow) {
      // Mobile / narrow screen: render as modal bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ModernCalendarPopoverCard(
          initialRange: widget.selectedDateRange,
          initialPresetLabel: widget.datePresetLabel,
          activeDates: widget.activeDates,
          onApply: (range, preset) {
            widget.onDateRangeChanged(range);
            widget.onPresetLabelChanged?.call(preset);
          },
          onClose: () => Navigator.of(ctx).pop(),
          isDialog: false,
        ),
      );
    } else {
      // Desktop / tablet: render anchored popover tethered to the button
      final renderBox =
          _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final buttonPos = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
      final buttonSize = renderBox?.size ?? Size(120, widget.height);

      const popoverWidth = 340.0;
      const estimatedPopoverHeight = 440.0;

      // Calculate horizontal alignment (anchor to button)
      double left = buttonPos.dx;
      if (left + popoverWidth > screenSize.width - 16) {
        left = (buttonPos.dx + buttonSize.width) - popoverWidth;
      }
      left =
          math.max(16.0, math.min(left, screenSize.width - popoverWidth - 16));

      // Calculate vertical alignment with flip-block fallback
      double top = buttonPos.dy + buttonSize.height + 6;
      if (top + estimatedPopoverHeight > screenSize.height - 16) {
        top = buttonPos.dy - estimatedPopoverHeight - 6;
        if (top < 16) {
          top = 16;
        }
      }

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'DateFilterPopover',
        barrierColor: Colors.black.withValues(alpha: 0.15),
        transitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (dialogCtx, anim1, anim2) {
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: Material(
                  color: Colors.transparent,
                  child: _ModernCalendarPopoverCard(
                    initialRange: widget.selectedDateRange,
                    initialPresetLabel: widget.datePresetLabel,
                    activeDates: widget.activeDates,
                    onApply: (range, preset) {
                      widget.onDateRangeChanged(range);
                      widget.onPresetLabelChanged?.call(preset);
                    },
                    onClose: () => Navigator.of(dialogCtx).pop(),
                    isDialog: true,
                  ),
                ),
              ),
            ],
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            child: child,
          );
        },
      );
    }
  }

  void _clearFilter() {
    widget.onDateRangeChanged(null);
    widget.onPresetLabelChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = widget.selectedDateRange != null;

    final triggerBtn = InkWell(
      key: _buttonKey,
      onTap: _openPopover,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: widget.height,
        padding: EdgeInsets.fromLTRB(
          isFiltered ? 8 : 10,
          0,
          isFiltered ? 6 : 10,
          0,
        ),
        decoration: BoxDecoration(
          color: isFiltered ? const Color(0xFFE8F1FC) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isFiltered ? const Color(0xFF1976D2) : const Color(0xFFCBD5E1),
            width: isFiltered ? 1.3 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isFiltered
                  ? const Color(0xFF1976D2).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 15,
              color: isFiltered ? const Color(0xFF1976D2) : AppColors.navyMid,
            ),
            const SizedBox(width: 6),
            Text(
              _displayButtonText,
              style: GoogleFonts.poppins(
                fontSize: widget.fontSize,
                fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                color:
                    isFiltered ? const Color(0xFF1976D2) : AppColors.navyDark,
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(width: 4),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _clearFilter,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!widget.showSortCompanion || widget.onSortOrderChanged == null) {
      return triggerBtn;
    }

    // Companion Sort Button (Newest First / Oldest First)
    final isNewest = widget.isNewestFirst ?? true;
    final sortBtn = InkWell(
      onTap: () => widget.onSortOrderChanged?.call(!isNewest),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: widget.height,
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
              isNewest
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 14,
              color: AppColors.navyMid,
            ),
            const SizedBox(width: 4),
            Text(
              isNewest
                  ? TranslationHelper.translate(context, 'Newest')
                  : TranslationHelper.translate(context, 'Oldest'),
              style: GoogleFonts.poppins(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        triggerBtn,
        const SizedBox(width: 8),
        sortBtn,
      ],
    );
  }
}

/// The internal Popover Card with:
/// - Streamlined 3-Option Segment Bar: [ Today | Range | Custom ] and Trash icon
/// - Sub-chips for Range mode: [ Under 1 month | 1 to 3 months | 3 to 6 months | 6 to 12 months | More than 1 year | Under 3 months (Total) ]
/// - Full interactive Month Calendar with distinct connected range ribbon
/// - Footer status summary & Done button
class _ModernCalendarPopoverCard extends StatefulWidget {
  final DateTimeRange? initialRange;
  final String? initialPresetLabel;
  final Set<DateTime>? activeDates;
  final void Function(DateTimeRange? range, String? preset) onApply;
  final VoidCallback onClose;
  final bool isDialog;

  const _ModernCalendarPopoverCard({
    required this.initialRange,
    required this.initialPresetLabel,
    this.activeDates,
    required this.onApply,
    required this.onClose,
    required this.isDialog,
  });

  @override
  State<_ModernCalendarPopoverCard> createState() =>
      _ModernCalendarPopoverCardState();
}

class _ModernCalendarPopoverCardState
    extends State<_ModernCalendarPopoverCard> {
  ModernDateFilterMode? _mode;
  late DateTime _viewMonth;
  DateTimeRange? _selectedRange;
  String? _presetLabel;

  // Custom range selection state
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isSelectingSecondDate = false;
  late Set<DateTime> _activeDates;

  static Set<DateTime> _normalizeDates(Set<DateTime>? dates) {
    if (dates == null || dates.isEmpty) return const {};
    return {for (final d in dates) DateTime(d.year, d.month, d.day)};
  }

  @override
  void initState() {
    super.initState();
    _activeDates = _normalizeDates(widget.activeDates);
    _selectedRange = widget.initialRange;
    _presetLabel = widget.initialPresetLabel;

    if (_presetLabel == 'Today') {
      _mode = ModernDateFilterMode.today;
    } else if (_presetLabel != null && _presetLabel!.isNotEmpty) {
      _mode = ModernDateFilterMode.range;
    } else if (_selectedRange != null) {
      _mode = ModernDateFilterMode.custom;
    } else {
      _mode = null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedRange?.end ?? today;
    final clampedInitial = initialDate.isAfter(today) ? today : initialDate;
    _viewMonth = DateTime(clampedInitial.year, clampedInitial.month, 1);

    if (_selectedRange != null) {
      _rangeStart = DateTime(
        _selectedRange!.start.year,
        _selectedRange!.start.month,
        _selectedRange!.start.day,
      );
      _rangeEnd = DateTime(
        _selectedRange!.end.year,
        _selectedRange!.end.month,
        _selectedRange!.end.day,
      );
    }
  }

  void _applyToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _mode = ModernDateFilterMode.today;
      _isSelectingSecondDate = false;
      _rangeStart = today;
      _rangeEnd = today;
      _selectedRange = DateTimeRange(start: today, end: today);
      _presetLabel = 'Today';
      _viewMonth = DateTime(today.year, today.month, 1);
    });
    widget.onApply(_selectedRange, _presetLabel);
  }

  static const List<String> _rangePresets = [
    'Under 1 month',
    '1 to 3 months',
    '3 to 6 months',
    '6 to 12 months',
    'More than 1 year',
    'Under 3 months (Total)',
  ];

  void _applyRangePreset(String label) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end = today;

    switch (label) {
      case 'Under 1 month':
        start = today.subtract(const Duration(days: 30));
        break;
      case '1 to 3 months':
        start = today.subtract(const Duration(days: 90));
        end = today.subtract(const Duration(days: 30));
        break;
      case '3 to 6 months':
        start = today.subtract(const Duration(days: 180));
        end = today.subtract(const Duration(days: 90));
        break;
      case '6 to 12 months':
        start = today.subtract(const Duration(days: 365));
        end = today.subtract(const Duration(days: 180));
        break;
      case 'More than 1 year':
        start = DateTime(2000, 1, 1);
        end = today.subtract(const Duration(days: 365));
        break;
      case 'Under 3 months (Total)':
        start = today.subtract(const Duration(days: 90));
        break;
      default:
        start = today.subtract(const Duration(days: 30));
    }

    setState(() {
      _mode = ModernDateFilterMode.range;
      _isSelectingSecondDate = false;
      _presetLabel = label;
      _rangeStart = start;
      _rangeEnd = end;
      _selectedRange = DateTimeRange(start: start, end: end);
      _viewMonth = DateTime(end.year, end.month, 1);
    });
    widget.onApply(_selectedRange, _presetLabel);
  }

  void _clearFilter() {
    setState(() {
      _mode = null;
      _isSelectingSecondDate = false;
      _selectedRange = null;
      _presetLabel = null;
      _rangeStart = null;
      _rangeEnd = null;
    });
    widget.onApply(null, null);
  }

  void _onDayTapped(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDay = DateTime(day.year, day.month, day.day);

    // Prevent selecting future dates
    if (normalizedDay.isAfter(today)) {
      return;
    }

    setState(() {
      _mode = ModernDateFilterMode.custom;
      _presetLabel = null;

      if (!_isSelectingSecondDate || _rangeStart == null) {
        // First tap: instantly select this single day
        _rangeStart = normalizedDay;
        _rangeEnd = normalizedDay;
        _selectedRange =
            DateTimeRange(start: normalizedDay, end: normalizedDay);
        _isSelectingSecondDate = true;
      } else {
        // Second tap: expand or reverse range
        if (normalizedDay.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = normalizedDay;
        } else {
          _rangeEnd = normalizedDay;
        }
        _selectedRange = DateTimeRange(start: _rangeStart!, end: _rangeEnd!);
        _isSelectingSecondDate = false;
      }
    });

    widget.onApply(_selectedRange, null);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    // Prevent navigating to future months
    if (!_viewMonth.isBefore(currentMonth)) {
      return;
    }
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        widget.isDialog ? 340.0 : math.min(screenWidth - 24, 380.0);

    final card = Container(
      width: cardWidth,
      margin: widget.isDialog ? EdgeInsets.zero : const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Streamlined Top Bar: 3-Segment Selector [Today | Range | Custom] + Trash Icon ──
          _buildSegmentedBar(),
          const SizedBox(height: 10),

          // ── Sub-row for Range mode (4 equal-width chips) ──
          if (_mode == ModernDateFilterMode.range) ...[
            _buildRangePresetChips(),
            const SizedBox(height: 10),
          ],

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // ── Inline Month Navigation Header ──
          _buildMonthHeader(),
          const SizedBox(height: 8),

          // ── Weekday Labels ──
          _buildWeekdayHeader(),
          const SizedBox(height: 4),

          // ── Calendar Days Grid ──
          _buildDaysGrid(),
          const SizedBox(height: 10),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // ── Footer: Status summary & Done action ──
          _buildFooterBar(),
        ],
      ),
    );

    if (widget.isDialog) {
      return card;
    }
    return SafeArea(top: false, child: card);
  }

  Widget _buildSegmentedBar() {
    final hasFilter = _selectedRange != null;

    return Row(
      children: [
        // Modern 3-Segment Pill Selector
        Expanded(
          child: Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildSegmentItem('Today', ModernDateFilterMode.today),
                _buildSegmentItem('Range', ModernDateFilterMode.range),
                _buildSegmentItem('Custom', ModernDateFilterMode.custom),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Clear Filter Button
        Tooltip(
          message: 'Clear date filter',
          child: MouseRegion(
            cursor:
                hasFilter ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasFilter ? _clearFilter : null,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 36,
                  width: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasFilter
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasFilter
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: hasFilter
                        ? AppColors.navyDark
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentItem(String title, ModernDateFilterMode mode) {
    final isSelected = _mode == mode;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (mode == ModernDateFilterMode.today) {
              _applyToday();
            } else if (mode == ModernDateFilterMode.range) {
              final preset = _rangePresets.contains(_presetLabel)
                  ? _presetLabel!
                  : _rangePresets.first;
              _applyRangePreset(preset);
            } else {
              setState(() {
                _mode = ModernDateFilterMode.custom;
                _isSelectingSecondDate = false;
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1976D2)
                    : AppColors.lightSubText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangePresetChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _rangePresets.map((label) {
        final isSelected = _presetLabel == label;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => _applyRangePreset(label),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1976D2)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1976D2)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.navyDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthHeader() {
    final monthStr = DateFormat('MMMM yyyy').format(_viewMonth);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final canGoNext = _viewMonth.isBefore(currentMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          monthStr,
          style: GoogleFonts.poppins(
            fontSize: 14.0,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: _prevMonth,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: AppColors.navyMid,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: canGoNext ? _nextMonth : null,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color:
                      canGoNext ? AppColors.navyMid : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Row(
      children: weekdays.map((w) {
        return Expanded(
          child: Center(
            child: Text(
              w,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.lightSubText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_viewMonth.year, _viewMonth.month, 1)
        .weekday; // 1 = Mon, 7 = Sun
    final leadingDays = firstWeekday - 1;

    final prevMonthDays = DateTime(_viewMonth.year, _viewMonth.month, 0).day;

    final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dayWidgets = <Widget>[];

    for (int i = 0; i < totalCells; i++) {
      if (i < leadingDays) {
        // Day from previous month
        final d = prevMonthDays - leadingDays + 1 + i;
        dayWidgets.add(
          Center(
            child: Text(
              '$d',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),
        );
      } else if (i < leadingDays + daysInMonth) {
        // Day of current month
        final d = i - leadingDays + 1;
        final cellDate = DateTime(_viewMonth.year, _viewMonth.month, d);
        final isToday = cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;
        final isFuture = cellDate.isAfter(today);

        dayWidgets.add(_buildDayCell(cellDate, isToday, isFuture));
      } else {
        // Day from next month
        final d = i - (leadingDays + daysInMonth) + 1;
        dayWidgets.add(
          Center(
            child: Text(
              '$d',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),
        );
      }
    }

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 3,
      crossAxisSpacing: 0,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(DateTime date, bool isToday, bool isFuture) {
    if (isFuture) {
      return Center(
        child: Text(
          '${date.day}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFCBD5E1),
          ),
        ),
      );
    }

    bool isSelectedStart = false;
    bool isSelectedEnd = false;
    bool isInRange = false;

    if (_rangeStart != null && _rangeEnd != null) {
      isSelectedStart = date.year == _rangeStart!.year &&
          date.month == _rangeStart!.month &&
          date.day == _rangeStart!.day;
      isSelectedEnd = date.year == _rangeEnd!.year &&
          date.month == _rangeEnd!.month &&
          date.day == _rangeEnd!.day;
      isInRange = (date.isAfter(_rangeStart!) && date.isBefore(_rangeEnd!)) ||
          isSelectedStart ||
          isSelectedEnd;
    } else if (_rangeStart != null) {
      isSelectedStart = date.year == _rangeStart!.year &&
          date.month == _rangeStart!.month &&
          date.day == _rangeStart!.day;
    }

    final isSingleSelected = (isSelectedStart && isSelectedEnd) ||
        (isSelectedStart && _rangeEnd == null);

    final isRowStart = date.weekday == DateTime.monday;
    final isRowEnd = date.weekday == DateTime.sunday;

    BoxDecoration? containerDec;
    Color textColor = AppColors.navyDark;
    FontWeight fontWeight = FontWeight.w500;

    if (isSingleSelected) {
      containerDec = BoxDecoration(
        color: const Color(0xFF1976D2),
        borderRadius: BorderRadius.circular(8),
      );
      textColor = Colors.white;
      fontWeight = FontWeight.w700;
    } else if (isSelectedStart) {
      containerDec = BoxDecoration(
        color: const Color(0xFF1976D2),
        borderRadius: isRowEnd
            ? BorderRadius.circular(8)
            : const BorderRadius.horizontal(left: Radius.circular(8)),
      );
      textColor = Colors.white;
      fontWeight = FontWeight.w700;
    } else if (isSelectedEnd) {
      containerDec = BoxDecoration(
        color: const Color(0xFF1976D2),
        borderRadius: isRowStart
            ? BorderRadius.circular(8)
            : const BorderRadius.horizontal(right: Radius.circular(8)),
      );
      textColor = Colors.white;
      fontWeight = FontWeight.w700;
    } else if (isInRange) {
      // Clean visible soft blue ribbon with row-boundary rounding
      containerDec = BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: isRowStart && isRowEnd
            ? BorderRadius.circular(8)
            : isRowStart
                ? const BorderRadius.horizontal(left: Radius.circular(8))
                : isRowEnd
                    ? const BorderRadius.horizontal(right: Radius.circular(8))
                    : BorderRadius.zero,
      );
      textColor = const Color(0xFF1E40AF);
      fontWeight = FontWeight.w600;
    } else if (isToday) {
      containerDec = BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1976D2), width: 1.2),
      );
      textColor = const Color(0xFF1976D2);
      fontWeight = FontWeight.w700;
    }

    final hasCases = _activeDates.contains(date);
    final isStrongSelected =
        isSingleSelected || isSelectedStart || isSelectedEnd;

    return InkWell(
      onTap: () => _onDayTapped(date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: containerDec,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.05,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: hasCases
                  ? Center(
                      child: Container(
                        key: const Key('date-case-dot'),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isStrongSelected
                              ? Colors.white
                              : const Color(0xFF1976D2),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterBar() {
    String summaryText = 'All dates';
    if (_presetLabel != null && _presetLabel!.isNotEmpty) {
      summaryText = _presetLabel!;
    } else if (_selectedRange != null) {
      final start = _selectedRange!.start;
      final end = _selectedRange!.end;
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        summaryText = DateFormat('dd MMM yyyy').format(start);
      } else if (start.year == end.year) {
        summaryText =
            '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
      } else {
        summaryText =
            '${DateFormat('dd MMM yy').format(start)} - ${DateFormat('dd MMM yy').format(end)}';
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            summaryText,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: AppColors.navyMid,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: widget.onClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            'Done',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
