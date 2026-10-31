import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

/// Asks for a date range with one-tap presets plus From/To pickers.
/// Opens as a bottom sheet on phones and a centred dialog on wider screens.
/// Returns null when the user cancels.
Future<DateTimeRange?> showDateRangeSheet(
  BuildContext context, {
  String title = 'Custom date range',
  String subtitle = 'See pending cases registered between two dates',
  String confirmLabel = 'Show cases',
}) {
  final panel = _DateRangePanel(
    title: title,
    subtitle: subtitle,
    confirmLabel: confirmLabel,
  );
  if (MediaQuery.of(context).size.width < Breakpoints.mobile) {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => panel,
    );
  }
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: panel,
      ),
    ),
  );
}

class _Preset {
  final String label;
  final DateTimeRange Function(DateTime today) range;
  const _Preset(this.label, this.range);
}

final _presets = <_Preset>[
  _Preset('Today', (t) => DateTimeRange(start: t, end: t)),
  _Preset(
    'Yesterday',
    (t) {
      final y = t.subtract(const Duration(days: 1));
      return DateTimeRange(start: y, end: y);
    },
  ),
  _Preset(
    'Last 7 days',
    (t) => DateTimeRange(start: t.subtract(const Duration(days: 6)), end: t),
  ),
  _Preset(
    'Last 30 days',
    (t) => DateTimeRange(start: t.subtract(const Duration(days: 29)), end: t),
  ),
  _Preset(
    'This month',
    (t) => DateTimeRange(start: DateTime(t.year, t.month), end: t),
  ),
  _Preset(
    'Last month',
    (t) => DateTimeRange(
      start: DateTime(t.year, t.month - 1),
      end: DateTime(t.year, t.month, 0),
    ),
  ),
  _Preset(
    'Last 3 months',
    (t) => DateTimeRange(start: DateTime(t.year, t.month - 3, t.day), end: t),
  ),
  _Preset(
    'This year',
    (t) => DateTimeRange(start: DateTime(t.year), end: t),
  ),
];

class _DateRangePanel extends StatefulWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;

  const _DateRangePanel({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
  });

  @override
  State<_DateRangePanel> createState() => _DateRangePanelState();
}

class _DateRangePanelState extends State<_DateRangePanel> {
  static final _firstDate = DateTime(2000);
  late final DateTime _today;
  late DateTime _start;
  late DateTime _end;
  String? _activePreset = 'Last 30 days';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final initial =
        _presets.firstWhere((p) => p.label == _activePreset).range(_today);
    _start = initial.start;
    _end = initial.end;
  }

  int get _days => _end.difference(_start).inDays + 1;

  void _applyPreset(_Preset preset) {
    final r = preset.range(_today);
    setState(() {
      _start = r.start;
      _end = r.end;
      _activePreset = preset.label;
    });
  }

  Future<void> _pick({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: _firstDate,
      lastDate: _today,
      helpText: isStart ? 'Select start date' : 'Select end date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.navyMid,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _activePreset = null;
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
        if (_start.isAfter(_end)) _start = _end;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSheet = MediaQuery.of(context).size.width < Breakpoints.mobile;
    final radius = isSheet
        ? const BorderRadius.vertical(top: Radius.circular(24))
        : BorderRadius.circular(20);

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isSheet)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 20),
              _sectionLabel('Quick select'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final p in _presets) _presetChip(p)],
              ),
              const SizedBox(height: 20),
              _sectionLabel('Or choose dates'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateBox(
                      label: 'From',
                      date: _start,
                      onTap: () => _pick(isStart: true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.lightSubText,
                    ),
                  ),
                  Expanded(
                    child: _dateBox(
                      label: 'To',
                      date: _end,
                      onTap: () => _pick(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSummary(),
              const SizedBox(height: 20),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navyMid, AppColors.navyAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.date_range_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              Text(
                widget.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.lightSubText,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: AppColors.lightSubText),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.lightSubText,
      ),
    );
  }

  Widget _presetChip(_Preset preset) {
    final selected = _activePreset == preset.label;
    return Material(
      color: selected ? AppColors.navyMid : AppColors.lightBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _applyPreset(preset),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.navyMid
                  : AppColors.navyMid.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            preset.label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.navyMid,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateBox({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.navyMid.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_rounded,
                size: 18,
                color: AppColors.navyMid,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.lightSubText,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
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

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.goldDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_days ${_days == 1 ? 'day' : 'days'} selected',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navyMid,
              side: BorderSide(color: AppColors.navyMid.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop(context, DateTimeRange(start: _start, end: _end)),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Text(
              widget.confirmLabel,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
