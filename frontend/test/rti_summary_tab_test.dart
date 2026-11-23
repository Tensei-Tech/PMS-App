import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/screens/rti/rti_hub_screen.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/rti_service.dart';

/// The RTI Summary tab shows applications counted by Type of Info and
/// outcome, with a Grand Total row, as /api/rti/summary/ sends them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    RtiService().clearCache();
  });
  tearDown(() => ApiService.clientForTesting = null);

  testWidgets('Summary tab shows the count table', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final chartRequests = <Uri>[];
    ApiService.clientForTesting = MockClient((request) async {
      const json = {'content-type': 'application/json'};
      final path = request.url.path;
      if (path.contains('/api/rti/summary/')) {
        return http.Response('''{
          "info_label": "Type of Info",
          "grand_total_label": "Grand Total",
          "columns": [
            {"key": "replied", "label": "Replied"},
            {"key": "rejected", "label": "Rejected"},
            {"key": "pending", "label": "Pending"},
            {"key": "transferred", "label": "Transferred"},
            {"key": "total", "label": "Total"}
          ],
          "rows": [
            {"info_type": "Crime record", "replied": 11, "rejected": 4, "pending": 0, "transferred": 0, "total": 15},
            {"info_type": "Accident record", "replied": 2, "rejected": 2, "pending": 22, "transferred": 0, "total": 26}
          ],
          "grand_total": {"replied": 13, "rejected": 6, "pending": 22, "transferred": 0, "total": 41}
        }''', 200, headers: json);
      }
      if (path.contains('/api/rti/counts/')) {
        return http.Response('{"total": 41, "pending": 22}', 200,
            headers: json);
      }
      if (path.contains('/api/rti/config/')) {
        return http.Response('{"page_size": 20}', 200, headers: json);
      }
      // The cases behind a clicked count: Accident record, every outcome
      final params = request.url.queryParameters;
      if (path.contains('/api/rti/chart/') &&
          params['info_type'] == 'Accident record' &&
          !params.containsKey('outcome')) {
        chartRequests.add(request.url);
        return http.Response('''{"count": 1, "page": 1, "page_size": 20,
          "results": [{"rti_id": 9, "sr_no": "RTI-2026/9",
            "person": "Ravi, 40 Yrs", "received_date": "01/10/2026",
            "due_date": "31/10/2026", "info_type": "Accident record",
            "assigned_officer": "", "info_given": ""}]}''', 200, headers: json);
      }
      return http.Response(
          '{"count": 0, "page": 1, "page_size": 20, "results": []}', 200,
          headers: json);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => FormIVProvider()),
        ],
        child: const MaterialApp(
          home: RTIHubScreen(
            categoryName: 'RTI',
            categoryCode: 'STAND_RTI',
            moduleKey: 'standalone',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();

    // Monthly-style table: uppercase headers, one row per type, grand total
    expect(find.text('TYPE OF INFO'), findsOneWidget);
    expect(find.text('REPLIED'), findsOneWidget);
    expect(find.text('TRANSFERRED'), findsOneWidget);
    expect(find.text('Crime record'), findsOneWidget);
    expect(find.text('Accident record'), findsOneWidget);
    expect(find.text('GRAND TOTAL'), findsOneWidget);
    // No title strip above the table
    expect(find.text('Grand Total: 41'), findsNothing);
    expect(find.text('41'), findsWidgets); // grand total cell + Total badge
    expect(find.text('26'), findsOneWidget); // Accident record total
    // No search bar on the Summary tab
    expect(find.byType(TextField), findsNothing);

    // Table fits available screen width via responsive LayoutBuilder
    expect(find.byType(LayoutBuilder), findsWidgets);

    // A count opens the cases behind it: Accident record x Total (26)
    await tester.tap(find.text('26'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Accident record · Total'), findsOneWidget);
    expect(find.text('RTI-2026/9'), findsOneWidget);
    expect(chartRequests, isNotEmpty);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
