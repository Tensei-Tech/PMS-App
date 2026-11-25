// A date field that opens when a checkbox is ticked (depends_on_field_key =
// the checkbox) is drawn inside the checkbox's card, without its own label,
// not as a separate cell in the grid.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';

const _box = DynamicFieldDef(
  fieldDefId: 1,
  fieldLabel: 'E-Shakshya',
  fieldKey: 'e_shakshya',
  fieldSource: 'common',
  fieldType: 'checkbox',
  isRequired: false,
  displayOrder: 1,
  section: 'Evidence',
);
const _date = DynamicFieldDef(
  fieldDefId: 2,
  fieldLabel: 'E-Shakshya Date',
  fieldKey: 'e_shakshya_date',
  fieldSource: 'common',
  fieldType: 'date',
  isRequired: false,
  displayOrder: 2,
  section: 'Evidence',
  dependsOnFieldKey: 'e_shakshya',
);

Widget _card(Map<String, dynamic> values) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 1200,
            child: DynamicSectionCard(
              title: 'Evidence',
              icon: Icons.inventory_2_outlined,
              fields: const [_box, _date],
              controllers: {},
              values: values,
              onValueChanged: (_, __) {},
              columns: 3,
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('ticked: the date sits inside the checkbox card, unlabelled',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_card({'e_shakshya': true}));
    await tester.pump();

    expect(find.text('E-Shakshya Date'), findsNothing,
        reason: 'the date has no separate label');
    final inBox = find.descendant(
      of: find.ancestor(
          of: find.text('E-Shakshya'), matching: find.byType(Container)).first,
      matching: find.byType(TextFormField),
    );
    expect(inBox, findsOneWidget, reason: 'the date field is inside the card');
  });

  testWidgets('unticked: no date', (tester) async {
    await tester.pumpWidget(_card({'e_shakshya': false}));
    await tester.pump();
    expect(find.byType(TextFormField), findsNothing);
  });

  // Murder Post-Mortem (migration 0198): the date shows on "Yes|true"; a
  // saved answer is "Yes" (ticked) or "No" (unticked)
  const pmBox = DynamicFieldDef(
    fieldDefId: 3,
    fieldLabel: 'Post-Mortem',
    fieldKey: 'murder_postmortem',
    fieldSource: 'custom',
    fieldType: 'checkbox',
    isRequired: false,
    displayOrder: 3,
    section: 'Post-Mortem & FSL',
  );
  const pmDate = DynamicFieldDef(
    fieldDefId: 4,
    fieldLabel: 'Date',
    fieldKey: 'murder_postmortem_date',
    fieldSource: 'custom',
    fieldType: 'date',
    isRequired: false,
    displayOrder: 4,
    section: 'Post-Mortem & FSL',
    dependsOnFieldKey: 'murder_postmortem',
    dependsOnValue: 'Yes|true',
  );
  Widget pmCard(dynamic answer) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: DynamicSectionCard(
              title: 'Post-Mortem & FSL',
              icon: Icons.science_outlined,
              fields: const [pmBox, pmDate],
              controllers: {},
              values: {'murder_postmortem': answer},
              onValueChanged: (_, __) {},
              columns: 4,
            ),
          ),
        ),
      );

  for (final answer in ['Yes', true]) {
    testWidgets('saved "$answer": ticked, date inside', (tester) async {
      await tester.pumpWidget(pmCard(answer));
      await tester.pump();
      expect(
          tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Date'), findsNothing);
    });
  }

  for (final answer in ['No', false]) {
    testWidgets('saved "$answer": unticked, no date', (tester) async {
      await tester.pumpWidget(pmCard(answer));
      await tester.pump();
      expect(
          tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(find.byType(TextFormField), findsNothing);
    });
  }
}
