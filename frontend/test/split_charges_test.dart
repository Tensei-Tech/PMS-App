// test/split_charges_test.dart
// Integration and Widget verification for Split Charges (Act -> Section -> Subsection)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/repeating_cascading_charges_selector.dart';

void main() {
  testWidgets(
      'RepeatingCascadingChargesSelector renders Act, Section, Subsection dropdowns and Add Charge button',
      (WidgetTester tester) async {
    List<Map<String, dynamic>>? capturedCharges;

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepeatingCascadingChargesSelector(
                initialCharges: const [
                  {'act_id': 1, 'section_id': 103}
                ],
                onChargesChanged: (charges) {
                  capturedCharges = charges;
                },
              ),
            ),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));
    });

    await tester.pump();

    // Verify initial Charge #1 header and labels
    expect(find.text('Charge #1'), findsOneWidget);
    expect(find.text('Act / Law'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Subsection (Optional)'), findsOneWidget);
    expect(find.text('Add Another Charge'), findsOneWidget);

    // Tap 'Add Another Charge' button
    await tester.tap(find.text('Add Another Charge'));
    await tester.pump();

    // Verify Charge #2 is created
    expect(find.text('Charge #2'), findsOneWidget);
    expect(capturedCharges, isNotNull);
    expect(capturedCharges!.length, equals(2));
  });
}
