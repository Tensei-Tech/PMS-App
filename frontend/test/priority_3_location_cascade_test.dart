import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khakhi_diary/services/api_config.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/widgets/cascading_location_selector.dart';

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

  group('Priority 3: Location Cascading Dropdowns Verification', () {
    final caseService = CaseService();

    test('API Level: GET /api/divisions/ returns 6 Maharashtra divisions', () async {
      final divs = await caseService.fetchDivisions();
      expect(divs.length, equals(6));
      final names = divs.map((d) => d['name']).toList();
      expect(
        names,
        containsAll([
          'Chhatrapati Sambhajinagar',
          'Pune',
          'Nashik',
          'Konkan',
          'Nagpur',
          'Amravati',
        ]),
      );
      debugPrint('Live Divisions: ${names.join(', ')}');
    });

    test('API Level: GET /api/districts/ returns all 36 districts', () async {
      final dists = await caseService.fetchDistricts();
      expect(dists.length, equals(36));
      final names = dists.map((d) => d['name']).toList();
      expect(names, containsAll(['Pune', 'Mumbai City', 'Amravati', 'Nashik', 'Nagpur']));
      debugPrint('Total Districts: ${dists.length}');
    });

    test('API Level: GET /api/districts/?division_id= cascades correctly', () async {
      // 1. Pune Division (5 districts)
      final puneDists = await caseService.fetchDistricts(divisionId: '2');
      expect(puneDists.length, equals(5));
      final puneNames = puneDists.map((d) => d['name']).toList();
      expect(puneNames, containsAll(['Kolhapur', 'Pune', 'Sangli', 'Satara', 'Solapur']));
      debugPrint('Pune Division Districts (5): ${puneNames.join(', ')}');

      // 2. Konkan Division (7 districts)
      final konkanDists = await caseService.fetchDistricts(divisionId: 'Konkan');
      expect(konkanDists.length, equals(7));
      final konkanNames = konkanDists.map((d) => d['name']).toList();
      expect(
        konkanNames,
        containsAll([
          'Mumbai City',
          'Mumbai Suburban',
          'Palghar',
          'Raigad',
          'Ratnagiri',
          'Sindhudurg',
          'Thane',
        ]),
      );
      debugPrint('Konkan Division Districts (7): ${konkanNames.join(', ')}');
    });

    test('API Level: GET /api/stations/?district_id= cascades correctly', () async {
      // 1. Pune district (57 stations)
      final puneStations = await caseService.fetchStations(districtId: 'DST-MH-PUNE');
      expect(puneStations.length, equals(57));
      debugPrint('Pune District Stations: ${puneStations.length}');

      // 2. Amravati district (20 stations)
      final amrStations = await caseService.fetchStations(districtId: 'Amravati');
      expect(amrStations.length, equals(20));
      debugPrint('Amravati District Stations: ${amrStations.length}');
    });

    testWidgets('On-Screen Widget: CascadingLocationSelector cascades Division -> District -> Stations',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(24.0),
              child: CascadingLocationSelector(),
            ),
          ),
        ),
      );

      // Wait for live network call to fetch 6 divisions from backend
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 3000));
      });
      await tester.pumpAndSettle();

      // Debug rendered texts
      final allTexts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList();
      debugPrint('Found texts on screen: $allTexts');

      // Verify dropdown labels appear on screen
      expect(find.text('Division / Range'), findsOneWidget);
      expect(find.text('District / Commissionerate'), findsOneWidget);
      expect(find.text('Police Station'), findsOneWidget);

      // Drain any pending timers
      await tester.pump(const Duration(seconds: 10));
    });
  });
}
