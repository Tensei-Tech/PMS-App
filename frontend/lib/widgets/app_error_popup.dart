import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';

/// Reusable, theme-consistent error and alert popup matching the app's design language.
///
/// Responsive behavior:
/// - Mobile (<600px): Smooth slide-up bottom sheet with top drag handle.
/// - Tablet/Desktop (>=600px): Centered modal dialog.
///
/// Dismiss behavior:
/// - Closeable via prominent top-right (X) button.
/// - Light dismiss via backdrop tap or platform Esc / back gesture.
class AppErrorPopup extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Future<void> Function()? onRetry;
  final String? retryLabel;
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  const AppErrorPopup({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.iconColor,
    this.onRetry,
    this.retryLabel,
    this.dismissLabel,
    this.onDismiss,
  });

  /// Displays the error popup responsively (bottom sheet on mobile, dialog on desktop).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.error_outline_rounded,
    Color? iconColor,
    Future<void> Function()? onRetry,
    String? retryLabel,
    String? dismissLabel,
    VoidCallback? onDismiss,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (_) => AppErrorPopup(
          title: title,
          message: message,
          icon: icon,
          iconColor: iconColor,
          onRetry: onRetry,
          retryLabel: retryLabel,
          dismissLabel: dismissLabel,
          onDismiss: onDismiss,
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (_) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Material(
              color: Colors.transparent,
              child: AppErrorPopup(
                title: title,
                message: message,
                icon: icon,
                iconColor: iconColor,
                onRetry: onRetry,
                retryLabel: retryLabel,
                dismissLabel: dismissLabel,
                onDismiss: onDismiss,
              ),
            ),
          ),
        ),
      );
    }
  }

  /// Convenience shortcut for network connection errors.
  static Future<T?> showNetworkError<T>(
    BuildContext context, {
    Future<void> Function()? onRetry,
    VoidCallback? onDismiss,
  }) {
    return show<T>(
      context,
      title: TranslationHelper.translate(context, 'No Internet Connection'),
      message: TranslationHelper.translate(
        context,
        'Unable to connect to the server. Please verify your data or Wi-Fi connection and try again.',
      ),
      icon: Icons.wifi_off_rounded,
      iconColor: AppColors.dangerRed,
      retryLabel: TranslationHelper.translate(context, 'Retry'),
      dismissLabel: TranslationHelper.translate(context, 'Dismiss'),
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  @override
  State<AppErrorPopup> createState() => _AppErrorPopupState();
}

class _AppErrorPopupState extends State<AppErrorPopup> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (widget.onRetry == null || _isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry!();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      // Keep popup open so user can retry again
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  void _handleDismiss() {
    widget.onDismiss?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final primaryColor = widget.iconColor ?? AppColors.dangerRed;

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle for bottom sheet
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

          // Header row with Icon, Title, and Close (X) button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: _handleDismiss,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.lightSubText,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
                tooltip: TranslationHelper.translate(context, 'Close'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Message Body
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.lightSubText,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _handleDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightSubText,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.dismissLabel ??
                      TranslationHelper.translate(context, 'Dismiss'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightSubText,
                  ),
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isRetrying ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.retryLabel ??
                              TranslationHelper.translate(context, 'Retry'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return content;
  }
}
