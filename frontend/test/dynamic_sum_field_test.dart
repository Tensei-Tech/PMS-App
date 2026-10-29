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

import 'package:khakhi_diary/modules/core/models/base_record.dart';

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

const _snatchFormDefinition = '''{
  "category_id": 222,
  "category_name": "Chain Snatching",
  "sections": [
    {"section_key": "stolen", "section_title": "Stolen Property List", "display_order": 1}
  ],
  "fields": [
    {
      "field_key": "snatch_stolen_total_value",
      "field_label": "Total Value of Stolen Property (₹)",
      "field_type": "number",
      "section_key": "stolen",
      "options_source": "sum:snatch_stolen_props.snatch_stolen_value"
    },
    {
      "field_key": "snatch_stolen_props",
      "field_label": "Stolen Property List",
      "field_type": "repeating_group",
      "section_key": "stolen",
      "child_fields": [
        {"field_key": "snatch_stolen_name", "field_label": "Name of Stolen Property", "field_type": "text"},
        {"field_key": "snatch_stolen_desc", "field_label": "Description", "field_type": "text"},
        {"field_key": "snatch_stolen_value", "field_label": "Value (₹)", "field_type": "number"}
      ]
    }
  ]
}''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService().setAuthToken('test-token');
    CaseService().clearCache();
  });
  tearDown(() => ApiService.clientForTesting = null);

  test(
      'sumOf reads only sum: sources of number fields and supports group.child',
      () {
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
    expect(def('number', 'sum:snatch_stolen_props.snatch_stolen_value').sumOf,
        ['snatch_stolen_props.snatch_stolen_value']);
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
            of: find
                .ancestor(of: find.text(label), matching: find.byType(Column))
                .first,
            matching: find.byType(TextField))
        .first);

    expect(fieldAfter('TEST Total').readOnly, isTrue);

    await tester.enterText(fieldFor('TEST Serious'), '3');
    await tester.pump();
    expect(fieldAfter('TEST Total').controller!.text, '3');

    await tester.enterText(fieldFor('TEST Misc'), '4');
    await tester.pump();
    expect(fieldAfter('TEST Total').controller!.text, '7');
  });

  testWidgets('Repeating group child sum fills total field on hydration',
      (tester) async {
    ApiService.clientForTesting = MockClient((req) async {
      if (req.url.path.contains('/form-definition/')) {
        return http.Response(_snatchFormDefinition, 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    });
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final testRecord = ModuleRecord(
      id: 'case_1',
      moduleKey: 'form_1_5',
      subCategory: 'Chain Snatching',
      title: 'Chain Snatching Case',
      caseNumber: 'CR/100/2026',
      description: 'Chain Snatching incident description',
      complainant: 'Rahul Sharma',
      accused: 'Unknown Person',
      location: 'MG Road, Near Bus Stop',
      priority: 'High',
      status: 'Investigation',
      assignedOfficer: 'PI Patil',
      stationName: 'Crime Branch',
      incidentDate: DateTime(2026, 1, 1),
      extraFields: {
        'snatch_stolen_props': [
          {
            'snatch_stolen_name': 'Gold Chain',
            'snatch_stolen_desc': '22K 15 grams',
            'snatch_stolen_value': '80000',
          },
          {
            'snatch_stolen_name': 'Smartphone',
            'snatch_stolen_desc': 'Samsung Galaxy S24',
            'snatch_stolen_value': '60000',
          },
        ],
      },
    );

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
      ],
      child: MaterialApp(
        home: DynamicFormScreen(
          moduleLabel: 'Chain Snatching',
          moduleKey: 'form_1_5',
          subCategory: 'Chain Snatching',
          existingRecord: testRecord,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await openFirstSection(tester);

    TextField fieldAfter(String label) => tester.widget<TextField>(find
        .descendant(
            of: find
                .ancestor(of: find.text(label), matching: find.byType(Column))
                .first,
            matching: find.byType(TextField))
        .first);

    // 80000 + 60000 = 140000
    expect(fieldAfter('Total Value of Stolen Property (₹)').controller!.text,
        '140000');
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
