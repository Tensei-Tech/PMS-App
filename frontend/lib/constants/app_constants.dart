// lib/constants/app_constants.dart

class ApiConstants {
  // Google Apps Script Web App URL for feedback notifications.
  // Injected at build time via --dart-define=FEEDBACK_WEB_APP_URL=https://...
  // or --dart-define-from-file=secrets.json.
  static const String feedbackWebAppUrl = String.fromEnvironment(
    'FEEDBACK_WEB_APP_URL',
    defaultValue: '',
  );

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys for Tokens
  static const String jwtAccessTokenKey = 'jwt_access_token';
  static const String jwtRefreshTokenKey = 'jwt_refresh_token';
}
