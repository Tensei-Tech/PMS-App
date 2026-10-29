import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/screens/category_subtabs_screen.dart';
import 'package:khakhi_diary/utils/app_constants.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('NAFIS shows the NAFIS and Fingerprint tabs', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: NafisFingerprintScreen(stationName: 'TEST')));
    await tester.pump();
    expect(find.text('Fingerprint'), findsOneWidget);
    expect(find.text('NAFIS'), findsWidgets); // title and first tab
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
}
