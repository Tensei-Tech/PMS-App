import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:khakhi_diary/modules/pvr/providers/pvr_provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/screens/category_subtabs_screen.dart';

/// Sub-tabs of dashboard tiles follow the dashboard_subtabs rows; with no rows
/// the built-in sub-tabs stay.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(DashboardSubtabs.clear);

  Widget passport() => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PvrProvider()),
        ],
        child: const MaterialApp(
          home: PassportLicenceScreen(stationName: 'TEST'),
        ),
      );

  testWidgets('Passport tile shows the table rows, in their order',
      (tester) async {
    DashboardSubtabs.setRows([
      {
        'parent_key': 'passport',
        'label': 'PVR',
        'screen_key': 'pvr',
        'icon': 'fact_check_rounded',
        'display_order': 10
      },
      {
        'parent_key': 'passport',
        'label': 'Passport',
        'screen_key': 'passport',
        'icon': 'badge_rounded',
        'display_order': 20
      },
      {
        'parent_key': 'passport',
        'label': 'Licence',
        'screen_key': 'licence',
        'icon': 'assignment_ind_rounded',
        'display_order': 30
      },
      {
        'parent_key': 'passport',
        'label': 'Arms',
        'screen_key': 'arms',
        'display_order': 40,
        'is_active': false
      },
    ]);
    await tester.pumpWidget(passport());
    await tester.pump();
    expect(find.text('PVR'), findsOneWidget);
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Licence'), findsOneWidget);
    expect(find.text('Arms'), findsNothing); // inactive row
    expect(
      tester.getTopLeft(find.text('PVR')).dx,
      lessThan(tester.getTopLeft(find.text('Passport')).dx),
    );
  });

  testWidgets('With no rows the built-in sub-tabs stay', (tester) async {
    await tester.pumpWidget(passport());
    await tester.pump();
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Licence'), findsOneWidget);
    expect(find.text('PVR'), findsOneWidget);
  });

  test('Category rows give a tile its "1 to 5" sub-tabs', () {
    DashboardSubtabs.setRows([
      {
        'parent_key': 'murder',
        'label': 'Murder',
        'screen_key': 'category',
        'icon': 'gavel_rounded',
        'display_order': 10
      },
      {
        'parent_key': 'murder',
        'label': 'Attempt to Murder',
        'screen_key': 'category',
        'icon': 'gavel_rounded',
        'display_order': 20
      },
      {
        'parent_key': 'theft',
        'label': 'Theft',
        'screen_key': 'category',
        'display_order': 10
      },
    ]);
    final murder = CategorySubtabsScreen.forTile('murder')!;
    expect(murder.subtabs.map((t) => t.$1), ['Murder', 'Attempt to Murder']);
    // A tile the app had no sub-tabs for gets them from the table
    final theft = CategorySubtabsScreen.forTile('theft', title: 'Theft')!;
    expect(theft.title, 'Theft');
    expect(theft.subtabs.map((t) => t.$1), ['Theft']);
  });

  test('Without rows Murder keeps its built-in sub-tabs', () {
    final murder = CategorySubtabsScreen.forTile('murder')!;
    expect(murder.subtabs.map((t) => t.$1), ['Murder', 'Attempt to Murder']);
    expect(CategorySubtabsScreen.forTile('theft'), isNull);
  });
}
