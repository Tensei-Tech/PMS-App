// test/dynamic_mobile_email_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:khakhi_diary/widgets/dynamic_form/dynamic_control_factory.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';

DynamicFieldDef _def(String key, String label, String type,
        {String? optionsSource}) =>
    DynamicFieldDef(
      fieldDefId: 1,
      fieldKey: key,
      fieldLabel: label,
      fieldSource: 'custom',
      fieldType: type,
      isRequired: false,
      displayOrder: 1,
      optionsSource: optionsSource,
    );

Future<void> _pump(WidgetTester tester, DynamicFieldDef def) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Form(
        child: DynamicControlFactory(
          fieldDef: def,
          controller: TextEditingController(),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('Mobile: optional, exactly 10 digits, letters blocked',
      (tester) async {
    await _pump(tester, _def('t_mobile', 'TEST Mobile', 'mobile'));
    final field = find.byType(TextFormField);

    // 11 digits: error shows under the field while typing
    await tester.enterText(field, '98765432101');
    await tester.pump();
    expect(find.text('TEST Mobile must be exactly 10 digits'), findsOneWidget);

    // Exactly 10 digits: no error
    await tester.enterText(field, '9876543210');
    await tester.pump();
    expect(find.text('TEST Mobile must be exactly 10 digits'), findsNothing);

    // Letters are not accepted at all
    await tester.enterText(field, 'abc');
    await tester.pump();
    expect(tester.widget<TextFormField>(field).controller!.text, isEmpty);

    // Empty: no error (not required)
    await tester.enterText(field, '');
    await tester.pump();
    expect(find.text('TEST Mobile must be exactly 10 digits'), findsNothing);
    expect(find.text('TEST Mobile is required'), findsNothing);
  });

  testWidgets('E-mail: optional, checked only when filled', (tester) async {
    await _pump(tester, _def('t_email', 'TEST E-mail', 'email'));
    final field = find.byType(TextFormField);

    await tester.enterText(field, 'citizen@');
    await tester.pump();
    expect(find.text('Enter a valid TEST E-mail'), findsOneWidget);

    await tester.enterText(field, 'citizen@example.com');
    await tester.pump();
    expect(find.text('Enter a valid TEST E-mail'), findsNothing);

    await tester.enterText(field, '');
    await tester.pump();
    expect(find.text('Enter a valid TEST E-mail'), findsNothing);
  });

  testWidgets('Age: optional, at most 3 digits, no range error',
      (tester) async {
    // The limit is field data (options source 'digits:3'), not the key name
    await _pump(
        tester, _def('t_age', 'TEST Age', 'number', optionsSource: 'digits:3'));
    final field = find.byType(TextFormField);
    String text() => tester.widget<TextFormField>(field).controller!.text;

    await tester.enterText(field, '123');
    await tester.pump();
    expect(find.textContaining('must be between'), findsNothing);
    expect(find.text('TEST Age can be at most 3 digits'), findsNothing);

    await tester.enterText(field, '1234');
    await tester.pump();
    expect(text(), '123');
    expect(find.text('TEST Age can be at most 3 digits'), findsOneWidget);

    await tester.enterText(field, '12');
    await tester.pump();
    expect(find.text('TEST Age can be at most 3 digits'), findsNothing);

    await tester.enterText(field, '');
    await tester.pump();
    expect(find.text('TEST Age is required'), findsNothing);
  });

  testWidgets('A number field without a digits limit takes any length',
      (tester) async {
    await _pump(tester, _def('t_count_age', 'TEST Count', 'number'));
    final field = find.byType(TextFormField);
    await tester.enterText(field, '123456');
    await tester.pump();
    expect(tester.widget<TextFormField>(field).controller!.text, '123456');
    expect(find.textContaining('can be at most'), findsNothing);
  });

  testWidgets('Aadhaar: optional, 12 digits shown in groups of four',
      (tester) async {
    await _pump(tester, _def('t_aadhaar', 'TEST Aadhaar', 'aadhaar'));
    final field = find.byType(TextFormField);
    String text() => tester.widget<TextFormField>(field).controller!.text;

    // Typed in groups of four; letters and a 13th digit are dropped
    await tester.enterText(field, '1234567890123x');
    await tester.pump();
    expect(text(), '1234 5678 9012');
    expect(find.text('TEST Aadhaar must be exactly 12 digits'), findsNothing);

    await tester.enterText(field, '12345');
    await tester.pump();
    expect(text(), '1234 5');
    expect(find.text('TEST Aadhaar must be exactly 12 digits'), findsOneWidget);

    await tester.enterText(field, '');
    await tester.pump();
    expect(find.text('TEST Aadhaar must be exactly 12 digits'), findsNothing);
    expect(find.text('TEST Aadhaar is required'), findsNothing);
  });

  test('Year: short year means 20xx, list is 2001-2100', () {
    expect(YearPickerField.expand('03'), '2003');
    expect(YearPickerField.expand('3'), '2003');
    expect(YearPickerField.expand('00'), '2100');
    expect(YearPickerField.expand('2024'), '2024');
    expect(YearPickerField.matches('').length, 100);
    expect(YearPickerField.matches('').first, '2001');
    expect(YearPickerField.matches('').last, '2100');
    expect(YearPickerField.matches('03'), ['2003']);
    expect(YearPickerField.matches('202'),
        [for (var y = 2020; y <= 2029; y++) '$y']);
  });

  testWidgets('Year: typing 03 and leaving the field gives 2003',
      (tester) async {
    await _pump(tester, _def('t_year', 'TEST Year', 'year'));
    final field = find.byType(TextFormField);
    await tester.enterText(field, '03');
    await tester.pump();
    expect(find.text('2003'), findsWidgets); // listed in the dropdown

    FocusManager.instance.primaryFocus?.unfocus(); // leave the field
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(field).controller!.text, '2003');
    expect(find.textContaining('Select a year'), findsNothing);
  });
}
