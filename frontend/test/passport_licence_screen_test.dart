import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:khakhi_diary/modules/pvr/providers/pvr_provider.dart';
import 'package:khakhi_diary/modules/pvr/screens/pvr_hub_screen.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/screens/category_subtabs_screen.dart';
import 'package:khakhi_diary/utils/app_constants.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PvrProvider()),
      ],
      child: const MaterialApp(
        home: PassportLicenceScreen(stationName: 'TEST'),
      ),
    );
  }

  testWidgets('Passport/PVR/Licence shows the Passport, Licence, and PVR tabs',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();
    expect(find.text('Passport/PVR/Licence'), findsOneWidget); // title
    expect(find.text('Passport'), findsOneWidget); // first tab
    expect(find.text('Licence'), findsOneWidget); // second tab
    expect(find.text('PVR'), findsOneWidget); // third tab
    expect(find.textContaining('cases'), findsNothing);
  });

  testWidgets(
      'Tapping PVR opens PvrHubScreen with Total, Verified, and Pending options',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.tap(find.text('PVR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PvrHubScreen), findsOneWidget);

    // Verify 3 options in PVR: Total, Verified, Pending
    expect(find.text('Total'), findsWidgets);
    expect(find.text('Verified'), findsWidgets);
    expect(find.text('Pending'), findsWidgets);
  });

  test('Licence is no longer its own dashboard tile', () {
    expect(ServiceData.dashboardTools.map((t) => t.label),
        isNot(contains('Licence')));
  });
}
