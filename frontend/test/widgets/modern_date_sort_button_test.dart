import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/modern_date_sort_button.dart';

void main() {
  testWidgets(
      'ModernDateSortButton renders active option and handles selection',
      (tester) async {
    String selected = 'newest_incident';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: ModernDateSortButton(
                  selectedKey: selected,
                  onSelected: (val) {
                    setState(() => selected = val);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    // Initial state: "Newest"
    expect(find.text('Newest'), findsOneWidget);

    // Tap to open popup
    await tester.tap(find.text('Newest'));
    await tester.pumpAndSettle();

    // Verify 3 options exist in menu
    expect(find.text('Newest first'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);
    expect(find.text('Recently added'), findsOneWidget);

    // Tap "Oldest first"
    await tester.tap(find.text('Oldest first'));
    await tester.pumpAndSettle();

    // Verify state updated to "Oldest"
    expect(selected, 'oldest_incident');
    expect(find.text('Oldest'), findsOneWidget);
  });
}
