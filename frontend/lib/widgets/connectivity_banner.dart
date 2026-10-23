// lib/widgets/connectivity_banner.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';
import '../theme/app_theme.dart';

/// Clean, theme-consistent alert dialog alerting user when offline with a Retry button.
class OfflineWarningDialog extends StatelessWidget {
  const OfflineWarningDialog({super.key});

  /// Convenient helper to display the offline modal popup (disabled)
  static Future<void> show(BuildContext context) {
    return Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();
    final isChecking = connectivity.isChecking;
    final isConnected = connectivity.isConnected;

    // If connection restores automatically while dialog is open, dismiss it
    if (isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.dangerRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No Internet Connection',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navyDark,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'You are currently offline. Please check your internet connection.',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF475569),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text(
            'OK',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: isChecking
              ? null
              : () async {
                  final online = await connectivity.checkConnection();
                  if (online && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyDark,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isChecking
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Retry',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Global Application Wrapper that monitors network status and alerts
/// the user with [OfflineWarningDialog] whenever internet connection is lost.
class ConnectivityBannerWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? child;
  const ConnectivityBannerWrapper({
    super.key,
    this.navigatorKey,
    this.child,
  });

  @override
  State<ConnectivityBannerWrapper> createState() =>
      _ConnectivityBannerWrapperState();
}

class _ConnectivityBannerWrapperState extends State<ConnectivityBannerWrapper> {
  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
