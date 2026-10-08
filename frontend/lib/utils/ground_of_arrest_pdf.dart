import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';
import 'pdf_font_cache.dart';

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

/// Inserts zero-width spaces (\u200B) every 18 chars ONLY into continuous runs of 20+ chars without spaces.
/// Leaves all normal Marathi text untouched so conjuncts, halant and matras are never broken.
String _insertZeroWidthSpaces(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.length > 20) {
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

/// Dedicated Ground of Arrest PDF preview & generation.
/// Guarantees strictly 2 pages, zero blank pages, high resolution pixelRatio 3.0,
/// and no reliance on shared ceil() slicing.
Future<void> previewGroundOfArrestPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Ground_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';

  final overlay = Overlay.of(context);

  // 1. Ensure NotoSansDevanagari is loaded before offscreen render
  try {
    await GoogleFonts.pendingFonts().timeout(const Duration(milliseconds: 600));
  } catch (_) {}

  final keyPg1 = GlobalKey();
  final keyPg2 = GlobalKey();
  final contentKeyPg1 = GlobalKey();
  final contentKeyPg2 = GlobalKey();

  final pg1Widget = _buildPg1Widget(doc, contentKeyPg1);
  final pg2Widget = _buildPg2Widget(doc, contentKeyPg2);

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -3000,
      top: 0,
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: keyPg1,
              child: pg1Widget,
            ),
            RepaintBoundary(
              key: keyPg2,
              child: pg2Widget,
            ),
          ],
        ),
      ),
    ),
  );

  overlay.insert(entry);

  final statusNotifier = ValueNotifier<String>('Generating page 1 of 2...');
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

    // Measure unscaled content heights to log actual usage
    final renderContent1 =
        contentKeyPg1.currentContext?.findRenderObject() as RenderBox?;
    final renderContent2 =
        contentKeyPg2.currentContext?.findRenderObject() as RenderBox?;
    final double h1 = renderContent1?.size.height ?? 0.0;
    final double h2 = renderContent2?.size.height ?? 0.0;
    debugPrint(
        '[GroundOfArrestPDF] Measured Page 1 unscaled content height: $h1 px (A4 limit: 1123 px)');
    debugPrint(
        '[GroundOfArrestPDF] Measured Page 2 unscaled content height: $h2 px (A4 limit: 1123 px)');

    RenderRepaintBoundary? rb1 =
        keyPg1.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    RenderRepaintBoundary? rb2 =
        keyPg2.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (rb1 == null || rb2 == null || !rb1.hasSize || !rb2.hasSize) {
      WidgetsBinding.instance.scheduleFrame();
      await Future.any([
        WidgetsBinding.instance.endOfFrame,
        Future.delayed(const Duration(milliseconds: 150)),
      ]);
      rb1 = keyPg1.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      rb2 = keyPg2.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    }

    if (rb1 == null || rb2 == null) {
      throw StateError(
          'Could not locate RenderRepaintBoundary for Ground of Arrest pages');
    }

    // Capture pages at pixelRatio 2.0 with fast native JPEG encoder for razor sharp text and instant PDF compile
    statusNotifier.value = 'Generating page 1 of 2...';
    final img1 = await rb1.toImage(pixelRatio: 2.0);
    final bytes1 =
        await FormImagePdfHelper.encodeImageFast(img1, quality: 0.84);
    img1.dispose();

    statusNotifier.value = 'Generating page 2 of 2...';
    final img2 = await rb2.toImage(pixelRatio: 2.0);
    final bytes2 =
        await FormImagePdfHelper.encodeImageFast(img2, quality: 0.84);
    img2.dispose();

    // Construct strictly 2-page PDF document
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(
          pw.MemoryImage(bytes1),
          fit: pw.BoxFit.fill,
          width: PdfPageFormat.a4.width,
          height: PdfPageFormat.a4.height,
        ),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(
          pw.MemoryImage(bytes2),
          fit: pw.BoxFit.fill,
          width: PdfPageFormat.a4.width,
          height: PdfPageFormat.a4.height,
        ),
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: fileName);
    }
  } catch (e, st) {
    debugPrint('Error in previewGroundOfArrestPdf: $e\n$st');
    final fallbackBytes = await generateGroundOfArrestPdf(doc);
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

// ══════════════════════════════════════════════════════════════════════════════
// ── SOLID LINED MULTILINE PAINTER & WIDGET HELPERS ──
// ══════════════════════════════════════════════════════════════════════════════

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
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= lineCount; i++) {
      final y = i * lineHeight - 2.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PdfLinedPainter oldDelegate) {
    return oldDelegate.lineCount != lineCount ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.lineColor != lineColor;
  }
}

