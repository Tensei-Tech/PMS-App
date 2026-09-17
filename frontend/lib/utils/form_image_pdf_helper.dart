import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Reusable engine for image-based PDF generation in the Forms tab.
///
/// Renders pages as native Flutter widgets inside an offscreen [OverlayEntry],
/// captures them at high DPI (2.0x, 1588x2246 px) via Skia/HarfBuzz, and
/// compiles them into clean A4 PDF documents.
///
/// This resolves all Indic/Devanagari matra, conjunct, and halant shaping
/// bugs that occur when the standard `pdf` package renders Devanagari text.
class FormImagePdfHelper {
  static const double a4Width = 794.0;
  static const double a4Height = 1123.0;
  static const double defaultPixelRatio = 2.0;

  /// Captures a single Flutter widget to PNG bytes.
  static Future<Uint8List> captureWidget(
    BuildContext context,
    Widget widget, {
    double width = a4Width,
    double height = a4Height,
    double pixelRatio = defaultPixelRatio,
    Duration delay = const Duration(milliseconds: 700),
  }) async {
    final key = GlobalKey();
    final comp = Completer<Uint8List>();
    OverlayEntry? ent;

    ent = OverlayEntry(
      builder: (_) => Positioned(
        left: -(width + 80),
        top: 0,
        width: width,
        height: height,
        child: RepaintBoundary(
          key: key,
          child: Material(
            color: Colors.white,
            child: widget,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(ent);

    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(delay);

    try {
      final rb = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (rb == null) {
        throw StateError('Failed to locate RenderRepaintBoundary for offscreen page');
      }
      final img = await rb.toImage(pixelRatio: pixelRatio);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      comp.complete(bd!.buffer.asUint8List());
    } catch (e, st) {
      comp.completeError(e, st);
    } finally {
      ent.remove();
    }

    return comp.future;
  }

  /// Captures a list of page widgets and assembles them into an A4 PDF document.
  static Future<Uint8List> buildPdfFromWidgets(
    BuildContext context,
    List<Widget> pages, {
    double width = a4Width,
    double height = a4Height,
    double pixelRatio = defaultPixelRatio,
    Duration delay = const Duration(milliseconds: 700),
  }) async {
    final pngs = <Uint8List>[];
    for (final page in pages) {
      final png = await captureWidget(
        context,
        page,
        width: width,
        height: height,
        pixelRatio: pixelRatio,
        delay: delay,
      );
      pngs.add(png);
    }

    final pdfDoc = pw.Document();
    for (final png in pngs) {
      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            pw.MemoryImage(png),
            fit: pw.BoxFit.contain,
          ),
        ),
      );
    }

    return pdfDoc.save();
  }

  /// High-level preview method: builds the PDF from widget pages and launches
  /// [Printing.sharePdf] on web or [Printing.layoutPdf] on desktop/mobile.
  static Future<void> previewImageBasedPdf(
    BuildContext context, {
    required String fileName,
    required List<Widget> pages,
    Future<Uint8List> Function()? fallbackPdfGenerator,
  }) async {
    try {
      final bytes = await buildPdfFromWidgets(context, pages);
      if (!context.mounted) return;
      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
      }
    } catch (e) {
      debugPrint('Error in FormImagePdfHelper.previewImageBasedPdf: $e');
      if (fallbackPdfGenerator != null && context.mounted) {
        try {
          final fallbackBytes = await fallbackPdfGenerator();
          await Printing.sharePdf(bytes: fallbackBytes, filename: fileName);
        } catch (_) {}
      } else {
        rethrow;
      }
    }
  }

  // ── Standard Devanagari Typography Helpers ─────────────────────────────────

  static TextStyle mReg([double sz = 10.5, double ht = 1.45]) =>
      GoogleFonts.notoSansDevanagari(
        fontSize: sz,
        height: ht,
        color: Colors.black87,
      );

  static TextStyle mBld([double sz = 10.5, double ht = 1.45]) =>
      GoogleFonts.notoSansDevanagari(
        fontSize: sz,
        height: ht,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );

  static TextStyle valStyle([double sz = 10.5]) =>
      GoogleFonts.notoSansDevanagari(
        fontSize: sz,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0D47A1),
      );

  /// Helper to wrap children in a standard A4 page container
  static Widget buildA4Page({
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Container(
      width: a4Width,
      height: a4Height,
      padding: padding,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}
