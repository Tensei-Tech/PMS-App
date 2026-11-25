// CCTV & CDR row (CDR dates, then CCTV Checked last): the CCTV Checked box
// is the same height as the two date boxes and sits level with them.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_field_model.dart';
import 'package:khakhi_diary/widgets/dynamic_form/dynamic_section_builder.dart';

DynamicFieldDef _f(int id, String label, String key, String type) =>
    DynamicFieldDef(
      fieldDefId: id,
      fieldLabel: label,
      fieldKey: key,
      fieldSource: 'common',
      fieldType: type,
      isRequired: false,
      displayOrder: id,
      section: 'CCTV and CDR Investigation',
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final ticked in [false, true]) {
    testWidgets('checkbox box level with date boxes (ticked: $ticked)',
        (tester) async {
      tester.view.physicalSize = const Size(1500, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controllers = <String, TextEditingController>{};
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1450,
              child: DynamicSectionCard(
                title: 'CCTV and CDR Investigation',
                icon: Icons.videocam_outlined,
                fields: [
                  _f(1, 'CDR Sent Date', 'cdr_sent_date', 'date'),
                  _f(2, 'CDR Received Date', 'cdr_received_date', 'date'),
                  _f(3, 'CCTV Checked', 'cctv_checked', 'checkbox'),
                ],
                controllers: controllers,
                values: {'cctv_checked': ticked},
                onValueChanged: (_, __) {},
                columns: 3,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      final box = tester.getRect(find
          .ancestor(
              of: find.text('CCTV Checked'),
              matching: find.byWidgetPredicate(
                  (w) => w is Container && w.decoration is BoxDecoration))
          .first);
      final dates = tester
          .widgetList(find.byType(TextFormField))
          .map((w) => tester.getRect(find.byWidget(w)))
          .toList();
      expect(dates, hasLength(2));
      for (final d in dates) {
        expect(box.left, greaterThan(d.right), reason: 'CCTV Checked is last');
        expect(box.top, moreOrLessEquals(d.top, epsilon: 0.5));
        expect(box.bottom, moreOrLessEquals(d.bottom, epsilon: 0.5));
      }
    });
  }
}