Widget _buildLinedText(
  String text, {
  required TextStyle style,
  double lineHeight = 26.0,
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

Widget _buildAddressBlock(
  String line1,
  String line2,
  TextStyle labelStyle,
  TextStyle textStyle,
) {
  final combined =
      [line1.trim(), line2.trim()].where((s) => s.isNotEmpty).join(' ');
  final fullText = _insertZeroWidthSpaces(combined);

  return LayoutBuilder(
    builder: (context, constraints) {
      final totalWidth =
          constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 714.0;

      final labelSpan = TextSpan(text: 'नाव व पत्ता ', style: labelStyle);
      final labelTp =
          TextPainter(text: labelSpan, textDirection: ui.TextDirection.ltr)
            ..layout();
      final labelWidth = labelTp.size.width;
      final firstLineWidth = totalWidth - labelWidth;

      if (fullText.isEmpty) {
        return Column(
          children: [
            Row(
              children: [
                Text('नाव व पत्ता ', style: labelStyle),
                Expanded(
                    child: _buildLinedText('', style: textStyle, minLines: 1)),
              ],
            ),
            const SizedBox(height: 3),
            _buildLinedText('', style: textStyle, minLines: 1),
          ],
        );
      }

      final tp = TextPainter(
        text: TextSpan(text: fullText, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: firstLineWidth);

      if (tp.computeLineMetrics().length <= 1) {
        return Column(
          children: [
            Row(
              children: [
                Text('नाव व पत्ता ', style: labelStyle),
                Expanded(
                    child: _buildLinedText(fullText,
                        style: textStyle, minLines: 1)),
              ],
            ),
            const SizedBox(height: 3),
            _buildLinedText('', style: textStyle, minLines: 1),
          ],
        );
      }

      final pos = tp.getPositionForOffset(Offset(firstLineWidth, 0));
      int splitIndex = pos.offset;
      if (splitIndex <= 0 || splitIndex > fullText.length) {
        splitIndex = fullText.length;
      }
      final lastSpace = fullText.lastIndexOf(RegExp(r'[\s\u200B]'), splitIndex);
      if (lastSpace > 10) {
        splitIndex = lastSpace;
      }

      final firstLineText = fullText.substring(0, splitIndex).trim();
      final restText = fullText.substring(splitIndex).trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('नाव व पत्ता ', style: labelStyle),
              Expanded(
                  child: _buildLinedText(firstLineText,
                      style: textStyle, minLines: 1)),
            ],
          ),
          const SizedBox(height: 3),
          _buildLinedText(restText, style: textStyle, minLines: 1),
        ],
      );
    },
  );
}

