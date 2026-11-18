import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/module_hub_screen_app_bar.dart';

void main() {
  testWidgets(
      'ModuleHubScreenAppBar shifts actionWidget to right corner on mobile',
      (WidgetTester tester) async {
    // Set mobile viewport width
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ModuleHubScreenAppBar(
            title: 'Form I-V Cases',
            subtitle: '50 cases · 28 types',
            actionWidget: ElevatedButton(
              key: const Key('add_case_btn'),
              onPressed: () {},
              child: const Text('Add Case'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final btnFinder = find.byKey(const Key('add_case_btn'));
    expect(btnFinder, findsOneWidget);

    final btnBox = tester.getRect(btnFinder);
    // On 390-wide screen, the button should sit near the right corner (e.g. right > 350)
    expect(btnBox.right, greaterThan(350));
  });

  testWidgets(
      'ModuleHubScreenAppBar shifts onAddPressed to right corner on mobile',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ModuleHubScreenAppBar(
            title: 'Pending Cases',
            subtitle: '20 cases',
            onAddPressed: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final btnFinder = find.widgetWithText(ElevatedButton, 'Add Case');
    expect(btnFinder, findsOneWidget);

    final btnBox = tester.getRect(btnFinder);
    expect(btnBox.right, greaterThan(350));
  });

  testWidgets(
      'ModuleHubScreenAppBar triggers onBackPressed on Escape key shortcut',
      (WidgetTester tester) async {
    bool backTriggered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ModuleHubScreenAppBar(
            title: 'Pending Cases',
            subtitle: '20 cases',
            onBackPressed: () => backTriggered = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(backTriggered, isTrue);
  });

  testWidgets(
      'ModuleHubScreenAppBar triggers onSearchShortcut on Slash key shortcut',
      (WidgetTester tester) async {
    bool searchTriggered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ModuleHubScreenAppBar(
            title: 'Pending Cases',
            subtitle: '20 cases',
            onSearchShortcut: () => searchTriggered = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pumpAndSettle();

    expect(searchTriggered, isTrue);
  });
}
