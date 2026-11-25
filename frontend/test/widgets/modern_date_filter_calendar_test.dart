import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:khakhi_diary/widgets/modern_date_filter_calendar.dart';

void main() {
  group('ModernDateFilterCalendar Widget Tests', () {
    testWidgets(
        'renders trigger button and shows Date Filter when not filtered',
        (tester) async {
      DateTimeRange? selectedRange;
      String? presetLabel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernDateFilterCalendar(
                selectedDateRange: selectedRange,
                datePresetLabel: presetLabel,
                onDateRangeChanged: (range) => selectedRange = range,
                onPresetLabelChanged: (label) => presetLabel = label,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Date Filter'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
    });

    testWidgets(
        'renders active date filter label and clear button when filtered',
        (tester) async {
      final today = DateTime.now();
      final range = DateTimeRange(
        start: DateTime(today.year, today.month, 1),
        end: DateTime(today.year, today.month, today.day),
      );

      DateTimeRange? activeRange = range;
      String? activePreset = 'This Month';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return ModernDateFilterCalendar(
                    selectedDateRange: activeRange,
                    datePresetLabel: activePreset,
                    onDateRangeChanged: (r) => setState(() => activeRange = r),
                    onPresetLabelChanged: (p) =>
                        setState(() => activePreset = p),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Date: This Month'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(activeRange, isNull);
      expect(activePreset, isNull);
      expect(find.text('Date Filter'), findsOneWidget);
    });

    testWidgets(
        'tapping trigger opens popover with 3 options and calendar on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      DateTimeRange? activeRange;
      String? activePreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ModernDateFilterCalendar(
                  selectedDateRange: activeRange,
                  datePresetLabel: activePreset,
                  onDateRangeChanged: (r) => activeRange = r,
                  onPresetLabelChanged: (p) => activePreset = p,
                ),
              ),
            ),
          ),
        ),
      );

      // Tap trigger button to open popover
      await tester.tap(find.text('Date Filter'));
      await tester.pumpAndSettle();

      // Check popover elements (the 3 streamlined options)
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Range'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('Mo'), findsOneWidget);
      expect(find.text('Tu'), findsOneWidget);
      expect(find.text('Su'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done to close
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets('selecting Today sets date range to today', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      DateTimeRange? activeRange;
      String? activePreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ModernDateFilterCalendar(
                  selectedDateRange: activeRange,
                  datePresetLabel: activePreset,
                  onDateRangeChanged: (r) => activeRange = r,
                  onPresetLabelChanged: (p) => activePreset = p,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Date Filter'));
      await tester.pumpAndSettle();

      // Tap on the Today segment
      await tester.tap(find.text('Today').first);
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(activeRange, isNotNull);
      expect(activePreset, 'Today');
      expect(activeRange!.start.day, now.day);
    });

    testWidgets('selecting Range and preset applies date range',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      DateTimeRange? activeRange;
      String? activePreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ModernDateFilterCalendar(
                  selectedDateRange: activeRange,
                  datePresetLabel: activePreset,
                  onDateRangeChanged: (r) => activeRange = r,
                  onPresetLabelChanged: (p) => activePreset = p,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Date Filter'));
      await tester.pumpAndSettle();

      // Tap on the Range segment
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();

      // Tap on This Week preset chip
      expect(find.text('This Week'), findsOneWidget);
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      expect(activeRange, isNotNull);
      expect(activePreset, 'This Week');
    });

    testWidgets(
        'custom date picker allows single-day and 2-day range selection',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      DateTimeRange? activeRange;
      String? activePreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ModernDateFilterCalendar(
                  selectedDateRange: activeRange,
                  datePresetLabel: activePreset,
                  onDateRangeChanged: (r) => activeRange = r,
                  onPresetLabelChanged: (p) => activePreset = p,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Date Filter'));
      await tester.pumpAndSettle();

      // Tap on day 15 in the month grid
      final day15 = find.text('15').first;
      await tester.tap(day15);
      await tester.pumpAndSettle();

      // 1st tap creates single-day range
      expect(activeRange, isNotNull);
      expect(activeRange!.start.day, 15);
      expect(activeRange!.end.day, 15);
      expect(activePreset, isNull);

      // Tap day 20 to extend to a range
      final day20 = find.text('20').first;
      await tester.tap(day20);
      await tester.pumpAndSettle();

      // 2nd tap extends the range from 15 to 20
      expect(activeRange!.start.day, 15);
      expect(activeRange!.end.day, 20);

      // Tap trash button inside popover to clear
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(activeRange, isNull);
      expect(activePreset, isNull);
    });

    testWidgets(
        'future dates cannot be selected and forward month navigation is disabled for future months',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      DateTimeRange? activeRange;
      String? activePreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ModernDateFilterCalendar(
                  selectedDateRange: activeRange,
                  datePresetLabel: activePreset,
                  onDateRangeChanged: (r) => activeRange = r,
                  onPresetLabelChanged: (p) => activePreset = p,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Date Filter'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      // If today is not the last day of the month, test tapping a future day in this month
      final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
      if (now.day < daysInCurrentMonth) {
        final futureDayNum = now.day + 1;
        final futureDayFinder = find.text('$futureDayNum');
        if (futureDayFinder.evaluate().isNotEmpty) {
          await tester.tap(futureDayFinder.first);
          await tester.pumpAndSettle();
          // activeRange should still be null because future day cannot be selected
          expect(activeRange, isNull);
        }
      }

      // Verify that next month chevron is disabled (cannot navigate past current month)
      final chevronRight = find.byIcon(Icons.chevron_right_rounded);
      expect(chevronRight, findsOneWidget);
      await tester.tap(chevronRight);
      await tester.pumpAndSettle();

      // Month text should still be the current month, not next month
      final expectedMonth = DateFormat('MMMM yyyy').format(now);
      expect(find.text(expectedMonth), findsOneWidget);
    });

    testWidgets('companion sort button toggles sort order', (tester) async {
      bool isNewest = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return ModernDateFilterCalendar(
                    selectedDateRange: null,
                    showSortCompanion: true,
                    isNewestFirst: isNewest,
                    onDateRangeChanged: (_) {},
                    onSortOrderChanged: (val) => setState(() => isNewest = val),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Newest'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

      await tester.tap(find.text('Newest'));
      await tester.pumpAndSettle();

      expect(isNewest, isFalse);
      expect(find.text('Oldest'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('works on mobile screen size without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernDateFilterCalendar(
                selectedDateRange: null,
                onDateRangeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Date Filter'));
      await tester.pumpAndSettle();

      // Bottom sheet is rendered on mobile
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Range'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
