import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'pdf_font_cache.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Font Caching & Preloading
// ──────────────────────────────────────────────────────────────────────────────

pw.Font? _cachedDevanagariRegular;
pw.Font? _cachedDevanagariBold;

Future<void> preloadOrderSection4748PdfFonts() async {
  try {
    _cachedDevanagariRegular ??= await PdfFontCache.devanagariRegular();
    _cachedDevanagariBold ??= await PdfFontCache.devanagariBold();
  } catch (_) {}
}

// ──────────────────────────────────────────────────────────────────────────────
// Public API: Direct Offscreen A4 PDF Export (No Slicing, Exact Form Match)
// ──────────────────────────────────────────────────────────────────────────────

Future<void> previewOrderSection4748Pdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Order_Section_47_48_${DateTime.now().millisecondsSinceEpoch}.pdf';

  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final section = fld(['formSection']).toLowerCase();
  final isP1Explicit = section.contains('47') ||
      section.contains('main') ||
      section.contains('1');
  final isP2Explicit = section.contains('48') || section.contains('2');
  final showP1 = section.isEmpty ||
      section.contains('complete') ||
      isP1Explicit ||
      !isP2Explicit;
  final showP2 = section.isEmpty ||
      section.contains('complete') ||
      isP2Explicit ||
      !isP1Explicit;

  final overlay = Overlay.of(context);

  try {
    await GoogleFonts.pendingFonts().timeout(const Duration(milliseconds: 600));
  } catch (_) {}

  final keys = <GlobalKey>[];
  final boundaries = <Widget>[];

  if (showP1) {
    final k = GlobalKey();
    keys.add(k);
    boundaries.add(RepaintBoundary(key: k, child: _buildPg1Widget(doc)));
  }
  if (showP2) {
    final k = GlobalKey();
    keys.add(k);
    boundaries.add(RepaintBoundary(key: k, child: _buildPg2Widget(doc)));
  }

  if (boundaries.isEmpty) {
    final k = GlobalKey();
    keys.add(k);
    boundaries.add(RepaintBoundary(key: k, child: _buildPg1Widget(doc)));
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
            'Could not find RenderRepaintBoundary for Order Section 47 page ${i + 1}');
      }

      final uiImage = await rb.toImage(pixelRatio: 3.0);
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw StateError(
            'Could not encode image data for Order Section 47 page ${i + 1}');
      }

      final rawImage = pw.RawImage(
        bytes: byteData.buffer.asUint8List(),
        width: uiImage.width,
        height: uiImage.height,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context _) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(
              rawImage,
              fit: pw.BoxFit.fill,
              width: PdfPageFormat.a4.width,
              height: PdfPageFormat.a4.height,
            ),
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
    debugPrint('Error in previewOrderSection4748Pdf: $e\n$st');
    final fallbackBytes = await generateOrderSection4748Pdf(doc);
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

// ──────────────────────────────────────────────────────────────────────────────
// Vector PDF Generator (Fallback)
// ──────────────────────────────────────────────────────────────────────────────

