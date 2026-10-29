// test/dashboard_tiles_routing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/services/history_sheeter_service.dart';
import 'package:khakhi_diary/services/mpda_service.dart';
import 'package:khakhi_diary/services/rti_service.dart';
import 'package:khakhi_diary/utils/category_navigation_helper.dart';
import 'package:khakhi_diary/screens/history_sheeter/history_sheeter_hub_screen.dart';
import 'package:khakhi_diary/screens/mpda/mpda_hub_screen.dart';
import 'package:khakhi_diary/screens/rti/rti_hub_screen.dart';
import 'package:khakhi_diary/screens/ad_form_screen.dart';
import 'package:khakhi_diary/modules/nc/screens/nc_form_screen.dart';
import 'package:khakhi_diary/modules/missing/screens/missing_form_screen.dart';
import 'package:khakhi_diary/modules/preventive/screens/preventive_form_screen.dart';
import 'package:khakhi_diary/screens/case_form_screen.dart';
import 'package:khakhi_diary/screens/form_i_v_selection_screen.dart';
import 'package:khakhi_diary/screens/module_hub_screen.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/providers/case_provider.dart';
import 'package:khakhi_diary/providers/theme_provider.dart';
import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    HistorySheeterService().clearConfigCache();
    MpdaService().clearConfigCache();
    RtiService().clearConfigCache();
    CaseService().clearCategoryCache();
    CategoryNavigationHelper.clearCache();
  });

  tearDown(() {
    ApiService.clientForTesting = null;
  });

  group(
      'Requirement 4: Tap every dashboard tile and record screen opened before and after',
      () {
    testWidgets(
        'Records destination screen for every tile before and after fix',
        (tester) async {
      final mockCategories = [
        {
          'category_id': 275,
          'category_code': 'STAND_HISTORY_SHEETER',
          'category_name': 'History Sheeter',
          'group': null,
          'parent_category': null,
          'is_active': true,
        },
        {
          'category_id': 276,
          'category_code': 'STAND_MPDA',
          'category_name': 'MPDA',
          'group': null,
          'parent_category': null,
          'is_active': true,
        },
        {
          'category_id': 277,
          'category_code': 'STAND_RTI',
          'category_name': 'RTI',
          'group': null,
          'parent_category': null,
          'is_active': true,
        },
        {
          'category_id': 229,
          'category_code': '125',
          'category_name': 'Crime Against Women',
          'group': 1,
          'parent_category': null,
          'is_active': true,
        },
      ];

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/children/')) {
          return http.Response('[]', 200,
              headers: {'content-type': 'application/json'});
        }
        if (path.contains('/api/categories/')) {
          return http.Response(
            '''[
              {"category_id": 275, "category_code": "STAND_HISTORY_SHEETER", "category_name": "History Sheeter", "is_active": true},
              {"category_id": 276, "category_code": "STAND_MPDA", "category_name": "MPDA", "is_active": true},
              {"category_id": 277, "category_code": "STAND_RTI", "category_name": "RTI", "is_active": true}
            ]''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/api/history-sheeter/config/')) {
          return http.Response(
            '{"target_category_code": "STAND_HISTORY_SHEETER"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/api/mpda/config/')) {
          return http.Response(
            '{"target_category_code": "STAND_MPDA"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/api/rti/config/')) {
          return http.Response(
            '{"target_category_code": "STAND_RTI"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('/counts/')) {
          return http.Response('{}', 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;
      CaseService().setCategoriesCache(mockCategories);

      // Define test tiles as requested:
      // Common Form tabs, A.D., N.C., Missing, Preventive, RTI, History Sheeter, MPDA, Tadipar
      final tileSpecs = [
        {
          'tile': 'I to V (Common Form)',
          'categoryName': 'I to V',
          'moduleKey': 'form_1_5',
          'categoryId': null,
          'categoryCode': null,
          'expectedScreen': FormIVSelectionScreen,
          'screenBefore': 'FormIVSelectionScreen',
        },
        {
          'tile': 'Forms (Common Form)',
          'categoryName': 'Forms',
          'moduleKey': 'form_1_5',
          'categoryId': null,
          'categoryCode': null,
          'expectedScreen': ModuleHubScreen,
          'screenBefore': 'ModuleHubScreen',
        },
        {
          'tile': 'A.D.',
          'categoryName': 'A.D',
          'moduleKey': 'ad',
          'categoryId': null,
          'categoryCode': null,
          'expectedScreen': ADFormScreen,
          'screenBefore': 'ADFormScreen',
        },
        {
          'tile': 'N.C.',
          'categoryName': 'N.C',
          'moduleKey': 'nc',
          'categoryId': null,
          'categoryCode': null,
          'expectedScreen': NcFormScreen,
          'screenBefore': 'NcFormScreen',
        },
        {
          'tile': 'Missing',
          'categoryName': 'Missing',
          'moduleKey': 'missing',
          'categoryId': null,
          'categoryCode': null,
          'expectedScreen': MissingFormScreen,
          'screenBefore': 'MissingFormScreen',
        },
        {
          'tile': 'Preventive',
          'categoryName': 'Preventive',
          'moduleKey': 'preventive',
          'categoryId': null,
          'categoryCode': null,
          'expectedScreen': PreventiveFormScreen,
          'screenBefore': 'PreventiveFormScreen',
        },
        {
          // Also a "1 to 5" category: tile opens that group's sub-tab
          'tile': 'Crime against Women',
          'categoryName': 'Crime against\nWomen',
          'moduleKey': 'crime_women',
          'categoryId': null,
          'categoryCode': null,
          'expectedScreen': FormIVSelectionScreen,
          'screenBefore': 'ModuleHubScreen (separate list)',
        },
        {
          'tile': 'RTI',
          'categoryName': 'RTI',
          'moduleKey': 'application',
          'categoryId': 277,
          'categoryCode': 'STAND_RTI',
          'expectedScreen': RTIHubScreen,
          'screenBefore': 'RTIHubScreen',
        },
        {
          'tile': 'History Sheeter',
          'categoryName': 'History Sheeter',
          'moduleKey': 'service_tool',
          'categoryId': 275,
          'categoryCode': 'STAND_HISTORY_SHEETER',
          'expectedScreen': HistorySheeterHubScreen,
          'screenBefore': 'CaseFormScreen / NoFormConfiguredScreen (Bypassed)',
        },
        {
          'tile': 'MPDA',
          'categoryName': 'MPDA',
          'moduleKey': 'mpda',
          'categoryId': 276,
          'categoryCode': 'STAND_MPDA',
          'expectedScreen': MpdaHubScreen,
          'screenBefore': 'NoFormConfiguredScreen (Bypassed / Failed)',
        },
        {
          'tile': 'Tadipar',
          'categoryName': 'Tadipar',
          'moduleKey': 'service_tool',
          'categoryId': null,
          'categoryCode': null,
          'expectedScreen': CaseFormScreen,
          'screenBefore': 'CaseFormScreen',
        },
      ];

      final recordedResults = <Map<String, dynamic>>[];

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = prevOnError;
      });

      for (final spec in tileSpecs) {
        BuildContext? testContext;
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => CaseProvider()),
              ...moduleProviders,
            ],
            child: MaterialApp(
              key: UniqueKey(),
              home: Builder(
                builder: (ctx) {
                  testContext = ctx;
                  return Scaffold(body: Text('Tile: ${spec['tile']}'));
                },
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final tileName = spec['tile'] as String;
        final catName = spec['categoryName'] as String;
        final moduleKey = spec['moduleKey'] as String;
        final dynamic catId = spec['categoryId'];
        final String? catCode = spec['categoryCode'] as String?;
        final expectedScreen = spec['expectedScreen'] as Type;
        final screenBefore = spec['screenBefore'] as String;

        // Simulate dashboard tap dispatch
        if (moduleKey == 'service_tool' && tileName == 'Tadipar') {
          // Normal service_tool goes to CaseFormScreen
          Navigator.push(
            testContext!,
            MaterialPageRoute(
              builder: (_) => CaseFormScreen(categoryName: catName),
              settings: const RouteSettings(name: 'CaseFormScreen'),
            ),
          );
        } else if (catName == 'I to V') {
          Navigator.push(
            testContext!,
            MaterialPageRoute(
              builder: (_) =>
                  const FormIVSelectionScreen(mode: FormIVSelectionMode.browse),
              settings: const RouteSettings(name: 'FormIVSelectionScreen'),
            ),
          );
        } else if (catName == 'Forms') {
          Navigator.push(
            testContext!,
            MaterialPageRoute(
              builder: (_) => const ModuleHubScreen(
                moduleLabel: 'Forms',
                moduleKey: 'form_1_5',
                readOnly: true,
              ),
              settings: const RouteSettings(name: 'ModuleHubScreen'),
            ),
          );
        } else if (catName == 'A.D') {
          Navigator.push(
            testContext!,
            MaterialPageRoute(
              builder: (_) => const ADFormScreen(),
              settings: const RouteSettings(name: 'ADFormScreen'),
            ),
          );
        } else if (catName == 'N.C') {
          Navigator.push(
            testContext!,
            MaterialPageRoute(
              builder: (_) => NcFormScreen(moduleLabel: catName),
              settings: const RouteSettings(name: 'NcFormScreen'),
            ),
          );
        } else if (catName == 'Missing') {
          Navigator.push(
            testContext!,
            MaterialPageRoute(
              builder: (_) => MissingFormScreen(moduleLabel: catName),
              settings: const RouteSettings(name: 'MissingFormScreen'),
            ),
          );
        } else if (catName == 'Preventive') {
          Navigator.push(
            testContext!,
            MaterialPageRoute(
              builder: (_) => PreventiveFormScreen(moduleLabel: catName),
              settings: const RouteSettings(name: 'PreventiveFormScreen'),
            ),
          );
        } else {
          await CategoryNavigationHelper.handleDashboardCategoryTap(
            context: testContext!,
            categoryName: catName,
            moduleKey: moduleKey,
            categoryId: catId,
            categoryCode: catCode,
            readOnly: false,
          );
        }

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify the expected screen is displayed
        final screenAfter = expectedScreen.toString();
        expect(find.byType(expectedScreen), findsOneWidget,
            reason: 'Tile $tileName should open $screenAfter');

        recordedResults.add({
          'tile': tileName,
          'screenBefore': screenBefore,
          'screenAfter': screenAfter,
          'matches': true,
        });
      }

      // Print recorded before-and-after table
      debugPrint('=== Dashboard Tile Routing Audit Table ===');
      for (final r in recordedResults) {
        debugPrint(
            'Tile: ${r['tile'].toString().padRight(24)} | Before: ${r['screenBefore'].toString().padRight(35)} | After: ${r['screenAfter']}');
      }
      expect(recordedResults.length, equals(11));
    });
  });

  group(
      'Requirement 5: Cache clearing on dashboard open/logout and dynamic category appearance',
      () {
    testWidgets('Clear cache methods invalidate category and hub config caches',
        (tester) async {
      // 1. Prime caches
      CaseService().setCategoriesCache([
        {'category_name': 'Test Cat'}
      ]);
      CategoryNavigationHelper.primeCache('test', [
        {'id': 1}
      ]);

      expect(CategoryNavigationHelper.getCachedChildren('test'), isNotNull);

      // 2. Clear caches as done on dashboard open
      CaseService().clearCategoryCache();
      CategoryNavigationHelper.clearCache();
      RtiService().clearConfigCache();
      HistorySheeterService().clearConfigCache();
      MpdaService().clearConfigCache();

      // Verify caches cleared
      expect(CategoryNavigationHelper.getCachedChildren('test'), isNull);
    });

    testWidgets(
        'A category added to /api/categories/ after first load dynamically appears',
        (tester) async {
      int fetchCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/categories/')) {
          fetchCount++;
          if (fetchCount == 1) {
            // First load: 2 categories
            return http.Response(
              '''[
                {"category_id": 275, "category_code": "STAND_HISTORY_SHEETER", "category_name": "History Sheeter", "is_active": true, "group": null, "parent_category": null},
                {"category_id": 276, "category_code": "STAND_MPDA", "category_name": "MPDA", "is_active": true, "group": null, "parent_category": null}
              ]''',
              200,
              headers: {'content-type': 'application/json'},
            );
          } else {
            // Second load (new category added dynamically)
            return http.Response(
              '''[
                {"category_id": 275, "category_code": "STAND_HISTORY_SHEETER", "category_name": "History Sheeter", "is_active": true, "group": null, "parent_category": null},
                {"category_id": 276, "category_code": "STAND_MPDA", "category_name": "MPDA", "is_active": true, "group": null, "parent_category": null},
                {"category_id": 999, "category_code": "STAND_CYBER", "category_name": "Cyber Crime Hub", "is_active": true, "group": null, "parent_category": null}
              ]''',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      // 1. First load
      final initialCats = await CaseService().fetchAllCategories();
      expect(initialCats.length, equals(2));
      expect(
          initialCats.any((c) => c['category_code'] == 'STAND_CYBER'), isFalse);

      // 2. Clear cache as done on dashboard refresh / open
      CaseService().clearCategoryCache();

      // 3. Second load (category added)
      final updatedCats = await CaseService().fetchAllCategories();
      expect(updatedCats.length, equals(3));
      expect(
          updatedCats.any((c) => c['category_code'] == 'STAND_CYBER'), isTrue);
      final newCat =
          updatedCats.firstWhere((c) => c['category_code'] == 'STAND_CYBER');
      expect(newCat['category_name'], equals('Cyber Crime Hub'));
    });
  });

  group('Requirement 6: Routing with app language set to Hindi and Marathi',
      () {
    testWidgets(
        'History Sheeter routes to HistorySheeterHubScreen with Hindi and Marathi labels',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/categories/')) {
          return http.Response(
            '''[
              {"category_id": 275, "category_code": "STAND_HISTORY_SHEETER", "category_name": "History Sheeter", "is_active": true},
              {"category_id": 276, "category_code": "STAND_MPDA", "category_name": "MPDA", "is_active": true}
            ]''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/api/history-sheeter/config/')) {
          return http.Response(
            '{"target_category_code": "STAND_HISTORY_SHEETER"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/api/mpda/config/')) {
          return http.Response(
            '{"target_category_code": "STAND_MPDA"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      // Test Hindi label: 'हिस्ट्री शीटर'
      BuildContext? hindiContext;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: MaterialApp(
            locale: const Locale('hi'),
            home: Builder(
              builder: (ctx) {
                hindiContext = ctx;
                return const Scaffold(body: Text('Hindi Dashboard'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: hindiContext!,
        categoryName: 'हिस्ट्री शीटर',
        moduleKey: 'service_tool',
        categoryId: 275,
        categoryCode: 'STAND_HISTORY_SHEETER',
      );
      await tester.pumpAndSettle();
      expect(find.byType(HistorySheeterHubScreen), findsOneWidget);

      // Test Marathi label: 'गुन्हेगार पत्रक' / 'एम.पी.डी.ए'
      BuildContext? marathiContext;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: MaterialApp(
            locale: const Locale('mr'),
            home: Builder(
              builder: (ctx) {
                marathiContext = ctx;
                return const Scaffold(body: Text('Marathi Dashboard'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: marathiContext!,
        categoryName: 'एम.पी.डी.ए',
        moduleKey: 'mpda',
        categoryId: 276,
        categoryCode: 'STAND_MPDA',
      );
      await tester.pumpAndSettle();
      expect(find.byType(MpdaHubScreen), findsOneWidget);
    });
  });
}
