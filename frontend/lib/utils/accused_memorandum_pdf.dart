// lib/utils/accused_memorandum_pdf.dart
//
// ACCUSED MEMORANDUM FORM (Form: 2-E, "ACCUSED MEMORANDUM FORM / आरोपीचे निवेदन पंचनामा")
// Under Section 23(2) Bhartiya Sakshya Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३
//
// High quality rendering offscreen at pixelRatio 3.0 for crisp Marathi Devanagari typography,
// multi-line text wrapping with solid bottom underlines, zero-width space wrapping for runs > 20 chars,
// and matching layout for Part I (Accused Memorandum) and Part II (Further Panchanama).

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

const double _kPdfPageWidth = 794.0;
const double _kPdfPageHeight = 1123.0;

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

String _v(Map<String, dynamic> doc, String key, [String fallback = '']) {
  final val = doc[key]?.toString().trim() ?? '';
  return val.isEmpty ? fallback : val;
}

TextStyle _eBld([double sz = 10]) => GoogleFonts.lora(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

TextStyle _mBld([double sz = 9.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

TextStyle _mReg([double sz = 9.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      color: Colors.black87,
    );

TextStyle _valStyle([double sz = 9.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );

class _FullWidthUnderlinePainter extends CustomPainter {
  final List<ui.LineMetrics> metrics;
  final Color color;
  final double thickness;

  _FullWidthUnderlinePainter({
    required this.metrics,
    this.color = Colors.black87,
    this.thickness = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    if (metrics.isNotEmpty) {
      for (final m in metrics) {
        final lineBottom = m.baseline + m.descent;
        final y = (lineBottom - 0.5).clamp(1.0, size.height - 0.5);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else {
      canvas.drawLine(
        Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FullWidthUnderlinePainter oldDelegate) => true;
}

Widget _bilingualField(
  String eng,
  String mr,
  String rawVal, {
  double? width,
  bool expand = false,
}) {
  final val = _insertZeroWidthSpaces(rawVal);
  final baseStyle = val.isNotEmpty ? _valStyle(9.5) : _mReg(9.5);
  final style = baseStyle.copyWith(height: baseStyle.height ?? 1.75);
  final text = val.isNotEmpty ? val : ' ';

  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: eng, style: _eBld(9.5)),
            const TextSpan(text: ' '),
            TextSpan(text: '($mr)', style: _mBld(9)),
          ],
        ),
        softWrap: true,
      ),
      const SizedBox(height: 2),
      LayoutBuilder(
        builder: (context, constraints) {
          final w = width ??
              (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : 100.0);
          final textMaxWidth = (w - 2.0).clamp(10.0, w);
          final tp = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: ui.TextDirection.ltr,
          )..layout(maxWidth: textMaxWidth);
          final metrics = tp.computeLineMetrics();

          return SizedBox(
            width: w,
            child: CustomPaint(
              painter: _FullWidthUnderlinePainter(
                metrics: metrics,
                color: Colors.black87,
                thickness: 0.8,
              ),
              child: SizedBox(
                width: w,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 1, right: 1),
                  child: Text(
                    text,
                    softWrap: true,
                    style: style,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  );

  if (expand) return Expanded(child: content);
  if (width != null) return SizedBox(width: width, child: content);
  return content;
}

class _PdfRuledLinesPainter extends CustomPainter {
  final double lineHeight;
  final Color lineColor;

  const _PdfRuledLinesPainter({
    this.lineHeight = 22.0,
    this.lineColor = const Color(0xFFCCCCCC),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    final count = (size.height / lineHeight).floor();
    for (int i = 1; i <= count; i++) {
      final y = i * lineHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PdfRuledLinesPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 1: PART I (Accused Memorandum)
// ─────────────────────────────────────────────────────────────────────────────

Widget accusedMemorandumPg1Widget(Map<String, dynamic> doc, [Key? key]) {
  final dist =
      _v(doc, 'dist').isNotEmpty ? _v(doc, 'dist') : _v(doc, 'district');
  final ps =
      _v(doc, 'ps').isNotEmpty ? _v(doc, 'ps') : _v(doc, 'policeStation');
  final year = _v(doc, 'year');
  final firNo = _v(doc, 'firNo');
  final firDate = _formatDate(_v(doc, 'firDate'));

  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedSex = _v(doc, 'accusedSex');

  final arrestDate = _formatDate(_v(doc, 'arrestDate'));
  final arrestTime = _formatTime(_v(doc, 'arrestTime'));

  final memo = _insertZeroWidthSpaces(_v(doc, 'accusedMemorandum'));
  final placeMemo = _v(doc, 'placeOfMemorandum');
  final memDate = _formatDate(_v(doc, 'memDate'));
  final memTime = _v(doc, 'memTime');

  final panch1 = _insertZeroWidthSpaces(_v(doc, 'panch1NameAddr'));
  final panch1Sig = _insertZeroWidthSpaces(_v(doc, 'panch1Sig'));
  final panch2 = _insertZeroWidthSpaces(_v(doc, 'panch2NameAddr'));
  final panch2Sig = _insertZeroWidthSpaces(_v(doc, 'panch2Sig'));

  final part1AccusedSig = _insertZeroWidthSpaces(_v(doc, 'part1AccusedSig'));
  final ioName = _v(doc, 'part1IoName');
  final ioRank = _v(doc, 'part1IoRank');
  final ioNo = _v(doc, 'part1IoNo');
  final ioPosting = _v(doc, 'part1IoPosting');

  return Container(
    key: key,
    width: _kPdfPageWidth,
    height: _kPdfPageHeight,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top right Form Label
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Form: 2-E',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 4),

        // Title Header
        Center(
          child: Column(
            children: [
              Text(
                'ACCUSED MEMORANDUM FORM',
                style: _eBld(15).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'गुन्ह्यांच्या तपशीलाचा नमुना/ आरोपीचे निवेदन पंचनामा',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '(Panchanama u/s 23(2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३)',
                style: _eBld(9.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 6),

        // Section 1: 2-Row Case Details
        // Row 1: District and P.S.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1) ', style: _eBld(10)),
            _bilingualField('District:', 'जिल्हा', dist, width: 220),
            const SizedBox(width: 32),
            _bilingualField('P.S.:', 'पोलीस स्टेशन', ps, expand: true),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: Year, FIR No, Date
        Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bilingualField('Year:', 'वर्ष', year, width: 110),
              const SizedBox(width: 20),
              _bilingualField('FIR No:', 'पहिली खबर क्र.', firNo, width: 300),
              const SizedBox(width: 20),
              _bilingualField('Date:', 'तारीख', firDate, expand: true),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section 2: Accused Particulars
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2) ', style: _eBld(10)),
            _bilingualField(
                'Name of Accused:', 'आरोपीचे नाव व पत्ता', accusedName,
                expand: true),
            const SizedBox(width: 12),
            _bilingualField('Age:', 'वय', accusedAge, width: 70),
            const SizedBox(width: 12),
            _bilingualField('Sex:', 'लिंग', accusedSex, width: 70),
          ],
        ),
        const SizedBox(height: 8),

        // Section 3: Date & Time of Arrest
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('3) ', style: _eBld(10)),
            _bilingualField('Date of Arrest:', 'अटक तारीख', arrestDate,
                width: 220),
            const SizedBox(width: 24),
            _bilingualField('Time of Arrest:', 'अटक वेळ', arrestTime,
                width: 220),
          ],
        ),
        const SizedBox(height: 8),

        // Section 4: Memorandum Text (Expanded with authentic ruled lines)
        Row(
          children: [
            Text('4) Memorandum made by Accused: - ', style: _eBld(9.5)),
            Text('(आरोपीने केलेले निवेदन: -)', style: _mBld(9.5)),
          ],
        ),
        const SizedBox(height: 3),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: _PdfRuledLinesPainter(
                        lineHeight: 22.0,
                        lineColor: Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      child: Text(
                        memo.isNotEmpty ? memo : ' ',
                        style: (memo.isNotEmpty ? _valStyle(9.5) : _mReg(9.5))
                            .copyWith(height: 22.0 / 9.5),
                        strutStyle: const StrutStyle(
                          fontSize: 9.5,
                          height: 22.0 / 9.5,
                          forceStrutHeight: true,
                        ),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Section 5: Place & Time of Memorandum
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('5) ', style: _eBld(10)),
            _bilingualField(
                'Place of Memorandum:', 'निवेदनाचे ठिकाण', placeMemo,
                expand: true),
            const SizedBox(width: 12),
            _bilingualField('Date:', 'दिनांक', memDate, width: 110),
            const SizedBox(width: 12),
            _bilingualField('Time:', 'वेळ', memTime, width: 110),
          ],
        ),
        const SizedBox(height: 8),

        // Section 6: Panchas
        Row(
          children: [
            Text('6) Name & Address of Panchas & Signatures: ',
                style: _eBld(9.5)),
            Text('(पंचांची नावे, पत्ते व सह्या)', style: _mBld(9.5)),
          ],
        ),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('क्र.', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('पंचाचे नाव व पत्ता', style: _mBld(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('पंचाची सही', style: _mBld(9))),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('१', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(panch1.isNotEmpty ? panch1 : ' ',
                      style: panch1.isNotEmpty ? _valStyle(9) : _mReg(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(panch1Sig.isNotEmpty ? panch1Sig : ' ',
                        style: panch1Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('२', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(panch2.isNotEmpty ? panch2 : ' ',
                      style: panch2.isNotEmpty ? _valStyle(9) : _mReg(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(panch2Sig.isNotEmpty ? panch2Sig : ' ',
                        style: panch2Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Section 7: Signatures (Part I)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('7) Accused Signature and Thumb', style: _eBld(9.5)),
                Text('   आरोपीची सही व अंगठा', style: _mBld(9)),
                const SizedBox(height: 14),
                Text(
                  part1AccusedSig.isNotEmpty
                      ? part1AccusedSig
                      : '_______________________',
                  style:
                      part1AccusedSig.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Signature of Investigation Officer', style: _eBld(9.5)),
                Text('तपासणी करणाऱ्या अधिकाऱ्याची सही व हुद्दा',
                    style: _mBld(9)),
                const SizedBox(height: 4),
                Text('नाव: ${ioName.isNotEmpty ? ioName : '____________'}',
                    style: ioName.isNotEmpty ? _valStyle(9) : _mReg(9)),
                Text(
                    'हुद्दा: ${ioRank.isNotEmpty ? ioRank : '_______'}  क्र.: ${ioNo.isNotEmpty ? ioNo : '______'}',
                    style: _mReg(9)),
                Text(
                    'नेमणूक: ${ioPosting.isNotEmpty ? ioPosting : '________________'}',
                    style: ioPosting.isNotEmpty ? _valStyle(9) : _mReg(9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2: PART II (Further Panchanama)
// ─────────────────────────────────────────────────────────────────────────────

Widget accusedMemorandumPg2Widget(Map<String, dynamic> doc, [Key? key]) {
  final further = _insertZeroWidthSpaces(_v(doc, 'furtherPanchanama'));
  final furtherDate = _formatDate(_v(doc, 'furtherDate'));
  final furtherTime = _v(doc, 'furtherTime');

  final panch1 = _insertZeroWidthSpaces(_v(doc, 'furtherPanch1NameAddr'));
  final panch1Sig = _insertZeroWidthSpaces(_v(doc, 'furtherPanch1Sig'));
  final panch2 = _insertZeroWidthSpaces(_v(doc, 'furtherPanch2NameAddr'));
  final panch2Sig = _insertZeroWidthSpaces(_v(doc, 'furtherPanch2Sig'));

  final accusedSig = _insertZeroWidthSpaces(_v(doc, 'accusedSig'));
  final ioName = _v(doc, 'ioName');
  final ioRank = _v(doc, 'ioRank');
  final ioNo = _v(doc, 'ioNo');
  final ioPosting = _v(doc, 'ioPosting');

  return Container(
    key: key,
    width: _kPdfPageWidth,
    height: _kPdfPageHeight,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top right Form Label
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Form: 2-E (Part II)',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 4),

        // Title Header
        Center(
          child: Column(
            children: [
              Text(
                'ACCUSED MEMORANDUM FORM (Part II)',
                style: _eBld(15).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'अधिक पंचनामा (Part II)',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '(Panchanama u/s 23(2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३)',
                style: _eBld(9.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 8),

        // Section 8: Details of Further Panchanama (Expanded with authentic ruled lines)
        Row(
          children: [
            Text('8) Details of Further Panchanama: ', style: _eBld(10)),
            Text('(पंचनाम्याचा पुढील भाग):-', style: _mBld(10)),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: _PdfRuledLinesPainter(
                        lineHeight: 22.0,
                        lineColor: Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      child: Text(
                        further.isNotEmpty ? further : ' ',
                        style:
                            (further.isNotEmpty ? _valStyle(9.8) : _mReg(9.8))
                                .copyWith(height: 22.0 / 9.8),
                        strutStyle: const StrutStyle(
                          fontSize: 9.8,
                          height: 22.0 / 9.8,
                          forceStrutHeight: true,
                        ),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Date & Time
        Row(
          children: [
            _bilingualField('Date:', 'दिनांक', furtherDate, width: 140),
            const SizedBox(width: 24),
            _bilingualField('Time:', 'वेळ', furtherTime, width: 140),
          ],
        ),
        const SizedBox(height: 12),

        // Section 9: Panchas (Part II)
        Row(
          children: [
            Text('9) Name & Address of Panchas & Signatures: ',
                style: _eBld(9.5)),
            Text('(पंचांची नावे, पत्ते व सह्या)', style: _mBld(9.5)),
          ],
        ),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('क्र.', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('पंचाचे नाव व पत्ता', style: _mBld(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('पंचाची सही', style: _mBld(9))),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('१', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(panch1.isNotEmpty ? panch1 : ' ',
                      style: panch1.isNotEmpty ? _valStyle(9) : _mReg(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(panch1Sig.isNotEmpty ? panch1Sig : ' ',
                        style: panch1Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('२', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(panch2.isNotEmpty ? panch2 : ' ',
                      style: panch2.isNotEmpty ? _valStyle(9) : _mReg(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(panch2Sig.isNotEmpty ? panch2Sig : ' ',
                        style: panch2Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Section 10: Signatures (Part II)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('10) Accused Signature and Thumb', style: _eBld(9.5)),
                Text('    आरोपीची सही व अंगठा', style: _mBld(9)),
                const SizedBox(height: 18),
                Text(
                  accusedSig.isNotEmpty
                      ? accusedSig
                      : '_______________________',
                  style: accusedSig.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Signature of Investigation Officer', style: _eBld(9.5)),
                Text('तपासणी करणाऱ्या अधिकाऱ्याची सही व हुद्दा',
                    style: _mBld(9)),
                const SizedBox(height: 4),
                Text('नाव: ${ioName.isNotEmpty ? ioName : '____________'}',
                    style: ioName.isNotEmpty ? _valStyle(9) : _mReg(9)),
                Text(
                    'हुद्दा: ${ioRank.isNotEmpty ? ioRank : '_______'}  क्र.: ${ioNo.isNotEmpty ? ioNo : '______'}',
                    style: _mReg(9)),
                Text(
                    'नेमणूक: ${ioPosting.isNotEmpty ? ioPosting : '________________'}',
                    style: ioPosting.isNotEmpty ? _valStyle(9) : _mReg(9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}

Future<void> previewAccusedMemorandumPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Accused_Memorandum_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final sectionStr = (doc['formSection'] ?? '').toString().toLowerCase().trim();
  final isPartIOnly = sectionStr == 'accused part i' ||
      (sectionStr.contains('part i') && !sectionStr.contains('part ii'));
  final isPartIIOnly =
      sectionStr == 'accused part ii' || sectionStr.contains('part ii');

  final overlay = Overlay.of(context);

  try {
    await GoogleFonts.pendingFonts().timeout(const Duration(milliseconds: 600));
  } catch (_) {}

  final keyPg1 = GlobalKey();
  final keyPg2 = GlobalKey();

  final pageWidgets = <Widget>[];
  if (!isPartIIOnly) {
    pageWidgets.add(RepaintBoundary(
      key: keyPg1,
      child: accusedMemorandumPg1Widget(doc),
    ));
  }
  if (!isPartIOnly) {
    pageWidgets.add(RepaintBoundary(
      key: keyPg2,
      child: accusedMemorandumPg2Widget(doc),
    ));
  }

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -3000,
      top: 0,
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: pageWidgets,
        ),
      ),
    ),
  );

  overlay.insert(entry);

  final statusNotifier = ValueNotifier<String>('Generating preview...');
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

    final capturedBytesList = <Uint8List>[];

    if (!isPartIIOnly) {
      RenderRepaintBoundary? rb1 =
          keyPg1.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (rb1 == null || !rb1.hasSize) {
        WidgetsBinding.instance.scheduleFrame();
        await Future.any([
          WidgetsBinding.instance.endOfFrame,
          Future.delayed(const Duration(milliseconds: 150)),
        ]);
        rb1 =
            keyPg1.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      }
      if (rb1 != null) {
        statusNotifier.value = 'Generating page 1...';
        final img1 = await rb1.toImage(pixelRatio: 3.0);
        final bd1 = await img1.toByteData(format: ui.ImageByteFormat.png);
        img1.dispose();
        if (bd1 != null) capturedBytesList.add(bd1.buffer.asUint8List());
      }
    }

    if (!isPartIOnly) {
      RenderRepaintBoundary? rb2 =
          keyPg2.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (rb2 == null || !rb2.hasSize) {
        WidgetsBinding.instance.scheduleFrame();
        await Future.any([
          WidgetsBinding.instance.endOfFrame,
          Future.delayed(const Duration(milliseconds: 150)),
        ]);
        rb2 =
            keyPg2.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      }
      if (rb2 != null) {
        statusNotifier.value = 'Generating page 2...';
        final img2 = await rb2.toImage(pixelRatio: 3.0);
        final bd2 = await img2.toByteData(format: ui.ImageByteFormat.png);
        img2.dispose();
        if (bd2 != null) capturedBytesList.add(bd2.buffer.asUint8List());
      }
    }

    if (capturedBytesList.isEmpty) {
      throw StateError(
          'Could not render any page image for Accused Memorandum');
    }

    final pdf = pw.Document();
    for (final b in capturedBytesList) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            pw.MemoryImage(b),
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
    debugPrint('Error in previewAccusedMemorandumPdf: $e\n$st');
    final fallbackBytes = await generateAccusedMemorandumPdf(doc);
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

Future<Uint8List> generateAccusedMemorandumPdf(
  Map<String, dynamic> doc,
) async {
  final sectionStr = (doc['formSection'] ?? '').toString().toLowerCase().trim();
  final isPartIOnly = sectionStr == 'accused part i' ||
      (sectionStr.contains('part i') && !sectionStr.contains('part ii'));
  final isPartIIOnly =
      sectionStr == 'accused part ii' || sectionStr.contains('part ii');

  final dist =
      _v(doc, 'dist').isNotEmpty ? _v(doc, 'dist') : _v(doc, 'district');
  final ps =
      _v(doc, 'ps').isNotEmpty ? _v(doc, 'ps') : _v(doc, 'policeStation');
  final year = _v(doc, 'year');
  final firNo = _v(doc, 'firNo');
  final firDate = _formatDate(_v(doc, 'firDate'));

  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedSex = _v(doc, 'accusedSex');

  final arrestDate = _formatDate(_v(doc, 'arrestDate'));
  final arrestTime = _formatTime(_v(doc, 'arrestTime'));

  final memo = _insertZeroWidthSpaces(_v(doc, 'accusedMemorandum'));
  final placeMemo = _v(doc, 'placeOfMemorandum');
  final memDate = _formatDate(_v(doc, 'memDate'));
  final memTime = _v(doc, 'memTime');

  final panch1 = _insertZeroWidthSpaces(_v(doc, 'panch1NameAddr'));
  final panch1Sig = _insertZeroWidthSpaces(_v(doc, 'panch1Sig'));
  final panch2 = _insertZeroWidthSpaces(_v(doc, 'panch2NameAddr'));
  final panch2Sig = _insertZeroWidthSpaces(_v(doc, 'panch2Sig'));

  final part1AccusedSig = _insertZeroWidthSpaces(_v(doc, 'part1AccusedSig'));
  final ioName = _v(doc, 'part1IoName');
  final ioRank = _v(doc, 'part1IoRank');
  final ioNo = _v(doc, 'part1IoNo');
  final ioPosting = _v(doc, 'part1IoPosting');

  final further = _insertZeroWidthSpaces(_v(doc, 'furtherPanchanama'));
  final furtherDate = _formatDate(_v(doc, 'furtherDate'));
  final furtherTime = _v(doc, 'furtherTime');

  final furtherPanch1 =
      _insertZeroWidthSpaces(_v(doc, 'furtherPanch1NameAddr'));
  final furtherPanch1Sig = _insertZeroWidthSpaces(_v(doc, 'furtherPanch1Sig'));
  final furtherPanch2 =
      _insertZeroWidthSpaces(_v(doc, 'furtherPanch2NameAddr'));
  final furtherPanch2Sig = _insertZeroWidthSpaces(_v(doc, 'furtherPanch2Sig'));

  final accusedSig = _insertZeroWidthSpaces(_v(doc, 'accusedSig'));
  final ioName2 = _v(doc, 'ioName');
  final ioRank2 = _v(doc, 'ioRank');
  final ioNo2 = _v(doc, 'ioNo');
  final ioPosting2 = _v(doc, 'ioPosting');

  final pdf = pw.Document();

  pw.Widget buildUnderlineField(String eng, String mr, String val,
      {double? width}) {
    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$eng ($mr)',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.SizedBox(height: 2),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
            ),
            child: pw.Text(val.isNotEmpty ? val : ' ',
                style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  if (!isPartIIOnly) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text('Form: 2-E',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline)),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('ACCUSED MEMORANDUM FORM',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          decoration: pw.TextDecoration.underline)),
                  pw.Text(
                      'गुन्ह्यांच्या तपशीलाचा नमुना/ आरोपीचे निवेदन पंचनामा',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                      '(Panchanama u/s 23(2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३)',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 4),
            // Row 1: District and P.S.
            pw.Row(
              children: [
                pw.Text('1) ',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
                buildUnderlineField('District:', 'जिल्हा', dist, width: 160),
                pw.SizedBox(width: 16),
                pw.Expanded(
                    child: buildUnderlineField('P.S.:', 'पोलीस ठाणे', ps)),
              ],
            ),
            pw.SizedBox(height: 6),
            // Row 2: Year, FIR No, Date
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12),
              child: pw.Row(
                children: [
                  buildUnderlineField('Year:', 'वर्ष', year, width: 90),
                  pw.SizedBox(width: 16),
                  buildUnderlineField('FIR No:', 'गु.र.क्र.', firNo,
                      width: 160),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                      child: buildUnderlineField('Date:', 'दिनांक', firDate)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Text('2) ',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Expanded(
                    child: buildUnderlineField('Name of Accused:',
                        'आरोपीचे नाव व पत्ता', accusedName)),
                pw.SizedBox(width: 10),
                buildUnderlineField('Age:', 'वय', accusedAge, width: 60),
                pw.SizedBox(width: 10),
                buildUnderlineField('Sex:', 'लिंग', accusedSex, width: 60),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Text('3) ',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
                buildUnderlineField('Date of Arrest:', 'अटक तारीख', arrestDate,
                    width: 160),
                pw.SizedBox(width: 16),
                buildUnderlineField('Time of Arrest:', 'अटक वेळ', arrestTime,
                    width: 160),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
                '4) Memorandum made by Accused: - (आरोपीने केलेले निवेदन: -)',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.SizedBox(height: 3),
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.8)),
                child: pw.Text(memo.isNotEmpty ? memo : ' ',
                    style: const pw.TextStyle(fontSize: 9.5)),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Text('5) ',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Expanded(
                    child: buildUnderlineField(
                        'Place of Memorandum:', 'निवेदनाचे ठिकाण', placeMemo)),
                pw.SizedBox(width: 10),
                buildUnderlineField('Date:', 'दिनांक', memDate, width: 90),
                pw.SizedBox(width: 10),
                buildUnderlineField('Time:', 'वेळ', memTime, width: 90),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
                '6) Name & Address of Panchas & Signatures: (पंचांची नावे, पत्ते व सह्या)',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Center(
                          child: pw.Text('क्र.',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('पंचाचे नाव व पत्ता',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Center(
                          child: pw.Text('पंचाची सही',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5))),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                            child: pw.Text('१',
                                style: const pw.TextStyle(fontSize: 8.5)))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(panch1.isNotEmpty ? panch1 : ' ',
                            style: const pw.TextStyle(fontSize: 8.5))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                            child: pw.Text(
                                panch1Sig.isNotEmpty ? panch1Sig : ' ',
                                style: const pw.TextStyle(fontSize: 8.5)))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                            child: pw.Text('२',
                                style: const pw.TextStyle(fontSize: 8.5)))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(panch2.isNotEmpty ? panch2 : ' ',
                            style: const pw.TextStyle(fontSize: 8.5))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                            child: pw.Text(
                                panch2Sig.isNotEmpty ? panch2Sig : ' ',
                                style: const pw.TextStyle(fontSize: 8.5)))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('7) Accused Signature and Thumb',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('   आरोपीची सही व अंगठा',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        part1AccusedSig.isNotEmpty
                            ? part1AccusedSig
                            : '_______________________',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Signature of Investigation Officer',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('तपासणी करणाऱ्या अधिकाऱ्याची सही व हुद्दा',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text(
                        'नाव: ${ioName.isNotEmpty ? ioName : '____________'}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text(
                        'हुद्दा: ${ioRank.isNotEmpty ? ioRank : '_______'} क्र.: ${ioNo.isNotEmpty ? ioNo : '______'}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text(
                        'नेमणूक: ${ioPosting.isNotEmpty ? ioPosting : '________________'}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  if (!isPartIOnly) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text('Form: 2-E (Part II)',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline)),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('ACCUSED MEMORANDUM FORM (Part II)',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          decoration: pw.TextDecoration.underline)),
                  pw.Text('अधिक पंचनामा (Part II)',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                      '(Panchanama u/s 23(2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३)',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
            pw.Text(
                '8) Details of Further Panchanama: (पंचनाम्याचा पुढील भाग):-',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
            pw.SizedBox(height: 4),
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.8)),
                child: pw.Text(further.isNotEmpty ? further : ' ',
                    style: const pw.TextStyle(fontSize: 9.5)),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                buildUnderlineField('Date:', 'दिनांक', furtherDate, width: 140),
                pw.SizedBox(width: 24),
                buildUnderlineField('Time:', 'वेळ', furtherTime, width: 140),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
                '9) Name & Address of Panchas & Signatures: (पंचांची नावे, पत्ते व सह्या)',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Center(
                          child: pw.Text('क्र.',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('पंचाचे नाव व पत्ता',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Center(
                          child: pw.Text('पंचाची सही',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8.5))),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                            child: pw.Text('१',
                                style: const pw.TextStyle(fontSize: 8.5)))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                            furtherPanch1.isNotEmpty ? furtherPanch1 : ' ',
                            style: const pw.TextStyle(fontSize: 8.5))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                            child: pw.Text(
                                furtherPanch1Sig.isNotEmpty
                                    ? furtherPanch1Sig
                                    : ' ',
                                style: const pw.TextStyle(fontSize: 8.5)))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                            child: pw.Text('२',
                                style: const pw.TextStyle(fontSize: 8.5)))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                            furtherPanch2.isNotEmpty ? furtherPanch2 : ' ',
                            style: const pw.TextStyle(fontSize: 8.5))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                            child: pw.Text(
                                furtherPanch2Sig.isNotEmpty
                                    ? furtherPanch2Sig
                                    : ' ',
                                style: const pw.TextStyle(fontSize: 8.5)))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('10) Accused Signature and Thumb',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('    आरोपीची सही व अंगठा',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        accusedSig.isNotEmpty
                            ? accusedSig
                            : '_______________________',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Signature of Investigation Officer',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text('तपासणी करणाऱ्या अधिकाऱ्याची सही व हुद्दा',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text(
                        'नाव: ${ioName2.isNotEmpty ? ioName2 : '____________'}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text(
                        'हुद्दा: ${ioRank2.isNotEmpty ? ioRank2 : '_______'} क्र.: ${ioNo2.isNotEmpty ? ioNo2 : '______'}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text(
                        'नेमणूक: ${ioPosting2.isNotEmpty ? ioPosting2 : '________________'}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}