Future<Uint8List> generateOrderSection4748Pdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  pw.Font devanagari;
  try {
    devanagari = await PdfFontCache.devanagariBold();
  } catch (_) {
    devanagari = pw.Font.helveticaBold();
  }

  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final section = fld(['formSection']).toLowerCase();
  final isP1Explicit = section.contains('47') ||
      section.contains('main') ||
      section.contains('1');
  final isP2Explicit = section.contains('48') || section.contains('2');
  final showP1 = section.isEmpty ||
      section.contains('complete') ||
      isP1Explicit ||
      !isP2Explicit;
  final showP2 = section.isEmpty ||
      section.contains('complete') ||
      isP2Explicit ||
      !isP1Explicit;

  final titleStyle = pw.TextStyle(
    font: devanagari,
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
  );
  final bodyStyle = pw.TextStyle(
    font: devanagari,
    fontSize: 10,
  );

  if (showP1) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
                child:
                    pw.Text('नोटीस बी.एन.एस.एस.कलम ४७(१)', style: titleStyle)),
            pw.SizedBox(height: 12),
            pw.Text('प्रति: ${fld(['p1To1', 'accusedName', 'n47To'])}',
                style: bodyStyle),
            pw.Text(
                'पोलीस ठाणे: ${fld([
                      'policeStation',
                      'ps',
                      'n47PoliceStation'
                    ])}',
                style: bodyStyle),
            pw.Text(
                'गुन्हा रजि.क्र.: ${fld(['crNo', 'firNo', 'n47CrNo'])} / ${fld([
                      'crYear',
                      'firYear',
                      'n47CrYear'
                    ])}',
                style: bodyStyle),
            pw.Text('कलम: ${fld(['bnsSection', 'section', 'n47Section'])}',
                style: bodyStyle),
            pw.Text(
                'अटक दिनांक: ${_formatDate(fld([
                      'arrestDate',
                      'date',
                      'n47Date'
                    ]))} वेळ: ${_formatTime(fld([
                      'arrestTime',
                      'time',
                      'n47Time'
                    ]))}',
                style: bodyStyle),
          ],
        ),
      ),
    );
  }

  if (showP2) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
                child: pw.Text('नोटीस बी.एन.एस.एस.कलम ४८', style: titleStyle)),
            pw.SizedBox(height: 12),
            pw.Text('प्रति: ${fld(['p2To1', 'n48To'])}', style: bodyStyle),
            pw.Text(
                'अटक व्यक्तीचे नाव: ${fld([
                      'p2AccusedName',
                      'accusedName',
                      'p1To1'
                    ])}',
                style: bodyStyle),
            pw.Text(
                'पोलीस ठाणे: ${fld([
                      'policeStation',
                      'ps',
                      'n47PoliceStation'
                    ])}',
                style: bodyStyle),
            pw.Text(
                'गुन्हा रजि.क्र.: ${fld(['crNo', 'firNo', 'n47CrNo'])} / ${fld([
                      'crYear',
                      'firYear',
                      'n47CrYear'
                    ])}',
                style: bodyStyle),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}

// ── NATIVE FLUTTER WIDGET BUILDERS (100% Devanagari Font Shaping & Form Match)
// ══════════════════════════════════════════════════════════════════════════════

Widget orderSection4748Pg1Widget(Map<String, dynamic> doc, [Key? key]) =>
    KeyedSubtree(key: key, child: _buildPg1Widget(doc));

Widget orderSection4748Pg2Widget(Map<String, dynamic> doc, [Key? key]) =>
    KeyedSubtree(key: key, child: _buildPg2Widget(doc));

TextStyle _mReg(double size, [double? height]) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
      height: height,
    );

TextStyle _mBld(double size, [double? height]) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      height: height,
    );

TextStyle _valStyle(double size, [double? height]) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      height: height,
    );

String _insertZeroWidthSpaces(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.length >= 20 && !word.contains('\u200B')) {
      final buffer = StringBuffer();
      for (int i = 0; i < word.length; i++) {
        buffer.write(word[i]);
        if ((i + 1) % 18 == 0 && i + 1 < word.length) {
          buffer.write('\u200B');
        }
      }
      return buffer.toString();
    }
    return word;
  }).join(' ');
}

String _formatDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  try {
    final parts = trimmed.split(RegExp(r'[-/.]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
      } else {
        return '${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[2]}';
      }
    }
  } catch (_) {}
  return trimmed;
}

