// A ticked Panchanama checkbox shows its Date & Time inside its box. In a
// narrow box (four per line) the date must fit, not overflow the box.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_control_factory.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';

const _field = DynamicFieldDef(
  fieldDefId: 1,
  fieldLabel: 'Personal Search Panchanama',
  fieldKey: 'personal_search_panchanama',
  fieldSource: 'common',
  fieldType: 'checkbox',
  isRequired: false,
  displayOrder: 1,
  section: 'All Panchnama',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final width in [220.0, 300.0, 330.0, 600.0]) {
    testWidgets('ticked, ${width.toInt()}px wide: date fits its box',
        (tester) async {
      final ctrl = TextEditingController(text: 'true');
      final date = TextEditingController(text: '23/11/2026 16:46');
      addTearDown(ctrl.dispose);
      addTearDown(date.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: DynamicControlFactory(
                fieldDef: _field,
                controller: ctrl,
                value: true,
                dateController: date,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      // An overflow would be reported as a FlutterError here
      expect(tester.takeException(), isNull);
      expect(find.textContaining('23/11/2026', findRichText: true),
          findsOneWidget);
    });
  }
}
