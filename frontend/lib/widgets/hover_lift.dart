import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows that a card is clickable: on mouse hover it lifts slightly, gains a
/// navy shadow and outline, and the cursor turns into a pointer. Has no effect
/// on touch screens, where the card's own tap ripple gives the feedback.
class HoverLift extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  /// Outline drawn while hovered; null draws none (e.g. on dark cards).
  final Color? hoverBorderColor;

  const HoverLift({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.hoverBorderColor = AppColors.navyMid,
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hoverBorderColor;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        foregroundDecoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: _hovered && borderColor != null
              ? Border.all(
                  color: borderColor.withValues(alpha: 0.55), width: 1.4)
              : null,
        ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.navyMid.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
