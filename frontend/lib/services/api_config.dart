import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

/// Configuration class for Django REST API endpoints and base URL.
class ApiConfig {
  /// Base URL override via --dart-define=API_BASE_URL=https://...
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Environment flag: --dart-define=IS_DEV=true (Switches to Local Dev Server).
  /// Default is false (Render Cloud Backend).
  static const bool isDev = bool.fromEnvironment('IS_DEV', defaultValue: false);

  /// Default Render Cloud Backend URL (Hardcoded Default)
  static const String renderBackendUrl =
      'https://pms-app-backend.onrender.com/api';

  /// Default local development port (8001 matches runserver 0.0.0.0:8001)
  static int defaultPort = 8001;

  /// Custom host override if specified at runtime
  static String? _customBaseUrl;

  static bool _hasPrewarmed = false;
  static DateTime? _lastPrewarmedAt;

  /// Root URL of the backend hosting environment (without /api path)
  static String get rootHealthUrl {
    final base = baseUrl;
    final uri = Uri.parse(base);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/';
  }

  /// Silently pre-warms the backend (Root health check + Auth service) to eliminate cold-start delays
  static void prewarmBackend({bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        _hasPrewarmed &&
        _lastPrewarmedAt != null &&
        now.difference(_lastPrewarmedAt!).inMinutes < 3) {
      return;
    }
    _hasPrewarmed = true;
    _lastPrewarmedAt = now;

    try {
      // 1. Ping Root Health Check (instant gunicorn/render wake-up)
      unawaited(
        http
            .get(Uri.parse(rootHealthUrl))
            .timeout(const Duration(seconds: 25))
            .catchError((_) => http.Response('', 408)),
      );

      // 2. Ping Auth endpoint to warm up Django authentication app & DB pool
      unawaited(
        http
            .get(Uri.parse(authCheckExists))
            .timeout(const Duration(seconds: 25))
            .catchError((_) => http.Response('', 408)),
      );
    } catch (_) {}
  }

  /// Override the default base URL dynamically at runtime
  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  /// Get local development base URL based on active platform
  static String get localDevUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$defaultPort/api';
    } else if (!kIsWeb && Platform.isAndroid) {
      // 10.0.2.2 maps to host machine's localhost inside Android Emulator
      return 'http://10.0.2.2:$defaultPort/api';
    } else {
      // iOS, Windows, macOS, Linux
      return 'http://127.0.0.1:$defaultPort/api';
    }
  }

  /// Base API URL:
  /// - If API_BASE_URL env var is provided, use it
  /// - If _customBaseUrl runtime override is set, use it
  /// - If IS_DEV=true, use Local Dev Server
  /// - Default -> Render Cloud Backend (https://pms-app-backend.onrender.com/api)
  static String get baseUrl {
    String url;
    if (_envBaseUrl.isNotEmpty) {
      url = _envBaseUrl;
    } else if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      url = _customBaseUrl!;
    } else if (isDev) {
      url = localDevUrl;
    } else {
      url = renderBackendUrl;
    }

    // Enforce HTTPS scheme for non-localhost endpoints
    if (url.startsWith('http://') &&
        !url.contains('127.0.0.1') &&
        !url.contains('localhost') &&
        !url.contains('10.0.2.2')) {
      url = url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  // Authentication Endpoints
  static String get authLogin => '$baseUrl/auth/login/';
  static String get authRegister => '$baseUrl/auth/register/';
  static String get authChangePassword => '$baseUrl/auth/change-password/';
  static String get authCheckExists => '$baseUrl/auth/check-exists/';
  static String get authTokenRefresh => '$baseUrl/auth/token/refresh/';
  static String get authPermissions => '$baseUrl/auth/me/permissions/';
  static String get authPendingApprovals =>
      '$baseUrl/auth/notifications/pending-approvals/';
  static String authApproveRegistration(String uid) =>
      '$baseUrl/auth/users/$uid/approve-registration/';

  // Resource Endpoints
  static String get users => '$baseUrl/users/';
  static String get hierarchyDirectory => '$baseUrl/users/hierarchy-directory/';
  static String get stations => '$baseUrl/stations/';
  static String get cases => '$baseUrl/cases/';
  static String get master => '$baseUrl/master/';
  static String get masterStates => '$baseUrl/master/states/';
  static String get transfers => '$baseUrl/users/transfers/';
  static String get auditLogs => '$baseUrl/core/audit-logs/';
  static String get sosAlerts => '$baseUrl/core/sos-alerts/';
  static String get announcements => '$baseUrl/master/announcements/';
}
