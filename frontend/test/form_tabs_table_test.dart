import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/case_provider.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/providers/settings_provider.dart';
import 'package:khakhi_diary/providers/theme_provider.dart';
import 'package:khakhi_diary/screens/form_i_v_selection_screen.dart';
import 'package:khakhi_diary/screens/form_vi_selection_screen.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'utils/mock_api_client.dart';

/// "1 to 5" and Part 6 show exactly the tabs of the form_1_5_tabs /
/// form_6_tabs tables, in their order.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    ApiService.clientForTesting = createMockApiClient();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });
  tearDownAll(() {
    ApiService.clientForTesting = null;
    CaseService().clearCategoryCache();
  });

  Widget app(Widget home) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => CaseProvider()),
          ...moduleProviders,
        ],
        child: MaterialApp(home: home),
      );

  Future<void> show(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(home));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  List<Map<String, dynamic>> rows(List<String> names) => [
        for (final n in names) {'tab_name': n}
      ];

  testWidgets('"1 to 5" shows the form_1_5_tabs rows only', (tester) async {
    // "Missing" was on the app's hidden list; the table now decides
    CaseService().setFormTabsCache('1_5', rows(['Theft', 'Murder', 'Missing']));
    await show(
        tester, const FormIVSelectionScreen(mode: FormIVSelectionMode.browse));
    expect(find.text('Theft'), findsOneWidget);
    expect(find.text('Murder'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
    expect(find.text('Robbery'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Theft')).dx,
      lessThan(tester.getTopLeft(find.text('Murder')).dx),
    );
  });

  testWidgets('A tab shows its own name and lists its linked category',
      (tester) async {
    CaseService().setFormTabsCache('1_5', [
      {'tab_name': 'Killings', 'category_name': 'Murder'},
    ]);
    await show(
        tester, const FormIVSelectionScreen(mode: FormIVSelectionMode.browse));
    expect(find.text('Killings'), findsOneWidget);
    expect(find.text('Murder'), findsNothing);
    expect(CaseService.formTabCategory({'tab_name': 'Killings'}), 'Killings');
    expect(
        CaseService.formTabCategory(
            {'tab_name': 'Killings', 'category_name': 'Murder'}),
        'Murder');
  });

  testWidgets('Part 6 shows the form_6_tabs rows only', (tester) async {
    CaseService().setFormTabsCache('6', rows(['NDPS', 'POCSO']));
    await show(
        tester, const FormVISelectionScreen(mode: FormVISelectionMode.browse));
    expect(find.text('NDPS'), findsOneWidget);
    expect(find.text('POCSO'), findsOneWidget);
    expect(find.text('Gambling'), findsNothing);
  });
}
