import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Conditional import for native browser fast JPEG encoding
import 'native_jpeg_encoder_stub.dart'
    if (dart.library.js_interop) 'native_jpeg_encoder_web.dart';

/// High-performance engine for image-based PDF generation in the Forms tab.
///
/// Optimizations:
/// - Native browser canvas JPEG encoding (zero Dart pure-CPU encoding penalty)
/// - Direct JPEG stream injection into pw.Document (avoids deflate recompression)
/// - Pipelined page processing with event-loop yielding
/// - Optimal pixelRatio 2.0 for razor-sharp Devanagari text at minimal file size
class FormImagePdfHelper {
  static const double a4Width = 794.0;
  static const double a4Height = 1123.0;
  static const double defaultPixelRatio = 2.0;

  /// Fast native image encoder: converts ui.Image to JPEG bytes.
  /// On Web, uses browser OffscreenCanvas/HTMLCanvasElement toBlob('image/jpeg', quality).
  /// Falls back to ui.ImageByteFormat.png if native web path is unavailable.
  static Future<Uint8List> encodeImageFast(ui.Image img,
      {double quality = 0.83}) async {
    if (kIsWeb) {
      try {
        final webBytes = await encodeWebCanvasJpeg(img, quality);
        if (webBytes != null) return webBytes;
      } catch (e) {
        debugPrint(
            '[FormImagePdfHelper] Native JPEG encode fallback due to: $e');
      }
    }

    // Fallback: standard CanvasKit / Skia PNG
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  /// Captures a single Flutter widget to JPEG bytes.
  static Future<Uint8List> captureWidget(
    BuildContext context,
    Widget widget, {
    double width = a4Width,
    double height = a4Height,
    double pixelRatio = defaultPixelRatio,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    final key = GlobalKey();
    final comp = Completer<Uint8List>();
    OverlayEntry? ent;

    ent = OverlayEntry(
      builder: (_) => Positioned(
        left: -(width + 120),
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

    try {
      await GoogleFonts.pendingFonts()
          .timeout(const Duration(milliseconds: 300));
    } catch (_) {}

    WidgetsBinding.instance.scheduleFrame();
    await Future.any([
      WidgetsBinding.instance.endOfFrame,
      Future.delayed(const Duration(milliseconds: 120)),
    ]);

    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    try {
      final rb =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (rb == null) {
        throw StateError(
            'Failed to locate RenderRepaintBoundary for offscreen page');
      }
      final img = await rb.toImage(pixelRatio: pixelRatio);
      final bytes = await encodeImageFast(img, quality: 0.83);
      img.dispose();
      comp.complete(bytes);
    } catch (e, st) {
      comp.completeError(e, st);
    } finally {
      ent.remove();
    }

    return comp.future;
  }

  /// Batch-captures a list of page widgets in a single overlay pass and compiles an A4 PDF.
  /// Yields between page encodes so the Flutter UI thread never freezes.
  static Future<Uint8List> buildPdfFromWidgets(
    BuildContext context,
    List<Widget> pages, {
    double width = a4Width,
    double? height = a4Height,
    double pixelRatio = defaultPixelRatio,
    void Function(int current, int total)? onProgress,
  }) async {
    if (pages.isEmpty) {
      final emptyDoc = pw.Document();
      return emptyDoc.save();
    }

    try {
      await GoogleFonts.pendingFonts()
          .timeout(const Duration(milliseconds: 300));
    } catch (_) {}

    if (!context.mounted) {
      final emptyDoc = pw.Document();
      return emptyDoc.save();
    }

    final keys = List.generate(pages.length, (_) => GlobalKey());
    final capturedPages = <({Uint8List bytes, Size size})>[];

    // Single-pass batch mount: all pages mount in ONE overlay entry at once
    final ent = OverlayEntry(
      builder: (_) => Positioned(
        left: -(width + 120),
        top: 0,
        width: width,
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < pages.length; i++)
                SizedBox(
                  width: width,
                  height: height,
                  child: RepaintBoundary(
                    key: keys[i],
                    child: height == null
                        ? IntrinsicHeight(child: pages[i])
                        : pages[i],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(ent);

    try {
      WidgetsBinding.instance.scheduleFrame();
      await Future.any([
        WidgetsBinding.instance.endOfFrame,
        Future.delayed(const Duration(milliseconds: 120)),
      ]);
      // Settle delay for all pages combined
      await Future.delayed(const Duration(milliseconds: 100));

      for (int i = 0; i < pages.length; i++) {
        // Yield execution to the event loop so the UI/progress spinner paints smoothly
        await Future.delayed(Duration.zero);
        onProgress?.call(i + 1, pages.length);

        final rb = keys[i].currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (rb == null) {
          throw StateError('RenderRepaintBoundary missing for page ${i + 1}');
        }

        final renderSize = rb.size;
        final img = await rb.toImage(pixelRatio: pixelRatio);
        final bytes = await encodeImageFast(img, quality: 0.83);
        img.dispose();
        capturedPages.add((bytes: bytes, size: renderSize));
      }
    } finally {
      ent.remove();
    }

    final pdfDoc = pw.Document();
    final double a4PtWidth = PdfPageFormat.a4.width;
    for (final page in capturedPages) {
      final PdfPageFormat format;
      if (height != null) {
        format = PdfPageFormat.a4;
      } else {
        final aspect = page.size.height /
            (page.size.width > 0 ? page.size.width : a4Width);
        format = PdfPageFormat(a4PtWidth, a4PtWidth * aspect);
      }
      pdfDoc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            pw.MemoryImage(page.bytes),
            fit: pw.BoxFit.fill,
            width: format.width,
            height: format.height,
          ),
        ),
      );
    }

    return pdfDoc.save();
  }

  /// High-level preview method with clean English visual spinner and automatic fallback.
  static Future<void> previewImageBasedPdf(
    BuildContext context, {
    required String fileName,
    required List<Widget> pages,
    double width = a4Width,
    double? height = a4Height,
    double pixelRatio = defaultPixelRatio,
    Future<Uint8List> Function()? fallbackPdfGenerator,
  }) async {
    final statusNotifier = ValueNotifier<String>(
      pages.length > 1
          ? 'Generating page 1 of ${pages.length}...'
          : 'Generating PDF...',
    );
    var dialogShown = false;

    // Show clean, minimal visual spinner in English
    if (context.mounted) {
      dialogShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black38,
        builder: (_) => PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ValueListenableBuilder<String>(
                      valueListenable: statusNotifier,
                      builder: (_, text, __) => Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    try {
      final bytes = await buildPdfFromWidgets(
        context,
        pages,
        width: width,
        height: height,
        pixelRatio: pixelRatio,
        onProgress: (curr, total) {
          statusNotifier.value = total > 1
              ? 'Generating page $curr of $total...'
              : 'Generating PDF...';
        },
      ).timeout(const Duration(seconds: 12));

      if (dialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShown = false;
      }

      if (!context.mounted) return;
      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
      }
    } catch (e) {
      debugPrint('Error in FormImagePdfHelper.previewImageBasedPdf: $e');
      if (fallbackPdfGenerator != null && context.mounted) {
        statusNotifier.value = 'Preparing PDF...';
        try {
          final fallbackBytes = await fallbackPdfGenerator();
          if (dialogShown && context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            dialogShown = false;
          }
          if (context.mounted) {
            if (kIsWeb) {
              await Printing.sharePdf(bytes: fallbackBytes, filename: fileName);
            } else {
              await Printing.layoutPdf(
                  onLayout: (_) async => fallbackBytes, name: fileName);
            }
          }
        } catch (_) {
          if (dialogShown && context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            dialogShown = false;
          }
        }
      } else {
        if (dialogShown && context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          dialogShown = false;
        }
        rethrow;
      }
    } finally {
      if (dialogShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
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
        color: Colors.black,
      );

  static TextStyle valUnderlineStyle([double sz = 10.5, double ht = 1.8]) =>
      GoogleFonts.notoSansDevanagari(
        fontSize: sz,
        fontWeight: FontWeight.w600,
        height: ht,
        color: Colors.black,
        decoration: TextDecoration.underline,
        decorationColor: Colors.black,
        decorationThickness: 0.8,
      );

  static TextSpan inlineFieldSpan(
    String val, {
    double emptyWidth = 100,
    double fontSize = 10.5,
    double height = 1.8,
    TextStyle? textStyle,
  }) {
    final content = val.trim();
    if (content.isNotEmpty) {
      final style = textStyle ?? valUnderlineStyle(fontSize, height);
      return TextSpan(text: content, style: style);
    } else {
      final charCount = (emptyWidth / (fontSize * 0.58)).round().clamp(3, 80);
      return TextSpan(
        text: '_' * charCount,
        style: mBld(fontSize, height).copyWith(color: Colors.black54),
      );
    }
  }

  /// Helper to wrap children in a standard A4 page container
  static Widget buildA4Page({
    required List<Widget> children,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
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
