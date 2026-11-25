import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khakhi_diary/widgets/custom_pdf_preview_dialog.dart';
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
      'CustomPdfPreviewDialog renders modern UI, actions, and zoom controls',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final pdfBytes = await generateDummyPdf();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => CustomPdfPreviewDialog.show(
              context: context,
              buildPdf: (_) async => pdfBytes,
              title: 'Murder - 321',
              fileName: 'Murder_321.pdf',
            ),
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
    await tester.pump();

    // 1. Open Dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // 2. Verify dialog title and actions
    expect(find.text('Murder - 321'), findsOneWidget);
    expect(find.byTooltip('Close Preview'), findsOneWidget);
    expect(find.byTooltip('Print'), findsOneWidget);
    expect(find.byTooltip('Download PDF'), findsOneWidget);

    // 3. Verify InteractiveViewer exists
    final interactiveViewerFinder = find.byType(InteractiveViewer);
    expect(interactiveViewerFinder, findsOneWidget);

    // 4. Verify zoom toolbar buttons exist
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Reset to fit'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // 5. Verify normal mouse wheel scroll does NOT zoom
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(interactiveViewerFinder),
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);

    // 6. Tap Zoom In
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('125%'), findsOneWidget);

    // 7. Tap Zoom Out
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('100%'), findsOneWidget);

    // 8. Test double-tap to zoom
    final gestureFinder = find
        .descendant(
          of: find.byType(InteractiveViewer),
          matching: find.byType(GestureDetector),
        )
        .last;
    await tester.tap(gestureFinder, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(gestureFinder, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('200%'), findsOneWidget);

    // 9. Double tap again to reset
    await tester.tap(gestureFinder, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(gestureFinder, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('100%'), findsOneWidget);
  });
}
