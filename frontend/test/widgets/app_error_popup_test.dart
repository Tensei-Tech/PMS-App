import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/app_error_popup.dart';

void main() {
  testWidgets('AppErrorPopup renders title, message, and close button',
      (WidgetTester tester) async {
    bool dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppErrorPopup.show(
                  context,
                  title: 'Network Timeout',
                  message: 'The request took too long to complete.',
                  onDismiss: () => dismissed = true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    // Open popup
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Network Timeout'), findsOneWidget);
    expect(find.text('The request took too long to complete.'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Tap Close (X)
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Network Timeout'), findsNothing);
    expect(dismissed, isTrue);
  });

  testWidgets('AppErrorPopup retry executes callback and dismisses',
      (WidgetTester tester) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppErrorPopup.show(
                  context,
                  title: 'Server Error',
                  message: 'Something went wrong.',
                  onRetry: () async {
                    retried = true;
                  },
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retried, isTrue);
    expect(find.text('Server Error'), findsNothing);
  });
}
