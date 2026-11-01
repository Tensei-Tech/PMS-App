import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:khakhi_diary/modules/form_iv/providers/form_iv_provider.dart';
import 'package:khakhi_diary/modules/form_vi/providers/form_vi_provider.dart';
import 'package:khakhi_diary/screens/disposal_hub_screen.dart';
import 'package:khakhi_diary/screens/disposal_selection_screen.dart';
import 'package:khakhi_diary/screens/form_i_v_selection_screen.dart';

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

  testWidgets(
      'DisposalSelectionScreen shows Disposal title, 2 types, and Form 1 to 5 and Form 6 cards',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Check title and subtitle
    expect(find.text('Disposal'), findsOneWidget);
    expect(find.text('2 types'), findsOneWidget);

    // Check subtab cards
    expect(find.text('Form 1 to 5'), findsOneWidget);
    expect(find.text('Form 6'), findsOneWidget);
  });

  testWidgets(
      'Tapping Form 1 to 5 navigates to DisposalHubScreen with groupId 1',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Form 1 to 5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DisposalHubScreen), findsOneWidget);
    final hub = tester.widget<DisposalHubScreen>(find.byType(DisposalHubScreen));
    expect(hub.groupId, 1);
    expect(hub.groupTitle, 'Form 1 to 5');
  });

  testWidgets(
      'Tapping Form 6 navigates to DisposalHubScreen with groupId 2',
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
    final hub = tester.widget<DisposalHubScreen>(find.byType(DisposalHubScreen));
    expect(hub.groupId, 2);
    expect(hub.groupTitle, 'Form 6');
  });

  testWidgets('on a phone both tabs sit side by side in one row',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final first =
        tester.getTopLeft(find.widgetWithText(CategoryGridCard, 'Form 1 to 5'));
    final second =
        tester.getTopLeft(find.widgetWithText(CategoryGridCard, 'Form 6'));
    expect(second.dx, greaterThan(first.dx)); // to the right
    expect((second.dy - first.dy).abs(), lessThan(20)); // same row
    expect(tester.takeException(), isNull); // no overflow
  });
}
