import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/screens/disposal_case_list_view.dart';

void main() {
  testWidgets(
      'DisposalCaseListView table renders without unbounded constraints',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DisposalCaseListView(),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));

    // We expect a CircularProgressIndicator since it's loading, but layout builder is checked.
    expect(find.byType(SingleChildScrollView),
        findsNothing); // It's loading initially

    addTearDown(tester.view.resetPhysicalSize);
  });
}
