import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'form_image_pdf_helper.dart';
import 'marathi_text_renderer.dart';
import 'pdf_font_cache.dart';

Future<void> previewWitnessNoticePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Witness_Notice_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPgWidget(doc)],
    fallbackPdfGenerator: () => generateWitnessNoticePdf(doc),
  );
}

Future<Uint8List> generateWitnessNoticePdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraBold = await PdfFontCache.loraBold();
  final cache = await _preRenderAllMarathi(doc);

  final pw.TextStyle englishValueStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 9.5,
    color: PdfColors.black,
  );

  pw.Widget renderField(String key, String? val) {
    final text = val?.trim() ?? '';
    if (text.isEmpty) {
      return pw.SizedBox();
    }
    if (cache.has(key)) {
      return cache.img(key);
    }
    return pw.Text(text, style: englishValueStyle);
  }

  pw.Widget mLbl(String key) {
    if (cache.has(key)) return cache.img(key);
    return pw.SizedBox();
  }

  final psName = doc['policeStation']?.toString() ?? '';
  final bodyPs = (doc['bodyPoliceStation']?.toString() ?? '').isNotEmpty
      ? doc['bodyPoliceStation']?.toString()
      : psName;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Right: Police Station & Date
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 220,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 1.0),
                          child: mLbl('lbl_top_ps'),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                    color: PdfColors.black, width: 0.8),
                              ),
                            ),
                            padding:
                                const pw.EdgeInsets.only(bottom: 2, left: 4),
                            child: renderField('val_policeStation', psName),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        mLbl('lbl_top_date'),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                    color: PdfColors.black, width: 0.8),
                              ),
                            ),
                            padding:
                                const pw.EdgeInsets.only(bottom: 2, left: 4),
                            child: renderField(
                              'val_noticeDate',
                              doc['noticeDate']?.toString() ??
                                  doc['date']?.toString(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 24),

            // Centered Title
            pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  mLbl('title'),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    width: 150,
                    height: 1,
                    color: PdfColors.black,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Panch / Witness Details
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('lbl_panch_name'),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom:
                            pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                    child: renderField(
                      'val_panchName',
                      doc['panchName']?.toString() ??
                          doc['witnessName']?.toString() ??
                          doc['witnessNameAddress']?.toString(),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Address Line 1
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
              child: renderField(
                'val_panchAddressLine1',
                doc['panchAddressLine1']?.toString() ??
                    doc['address']?.toString(),
              ),
            ),
            pw.SizedBox(height: 8),

            // Address Line 2
            if ((doc['panchAddressLine2']?.toString() ?? '')
                .trim()
                .isNotEmpty) ...[
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  ),
                ),
                padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                child: renderField('val_panchAddressLine2',
                    doc['panchAddressLine2']?.toString()),
              ),
              pw.SizedBox(height: 8),
            ],

            // Address Line 3
            if ((doc['panchAddressLine3']?.toString() ?? '')
                .trim()
                .isNotEmpty) ...[
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  ),
                ),
                padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                child: renderField('val_panchAddressLine3',
                    doc['panchAddressLine3']?.toString()),
              ),
              pw.SizedBox(height: 8),
            ],

            // Centered Symbol "००००"
            pw.Center(
              child: mLbl('symbol_dots'),
            ),
            pw.SizedBox(height: 16),

            // Notice Body Lines
            // Line 1: आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन [PS] येथे अपराध
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1.0),
                  child: mLbl('body_p1_1'),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom:
                            pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                    child: renderField('val_bodyPoliceStation', bodyPs),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1.0),
                  child: mLbl('body_p1_2'),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Line 2: क्रमांक [CR] कलम [Section]
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('body_p2_cr'),
                pw.SizedBox(width: 4),
                pw.Container(
                  width: 100,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                    'val_crNoYear',
                    doc['crNoYear']?.toString() ?? doc['crNo']?.toString(),
                  ),
                ),
                pw.SizedBox(width: 6),
                mLbl('body_p2_sec'),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom:
                            pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                    child:
                        renderField('val_section', doc['section']?.toString()),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Line 3: अन्वये गुन्हा नोंद असुन सदर गुन्ह्याचे तपासकामी आपणाकडे चौकशी करून आपला जबाब
            mLbl('body_p3'),
            pw.SizedBox(height: 8),

            // Line 4: नोंदविणे आवश्यक असल्याने, आपण दिनांक:[date] रोजी [time] वाजता
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('body_p4_1'),
                pw.SizedBox(width: 4),
                pw.Container(
                  width: 110,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                      'val_appearanceDate', doc['appearanceDate']?.toString()),
                ),
                pw.SizedBox(width: 4),
                mLbl('body_p4_2'),
                pw.SizedBox(width: 4),
                pw.Container(
                  width: 80,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                      'val_appearanceTime', doc['appearanceTime']?.toString()),
                ),
                pw.SizedBox(width: 4),
                mLbl('body_p4_3'),
              ],
            ),
            pw.SizedBox(height: 8),

            // Line 5: आमचे समक्ष न चुकता हजर राहावे.
            mLbl('body_p5'),
            pw.SizedBox(height: 14),

            // Line 6: करीता सुचनापत्र देण्यात येत आहे.
            mLbl('body_p6'),
            pw.SizedBox(height: 36),

            // IO Signature
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 180,
                    alignment: pw.Alignment.center,
                    child: renderField(
                      'val_ioSign',
                      doc['ioSign']?.toString() ?? doc['ioName']?.toString(),
                    ),
                  ),
                  pw.Container(
                    width: 180,
                    height: 0.8,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.only(top: 2, bottom: 6),
                  ),
                  mLbl('sig_io'),
                ],
              ),
            ),
            pw.SizedBox(height: 40),

            // Acknowledgement Section
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                mLbl('ack_header'),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 190,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                    'val_ackLine1',
                    doc['ackLine1']?.toString() ??
                        doc['witnessSig']?.toString(),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 190,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                    'val_ackLine2',
                    doc['ackLine2']?.toString() ??
                        doc['witnessReceiptDate']?.toString(),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 190,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child:
                      renderField('val_ackLine3', doc['ackLine3']?.toString()),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 190,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child:
                      renderField('val_ackLine4', doc['ackLine4']?.toString()),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text(
                'M.R.W',
                style: pw.TextStyle(
                  font: loraBold,
                  fontSize: 8.5,
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

Future<MarathiImageCache> _preRenderAllMarathi(Map<String, dynamic> doc) async {
  final pairs = <String, String>{
    'title': '—:: साक्षीदार सुचनापत्र ::—',
    'lbl_top_ps': 'पोलीस स्टेशन',
    'lbl_top_date': 'दिनांक :',
    'lbl_panch_name': 'पंच नांव :—',
    'symbol_dots': '० ० ० ०',
    'body_p1_1': 'आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन',
    'body_p1_2': 'येथे अपराध',
    'body_p2_cr': 'क्रमांक',
    'body_p2_sec': 'कलम',
    'body_p3':
        'अन्वये गुन्हा नोंद असुन सदर गुन्ह्याचे तपासकामी आपणाकडे चौकशी करून आपला जबाब',
    'body_p4_1': 'नोंदविणे आवश्यक असल्याने, आपण दिनांक :',
    'body_p4_2': 'रोजी',
    'body_p4_3': 'वाजता',
    'body_p5': 'आमचे समक्ष न चुकता हजर राहावे.',
    'body_p6': 'करीता सुचनापत्र देण्यात येत आहे.',
    'sig_io': 'तपासी अधिकारी नांव व सही',
    'ack_header': 'सुचनापत्र मिळाले आहे.',
  };

  void addIfDevanagari(String k, dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isNotEmpty && containsDevanagari(s)) {
      pairs[k] = s;
    }
  }

  // Values
  addIfDevanagari('val_policeStation', doc['policeStation']);
  addIfDevanagari('val_noticeDate', doc['noticeDate'] ?? doc['date']);
  addIfDevanagari('val_panchName',
      doc['panchName'] ?? doc['witnessName'] ?? doc['witnessNameAddress']);
  addIfDevanagari(
      'val_panchAddressLine1', doc['panchAddressLine1'] ?? doc['address']);
  addIfDevanagari('val_panchAddressLine2', doc['panchAddressLine2']);
  addIfDevanagari('val_panchAddressLine3', doc['panchAddressLine3']);
  addIfDevanagari('val_bodyPoliceStation',
      doc['bodyPoliceStation'] ?? doc['policeStation']);
  addIfDevanagari('val_crNoYear', doc['crNoYear'] ?? doc['crNo']);
  addIfDevanagari('val_section', doc['section']);
  addIfDevanagari('val_appearanceDate', doc['appearanceDate']);
  addIfDevanagari('val_appearanceTime', doc['appearanceTime']);
  addIfDevanagari('val_ioSign', doc['ioSign'] ?? doc['ioName']);
  addIfDevanagari('val_ackLine1', doc['ackLine1'] ?? doc['witnessSig']);
  addIfDevanagari('val_ackLine2', doc['ackLine2'] ?? doc['witnessReceiptDate']);
  addIfDevanagari('val_ackLine3', doc['ackLine3']);
  addIfDevanagari('val_ackLine4', doc['ackLine4']);

  final boldKeys = {
    'title',
    'lbl_top_ps',
    'lbl_top_date',
    'lbl_panch_name',
    'symbol_dots',
    'sig_io',
    'ack_header',
  };

  final cache = MarathiImageCache();
  await GoogleFonts.pendingFonts();

  for (final entry in pairs.entries) {
    final isBold = boldKeys.contains(entry.key);
    final double fs = entry.key == 'title'
        ? 14.0
        : (entry.key == 'symbol_dots'
            ? 12.0
            : (entry.key == 'ack_header' || entry.key == 'sig_io'
                ? 10.5
                : 9.5));

    const color = Colors.black;

    final double maxW = entry.key == 'title' || entry.key == 'body_p3'
        ? 500
        : (entry.key.startsWith('val_panchAddress') ? 480 : 350);

    await cache.add(
      entry.key,
      entry.value,
      GoogleFonts.notoSansDevanagari(
        fontSize: fs,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color,
      ),
      maxWidth: maxW,
    );
  }

  return cache;
}

class _WitnessLinePainter extends CustomPainter {
  final int lines;
  final double lineHeight;

  const _WitnessLinePainter({
    required this.lines,
    required this.lineHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= lines; i++) {
      final y = (i * lineHeight) - 1.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WitnessLinePainter oldDelegate) =>
      oldDelegate.lines != lines || oldDelegate.lineHeight != lineHeight;
}

class _DynamicWitnessUnderlineField extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int minLines;
  final double lineHeight;

  const _DynamicWitnessUnderlineField({
    required this.text,
    required this.style,
    this.minLines = 1,
    this.lineHeight = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 500.0;
        int lines = minLines;
        if (trimmed.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(text: trimmed, style: style),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: maxW > 0 ? maxW : 500.0);
          final metrics = tp.computeLineMetrics();
          lines = metrics.isEmpty ? 1 : metrics.length;
          if (lines < minLines) lines = minLines;
        }

        final h = lines * lineHeight;
        return CustomPaint(
          size: Size(maxW, h),
          painter: _WitnessLinePainter(lines: lines, lineHeight: lineHeight),
          child: Container(
            width: maxW,
            height: h,
            padding: const EdgeInsets.only(left: 2, right: 2),
            child: trimmed.isEmpty
                ? const SizedBox()
                : Text(
                    trimmed,
                    style: style.copyWith(
                      height: lineHeight / (style.fontSize ?? 11.5),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

Widget _buildPgWidget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final psName = v('policeStation');
  final bodyPs = v('bodyPoliceStation', psName);
  final noticeDate = v('noticeDate', v('date'));
  final panchName = v('panchName', v('witnessName', v('witnessNameAddress')));
  final addr1 = v('panchAddressLine1', v('address'));
  final addr2 = v('panchAddressLine2');
  final addr3 = v('panchAddressLine3');
  final crNo = v('crNoYear', v('crNo'));
  final section = v('section');
  final appDate = v('appearanceDate');
  final appTime = v('appearanceTime');
  final ioSign = v('ioSign', v('ioName'));
  final ack1 = v('ackLine1', v('witnessSig'));
  final ack2 = v('ackLine2', v('witnessReceiptDate'));
  final ack3 = v('ackLine3');
  final ack4 = v('ackLine4');

  final addrList = [addr1, addr2, addr3].where((s) => s.isNotEmpty).toList();
  final fullAddress = addrList.join(' ');

  final reg = FormImagePdfHelper.mBld(11.5, 1.85);
  final bld = FormImagePdfHelper.mBld(11.5, 1.85);
  final titleStyle = FormImagePdfHelper.mBld(17, 1.3);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 38),
    children: [
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 290,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text('पोलीस स्टेशन', style: bld),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _DynamicWitnessUnderlineField(
                      text: psName,
                      style: FormImagePdfHelper.valStyle(10.5),
                      minLines: 1,
                      lineHeight: 20.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('दिनांक :', style: bld),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _DynamicWitnessUnderlineField(
                      text: noticeDate,
                      style: FormImagePdfHelper.valStyle(10.5),
                      minLines: 1,
                      lineHeight: 20.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Center(
        child: Column(
          children: [
            Text('—:: साक्षीदार सुचनापत्र ::—', style: titleStyle),
            const SizedBox(height: 2),
            Container(width: 190, height: 1, color: Colors.black),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text('पंच नांव :—', style: bld),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _DynamicWitnessUnderlineField(
              text: panchName,
              style: FormImagePdfHelper.valStyle(11.5),
              minLines: 1,
              lineHeight: 22.0,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _DynamicWitnessUnderlineField(
        text: fullAddress,
        style: FormImagePdfHelper.valStyle(11),
        minLines: 1,
        lineHeight: 22.0,
      ),
      const SizedBox(height: 24),
      Center(
        child: Text('० ० ० ०',
            style: bld.copyWith(fontSize: 13, letterSpacing: 4)),
      ),
      const SizedBox(height: 20),
      if (bodyPs.length > 15) ...[
        Text('आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन :', style: reg),
        const SizedBox(height: 4),
        _DynamicWitnessUnderlineField(
          text: bodyPs,
          style: FormImagePdfHelper.valStyle(11.5),
          minLines: 1,
          lineHeight: 22.0,
        ),
        const SizedBox(height: 6),
        Text('येथे अपराध', style: reg),
      ] else ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन',
                  style: reg),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _DynamicWitnessUnderlineField(
                text: bodyPs,
                style: FormImagePdfHelper.valStyle(11.5),
                minLines: 1,
                lineHeight: 22.0,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('येथे अपराध', style: reg),
            ),
          ],
        ),
      ],
      const SizedBox(height: 10),
      if (section.length > 25) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('क्रमांक', style: reg),
            const SizedBox(width: 4),
            SizedBox(
              width: 140,
              child: _DynamicWitnessUnderlineField(
                text: crNo,
                style: FormImagePdfHelper.valStyle(11.5),
                minLines: 1,
                lineHeight: 22.0,
              ),
            ),
            const SizedBox(width: 8),
            Text('कलम :', style: reg),
          ],
        ),
        const SizedBox(height: 4),
        _DynamicWitnessUnderlineField(
          text: section,
          style: FormImagePdfHelper.valStyle(11.5),
          minLines: 1,
          lineHeight: 22.0,
        ),
      ] else ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('क्रमांक', style: reg),
            const SizedBox(width: 4),
            SizedBox(
              width: 120,
              child: _DynamicWitnessUnderlineField(
                text: crNo,
                style: FormImagePdfHelper.valStyle(11.5),
                minLines: 1,
                lineHeight: 22.0,
              ),
            ),
            const SizedBox(width: 6),
            Text('कलम', style: reg),
            const SizedBox(width: 4),
            Expanded(
              child: _DynamicWitnessUnderlineField(
                text: section,
                style: FormImagePdfHelper.valStyle(11.5),
                minLines: 1,
                lineHeight: 22.0,
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 10),
      Text(
        'अन्वये गुन्हा नोंद असुन सदर गुन्ह्याचे तपासकामी आपणाकडे चौकशी करून आपला जबाब',
        style: reg,
      ),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('नोंदविणे आवश्यक असल्याने, आपण दिनांक :', style: reg),
          const SizedBox(width: 4),
          SizedBox(
            width: 120,
            child: _DynamicWitnessUnderlineField(
              text: appDate,
              style: FormImagePdfHelper.valStyle(11.5),
              minLines: 1,
              lineHeight: 22.0,
            ),
          ),
          const SizedBox(width: 4),
          Text('रोजी', style: reg),
          const SizedBox(width: 4),
          SizedBox(
            width: 90,
            child: _DynamicWitnessUnderlineField(
              text: appTime,
              style: FormImagePdfHelper.valStyle(11.5),
              minLines: 1,
              lineHeight: 22.0,
            ),
          ),
          const SizedBox(width: 4),
          Text('वाजता', style: reg),
        ],
      ),
      const SizedBox(height: 10),
      Text('आमचे समक्ष न चुकता हजर राहावे.', style: reg),
      const SizedBox(height: 16),
      Text('करीता सुचनापत्र देण्यात येत आहे.', style: reg),
      const SizedBox(height: 36),
      Align(
        alignment: Alignment.centerRight,
        child: Column(
          children: [
            SizedBox(
              width: 180,
              child: Center(
                child: Text(
                  ioSign.isEmpty ? ' ' : ioSign,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: FormImagePdfHelper.valStyle(11),
                ),
              ),
            ),
            Container(
                width: 180,
                height: 0.8,
                color: Colors.black,
                margin: const EdgeInsets.only(top: 2, bottom: 6)),
            Text('तपासी अधिकारी नांव व सही', style: bld),
          ],
        ),
      ),
      const SizedBox(height: 32),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('सुचनापत्र मिळाले आहे.', style: bld),
          const SizedBox(height: 8),
          SizedBox(
            width: 220,
            child: _DynamicWitnessUnderlineField(
              text: ack1,
              style: FormImagePdfHelper.valStyle(11),
              minLines: 1,
              lineHeight: 22.0,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 220,
            child: _DynamicWitnessUnderlineField(
              text: ack2,
              style: FormImagePdfHelper.valStyle(11),
              minLines: 1,
              lineHeight: 22.0,
            ),
          ),
          if (ack3.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 220,
              child: _DynamicWitnessUnderlineField(
                text: ack3,
                style: FormImagePdfHelper.valStyle(11),
                minLines: 1,
                lineHeight: 22.0,
              ),
            ),
          ],
          if (ack4.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 220,
              child: _DynamicWitnessUnderlineField(
                text: ack4,
                style: FormImagePdfHelper.valStyle(11),
                minLines: 1,
                lineHeight: 22.0,
              ),
            ),
          ],
        ],
      ),
      const Spacer(),
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
