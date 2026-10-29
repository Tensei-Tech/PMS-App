import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/screens/category_subtabs_screen.dart';
import 'package:khakhi_diary/utils/app_constants.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Passport/PVR/Licence shows the Passport and Licence tabs',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PassportLicenceScreen()));
    await tester.pump();
    expect(
        find.text('Passport/PVR/Licence'), findsWidgets); // title and first tab
    expect(find.text('Licence'), findsOneWidget);
    expect(find.textContaining('cases'), findsNothing);
  });

  test('Licence is no longer its own dashboard tile', () {
    expect(ServiceData.dashboardTools.map((t) => t.label),
        isNot(contains('Licence')));
  });
}
