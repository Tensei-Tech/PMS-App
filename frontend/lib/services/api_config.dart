import 'dart:async';
import 'package:flutter/foundation.dart';
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

  /// Local backend used when API_BASE_URL is not set (development only).
  static const String _localBaseUrl = 'http://127.0.0.1:8000/api';

  /// True for a release build made without API_BASE_URL. Such a build points
  /// at 127.0.0.1, which a phone cannot reach, so login must refuse early.
  /// Build releases with --dart-define-from-file=config/prod.json.
  static bool get isMissingInRelease => kReleaseMode && _envBaseUrl.isEmpty;

  /// Host the app talks to, for error messages.
  static String get serverHost {
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host.isNotEmpty ? host : baseUrl;
  }

  /// Base API URL: strictly uses API_BASE_URL env var
  static String get baseUrl {
    String url = _envBaseUrl;
    if (url.isEmpty) {
      url = _localBaseUrl;
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

  // In-app update check (public, called before login)
  static String get appVersion => '$baseUrl/app-version/';
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
  static String get uiConfig => '${master}ui-config/'; // master ends with '/'
  static String get masterStates => '$baseUrl/master/states/';
  static String get transfers => '$baseUrl/users/transfers/';
  static String get auditLogs => '$baseUrl/core/audit-logs/';
  static String get sosAlerts => '$baseUrl/core/sos-alerts/';
  static String get announcements => '$baseUrl/master/announcements/';

  static String get designations => '$baseUrl/master/designations/';

  // Reference Data Endpoints for Acts & Charges
  static String get acts => '$baseUrl/acts/';
  static String get actSections => '$baseUrl/act-sections/';
  static String get actSubsections => '$baseUrl/act-subsections/';

  // RTI Endpoints
  static String get rti => '$baseUrl/rti/';
  static String get rtiCounts => '$baseUrl/rti/counts/';
  static String get rtiConfig => '$baseUrl/rti/config/';
  static String get rtiChart => '$baseUrl/rti/chart/';
  static String get rtiReminders => '$baseUrl/rti/reminders/';
  static String get rtiRemindersSeen => '$baseUrl/rti/reminders/seen/';
  static String rtiRemind(dynamic id) => '$baseUrl/rti/$id/remind/';
  static String get rtiOfficers => '$baseUrl/rti/officers/';
  static String rtiDetail(dynamic id) => '$baseUrl/rti/$id/';
  static String rtiPdf(dynamic id) => '$baseUrl/rti/$id/pdf/';

  // History Sheeter Endpoints
  static String get historySheeter => '$baseUrl/history-sheeter/';
  static String get historySheeterCounts => '$baseUrl/history-sheeter/counts/';
  static String get historySheeterConfig => '$baseUrl/history-sheeter/config/';
  static String get historySheeterChart => '$baseUrl/history-sheeter/chart/';
  static String historySheeterDetail(dynamic id) =>
      '$baseUrl/history-sheeter/$id/';
  static String historySheeterPdf(dynamic id) =>
      '$baseUrl/history-sheeter/$id/pdf/';

  // N.C. (independent module, not cases)
  static String get nc => '$baseUrl/nc/';
  static String get ncCounts => '$baseUrl/nc/counts/';
  static String get ncConfig => '$baseUrl/nc/config/';
  static String ncDetail(dynamic id) => '$baseUrl/nc/$id/';
  static String ncPdf(dynamic id) => '$baseUrl/nc/$id/pdf/';

  // A.D. (Suicide / Other sub-tabs; ?category=<sub-tab code>)
  static String get ad => '$baseUrl/ad/';
  static String get adCounts => '$baseUrl/ad/counts/';
  static String get adConfig => '$baseUrl/ad/config/';
  static String adDetail(dynamic id) => '$baseUrl/ad/$id/';
  static String adPdf(dynamic id) => '$baseUrl/ad/$id/pdf/';

  // MPDA Endpoints
  static String get mpda => '$baseUrl/mpda/';
  static String get mpdaCounts => '$baseUrl/mpda/counts/';
  static String get mpdaConfig => '$baseUrl/mpda/config/';
  static String get mpdaSummary => '$baseUrl/mpda/summary/';
  static String get mpdaReminders => '$baseUrl/mpda/reminders/';
  static String get mpdaRemindersSeen => '$baseUrl/mpda/reminders/seen/';
  static String mpdaRemind(dynamic id) => '$baseUrl/mpda/$id/remind/';
  static String get mpdaOfficers => '$baseUrl/mpda/officers/';
  static String mpdaDetail(dynamic id) => '$baseUrl/mpda/$id/';
  static String mpdaPdf(dynamic id) => '$baseUrl/mpda/$id/pdf/';
  // E-Learning Endpoints
  static String get elearningCourses => '$baseUrl/elearning/courses/';
  static String get elearningSubmit => '$baseUrl/elearning/submit/';
  static String get elearningRecords => '$baseUrl/elearning/records/';
  static String get elearningAnalytics => '$baseUrl/elearning/analytics/';
}
