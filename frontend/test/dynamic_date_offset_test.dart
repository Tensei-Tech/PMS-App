// test/dynamic_date_offset_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_form_screen.dart';

const _formDefinition = '''{
  "category_id": 1,
  "category_name": "TEST Dates",
  "sections": [
    {"section_key": "app", "section_title": "TEST Application", "display_order": 1}
  ],
  "fields": [
    {"field_key": "t_received", "field_label": "TEST Received", "field_type": "date",
     "section_key": "app"},
    {"field_key": "t_due", "field_label": "TEST Due", "field_type": "date",
     "section_key": "app"}
  ]
}''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    CaseService().clearCache();
  });
  tearDown(() => ApiService.clientForTesting = null);

  testWidgets('Picking the source date fills the target date with source + days',
      (tester) async {
    ApiService.clientForTesting = MockClient((req) async {
      if (req.url.path.contains('/form-definition/')) {
        return http.Response(_formDefinition, 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    });
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
      ],
      child: const MaterialApp(
        home: DynamicFormScreen(
          moduleLabel: 'TEST Dates',
          moduleKey: 'form_1_5',
          subCategory: 'TEST Dates',
          dateOffsetRules: [
            {'source_field': 't_received', 'target_field': 't_due', 'days': 30},
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    Finder fieldUnder(String label) => find
        .descendant(
            of: find.ancestor(
                of: find.text(label), matching: find.byType(Column)).first,
            matching: find.byType(TextField))
        .first;

    expect(tester.widget<TextField>(fieldUnder('TEST Due')).controller!.text,
        isEmpty);

    // Pick today's date (the picker opens on today) for the source field
    await tester.tap(fieldUnder('TEST Received'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fmt = DateFormat('dd/MM/yyyy');
    expect(
        tester.widget<TextField>(fieldUnder('TEST Received')).controller!.text,
        fmt.format(today));
    expect(tester.widget<TextField>(fieldUnder('TEST Due')).controller!.text,
        fmt.format(today.add(const Duration(days: 30))));
  });
}
