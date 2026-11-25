import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/screens/absconded_hub_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('AbscondedHubScreen tabs are swipeable via drag gestures',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: AbscondedHubScreen(stationName: 'Test Station'),
      ),
    );
    await tester.pump();

    // Verify TabBarView exists and has controller attached
    final tabBarViewFinder = find.byType(TabBarView);
    expect(tabBarViewFinder, findsOneWidget);

    final TabBarView tabBarView = tester.widget<TabBarView>(tabBarViewFinder);
    expect(tabBarView.physics, isNot(isA<NeverScrollableScrollPhysics>()));
    expect(tabBarView.controller?.index, 0);

    // Swipe left (from index 0: Case Wise -> index 1: Time Wise)
    await tester.fling(tabBarViewFinder, const Offset(-600, 0), 1000);
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (tabBarView.controller?.index == 1) break;
    }

    expect(tabBarView.controller?.index, 1);

    // Swipe left again (from index 1: Time Wise -> index 2: IO Wise)
    await tester.fling(tabBarViewFinder, const Offset(-600, 0), 1000);
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (tabBarView.controller?.index == 2) break;
    }

    expect(tabBarView.controller?.index, 2);

    // Swipe right (from index 2: IO Wise -> index 1: Time Wise)
    await tester.fling(tabBarViewFinder, const Offset(600, 0), 1000);
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (tabBarView.controller?.index == 1) break;
    }

    expect(tabBarView.controller?.index, 1);
  });
}