String _formatTime(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  try {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
            caseSensitive: false)
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

class _PdfLinedPainter extends CustomPainter {
  final int lineCount;
  final double lineHeight;
  final Color lineColor;

  _PdfLinedPainter({
    required this.lineCount,
    required this.lineHeight,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.85
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= lineCount; i++) {
      final y = i * lineHeight - 1.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PdfLinedPainter oldDelegate) =>
      oldDelegate.lineCount != lineCount ||
      oldDelegate.lineHeight != lineHeight ||
      oldDelegate.lineColor != lineColor;
}

Widget _buildLinedText(
  String text, {
  required TextStyle style,
  double lineHeight = 24.0,
  int minLines = 1,
  double indent = 0.0,
}) {
  final wrappedText = _insertZeroWidthSpaces(text.trim());
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : (794.0 - 80.0 - indent);

      int lineCount = minLines;
      if (wrappedText.isNotEmpty && maxWidth > 0) {
        final tp = TextPainter(
          text: TextSpan(text: wrappedText, style: style),
          textDirection: ui.TextDirection.ltr,
          maxLines: null,
        )..layout(maxWidth: maxWidth);
        lineCount = tp.computeLineMetrics().length;
        if (lineCount < minLines) lineCount = minLines;
      }

      final totalHeight = lineCount * lineHeight;

      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: CustomPaint(
          painter: _PdfLinedPainter(
            lineCount: lineCount,
            lineHeight: lineHeight,
            lineColor: Colors.black87,
          ),
          child: SizedBox(
            width: double.infinity,
            height: totalHeight,
            child: Text(
              wrappedText.isNotEmpty ? wrappedText : ' ',
              style: style.copyWith(
                height: lineHeight / (style.fontSize ?? 13.5),
                color: Colors.black87,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildRuledBlock({
  String prefix = '',
  required String text,
  required TextStyle boldStyle,
  required TextStyle textStyle,
  int minLines = 1,
  double bottomPadding = 6.0,
}) {
  final wrapped = _insertZeroWidthSpaces(text.trim());
  return Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prefix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 6),
            child: Text(prefix, style: boldStyle),
          ),
        Expanded(
          child: _buildLinedText(
            wrapped,
            style: textStyle,
            minLines: minLines,
            lineHeight: 24.0,
          ),
        ),
      ],
    ),
  );
}

Widget _buildInlineUnderlineField(
  String rawValue, {
  double minWidth = 100,
  double maxWidth = 680,
  String hint = '',
  TextAlign textAlign = TextAlign.start,
  IconData? icon,
  required TextStyle valStyle,
  required TextStyle hintStyle,
}) {
  final value = _insertZeroWidthSpaces(rawValue.trim());
  if (value.isEmpty) {
    return Container(
      width: minWidth,
      height: 22,
      alignment: textAlign == TextAlign.center
          ? Alignment.bottomCenter
          : Alignment.bottomLeft,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black54, width: 0.85),
        ),
      ),
      child: Text(hint, style: hintStyle, textAlign: textAlign),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth =
          constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : maxWidth;

      final tp = TextPainter(
        text: TextSpan(text: value, style: valStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: availableWidth);

      if (tp.computeLineMetrics().length <= 1) {
        final double itemW =
            (tp.size.width + 12.0).clamp(minWidth, availableWidth);
        return Container(
          width: itemW,
          height: 22,
          alignment: textAlign == TextAlign.center
              ? Alignment.bottomCenter
              : Alignment.bottomLeft,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black87, width: 0.85),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: textAlign == TextAlign.center
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: valStyle,
                  textAlign: textAlign,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 12, color: Colors.black54),
              ],
            ],
          ),
        );
      }

      return SizedBox(
        width: availableWidth,
        child: _buildLinedText(
          value,
          style: valStyle,
          lineHeight: 24.0,
          minLines: 1,
        ),
      );
    },
  );
}

Widget _buildPgWrapper(Widget pageContent) {
  return Container(
    width: 794.0,
    height: 1123.0,
    color: Colors.white,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 794.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: pageContent,
        ),
      ),
    ),
  );
}

