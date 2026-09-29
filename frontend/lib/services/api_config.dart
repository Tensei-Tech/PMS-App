import 'dart:async';
import 'package:http/http.dart' as http;

/// Configuration class for Django REST API endpoints and base URL.
class ApiConfig {
  /// Base URL override via --dart-define=API_BASE_URL=https://...
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

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

  /// Base API URL: strictly uses API_BASE_URL env var
  static String get baseUrl {
    String url = _envBaseUrl;
    if (url.isEmpty) {
      throw Exception(
          'CRITICAL: API_BASE_URL environment variable is missing!\n'
          'You must run the app with --dart-define=API_BASE_URL=http://...\n'
          'For local dev: flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8001/api');
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
