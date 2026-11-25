import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/pdf_document_view_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<Uint8List> generateDummyPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Center(
          child: pw.Text('MAHARASHTRA STATE POLICE DEPARTMENT'),
        ),
      ),
    );
    return await doc.save();
  }

  testWidgets(
      'PdfDocumentViewScreen renders zoom controls and handles zoom interactions',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final pdfBytes = await generateDummyPdf();

    await tester.pumpWidget(
      MaterialApp(
        home: PdfDocumentViewScreen(
          pdfBytes: pdfBytes,
          moduleName: 'Murder',
        ),
      ),
    );
    await tester.pump();

    // 1. Verify AppBar title and subtitle
    expect(find.text('View Murder'), findsOneWidget);
    expect(find.text('Murder'), findsOneWidget);

    // 2. Verify InteractiveViewer exists
    final interactiveViewerFinder = find.byType(InteractiveViewer);
    expect(interactiveViewerFinder, findsOneWidget);

    // 3. Verify zoom toolbar buttons exist
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Reset to fit'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // 3b. Verify normal mouse wheel scroll does NOT zoom
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(interactiveViewerFinder),
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);

    // 4. Tap Zoom In
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('125%'), findsOneWidget);

    // 5. Tap Zoom In again
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('150%'), findsOneWidget);

    // 6. Tap Zoom Out
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('125%'), findsOneWidget);

    // 7. Tap Reset to fit
    await tester.tap(find.byTooltip('Reset to fit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('100%'), findsOneWidget);

    // 8. Test double-tap to zoom
    final gestureFinder = find.byType(GestureDetector).first;
    await tester.tap(gestureFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(gestureFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('200%'), findsOneWidget);

    // 9. Double tap again to reset
    await tester.tap(gestureFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(gestureFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('100%'), findsOneWidget);
  });
}
