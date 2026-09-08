import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'marathi_text_renderer.dart';

Future<void> previewWitnessNoticePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateWitnessNoticePdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Witness_Notice_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (_) {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}

Future<Uint8List> generateWitnessNoticePdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraBold = await PdfGoogleFonts.loraBold();
  final cache = await _preRenderAllMarathi(doc);

  final pw.TextStyle englishValueStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 9.5,
    color: PdfColors.blue900,
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
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        mLbl('lbl_top_ps'),
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

            // Address Line 3
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
            pw.SizedBox(height: 20),

            // Centered Symbol "००००"
            pw.Center(
              child: mLbl('symbol_dots'),
            ),
            pw.SizedBox(height: 16),

            // Notice Body Lines
            // Line 1: आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन [PS] येथे अपराध
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('body_p1_1'),
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
                mLbl('body_p1_2'),
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

    final color =
        entry.key.startsWith('val_') ? const Color(0xFF0D47A1) : Colors.black87;

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
