import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/modules/form_vi/providers/form_vi_provider.dart';
import 'package:khakhi_diary/screens/disposal_hub_screen.dart';
import 'package:khakhi_diary/screens/disposal_selection_screen.dart';
import 'package:khakhi_diary/widgets/sub_tab_host.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FormIVProvider()),
        ChangeNotifierProvider(create: (_) => FormVIProvider()),
      ],
      child: const MaterialApp(
        home: DisposalSelectionScreen(stationName: 'TEST Station'),
      ),
    );
  }

  DisposalHubScreen visibleHub(WidgetTester tester) =>
      tester.widget<DisposalHubScreen>(find.byType(DisposalHubScreen));

  testWidgets('Disposal opens Form 1 to 5 first, with a switch to Form 6',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final host = tester.widget<SubTabHost>(find.byType(SubTabHost));
    expect(host.tabs.map((t) => t.label), ['Form 1 to 5', 'Form 6']);

    // First tab's hub is shown straight away.
    expect(find.byType(DisposalHubScreen), findsOneWidget);
    expect(visibleHub(tester).groupId, 1);
    expect(visibleHub(tester).groupTitle, 'Form 1 to 5');
    expect(find.text('Form 6'), findsOneWidget); // switch
  });

  testWidgets('Tapping Form 6 shows DisposalHubScreen with groupId 2',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Form 6'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DisposalHubScreen), findsOneWidget);
    expect(visibleHub(tester).groupId, 2);
    expect(visibleHub(tester).groupTitle, 'Form 6');
  });

  testWidgets('on a phone both switch buttons sit side by side in one row',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final first = tester.getTopLeft(find.text('Form 1 to 5').last);
    final second = tester.getTopLeft(find.text('Form 6'));
    expect(second.dx, greaterThan(first.dx)); // to the right
    expect((second.dy - first.dy).abs(), lessThan(20)); // same row
    expect(tester.takeException(), isNull); // no overflow
  });
}
