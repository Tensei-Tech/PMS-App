import 'app_update_service.dart';

/// The version this app was built as. CI passes APP_VERSION_NAME (the
/// version in pubspec.yaml) and APP_BUILD_NUMBER (the Actions run number);
/// builds made on a computer show "dev" and no build number.
class AppVersion {
  static const String name =
      String.fromEnvironment('APP_VERSION_NAME', defaultValue: 'dev');

  static int get build => AppUpdateService.currentBuild;

  /// e.g. "Version 1.0.1 (build 405)"
  static String get label => build > 0
      ? 'Version $name (build $build)'
      : 'Version $name (local build)';
}
