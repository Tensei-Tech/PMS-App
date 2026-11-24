import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/theme_provider.dart';
import 'package:khakhi_diary/screens/itsso_hub_screen.dart';
import 'package:khakhi_diary/screens/victim_hub_screen.dart';
import 'package:khakhi_diary/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );

    ApiService.clientForTesting = MockClient((request) async {
      final url = request.url.toString();
      if (url.contains('victim')) {
        return http.Response(
          jsonEncode({
            'stats': {
              'total_victims': 5,
              'female': 3,
              'women': 2,
              'minor': 2,
              'male': 2,
            },
            'results': [
              {
                'id': 'v-101',
                'title': 'Test CAW Case',
                'case_number': 'CR-101',
                'module_key': 'crime_women',
                'status': 'Pending',
                'station_name': 'TUMSAR',
                'extra_fields': {
                  'victim_gender': 'Female',
                  'victim_age': 25,
                },
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      // Default response for ITSSO and others
      return http.Response(
        jsonEncode({
          'stats': {
            'total_cases': 3,
            'under_60_days': 2,
            'over_60_days': 1,
          },
          'results': [
            {
              'id': 'itsso-1',
              'title': 'Test POCSO Case',
              'case_number': 'CR-201',
              'module_key': 'pocso',
              'status': 'Pending',
              'station_name': 'Central Station',
              'assigned_officer': 'Inspector Kumar',
              'incident_date': '2024-01-15T00:00:00Z',
              'extra_fields': {
                'section_act': 'Section 64 BNS',
              },
            }
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  });

  tearDown(() {
    ApiService.clientForTesting = null;
  });

  Widget buildApp(Widget screen) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        home: screen,
      ),
    );
  }

  group('VictimHubScreen Widget Tests', () {
    testWidgets('renders properly on mobile without layout overflow',
        (tester) async {
      tester.view.physicalSize = const Size(380, 750);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          buildApp(const VictimHubScreen(stationName: 'Station 1')));
      await tester.pumpAndSettle();

      expect(find.byType(VictimHubScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('renders properly on desktop size without layout overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          buildApp(const VictimHubScreen(stationName: 'Station 1')));
      await tester.pumpAndSettle();

      expect(find.byType(VictimHubScreen), findsOneWidget);
    });
  });

  group('ItssoHubScreen Widget Tests', () {
    testWidgets('renders properly on mobile without layout overflow',
        (tester) async {
      tester.view.physicalSize = const Size(380, 750);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester
          .pumpWidget(buildApp(const ItssoHubScreen(stationName: 'Station 1')));
      await tester.pumpAndSettle();

      expect(find.byType(ItssoHubScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('renders properly on desktop size without layout overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester
          .pumpWidget(buildApp(const ItssoHubScreen(stationName: 'Station 1')));
      await tester.pumpAndSettle();

      expect(find.byType(ItssoHubScreen), findsOneWidget);
    });
  });
}
