import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

enum AppUpdateStatus { none, optional, required }

class AppUpdateInfo {
  final AppUpdateStatus status;
  final int latestBuild;
  final String downloadUrl;

  const AppUpdateInfo({
    required this.status,
    this.latestBuild = 0,
    this.downloadUrl = '',
  });

  static const none = AppUpdateInfo(status: AppUpdateStatus.none);
}

/// Compares this APK's build number with the builds the backend advertises
/// (APP_LATEST_BUILD / APP_MIN_BUILD on Render, served by /api/app-version/).
class AppUpdateService {
  /// Set by CI: --dart-define=APP_BUILD_NUMBER=<run number>. Local builds
  /// leave it 0, which turns the check off.
  static const int currentBuild = int.fromEnvironment('APP_BUILD_NUMBER');

  /// Only CI-built Android APKs can be updated by downloading a new APK.
  static bool get isSupported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      currentBuild > 0;

  /// Free Render instances can take about a minute to wake up.
  static const Duration timeout = Duration(seconds: 60);

  static Future<AppUpdateInfo> check({http.Client? client}) async {
    if (!isSupported) return AppUpdateInfo.none;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse(ApiConfig.appVersion))
          .timeout(timeout);
      if (response.statusCode != 200) return AppUpdateInfo.none;
      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return AppUpdateInfo.none;
      return evaluate(currentBuild: currentBuild, data: data);
    } catch (e) {
      // A failed check must never block the app.
      if (kDebugMode) debugPrint('[AppUpdate] check failed: $e');
      return AppUpdateInfo.none;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  @visibleForTesting
  static AppUpdateInfo evaluate({
    required int currentBuild,
    required Map<String, dynamic> data,
  }) {
    final latest = _asInt(data['latest_build']);
    final minimum = _asInt(data['min_build']);
    final url = (data['download_url'] ?? '').toString().trim();
    // Nothing to install means nothing to ask for.
    if (currentBuild <= 0 || url.isEmpty) return AppUpdateInfo.none;

    final AppUpdateStatus status;
    if (currentBuild < minimum) {
      status = AppUpdateStatus.required;
    } else if (currentBuild < latest) {
      status = AppUpdateStatus.optional;
    } else {
      return AppUpdateInfo.none;
    }
    return AppUpdateInfo(status: status, latestBuild: latest, downloadUrl: url);
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}'.trim()) ?? 0;
  }
}
