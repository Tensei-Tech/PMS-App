// test/ad_hub_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/screens/ad/ad_hub_screen.dart';
import 'package:khakhi_diary/services/ad_service.dart';
import 'package:khakhi_diary/services/api_service.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json'});

Map<String, dynamic> _config() => {
      'target_category_code': 'STAND_AD',
      'sub_categories': [
        {'code': 'STAND_AD_SUICIDE', 'name': 'TEST Suicide', 'id': 1},
        {'code': 'STAND_AD_OTHER', 'name': 'TEST Other', 'id': 2},
      ],
      'sub_tab_labels': {
        'total': 'TEST Total',
        'pending': 'TEST Pending',
        'disposal': 'TEST Disposal',
      },
      'action_labels': {
        'add': 'TEST Add AD',
        'edit': 'TEST Edit',
        'view': 'TEST View',
        'pdf': 'TEST PDF',
      },
      'search_placeholder': 'TEST search',
      'empty_list_message': 'TEST nothing here',
      'messages': {'pdf_failed_message': 'TEST pdf failed'},
      'page_size': 20,
      'serial_label': 'TEST Sr',
      'pending_definition': 'TEST pending means SDM not granted',
    };

Widget _app(Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
      ],
      child: MaterialApp(home: home),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    AdService().clearConfigCache();
  });

  tearDown(() => ApiService.clientForTesting = null);

  testWidgets(
      'A.D. hub: sub-tabs, counts and cards per sub-tab, all from the backend',
      (tester) async {
    final requests = <Uri>[];
    ApiService.clientForTesting = MockClient((req) async {
      requests.add(req.url);
      final p = req.url.path;
      final cat = req.url.queryParameters['category'];
      if (p.endsWith('/api/ad/config/')) return _json(_config());
      if (p.endsWith('/api/ad/counts/')) {
        return _json(cat == 'STAND_AD_OTHER'
            ? {'total': 0, 'pending': 0, 'disposal': 0}
            : {'total': 2, 'pending': 1, 'disposal': 1});
      }
      if (p.endsWith('/api/ad/')) {
        if (cat == 'STAND_AD_OTHER') {
          return _json({'results': [], 'next_cursor': null});
        }
        return _json({
          'results': [
            {
              'id': 'abc',
              'case_number': 'TEST-AD-1',
              'is_disposal': false,
              'status_label': 'TEST Pending',
              'card_rows': [
                ['TEST AD No.', 'TEST-AD-1'],
                ['TEST Deceased Name', 'TEST Ram'],
                ['TEST SDM Granted / Date', 'Yes\n15/10/2026'],
              ],
            }
          ],
          'next_cursor': null,
        });
      }
      return _json({});
    });

    await tester.pumpWidget(
        _app(const AdHubScreen(categoryName: 'A.D', moduleKey: 'ad')));
    await tester.pumpAndSettle();

    // Sub-tabs and labels come from config; first sub-tab is open
    expect(find.text('TEST Suicide'), findsOneWidget);
    expect(find.text('TEST Other'), findsOneWidget);
    expect(find.text('TEST Total'), findsOneWidget);
    expect(find.text('TEST Add AD'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Card boxes are exactly the backend's card_rows
    expect(find.text('TEST AD No.'), findsOneWidget);
    expect(find.text('TEST Ram'), findsOneWidget);
    expect(find.text('15/10/2026'), findsOneWidget);
    expect(find.text('TEST View'), findsOneWidget);
    expect(
        requests.any((u) =>
            u.path.endsWith('/api/ad/') &&
            u.queryParameters['category'] == 'STAND_AD_SUICIDE' &&
            u.queryParameters['tab'] == 'total'),
        isTrue);

    // Other sub-tab: its own counts and list
    await tester.tap(find.text('TEST Other'));
    await tester.pumpAndSettle();
    expect(find.text('TEST Ram'), findsNothing);
    expect(find.text('TEST nothing here'), findsOneWidget);
    expect(
        requests.any((u) =>
            u.path.endsWith('/api/ad/counts/') &&
            u.queryParameters['category'] == 'STAND_AD_OTHER'),
        isTrue);
  });
}
