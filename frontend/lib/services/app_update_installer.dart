import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';

enum UpdateDownloadStatus { downloading, installing, failed }

class UpdateDownloadEvent {
  final UpdateDownloadStatus status;

  /// 0-100 while downloading.
  final int? percent;

  /// What went wrong, for [UpdateDownloadStatus.failed].
  final String? message;

  const UpdateDownloadEvent(this.status, {this.percent, this.message});
}

/// Downloads the new APK inside the app (with progress) and opens Android's
/// installer. Handing the link to the browser instead made it download the
/// APK twice and left the user to find and open the file.
class AppUpdateInstaller {
  static const String fileName = 'khakhi-diary-update.apk';

  /// Our backend's download link serves the APK; any other link (for example
  /// a Play Store page after launch) is opened outside the app.
  static bool canInstallInApp(String url) =>
      Uri.tryParse(url)?.path.endsWith('/app-version/download/') ?? false;

  static Stream<UpdateDownloadEvent> downloadAndInstall(String url) =>
      OtaUpdate()
          .execute(url, destinationFilename: fileName)
          .map((event) => fromOta(event.status, event.value));

  @visibleForTesting
  static UpdateDownloadEvent fromOta(OtaStatus status, String? value) {
    switch (status) {
      case OtaStatus.DOWNLOADING:
        final percent = int.tryParse((value ?? '').trim());
        return UpdateDownloadEvent(
          UpdateDownloadStatus.downloading,
          percent: percent?.clamp(0, 100),
        );
      case OtaStatus.INSTALLING:
      case OtaStatus.INSTALLATION_DONE:
        return const UpdateDownloadEvent(UpdateDownloadStatus.installing);
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        return const UpdateDownloadEvent(
          UpdateDownloadStatus.failed,
          message:
              'Allow PMS to install apps (Android asks once), then tap Update again.',
        );
      case OtaStatus.ALREADY_RUNNING_ERROR:
        return const UpdateDownloadEvent(
          UpdateDownloadStatus.failed,
          message: 'The update is already downloading. Please wait.',
        );
      case OtaStatus.CANCELED:
        return const UpdateDownloadEvent(
          UpdateDownloadStatus.failed,
          message: 'Download cancelled.',
        );
      default:
        return const UpdateDownloadEvent(
          UpdateDownloadStatus.failed,
          message:
              'Download failed. Check your internet connection and try again.',
        );
    }
  }
}
