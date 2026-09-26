import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/providers/theme_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/settings_provider.dart';
import 'package:khakhi_diary/providers/case_provider.dart';
import 'package:khakhi_diary/providers/news_provider.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/widgets/common_form/common_form.dart';
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
    setupFirebaseCoreMocks();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: '1:1:android:test',
          messagingSenderId: '1',
          projectId: 'test-project',
          storageBucket: 'test-project.appspot.com',
        ),
      );
    } catch (_) {}
  });

  group('Priority 1: Dynamic Form Engine Tests', () {
    test('3a & 3b Backend API Reshaping: Murder vs Plain vs Murder+Hurt', () async {
      final service = CaseService();

      // 1. Plain tab (Robbery / Category 4): exactly 105 baseline fields, 0 extra
      final plainDef = await service.fetchFormDefinition('Robbery', forceRefresh: true);
      expect(plainDef, isNotNull);
      final plainFields = (plainDef!['fields'] as List);
      final plainExtras = plainFields.where((f) => f['field_source'] != 'common').toList();
      expect(plainFields.length, equals(105));
      expect(plainExtras.isEmpty, isTrue);
      expect(plainFields.map((f) => f['field_label']), contains('Object Name'));

      // Verify Unidentified Accused fields and order
      final unidFields = plainFields.where((f) => f['section'] == 'Unidentified Accused').toList();
      expect(unidFields.length, equals(8));
      expect(unidFields.map((f) => f['field_label']).toList(), equals([
        'Approximate Age',
        'Gender',
        'Skin Colour',
        'Possible Occupation',
        'Identification Mark',
        'Height',
        'Address',
        'Description',
      ]));

      // Verify Arrest fields and order (Arrested Person Name first)
      final arrestFields = plainFields.where((f) => f['section'] == 'Arrest').toList();
      expect(arrestFields.length, equals(11));
      expect(arrestFields.first['field_label'], equals('Arrested Person Name'));
      expect(arrestFields.first['field_key'], equals('arrested_person_name'));

      // 2. Murder (Category 1): 111 fields total (105 baseline + 6 extra Murder fields)
      final murderDef = await service.fetchFormDefinition('Murder', forceRefresh: true);
      expect(murderDef, isNotNull);
      final murderFields = (murderDef!['fields'] as List);
      final murderExtras = murderFields.where((f) => f['field_source'] != 'common').toList();
      expect(murderFields.length, equals(111));
      expect(murderExtras.length, equals(6));
      final murderLabels = murderExtras.map((f) => f['field_label']).toList();
      expect(murderLabels, containsAll([
        'Deceased Name',
        'Deceased Age',
        'Deceased Gender',
        'Inquest Panchanama Details',
        'Post-Mortem Report Date',
        'Cause of Death',
      ]));

      // 3. Murder with Hurt charge (BNS 115): 115 fields (105 baseline + 6 Murder + 4 Hurt extra fields)
      final murderHurtDef = await service.fetchFormDefinition(
        'Murder',
        sections: ['115'],
        forceRefresh: true,
      );
      expect(murderHurtDef, isNotNull);
      final mhFields = (murderHurtDef!['fields'] as List);
      final mhExtras = mhFields.where((f) => f['field_source'] != 'common').toList();
      expect(mhFields.length, equals(115));
      expect(mhExtras.length, equals(10));
      final mhLabels = mhExtras.map((f) => f['field_label']).toList();
      expect(mhLabels, containsAll([
        'Deceased Name',
        'Deceased Age',
        'Deceased Gender',
        'Inquest Panchanama Details',
        'Post-Mortem Report Date',
        'Cause of Death',
        'Injured Person Name',
        'Injury Type / Severity',
        'Medical Certificate Date',
        'Hospital Name',
      ]));
    });

    testWidgets('3a & 3c On-Screen: Murder renders 6 extra fields, Hurt unlocks 4 more without data loss', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final formKey = GlobalKey<CommonFormState>();

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
          child: MaterialApp(
            home: Scaffold(
              body: CommonForm(
                key: formKey,
                moduleKey: 'murder',
                moduleLabel: 'Murder',
              ),
            ),
          ),
        ),
      );

      // Await real async HTTP network call to load Murder form definition
      await tester.runAsync(() async {
        await formKey.currentState?.loadFormDefinitionForTest([]);
      });
      await tester.pump();

      // Test 3a: Verify Murder card and extra fields appear on screen
      expect(find.textContaining('Special Section / Template Details (6)'), findsOneWidget);
      expect(find.textContaining('Deceased Name'), findsOneWidget);
      expect(find.textContaining('Deceased Age'), findsOneWidget);
      expect(find.textContaining('Inquest Panchanama Details'), findsOneWidget);
      expect(find.textContaining('Cause of Death'), findsOneWidget);

      // Type data into 'Deceased Name' to test preservation
      final deceasedNameField = find.widgetWithText(TextFormField, 'Deceased Name');
      expect(deceasedNameField, findsOneWidget);
      await tester.enterText(deceasedNameField, 'Suresh Patil');
      await tester.pump();
      expect(find.text('Suresh Patil'), findsOneWidget);

      // Test 3c: Add Hurt charge (BNS 115) via real async HTTP request
      await tester.runAsync(() async {
        await formKey.currentState?.loadFormDefinitionForTest(['115']);
      });
      await tester.pump();

      // Verify card title updated to 10 fields
      expect(find.textContaining('Special Section / Template Details (10)'), findsOneWidget);

      // Verify newly unlocked Hurt fields appear on screen
      expect(find.textContaining('Injured Person Name'), findsOneWidget);
      expect(find.textContaining('Injury Type / Severity'), findsOneWidget);
      expect(find.textContaining('Hospital Name'), findsOneWidget);

      // Verify previous user input 'Suresh Patil' is STILL on screen!
      expect(find.text('Suresh Patil'), findsOneWidget);

      // Drain pending network timeout timers
      await tester.pump(const Duration(seconds: 35));
    });
  });
}
