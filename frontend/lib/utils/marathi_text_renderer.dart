import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

/// Holds the result of rendering text as a PNG image.
class RenderedText {
  final Uint8List bytes;
  final double width;
  final double height;

  RenderedText({
    required this.bytes,
    required this.width,
    required this.height,
  });

  bool get isEmpty => bytes.isEmpty;
  bool get isNotEmpty => bytes.isNotEmpty;
}

/// Fallback font list to guarantee Latin letters, numbers, and symbols render
/// even when the primary TextStyle specifies a Devanagari-only font on Flutter Web.
const List<String> kMarathiFallbackFonts = [
  'Roboto',
  'Noto Sans',
  'Arial',
  'sans-serif',
];

TextStyle _withFallback(TextStyle style) {
  return style.copyWith(
    fontFamilyFallback: [
      ...?style.fontFamilyFallback,
      ...kMarathiFallbackFonts,
    ],
  );
}

InlineSpan _ensureSpanFontFallback(InlineSpan span) {
  if (span is TextSpan) {
    return TextSpan(
      text: span.text,
      children: span.children?.map(_ensureSpanFontFallback).toList(),
      style: _withFallback(span.style ?? const TextStyle()),
      recognizer: span.recognizer,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
  return span;
}

/// Renders a text string to a high-resolution PNG image using Flutter's
/// Skia/HarfBuzz engine. This ensures correct Devanagari rendering
/// with proper matras, conjuncts, and half-letters that the `pdf`
/// package cannot do natively.
Future<RenderedText> renderTextToImage(
  String text, {
  required TextStyle style,
  double maxWidth = 500,
  double pixelRatio = 2.0,
  TextAlign textAlign = TextAlign.left,
}) async {
  if (text.trim().isEmpty) {
    return RenderedText(bytes: Uint8List(0), width: 0, height: 0);
  }

  // Yield to the event loop so the UI (like loading spinners) can paint
  // during intensive pre-rendering of hundreds of text blocks.
  await Future.delayed(Duration.zero);

  final effectiveStyle = _withFallback(style);

  final textPainter = TextPainter(
    text: TextSpan(text: text, style: effectiveStyle),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
  );
  textPainter.layout(maxWidth: maxWidth);

  // For center/right alignment, use maxWidth so text is properly positioned
  final w = (textAlign != TextAlign.left && maxWidth.isFinite)
      ? maxWidth
      : textPainter.width;
  final h = textPainter.height;

  if (w <= 0 || h <= 0) {
    return RenderedText(bytes: Uint8List(0), width: 0, height: 0);
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(pixelRatio);
  textPainter.paint(canvas, Offset.zero);

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (w * pixelRatio).ceil(),
    (h * pixelRatio).ceil(),
  );

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return RenderedText(
    bytes: byteData!.buffer.asUint8List(),
    width: w,
    height: h,
  );
}

/// Renders an InlineSpan (e.g. TextSpan with rich children) to a high-resolution PNG image.
Future<RenderedText> renderSpanToImage(
  InlineSpan span, {
  double maxWidth = 500,
  double pixelRatio = 2.0,
  TextAlign textAlign = TextAlign.left,
}) async {
  await Future.delayed(Duration.zero);

  final effectiveSpan = _ensureSpanFontFallback(span);

  final textPainter = TextPainter(
    text: effectiveSpan,
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
  );
  textPainter.layout(maxWidth: maxWidth);

  final w = (textAlign != TextAlign.left && maxWidth.isFinite)
      ? maxWidth
      : textPainter.width;
  final h = textPainter.height;

  if (w <= 0 || h <= 0) {
    return RenderedText(bytes: Uint8List(0), width: 0, height: 0);
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(pixelRatio);
  textPainter.paint(canvas, Offset.zero);

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (w * pixelRatio).ceil(),
    (h * pixelRatio).ceil(),
  );

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return RenderedText(
    bytes: byteData!.buffer.asUint8List(),
    width: w,
    height: h,
  );
}

/// Cache for pre-rendered Marathi text images used in PDF generation.
class MarathiImageCache {
  final Map<String, RenderedText> _cache = {};
  final double pixelRatio;

  MarathiImageCache({this.pixelRatio = 2.0});

  /// Pre-render text and store with the given key.
  Future<void> add(
    String key,
    String text,
    TextStyle style, {
    double maxWidth = 500,
    TextAlign textAlign = TextAlign.left,
  }) async {
    if (text.trim().isEmpty) return;
    _cache[key] = await renderTextToImage(
      text,
      style: style,
      maxWidth: maxWidth,
      pixelRatio: pixelRatio,
      textAlign: textAlign,
    );
  }

  /// Pre-render an InlineSpan (TextSpan with rich children) and store with the given key.
  Future<void> addSpan(
    String key,
    InlineSpan span, {
    double maxWidth = 500,
    TextAlign textAlign = TextAlign.left,
  }) async {
    _cache[key] = await renderSpanToImage(
      span,
      maxWidth: maxWidth,
      pixelRatio: pixelRatio,
      textAlign: textAlign,
    );
  }

  /// Get a `pw.Image` widget for a pre-rendered text with proportional scaling.
  pw.Widget img(
    String key, {
    double? width,
    double? height,
    double? maxWidth,
    pw.BoxFit fit = pw.BoxFit.contain,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    final data = _cache[key];
    if (data == null || data.isEmpty) return pw.SizedBox(width: 0, height: 0);

    double targetW = data.width;
    double targetH = data.height;

    if (height != null && width == null) {
      targetH = height;
      targetW =
          data.height > 0 ? (data.width * (targetH / data.height)) : data.width;
    } else if (width != null && height == null) {
      targetW = width;
      targetH =
          data.width > 0 ? (data.height * (targetW / data.width)) : data.height;
    } else if (width != null && height != null) {
      targetW = width;
      targetH = height;
    }

    if (maxWidth != null && maxWidth > 0 && targetW > maxWidth) {
      final shrink = maxWidth / targetW;
      targetW = maxWidth;
      targetH = targetH * shrink;
    }

    return pw.Image(
      pw.MemoryImage(data.bytes),
      width: targetW,
      height: targetH,
      fit: fit,
      alignment: alignment,
    );
  }

  /// Check if a key exists and has image data.
  bool has(String key) =>
      _cache.containsKey(key) && (_cache[key]?.isNotEmpty ?? false);

  /// Get raw rendered text data.
  RenderedText? get(String key) => _cache[key];
}

/// Check if a string contains Devanagari characters (U+0900–U+097F).
bool containsDevanagari(String text) {
  return text.runes.any((r) => r >= 0x0900 && r <= 0x097F);
}
