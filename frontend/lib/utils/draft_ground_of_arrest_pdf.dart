// lib/utils/draft_ground_of_arrest_pdf.dart
//
// Dedicated high-resolution image-based PDF generation for Draft Ground of Arrest forms:
//   Page 9:  अटकेचा आधार (कलम ४७ BNSS) — Notice to Accused
//   Page 10: नातेवाईक/ मित्रांसाठी अटकेची नोटीस (कलम ४८ BNSS) — Notice to Relative
//   Page 11: अटकेचे कारणे [कलम ३५(१)(ब) BNSS] — Reasons of Arrest to Accused
//
// Each page is rendered at 794x1123 px with RepaintBoundary (pixelRatio: 3.0),
// using FittedBox(fit: BoxFit.scaleDown) as an overflow fallback around a SizedBox(width: 794),
// and assembled into exactly one pw.Page (A4, zero margin, BoxFit.fill) per page widget.
// Guarantees zero blank pages, full form-matching font sizing (13-14px body, 16-17px headings),
// and solid underlines under every wrapped line.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'pdf_font_cache.dart';

// ── A4 layout constants at 96 DPI ──────────────────────────────────────────
const double _kW = 794.0;
const double _kH = 1123.0;

/// Formats date string to DD/MM/YYYY if parseable, or returns cleaned text
String _formatDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  try {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
      final parsed = DateTime.parse(trimmed.substring(0, 10));
      return DateFormat('dd/MM/yyyy').format(parsed);
    }
    final parts = trimmed.split(RegExp(r'[-/.]'));
    if (parts.length == 3) {
      int? d, m, y;
      if (parts[0].length == 4) {
        y = int.tryParse(parts[0]);
        m = int.tryParse(parts[1]);
        d = int.tryParse(parts[2]);
      } else {
        d = int.tryParse(parts[0]);
        m = int.tryParse(parts[1]);
        y = int.tryParse(parts[2]);
        if (y != null && y < 100) y += 2000;
      }
      if (d != null &&
          m != null &&
          y != null &&
          d > 0 &&
          d <= 31 &&
          m > 0 &&
          m <= 12) {
        return '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
      }
    }
  } catch (_) {}
  return trimmed;
}

/// Formats time string to hh:mm AM/PM if parseable, or returns cleaned text
String _formatTime(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  try {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([aApP][mM])?')
        .firstMatch(trimmed);
    if (match != null) {
      int h = int.parse(match.group(1)!);
      final int m = int.parse(match.group(2)!);
      final ampm = match.group(3)?.toUpperCase();
      if (ampm != null) {
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
      }
      final period = h >= 12 ? 'PM' : 'AM';
      if (h == 0) {
        h = 12;
      } else if (h > 12) {
        h -= 12;
      }
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    }
  } catch (_) {}
  return trimmed;
}

/// Inserts zero-width spaces (\u200B) into continuous runs of non-whitespace characters
/// so that even unbroken strings of 100+ characters (e.g. yeeeeee... or gggggg...) can wrap
/// cleanly according to available line width.
///
/// Devanagari combining marks (matras U+093E..U+094F, halant/virama U+094D, anusvara U+0901..U+0903,
/// nukta U+093C) are preserved together with their base consonants and never split.
String _insertZeroWidthSpaces(String text, {int maxChunk = 8}) {
  if (text.isEmpty) return text;
  final buffer = StringBuffer();
  int runLength = 0;

  for (final char in text.runes) {
    final s = String.fromCharCode(char);
    if (s == ' ' || s == '\n' || s == '\t' || s == '\r') {
      runLength = 0;
      buffer.write(s);
      continue;
    }

    final isDevanagariMark = (char >= 0x0901 && char <= 0x0903) ||
        char == 0x093C ||
        (char >= 0x093E && char <= 0x094F) ||
        (char >= 0x0951 && char <= 0x0954) ||
        (char >= 0x0962 && char <= 0x0963);

    if (runLength >= maxChunk && !isDevanagariMark) {
      buffer.write('\u200B');
      runLength = 0;
    }

    buffer.write(s);
    if (!isDevanagariMark) {
      runLength++;
    }
  }

  return buffer.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Public Entrypoint: previewDraftGroundOfArrestPdf
// ─────────────────────────────────────────────────────────────────────────────

Future<void> previewDraftGroundOfArrestPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Draft_Ground_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';

  final s = (doc['formSection'] ?? '').toString().toLowerCase();
  final p9Match = s.contains('9') || s.contains('47') || s.contains('आधार');
  final p10Match =
      s.contains('10') || s.contains('48') || s.contains('नातेवाईक');
  final p11Match = s.contains('11') || s.contains('35') || s.contains('कारणे');
  final showAll = s.isEmpty ||
      s.contains('complete') ||
      (!p9Match && !p10Match && !p11Match);

  final showP9 = showAll || p9Match;
  final showP10 = showAll || p10Match;
  final showP11 = showAll || p11Match;

  final overlay = Overlay.of(context);

  // Ensure NotoSansDevanagari is loaded before offscreen render
  try {
    await GoogleFonts.pendingFonts().timeout(const Duration(milliseconds: 600));
  } catch (_) {}

  final keys = <GlobalKey>[];
  final boundaries = <Widget>[];

  if (showP9) {
    final k = GlobalKey();
    keys.add(k);
    boundaries.add(RepaintBoundary(key: k, child: _pg9(doc)));
  }
  if (showP10) {
    final k = GlobalKey();
    keys.add(k);
    boundaries.add(RepaintBoundary(key: k, child: _pg10(doc)));
  }
  if (showP11) {
    final k = GlobalKey();
    keys.add(k);
    boundaries.add(RepaintBoundary(key: k, child: _pg11(doc)));
  }

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -3500,
      top: 0,
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: boundaries,
        ),
      ),
    ),
  );

  overlay.insert(entry);

  final total = keys.length;
  final statusNotifier =
      ValueNotifier<String>('Generating page 1 of $total...');
  var dialogShown = false;
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: statusNotifier,
                builder: (_, msg, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      msg,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  try {
    WidgetsBinding.instance.scheduleFrame();
    await Future.any([
      WidgetsBinding.instance.endOfFrame,
      Future.delayed(const Duration(milliseconds: 180)),
    ]);
    await Future.delayed(const Duration(milliseconds: 140));

    final pdf = pw.Document();

    for (int i = 0; i < keys.length; i++) {
      statusNotifier.value = 'Generating page ${i + 1} of $total...';
      final k = keys[i];
      RenderRepaintBoundary? rb =
          k.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (rb == null || !rb.hasSize) {
        WidgetsBinding.instance.scheduleFrame();
        await Future.any([
          WidgetsBinding.instance.endOfFrame,
          Future.delayed(const Duration(milliseconds: 150)),
        ]);
        rb = k.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      }

      if (rb == null) {
        throw StateError(
            'Could not find RenderRepaintBoundary for Draft Ground of Arrest page ${i + 1}');
      }
      final img = await rb.toImage(pixelRatio: 3.0);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bd == null) {
        throw StateError('Failed to encode page ${i + 1} to PNG');
      }
      final bytes = bd.buffer.asUint8List();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            pw.MemoryImage(bytes),
            fit: pw.BoxFit.fill,
            width: PdfPageFormat.a4.width,
            height: PdfPageFormat.a4.height,
          ),
        ),
      );
    }

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: fileName);
    }
  } catch (e, st) {
    debugPrint('Error in previewDraftGroundOfArrestPdf: $e\n$st');
    final fallbackBytes = await generateDraftGroundOfArrestPdf(doc);
    if (kIsWeb) {
      await Printing.sharePdf(bytes: fallbackBytes, filename: fileName);
    } else {
      await Printing.layoutPdf(
          onLayout: (_) async => fallbackBytes, name: fileName);
    }
  } finally {
    if (dialogShown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    entry.remove();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helpers & Typography
// ─────────────────────────────────────────────────────────────────────────────

String _v(Map<String, dynamic> doc, String key, [String fallback = '']) {
  final val = doc[key]?.toString().trim() ?? '';
  return val.isEmpty ? fallback : val;
}

bool _b(Map<String, dynamic> doc, String key, [bool def = true]) {
  final val = doc[key];
  if (val is bool) return val;
  return def;
}

const List<String> _kDevanagariFallback = [
  'Noto Sans Devanagari',
  'Mangal',
  'Nirmala UI',
  'sans-serif',
];

TextStyle _mReg([double sz = 13.5, double ht = 1.45]) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      height: ht,
      color: Colors.black87,
    ).copyWith(fontFamilyFallback: _kDevanagariFallback);

TextStyle _mBld([double sz = 13.5, double ht = 1.45]) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      height: ht,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ).copyWith(fontFamilyFallback: _kDevanagariFallback);

