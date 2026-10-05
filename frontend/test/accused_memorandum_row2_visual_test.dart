import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/widgets/accused_memorandum_form_view.dart';
import 'package:khakhi_diary/utils/accused_memorandum_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  EditableText.debugDeterministicCursor = true;
  const artifactDir =
      r'C:\Users\TANISHK.GUPTA\.gemini\antigravity-ide\brain\c35725f3-9b7b-431f-8db3-aa885368f227';

  Future<void> captureWidgetScreenshot(
    WidgetTester tester,
    GlobalKey repaintKey,
    String filename,
  ) async {
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final img = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          File('$artifactDir/$filename')
              .writeAsBytesSync(byteData.buffer.asUint8List());
        }
      }
    });
  }

  group('Accused Memorandum Row 2 Visual Tests', () {
    testWidgets('PDF Row 2 - Empty state', (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: repaintKey,
                child: accusedMemorandumPg1Widget({}),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await captureWidgetScreenshot(
          tester, repaintKey, 'accused_memo_pdf_empty.png');
    });

    testWidgets('PDF Row 2 - Filled state with long FIR No and Date',
        (WidgetTester tester) async {
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: repaintKey,
                child: accusedMemorandumPg1Widget({
                  'dist': 'पुणे ग्रामीण (Pune Rural)',
                  'ps': 'हवेली पोलीस ठाणे',
                  'year': '2026',
                  'firNo': 'CR/10928374/2026',
                  'firDate': '05/10/2026',
                  'accusedName': 'रमेश बाळू शिंदे',
                  'accusedAge': '32',
                  'accusedSex': 'पुरुष',
                  'arrestDate': '05/10/2026',
                  'arrestTime': '14:30',
                }),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await captureWidgetScreenshot(
          tester, repaintKey, 'accused_memo_pdf_filled.png');
    });

    testWidgets('Form Row 2 - Empty state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 1000,
              child: RepaintBoundary(
                key: repaintKey,
                child: const AccusedMemorandumFormView(formSection: 'part1'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await captureWidgetScreenshot(
          tester, repaintKey, 'accused_memo_form_empty.png');
    });

    testWidgets('Form Row 2 - Filled state with long FIR No and Date',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 1000,
              child: RepaintBoundary(
                key: repaintKey,
                child: const AccusedMemorandumFormView(
                  formSection: 'part1',
                  existingRecord: {
                    'dist': 'पुणे ग्रामीण (Pune Rural)',
                    'ps': 'हवेली पोलीस ठाणे (Haveli P.S.)',
                    'year': '2026',
                    'firNo': 'CR/10928374/2026',
                    'firNoRaw': 'CR/10928374',
                    'firYearSuffix': '26',
                    'firDate': '05/10/2026',
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await captureWidgetScreenshot(
          tester, repaintKey, 'accused_memo_form_filled.png');
    });
  });
}
