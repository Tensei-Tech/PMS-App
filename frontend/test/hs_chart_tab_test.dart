// test/hs_chart_tab_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/screens/history_sheeter/history_sheeter_hub_screen.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/history_sheeter_service.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    HistorySheeterService().clearCache();
  });
  tearDown(() => ApiService.clientForTesting = null);

  testWidgets(
      'Summary tab: first tab, no Total tab, table of all sheets with View',
      (tester) async {
    final chartCalls = <Uri>[];
    ApiService.clientForTesting = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/api/history-sheeter/config/')) {
        return _json({
          'sub_tab_labels': {
            'active': 'TEST Active',
            'open': 'TEST Open',
            'closed': 'TEST Closed',
            'chart': 'TEST Summary',
            'total': 'TEST Total HS',
            'jail': 'TEST Jail',
            'bail': 'TEST Bail',
          },
          'chart_headers': {
            'sr_no': 'TEST Sr',
            'person': 'TEST Person',
            'total_cases': 'TEST Total',
            'associates': 'TEST Associates',
            'rivals': 'TEST Rivals',
            'preventive': 'TEST Preventive',
          },
          'action_labels': {'view': 'TEST View'},
          'page_size': 20,
        });
      }
      if (p.endsWith('/api/history-sheeter/counts/')) {
        return _json({'active': 1, 'open': 2, 'closed': 3});
      }
      if (p.endsWith('/api/history-sheeter/chart/')) {
        chartCalls.add(req.url);
        return _json({
          'count': 5,
          'page': 1,
          'page_size': 20,
          'results': [
            {
              'id': 1,
              'sr_no': 7,
              'person': 'TEST Ravi, 30 Yrs, Male',
              'total_cases': 4,
              'associates': 2,
              'rivals': 1,
              'preventive': 3,
            }
          ],
        });
      }
      return _json({'count': 0, 'page': 1, 'page_size': 20, 'results': []});
    });

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
      ],
      child: const MaterialApp(
        home: HistorySheeterHubScreen(
          categoryName: 'TEST History Sheeter',
          categoryCode: 'STAND_HISTORY_SHEETER',
          moduleKey: 'history_sheeter',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Summary tab first (it carries the total), then the status tabs; no Total tab
    expect(find.text('TEST Active'), findsOneWidget);
    expect(find.text('TEST Open'), findsOneWidget);
    expect(find.text('TEST Closed'), findsOneWidget);
    expect(find.text('TEST Summary'), findsOneWidget);
    expect(find.text('TEST Total HS'), findsNothing);
    expect(find.text('TEST Jail'), findsOneWidget);
    expect(find.text('TEST Bail'), findsOneWidget);
    expect(find.text('5'),
        findsNothing); // the badge is the counts total, not the chart count

    // Seven tabs: scroll the tab bar so the Summary tab is on screen
    await tester.ensureVisible(find.text('TEST Summary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TEST Summary'));
    await tester.pumpAndSettle();

    expect(chartCalls, isNotEmpty);
    for (final h in [
      'TEST Sr',
      'TEST Person',
      'TEST Total',
      'TEST Associates',
      'TEST Rivals',
      'TEST Preventive'
    ]) {
      expect(find.text(h), findsOneWidget);
    }
    expect(find.text('TEST Ravi, 30 Yrs, Male'), findsOneWidget);
    // View action button
    expect(find.text('TEST View'), findsOneWidget);
  });

  testWidgets('Summary: tapping the associates count lists the gang members',
      (tester) async {
    ApiService.clientForTesting = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/api/history-sheeter/config/')) {
        return _json({
          'sub_tab_labels': {'chart': 'TEST Summary'},
          'chart_headers': {'associates': 'TEST Associates'},
          'action_labels': {'view': 'TEST View'},
          'page_size': 20,
        });
      }
      if (p.endsWith('/api/history-sheeter/counts/')) return _json({});
      if (p.endsWith('/api/history-sheeter/chart/')) {
        return _json({
          'count': 1,
          'page': 1,
          'page_size': 20,
          'results': [
            {
              'id': 9,
              'sr_no': 2,
              'person': 'TEST',
              'total_cases': 0,
              'associates': 2,
              'rivals': 0,
              'preventive': 0
            }
          ],
        });
      }
      if (p.endsWith('/api/history-sheeter/9/')) {
        return _json({
          'id': 9,
          'sr_no': 2,
          'name': 'TEST Sheet',
          'repeating_sections': [
            {
              'field_key': 'hs_associates',
              'section_title': 'TEST Gang Members',
              'headers': ['TEST Name', 'TEST Mobile'],
              'rows': [
                ['TEST Raju', '9876543210'],
                ['TEST Shyam', ''],
              ],
            }
          ],
        });
      }
      return _json({'count': 0, 'page': 1, 'page_size': 20, 'results': []});
    });

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
      ],
      child: const MaterialApp(
        home: HistorySheeterHubScreen(
          categoryName: 'TEST History Sheeter',
          categoryCode: 'STAND_HISTORY_SHEETER',
          moduleKey: 'history_sheeter',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // Seven tabs: scroll the tab bar so the Summary tab is on screen
    await tester.ensureVisible(find.text('TEST Summary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TEST Summary'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2').last); // associates count pill
    await tester.pumpAndSettle();

    expect(find.text('TEST Gang Members'), findsOneWidget);
    expect(find.text('TEST Raju'), findsOneWidget);
    expect(find.text('TEST Shyam'), findsOneWidget);
    expect(find.text('-'), findsWidgets); // empty mobile shown as '-'
  });
}