TextStyle _valStyle([double sz = 13.5, double ht = 1.45]) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      height: ht,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ).copyWith(fontFamilyFallback: _kDevanagariFallback);

Widget _prosecutorBox(String pageLabel) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(width: 120),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          pageLabel,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 0.9),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Gaware Ashok',
              style: GoogleFonts.lora(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Public Prosecutor A.Nagar',
              style: GoogleFonts.lora(fontSize: 9.5, color: Colors.black87),
            ),
            Text(
              '9823911047',
              style: GoogleFonts.lora(fontSize: 9.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Underline / Field Helpers
// ─────────────────────────────────────────────────────────────────────────────

int _findFittingLength(String text, TextStyle style, double maxWidth) {
  if (text.isEmpty) return 0;
  int low = 1;
  int high = text.length;
  int best = 0;

  while (low <= high) {
    final mid = (low + high) ~/ 2;
    final sub = text.substring(0, mid);
    final tp = TextPainter(
      text: TextSpan(text: sub, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();

    if (tp.size.width <= maxWidth) {
      best = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }

  return best;
}

List<String> _breakTextIntoLines({
  required String text,
  required TextStyle style,
  required double firstLineWidth,
  required double fullLineWidth,
}) {
  final cleanText = text.trim();
  if (cleanText.isEmpty) return [];

  final prepared = _insertZeroWidthSpaces(cleanText, maxChunk: 8);

  final lines = <String>[];
  String remaining = prepared;

  final tp1 = TextPainter(
    text: TextSpan(text: remaining, style: style),
    textDirection: ui.TextDirection.ltr,
    maxLines: 1,
  )..layout();

  if (tp1.size.width <= firstLineWidth) {
    lines.add(remaining);
    return lines;
  }

  int cut1 = _findFittingLength(remaining, style, firstLineWidth);
  if (cut1 < remaining.length && cut1 > 0) {
    final lastSpace =
        remaining.substring(0, cut1).lastIndexOf(RegExp(r'[\s\u200B]'));
    if (lastSpace > (cut1 * 0.35).round()) {
      cut1 = lastSpace + 1;
    }
  }
  if (cut1 <= 0) cut1 = 1;

  lines.add(remaining.substring(0, cut1).trim());
  remaining = remaining.substring(cut1).trim();

  while (remaining.isNotEmpty) {
    final tpRem = TextPainter(
      text: TextSpan(text: remaining, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();

    if (tpRem.size.width <= fullLineWidth) {
      lines.add(remaining);
      break;
    }

    int cutRem = _findFittingLength(remaining, style, fullLineWidth);
    if (cutRem < remaining.length && cutRem > 0) {
      final lastSpace =
          remaining.substring(0, cutRem).lastIndexOf(RegExp(r'[\s\u200B]'));
      if (lastSpace > (cutRem * 0.35).round()) {
        cutRem = lastSpace + 1;
      }
    }
    if (cutRem <= 0) cutRem = 1;

    lines.add(remaining.substring(0, cutRem).trim());
    remaining = remaining.substring(cutRem).trim();
  }

  return lines;
}

Widget _singleUnderlineText(
  String text, {
  required TextStyle style,
  required double lineHeight,
  double? width,
}) {
  return Container(
    width: width ?? double.infinity,
    height: lineHeight,
    alignment: Alignment.bottomLeft,
    padding: const EdgeInsets.only(bottom: 2.0, left: 1.0, right: 1.0),
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.black87, width: 1.0),
      ),
    ),
    child: Text(
      text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
    ),
  );
}

Widget _buildLinedText(
  String text, {
  required TextStyle style,
  double lineHeight = 24.0,
  int minLines = 1,
  double indent = 0.0,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : (_kW - 80.0 - indent);

      final lines = _breakTextIntoLines(
        text: text,
        style: style,
        firstLineWidth: maxWidth,
        fullLineWidth: maxWidth,
      );

      final count = lines.length > minLines ? lines.length : minLines;

      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: 3.5),
              _singleUnderlineText(
                i < lines.length ? lines[i] : '',
                style: style,
                lineHeight: lineHeight,
              ),
            ],
          ],
        ),
      );
    },
  );
}

