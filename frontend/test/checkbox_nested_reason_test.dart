// A Reason (text, key ending in _reason) that opens when a checkbox is
// ticked is drawn inside the checkbox's card next to its date, not as a
// separate labelled cell beside the card.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';

const _box = DynamicFieldDef(
  fieldDefId: 1,
  fieldLabel: 'Vehicle Log Book Entry',
  fieldKey: 'vehicle_log_book_entry',
  fieldSource: 'custom',
  fieldType: 'checkbox',
  isRequired: false,
  displayOrder: 1,
  section: 'Vehicle Log Book',
);
const _date = DynamicFieldDef(
  fieldDefId: 2,
  fieldLabel: 'Vehicle Log Book Entry Date',
  fieldKey: 'vehicle_log_book_entry_date',
  fieldSource: 'custom',
  fieldType: 'date',
  isRequired: false,
  displayOrder: 2,
  section: 'Vehicle Log Book',
  dependsOnFieldKey: 'vehicle_log_book_entry',
);
const _reason = DynamicFieldDef(
  fieldDefId: 3,
  fieldLabel: 'Log Book Entry Reason',
  fieldKey: 'vehicle_log_book_entry_reason',
  fieldSource: 'custom',
  fieldType: 'text',
  isRequired: false,
  displayOrder: 3,
  section: 'Vehicle Log Book',
  dependsOnFieldKey: 'vehicle_log_book_entry',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('ticked: date and reason sit side by side inside the card',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 1200,
            child: DynamicSectionCard(
              title: 'Vehicle Log Book',
              icon: Icons.menu_book_outlined,
              fields: const [_box, _date, _reason],
              controllers: {},
              values: {'vehicle_log_book_entry': true},
              onValueChanged: (_, __) {},
              columns: 2,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Log Book Entry Reason'), findsNothing,
        reason: 'the reason has no separate label above it');
    final inBox = find.descendant(
      of: find.ancestor(
              of: find.text('Vehicle Log Book Entry'),
              matching: find.byType(Container))
          .first,
      matching: find.byType(TextFormField),
    );
    expect(inBox, findsNWidgets(2), reason: 'date and reason are in the card');
    final fields = tester.widgetList(inBox).toList();
    final a = tester.getTopLeft(find.byWidget(fields[0]));
    final b = tester.getTopLeft(find.byWidget(fields[1]));
    expect(a.dy, b.dy, reason: 'same line');
  });
}
