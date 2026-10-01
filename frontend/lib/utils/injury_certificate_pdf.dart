import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'form_image_pdf_helper.dart';
import 'pdf_font_cache.dart';

Future<void> previewInjuryCertificatePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Injury_Certificate_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPgWidget(doc)],
    fallbackPdfGenerator: () => generateInjuryCertificatePdf(doc),
  );
}

Future<Uint8List> generateInjuryCertificatePdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfFontCache.loraRegular();
  final loraBold = await PdfFontCache.loraBold();
  final devanagari = await PdfFontCache.devanagariRegular();
  final devanagariBold = await PdfFontCache.devanagariBold();

  final regular = pw.TextStyle(font: loraRegular, fontSize: 9.5);
  final bold = pw.TextStyle(
    font: loraBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    decoration: pw.TextDecoration.underline,
  );

  String v(String key) => doc[key]?.toString().trim() ?? '';

  pw.Widget underlineField(
    String text, {
    double? width,
    double minWidth = 40,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    final t = text.trim();
    return pw.Container(
      width: width,
      constraints: pw.BoxConstraints(minWidth: minWidth),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.8, color: PdfColors.black),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 2, left: 2, right: 2),
      child: pw.Text(
        t.isEmpty ? ' ' : t,
        textAlign: textAlign,
        style: bold,
      ),
    );
  }

  pw.Widget staticText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text, style: regular),
    );
  }

  final rawInjuries = doc['injuries'];
  final List<Map<String, String>> injuryList = [];
  if (rawInjuries is List && rawInjuries.isNotEmpty) {
    for (final item in rawInjuries) {
      if (item is Map) {
        injuryList.add({
          'typeOfInjury': item['typeOfInjury']?.toString() ?? '',
          'siteOnBody': item['siteOnBody']?.toString() ?? '',
          'ageOfInjury': item['ageOfInjury']?.toString() ?? '',
          'size': item['size']?.toString() ?? '',
          'color': item['color']?.toString() ?? '',
          'probableWeapon': item['probableWeapon']?.toString() ?? '',
          'simpleGrievous': item['simpleGrievous']?.toString() ?? '',
          'remark': item['remark']?.toString() ?? '',
        });
      }
    }
  }
  while (injuryList.length < 6) {
    injuryList.add({
      'typeOfInjury': '',
      'siteOnBody': '',
      'ageOfInjury': '',
      'size': '',
      'color': '',
      'probableWeapon': '',
      'simpleGrievous': '',
      'remark': '',
    });
  }

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(
        base: loraRegular,
        bold: loraBold,
        fontFallback: [devanagari, devanagariBold],
      ),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.bottomRight,
        child: pw.Text('M.R.W', style: bold.copyWith(fontSize: 8)),
      ),
      build: (ctx) => [
        pw.Center(
          child: pw.Text('INJURY CERTIFICATE', style: titleStyle),
        ),
        pw.SizedBox(height: 14),

        // ── TOP RIGHT MLC / DATE ──
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Container(
            width: 220,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('MLC No.:-', style: bold),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                        child: underlineField(v('mlcNo'), minWidth: 100)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Date. ', style: bold),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                        child: underlineField(v('mlcDate'), minWidth: 100)),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 16),

        // ── CERTIFICATE BODY PARAGRAPH ──
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                staticText('Certified that shri/smt  '),
                pw.Expanded(
                  child: underlineField(v('patientName'), minWidth: 100),
                ),
                staticText('  age  '),
                underlineField(v('patientAge'),
                    width: 50, minWidth: 35, textAlign: pw.TextAlign.center),
                staticText('  about years'),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                staticText('bearing following identification mark R/O.  '),
                pw.Expanded(
                  child: underlineField(v('idMarkAndAddress'), minWidth: 100),
                ),
                staticText('  tah  '),
                underlineField(v('tah'),
                    width: 75, minWidth: 50, textAlign: pw.TextAlign.center),
                staticText('  dist.  '),
                underlineField(v('dist'),
                    width: 90, minWidth: 60, textAlign: pw.TextAlign.center),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                staticText('brought to this hospital by PC/HC.  '),
                pw.Expanded(
                  flex: 3,
                  child: underlineField(v('broughtBy'), minWidth: 80),
                ),
                staticText('  B.No.  '),
                underlineField(v('buckleNo'),
                    width: 60, minWidth: 40, textAlign: pw.TextAlign.center),
                staticText('  Police station.  '),
                pw.Expanded(
                  flex: 3,
                  child: underlineField(v('policeStation'), minWidth: 80),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                staticText('at  '),
                underlineField(v('broughtTime'),
                    width: 55, minWidth: 40, textAlign: pw.TextAlign.center),
                staticText('  AM/PM on  '),
                underlineField(v('broughtDate'),
                    width: 95, minWidth: 70, textAlign: pw.TextAlign.center),
                staticText('  & examination by me on  '),
                underlineField(v('examDate'),
                    width: 95, minWidth: 70, textAlign: pw.TextAlign.center),
                staticText('  at  '),
                underlineField(v('examTime'),
                    width: 55, minWidth: 40, textAlign: pw.TextAlign.center),
                staticText('  AM/PM'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 18),

        // ── 9-COLUMN TABLE ──
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2.2),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(2),
            7: const pw.FlexColumnWidth(1.6),
            8: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPdfHeaderCell('Sr\nno', bold),
                _buildPdfHeaderCell('Type of\ninjury', bold),
                _buildPdfHeaderCell('Site on the part of\nbody', bold),
                _buildPdfHeaderCell('Age of\ninjury', bold),
                _buildPdfHeaderCell('Size', bold),
                _buildPdfHeaderCell('Color', bold),
                _buildPdfHeaderCell('Probable\nweapon used', bold),
                _buildPdfHeaderCell('Simpler\nGrievous', bold),
                _buildPdfHeaderCell('Remark', bold),
              ],
            ),
            for (int i = 0; i < injuryList.length; i++)
              pw.TableRow(
                children: [
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child:
                        pw.Text('${i + 1}', style: bold.copyWith(fontSize: 8)),
                  ),
                  _buildPdfDataCell(
                      injuryList[i]['typeOfInjury'] ?? '', regular),
                  _buildPdfDataCell(injuryList[i]['siteOnBody'] ?? '', regular),
                  _buildPdfDataCell(
                      injuryList[i]['ageOfInjury'] ?? '', regular),
                  _buildPdfDataCell(injuryList[i]['size'] ?? '', regular),
                  _buildPdfDataCell(injuryList[i]['color'] ?? '', regular),
                  _buildPdfDataCell(
                      injuryList[i]['probableWeapon'] ?? '', regular),
                  _buildPdfDataCell(
                      injuryList[i]['simpleGrievous'] ?? '', regular),
                  _buildPdfDataCell(injuryList[i]['remark'] ?? '', regular),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 36),

        // ── FOOTER SECTION ──
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('Date:- ', style: bold),
                  pw.SizedBox(width: 4),
                  pw.Expanded(
                    child: underlineField(v('footerDate'), minWidth: 80),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('Place:- ', style: bold),
                  pw.SizedBox(width: 4),
                  pw.Expanded(
                    child: underlineField(v('footerPlace'), minWidth: 80),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Medical officer', style: bold),
                  pw.Text('Name and Sign', style: bold),
                  pw.SizedBox(height: 4),
                  pw.SizedBox(
                    width: double.infinity,
                    child: underlineField(v('moName'), minWidth: 100),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Align(
          alignment: pw.Alignment.bottomRight,
          child: pw.Text(
            'M.R.W',
            style: regular.copyWith(fontSize: 8.5, color: PdfColors.grey700),
          ),
        ),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _buildPdfHeaderCell(String text, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 6),
    child: pw.Center(
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: style.copyWith(fontSize: 8),
      ),
    ),
  );
}