Widget _pdfUnderlineField(
  String text, {
  required TextStyle textStyle,
  double minWidth = 50.0,
  String? hintText,
  double lineHeight = 24.0,
}) {
  final cleanText = text.trim();
  return LayoutBuilder(
    builder: (context, constraints) {
      final isBounded =
          constraints.maxWidth.isFinite && constraints.maxWidth > 0;
      final maxAllowedWidth = isBounded ? constraints.maxWidth : (_kW - 80.0);

      final span = TextSpan(
        text: cleanText.isNotEmpty ? cleanText : (hintText ?? ' '),
        style: textStyle,
      );
      final tp = TextPainter(
        text: span,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      final neededWidth = tp.size.width + 12;

      if (neededWidth > maxAllowedWidth && maxAllowedWidth > 0) {
        final lines = _breakTextIntoLines(
          text: cleanText,
          style: textStyle,
          firstLineWidth: maxAllowedWidth,
          fullLineWidth: maxAllowedWidth,
        );
        if (lines.length > 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: 3.5),
                _singleUnderlineText(
                  lines[i],
                  style: textStyle,
                  lineHeight: lineHeight,
                  width: maxAllowedWidth,
                ),
              ],
            ],
          );
        }
      }

      final isInsideExpanded =
          isBounded && constraints.minWidth == constraints.maxWidth;
      final singleWidth = isInsideExpanded
          ? maxAllowedWidth
          : (isBounded
              ? (neededWidth > maxAllowedWidth
                  ? maxAllowedWidth
                  : (neededWidth > minWidth ? neededWidth : minWidth))
              : (neededWidth > minWidth ? neededWidth : minWidth));

      return _singleUnderlineText(
        cleanText.isNotEmpty ? cleanText : (hintText ?? ''),
        style: textStyle.copyWith(
          color: cleanText.isNotEmpty ? textStyle.color : Colors.grey.shade400,
        ),
        lineHeight: lineHeight,
        width: singleWidth,
      );
    },
  );
}

Widget _buildAddressWithAgeBlock({
  required String age,
  required String address,
  required TextStyle labelStyle,
  required TextStyle textStyle,
  String ageLabel = 'वय: ',
  String postAgeLabel = ' वर्ष, पत्ता: ',
  double lineHeight = 24.0,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final totalWidth =
          constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : (_kW - 80.0);

      final ageDisplay = age.isNotEmpty ? age : '      ';
      final prefixSpan = TextSpan(
        style: labelStyle,
        children: [
          TextSpan(text: ageLabel),
          TextSpan(text: ageDisplay, style: textStyle),
          TextSpan(text: postAgeLabel),
        ],
      );
      final prefixTp =
          TextPainter(text: prefixSpan, textDirection: ui.TextDirection.ltr)
            ..layout();
      final prefixWidth = prefixTp.size.width + 12.0;
      final firstLineWidth = (totalWidth - prefixWidth).clamp(60.0, totalWidth);
      final fullLineWidth = totalWidth;

      Widget buildPrefix() {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(ageLabel, style: labelStyle),
            _pdfUnderlineField(
              age,
              textStyle: textStyle,
              minWidth: 45,
              lineHeight: lineHeight,
            ),
            Text(postAgeLabel, style: labelStyle),
          ],
        );
      }

      final lines = _breakTextIntoLines(
        text: address,
        style: textStyle,
        firstLineWidth: firstLineWidth,
        fullLineWidth: fullLineWidth,
      );

      if (lines.isEmpty) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildPrefix(),
            Expanded(
              child: _singleUnderlineText(
                '',
                style: textStyle,
                lineHeight: lineHeight,
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              buildPrefix(),
              Expanded(
                child: _singleUnderlineText(
                  lines[0],
                  style: textStyle,
                  lineHeight: lineHeight,
                ),
              ),
            ],
          ),
          for (int i = 1; i < lines.length; i++) ...[
            const SizedBox(height: 3.5),
            _singleUnderlineText(
              lines[i],
              style: textStyle,
              lineHeight: lineHeight,
            ),
          ],
        ],
      );
    },
  );
}

@visibleForTesting
String insertZeroWidthSpacesDraft(String text, {int maxChunk = 8}) =>
    _insertZeroWidthSpaces(text, maxChunk: maxChunk);

@visibleForTesting
List<String> breakTextIntoLinesDraft({
  required String text,
  required TextStyle style,
  required double firstLineWidth,
  required double fullLineWidth,
}) =>
    _breakTextIntoLines(
      text: text,
      style: style,
      firstLineWidth: firstLineWidth,
      fullLineWidth: fullLineWidth,
    );

@visibleForTesting
Widget buildAddressWithAgeBlockForTest({
  required String age,
  required String address,
  required TextStyle labelStyle,
  required TextStyle textStyle,
  String ageLabel = 'वय: ',
  String postAgeLabel = ' वर्ष, पत्ता: ',
  double lineHeight = 24.0,
}) =>
    _buildAddressWithAgeBlock(
      age: age,
      address: address,
      labelStyle: labelStyle,
      textStyle: textStyle,
      ageLabel: ageLabel,
      postAgeLabel: postAgeLabel,
      lineHeight: lineHeight,
    );

