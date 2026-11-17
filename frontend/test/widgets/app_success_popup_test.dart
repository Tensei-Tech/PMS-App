import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/app_success_popup.dart';

void main() {
  testWidgets('AppSuccessPopup renders title, message, and close button',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppSuccessPopup.show(
                  context,
                  title: 'Reminder Sent',
                  message: 'Reminder sent to IO for case 2344',
                  autoCloseDuration: const Duration(seconds: 10),
                );
              },
              child: const Text('Show Success'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Success'));
    await tester.pumpAndSettle();

    expect(find.text('Reminder Sent'), findsOneWidget);
    expect(find.text('Reminder sent to IO for case 2344'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Dismiss manually
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Reminder Sent'), findsNothing);
  });

  testWidgets('AppSuccessPopup auto-closes after specified duration',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppSuccessPopup.show(
                  context,
                  title: 'Reminder Sent',
                  message: 'Reminder sent to IO for case 2344',
                  autoCloseDuration: const Duration(milliseconds: 500),
                );
              },
              child: const Text('Show Success'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Reminder Sent'), findsOneWidget);

    // Advance clock past autoCloseDuration (500ms)
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Reminder Sent'), findsNothing);
  });
}