pw.Widget _buildPdfDataCell(String text, pw.TextStyle style) {
  return pw.Container(
    constraints: const pw.BoxConstraints(minHeight: 28),
    padding: const pw.EdgeInsets.all(3),
    child: pw.Text(
      text,
      style: style.copyWith(fontSize: 8),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDER (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

class _InjuryLinePainter extends CustomPainter {
  final int lines;
  final double lineHeight;

  const _InjuryLinePainter({
    required this.lines,
    required this.lineHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 0.85
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= lines; i++) {
      final y = (i * lineHeight) - 1.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InjuryLinePainter oldDelegate) =>
      oldDelegate.lines != lines || oldDelegate.lineHeight != lineHeight;
}

class _DynamicInjuryUnderlineField extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int minLines;
  final double lineHeight;
  final double? width;
  final double minWidth;
  final TextAlign textAlign;

  const _DynamicInjuryUnderlineField({
    required this.text,
    required this.style,
    this.minLines = 1,
    this.lineHeight = 22.0,
    this.width,
    this.minWidth = 40.0,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 500.0);
        final effectiveW = maxW < minWidth ? minWidth : maxW;
        int lines = minLines;
        if (trimmed.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(text: trimmed, style: style),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: effectiveW > 0 ? effectiveW : 500.0);
          final metrics = tp.computeLineMetrics();
          lines = metrics.isEmpty ? 1 : metrics.length;
          if (lines < minLines) lines = minLines;
        }

        final h = lines * lineHeight;
        return CustomPaint(
          size: Size(effectiveW, h),
          painter: _InjuryLinePainter(lines: lines, lineHeight: lineHeight),
          child: Container(
            width: effectiveW,
            height: h,
            padding: const EdgeInsets.only(left: 2, right: 2),
            child: trimmed.isEmpty
                ? const SizedBox()
                : Text(
                    trimmed,
                    textAlign: textAlign,
                    style: style.copyWith(
                      height: lineHeight / (style.fontSize ?? 10.5),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

Widget _buildPgWidget(Map<String, dynamic> doc) {
  String v(String key) => doc[key]?.toString().trim() ?? '';

  Widget underlineField(
    String text, {
    double? width,
    double minWidth = 40,
    TextAlign textAlign = TextAlign.start,
  }) {
    return _DynamicInjuryUnderlineField(
      text: text,
      style: FormImagePdfHelper.valStyle(10.5),
      width: width,
      minWidth: minWidth,
      textAlign: textAlign,
      lineHeight: 22.0,
      minLines: 1,
    );
  }

  Widget staticText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: FormImagePdfHelper.mReg(10.5),
      ),
    );
  }

  final rawInjuries = doc['injuries'];
  final List<Map<String, String>> injuryList = [];
  if (rawInjuries is List && rawInjuries.isNotEmpty) {
    for (final item in rawInjuries) {
      if (item is Map) {
        injuryList.add({
          'typeOfInjury': item['typeOfInjury']?.toString() ?? '',
          'siteOnBody': item['siteOnBody']?.toString() ?? '',
          'ageOfInjury': item['ageOfInjury']?.toString() ?? '',
          'size': item['size']?.toString() ?? '',
          'color': item['color']?.toString() ?? '',
          'probableWeapon': item['probableWeapon']?.toString() ?? '',
          'simpleGrievous': item['simpleGrievous']?.toString() ?? '',
          'remark': item['remark']?.toString() ?? '',
        });
      }
    }
  }
  while (injuryList.length < 6) {
    injuryList.add({
      'typeOfInjury': '',
      'siteOnBody': '',
      'ageOfInjury': '',
      'size': '',
      'color': '',
      'probableWeapon': '',
      'simpleGrievous': '',
      'remark': '',
    });
  }

  Widget headerCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: FormImagePdfHelper.mBld(9.5),
      ),
    );
  }

  Widget dataCell(String text) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: FormImagePdfHelper.valStyle(9.5),
      ),
    );
  }

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 34),
    children: [
      Center(
        child: Text(
          'INJURY CERTIFICATE',
          style: FormImagePdfHelper.mBld(17).copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Top Right MLC / Date
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('MLC No.:- ', style: FormImagePdfHelper.mBld(11.5)),
                  const SizedBox(width: 4),
                  Expanded(child: underlineField(v('mlcNo'), minWidth: 100)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Date. ', style: FormImagePdfHelper.mBld(11.5)),
                  const SizedBox(width: 4),
                  Expanded(child: underlineField(v('mlcDate'), minWidth: 100)),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),

      // Certificate Body Paragraph
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (v('patientName').length > 25) ...[
            staticText('Certified that shri/smt :'),
            const SizedBox(height: 2),
            underlineField(v('patientName')),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                staticText('age  '),
                underlineField(v('patientAge'),
                    width: 55, minWidth: 40, textAlign: TextAlign.center),
                staticText('  about years'),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                staticText('Certified that shri/smt  '),
                Expanded(
                  child: underlineField(v('patientName'), minWidth: 120),
                ),
                staticText('  age  '),
                underlineField(v('patientAge'),
                    width: 55, minWidth: 40, textAlign: TextAlign.center),
                staticText('  about years'),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (v('idMarkAndAddress').length > 20) ...[
            staticText('bearing following identification mark R/O. :'),
            const SizedBox(height: 2),
            underlineField(v('idMarkAndAddress')),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                staticText('tah  '),
                underlineField(v('tah'),
                    width: 100, minWidth: 60, textAlign: TextAlign.center),
                const SizedBox(width: 12),
                staticText('dist.  '),
                underlineField(v('dist'),
                    width: 120, minWidth: 70, textAlign: TextAlign.center),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                staticText('bearing following identification mark R/O.  '),
                Expanded(
                  child: underlineField(v('idMarkAndAddress'), minWidth: 120),
                ),
                staticText('  tah  '),
                underlineField(v('tah'),
                    width: 80, minWidth: 60, textAlign: TextAlign.center),
                staticText('  dist.  '),
                underlineField(v('dist'),
                    width: 100, minWidth: 70, textAlign: TextAlign.center),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (v('broughtBy').length > 20 || v('policeStation').length > 15) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                staticText('brought to this hospital by PC/HC.  '),
                Expanded(
                  child: underlineField(v('broughtBy'), minWidth: 100),
                ),
                staticText('  B.No.  '),
                underlineField(v('buckleNo'),
                    width: 65, minWidth: 45, textAlign: TextAlign.center),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                staticText('Police station.  '),
                Expanded(
                  child: underlineField(v('policeStation'), minWidth: 120),
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                staticText('brought to this hospital by PC/HC.  '),
                Expanded(
                  flex: 3,
                  child: underlineField(v('broughtBy'), minWidth: 100),
                ),
                staticText('  B.No.  '),
                underlineField(v('buckleNo'),
                    width: 65, minWidth: 45, textAlign: TextAlign.center),
                staticText('  Police station.  '),
                Expanded(
                  flex: 3,
                  child: underlineField(v('policeStation'), minWidth: 100),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              staticText('at  '),
              underlineField(v('broughtTime'),
                  width: 65, minWidth: 50, textAlign: TextAlign.center),
              staticText('  AM/PM on  '),
              underlineField(v('broughtDate'),
                  width: 105, minWidth: 80, textAlign: TextAlign.center),
              staticText('  & examination by me on  '),
              underlineField(v('examDate'),
                  width: 105, minWidth: 80, textAlign: TextAlign.center),
              staticText('  at  '),
              underlineField(v('examTime'),
                  width: 65, minWidth: 50, textAlign: TextAlign.center),
              staticText('  AM/PM'),
            ],
          ),
        ],
      ),
      const SizedBox(height: 18),

      // 9-Column Table
      Table(
        border: TableBorder.all(color: Colors.black, width: 0.8),
        columnWidths: const {
          0: FixedColumnWidth(30),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2.2),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(2),
          7: FlexColumnWidth(1.6),
          8: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
            children: [
              headerCell('Sr\nno'),
              headerCell('Type of\ninjury'),
              headerCell('Site on\nbody'),
              headerCell('Age of\ninjury'),
              headerCell('Size'),
              headerCell('Color'),
              headerCell('Probable\nweapon'),
              headerCell('Simple/\nGrievous'),
              headerCell('Remark'),
            ],
          ),
          for (int i = 0; i < injuryList.length; i++)
            TableRow(
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('${i + 1}', style: FormImagePdfHelper.mBld(9.5)),
                ),
                dataCell(injuryList[i]['typeOfInjury'] ?? ''),
                dataCell(injuryList[i]['siteOnBody'] ?? ''),
                dataCell(injuryList[i]['ageOfInjury'] ?? ''),
                dataCell(injuryList[i]['size'] ?? ''),
                dataCell(injuryList[i]['color'] ?? ''),
                dataCell(injuryList[i]['probableWeapon'] ?? ''),
                dataCell(injuryList[i]['simpleGrievous'] ?? ''),
                dataCell(injuryList[i]['remark'] ?? ''),
              ],
            ),
        ],
      ),
      const SizedBox(height: 36),

      // Footer Section
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Text('Date:- ', style: FormImagePdfHelper.mBld(11.5)),
                const SizedBox(width: 4),
                Expanded(child: underlineField(v('footerDate'), minWidth: 80)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text('Place:- ', style: FormImagePdfHelper.mBld(11.5)),
                const SizedBox(width: 4),
                Expanded(child: underlineField(v('footerPlace'), minWidth: 80)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medical officer', style: FormImagePdfHelper.mBld(11.5)),
                Text('Name and Sign', style: FormImagePdfHelper.mBld(11.5)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: underlineField(v('moName'), minWidth: 100),
                ),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),

      // Footer
      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: FormImagePdfHelper.mReg(9).copyWith(color: Colors.black54),
        ),
      ),
    ],
  );
}