Widget _buildPgWrapper(Widget child, [GlobalKey? contentKey]) {
  return Container(
    width: _kW,
    height: _kH,
    color: Colors.white,
    alignment: Alignment.topCenter,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        key: contentKey,
        width: _kW,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 34.0),
          child: child,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 9: अटकेचा आधार (कलम ४७ BNSS) — Notice to Accused
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg9(Map<String, dynamic> doc, [GlobalKey? contentKey]) {
  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedAddress = _v(doc, 'accusedAddress');
  final psName = _v(doc, 'psName');
  final crNo = _v(doc, 'crNo');
  final bnsSection = _v(doc, 'bnsSection');
  final arrestDate = _v(doc, 'arrestDate');
  final arrestTime = _v(doc, 'arrestTime');
  final briefFacts = _v(doc, 'briefFacts');

  final g1Fir = _b(doc, 'g1Fir', _b(doc, 's48G1', true));
  final g2Witness = _b(doc, 'g2Witness', _b(doc, 's48G2', true));
  final witnessName = _v(doc, 'witnessName', _v(doc, 's48WitnessName'));
  final g3Cctv = _b(doc, 'g3Cctv', _b(doc, 's48G3', true));
  final g4Recovery = _b(doc, 'g4Recovery', true);
  final g5Confession = _b(doc, 'g5Confession', _b(doc, 's48G5', true));
  final g6CoAccused = _b(doc, 'g6CoAccused', _b(doc, 's48G6', true));
  final coAccusedName = _v(doc, 'coAccusedName', _v(doc, 's48CoAccused'));
  final g7Cdr = _b(doc, 'g7Cdr', true);

  final relativeName = _v(doc, 'relativeName', _v(doc, 's48RelativeName'));
  final noticeDate = _v(doc, 'noticeDate', _v(doc, 's48Date'));
  final officerName = _v(doc, 'officerName', _v(doc, 's48OfficerSig'));

  final groundRows = <TableRow>[
    TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(child: Text('अ.क्र.', style: _mBld(13.0))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Center(
            child: Text('अटकेचे आधार ( Ground of Arrest )', style: _mBld(13.0)),
          ),
        ),
      ],
    ),
  ];

  void addGround(String num, Widget textWidget) {
    groundRows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(child: Text(num, style: _mBld(12.5))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: textWidget,
          ),
        ],
      ),
    );
  }

  if (g1Fir) {
    addGround(
      '१',
      Text(
        'फिर्यादीने दाखल केलेल्या FIR मध्ये तुमचे विरुद्ध आरोप केलेले आहेत.',
        style: _mReg(12.5),
      ),
    );
  }
  if (g2Witness) {
    addGround(
      '२',
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('प्रत्यक्षदर्शी साक्षीदार ', style: _mReg(12.5)),
          _pdfUnderlineField(
            witnessName,
            textStyle: _valStyle(12.5),
            minWidth: 120,
            hintText: '[नाव]',
          ),
          Text(
            ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
            style: _mReg(12.5),
          ),
        ],
      ),
    );
  }
  if (g3Cctv) {
    addGround(
      '३',
      Text(
        'घटनास्थळावरील पुराव्यांच्या (CCTV / डिजिटल रेकॉर्ड / मोबाईल व्हिडिओ ) आधारे गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
        style: _mReg(12.5),
      ),
    );
  }
  if (g4Recovery) {
    addGround(
      '४',
      Text(
        'गुन्ह्यात वापरलेले हत्यार / चोरीची मालमत्ता / गुन्ह्याशी संबंधित महत्त्वाचे दस्तऐवज हे केवळ तुमच्याकडे असलेल्या माहितीच्या आधारे आणि तुमच्या ताब्यातून हस्तगत करण्यात आले आहेत.',
        style: _mReg(12.5),
      ),
    );
  }
  if (g5Confession) {
    addGround(
      '५',
      Text('तुम्ही गुन्हा केल्याची कबुली दिली आहे.', style: _mReg(12.5)),
    );
  }
  if (g6CoAccused) {
    addGround(
      '६',
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('गुन्ह्यातील सहआरोपी ', style: _mReg(12.5)),
          _pdfUnderlineField(
            coAccusedName,
            textStyle: _valStyle(12.5),
            minWidth: 120,
            hintText: '___________',
          ),
          Text(
            ' यांनी तुम्ही गुन्ह्यामध्ये सहभागी असल्याचे कबुल केले आहे.',
            style: _mReg(12.5),
          ),
        ],
      ),
    );
  }
  if (g7Cdr) {
    addGround(
      '७',
      Text(
        'मोबाईल CDR वरून घटनेच्या दिवशी तुमचे tower location घटनास्थळाजवळ असल्याचे दिसून आले आहे.',
        style: _mReg(12.5),
      ),
    );
  }

  return _buildPgWrapper(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _prosecutorBox('Page 9 of 13'),
        const SizedBox(height: 10),

        // Title
        Center(
          child: Text(
            'अटकेचा आधार (कलम ४७ BNSS)',
            style: _mBld(16.5).copyWith(decoration: TextDecoration.underline),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Center(
          child: Text(
            '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४७ आणि भारतीय संविधान कलम २२(१) अन्वये तसेच माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विद्वान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
            style: _mReg(11.0, 1.35),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Recipient block
        Text('प्रति,', style: _mBld(13.5)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('अटक केलेल्या आरोपीचे नाव: ', style: _mBld(13.5)),
            Expanded(
              child: _pdfUnderlineField(
                accusedName,
                textStyle: _valStyle(13.5),
                minWidth: 180,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildAddressWithAgeBlock(
          age: accusedAge,
          address: accusedAddress,
          labelStyle: _mBld(13.5),
          textStyle: _valStyle(13.5),
        ),
        const SizedBox(height: 10),

        // Notice text
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text(
              'या नोटीसद्वारे तुम्हाला माहिती करण्यात येते की, तुम्हाला पोलीस ठाणे',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              psName,
              textStyle: _valStyle(13.5),
              minWidth: 140,
            ),
            Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक',
                style: _mReg(13.5, 1.5)),
            _pdfUnderlineField(
              crNo,
              textStyle: _valStyle(13.5),
              minWidth: 120,
            ),
            Text(
              ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              bnsSection,
              textStyle: _valStyle(13.5),
              minWidth: 110,
            ),
            Text(
              'अन्वये नोंदवलेल्या गुन्ह्यात आज दिनांक',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              _formatDate(arrestDate),
              textStyle: _valStyle(13.5),
              minWidth: 120,
            ),
            Text('रोजी वेळ', style: _mReg(13.5, 1.5)),
            _pdfUnderlineField(
              _formatTime(arrestTime),
              textStyle: _valStyle(13.5),
              minWidth: 100,
            ),
            Text('वाजता अटक करण्यात आली आहे.', style: _mReg(13.5, 1.5)),
          ],
        ),
        const SizedBox(height: 10),

        // Brief facts
        Text('गुन्ह्याची थोडक्यात हकीकत :-', style: _mBld(13.5)),
        const SizedBox(height: 4),
        _buildLinedText(
          briefFacts,
          style: briefFacts.isNotEmpty ? _valStyle(13.0) : _mReg(13.0),
          minLines: 1,
          lineHeight: 24.0,
        ),
        const SizedBox(height: 10),

        // Table 1: Grounds
        Text('अटकेचा आधार :-', style: _mBld(13.5)),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(1),
          },
          children: groundRows,
        ),
        const SizedBox(height: 10),

        // Table 2: Rights of Accused
        Text('आरोपीचे हक्क /अधिकार :-', style: _mBld(13.5)),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: Text('अ.क्र.', style: _mBld(13.0))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Center(
                    child: Text('आरोपींचे हक्क', style: _mBld(13.0)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: Text('१', style: _mBld(12.5))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    'तुम्हाला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                    style: _mReg(12.5),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: Text('२', style: _mBld(12.5))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                    style: _mReg(12.5),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: Text('३', style: _mBld(12.5))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'तुमच्या अटकेची आणि तुम्हाला ज्या ठिकाणी कोठडीत ठेवण्यात आले आहे त्या ठिकाणाची माहिती तुमच्याद्वारे नामांकित केलेले नातेवाईक/मित्र ',
                        style: _mReg(12.5),
                      ),
                      _pdfUnderlineField(
                        relativeName,
                        textStyle: _valStyle(12.5),
                        minWidth: 150,
                        hintText: '____________________________',
                      ),
                      Text(' यांना देण्यात आली आहे.', style: _mReg(12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Page 9 Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('दिनांक :- ', style: _mBld(13.0)),
                _pdfUnderlineField(
                  _formatDate(noticeDate),
                  textStyle: _valStyle(13.0),
                  minWidth: 120,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _pdfUnderlineField(
                  officerName,
                  textStyle: _valStyle(13.0),
                  minWidth: 180,
                  hintText: 'अधिकारी नाव, हुद्दा',
                ),
                const SizedBox(height: 3),
                Text('पोलीस अधिकारी नाव, हुद्दा सही शिक्का',
                    style: _mReg(11.5)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    accusedName.isNotEmpty ? accusedName : '',
                    style: _mBld(13.0),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 3),
                Text('आरोपीचे नाव , सही, अंगठा', style: _mReg(11.5)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
    contentKey,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 10: नातेवाईक/ मित्रांसाठी अटकेची नोटीस (कलम ४८ BNSS)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg10(Map<String, dynamic> doc, [GlobalKey? contentKey]) {
  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedAddress = _v(doc, 'accusedAddress');
  final psName = _v(doc, 'psName');
  final crNo = _v(doc, 'crNo');
  final bnsSection = _v(doc, 'bnsSection');
  final arrestDate = _v(doc, 'arrestDate');
  final arrestTime = _v(doc, 'arrestTime');
  final briefFacts = _v(doc, 'briefFacts');

  final relativeName = _v(doc, 'relativeName', _v(doc, 's48RelativeName'));
  final relativeAge = _v(doc, 'relativeAge', _v(doc, 's48RelativeAge'));
  final relativeAddress =
      _v(doc, 'relativeAddress', _v(doc, 's48RelativeAddress'));
  final relationship = _v(doc, 'relationship', _v(doc, 's48Relationship'));
  final custodyPs = _v(doc, 'custodyPs', _v(doc, 's48CustodyPs', psName));

  final g1Fir = _b(doc, 'g1Fir', _b(doc, 's48G1', true));
  final g2Witness = _b(doc, 'g2Witness', _b(doc, 's48G2', true));
  final witnessName = _v(doc, 'witnessName', _v(doc, 's48WitnessName'));
  final g3Cctv = _b(doc, 'g3Cctv', _b(doc, 's48G3', true));
  final g5Confession = _b(doc, 'g5Confession', _b(doc, 's48G5', true));
  final g6CoAccused = _b(doc, 'g6CoAccused', _b(doc, 's48G6', true));
  final coAccusedName = _v(doc, 'coAccusedName', _v(doc, 's48CoAccused'));

  final noticeDate = _v(doc, 'noticeDate', _v(doc, 's48Date'));
  final noticePlace = _v(doc, 'noticePlace', _v(doc, 's48Place'));
  final officerName = _v(doc, 'officerName', _v(doc, 's48OfficerSig'));
  final relativeSig = _v(doc, 'relativeSig', _v(doc, 's48RelativeSig'));

  final groundRows = <TableRow>[
    TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(child: Text('अ.क्र.', style: _mBld(13.0))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Center(
            child: Text('अटकेचे आधार (Ground of Arrest )', style: _mBld(13.0)),
          ),
        ),
      ],
    ),
  ];

  void addGround(String num, Widget textWidget) {
    groundRows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(child: Text(num, style: _mBld(12.5))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: textWidget,
          ),
        ],
      ),
    );
  }

  if (g1Fir) {
    addGround(
      '१',
      Text(
        'FIR मध्ये आरोपीने सदर गुन्हा केल्याचा उल्लेख आहे.',
        style: _mReg(12.5),
      ),
    );
  }
  if (g2Witness) {
    addGround(
      '२',
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('प्रत्यक्षदर्शी साक्षीदार ', style: _mReg(12.5)),
          _pdfUnderlineField(
            witnessName,
            textStyle: _valStyle(12.5),
            minWidth: 120,
            hintText: '[नाव]',
          ),
          Text(
            ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये आरोपीचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
            style: _mReg(12.5),
          ),
        ],
      ),
    );
  }
  if (g3Cctv) {
    addGround(
      '३',
      Text(
        'घटनास्थळावरील पुराव्यांच्या CCTV/डिजिटल रेकॉर्ड आधारे गुन्ह्यामध्ये थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
        style: _mReg(12.5),
      ),
    );
  }
  if (g5Confession) {
    addGround(
      '५',
      Text('आरोपीने गुन्हा केल्याची कबुली दिली आहे.', style: _mReg(12.5)),
    );
  }
  if (g6CoAccused) {
    addGround(
      '६',
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('गुन्ह्यातील सहआरोपी ', style: _mReg(12.5)),
          _pdfUnderlineField(
            coAccusedName,
            textStyle: _valStyle(12.5),
            minWidth: 120,
            hintText: '___________',
          ),
          Text(
            ' यांनी गुन्ह्यामध्ये आरोपी सहभागी असल्याचे कबुल केले आहे.',
            style: _mReg(12.5),
          ),
        ],
      ),
    );
  }

  return _buildPgWrapper(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _prosecutorBox('Page 10 of 13'),
        const SizedBox(height: 10),

        // Title
        Center(
          child: Text(
            'नातेवाईक/ मित्रांसाठी अटकेच्या माहितीची नोटीस ( कलम ४८ BNSS)',
            style: _mBld(16.0).copyWith(decoration: TextDecoration.underline),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Center(
          child: Text(
            '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४८(१) अन्वये माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विद्वान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
            style: _mReg(11.0, 1.35),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Recipient block
        Text('प्रति,', style: _mBld(13.5)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('नातेवाईक/मित्राचे नाव:- ', style: _mBld(13.5)),
            Expanded(
              child: _pdfUnderlineField(
                relativeName,
                textStyle: _valStyle(13.5),
                minWidth: 180,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildAddressWithAgeBlock(
          age: relativeAge,
          address: relativeAddress,
          labelStyle: _mBld(13.5),
          textStyle: _valStyle(13.5),
          ageLabel: 'वय :- ',
          postAgeLabel: ' वर्ष, पत्ता:- ',
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('आरोपीशी असलेले नाते: ', style: _mBld(13.5)),
            Expanded(
              child: _pdfUnderlineField(
                relationship,
                textStyle: _valStyle(13.5),
                minWidth: 180,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Notice text
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text(
              'या नोटीसद्वारे तुम्हाला, भारतीय नागरिक सुरक्षा संहिता, २०२३ (BNSS) च्या कलम ४८(१) मधील कायदेशीर तरतुदींनुसार अधिकृतपणे सूचित करण्यात येते की, तुमचे/तुमच्या आरोपीचे नाव: ',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              accusedName,
              textStyle: _valStyle(13.5),
              minWidth: 160,
            ),
            Text('वय: ', style: _mReg(13.5, 1.5)),
            _pdfUnderlineField(
              accusedAge,
              textStyle: _valStyle(13.5),
              minWidth: 50,
            ),
            Text('वर्ष, पत्ता:- ', style: _mReg(13.5, 1.5)),
            _pdfUnderlineField(
              accusedAddress,
              textStyle: _valStyle(13.5),
              minWidth: 160,
            ),
            Text('यांना पोलीस ठाणे ', style: _mReg(13.5, 1.5)),
            _pdfUnderlineField(
              psName,
              textStyle: _valStyle(13.5),
              minWidth: 140,
            ),
            Text(
              'येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक (Cr.No.) ',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              crNo,
              textStyle: _valStyle(13.5),
              minWidth: 120,
            ),
            Text(
              ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              bnsSection,
              textStyle: _valStyle(13.5),
              minWidth: 110,
            ),
            Text(
              'अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने आज दिनांक ',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              _formatDate(arrestDate),
              textStyle: _valStyle(13.5),
              minWidth: 120,
            ),
            Text('रोजी वेळ ', style: _mReg(13.5, 1.5)),
            _pdfUnderlineField(
              _formatTime(arrestTime),
              textStyle: _valStyle(13.5),
              minWidth: 100,
            ),
            Text('वाजता कायदेशीररीत्या अटक करण्यात आली आहे.',
                style: _mReg(13.5, 1.5)),
          ],
        ),
        const SizedBox(height: 10),

        // Brief facts
        Text('गुन्ह्याची थोडक्यात हकीकत :-', style: _mBld(13.5)),
        const SizedBox(height: 4),
        _buildLinedText(
          briefFacts,
          style: briefFacts.isNotEmpty ? _valStyle(13.0) : _mReg(13.0),
          minLines: 1,
          lineHeight: 24.0,
        ),
        const SizedBox(height: 10),

        // Table 1: Information
        Text(
          'आरोपीच्या अटकेबाबत तुम्हाला खालील बाबींची लेखी माहिती देण्यात येत आहे:-',
          style: _mBld(13.5),
        ),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: Text('अ.क्र.', style: _mBld(13.0))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Center(
                    child: Text('अटकेबाबत माहिती', style: _mBld(13.0)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: Text('१.', style: _mBld(12.5))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('आरोपी नाव ', style: _mReg(12.5)),
                      Text(
                        accusedName.isNotEmpty
                            ? accusedName
                            : '___________________',
                        style: _mBld(12.5),
                      ),
                      Text(' यांना गुन्हा रजिस्टर क्रमांक ',
                          style: _mReg(12.5)),
                      Text(
                        crNo.isNotEmpty ? crNo : '_______________',
                        style: _mBld(12.5),
                      ),
                      Text(
                        ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
                        style: _mReg(12.5),
                      ),
                      Text(
                        bnsSection.isNotEmpty
                            ? bnsSection
                            : '__________________',
                        style: _mBld(12.5),
                      ),
                      Text(
                        ' अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने कायदेशीररीत्या अटक करण्यात आली असून सदर आरोपीला सध्या [पोलीस ठाण्याचे नाव: ',
                        style: _mReg(12.5),
                      ),
                      _pdfUnderlineField(
                        custodyPs.isNotEmpty
                            ? custodyPs
                            : (psName.isNotEmpty ? psName : ''),
                        textStyle: _valStyle(12.5),
                        minWidth: 140,
                        hintText: 'पोलीस ठाणे',
                      ),
                      Text('] येथे ठेवण्यात आले आहे.', style: _mReg(12.5)),
                    ],
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: Text('२.', style: _mBld(12.5))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    'आरोपीला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                    style: _mReg(12.5),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(child: Text('३.', style: _mBld(12.5))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                    style: _mReg(12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Table 2: Grounds
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(1),
          },
          children: groundRows,
        ),
        const SizedBox(height: 18),

        // Page 10 Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('दिनांक :- ', style: _mBld(13.0)),
                    _pdfUnderlineField(
                      _formatDate(noticeDate),
                      textStyle: _valStyle(13.0),
                      minWidth: 120,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ठिकाण :- ', style: _mBld(13.0)),
                    _pdfUnderlineField(
                      noticePlace,
                      textStyle: _valStyle(13.0),
                      minWidth: 90,
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _pdfUnderlineField(
                  officerName,
                  textStyle: _valStyle(13.0),
                  minWidth: 180,
                  hintText: 'अधिकारी नाव, हुद्दा',
                ),
                const SizedBox(height: 3),
                Text('पोलीस अधिकारी नाव सही शिक्का', style: _mReg(11.5)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _pdfUnderlineField(
                  relativeSig,
                  textStyle: _valStyle(13.0),
                  minWidth: 180,
                  hintText: 'नातेवाईक/मित्र नाव',
                ),
                const SizedBox(height: 3),
                Text('नातेवाईक/ मित्र यांचे नाव , सही, अंगठा',
                    style: _mReg(11.5)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
    contentKey,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 11: अटकेचे कारणे [कलम ३५(१)(ब) BNSS ] — Reasons of Arrest to Accused
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg11(Map<String, dynamic> doc, [GlobalKey? contentKey]) {
  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedAddress = _v(doc, 'accusedAddress');
  final psName = _v(doc, 'psName');
  final crNo = _v(doc, 'crNo');
  final bnsSection = _v(doc, 'bnsSection');
  final arrestDate = _v(doc, 'arrestDate');
  final arrestTime = _v(doc, 'arrestTime');
  final briefFacts = _v(doc, 'briefFacts');

  final roaR1 = _b(doc, 'roaR1', true);
  final roaR2 = _b(doc, 'roaR2', true);
  final roaR3 = _b(doc, 'roaR3', true);
  final roaR4 = _b(doc, 'roaR4', true);
  final roaR5 = _b(doc, 'roaR5', true);

  final noticeDate = _v(doc, 'noticeDate', _v(doc, 'roaDate'));
  final noticePlace = _v(doc, 'noticePlace', _v(doc, 'roaPlace'));
  final officerName = _v(doc, 'officerName', _v(doc, 'roaOfficerSig'));

  final roaRows = <TableRow>[
    TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(child: Text('अ.क्र.', style: _mBld(13.0))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Center(
            child: Text('अटकेचे कारण (Reason for Arrest)', style: _mBld(13.0)),
          ),
        ),
      ],
    ),
  ];

  void addReason(String num, String text) {
    roaRows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(child: Text(num, style: _mBld(12.5))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(text, style: _mReg(12.5)),
          ),
        ],
      ),
    );
  }

  if (roaR1) {
    addReason(
      '१',
      'कलम ३५(१)(ब)(i) — आरोपीने आणखी कोणताही गुन्हा करू नये यासाठी त्याची अटक आवश्यक आहे.',
    );
  }
  if (roaR2) {
    addReason(
      '२',
      'कलम ३५(१)(ब)(ii) — गुन्ह्याच्या योग्य तपासासाठी आरोपीची अटक आवश्यक आहे.',
    );
  }
  if (roaR3) {
    addReason(
      '३',
      'कलम ३५(१)(ब)(iii) — आरोपीने गुन्ह्यातील पुरावे नष्ट करू नये किंवा अशा पुराव्यांमध्ये छेडछाड करू नये यासाठी अटक आवश्यक आहे.',
    );
  }
  if (roaR4) {
    addReason(
      '४',
      'कलम ३५(१)(ब)(iv) — गुन्ह्याशी संबंधित कोणत्याही साक्षीदाराला आरोपीने धमकी, प्रलोभन किंवा दबाव आणू नये यासाठी अटक आवश्यक आहे.',
    );
  }
  if (roaR5) {
    addReason(
      '५',
      'कलम ३५(१)(ब)(v) — आरोपीला न्यायालयात हजर करणे सुनिश्चित करण्यासाठी आणि तो फरारी होऊ नये यासाठी त्याची अटक आवश्यक आहे.',
    );
  }

  return _buildPgWrapper(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _prosecutorBox('Page 11 of 13'),
        const SizedBox(height: 10),

        // Title
        Center(
          child: Text(
            'अटकेचे कारणे [कलम ३५(१)(ब) BNSS ]',
            style: _mBld(16.5).copyWith(decoration: TextDecoration.underline),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Center(
          child: Text(
            '(भारतीय नागरिक सुरक्षा संहिता,२०२३ कलम ३५(१)(ब) अन्वये मा.सर्वोच्च न्यायालयाच्या मार्गदर्शक तत्त्वांच्या निकषांच्या अधीन)',
            style: _mReg(11.0, 1.35),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Recipient block
        Text('प्रति,', style: _mBld(13.5)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('अटक केलेल्या आरोपीचे नाव:- ', style: _mBld(13.5)),
            Expanded(
              child: _pdfUnderlineField(
                accusedName,
                textStyle: _valStyle(13.5),
                minWidth: 180,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildAddressWithAgeBlock(
          age: accusedAge,
          address: accusedAddress,
          labelStyle: _mBld(13.5),
          textStyle: _valStyle(13.5),
          ageLabel: 'वय:- ',
          postAgeLabel: ' वर्ष, पत्ता:- ',
        ),
        const SizedBox(height: 10),

        // Notice text
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text(
              'या नोटीसद्वारे तुम्हाला सूचित करण्यात येते की, पोलीस ठाणे',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              psName,
              textStyle: _valStyle(13.5),
              minWidth: 140,
              hintText: '[पोलीस ठाण्याचे नाव]',
            ),
            Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक',
                style: _mReg(13.5, 1.5)),
            _pdfUnderlineField(
              crNo,
              textStyle: _valStyle(13.5),
              minWidth: 120,
            ),
            Text(
              ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              bnsSection,
              textStyle: _valStyle(13.5),
              minWidth: 110,
            ),
            Text(
              'अन्वये नोंदवलेल्या गुन्ह्यात तपासाच्या अनुषंगाने आज दिनांक',
              style: _mReg(13.5, 1.5),
            ),
            _pdfUnderlineField(
              _formatDate(arrestDate),
              textStyle: _valStyle(13.5),
              minWidth: 120,
            ),
            Text('रोजी वेळ', style: _mReg(13.5, 1.5)),
            _pdfUnderlineField(
              _formatTime(arrestTime),
              textStyle: _valStyle(13.5),
              minWidth: 100,
            ),
            Text('वाजता अटक करण्यात आली आहे.', style: _mReg(13.5, 1.5)),
          ],
        ),
        const SizedBox(height: 10),

        // Brief facts
        Text('गुन्ह्याची थोडक्यात हकीकत :-', style: _mBld(13.5)),
        const SizedBox(height: 4),
        _buildLinedText(
          briefFacts,
          style: briefFacts.isNotEmpty ? _valStyle(13.0) : _mReg(13.0),
          minLines: 1,
          lineHeight: 24.0,
        ),
        const SizedBox(height: 10),

        // Table: Reasons
        Text('अटकेची कारणे [कलम ३५(१)(ब) BNSS]:-', style: _mBld(13.5)),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(1),
          },
          children: roaRows,
        ),
        const SizedBox(height: 18),

        // Page 11 Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('दिनांक :- ', style: _mBld(13.0)),
                    _pdfUnderlineField(
                      _formatDate(noticeDate),
                      textStyle: _valStyle(13.0),
                      minWidth: 120,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ठिकाण :- ', style: _mBld(13.0)),
                    _pdfUnderlineField(
                      noticePlace,
                      textStyle: _valStyle(13.0),
                      minWidth: 90,
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _pdfUnderlineField(
                  officerName,
                  textStyle: _valStyle(13.0),
                  minWidth: 180,
                  hintText: 'अधिकारी नाव, हुद्दा',
                ),
                const SizedBox(height: 3),
                Text('पोलीस अधिकारी नाव सही शिक्का', style: _mReg(11.5)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    accusedName.isNotEmpty ? accusedName : '',
                    style: _mBld(13.0),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 3),
                Text('आरोपीचे नाव , सही, अंगठा', style: _mReg(11.5)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
    contentKey,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Backward Compatibility Fallback
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> generateDraftGroundOfArrestPdf(
  Map<String, dynamic> doc,
) async {
  final pdf = pw.Document();
  pw.Font devanagari;
  try {
    devanagari = await PdfFontCache.devanagariBold();
  } catch (_) {
    devanagari = pw.Font.helveticaBold();
  }

  final s = (doc['formSection'] ?? '').toString().toLowerCase();
  final p9Match = s.contains('9') || s.contains('47') || s.contains('आधार');
  final p10Match =
      s.contains('10') || s.contains('48') || s.contains('नातेवाईक');
  final p11Match = s.contains('11') || s.contains('35') || s.contains('कारणे');
  final showAll = s.isEmpty ||
      s.contains('complete') ||
      (!p9Match && !p10Match && !p11Match);

  final showP9 = showAll || p9Match;
  final showP10 = showAll || p10Match;
  final showP11 = showAll || p11Match;

  final titleStyle = pw.TextStyle(
      font: devanagari, fontSize: 14, fontWeight: pw.FontWeight.bold);
  final bodyStyle = pw.TextStyle(font: devanagari, fontSize: 10);

  if (showP9) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
                child: pw.Text('अटकेचा आधार (कलम ४७ BNSS)', style: titleStyle)),
            pw.SizedBox(height: 12),
            pw.Text('आरोपी नाव: ${doc['accusedName'] ?? ''}', style: bodyStyle),
            pw.Text(
                'वय: ${doc['accusedAge'] ?? ''} वर्ष, पत्ता: ${doc['accusedAddress'] ?? ''}',
                style: bodyStyle),
            pw.Text('पोलीस ठाणे: ${doc['psName'] ?? ''}', style: bodyStyle),
            pw.Text(
                'गुन्हा रजि.क्र.: ${doc['crNo'] ?? ''}, कलम: ${doc['bnsSection'] ?? ''}',
                style: bodyStyle),
            pw.Text(
                'अटक दिनांक: ${_formatDate(doc['arrestDate']?.toString() ?? '')} वेळ: ${_formatTime(doc['arrestTime']?.toString() ?? '')}',
                style: bodyStyle),
          ],
        ),
      ),
    );
  }

  if (showP10) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
                child: pw.Text(
                    'नातेवाईक/ मित्रांसाठी अटकेची नोटीस (कलम ४८ BNSS)',
                    style: titleStyle)),
            pw.SizedBox(height: 12),
            pw.Text('नातेवाईकाचे नाव: ${doc['relativeName'] ?? ''}',
                style: bodyStyle),
            pw.Text(
                'वय: ${doc['relativeAge'] ?? ''} वर्ष, पत्ता: ${doc['relativeAddress'] ?? ''}',
                style: bodyStyle),
            pw.Text('आरोपी नाव: ${doc['accusedName'] ?? ''}', style: bodyStyle),
            pw.Text('पोलीस ठाणे: ${doc['psName'] ?? ''}', style: bodyStyle),
          ],
        ),
      ),
    );
  }

  if (showP11) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
                child: pw.Text('अटकेचे कारणे [कलम ३५(१)(ब) BNSS ]',
                    style: titleStyle)),
            pw.SizedBox(height: 12),
            pw.Text('आरोपी नाव: ${doc['accusedName'] ?? ''}', style: bodyStyle),
            pw.Text(
                'वय: ${doc['accusedAge'] ?? ''} वर्ष, पत्ता: ${doc['accusedAddress'] ?? ''}',
                style: bodyStyle),
            pw.Text('पोलीस ठाणे: ${doc['psName'] ?? ''}', style: bodyStyle),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}
