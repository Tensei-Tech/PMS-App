// test/priority_2_tabs_test.dart
// Priority 2 tests: Verify Group 1, Group 2, and Standalone (all 26) tabs
// load from live backend and render on screen.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:khakhi_diary/providers/theme_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/settings_provider.dart';
import 'package:khakhi_diary/providers/case_provider.dart';
import 'package:khakhi_diary/providers/news_provider.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/screens/form_i_v_selection_screen.dart';
import 'package:khakhi_diary/screens/form_vi_selection_screen.dart';
import 'package:khakhi_diary/screens/standalone_selection_screen.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/services/api_config.dart';

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

  group('Priority 2: Group 1, Group 2, and Standalone Tabs API & On-Screen Verification', () {
    test('API Level: Verify endpoints return correct categories count and names', () async {
      final service = CaseService();

      // 1. Group 1: Part 1 to 5
      final g1Cats = await service.fetchGroupCategories(1);
      expect(g1Cats, isNotEmpty);
      final g1Names = g1Cats.map((c) => c['category_name']).toList();
      expect(g1Names, containsAll(['Murder', 'Attempt to Murder', 'Dacoity', 'Robbery', 'Theft']));
      debugPrint('Live Group 1 categories: ${g1Cats.length}');

      // 2. Group 2: Part 6
      final g2Cats = await service.fetchGroupCategories(2);
      expect(g2Cats.length, equals(9));
      final g2Names = g2Cats.map((c) => c['category_name']).toList();
      expect(g2Names, containsAll(['ST Drugs', 'Prohibition', 'Gambling', 'POCSO', 'NDPS', 'UAPA']));
      debugPrint('Live Group 2 categories: ${g2Cats.length}');

      // 3. Standalone: ALL 26 categories (group_id IS NULL)
      final standaloneCats = await service.fetchStandaloneCategories();
      expect(standaloneCats.length, equals(26));
      final standNames = standaloneCats.map((c) => c['category_name']).toList();
      expect(standNames, containsAll([
        'Suicide',
        'A.D.',
        'N.C.',
        'Theft',
        'Kidnapping',
        'Hurt',
        'Sand Theft',
        'Two/Four Wheeler Theft',
        'Missing',
        'Crime Against Women',
        'Accident',
        'Sec 156(3)/175(3)(BNSS)',
        'Coin',
        'ST Drugs',
        'Prohibition',
        'Gambling',
        'POCSO',
        'NDPS',
        'Gowans',
        'IT Act',
        'M.V Act',
        'UAPA',
      ]));
      debugPrint('Live Standalone categories: ${standaloneCats.length} (all 26 confirmed)');
    });

    testWidgets('On-Screen: StandaloneSelectionScreen renders ALL 26 tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => NewsProvider()),
            ChangeNotifierProvider(create: (_) => CaseProvider()),
            ...moduleProviders,
          ],
          child: const MaterialApp(
            home: StandaloneSelectionScreen(),
          ),
        ),
      );

      // Await live network call to fetch 26 standalone categories
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 1500));
      });
      await tester.pumpAndSettle();

      // Verify on screen: Header shows 26 tabs
      expect(find.textContaining('Total Standalone: 26 tabs'), findsOneWidget);

      // Verify all 26 genuine database standalone categories appear on screen
      const expected26 = [
        'A.D.',
        'Accident',
        'Coin',
        'Crime Against Women',
        'Death Due to Rash Driving',
        'Gambling',
        'Gowans',
        'Hurt',
        'IT Act',
        'Kidnapping',
        'M.V Act',
        'Missing',
        'N.C.',
        'NDPS',
        'Normal Accident',
        'Other Road Accident',
        'POCSO',
        'Prohibition',
        'Road Accident',
        'Sand Theft',
        'Sec 156(3)/175(3)(BNSS)',
        'ST Drugs',
        'Suicide',
        'Theft',
        'Two/Four Wheeler Theft',
        'UAPA',
      ];
      for (final catName in expected26) {
        expect(find.text(catName), findsOneWidget, reason: 'Expected $catName to appear on screen');
      }

      // Test search filtering on screen: type "Suicide"
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Suicide');
      await tester.pumpAndSettle();

      expect(find.textContaining('Total Standalone: 1 tabs'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Suicide'), findsOneWidget);
      expect(find.text('A.D.'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.textContaining('Total Standalone: 26 tabs'), findsOneWidget);

      // Drain pending network timeout timers
      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('On-Screen: FormIVSelectionScreen (Group 1) renders top-level categories dynamically', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => NewsProvider()),
            ChangeNotifierProvider(create: (_) => CaseProvider()),
            ...moduleProviders,
          ],
          child: const MaterialApp(
            home: FormIVSelectionScreen(mode: FormIVSelectionMode.browse),
          ),
        ),
      );

      // Await live network call to fetch Group 1 categories
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 1500));
      });
      await tester.pumpAndSettle();

      // Verify on screen: 28 types in header
      expect(find.textContaining('28 types'), findsOneWidget);

      // Verify Murder, Dacoity, Robbery render on screen
      expect(find.text('Murder'), findsOneWidget);
      expect(find.text('Attempt to Murder'), findsOneWidget);
      expect(find.text('Dacoity'), findsOneWidget);
      expect(find.text('Robbery'), findsOneWidget);

      // Drain pending network timeout timers
      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('On-Screen: FormVISelectionScreen (Group 2) renders Part 6 categories dynamically', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => NewsProvider()),
            ChangeNotifierProvider(create: (_) => CaseProvider()),
            ...moduleProviders,
          ],
          child: const MaterialApp(
            home: FormVISelectionScreen(mode: FormVISelectionMode.browse),
          ),
        ),
      );

      // Await live network call to fetch Group 2 categories
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 1500));
      });
      await tester.pumpAndSettle();

      // Verify on screen: 9 types in header
      expect(find.textContaining('9 types'), findsOneWidget);

      // Verify ST Drugs, Prohibition, Gambling, POCSO, NDPS render on screen
      expect(find.text('ST Drugs'), findsOneWidget);
      expect(find.text('Prohibition'), findsOneWidget);
      expect(find.text('Gambling'), findsOneWidget);
      expect(find.text('POCSO'), findsOneWidget);
      expect(find.text('NDPS'), findsOneWidget);

      // Drain pending network timeout timers
      await tester.pump(const Duration(seconds: 35));
    });
  });
}
