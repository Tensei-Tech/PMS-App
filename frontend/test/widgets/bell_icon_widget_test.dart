import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/providers/notification_provider.dart';
import 'package:khakhi_diary/widgets/bell_icon_widget.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('BellIconWidget shows hover preview box on mouse enter',
      (tester) async {
    final provider = NotificationProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: BellIconWidget(),
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.byType(BellIconWidget)));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No new notifications'), findsOneWidget);
    expect(find.text('View all notifications'), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();

    expect(find.text('Notifications'), findsNothing);
  });
}
