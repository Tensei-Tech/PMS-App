// lib/utils/pdf_loading_helper.dart
// Lightweight KISS helper for PDF loading states & UI freeze prevention.

import 'package:flutter/material.dart';

/// Global key to show SnackBars even when BuildContext is unavailable or unmounted.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class PdfLoadingHelper {
  PdfLoadingHelper._();

  /// Runs an asynchronous PDF generation [action] while displaying a clean,
  /// theme-consistent modal loading indicator or floating SnackBar, and yields
  /// to the UI event loop so Flutter has time to paint before CPU-heavy PDF layout begins.
  static Future<T> runWithLoading<T>({
    BuildContext? context,
    required Future<T> Function() action,
    String loadingMessage = 'Generating PDF, please wait...',
    String successMessage = 'PDF ready!',
  }) async {
    final messenger = (context != null && context.mounted
            ? ScaffoldMessenger.maybeOf(context)
            : null) ??
        rootScaffoldMessengerKey.currentState;

    bool dialogShown = false;
    BuildContext? dialogContext;

    if (context != null && context.mounted) {
      dialogShown = true;
      // Show clean, non-intrusive modal loading dialog
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        builder: (ctx) {
          dialogContext = ctx;
          return PopScope(
            canPop: false,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        loadingMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 25),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loadingMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Yield to the event loop so the Flutter engine can paint the frame with
    // the active modal dialog or SnackBar before CPU-heavy PDF layout begins.
    await Future.delayed(const Duration(milliseconds: 120));

    try {
      final result = await action();

      if (dialogShown && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      messenger?.hideCurrentSnackBar();
      if (successMessage.isNotEmpty) {
        messenger?.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  successMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return result;
    } catch (e) {
      if (dialogShown && dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
      messenger?.hideCurrentSnackBar();
      rethrow;
    }
  }
}
