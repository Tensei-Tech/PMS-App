// lib/widgets/common_form/section_82_83_action_widget.dart
import 'package:flutter/material.dart';

/// Shared, reusable component for Section 82/83 Action query:
/// "If the accused is not traceable, has action under Section 82/83 been initiated?" (Y/N)
/// Applicable across all crime tabs where accused-tracking is recorded.
class Section8283ActionWidget extends StatefulWidget {
  final String? value; // 'yes' | 'no' | null
  final ValueChanged<String?>? onChanged;

  const Section8283ActionWidget({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  State<Section8283ActionWidget> createState() =>
      _Section8283ActionWidgetState();
}

class _Section8283ActionWidgetState extends State<Section8283ActionWidget> {
  static const Color _kDark = Color(0xFF0F172A);
  static const Color _kGreen = Color(0xFF10B981);
  static const Color _kRed = Color(0xFFEF4444);
  static const Color _kSec = Color(0xFF64748B);
  static const Color _kInputBg = Color(0xFFF8FAFC);
  static const Color _kBorder = Color(0xFFE2E8F0);

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

  @override
  Widget build(BuildContext context) {
    final val = widget.value;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              'If the accused is not traceable, has action under Section 82/83 been initiated?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _yesNoChip('Yes', val == 'yes', _kGreen, () {
            widget.onChanged?.call('yes');
          }),
          const SizedBox(width: 8),
          _yesNoChip('No', val == 'no', _kRed, () {
            widget.onChanged?.call('no');
          }),
        ],
      ),
    );
  }
}
