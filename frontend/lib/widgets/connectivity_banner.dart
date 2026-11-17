import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';
import 'app_error_popup.dart';

/// Clean, theme-consistent alert dialog alerting user when offline with a Retry button.
class OfflineWarningDialog extends StatelessWidget {
  const OfflineWarningDialog({super.key});

  /// Convenient helper to display the offline modal popup
  static Future<void> show(BuildContext context,
      {Future<void> Function()? onRetry}) {
    return AppErrorPopup.showNetworkError(context, onRetry: onRetry);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Global Application Wrapper that monitors network status and alerts
/// the user with [AppErrorPopup] whenever internet connection is lost.
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
  bool _hasShownOfflinePopup = false;
  bool _wasOffline = false;
  bool _showRestoredBanner = false;
  Timer? _restoredTimer;

  @override
  void dispose() {
    _restoredTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ConnectivityProvider? connectivity;
    try {
      connectivity = context.watch<ConnectivityProvider>();
    } catch (_) {
      // Graceful fallback for widget tests where ConnectivityProvider is not mocked
    }

    if (connectivity == null) {
      return widget.child ?? const SizedBox.shrink();
    }

    final isOffline = !connectivity.isConnected;

    if (isOffline && !_hasShownOfflinePopup) {
      _hasShownOfflinePopup = true;
      _wasOffline = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetContext = widget.navigatorKey?.currentContext ?? context;
        AppErrorPopup.showNetworkError(
          targetContext,
          onRetry: () async {
            await connectivity?.checkConnection();
          },
        );
      });
    } else if (!isOffline && _wasOffline) {
      _hasShownOfflinePopup = false;
      _wasOffline = false;
      _showRestoredBanner = true;
      _restoredTimer?.cancel();
      _restoredTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showRestoredBanner = false);
        }
      });
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child ?? const SizedBox.shrink(),
          if (_showRestoredBanner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                color: const Color(0xFF16A34A),
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connection restored. Back online.',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
