import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';

Future<void> previewMuddemalPavtiPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Muddemal_Pavti_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPgWidget(doc)],
    fallbackPdfGenerator: () => generateMuddemalPavtiPdf(doc),
  );
}

Future<Uint8List> generateMuddemalPavtiPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 10.5,
    lineSpacing: 4,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 15,
    fontWeight: pw.FontWeight.bold,
    decoration: pw.TextDecoration.underline,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final ps = v('policeStation');
  final dist = v('district');
  final crimeNo = v('crimeNo', v('crNoYear', v('crNo', '........../२०......')));
  final actSec = v('actSec',
      v('section', '________________________________________________'));
  final ioName = v('ioName', v('investigatingOfficer'));
  final ioPs = v('ioPs', v('ioPoliceStation', ps));
  final ioDist = v('ioDist', v('ioDistrict'));
  final accusedName = v('accusedName',
      '____________________________________________________________________');
  final seizureDate = v('seizureDate', v('seizedDate', v('date')));
  final propertyNo = v('propertyNo', v('malNumber', v('receiptNo')));

  final rawItems = (doc['items'] is List)
      ? (doc['items'] as List)
      : ((doc['muddemalItems'] is List) ? (doc['muddemalItems'] as List) : []);

  final items = <Map<String, dynamic>>[];
  if (rawItems.isNotEmpty) {
    for (final item in rawItems) {
      if (item is Map) {
        items.add({
          'description': item['description']?.toString() ?? '',
          'estimatedValue': item['estimatedValue']?.toString() ?? '',
          'propertyNo':
              (item['propertyNo'] ?? item['malNumber'])?.toString() ?? '',
          'seizedFrom': item['seizedFrom']?.toString() ?? '',
        });
      }
    }
  } else if ((doc['propertyDescription']?.toString() ?? '').isNotEmpty ||
      (doc['propertyValue']?.toString() ?? '').isNotEmpty) {
    items.add({
      'description': doc['propertyDescription']?.toString() ?? '',
      'estimatedValue': doc['propertyValue']?.toString() ?? '',
      'propertyNo': propertyNo,
      'seizedFrom': doc['seizedFrom']?.toString() ?? '',
    });
  }

  final headMohararSig =
      v('headMohararSig', v('headMoharirSign', v('receiverName')));
  final investigatingOfficerSig =
      v('investigatingOfficerSig', v('ioSign', v('ioName')));

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── TITLE ──
            pw.Center(
              child: pw.Text('-:: मुद्देमाल पावती ::-', style: headerTitle),
            ),
            pw.SizedBox(height: 24),

            // ── ROW 1: पोलीस स्टेशन ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1.0),
                  child: pw.Text('१) पोलीस स्टेशन   :-  ', style: bold),
                ),
                pw.Expanded(
                  child: pw.Text(
                    ps.isEmpty ? ' ' : ps,
                    style: regular,
                    softWrap: true,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1.0),
                  child: pw.Text('जिल्हा $dist', style: bold),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── ROW 2: अप क्रमांक व कलम ──
            pw.Row(
              children: [
                pw.Text('२) अप क्रमांक :- ', style: bold),
                pw.Text(crimeNo, style: regular),
                pw.SizedBox(width: 16),
                pw.Text('कलम ', style: bold),
                pw.Expanded(
                  child: pw.Text(actSec, style: regular),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── ROW 3: अन्वेषन अधिकारी ──
            if (ioName.trim().length > 20 || (ioName.trim().length + ioPs.trim().length > 35)) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('३) अन्वेषन अधिकारी:- ', style: bold),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom:
                              pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        ioName.isNotEmpty ? ioName : ' ',
                        style: regular,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('पोलीस स्टेशन :- ', style: bold),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom:
                              pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        ioPs.isEmpty ? ' ' : ioPs,
                        style: regular,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('जिल्हा :- ', style: bold),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom:
                              pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        ioDist.isEmpty ? ' ' : ioDist,
                        style: regular,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('३) अन्वेषन अधिकारी:- ', style: bold),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom:
                              pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        ioName.isNotEmpty ? ioName : ' ',
                        style: regular,
                        softWrap: true,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('पोलीस स्टेशन ', style: bold),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom:
                              pw.BorderSide(color: PdfColors.black, width: 0.8),
                        ),
                      ),
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        ioPs.isEmpty ? ' ' : ioPs,
                        style: regular,
                        softWrap: true,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('जिल्हा $ioDist', style: bold),
                  ),
                ],
              ),
            ],
            pw.SizedBox(height: 12),

            // ── ROW 4: आरोपी नांव ──
            pw.Row(
              children: [
                pw.Text('४) आरोपी नांव :- ', style: bold),
                pw.Expanded(
                  child: pw.Text(accusedName, style: regular),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── ROW 5: जप्त माल दिनांक व माल नंबर ──
            pw.Row(
              children: [
                pw.Text('५) जप्त माल दिनांक :- ', style: bold),
                pw.Text(seizureDate, style: regular),
                pw.SizedBox(width: 32),
                pw.Text('माल नंबर :- ', style: bold),
                pw.Text(propertyNo, style: regular),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── MAIN TABLE ──
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(3),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('जप्त मालाचे विवरण', style: bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('मुल्य अंदाजे', style: bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('माल नंबर', style: bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('कोणाकडुन जप्त केले', style: bold),
                    ),
                  ],
                ),

                // Property Rows
                if (items.isEmpty)
                  pw.TableRow(
                    children: [
                      pw.Container(
                        height: 240,
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('', style: regular),
                      ),
                      pw.Container(
                        height: 240,
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('', style: regular),
                      ),
                      pw.Container(
                        height: 240,
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.topCenter,
                        child: pw.Text('......./२०....', style: regular),
                      ),
                      pw.Container(
                        height: 240,
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('', style: regular),
                      ),
                    ],
                  )
                else
                  for (final item in items)
                    pw.TableRow(
                      children: [
                        pw.Container(
                          constraints: const pw.BoxConstraints(minHeight: 180),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item['description']?.toString() ?? '',
                            style: regular,
                          ),
                        ),
                        pw.Container(
                          constraints: const pw.BoxConstraints(minHeight: 180),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item['estimatedValue']?.toString() ?? '',
                            style: regular,
                          ),
                        ),
                        pw.Container(
                          constraints: const pw.BoxConstraints(minHeight: 180),
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text(
                            (item['propertyNo']?.toString().isNotEmpty ?? false)
                                ? item['propertyNo'].toString()
                                : '......./२०....',
                            style: regular,
                          ),
                        ),
                        pw.Container(
                          constraints: const pw.BoxConstraints(minHeight: 180),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item['seizedFrom']?.toString() ?? '',
                            style: regular,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
            pw.Spacer(),

            // ── SIGNATURES ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('हेडमोहरर सही', style: bold),
                    if (headMohararSig.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(headMohararSig, style: regular),
                    ],
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('तपास अधिकारी', style: bold),
                    if (investigatingOfficerSig.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(investigatingOfficerSig, style: regular),
                    ],
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── MRW FOOTER ──
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text(
                'M.R.W',
                style: pw.TextStyle(
                  font: devanagari,
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

class _MuddemalUnderlinePainter extends CustomPainter {
  final List<ui.LineMetrics> metrics;
  final Color color;
  final double thickness;

  _MuddemalUnderlinePainter({
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
        final y = (lineBottom + 1.0).clamp(1.0, size.height - 0.5);
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
  bool shouldRepaint(covariant _MuddemalUnderlinePainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDER (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

Widget _buildPgWidget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final ps = v('policeStation');
  final dist = v('district');
  final crimeNo = v('crimeNo', v('crNoYear', v('crNo', '........../२०......')));
  final actSec = v('actSec',
      v('section', '________________________________________________'));
  final ioName = v('ioName', v('investigatingOfficer'));
  final ioPs = v('ioPs', v('ioPoliceStation', ps));
  final ioDist = v('ioDist', v('ioDistrict'));
  final accusedName = v('accusedName',
      '____________________________________________________________________');
  final seizureDate = v('seizureDate', v('seizedDate', v('date')));
  final propertyNo = v('propertyNo', v('malNumber', v('receiptNo')));

  final rawItems = (doc['items'] is List)
      ? (doc['items'] as List)
      : ((doc['muddemalItems'] is List) ? (doc['muddemalItems'] as List) : []);

  final items = <Map<String, dynamic>>[];
  if (rawItems.isNotEmpty) {
    for (final item in rawItems) {
      if (item is Map) {
        items.add({
          'description': item['description']?.toString() ?? '',
          'estimatedValue': item['estimatedValue']?.toString() ?? '',
          'propertyNo':
              (item['propertyNo'] ?? item['malNumber'])?.toString() ?? '',
          'seizedFrom': item['seizedFrom']?.toString() ?? '',
        });
      }
    }
  } else if ((doc['propertyDescription']?.toString() ?? '').isNotEmpty ||
      (doc['propertyValue']?.toString() ?? '').isNotEmpty) {
    items.add({
      'description': doc['propertyDescription']?.toString() ?? '',
      'estimatedValue': doc['propertyValue']?.toString() ?? '',
      'propertyNo': propertyNo,
      'seizedFrom': doc['seizedFrom']?.toString() ?? '',
    });
  }

  final headMohararSig =
      v('headMohararSig', v('headMoharirSign', v('receiverName')));
  final investigatingOfficerSig =
      v('investigatingOfficerSig', v('ioSign', v('ioName')));

  final reg = FormImagePdfHelper.mReg(10.5, 1.45);
  final bld = FormImagePdfHelper.mBld(10.5, 1.45);
  final headerTitle = FormImagePdfHelper.mBld(15, 1.3);

  Widget uUnderlineField(String value, TextStyle style, {double minWidth = 40}) {
    final valText = value.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : minWidth;
        final textMaxWidth = (w - 4.0).clamp(10.0, w);
        final tp = TextPainter(
          text: TextSpan(
            text: valText.isEmpty ? ' ' : valText,
            style: style,
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: textMaxWidth);
        final metrics = tp.computeLineMetrics();
        return SizedBox(
          width: w,
          child: CustomPaint(
            painter: _MuddemalUnderlinePainter(
              metrics: metrics,
              color: Colors.black87,
              thickness: 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
              child: Text(
                valText.isEmpty ? ' ' : valText,
                softWrap: true,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }

  final isIoNameLong = () {
    final name = ioName.trim();
    if (name.length > 20) return true;
    final tp = TextPainter(
      text: TextSpan(text: name, style: reg),
      textDirection: TextDirection.ltr,
    )..layout();
    if (tp.width > 180) return true;
    final tpPs = TextPainter(
      text: TextSpan(text: ioPs.trim(), style: reg),
      textDirection: TextDirection.ltr,
    )..layout();
    if (tp.width + tpPs.width > 320) return true;
    return false;
  }();

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
    children: [
      Center(
        child: Text(
          '-:: मुद्देमाल पावती ::-',
          style: headerTitle.copyWith(decoration: TextDecoration.underline),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('१) पोलीस स्टेशन   :-  ', style: bld),
          ),
          Expanded(
            child: Text(
              ps.isEmpty ? ' ' : ps,
              softWrap: true,
              style: reg,
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('जिल्हा $dist', style: bld),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('२) अप क्रमांक :- ', style: bld),
          ),
          Text(
            crimeNo.isNotEmpty ? crimeNo : '________/२०____',
            style: reg,
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('कलम ', style: bld),
          ),
          Expanded(
            child: Text(
              actSec.isNotEmpty
                  ? actSec
                  : '____________________________________',
              softWrap: true,
              style: reg,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // ── ROW 3: अन्वेषन अधिकारी ──
      if (isIoNameLong) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('३) अन्वेषन अधिकारी:- ', style: bld),
            ),
            Expanded(
              child: uUnderlineField(ioName, reg),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('पोलीस स्टेशन :- ', style: bld),
            ),
            Expanded(
              child: uUnderlineField(ioPs, reg),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('जिल्हा :- ', style: bld),
            ),
            Expanded(
              child: uUnderlineField(ioDist, reg),
            ),
          ],
        ),
      ] else ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('३) अन्वेषन अधिकारी:- ', style: bld),
            ),
            Expanded(
              flex: 4,
              child: uUnderlineField(ioName, reg),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('पोलीस स्टेशन ', style: bld),
            ),
            Expanded(
              flex: 3,
              child: uUnderlineField(ioPs, reg),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('जिल्हा $ioDist', style: bld),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('४) आरोपी नांव :- ', style: bld),
          ),
          Expanded(
            child: Text(
              accusedName.isNotEmpty
                  ? accusedName
                  : '________________________________________________',
              softWrap: true,
              style: reg,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('५) जप्त माल दिनांक :- ', style: bld),
          ),
          Text(
            seizureDate.isNotEmpty ? seizureDate : '________________',
            style: reg,
          ),
          const SizedBox(width: 32),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('माल नंबर :- ', style: bld),
          ),
          Expanded(
            child: Text(
              propertyNo.isNotEmpty ? propertyNo : '________________',
              softWrap: true,
              style: reg,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Table(
        border: TableBorder.all(color: Colors.black87, width: 1),
        columnWidths: const {
          0: FlexColumnWidth(4),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.black87, width: 1)),
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                alignment: Alignment.center,
                child: Text('जप्त मालाचे विवरण', style: bld),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                alignment: Alignment.center,
                child: Text('मुल्य अंदाजे', style: bld),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                alignment: Alignment.center,
                child: Text('माल नंबर', style: bld),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                alignment: Alignment.center,
                child: Text('कोणाकडुन जप्त केले', style: bld),
              ),
            ],
          ),
          if (items.isEmpty)
            TableRow(
              children: [
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(6),
                  child: Text('', style: reg),
                ),
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(6),
                  child: Text('', style: reg),
                ),
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(6),
                  alignment: Alignment.topCenter,
                  child: Text('......./२०....', style: reg),
                ),
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(6),
                  child: Text('', style: reg),
                ),
              ],
            )
          else
            for (final item in items)
              TableRow(
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 180),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      item['description']?.toString() ?? '',
                      style: reg,
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 180),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      item['estimatedValue']?.toString() ?? '',
                      style: reg,
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 180),
                    padding: const EdgeInsets.all(6),
                    alignment: Alignment.topCenter,
                    child: Text(
                      (item['propertyNo']?.toString().isNotEmpty ?? false)
                          ? item['propertyNo'].toString()
                          : '......./२०....',
                      style: reg,
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 180),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      item['seizedFrom']?.toString() ?? '',
                      style: reg,
                    ),
                  ),
                ],
              ),
        ],
      ),
      const Spacer(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text('हेडमोहरर सही', style: bld),
              if (headMohararSig.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(headMohararSig, style: reg),
              ],
            ],
          ),
          Column(
            children: [
              Text('तपास अधिकारी', style: bld),
              if (investigatingOfficerSig.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(investigatingOfficerSig, style: reg),
              ],
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: reg.copyWith(fontSize: 8, color: Colors.grey.shade700),
        ),
      ),
    ],
  );
}
