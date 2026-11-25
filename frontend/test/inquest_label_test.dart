// In a card that names two things ("Inquest & Exhumation Panchnama") a field
// keeps its full name when shortening it would drop what tells it apart:
// "Inquest Panchnama Date & Time" must not show as "Panchnama Date & Time".
// Ordinary shortening ("Complainant Age" -> "Age") still applies.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';

DynamicFieldDef _f(int id, String label, String key, String section) =>
    DynamicFieldDef(
      fieldDefId: id,
      fieldLabel: label,
      fieldKey: key,
      fieldSource: 'custom',
      fieldType: 'text',
      isRequired: false,
      displayOrder: id,
      section: section,
    );

Future<void> _pump(WidgetTester tester, String title,
    List<DynamicFieldDef> fields) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controllers = <String, TextEditingController>{};
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 1300,
          child: DynamicSectionCard(
            title: title,
            icon: Icons.description_outlined,
            fields: fields,
            controllers: controllers,
            values: <String, dynamic>{},
            onValueChanged: (_, __) {},
            columns: 2,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Inquest field keeps its full name', (tester) async {
    const sec = 'Inquest & Exhumation Panchnama';
    await _pump(tester, sec, [
      _f(1, 'Inquest Panchnama Date & Time', 'murder_inquest_datetime', sec),
      _f(2, 'Exhumation Panchnama Date & Time', 'murder_exhumation_datetime',
          sec),
    ]);
    expect(find.text('Inquest Panchnama Date & Time'), findsOneWidget);
    expect(find.text('Exhumation Panchnama Date & Time'), findsOneWidget);
    expect(find.text('Panchnama Date & Time'), findsNothing);
  });

  testWidgets('ordinary shortening still applies', (tester) async {
    await _pump(tester, 'Complainant Details', [
      _f(1, 'Complainant Age', 'complainant_age', 'Complainant Details'),
    ]);
    expect(find.text('Age'), findsOneWidget);
  });
}
