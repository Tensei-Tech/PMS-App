import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/logout_confirm_dialog.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<bool?> tapIn(WidgetTester tester, String button) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await confirmLogout(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(
        button == 'Cancel' ? TextButton : ElevatedButton, button));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('Cancel keeps the user logged in', (tester) async {
    expect(await tapIn(tester, 'Cancel'), isFalse);
  });

  testWidgets('Log out confirms', (tester) async {
    expect(await tapIn(tester, 'Log out'), isTrue);
  });
}
