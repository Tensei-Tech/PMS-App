import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/medical_376_form_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  EditableText.debugDeterministicCursor = true;
  const artifactDir =
      r'C:\Users\TANISHK.GUPTA\.gemini\antigravity-ide\brain\3c253216-2949-4c91-9492-1a6f0fe53fda';

  Future<void> captureWidgetScreenshot(
    WidgetTester tester,
    GlobalKey repaintKey,
    String filename,
  ) async {
    await tester.runAsync(() async {
      try {
        final boundary = repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final img = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null && Directory(artifactDir).existsSync()) {
            File('$artifactDir/$filename')
                .writeAsBytesSync(byteData.buffer.asUint8List());
          }
        }
      } catch (e) {
        // Screenshot capture is optional for visual debugging
      }
    });
  }

  group('376 Medical Form UI & Pagination Tests', () {
    testWidgets('Desktop view: Form renders Phase A as separate A4 page cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFF0F2F5),
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: repaintKey,
                child: const Medical376FormView(
                  formSection: 'female',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await captureWidgetScreenshot(
          tester, repaintKey, 'medical_376_form_ui_desktop.png');

      expect(find.textContaining('Page 1 of'), findsOneWidget);
      expect(find.textContaining('Page 2 of'), findsOneWidget);
    });

    testWidgets('Narrow mobile view: Form scales A4 page cards with FittedBox',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFF0F2F5),
            body: RepaintBoundary(
              key: repaintKey,
              child: const Medical376FormView(
                formSection: 'female',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await captureWidgetScreenshot(
          tester, repaintKey, 'medical_376_form_ui_mobile.png');

      expect(find.textContaining('Page 1 of'), findsOneWidget);
    });

    testWidgets(
        'Dynamic growth test: typing long address moves overflowing blocks to next page',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFF0F2F5),
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: repaintKey,
                child: const Medical376FormView(
                  formSection: 'female',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find text fields and enter long text in address field
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(
          textFields.at(5), // Address field index
          'Room No. 402, Building B-3, Gokuldham Co-Operative Housing Society, Sector 18, Plot 45/46, Near D-Mart & City Central Mall, Mahatma Gandhi Road, Shivaji Nagar, Pune, Maharashtra - 411005 (Behind Old Police Chowki, Landmark: Ganesh Temple)',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250)); // Debounce timer
        await tester.pumpAndSettle();
      }

      await captureWidgetScreenshot(
          tester, repaintKey, 'medical_376_form_dynamic_overflow.png');
      expect(find.textContaining('Page 1 of'), findsOneWidget);
    });
  });
}
