import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/settings_provider.dart';
import 'package:khakhi_diary/widgets/dashboard_stats_widget.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('DashboardStatsWidget renders nothing when session is inactive',
      (WidgetTester tester) async {
    final auth = AuthProvider();
    // Default isSessionActive is false
    expect(auth.isSessionActive, isFalse);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DashboardStatsWidget(auth: auth),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(DashboardStatsWidget), findsOneWidget);
    // When session is inactive, it returns SizedBox.shrink()
    expect(find.byType(Card), findsNothing);
  });

  testWidgets(
      'DashboardStatsWidget mounts, observes lifecycle and disposes cleanly without timer leaks',
      (WidgetTester tester) async {
    final auth = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DashboardStatsWidget(auth: auth),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify lifecycle transitions do not crash or leak
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Unmount widget to trigger dispose() and timer cancellation
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DashboardStatsWidget), findsNothing);
  });
}
