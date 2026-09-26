// test/nested_sub_tabs_test.dart
// Verification test for nested category sub-tabs drilldown via CategoryNavigationHelper
// and FormIVSelectionScreen.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:khakhi_diary/providers/theme_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/settings_provider.dart';
import 'package:khakhi_diary/providers/case_provider.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/screens/form_i_v_selection_screen.dart';
import 'package:khakhi_diary/services/api_config.dart';
import 'package:khakhi_diary/utils/category_navigation_helper.dart';

class RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    HttpOverrides.global = RealHttpOverrides();
    ApiConfig.setCustomBaseUrl('http://127.0.0.1:8001/api');
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CaseProvider()),
        ...moduleProviders,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Nested Sub-Tabs Navigation & Hierarchy Verification', () {
    test('CategoryNavigationHelper correctly discovers children hierarchy for Accident and leaves', () async {
      // 1. Accident -> Normal Accident & Road Accident
      final accidentChildren = await CategoryNavigationHelper.getChildren('Accident');
      expect(accidentChildren, isNotEmpty);
      final accidentNames = accidentChildren.map((c) => c['category_name']).toList();
      expect(accidentNames, containsAll(['Normal Accident', 'Road Accident']));

      // 2. Road Accident -> Death Due to Rash Driving & Other Road Accident
      final roadAccidentChildren = await CategoryNavigationHelper.getChildren('Road Accident');
      expect(roadAccidentChildren, isNotEmpty);
      final roadNames = roadAccidentChildren.map((c) => c['category_name']).toList();
      expect(roadNames, containsAll(['Death Due to Rash Driving', 'Other Road Accident']));

      // 3. Theft -> leaf category with no children
      final theftChildren = await CategoryNavigationHelper.getChildren('Theft');
      expect(theftChildren, isEmpty);
    });

    testWidgets('FormIVSelectionScreen with initialCategory="Accident" displays sub-tiles and supports drill-down', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        buildTestApp(
          const FormIVSelectionScreen(
            initialCategory: 'Accident',
            customTitle: 'Accident',
            mode: FormIVSelectionMode.browse,
          ),
        ),
      );

      // Wait for async children loading
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify Accident title and sub-tiles are displayed
      expect(find.text('Normal Accident'), findsOneWidget);
      expect(find.text('Road Accident'), findsOneWidget);

      // Drill down into Road Accident
      await tester.tap(find.text('Road Accident'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify nested sub-tiles under Road Accident
      expect(find.text('Death Due to Rash Driving'), findsOneWidget);
      expect(find.text('Other Road Accident'), findsOneWidget);

      // Verify breadcrumb shows Road Accident
      expect(find.text('Road Accident'), findsWidgets);

      // Back navigation returns to parent sub-tiles
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify we are back to Normal Accident and Road Accident
      expect(find.text('Normal Accident'), findsOneWidget);
      expect(find.text('Road Accident'), findsOneWidget);
    });
  });
}
