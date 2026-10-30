import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/screens/category_subtabs_screen.dart';
import 'package:khakhi_diary/screens/form_i_v_selection_screen.dart';
import 'package:khakhi_diary/utils/app_constants.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('NAFIS shows the NAFIS and Fingerprint tabs', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: NafisFingerprintScreen(stationName: 'TEST')));
    await tester.pump();
    expect(find.text('Fingerprint'), findsOneWidget);
    expect(find.text('NAFIS/Fingerprint'), findsOneWidget); // title
    expect(find.text('NAFIS'), findsOneWidget); // first tab
  });

  testWidgets('Fingerprint opens a Coming soon page', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: NafisFingerprintScreen(stationName: 'TEST')));
    await tester.tap(find.text('Fingerprint'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsWidgets);
  });

  test('the BNSS tile is named CRPC 156(3)/BNSS 175(3) and still opens bnss',
      () {
    final names = [
      ...Classification.servicesGroup,
      ...Classification.addMenuAll,
    ]
        .where((c) => c.moduleKey == 'bnss')
        .map((c) => c.name.replaceAll('\n', ''));
    expect(names, everyElement('CRPC 156(3)/BNSS 175(3)'));
    for (final label in [
      'CRPC 156(3)/BNSS 175(3)',
      'CRPC 156(3)/\nBNSS 175(3)'
    ]) {
      expect(labelToModuleKey[label], 'bnss');
    }
  });

  testWidgets('DAR/IRAD shows the DAR and IRAD tabs', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: DarIradScreen(stationName: 'TEST')));
    await tester.pump();
    expect(find.text('DAR/IRAD'), findsOneWidget);
    expect(find.text('DAR'), findsOneWidget);
    expect(find.text('IRAD'), findsOneWidget);
  });

  test('DAR/IRAD and NAFIS/Fingerprint replace their single tiles', () {
    final labels = ServiceData.dashboardTools.map((t) => t.label).toList();
    expect(labels, containsAll(['DAR/IRAD', 'NAFIS/Fingerprint']));
    expect(labels, isNot(contains('IRAD')));
    expect(labels, isNot(contains('DAR')));
    expect(labels, isNot(contains('NAFIS')));
  });

  testWidgets('on a phone both tabs sit side by side in one row',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: ModuleTabsScreen(title: 'Murder', tabs: [
        ('Murder', Icons.warning_amber_rounded, (_) {}),
        ('Attempt to Murder', Icons.warning_amber_rounded, (_) {}),
      ]),
    ));
    await tester.pump();
    final first =
        tester.getTopLeft(find.widgetWithText(CategoryGridCard, 'Murder'));
    final second = tester
        .getTopLeft(find.widgetWithText(CategoryGridCard, 'Attempt to Murder'));
    expect(second.dx, greaterThan(first.dx)); // to the right
    expect((second.dy - first.dy).abs(), lessThan(20)); // same row
    expect(tester.takeException(), isNull); // no overflow
  });
}
