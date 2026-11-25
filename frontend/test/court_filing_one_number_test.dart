// Court Filing and Final Summary: only one of the six numbers can be entered.
// Once one is filled the empty others lock (read-only, with a hint naming the
// filled one); clearing it unlocks them again.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';

const _numbers = [
  ('charge_sheet_no', 'Charge Sheet No'),
  ('a_final_number', 'A Final Number'),
  ('b_final_number', 'B Final Number'),
  ('c_final_number', 'C Final Number'),
  ('nc_final_number', 'NC Final Number'),
  ('abeted_summary_no', 'Abeted Summary No'),
];

List<DynamicFieldDef> _fields() => [
      for (var i = 0; i < _numbers.length; i++)
        DynamicFieldDef(
          fieldDefId: i + 1,
          fieldLabel: _numbers[i].$2,
          fieldKey: _numbers[i].$1,
          fieldSource: 'common',
          fieldType: 'text',
          isRequired: false,
          displayOrder: i + 1,
          section: 'Court Filing and Final Summary',
        ),
    ];

Future<Map<String, dynamic>> _pump(WidgetTester tester,
    [Map<String, dynamic>? start]) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final values = <String, dynamic>{...?start};
  final controllers = <String, TextEditingController>{};
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 1300,
          child: DynamicSectionCard(
            title: 'Court Filing and Final Summary',
            icon: Icons.gavel_outlined,
            fields: _fields(),
            controllers: controllers,
            values: values,
            onValueChanged: (_, __) {},
            columns: 3,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  return values;
}

/// The TextField drawn for the field with this label.
TextField _box(WidgetTester tester, String label) => tester.widget<TextField>(
    find.descendant(
        of: find.ancestor(
                of: find.text(label), matching: find.byType(Column))
            .first,
        matching: find.byType(TextField)));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('filling one locks the other five; clearing unlocks them',
      (tester) async {
    await _pump(tester);
    for (final n in _numbers) {
      expect(_box(tester, n.$2).readOnly, isFalse, reason: '${n.$2} open');
    }

    await tester.enterText(
        find.byWidget(_box(tester, 'B Final Number')), 'B/12/2026');
    await tester.pump();
    for (final n in _numbers) {
      final box = _box(tester, n.$2);
      if (n.$1 == 'b_final_number') {
        expect(box.readOnly, isFalse);
      } else {
        expect(box.readOnly, isTrue, reason: '${n.$2} locked');
        expect(box.decoration?.hintText, 'Clear B Final Number to use this');
      }
    }

    await tester.enterText(find.byWidget(_box(tester, 'B Final Number')), '');
    await tester.pump();
    for (final n in _numbers) {
      expect(_box(tester, n.$2).readOnly, isFalse, reason: '${n.$2} open');
    }
  });

  testWidgets('an older case with two numbers keeps both editable',
      (tester) async {
    await _pump(tester, {'a_final_number': 'A/1', 'c_final_number': 'C/2'});
    expect(_box(tester, 'A Final Number').readOnly, isFalse);
    expect(_box(tester, 'C Final Number').readOnly, isFalse);
    expect(_box(tester, 'Charge Sheet No').readOnly, isTrue);
  });
}
