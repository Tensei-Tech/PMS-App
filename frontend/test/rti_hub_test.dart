import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/services/rti_service.dart';
import 'package:khakhi_diary/screens/rti/rti_hub_screen.dart';
import 'package:khakhi_diary/screens/module_hub_screen.dart';
import 'package:khakhi_diary/screens/no_form_configured_screen.dart';
import 'package:khakhi_diary/utils/category_navigation_helper.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    RtiService().clearCache();
    CaseService().clearCache();
  });

  group('RTI Hub Screen & Entry Point Navigation Tests', () {
    testWidgets('RTIHubScreen renders sub-tabs, counts, action buttons, and empty state from config (No Delete button)', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/rti/config/')) {
          return http.Response('''{
            "target_category_code": "STAND_RTI",
            "sub_tab_labels": {"all": "Total RTI", "pending": "Pending RTI", "disposal": "Resolved RTI"},
            "row_action_labels": {"edit": "Edit Application", "view": "View Application", "pdf": "Print PDF"},
            "add_button_label": "New RTI",
            "serial_label": "Serial No.",
            "empty_list_message": "No applications stored yet",
            "no_form_message": "No form configured",
            "page_size": 20,
            "limits": {"due_days": 30}
          }''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/counts/')) {
          return http.Response('''{"total": 5, "pending": 3, "disposal": 2}''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/')) {
          return http.Response('''{"count": 0, "page": 1, "page_size": 20, "results": []}''', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: const MaterialApp(
            home: RTIHubScreen(
              categoryName: 'Right to Information',
              categoryCode: 'STAND_RTI',
              moduleKey: 'standalone',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify custom sub-tab labels from config
      expect(find.text('Total RTI'), findsOneWidget);
      expect(find.text('Pending RTI'), findsOneWidget);
      expect(find.text('Resolved RTI'), findsOneWidget);

      // Verify custom Add button label from config
      expect(find.text('New RTI'), findsOneWidget);

      // Verify empty list message from config
      expect(find.text('No applications stored yet'), findsOneWidget);

      // Rule: No RTI screen has a Delete button
      expect(find.text('Delete'), findsNothing);

      ApiService.clientForTesting = null;
    });

    testWidgets('Unlinked Application tile with no DB category row opens NoFormConfiguredScreen (NO Add, NO list, NO counts, NO Delete, NO ModuleHubScreen)', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/categories/')) {
          return http.Response('''[
            {"category_id": 1, "category_name": "Theft", "category_code": "STAND_THEFT"}
          ]''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/config/')) {
          return http.Response('''{"target_category_code": "STAND_RTI"}''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/children/')) {
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      late BuildContext testContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Scaffold(body: Text('Home'));
              },
            ),
          ),
        ),
      );

      // Tap Application category tile (no DB category row)
      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: testContext,
        categoryName: 'Application',
        moduleKey: 'application',
        categoryCode: null,
      );

      await tester.pumpAndSettle();

      // Must open NoFormConfiguredScreen
      expect(find.byType(NoFormConfiguredScreen), findsOneWidget);
      expect(find.text('No form configured for this tab'), findsOneWidget);

      // Must NOT show Add button, list, counts, Delete button, or ModuleHubScreen
      expect(find.text('+ Add Case'), findsNothing);
      expect(find.text('Total Cases'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.byType(ModuleHubScreen), findsNothing);
      expect(find.byType(RTIHubScreen), findsNothing);

      ApiService.clientForTesting = null;
    });

    testWidgets('Entry Point 1 (Dashboard Grid): RTI tile resolves category code from /api/categories/ matching target_category_code and opens RTIHubScreen', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/categories/')) {
          return http.Response('''[
            {"category_id": 205, "category_name": "RTI", "category_code": "STAND_RTI"}
          ]''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/config/')) {
          return http.Response('''{
            "target_category_code": "STAND_RTI",
            "sub_tab_labels": {"all": "Total", "pending": "Pending", "disposal": "Disposal"},
            "row_action_labels": {"edit": "Edit", "view": "View", "pdf": "PDF"},
            "add_button_label": "Add RTI",
            "empty_list_message": "Empty",
            "page_size": 20
          }''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/counts/')) {
          return http.Response('''{"total": 0, "pending": 0, "disposal": 0}''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/')) {
          return http.Response('''{"count": 0, "page": 1, "page_size": 20, "results": []}''', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      late BuildContext testContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Scaffold(body: Text('Home'));
              },
            ),
          ),
        ),
      );

      // Dashboard Grid tap passing null categoryCode initially
      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: testContext,
        categoryName: 'RTI',
        moduleKey: 'standalone',
        categoryCode: null,
      );

      await tester.pumpAndSettle();

      // Opens RTIHubScreen and NEVER ModuleHubScreen
      expect(find.byType(RTIHubScreen), findsOneWidget);
      expect(find.byType(ModuleHubScreen), findsNothing);

      ApiService.clientForTesting = null;
    });

    testWidgets('Entry Point 2 (Quick Actions): Quick Action tile opens RTIHubScreen via CategoryNavigationHelper', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/categories/')) {
          return http.Response('''[
            {"category_id": 205, "category_name": "RTI", "category_code": "STAND_RTI"}
          ]''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/config/')) {
          return http.Response('''{
            "target_category_code": "STAND_RTI",
            "sub_tab_labels": {"all": "Total", "pending": "Pending", "disposal": "Disposal"},
            "add_button_label": "Add RTI",
            "empty_list_message": "Empty",
            "page_size": 20
          }''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/counts/')) {
          return http.Response('''{"total": 0, "pending": 0, "disposal": 0}''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/')) {
          return http.Response('''{"count": 0, "page": 1, "page_size": 20, "results": []}''', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      late BuildContext testContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Scaffold(body: Text('Home'));
              },
            ),
          ),
        ),
      );

      // Quick Action tile tap
      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: testContext,
        categoryName: 'RTI',
        moduleKey: 'form_1_5',
      );

      await tester.pumpAndSettle();

      expect(find.byType(RTIHubScreen), findsOneWidget);
      expect(find.byType(ModuleHubScreen), findsNothing);

      ApiService.clientForTesting = null;
    });

    testWidgets('Entry Point 3 (Global Search): Search result header opens RTIHubScreen via CategoryNavigationHelper', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/categories/')) {
          return http.Response('''[
            {"category_id": 205, "category_name": "RTI", "category_code": "STAND_RTI"}
          ]''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/config/')) {
          return http.Response('''{
            "target_category_code": "STAND_RTI",
            "sub_tab_labels": {"all": "Total", "pending": "Pending", "disposal": "Disposal"},
            "add_button_label": "Add RTI",
            "empty_list_message": "Empty",
            "page_size": 20
          }''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/counts/')) {
          return http.Response('''{"total": 0, "pending": 0, "disposal": 0}''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/')) {
          return http.Response('''{"count": 0, "page": 1, "page_size": 20, "results": []}''', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      late BuildContext testContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Scaffold(body: Text('Home'));
              },
            ),
          ),
        ),
      );

      // Global Search tile tap
      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: testContext,
        categoryName: 'RTI',
        moduleKey: 'standalone',
      );

      await tester.pumpAndSettle();

      expect(find.byType(RTIHubScreen), findsOneWidget);
      expect(find.byType(ModuleHubScreen), findsNothing);

      ApiService.clientForTesting = null;
    });

    testWidgets('Entry Point 4 (Notification / Report Cards): Report tile opens RTIHubScreen via CategoryNavigationHelper', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/categories/')) {
          return http.Response('''[
            {"category_id": 205, "category_name": "RTI", "category_code": "STAND_RTI"}
          ]''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/config/')) {
          return http.Response('''{
            "target_category_code": "STAND_RTI",
            "sub_tab_labels": {"all": "Total", "pending": "Pending", "disposal": "Disposal"},
            "add_button_label": "Add RTI",
            "empty_list_message": "Empty",
            "page_size": 20
          }''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/counts/')) {
          return http.Response('''{"total": 0, "pending": 0, "disposal": 0}''', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/')) {
          return http.Response('''{"count": 0, "page": 1, "page_size": 20, "results": []}''', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      late BuildContext testContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const Scaffold(body: Text('Home'));
              },
            ),
          ),
        ),
      );

      // Report Tile tap
      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: testContext,
        categoryName: 'RTI',
        moduleKey: 'rti',
        readOnly: true,
      );

      await tester.pumpAndSettle();

      expect(find.byType(RTIHubScreen), findsOneWidget);
      expect(find.byType(ModuleHubScreen), findsNothing);

      ApiService.clientForTesting = null;
    });

    testWidgets('Failed POST (HTTP 400 Bad Request) must NOT show a new row', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/api/rti/')) {
          return http.Response('''{"error": "applicant_name is required."}''', 400, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      final res = await RtiService().createApplication({
        'received_date': '2026-10-01',
        'mode_of_receipt': 'Online'
      });

      expect(res.isSuccess, false);
      expect(res.statusCode, 400);
      expect(res.errorMessage, 'applicant_name is required.');

      ApiService.clientForTesting = null;
    });

    testWidgets('Failed POST (HTTP 500 Server Error) must NOT show a new row', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/api/rti/')) {
          return http.Response('''{"detail": "Internal Server Error"}''', 500, headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      final res = await RtiService().createApplication({
        'received_date': '2026-10-01'
      });

      expect(res.isSuccess, false);
      expect(res.statusCode, 500);
      expect(res.errorMessage, 'Internal Server Error');

      ApiService.clientForTesting = null;
    });
  });
}