Widget _buildGroundItem(
  String num,
  String line1,
  String line2,
  TextStyle boldStyle,
  TextStyle textStyle,
) {
  final combined =
      [line1.trim(), line2.trim()].where((s) => s.isNotEmpty).join(' ');
  final fullText = _insertZeroWidthSpaces(combined);

  return LayoutBuilder(
    builder: (context, constraints) {
      final totalWidth =
          constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 714.0;
      final numSpan = TextSpan(text: '$num. ', style: boldStyle);
      final numTp =
          TextPainter(text: numSpan, textDirection: ui.TextDirection.ltr)
            ..layout();
      final numWidth = numTp.size.width;
      final firstLineWidth = totalWidth - numWidth;

      if (fullText.isEmpty) {
        return Column(
          children: [
            Row(
              children: [
                Text('$num. ', style: boldStyle),
                Expanded(
                    child: _buildLinedText('', style: textStyle, minLines: 1)),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: _buildLinedText('', style: textStyle, minLines: 1),
            ),
            const SizedBox(height: 4),
          ],
        );
      }

      final tp = TextPainter(
        text: TextSpan(text: fullText, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: firstLineWidth);

      if (tp.computeLineMetrics().length <= 1) {
        return Column(
          children: [
            Row(
              children: [
                Text('$num. ', style: boldStyle),
                Expanded(
                    child: _buildLinedText(fullText,
                        style: textStyle, minLines: 1)),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: _buildLinedText('', style: textStyle, minLines: 1),
            ),
            const SizedBox(height: 4),
          ],
        );
      }

      final pos = tp.getPositionForOffset(Offset(firstLineWidth, 0));
      int splitIndex = pos.offset;
      if (splitIndex <= 0 || splitIndex > fullText.length) {
        splitIndex = fullText.length;
      }
      final lastSpace = fullText.lastIndexOf(RegExp(r'[\s\u200B]'), splitIndex);
      if (lastSpace > 10) {
        splitIndex = lastSpace;
      }

      final firstLineText = fullText.substring(0, splitIndex).trim();
      final restText = fullText.substring(splitIndex).trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('$num. ', style: boldStyle),
              Expanded(
                  child: _buildLinedText(firstLineText,
                      style: textStyle, minLines: 1)),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _buildLinedText(restText, style: textStyle, minLines: 1),
          ),
          const SizedBox(height: 4),
        ],
      );
    },
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDERS (FittedBox Safe Scaling, Zero Blank Pages) ──
// ══════════════════════════════════════════════════════════════════════════════

Widget groundOfArrestPg1Widget(Map<String, dynamic> doc,
        [GlobalKey? contentKey]) =>
    _buildPg1Widget(doc, contentKey);

Widget groundOfArrestPg2Widget(Map<String, dynamic> doc,
        [GlobalKey? contentKey]) =>
    _buildPg2Widget(doc, contentKey);

Widget _buildPg1Widget(Map<String, dynamic> doc, [GlobalKey? contentKey]) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final outwardNo = v('outwardNo');
  final outwardYear = v('outwardYear', '२५');
  final policeStation = v('policeStation');
  final taluka = v('taluka');
  final district = v('district');
  final noticeDate = _formatDate(v('noticeDate'));

  final accusedNameAddress = v('accusedNameAddress');
  final accusedNameAddressLine2 = v('accusedNameAddressLine2');

  final subjectPs = v('subjectPs');
  final subjectCrNo = v('subjectCrNo');
  final subjectSection = v('subjectSection');

  final firPs = v('firPs');
  final firCrNo = v('firCrNo');
  final firCrYear = v('firCrYear');
  final firActSec = v('firActSec');
  final ioName = v('ioName');

  final briefDescription = v('briefDescription');
  final briefDescLine2 = v('briefDescLine2');
  final briefDescLine3 = v('briefDescLine3');
  final briefDescLine4 = v('briefDescLine4');
  final briefDescLine5 = v('briefDescLine5');

  // Full readable form-matching typography
  final reg = GoogleFonts.notoSansDevanagari(
    fontSize: 13.5,
    height: 1.5,
    color: Colors.black87,
  );
  final bld = GoogleFonts.notoSansDevanagari(
    fontSize: 13.5,
    height: 1.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final header1 = GoogleFonts.notoSansDevanagari(
    fontSize: 16.5,
    height: 1.4,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final header2 = GoogleFonts.notoSansDevanagari(
    fontSize: 15.0,
    height: 1.4,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  return Container(
    width: 794.0,
    height: 1123.0,
    color: Colors.white,
    alignment: Alignment.topCenter,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 794.0,
        child: Container(
          key: contentKey,
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 34.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Text(
                      'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये',
                      style: header1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text('सुचनापत्र', style: header2),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Top-Right Outward Details
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('जावक.क्रमांक- ', style: reg),
                          Expanded(
                              child: _buildLinedText(outwardNo,
                                  style: reg, minLines: 1)),
                          Text(' /२०$outwardYear', style: reg),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('पोलीस स्टेशन ', style: reg),
                          Expanded(
                              child: _buildLinedText(policeStation,
                                  style: reg, minLines: 1)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('ता.-', style: reg),
                          Expanded(
                              child: _buildLinedText(taluka,
                                  style: reg, minLines: 1)),
                          Text(' -जिल्हा-', style: reg),
                          Expanded(
                              child: _buildLinedText(district,
                                  style: reg, minLines: 1)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('दिनांक:- ', style: reg),
                          SizedBox(
                            width: 140,
                            child: _buildLinedText(noticeDate,
                                style: reg, minLines: 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Recipient Section
              Text('प्रति,', style: bld),
              const SizedBox(height: 4),
              _buildAddressBlock(
                  accusedNameAddress, accusedNameAddressLine2, bld, reg),
              const SizedBox(height: 14),

              // Subject Section
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: reg,
                  children: [
                    TextSpan(
                      text:
                          'विषय:- पोलीस स्टेशन $subjectPs गुन्हा रजि.क्र.$subjectCrNo कलम $subjectSection भा.न्या.स.\n',
                      style: bld,
                    ),
                    const TextSpan(
                      text:
                          '        नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक\n        करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Main FIR Investigation Paragraph
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: reg,
                  children: [
                    const TextSpan(
                      text:
                          '        आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुद्ध पोलीस ठाणे ',
                    ),
                    TextSpan(text: '$firPs ', style: bld),
                    const TextSpan(text: 'येथे गुन्हा रजि.क्र.'),
                    TextSpan(text: '$firCrNo/$firCrYear ', style: bld),
                    const TextSpan(text: 'कलम '),
                    TextSpan(text: '$firActSec ', style: bld),
                    const TextSpan(
                      text:
                          'भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन, आम्ही ',
                    ),
                    TextSpan(text: '$ioName ', style: bld),
                    const TextSpan(
                      text:
                          'तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत.सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार आपणास अटक करण्यासाठी आधारभूत मुद्दे (भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार ) खालील प्रमाणे आहेत.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // गुन्ह्यांचे संक्षीप्त विवरण
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('गुन्ह्यांचे संक्षीप्त विवरण :- ', style: bld),
                  Expanded(
                      child: _buildLinedText(briefDescription,
                          style: reg, minLines: 1)),
                ],
              ),
              const SizedBox(height: 3),
              _buildLinedText(briefDescLine2, style: reg, minLines: 1),
              const SizedBox(height: 3),
              _buildLinedText(briefDescLine3, style: reg, minLines: 1),
              const SizedBox(height: 3),
              _buildLinedText(briefDescLine4, style: reg, minLines: 1),
              const SizedBox(height: 3),
              _buildLinedText(briefDescLine5, style: reg, minLines: 1),
              const SizedBox(height: 14),

              // Footer Note & Continuation Indicator
              Text(
                '(अधिक माहितीसाठी फिर्यादीची प्रत सोबत जोडली आहे)',
                style: reg.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Text('२..', style: bld.copyWith(fontSize: 15.0)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildPg2Widget(Map<String, dynamic> doc, [GlobalKey? contentKey]) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final ground1 = v('ground1');
  final ground1Line2 = v('ground1Line2');
  final ground2 = v('ground2');
  final ground2Line2 = v('ground2Line2');
  final ground3 = v('ground3');
  final ground3Line2 = v('ground3Line2');
  final ground4 = v('ground4');
  final ground4Line2 = v('ground4Line2');
  final ground5 = v('ground5');
  final ground5Line2 = v('ground5Line2');

  final relativeName = v('relativeName');
  final relativeAddress = v('relativeAddress');
  final relativePhone = v('relativePhone');

  final accusedSig = v('accusedSig');
  final accusedName = v('accusedName');
  final accusedDate = _formatDate(v('accusedDateOnly', v('accusedDateTime')));
  final accusedTime = _formatTime(v('accusedTimeOnly'));
  final accusedDateTimeCombined =
      [accusedDate, accusedTime].where((s) => s.isNotEmpty).join(' ');

  final ioSig = v('ioSig');
  final ioNameRank = v('ioNameRank');
  final ioPs = v('ioPs');
  final ioTah = v('ioTah');
  final ioDist = v('ioDist');

  final reg = GoogleFonts.notoSansDevanagari(
    fontSize: 13.5,
    height: 1.5,
    color: Colors.black87,
  );
  final bld = GoogleFonts.notoSansDevanagari(
    fontSize: 13.5,
    height: 1.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final header1 = GoogleFonts.notoSansDevanagari(
    fontSize: 16.5,
    height: 1.4,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  return Container(
    width: 794.0,
    height: 1123.0,
    color: Colors.white,
    alignment: Alignment.topCenter,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 794.0,
        child: Container(
          key: contentKey,
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 34.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page 2 Header
              Center(child: Text('..२..', style: bld.copyWith(fontSize: 15.0))),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'अटक करण्यासाठी आधारभूत मुद्दे (GROUNDS OF ARREST)',
                  style: header1,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),

              // Grounds 1 to 5 with Indented Continuation Lines
              _buildGroundItem('१', ground1, ground1Line2, bld, reg),
              _buildGroundItem('२', ground2, ground2Line2, bld, reg),
              _buildGroundItem('३', ground3, ground3Line2, bld, reg),
              _buildGroundItem('४', ground4, ground4Line2, bld, reg),
              _buildGroundItem('५', ground5, ground5Line2, bld, reg),
              const SizedBox(height: 14),

              // Bail/Cognizable Notice
              Text(
                '        आपणास असेही कळविण्यात येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
                style: reg,
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 14),

              // Relative/Friend Intimation Notice
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: reg,
                  children: [
                    const TextSpan(
                      text:
                          '        आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र ',
                    ),
                    TextSpan(
                      text: relativeName.isNotEmpty
                          ? '$relativeName '
                          : ' _________________ ',
                      style: bld.copyWith(
                        decoration: relativeName.isNotEmpty
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                    const TextSpan(text: 'रा.'),
                    TextSpan(
                      text: relativeAddress.isNotEmpty
                          ? '$relativeAddress '
                          : ' _________________ ',
                      style: bld.copyWith(
                        decoration: relativeAddress.isNotEmpty
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                    const TextSpan(
                      text: 'यांना लेखी सुचनेद्वारे/फोन क्रमांक ',
                    ),
                    TextSpan(
                      text: relativePhone.isNotEmpty
                          ? '$relativePhone '
                          : ' _________________ ',
                      style: bld.copyWith(
                        decoration: relativePhone.isNotEmpty
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                    const TextSpan(
                      text: 'यावर संपर्क करुन देण्यांत आली आहे.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Final Statement
              Text(
                '        याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
                style: reg,
              ),
              const SizedBox(height: 24),

              // Signatures Table (Directly follows content without Spacer or bottom pinning)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Accused
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('मला सुचनापत्र प्राप्त झाले', style: bld),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('(आरोपीची सही ', style: reg),
                            Expanded(
                                child: _buildLinedText(accusedSig,
                                    style: reg, minLines: 1)),
                            Text(')', style: reg),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('आरोपीचे नांव ', style: reg),
                            Expanded(
                                child: _buildLinedText(accusedName,
                                    style: reg, minLines: 1)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('दिनांक व वेळ ', style: reg),
                            Expanded(
                                child: _buildLinedText(accusedDateTimeCombined,
                                    style: reg, minLines: 1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Right Column: IO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('तपास अधि सही/- $ioSig', style: bld),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('नाव/हुद्दा ', style: reg),
                            Expanded(
                                child: _buildLinedText(ioNameRank,
                                    style: reg, minLines: 1)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('पोलीस स्टेशन ', style: reg),
                            Expanded(
                                child: _buildLinedText(ioPs,
                                    style: reg, minLines: 1)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('ता.-', style: reg),
                            Expanded(
                                child: _buildLinedText(ioTah,
                                    style: reg, minLines: 1)),
                            Text(' जिल्हा-', style: reg),
                            Expanded(
                                child: _buildLinedText(ioDist,
                                    style: reg, minLines: 1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── VECTOR PDF GENERATOR (Fallback Engine) ──
// ══════════════════════════════════════════════════════════════════════════════

Future<Uint8List> generateGroundOfArrestPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfFontCache.devanagariRegular();
  final devanagariBold = await PdfFontCache.devanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 10.0,
    lineSpacing: 3.5,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.0,
    fontWeight: pw.FontWeight.bold,
    lineSpacing: 3.5,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 13.0,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  pw.Widget pwUnderline(String text,
      {double minWidth = 60, bool expand = false}) {
    final line = pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(width: 0.8, color: PdfColors.black)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Text(text.isNotEmpty ? text : ' ', style: regular),
    );
    return expand
        ? pw.Expanded(child: line)
        : pw.Container(width: minWidth, child: line);
  }

  // Page 1
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                      'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये',
                      style: headerTitle,
                      textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 2),
                  pw.Text('सुचनापत्र', style: headerTitle),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 280,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('जावक.क्रमांक- ', style: regular),
                        pwUnderline(v('outwardNo'), minWidth: 80, expand: true),
                        pw.Text(' /२०${v('outwardYear', '२५')}',
                            style: regular),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        pw.Text('पोलीस स्टेशन ', style: regular),
                        pwUnderline(v('policeStation'),
                            minWidth: 100, expand: true),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        pw.Text('ता.-', style: regular),
                        pwUnderline(v('taluka'), minWidth: 50, expand: true),
                        pw.Text(' -जिल्हा-', style: regular),
                        pwUnderline(v('district'), minWidth: 50, expand: true),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        pw.Text('दिनांक:- ', style: regular),
                        pwUnderline(_formatDate(v('noticeDate')), minWidth: 90),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('प्रति,', style: bold),
            pw.SizedBox(height: 3),
            pw.Row(
              children: [
                pw.Text('नाव व पत्ता ', style: regular),
                pwUnderline(v('accusedNameAddress'), expand: true),
              ],
            ),
            pw.SizedBox(height: 3),
            pwUnderline(v('accusedNameAddressLine2'), expand: false),
            pw.SizedBox(height: 10),
            pw.Text(
                'विषय:- पोलीस स्टेशन ${v('subjectPs')} गुन्हा रजि.क्र.${v('subjectCrNo')} कलम ${v('subjectSection')} भा.न्या.स.',
                style: bold),
            pw.Text(
                '        नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
                style: regular),
            pw.SizedBox(height: 10),
            pw.Text(
                '        आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुद्ध पोलीस ठाणे ${v('firPs')} येथे गुन्हा रजि.क्र. ${v('firCrNo')}/${v('firCrYear')} कलम ${v('firActSec')} भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन, आम्ही ${v('ioName')} तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत.सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार आपणास अटक करण्यासाठी आधारभूत मुद्दे खालील प्रमाणे आहेत.',
                style: regular,
                textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Text('गुन्ह्यांचे संक्षीप्त विवरण :- ', style: regular),
                pwUnderline(v('briefDescription'), expand: true),
              ],
            ),
            pw.SizedBox(height: 3),
            pwUnderline(v('briefDescLine2'), expand: false),
            pw.SizedBox(height: 3),
            pwUnderline(v('briefDescLine3'), expand: false),
            pw.SizedBox(height: 3),
            pwUnderline(v('briefDescLine4'), expand: false),
            pw.SizedBox(height: 3),
            pwUnderline(v('briefDescLine5'), expand: false),
            pw.SizedBox(height: 10),
            pw.Text('(अधिक माहितीसाठी फिर्यादीची प्रत सोबत जोडली आहे)',
                style: regular),
            pw.Spacer(),
            pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text('२..', style: bold)),
          ],
        );
      },
    ),
  );

  // Page 2
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(child: pw.Text('..२..', style: bold)),
            pw.SizedBox(height: 6),
            pw.Center(
                child: pw.Text(
                    'अटक करण्यासाठी आधारभूत मुद्दे (GROUNDS OF ARREST)',
                    style: headerTitle)),
            pw.SizedBox(height: 12),
            for (int i = 1; i <= 5; i++) ...[
              pw.Row(
                children: [
                  pw.Text('$i. ', style: regular),
                  pwUnderline(v('ground$i'), expand: true),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 14),
                child: pwUnderline(v('ground${i}Line2'), expand: false),
              ),
              pw.SizedBox(height: 4),
            ],
            pw.SizedBox(height: 10),
            pw.Text(
                '        आपणास असेही कळविण्यात येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
                style: regular,
                textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 8),
            pw.Text(
                '        आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र ${v('relativeName')} रा. ${v('relativeAddress')} यांना लेखी सुचनेद्वारे/फोन क्रमांक ${v('relativePhone')} यावर संपर्क करुन देण्यांत आली आहे.',
                style: regular,
                textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 8),
            pw.Text('        याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
                style: regular),
            pw.SizedBox(height: 20),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('मला सुचनापत्र प्राप्त झाले', style: bold),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.Text('(आरोपीची सही ', style: regular),
                        pwUnderline(v('accusedSig'), expand: true),
                        pw.Text(')', style: regular)
                      ]),
                      pw.SizedBox(height: 3),
                      pw.Row(children: [
                        pw.Text('आरोपीचे नांव ', style: regular),
                        pwUnderline(v('accusedName'), expand: true)
                      ]),
                      pw.SizedBox(height: 3),
                      pw.Row(children: [
                        pw.Text('दिनांक व वेळ ', style: regular),
                        pwUnderline(
                            '${_formatDate(v('accusedDateOnly', v('accusedDateTime')))} ${_formatTime(v('accusedTimeOnly'))}'
                                .trim(),
                            expand: true)
                      ]),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपास अधि सही/- ${v('ioSig')}', style: bold),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.Text('नाव/हुद्दा ', style: regular),
                        pwUnderline(v('ioNameRank'), expand: true)
                      ]),
                      pw.SizedBox(height: 3),
                      pw.Row(children: [
                        pw.Text('पोलीस स्टेशन ', style: regular),
                        pwUnderline(v('ioPs'), expand: true)
                      ]),
                      pw.SizedBox(height: 3),
                      pw.Row(children: [
                        pw.Text('ता.-', style: regular),
                        pwUnderline(v('ioTah'), expand: true),
                        pw.Text(' जिल्हा-', style: regular),
                        pwUnderline(v('ioDist'), expand: true)
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
