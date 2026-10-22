// test/dynamic_sum_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/services/api_service.dart';
import 'package:khakhi_diary/services/case_service.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_form_screen.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';

const _formDefinition = '''{
  "category_id": 1,
  "category_name": "TEST Sum",
  "sections": [
    {"section_key": "chart", "section_title": "TEST Chart", "display_order": 1}
  ],
  "fields": [
    {"field_key": "t_total", "field_label": "TEST Total", "field_type": "number",
     "section_key": "chart", "options_source": "sum:t_serious,t_misc"},
    {"field_key": "t_serious", "field_label": "TEST Serious", "field_type": "number",
     "section_key": "chart"},
    {"field_key": "t_misc", "field_label": "TEST Misc", "field_type": "number",
     "section_key": "chart"}
  ]
}''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    CaseService().clearCache();
  });
  tearDown(() => ApiService.clientForTesting = null);

  test('sumOf reads only sum: sources of number fields', () {
    DynamicFieldDef def(String type, String? src) => DynamicFieldDef(
        fieldDefId: 1,
        fieldLabel: 'x',
        fieldKey: 'x',
        fieldSource: 'custom',
        fieldType: type,
        isRequired: false,
        displayOrder: 1,
        optionsSource: src);
    expect(def('number', 'sum:a, b').sumOf, ['a', 'b']);
    expect(def('text', 'sum:a,b').sumOf, isEmpty);
    expect(def('number', '/api/options/x/').sumOf, isEmpty);
  });

  testWidgets('Total fills itself from Serious + Misc and is read-only',
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
          moduleLabel: 'TEST Sum',
          moduleKey: 'form_1_5',
          subCategory: 'TEST Sum',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await openFirstSection(tester);

    TextField fieldAfter(String label) => tester.widget<TextField>(find
        .descendant(
            of: find.ancestor(
                of: find.text(label), matching: find.byType(Column)).first,
            matching: find.byType(TextField))
        .first);

    expect(fieldAfter('TEST Total').readOnly, isTrue);

    await tester.enterText(
        fieldFor('TEST Serious'),
        '3');
    await tester.pump();
    expect(fieldAfter('TEST Total').controller!.text, '3');

    await tester.enterText(
        fieldFor('TEST Misc'),
        '4');
    await tester.pump();
    expect(fieldAfter('TEST Total').controller!.text, '7');
  });
}

/// Opens the first section (sections start collapsed in the accordion form).
Future<void> openFirstSection(WidgetTester tester) async {
  final header = find
      .descendant(
          of: find.byType(DynamicSectionCard).first,
          matching: find.byType(InkWell))
      .first;
  await tester.tap(header);
  await tester.pumpAndSettle();
}

/// The text box of the field labelled [label]: the smallest Row / Column
/// around the label that holds exactly one TextField (label beside or above).
Finder fieldFor(String label) {
  for (final e in find
      .ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is Row || w is Column))
      .evaluate()) {
    final boxes = find.descendant(
        of: find.byWidget(e.widget), matching: find.byType(TextField));
    if (boxes.evaluate().length == 1) return boxes;
  }
  throw StateError('No single TextField found for $label');
}
