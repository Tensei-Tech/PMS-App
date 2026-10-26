import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khakhi_diary/services/app_update_installer.dart';
import 'package:khakhi_diary/services/app_update_service.dart';
import 'package:khakhi_diary/services/app_version.dart';
import 'package:khakhi_diary/widgets/app_update_gate.dart';
import 'package:ota_update/ota_update.dart';

const _url = 'https://example.test/api/app-version/download/';

void main() {
  group('AppUpdateService.evaluate', () {
    AppUpdateInfo eval(int current, Map<String, dynamic> data) =>
        AppUpdateService.evaluate(currentBuild: current, data: data);

    test('below minimum is required', () {
      final info = eval(5, {
        'latest_build': 10,
        'min_build': 8,
        'download_url': _url,
      });
      expect(info.status, AppUpdateStatus.required);
      expect(info.latestBuild, 10);
      expect(info.downloadUrl, _url);
    });

    test('below latest but at minimum is optional', () {
      final info = eval(8, {
        'latest_build': 10,
        'min_build': 8,
        'download_url': _url,
      });
      expect(info.status, AppUpdateStatus.optional);
    });

    test('at latest is up to date', () {
      final info = eval(10, {
        'latest_build': 10,
        'min_build': 8,
        'download_url': _url,
      });
      expect(info.status, AppUpdateStatus.none);
    });

    test('no download link means no prompt', () {
      final info = eval(1, {
        'latest_build': 10,
        'min_build': 8,
        'download_url': '',
      });
      expect(info.status, AppUpdateStatus.none);
    });

    test('unknown local build (0) is never prompted', () {
      final info = eval(0, {
        'latest_build': 10,
        'min_build': 8,
        'download_url': _url,
      });
      expect(info.status, AppUpdateStatus.none);
    });

    test('accepts numbers sent as strings', () {
      final info = eval(3, {
        'latest_build': '10',
        'min_build': '4',
        'download_url': _url,
      });
      expect(info.status, AppUpdateStatus.required);
    });
  });

  test('check is off for non-CI builds and makes no request', () async {
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response(json.encode({}), 200);
    });
    // Tests run without APP_BUILD_NUMBER, like a local build.
    final info = await AppUpdateService.check(client: client);
    expect(info.status, AppUpdateStatus.none);
    expect(called, isFalse);
  });

  group('AppUpdateGate', () {
    Widget app(AppUpdateInfo info) => MaterialApp(
          home: AppUpdateGate(
            checker: () async => info,
            child: const Scaffold(body: Text('app content')),
          ),
        );

    testWidgets('required update covers the app', (tester) async {
      await tester.pumpWidget(app(const AppUpdateInfo(
        status: AppUpdateStatus.required,
        latestBuild: 12,
        downloadUrl: _url,
      )));
      await tester.pump();
      expect(find.text('Update required'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Update'), findsOneWidget);
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('optional update can be dismissed', (tester) async {
      await tester.pumpWidget(app(const AppUpdateInfo(
        status: AppUpdateStatus.optional,
        latestBuild: 12,
        downloadUrl: _url,
      )));
      await tester.pump();
      expect(find.text('Update available: build 12'), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pump();
      expect(find.text('Update available: build 12'), findsNothing);
      expect(find.text('app content'), findsOneWidget);
    });

    testWidgets('no update shows only the app', (tester) async {
      await tester.pumpWidget(app(AppUpdateInfo.none));
      await tester.pump();
      expect(find.text('app content'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('In-app update download', () {
    late StreamController<UpdateDownloadEvent> events;
    late List<String> requested;
    late List<Uri> opened;

    setUp(() {
      events = StreamController<UpdateDownloadEvent>();
      requested = [];
      opened = [];
    });

    // Not awaited: close() only completes once someone listened, and the
    // Play Store test never starts a download.
    tearDown(() {
      events.close();
    });

    Widget app(String url) => MaterialApp(
          home: AppUpdateGate(
            checker: () async => AppUpdateInfo(
              status: AppUpdateStatus.optional,
              latestBuild: 12,
              downloadUrl: url,
            ),
            downloader: (u) {
              requested.add(u);
              return events.stream;
            },
            browserOpener: (u) async {
              opened.add(u);
              return true;
            },
            child: const Scaffold(body: Text('app content')),
          ),
        );

    Future<void> tapUpdate(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Update'));
      await tester.pump();
    }

    testWidgets('downloads inside the app once, with progress', (tester) async {
      await tester.pumpWidget(app(_url));
      await tester.pump();
      await tapUpdate(tester);
      expect(requested, [_url]); // one download, no browser

      events.add(const UpdateDownloadEvent(UpdateDownloadStatus.downloading,
          percent: 42));
      await tester.pump();
      expect(find.text('Downloading update... 42%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Update and Later are disabled while downloading
      final update = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(update.onPressed, isNull);

      events.add(const UpdateDownloadEvent(UpdateDownloadStatus.installing));
      await tester.pump();
      expect(find.textContaining('Opening the installer'), findsOneWidget);
    });

    testWidgets('failure offers try again and the browser fallback',
        (tester) async {
      await tester.pumpWidget(app(_url));
      await tester.pump();
      await tapUpdate(tester);
      events.add(const UpdateDownloadEvent(UpdateDownloadStatus.failed,
          message: 'Download failed.'));
      await tester.pump();
      expect(find.text('Download failed.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
      expect(find.text('Open in browser'), findsOneWidget);
    });

    testWidgets('a non-APK link (e.g. Play Store) is not downloaded in-app',
        (tester) async {
      await tester
          .pumpWidget(app('https://play.google.com/store/apps/details?id=x'));
      await tester.pump();
      await tapUpdate(tester);
      expect(requested, isEmpty); // not downloaded in-app
      expect(opened.single.host, 'play.google.com'); // opened in the store
    });
  });

  group('AppUpdateInstaller', () {
    test('only our backend APK link is installed in-app', () {
      expect(AppUpdateInstaller.canInstallInApp(_url), isTrue);
      expect(
          AppUpdateInstaller.canInstallInApp(
              'https://play.google.com/store/apps/details?id=x'),
          isFalse);
      expect(AppUpdateInstaller.canInstallInApp(''), isFalse);
    });

    test('plugin events become progress, installing or a clear error', () {
      final downloading =
          AppUpdateInstaller.fromOta(OtaStatus.DOWNLOADING, '37');
      expect(downloading.status, UpdateDownloadStatus.downloading);
      expect(downloading.percent, 37);
      expect(AppUpdateInstaller.fromOta(OtaStatus.INSTALLING, null).status,
          UpdateDownloadStatus.installing);
      final denied = AppUpdateInstaller.fromOta(
          OtaStatus.PERMISSION_NOT_GRANTED_ERROR, null);
      expect(denied.status, UpdateDownloadStatus.failed);
      expect(denied.message, contains('install apps'));
      expect(AppUpdateInstaller.fromOta(OtaStatus.DOWNLOAD_ERROR, 'x').status,
          UpdateDownloadStatus.failed);
    });
  });

  test('version label without a CI build number', () {
    // Tests run without APP_BUILD_NUMBER / APP_VERSION_NAME, like a local build.
    expect(AppVersion.label, 'Version dev (local build)');
  });
}
