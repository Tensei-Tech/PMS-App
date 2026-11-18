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
import 'package:khakhi_diary/screens/dar_hub_screen.dart';
import 'package:khakhi_diary/screens/irad_hub_screen.dart';
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
      return http.Response(
        jsonEncode({
          'stats': {
            'total_dar': 2,
            'dar_filled': 0,
            'dar_pending': 2,
            'total_irad': 2,
            'irad_filled': 0,
            'irad_pending': 2,
          },
          'results': [],
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

  testWidgets(
      'DARHubScreen summary cards appear in a single Row on mobile without wrapping',
      (tester) async {
    tester.view.physicalSize = const Size(380, 750);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(const DarHubScreen()));
    await tester.pumpAndSettle();

    // Verify all 3 cards are present with compact labels
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Filled'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    // Verify that the metric cards are laid out in a single Row (same vertical Y position)
    final totalPos = tester.getTopLeft(find.text('Total'));
    final filledPos = tester.getTopLeft(find.text('Filled'));
    final pendingPos = tester.getTopLeft(find.text('Pending'));

    expect(totalPos.dy, equals(filledPos.dy));
    expect(filledPos.dy, equals(pendingPos.dy));
  });

  testWidgets('DARHubScreen summary cards appear in a single Row on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(const DarHubScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Total DAR'), findsOneWidget);
    expect(find.text('DAR Form Filled'), findsOneWidget);
    expect(find.text('DAR Form Pending'), findsOneWidget);

    final totalPos = tester.getTopLeft(find.text('Total DAR'));
    final filledPos = tester.getTopLeft(find.text('DAR Form Filled'));
    final pendingPos = tester.getTopLeft(find.text('DAR Form Pending'));

    expect(totalPos.dy, equals(filledPos.dy));
    expect(filledPos.dy, equals(pendingPos.dy));
  });

  testWidgets(
      'IRADHubScreen summary cards appear in a single Row on mobile without wrapping',
      (tester) async {
    tester.view.physicalSize = const Size(380, 750);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(const IradHubScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Filled'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    final totalPos = tester.getTopLeft(find.text('Total'));
    final filledPos = tester.getTopLeft(find.text('Filled'));
    final pendingPos = tester.getTopLeft(find.text('Pending'));

    expect(totalPos.dy, equals(filledPos.dy));
    expect(filledPos.dy, equals(pendingPos.dy));
  });

  testWidgets('IRADHubScreen summary cards appear in a single Row on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(const IradHubScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Total IRAD'), findsOneWidget);
    expect(find.text('IRAD Form Filled'), findsOneWidget);
    expect(find.text('IRAD Form Pending'), findsOneWidget);

    final totalPos = tester.getTopLeft(find.text('Total IRAD'));
    final filledPos = tester.getTopLeft(find.text('IRAD Form Filled'));
    final pendingPos = tester.getTopLeft(find.text('IRAD Form Pending'));

    expect(totalPos.dy, equals(filledPos.dy));
    expect(filledPos.dy, equals(pendingPos.dy));
  });
}
