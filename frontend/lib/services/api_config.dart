import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Configuration class for Django REST API endpoints and base URL.
class ApiConfig {
  /// Base URL configurable via --dart-define=API_BASE_URL=https://api.pms.gov.in/api
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Default local development port
  static const int defaultPort = 8000;

  /// Custom host override if specified at runtime
  static String? _customBaseUrl;

  /// Override the default base URL dynamically at runtime
  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  /// Base API URL dynamically determined by environment, platform & override settings
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

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

  // Authentication Endpoints
  static String get authLogin => '$baseUrl/auth/login/';
  static String get authRegister => '$baseUrl/auth/register/';
  static String get authCheckExists => '$baseUrl/auth/check-exists/';
  static String get authTokenRefresh => '$baseUrl/auth/token/refresh/';
  static String get authPermissions => '$baseUrl/auth/me/permissions/';

  // Resource Endpoints
  static String get users => '$baseUrl/users/';
  static String get stations => '$baseUrl/stations/';
  static String get cases => '$baseUrl/cases/';
  static String get master => '$baseUrl/master/';
  static String get masterStates => '$baseUrl/master/states/';
}
