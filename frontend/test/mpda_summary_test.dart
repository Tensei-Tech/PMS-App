// test/mpda_summary_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/screens/mpda/mpda_hub_screen.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/mpda_service.dart';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    MpdaService().clearCache();
  });
  tearDown(() => ApiService.clientForTesting = null);

  testWidgets('MPDA Summary card: table, gang member popup, no count',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    ApiService.clientForTesting = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/api/mpda/config/')) {
        return _json({
          'card_labels': {
            'total': 'TEST Total',
            'approved': 'TEST Approved',
            'rejected': 'TEST Rejected',
            'jail': 'TEST Jail',
            'released_next_month': 'TEST Released',
            'summary': 'TEST Summary',
          },
          'summary_headers': {
            'sr_no': 'TEST Sr',
            'accused': 'TEST Accused',
            'gang_members': 'TEST Gang',
            'outcome': 'TEST Outcome',
            'category': 'TEST Category',
          },
          'action_labels': {'view': 'TEST View'},
          'page_size': 20,
        });
      }
      if (p.endsWith('/api/mpda/counts/')) {
        return _json({
          'total': 4,
          'approved': 1,
          'rejected': 1,
          'jail': 0,
          'released_next_month': 0
        });
      }
      if (p.endsWith('/api/mpda/summary/')) {
        return _json({
          'count': 1,
          'page': 1,
          'page_size': 20,
          'results': [
            {
              'id': 7,
              'sr_no': 1,
              'accused': ['TEST Ravi, 30 Yrs', 'TEST Shyam'],
              'gang_members': 2,
              'outcome': 'TEST Granted (01/10/2026)',
              'category': 'TEST Dangerous Person',
            }
          ],
        });
      }
      if (p.endsWith('/api/mpda/7/')) {
        return _json({
          'id': 7,
          'proposal_no_and_year': 'TEST 1/2026',
          'display_fields': [
            {
              'field_key': 'mpda_proposal_outcome',
              'label': 'TEST Outcome Field',
              'value': 'TEST Granted',
              'section': 'TEST Info'
            },
            {
              'field_key': 'mpda_proposal_revoked',
              'label': 'TEST Revoked Field',
              'value': 'TEST Yes',
              'section': 'TEST Info'
            },
            {
              'field_key': 'mpda_io_name',
              'label': 'TEST IO Field',
              'value': 'TEST IO',
              'section': 'TEST Info'
            },
            {
              'field_key': 'mpda_category',
              'label': 'TEST Category Field',
              'value': 'TEST Dangerous',
              'section': 'TEST Cat'
            },
            {
              'field_key': 'mpda_category_other',
              'label': 'TEST Other Field',
              'value': '',
              'section': 'TEST Cat'
            },
          ],
          'repeating_sections': [
            {
              'field_key': 'mpda_accused',
              'section_title': 'TEST Accused Section',
              'headers': ['TEST Accused Name', 'TEST PAN'],
              'rows': [
                ['TEST Ravi', 'TEST PAN1'],
              ],
            },
            {
              'field_key': 'mpda_gang_members',
              'section_title': 'TEST Gang Members',
              'headers': ['TEST Name'],
              'rows': [
                ['TEST Member A'],
                ['TEST Member B'],
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
        home: MpdaHubScreen(
          categoryName: 'TEST MPDA',
          categoryCode: 'STAND_MPDA',
          moduleKey: 'mpda',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('TEST Summary'), findsOneWidget);
    expect(find.byIcon(Icons.table_chart_rounded), findsOneWidget); // no count

    await tester.tap(find.text('TEST Summary'));
    await tester.pumpAndSettle();

    for (final h in [
      'TEST Sr',
      'TEST Accused',
      'TEST Gang',
      'TEST Outcome',
      'TEST Category'
    ]) {
      expect(find.text(h), findsOneWidget);
    }
    expect(find.text('1. TEST Ravi, 30 Yrs'), findsOneWidget);
    expect(find.text('2. TEST Shyam'), findsOneWidget);
    expect(find.text('TEST Granted (01/10/2026)'), findsOneWidget);
    expect(find.text('TEST Dangerous Person'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'TEST View'), findsOneWidget);

    await tester.tap(find.text('2').last); // gang member count
    await tester.pumpAndSettle();
    expect(find.text('TEST Gang Members'), findsOneWidget);
    expect(find.text('TEST Member A'), findsOneWidget);
    expect(find.text('TEST Member B'), findsOneWidget);

    Future<void> closeDialog() async {
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    }

    await closeDialog();

    // Accused cell -> every accused detail from the form setup
    await tester.tap(find.text('2. TEST Shyam'));
    await tester.pumpAndSettle();
    expect(find.text('TEST Accused Section'), findsOneWidget);
    expect(find.text('TEST PAN1'), findsOneWidget);
    await closeDialog();

    // Outcome cell -> only the outcome fields (not IO name)
    await tester.tap(find.text('TEST Granted (01/10/2026)'));
    await tester.pumpAndSettle();
    expect(find.text('TEST Outcome Field'), findsOneWidget);
    expect(find.text('TEST Revoked Field'), findsOneWidget);
    expect(find.text('TEST IO Field'), findsNothing);
    await closeDialog();

    // Category cell -> the category section's fields
    await tester.tap(find.text('TEST Dangerous Person'));
    await tester.pumpAndSettle();
    expect(find.text('TEST Category Field'), findsOneWidget);
    expect(find.text('TEST Other Field'), findsOneWidget);
    expect(find.text('TEST Outcome Field'), findsNothing);
  });
}
