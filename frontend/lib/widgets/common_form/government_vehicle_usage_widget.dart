// lib/widgets/common_form/government_vehicle_usage_widget.dart
import 'package:flutter/material.dart';

/// Shared, reusable component for logging Government Vehicle Usage during investigation / panchnama.
/// Applicable across all crime tabs.
class GovernmentVehicleUsageData {
  String? sdEntry; // 'yes' | 'no' | null
  String? logBookEntry; // 'yes' | 'no' | null
  String? caseDiaryEntry; // 'yes' | 'no' | null

  GovernmentVehicleUsageData({
    this.sdEntry,
    this.logBookEntry,
    this.caseDiaryEntry,
  });

  Map<String, dynamic> toMap() => {
        'sdEntry': sdEntry,
        'logBookEntry': logBookEntry,
        'caseDiaryEntry': caseDiaryEntry,
      };

  factory GovernmentVehicleUsageData.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return GovernmentVehicleUsageData();
    return GovernmentVehicleUsageData(
      sdEntry: map['sdEntry']?.toString(),
      logBookEntry: map['logBookEntry']?.toString(),
      caseDiaryEntry: map['caseDiaryEntry']?.toString(),
    );
  }

  GovernmentVehicleUsageData copy() {
    return GovernmentVehicleUsageData(
      sdEntry: sdEntry,
      logBookEntry: logBookEntry,
      caseDiaryEntry: caseDiaryEntry,
    );
  }

  void clear() {
    sdEntry = null;
    logBookEntry = null;
    caseDiaryEntry = null;
  }
}

class GovernmentVehicleUsageWidget extends StatefulWidget {
  final GovernmentVehicleUsageData? data;
  final ValueChanged<GovernmentVehicleUsageData>? onChanged;
  final bool compact;

  const GovernmentVehicleUsageWidget({
    super.key,
    this.data,
    this.onChanged,
    this.compact = false,
  });

  @override
  State<GovernmentVehicleUsageWidget> createState() =>
      _GovernmentVehicleUsageWidgetState();
}

class _GovernmentVehicleUsageWidgetState
    extends State<GovernmentVehicleUsageWidget> {
  static const Color _kDark = Color(0xFF0F172A);
  static const Color _kGreen = Color(0xFF10B981);
  static const Color _kRed = Color(0xFFEF4444);
  static const Color _kSec = Color(0xFF64748B);
  static const Color _kInputBg = Color(0xFFF8FAFC);
  static const Color _kBorder = Color(0xFFE2E8F0);

  late final GovernmentVehicleUsageData _fallbackData =
      GovernmentVehicleUsageData();

  GovernmentVehicleUsageData get _effectiveData => widget.data ?? _fallbackData;

  Widget _yesNoChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : _kInputBg,
          border: Border.all(
            color: selected ? color : _kBorder,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? color : _kSec,
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String title,
    required String? value,
    required ValueChanged<String?> onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
          ),
          _yesNoChip('Yes', value == 'yes', _kGreen, () {
            onSelect('yes');
          }),
          const SizedBox(width: 8),
          _yesNoChip('No', value == 'no', _kRed, () {
            onSelect('no');
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Icon(Icons.directions_car_filled_outlined,
                  size: 16, color: Color(0xFF0EA5E9)),
              SizedBox(width: 6),
              Text(
                'GOVERNMENT VEHICLE USAGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildRow(
          title: 'SD Entry of Vehicle Number and Time',
          value: _effectiveData.sdEntry,
          onSelect: (v) {
            final d = _effectiveData;
            setState(() => d.sdEntry = v);
            widget.onChanged?.call(d);
          },
        ),
        _buildRow(
          title: 'Log Book of Vehicle Entry',
          value: _effectiveData.logBookEntry,
          onSelect: (v) {
            final d = _effectiveData;
            setState(() => d.logBookEntry = v);
            widget.onChanged?.call(d);
          },
        ),
        _buildRow(
          title: 'Case Diary Vehicle Entry',
          value: _effectiveData.caseDiaryEntry,
          onSelect: (v) {
            final d = _effectiveData;
            setState(() => d.caseDiaryEntry = v);
            widget.onChanged?.call(d);
          },
        ),
      ],
    );
  }
}
