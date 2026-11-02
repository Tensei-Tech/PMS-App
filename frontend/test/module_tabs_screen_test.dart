import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/providers/module_registry.dart';
import 'package:khakhi_diary/screens/category_subtabs_screen.dart';
import 'package:khakhi_diary/screens/form_i_v_selection_screen.dart';
import 'package:khakhi_diary/utils/app_constants.dart';
import 'package:khakhi_diary/widgets/sub_tab_host.dart';

/// A stand-in sub-tab screen: shows the tab switch in its AppBar like the real
/// hub screens, plus a counter to check that state survives switching tabs.
class _FakeTab extends StatefulWidget {
  final String name;
  const _FakeTab(this.name);

  @override
  State<_FakeTab> createState() => _FakeTabState();
}

class _FakeTabState extends State<_FakeTab> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name} screen'),
        bottom: SubTabHost.appBarBottom(context),
      ),
      body: TextButton(
        onPressed: () => setState(() => taps++),
        child: Text('${widget.name} taps: $taps'),
      ),
    );
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a two-tab tile opens its first tab with a switch to the other',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ModuleTabsScreen(title: 'Murder', tabs: [
        (
          'Murder',
          Icons.warning_amber_rounded,
          (_) => const _FakeTab('Murder')
        ),
        (
          'Attempt to Murder',
          Icons.warning_amber_rounded,
          (_) => const _FakeTab('Attempt')
        ),
      ]),
    ));
    await tester.pump();

    // First tab shown straight away, no chooser cards.
    expect(find.text('Murder screen'), findsOneWidget);
    expect(find.byType(CategoryGridCard), findsNothing);
    expect(find.text('Murder'), findsOneWidget); // switch
    expect(find.text('Attempt to Murder'), findsOneWidget); // switch

    await tester.tap(find.text('Murder taps: 0'));
    await tester.pump();

    // Switch to the second tab.
    await tester.tap(find.text('Attempt to Murder'));
    await tester.pumpAndSettle();
    expect(find.text('Attempt screen'), findsOneWidget);
    expect(find.text('Murder screen'), findsNothing);

    // Back to the first: its state was kept.
    await tester.tap(find.text('Murder').last);
    await tester.pumpAndSettle();
    expect(find.text('Murder taps: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('NAFIS/Fingerprint opens NAFIS first, with a Fingerprint tab',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: NafisFingerprintScreen(stationName: 'TEST')));
    await tester.pump();
    final host = tester.widget<SubTabHost>(find.byType(SubTabHost));
    expect(host.tabs.map((t) => t.label), ['NAFIS', 'Fingerprint']);
    expect(find.text('Fingerprint'), findsOneWidget); // switch
  });

  testWidgets('Fingerprint tab shows a Coming soon page', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: NafisFingerprintScreen(stationName: 'TEST')));
    await tester.pump();
    await tester.tap(find.text('Fingerprint'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsWidgets);
  });

  testWidgets('DAR/IRAD opens DAR first, with an IRAD tab', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: DarIradScreen(stationName: 'TEST')));
    await tester.pump();
    final host = tester.widget<SubTabHost>(find.byType(SubTabHost));
    expect(host.tabs.map((t) => t.label), ['DAR', 'IRAD']);
    expect(find.text('IRAD'), findsOneWidget); // switch
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

  test('DAR/IRAD and NAFIS/Fingerprint replace their single tiles', () {
    final labels = ServiceData.dashboardTools.map((t) => t.label).toList();
    expect(labels, containsAll(['DAR/IRAD', 'NAFIS/Fingerprint']));
    expect(labels, isNot(contains('IRAD')));
    expect(labels, isNot(contains('DAR')));
    expect(labels, isNot(contains('NAFIS')));
  });

  testWidgets('on a phone a tile with more tabs shows them side by side',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: ModuleTabsScreen(title: 'Passport', tabs: [
        ('Passport', Icons.badge_rounded, (_) => const SizedBox()),
        ('Licence', Icons.assignment_ind_rounded, (_) => const SizedBox()),
        ('PVR', Icons.fact_check_rounded, (_) => const SizedBox()),
      ]),
    ));
    await tester.pump();
    final first =
        tester.getTopLeft(find.widgetWithText(CategoryGridCard, 'Passport'));
    final second =
        tester.getTopLeft(find.widgetWithText(CategoryGridCard, 'Licence'));
    expect(second.dx, greaterThan(first.dx)); // to the right
    expect((second.dy - first.dy).abs(), lessThan(20)); // same row
    expect(tester.takeException(), isNull); // no overflow
  });
}
