import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';

/// Reusable success popup that automatically closes after a few seconds
/// and matches the application's police theme.
class AppSuccessPopup extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Duration autoCloseDuration;
  final VoidCallback? onDismiss;

  const AppSuccessPopup({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.check_circle_rounded,
    this.iconColor,
    this.iconBgColor,
    this.autoCloseDuration = const Duration(milliseconds: 2500),
    this.onDismiss,
  });

  /// Displays the success popup responsively (bottom sheet on mobile, dialog on desktop)
  /// and automatically dismisses it after [autoCloseDuration].
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Color? iconColor,
    Color? iconBgColor,
    Duration autoCloseDuration = const Duration(milliseconds: 2500),
    VoidCallback? onDismiss,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => AppSuccessPopup(
          title: title,
          message: message,
          icon: icon,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
          autoCloseDuration: autoCloseDuration,
          onDismiss: onDismiss,
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: AppSuccessPopup(
                title: title,
                message: message,
                icon: icon,
                iconColor: iconColor,
                iconBgColor: iconBgColor,
                autoCloseDuration: autoCloseDuration,
                onDismiss: onDismiss,
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  State<AppSuccessPopup> createState() => _AppSuccessPopupState();
}

class _AppSuccessPopupState extends State<AppSuccessPopup> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _autoCloseTimer = Timer(widget.autoCloseDuration, () {
      if (mounted) {
        _handleDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _handleDismiss() {
    _autoCloseTimer?.cancel();
    widget.onDismiss?.call();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final primaryColor = widget.iconColor ?? const Color(0xFF2E7D32);
    final bgColor = widget.iconBgColor ?? const Color(0xFFE8F5E9);

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...[
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: _handleDismiss,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.lightSubText,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 16,
                tooltip: TranslationHelper.translate(context, 'Close'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.navyDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

    return content;
  }
}
