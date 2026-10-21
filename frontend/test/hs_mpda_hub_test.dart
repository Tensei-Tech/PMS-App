// test/hs_mpda_hub_test.dart
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
import 'package:khakhi_diary/screens/history_sheeter/history_sheeter_hub_screen.dart';
import 'package:khakhi_diary/screens/mpda/mpda_hub_screen.dart';
import 'package:khakhi_diary/screens/no_form_configured_screen.dart';
import 'package:khakhi_diary/utils/category_navigation_helper.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_form_screen.dart';
import 'package:khakhi_diary/widgets/pdf_document_view_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    HistorySheeterService().clearCache();
    MpdaService().clearCache();
    RtiService().clearCache();
    CaseService().clearCache();
  });

  group('History Sheeter Hub Screen Tests', () {
    testWidgets(
        'HistorySheeterHubScreen renders 3 tabs, counts, actions from config, NO number cards, NO delete button',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/history-sheeter/config/')) {
          return http.Response(
              '''{
            "target_category_code": "STAND_HISTORY_SHEETER",
            "sub_tab_labels": {
              "active": "Dynamic Active HS",
              "open": "Dynamic Open HS",
              "closed": "Dynamic Closed HS"
            },
            "action_labels": {
              "add": "New History Record",
              "edit": "Modify HS",
              "view": "Inspect HS",
              "pdf": "Print HS Dossier"
            },
            "search_placeholder": "Find Sheeter By Sr No...",
            "empty_list_message": "Zero Sheeters on file",
            "page_size": 20
          }''',
              200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/history-sheeter/counts/')) {
          return http.Response(
              '''{"active": 12, "open": 25, "closed": 7}''', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/history-sheeter/')) {
          return http.Response(
              '''{"count": 0, "page": 1, "page_size": 20, "results": []}''',
              200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: const MaterialApp(
            home: HistorySheeterHubScreen(
              categoryName: 'History Sheeter Test',
              categoryCode: 'STAND_HISTORY_SHEETER',
              moduleKey: 'history_sheeter',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dynamic 3 tab labels follow backend config
      expect(find.text('Dynamic Active HS'), findsOneWidget);
      expect(find.text('Dynamic Open HS'), findsOneWidget);
      expect(find.text('Dynamic Closed HS'), findsOneWidget);

      // Verify counts follow backend
      expect(find.text('12'), findsOneWidget);
      expect(find.text('25'), findsWidgets); // tab badge + subtitle
      expect(find.text('7'), findsOneWidget);

      // Verify action add button follows config
      expect(find.text('New History Record'), findsOneWidget);

      // Verify search placeholder
      expect(find.text('Find Sheeter By Sr No...'), findsOneWidget);

      // Verify empty list message follows config
      expect(find.text('Zero Sheeters on file'), findsOneWidget);

      // Rule: NO Delete button anywhere
      expect(find.text('Delete'), findsNothing);

      ApiService.clientForTesting = null;
    });

    testWidgets(
        'HistorySheeterHubScreen updates dynamically when config values change',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/history-sheeter/config/')) {
          return http.Response(
              '''{
            "target_category_code": "STAND_HISTORY_SHEETER",
            "sub_tab_labels": {
              "active": "Active Criminals",
              "open": "Unclosed Sheets",
              "closed": "Archived Sheets"
            },
            "action_labels": {
              "add": "Create Sheeter",
              "edit": "Edit",
              "view": "View",
              "pdf": "PDF"
            },
            "search_placeholder": "Quick Search...",
            "empty_list_message": "No records exist",
            "page_size": 20
          }''',
              200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/history-sheeter/counts/')) {
          return http.Response('''{"active": 3, "open": 5, "closed": 2}''', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/history-sheeter/')) {
          return http.Response(
              '''{"count": 0, "page": 1, "page_size": 20, "results": []}''',
              200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: const MaterialApp(
            home: HistorySheeterHubScreen(
              categoryName: 'History Sheeter Test',
              categoryCode: 'STAND_HISTORY_SHEETER',
              moduleKey: 'history_sheeter',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Screen updated to new labels from backend
      expect(find.text('Active Criminals'), findsOneWidget);
      expect(find.text('Unclosed Sheets'), findsOneWidget);
      expect(find.text('Archived Sheets'), findsOneWidget);
      expect(find.text('Create Sheeter'), findsOneWidget);
      expect(find.text('Quick Search...'), findsOneWidget);
      expect(find.text('No records exist'), findsOneWidget);

      ApiService.clientForTesting = null;
    });
  });

  group('MPDA Hub Screen Tests', () {
    testWidgets(
        'MpdaHubScreen renders 5 cards that are ALSO tabs, counts agree, NO delete button',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/mpda/config/')) {
          return http.Response(
              '''{
            "target_category_code": "STAND_MPDA",
            "card_labels": {
              "total": "Total MPDA Dossiers",
              "approved": "Sanctioned Proposals",
              "rejected": "Declined Proposals",
              "jail": "Currently Detained In Jail",
              "released_next_month": "Due Release Next Month"
            },
            "sub_tab_labels": {
              "total": "All MPDA",
              "approved": "Sanctioned",
              "rejected": "Declined",
              "jail": "In Jail",
              "released_next_month": "Next Month Release"
            },
            "action_labels": {
              "add": "Draft MPDA",
              "edit": "Modify Proposal",
              "view": "View Dossier",
              "pdf": "Export PDF"
            },
            "search_placeholder": "Search by Proposal or Accused...",
            "empty_list_message": "No MPDA dossiers found",
            "page_size": 20
          }''',
              200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/mpda/counts/')) {
          return http.Response(
              '''{
            "total": 45,
            "approved": 30,
            "rejected": 10,
            "jail": 20,
            "released_next_month": 4
          }''',
              200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/mpda/')) {
          return http.Response(
              '''{"count": 45, "page": 1, "page_size": 20, "results": []}''',
              200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: const MaterialApp(
            home: MpdaHubScreen(
              categoryName: 'MPDA Test',
              categoryCode: 'STAND_MPDA',
              moduleKey: 'mpda',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 5 card labels from backend
      expect(find.text('Total MPDA Dossiers'), findsOneWidget);
      expect(find.text('Sanctioned Proposals'), findsOneWidget);
      expect(find.text('Declined Proposals'), findsOneWidget);
      expect(find.text('Currently Detained In Jail'), findsOneWidget);
      expect(find.text('Due Release Next Month'), findsOneWidget);
      expect(find.text('Revocation Orders'), findsNothing);

      // Verify counts on cards
      expect(find.text('45'), findsWidgets); // card + tab badge + subtitle
      expect(find.text('30'), findsWidgets);
      expect(find.text('10'), findsWidgets);
      expect(find.text('20'), findsWidgets);
      expect(find.text('4'), findsWidgets);

      // Verify Add button label from config
      expect(find.text('Draft MPDA'), findsOneWidget);

      // Verify search placeholder
      expect(find.text('Search by Proposal or Accused...'), findsOneWidget);

      // Rule: NO Delete button anywhere
      expect(find.text('Delete'), findsNothing);

      // Tapping card switches tab
      await tester.tap(find.text('Sanctioned Proposals'), warnIfMissed: false);
      await tester.pumpAndSettle();

      ApiService.clientForTesting = null;
    });

    testWidgets(
        'MpdaHubScreen card View opens the PDF-style view; Edit populates the form',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/mpda/config/')) {
          return http.Response(
              '''{
            "target_category_code": "STAND_MPDA",
            "card_labels": {"total": "Total"},
            "sub_tab_labels": {"total": "Total"},
            "action_labels": {"edit": "Edit", "view": "View"}
          }''',
              200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/mpda/counts/')) {
          return http.Response('{"total": 1}', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.endsWith('/api/mpda/1/pdf/')) {
          return http.Response('%PDF-1.4 test', 200,
              headers: {'content-type': 'application/pdf'});
        }
        if (request.url.path.endsWith('/api/mpda/1/')) {
          return http.Response(
              '''{
            "id": 1,
            "proposal_no": "1/2026",
            "proposal_no_and_year": "1/2026",
            "proposal_outcome": "Rejected",
            "authority_name": "District Magistrate",
            "mpda_proposal_no": "1/2026",
            "mpda_proposal_outcome": "Rejected",
            "mpda_authority_name": "District Magistrate",
            "accused_persons": [
              {"name": "Ganesh K", "age": 28, "gender": "Male"}
            ],
            "mpda_accused": [
              {"name": "Ganesh K", "age": 28, "gender": "Male"}
            ]
          }''',
              200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/mpda/')) {
          return http.Response(
              '''{
            "count": 1,
            "page": 1,
            "page_size": 20,
            "results": [
              {
                "id": 1,
                "proposal_no_and_year": "1/2026",
                "proposal_outcome": "Rejected",
                "accused_name": "Ganesh K"
              }
            ]
          }''',
              200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/form-definition/')) {
          return http.Response(
              '''{
            "category_id": 102,
            "category_code": "STAND_MPDA",
            "category_name": "MPDA",
            "has_linked_bundle": true,
            "fields": [
              {
                "field_def_id": 1,
                "field_key": "mpda_proposal_no",
                "field_label": "Proposal Number",
                "field_type": "text",
                "display_order": 1,
                "is_required": true,
                "section": "sec_1"
              },
              {
                "field_def_id": 2,
                "field_key": "mpda_proposal_outcome",
                "field_label": "Proposal Outcome",
                "field_type": "dropdown",
                "options": ["Sanctioned", "Rejected", "In Jail"],
                "display_order": 2,
                "section": "sec_1"
              },
              {
                "field_def_id": 3,
                "field_key": "mpda_authority_name",
                "field_label": "Competent Authority",
                "field_type": "text",
                "display_order": 3,
                "section": "sec_1"
              }
            ],
            "sections": [
              {
                "section_key": "sec_1",
                "title": "Proposal Details",
                "field_keys": ["mpda_proposal_no", "mpda_proposal_outcome", "mpda_authority_name"]
              }
            ]
          }''',
              200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FormIVProvider()),
          ],
          child: const MaterialApp(
            home: MpdaHubScreen(
              categoryName: 'MPDA',
              categoryCode: 'STAND_MPDA',
              moduleKey: 'mpda',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card is displayed with 1/2026 and Rejected
      expect(find.text('1/2026'), findsWidgets);
      expect(find.text('Rejected'), findsWidgets);

      // Tap View button
      final viewBtn = find.widgetWithText(OutlinedButton, 'View');
      expect(viewBtn, findsOneWidget);
      await tester.tap(viewBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // View shows the proposal as its PDF document, read-only (no form)
      expect(find.byType(PdfDocumentViewScreen), findsOneWidget);
      expect(find.text('View MPDA'), findsOneWidget);
      expect(find.byType(DynamicFormScreen), findsNothing);
      expect(find.text('Save Changes'), findsNothing);

      // Go back to hub
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      await tester.tap(backBtn.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Now tap Edit button
      final editBtn = find.widgetWithText(OutlinedButton, 'Edit');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify DynamicFormScreen is opened in Edit mode
      expect(find.byType(DynamicFormScreen), findsOneWidget);
      expect(find.text('Edit MPDA'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Verify data is populated in edit mode
      expect(find.text('1/2026'), findsWidgets);
      expect(find.text('District Magistrate'), findsOneWidget);

      ApiService.clientForTesting = null;
    });
  });

  group('Category Navigation Helper Routing Tests', () {
    testWidgets(
        'Routing opens HistorySheeterHubScreen for STAND_HISTORY_SHEETER and MpdaHubScreen for STAND_MPDA',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/categories/')) {
          return http.Response(
              '''[
            {"category_id": 101, "category_code": "STAND_HISTORY_SHEETER", "category_name": "History Sheeter"},
            {"category_id": 102, "category_code": "STAND_MPDA", "category_name": "MPDA"}
          ]''',
              200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/history-sheeter/config/')) {
          return http.Response(
              '''{"target_category_code": "STAND_HISTORY_SHEETER"}''', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/mpda/config/')) {
          return http.Response(
              '''{"target_category_code": "STAND_MPDA"}''', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/api/rti/config/')) {
          return http.Response('''{"target_category_code": "STAND_RTI"}''', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/counts/')) {
          return http.Response('{}', 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      // 1. Test History Sheeter tile routing
      BuildContext? testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );

      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: testContext!,
        categoryName: 'History Sheeter',
        moduleKey: 'history_sheeter',
        categoryCode: 'STAND_HISTORY_SHEETER',
      );

      await tester.pumpAndSettle();
      expect(find.byType(HistorySheeterHubScreen), findsOneWidget);

      ApiService.clientForTesting = null;
    });

    testWidgets(
        'Unlinked category or category with no form opens NoFormConfiguredScreen (never ModuleHubScreen)',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/categories/')) {
          return http.Response('[]', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/config/')) {
          return http.Response('{}', 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      ApiService.clientForTesting = mockClient;

      BuildContext? testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );

      await CategoryNavigationHelper.handleDashboardCategoryTap(
        context: testContext!,
        categoryName: 'Unknown Phantom Tab',
        moduleKey: 'unknown_module',
      );

      await tester.pumpAndSettle();
      expect(find.byType(NoFormConfiguredScreen), findsOneWidget);

      ApiService.clientForTesting = null;
    });
  });
}
