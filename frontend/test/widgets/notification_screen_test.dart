import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khakhi_diary/providers/auth_provider.dart';
import 'package:khakhi_diary/providers/notification_provider.dart';
import 'package:khakhi_diary/screens/notification_screen.dart';
import 'package:khakhi_diary/widgets/module_hub_screen_app_bar.dart';

void main() {
  testWidgets('NotificationScreen renders police theme AppBar, tabs, and empty state', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final authProvider = AuthProvider();
    final notifProvider = NotificationProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
        ],
        child: const MaterialApp(
          home: NotificationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify ModuleHubScreenAppBar renders with title & subtitle
    expect(find.byType(ModuleHubScreenAppBar), findsOneWidget);
    expect(find.text('Notifications & Reminders'), findsOneWidget);
    expect(find.text('Directives, Case Reminders & System Alerts'), findsOneWidget);

    // Verify tabs
    expect(find.text('Case Reminders'), findsOneWidget);
    expect(find.text('System Alerts'), findsOneWidget);

    // Verify Tab 1 empty state
    expect(find.text('No Case Reminders'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_outlined), findsWidgets);

    // Switch to Tab 2
    await tester.tap(find.text('System Alerts'));
    await tester.pumpAndSettle();

    // Verify Tab 2 empty state
    expect(find.text('No System Alerts'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
  });

  testWidgets('NotificationScreen displays notifications and Mark Read button', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final authProvider = AuthProvider();
    final notifProvider = NotificationProvider();
    notifProvider.addNotification(
      title: 'Urgent PCR Notice',
      body: 'Submit PCR report for CR/123/2026',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
        ],
        child: const MaterialApp(
          home: NotificationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Mark Read" button is shown in AppBar
    expect(find.text('Mark Read'), findsOneWidget);

    // Switch to Tab 2 to view the notification
    await tester.tap(find.text('System Alerts'));
    await tester.pumpAndSettle();

    expect(find.text('Urgent PCR Notice'), findsOneWidget);
    expect(find.text('Submit PCR report for CR/123/2026'), findsOneWidget);

    // Tap Mark Read
    await tester.tap(find.text('Mark Read'));
    await tester.pumpAndSettle();

    // Unread count should now be 0, button disappears
    expect(notifProvider.unreadCount, 0);
    expect(find.text('Mark Read'), findsNothing);
  });
}
