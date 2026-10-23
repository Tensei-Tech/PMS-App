// test/mpda_reminders_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/notification_provider.dart';
import 'package:khakhi_diary/screens/mpda/mpda_hub_screen.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/mpda_service.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json'});

final _reminders = {
  'count': 2,
  'days': 30,
  'labels': {
    'banner': 'TEST {count} ending within {days} days',
    'tab': 'TEST MPDA Detention',
  },
  'results': [
    {
      'id': 7,
      'title': 'TEST Title',
      'message': 'TEST Ravi ends on 20/11/2026',
      'days_left': 5,
    },
    {
      'id': 8,
      'title': 'TEST Title',
      'message': 'TEST Shyam ends on 25/11/2026',
      'days_left': 10,
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    MpdaService().clearCache();
    ApiService.clientForTesting = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/api/mpda/reminders/')) return _json(_reminders);
      if (p.endsWith('/api/mpda/config/')) {
        return _json({
          'card_labels': {'total': 'TEST Total', 'summary': 'TEST Summary'},
          'action_labels': {'view': 'TEST View'},
          'page_size': 20,
        });
      }
      return _json({'count': 0, 'page': 1, 'page_size': 20, 'results': []});
    });
  });
  tearDown(() => ApiService.clientForTesting = null);

  test('bell count includes reminders until the bell is opened', () async {
    final np = NotificationProvider();
    await np.loadDetentionReminders();
    expect(np.detentionReminders.length, 2);
    expect(np.unreadCount, 2);
    expect(np.detentionReminderLabel, 'TEST MPDA Detention');
    np.clearBadge();
    expect(np.unreadCount, 0);
    expect(np.detentionReminders.length, 2); // still listed
  });

  testWidgets('MPDA hub shows the reminder banner and its list',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
      ],
      child: const MaterialApp(
        home: MpdaHubScreen(
          categoryName: 'TEST MPDA',
          categoryCode: 'STAND_MPDA',
          moduleKey: 'mpda',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('TEST 2 ending within 30 days'), findsOneWidget);
    await tester.tap(find.text('TEST 2 ending within 30 days'));
    await tester.pumpAndSettle();
    expect(find.text('TEST MPDA Detention'), findsOneWidget);
    expect(find.text('TEST Ravi ends on 20/11/2026'), findsOneWidget);
    expect(find.text('TEST Shyam ends on 25/11/2026'), findsOneWidget);
  });
}
