import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/summary_category_filter_bar.dart';

void main() {
  testWidgets(
      'SummaryCategoryFilterBar groups excess categories into More menu',
      (tester) async {
    String selected = 'All';
    final counts = <String, int>{
      '498 (A) IPC': 1,
      'Assault': 2,
      'Attempt to Murder': 4,
      'CBT': 5,
      'Chain Snatching': 3,
      'Murder': 10,
      'Robbery': 6,
      'Theft': 8,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SummaryCategoryFilterBar(
                totalCount: 39,
                categoryCounts: counts,
                selectedCategory: selected,
                onSelected: (cat) => setState(() => selected = cat),
              );
            },
          ),
        ),
      ),
    );

    // Top 5 by count (Murder=10, Theft=8, Robbery=6, CBT=5, Attempt to Murder=4) + All + More(3).
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Murder'), findsOneWidget);
    expect(find.text('Theft'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('498 (A) IPC'), findsNothing);

    // Open More menu and select an overflow category.
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('498 (A) IPC'), findsOneWidget);
    await tester.tap(find.text('498 (A) IPC'));
    await tester.pumpAndSettle();

    expect(selected, '498 (A) IPC');
    expect(find.text('498 (A) IPC'), findsOneWidget);
    expect(find.text('More'), findsNothing);
  });
}