Widget _buildPg1Widget(Map<String, dynamic> doc) {
  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final policeStation = fld(['policeStation', 'ps', 'n47PoliceStation']);
  final crNo = fld(['crNo', 'firNo', 'n47CrNo']);
  final crYear = fld(['crYear', 'firYear', 'n47CrYear']);
  final bnsSection = fld(['bnsSection', 'section', 'actSection', 'n47Section']);
  final arrestDate = fld(['arrestDate', 'date', 'n47Date']);
  final arrestTime = fld(['arrestTime', 'time', 'n47Time']);
  final ioName = fld(['ioName', 'shoName', 'n47IoName']);
  final pageRange = fld(['pageRange', 'formLabel']);

  final p1To1 = fld(['p1To1', 'accusedName', 'n47To']);
  final p1To2 = fld(['p1To2']);
  final p1To3 = fld(['p1To3']);
  final p1Fact1 = fld(['p1Fact1', 'orderBody', 'n47Body']);
  final p1Fact2 = fld(['p1Fact2']);
  final p1Fact3 = fld(['p1Fact3']);
  final p1Ground1 = fld(['p1Ground1']);
  final p1Ground2 = fld(['p1Ground2']);
  final p1Ground3 = fld(['p1Ground3']);
  final p1Ground4 = fld(['p1Ground4']);
  final p1Ground5 = fld(['p1Ground5']);
  final p1Reason1 = fld(['p1Reason1']);
  final p1Reason2 = fld(['p1Reason2']);
  final p1Reason3 = fld(['p1Reason3']);
  final p1Reason4 = fld(['p1Reason4']);
  final p1Reason5 = fld(['p1Reason5']);
  final p1RemandDate = fld(['p1RemandDate', 'arrestDate'], arrestDate);
  final p1AccusedSig =
      fld(['p1AccusedSig', 'n47AccusedSig', 'n47AccusedName'], p1To1);
  final p1IoSig = fld(['p1IoSig', 'n47IoName', 'ioName'], ioName);

  final titleStyle = _mBld(18.0, 1.2);
  final subTitleStyle = _mBld(15.0, 1.25);
  final boldLabelStyle = _mBld(13.5, 1.45);
  final bodyStyle = _mReg(13.5, 1.55);
  final valStyle = _valStyle(13.5, 1.45);
  final hintStyle = _mReg(12.0, 1.3).copyWith(color: Colors.black38);
  final badgeStyle = GoogleFonts.lora(
    fontSize: 12.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    decoration: TextDecoration.underline,
  );

  return _buildPgWrapper(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Text(
            pageRange.isNotEmpty
                ? pageRange
                : 'Page 1 — नोटीस बी.एन.एस.एस.कलम ४७(१)',
            style: badgeStyle,
          ),
        ),
        const SizedBox(height: 4),
        Center(child: Text('नोटीस', style: titleStyle)),
        const SizedBox(height: 2),
        Center(child: Text('बी.एन.एस.एस.कलम ४७(१)', style: subTitleStyle)),
        const SizedBox(height: 12),
        Text('प्रति,', style: boldLabelStyle),
        const SizedBox(height: 4),
        _buildRuledBlock(
          text: p1To1,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          text: p1To2,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          text: p1To3,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 8,
        ),
        const SizedBox(height: 6),
        Text(
          'विषय :- गुन्ह्याचे तपास कामी अटक करण्याचा आधार व कारणांबाबत...',
          style: boldLabelStyle,
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            const SizedBox(width: 24),
            Text('आपणास याद्वारे कळविण्यात येते की,', style: bodyStyle),
            _buildInlineUnderlineField(
              policeStation,
              minWidth: 160,
              maxWidth: 680,
              hint: 'पोलीस स्टेशन नाव',
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('पोलीस स्टेशन, गुन्हा रजि.नंबर', style: bodyStyle),
            _buildInlineUnderlineField(
              crNo,
              minWidth: 75,
              maxWidth: 120,
              hint: 'गु.र.नं.',
              textAlign: TextAlign.center,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('/', style: bodyStyle),
            _buildInlineUnderlineField(
              crYear,
              minWidth: 45,
              maxWidth: 80,
              hint: 'वर्ष',
              textAlign: TextAlign.center,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('भा.न्या.सं.कलम', style: bodyStyle),
            _buildInlineUnderlineField(
              bnsSection,
              minWidth: 180,
              maxWidth: 680,
              hint: 'उदा. १०३, ३(५)',
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text(
              'या गुन्ह्याचे तपासात निष्पन्न झालेल्या पुराव्यावरून आपणास दिनांक',
              style: bodyStyle,
            ),
            _buildInlineUnderlineField(
              _formatDate(arrestDate),
              minWidth: 110,
              maxWidth: 160,
              hint: 'दिनांक',
              icon: Icons.calendar_today,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('रोजी', style: bodyStyle),
            _buildInlineUnderlineField(
              _formatTime(arrestTime),
              minWidth: 90,
              maxWidth: 140,
              hint: 'वेळ',
              icon: Icons.access_time,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text(
              'वा. खालील आधारावर व कारणांसाठी अटक करण्यात येत आहे :-',
              style: bodyStyle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('अ) गुन्ह्याची थोडक्यात हकीगत :-', style: boldLabelStyle),
        const SizedBox(height: 4),
        _buildRuledBlock(
          text: p1Fact1,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          text: p1Fact2,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          text: p1Fact3,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 8,
        ),
        const SizedBox(height: 8),
        Text('ब) अटक करण्यासंबंधाने आधार :-', style: boldLabelStyle),
        const SizedBox(height: 4),
        _buildRuledBlock(
          prefix: '१)',
          text: p1Ground1,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '२)',
          text: p1Ground2,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '३)',
          text: p1Ground3,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '४)',
          text: p1Ground4,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '५)',
          text: p1Ground5,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 8,
        ),
        const SizedBox(height: 8),
        Text('क) अटकेची कारणे :-', style: boldLabelStyle),
        const SizedBox(height: 4),
        _buildRuledBlock(
          prefix: '१)',
          text: p1Reason1,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '२)',
          text: p1Reason2,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '३)',
          text: p1Reason3,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '४)',
          text: p1Reason4,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '५)',
          text: p1Reason5,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 8,
        ),
        const SizedBox(height: 8),
        Text(
          'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने आपण योग्य तो जामीन दिल्यास आपणास जामीनावर मुक्त करण्यात येईल.',
          style: bodyStyle,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('इ) आपणास दिनांक', style: bodyStyle),
            _buildInlineUnderlineField(
              _formatDate(p1RemandDate),
              minWidth: 110,
              maxWidth: 160,
              hint: 'दिनांक',
              icon: Icons.calendar_today,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text(
              'रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
              style: bodyStyle,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 36),
            child: Text('कळावे,', style: boldLabelStyle),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 225,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 56,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black54, width: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '(सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 220,
                    height: 22,
                    alignment: Alignment.bottomCenter,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black87, width: 0.85),
                      ),
                    ),
                    child: Text(
                      p1AccusedSig.isNotEmpty
                          ? p1AccusedSig
                          : (p1To1.isNotEmpty ? p1To1 : ' '),
                      style: valStyle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('आरोपीची स्वाक्षरी / अंगठा',
                      style: boldLabelStyle.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
            SizedBox(
              width: 225,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 56,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black54, width: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '(स्वाक्षरी व पोलीस स्टेशन शिक्का)',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 220,
                    height: 22,
                    alignment: Alignment.bottomCenter,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black87, width: 0.85),
                      ),
                    ),
                    child: Text(
                      p1IoSig.isNotEmpty
                          ? p1IoSig
                          : (ioName.isNotEmpty ? ioName : ' '),
                      style: valStyle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('तपासणी अधिकारी / अंमलदार',
                      style: boldLabelStyle.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPg2Widget(Map<String, dynamic> doc) {
  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final policeStation = fld(['policeStation', 'ps', 'n47PoliceStation']);
  final crNo = fld(['crNo', 'firNo', 'n47CrNo']);
  final crYear = fld(['crYear', 'firYear', 'n47CrYear']);
  final bnsSection = fld(['bnsSection', 'section', 'actSection', 'n47Section']);
  final arrestDate = fld(['arrestDate', 'date', 'n47Date']);
  final arrestTime = fld(['arrestTime', 'time', 'n47Time']);
  final ioName = fld(['ioName', 'shoName', 'n47IoName']);
  final pageRange = fld(['pageRange', 'formLabel']);

  final p1To1 = fld(['p1To1', 'accusedName', 'n47To']);
  final p1Fact1 = fld(['p1Fact1', 'orderBody', 'n47Body']);
  final p1Fact2 = fld(['p1Fact2']);
  final p1Fact3 = fld(['p1Fact3']);
  final p1Ground1 = fld(['p1Ground1']);
  final p1Ground2 = fld(['p1Ground2']);
  final p1Ground3 = fld(['p1Ground3']);
  final p1Ground4 = fld(['p1Ground4']);
  final p1Ground5 = fld(['p1Ground5']);
  final p1Reason1 = fld(['p1Reason1']);
  final p1Reason2 = fld(['p1Reason2']);
  final p1Reason3 = fld(['p1Reason3']);
  final p1Reason4 = fld(['p1Reason4']);
  final p1Reason5 = fld(['p1Reason5']);
  final p1RemandDate = fld(['p1RemandDate', 'arrestDate'], arrestDate);

  final p2To1 = fld(['p2To1', 'n48To']);
  final p2To2 = fld(['p2To2']);
  final p2To3 = fld(['p2To3']);
  final p2AccusedName = fld(['p2AccusedName', 'accusedName', 'p1To1'], p1To1);
  final p2Fact1 = fld(['p2Fact1', 'p1Fact1', 'orderBody'], p1Fact1);
  final p2Fact2 = fld(['p2Fact2', 'p1Fact2'], p1Fact2);
  final p2Fact3 = fld(['p2Fact3', 'p1Fact3'], p1Fact3);
  final p2Ground1 = fld(['p2Ground1', 'p1Ground1'], p1Ground1);
  final p2Ground2 = fld(['p2Ground2', 'p1Ground2'], p1Ground2);
  final p2Ground3 = fld(['p2Ground3', 'p1Ground3'], p1Ground3);
  final p2Ground4 = fld(['p2Ground4', 'p1Ground4'], p1Ground4);
  final p2Ground5 = fld(['p2Ground5', 'p1Ground5'], p1Ground5);
  final p2Reason1 = fld(['p2Reason1', 'p1Reason1'], p1Reason1);
  final p2Reason2 = fld(['p2Reason2', 'p1Reason2'], p1Reason2);
  final p2Reason3 = fld(['p2Reason3', 'p1Reason3'], p1Reason3);
  final p2Reason4 = fld(['p2Reason4', 'p1Reason4'], p1Reason4);
  final p2Reason5 = fld(['p2Reason5', 'p1Reason5'], p1Reason5);
  final p2RemandDate =
      fld(['p2RemandDate', 'p1RemandDate', 'arrestDate'], p1RemandDate);
  final p2RelativeSig = fld(['p2RelativeSig', 'n48RelativeSig'], p2To1);
  final p2IoSig = fld(['p2IoSig', 'n48IoName', 'ioName'], ioName);

  final titleStyle = _mBld(18.0, 1.2);
  final subTitleStyle = _mBld(15.0, 1.25);
  final boldLabelStyle = _mBld(13.5, 1.45);
  final bodyStyle = _mReg(13.5, 1.55);
  final valStyle = _valStyle(13.5, 1.45);
  final hintStyle = _mReg(12.0, 1.3).copyWith(color: Colors.black38);
  final badgeStyle = GoogleFonts.lora(
    fontSize: 12.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    decoration: TextDecoration.underline,
  );

  return _buildPgWrapper(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Text(
            pageRange.isNotEmpty
                ? pageRange
                : 'Page 2 — नोटीस बी.एन.एस.एस.कलम ४८',
            style: badgeStyle,
          ),
        ),
        const SizedBox(height: 4),
        Center(child: Text('नोटीस', style: titleStyle)),
        const SizedBox(height: 2),
        Center(child: Text('बी.एन.एस.एस.कलम ४८', style: subTitleStyle)),
        const SizedBox(height: 12),
        Text('प्रति,', style: boldLabelStyle),
        const SizedBox(height: 4),
        _buildRuledBlock(
          text: p2To1,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          text: p2To2,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          text: p2To3,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 8,
        ),
        const SizedBox(height: 6),
        Text(
          'विषय :- गुन्ह्याचे तपास कामी अटक केले संबंधी अवगत केले बाबत...',
          style: boldLabelStyle,
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            const SizedBox(width: 24),
            Text('आपणास याद्वारे कळविण्यात येते की,', style: bodyStyle),
            _buildInlineUnderlineField(
              policeStation,
              minWidth: 160,
              maxWidth: 680,
              hint: 'पोलीस स्टेशन नाव',
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('पोलीस स्टेशन, गुन्हा रजि.नंबर', style: bodyStyle),
            _buildInlineUnderlineField(
              crNo,
              minWidth: 75,
              maxWidth: 120,
              hint: 'गु.र.नं.',
              textAlign: TextAlign.center,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('/', style: bodyStyle),
            _buildInlineUnderlineField(
              crYear,
              minWidth: 45,
              maxWidth: 80,
              hint: 'वर्ष',
              textAlign: TextAlign.center,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('भा.न्या.सं.कलम', style: bodyStyle),
            _buildInlineUnderlineField(
              bnsSection,
              minWidth: 180,
              maxWidth: 680,
              hint: 'उदा. १०३, ३(५)',
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text(
              'या गुन्ह्यात आपले नातेवाईक / मित्र / आप्तेष्ठ नामे',
              style: bodyStyle,
            ),
            _buildInlineUnderlineField(
              p2AccusedName,
              minWidth: 200,
              maxWidth: 680,
              hint: '[अटक व्यक्तीचे नाव]',
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('यांना दिनांक', style: bodyStyle),
            _buildInlineUnderlineField(
              _formatDate(arrestDate),
              minWidth: 110,
              maxWidth: 160,
              hint: 'दिनांक',
              icon: Icons.calendar_today,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('रोजी', style: bodyStyle),
            _buildInlineUnderlineField(
              _formatTime(arrestTime),
              minWidth: 90,
              maxWidth: 140,
              hint: 'वेळ',
              icon: Icons.access_time,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text('वा. अटक करण्यात आली आहे.', style: bodyStyle),
          ],
        ),
        const SizedBox(height: 12),
        Text('अ) गुन्ह्याची थोडक्यात हकीगत :-', style: boldLabelStyle),
        const SizedBox(height: 4),
        _buildRuledBlock(
          text: p2Fact1,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          text: p2Fact2,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          text: p2Fact3,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 8,
        ),
        const SizedBox(height: 8),
        Text('ब) अटक करण्यासंबंधाने आधार :-', style: boldLabelStyle),
        const SizedBox(height: 4),
        _buildRuledBlock(
          prefix: '१)',
          text: p2Ground1,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '२)',
          text: p2Ground2,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '३)',
          text: p2Ground3,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '४)',
          text: p2Ground4,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '५)',
          text: p2Ground5,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 8,
        ),
        const SizedBox(height: 8),
        Text('क) अटकेची कारणे :-', style: boldLabelStyle),
        const SizedBox(height: 4),
        _buildRuledBlock(
          prefix: '१)',
          text: p2Reason1,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '२)',
          text: p2Reason2,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '३)',
          text: p2Reason3,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '४)',
          text: p2Reason4,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 6,
        ),
        _buildRuledBlock(
          prefix: '५)',
          text: p2Reason5,
          boldStyle: boldLabelStyle,
          textStyle: valStyle,
          minLines: 1,
          bottomPadding: 8,
        ),
        const SizedBox(height: 8),
        Text(
          'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने योग्य तो जामीन दिल्यास अटक व्यक्तीस जामीनावर मुक्त करण्यात येईल.',
          style: bodyStyle,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('इ) अटक व्यक्तीला दिनांक', style: bodyStyle),
            _buildInlineUnderlineField(
              _formatDate(p2RemandDate),
              minWidth: 110,
              maxWidth: 160,
              hint: 'दिनांक',
              icon: Icons.calendar_today,
              valStyle: valStyle,
              hintStyle: hintStyle,
            ),
            Text(
              'रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
              style: bodyStyle,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 36),
            child: Text('कळावे,', style: boldLabelStyle),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 225,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 56,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black54, width: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '(सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 220,
                    height: 22,
                    alignment: Alignment.bottomCenter,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black87, width: 0.85),
                      ),
                    ),
                    child: Text(
                      p2RelativeSig.isNotEmpty
                          ? p2RelativeSig
                          : (p2To1.isNotEmpty ? p2To1 : ' '),
                      style: valStyle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('नातेवाईकाची स्वाक्षरी / अंगठा',
                      style: boldLabelStyle.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
            SizedBox(
              width: 225,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 56,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black54, width: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '(स्वाक्षरी व पोलीस स्टेशन शिक्का)',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 220,
                    height: 22,
                    alignment: Alignment.bottomCenter,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black87, width: 0.85),
                      ),
                    ),
                    child: Text(
                      p2IoSig.isNotEmpty
                          ? p2IoSig
                          : (ioName.isNotEmpty ? ioName : ' '),
                      style: valStyle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('तपासणी अधिकारी / अंमलदार',
                      style: boldLabelStyle.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
