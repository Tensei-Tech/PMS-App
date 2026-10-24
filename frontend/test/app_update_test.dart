import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khakhi_diary/services/app_update_service.dart';
import 'package:khakhi_diary/widgets/app_update_gate.dart';

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
      expect(find.text('Download update'), findsOneWidget);
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
}
