import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';

Future<void> previewNoticeToAccusedPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Notice_To_Accused_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPgWidget(doc)],
    fallbackPdfGenerator: () => generateNoticeToAccusedPdf(doc),
  );
}

Future<Uint8List> generateNoticeToAccusedPdf(Map<String, dynamic> doc) async {
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
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
  );
  final headerSub = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  const borderLine = pw.BorderSide(color: PdfColors.black, width: 0.8);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 44),
      build: (pw.Context context) {
        final ps = v('policeStation', '--------');
        final dateStr = v('date', '......./ ......../२०....');

        final accusedLine1 = v('accusedName', v('accusedNameAddress'));
        final accusedLine2 = v('accusedNameLine2');

        final mobileNo = v('mobileNo', '..................................');
        final aadhaarNo = v('aadhaarNo', '..................................');
        final email = v('email',
            '.........................................................................');

        final firPs = v('firPs', '...................');
        final firDist = v('firDist', 'यवतमाळ');
        final crimeNo = v('crimeNumberOnly', v('crimeNo', '............'));
        final crimeYear = v('crimeYear', '२५');
        final actSec = v('actSec', '...................................');
        final coActSec = v('coActSec', '.............................');
        final firDate = v('firDate', '...../...../२०.....');

        final bailType = v('bailType', 'अजमीनपात्र/ जामीनपात्र');
        final relativeDetails = v('relativeDetails',
            '.....................................................................................');

        final accusedSig = v('accusedSig');
        final ioNameSig = v('ioNameSig');

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── TOP RIGHT POLICE STATION & DATE ──
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('पोलीस स्टेशन ', style: bold),
                        pw.Expanded(
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: borderLine),
                            ),
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(ps, style: regular),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text('दिनांक :', style: bold),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: borderLine),
                            ),
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(dateStr, style: regular),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 24),

            // ── HEADER TITLE ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('-:: आरोपीस सुचनापत्र ::-', style: headerTitle),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '(भारतीय नागरी सुरक्षा संहिता २०२३ कलम ४७ (१)(२))',
                    style: headerSub.copyWith(
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 28),

            // ── ACCUSED SECTION ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('नांव :- ', style: bold),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: borderLine),
                        ),
                        child: pw.Text(
                          accusedLine1.isNotEmpty ? accusedLine1 : ' ',
                          style: regular,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: borderLine),
                        ),
                        child: pw.Text(
                          accusedLine2.isNotEmpty ? accusedLine2 : ' ',
                          style: regular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Mobile & Aadhaar
            pw.Row(
              children: [
                pw.Text('मो.नं.:-', style: bold),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: borderLine),
                    ),
                    child: pw.Text(mobileNo, style: regular),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Text('आधार क्र :-', style: bold),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: borderLine),
                    ),
                    child: pw.Text(aadhaarNo, style: regular),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Email
            pw.Row(
              children: [
                pw.Text('ईमेल :-', style: bold),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: borderLine),
                    ),
                    child: pw.Text(email, style: regular),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // ── BODY PARAGRAPH 1 ──
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 6),
                children: [
                  const pw.TextSpan(
                    text:
                        '        आपणास याद्वारे सुचीत करण्यात येते की,आपणा विरूध्द पोलीस स्टेशन ',
                  ),
                  pw.TextSpan(text: '$firPs ', style: bold),
                  pw.TextSpan(text: 'जिल्हा $firDist येथे अपराध क्रमांक'),
                  pw.TextSpan(text: ' $crimeNo / २०$crimeYear ', style: bold),
                  const pw.TextSpan(text: 'कलम '),
                  pw.TextSpan(text: '$actSec ', style: bold),
                  const pw.TextSpan(
                    text: 'भा.न्या.संहिता २०२३ व सह कलम ',
                  ),
                  pw.TextSpan(text: '$coActSec ', style: bold),
                  const pw.TextSpan(text: 'प्रमाणे दिनांक '),
                  pw.TextSpan(text: '$firDate ', style: bold),
                  const pw.TextSpan(
                    text:
                        'गुन्हा दाखल असुन सदर गुन्ह्याचा तपास आम्ही स्वतः करत आहोत. सदर गुन्ह्याच्या तपासकामी आपणास अटक करण्यात येत आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── BODY PARAGRAPH 2 ──
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 6),
                children: [
                  const pw.TextSpan(
                    text: '        सदर गुन्हा दखलपात्र असुन ',
                  ),
                  pw.TextSpan(text: '$bailType ', style: bold),
                  const pw.TextSpan(
                    text:
                        'आहे. आपल्या अटकेबाबतची माहित भारतीय नागरीक सुरक्षा संहिता २०२३ कलम (४८) प्रमाणे आपले नातेवाईक/ मित्र..... ',
                  ),
                  pw.TextSpan(text: '$relativeDetails ', style: bold),
                  const pw.TextSpan(
                    text:
                        'यांना समक्ष/फोनद्वारे देण्यात आली असुन अटक पंचनाम्यावर त्यांची स्वाक्षरी घेण्यात आली आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── BODY PARAGRAPH 3 (Closing Line) ──
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 28),
              child: pw.Text(
                'करीता आपणास सुचनापत्र देण्यात येत आहे.',
                style: regular,
              ),
            ),
            pw.Spacer(),

            // ── SIGNATURES ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  children: [
                    pw.Text('आरोपीची स्वाक्षरी', style: bold),
                    pw.SizedBox(height: 12),
                    if (accusedSig.isNotEmpty)
                      pw.Text(accusedSig, style: regular)
                    else
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: borderLine),
                        ),
                        height: 1,
                      ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('तपासी अधिकारी नांव व सही', style: bold),
                    pw.SizedBox(height: 12),
                    if (ioNameSig.isNotEmpty)
                      pw.Text(ioNameSig, style: regular)
                    else
                      pw.Container(
                        width: 170,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: borderLine),
                        ),
                        height: 1,
                      ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

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

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDER (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

Widget _buildPgWidget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  const borderLine = BorderSide(color: Colors.black87, width: 0.8);

  final ps = v('policeStation');
  final dateStr = v('date');

  final accusedLine1 = v('accusedName', v('accusedNameAddress'));
  final accusedLine2 = v('accusedNameLine2');

  final mobileNo = v('mobileNo');
  final aadhaarNo = v('aadhaarNo');
  final email = v('email');

  final firPs = v('firPs');
  final firDist = v('firDist', 'यवतमाळ');
  final crimeNo = v('crimeNumberOnly', v('crimeNo'));
  final crimeYear = v('crimeYear', '२५');
  final actSec = v('actSec');
  final coActSec = v('coActSec');
  final firDate = v('firDate');

  final bailType = v('bailType', 'अजमीनपात्र/ जामीनपात्र');
  final relativeDetails = v('relativeDetails');

  final accusedSig = v('accusedSig');
  final ioNameSig = v('ioNameSig');

  final reg = FormImagePdfHelper.mReg(10.5, 1.45);
  final bld = FormImagePdfHelper.mBld(10.5, 1.45);
  final headerTitle = FormImagePdfHelper.mBld(16, 1.3);
  final headerSub = FormImagePdfHelper.mBld(11, 1.3);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
    children: [
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('पोलीस स्टेशन ', style: bld),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: borderLine),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ps.isEmpty ? ' ' : ps,
                          maxLines: 1,
                          softWrap: false,
                          style: reg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('दिनांक :', style: bld),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: borderLine),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(dateStr.isEmpty ? ' ' : dateStr, style: reg),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: Column(
          children: [
            Text('-:: आरोपीस सुचनापत्र ::-', style: headerTitle),
              const SizedBox(height: 3),
              Text(
                '(भारतीय नागरी सुरक्षा संहिता २०२३ कलम ४७ (१)(२))',
                style: headerSub.copyWith(decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('नांव :- ', style: bld),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: borderLine),
                    ),
                    child: Text(
                      accusedLine1.isNotEmpty ? accusedLine1 : ' ',
                      style: reg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: borderLine),
                    ),
                    child: Text(
                      accusedLine2.isNotEmpty ? accusedLine2 : ' ',
                      style: reg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('मो.नं.:-', style: bld),
            const SizedBox(width: 4),
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: borderLine),
                ),
                child: Text(mobileNo, style: reg),
              ),
            ),
            const SizedBox(width: 20),
            Text('आधार क्र :-', style: bld),
            const SizedBox(width: 4),
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: borderLine),
                ),
                child: Text(aadhaarNo, style: reg),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('ईमेल :-', style: bld),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: borderLine),
                ),
                child: Text(email, style: reg),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: reg.copyWith(height: 1.6),
            children: [
              const TextSpan(
                text:
                    '        आपणास याद्वारे सुचीत करण्यात येते की,आपणा विरूध्द पोलीस स्टेशन ',
              ),
              TextSpan(text: '$firPs ', style: bld),
              TextSpan(text: 'जिल्हा $firDist येथे अपराध क्रमांक'),
              TextSpan(text: ' $crimeNo / २०$crimeYear ', style: bld),
              const TextSpan(text: 'कलम '),
              TextSpan(text: '$actSec ', style: bld),
              const TextSpan(
                text: 'भा.न्या.संहिता २०२३ व सह कलम ',
              ),
              TextSpan(text: '$coActSec ', style: bld),
              const TextSpan(text: 'प्रमाणे दिनांक '),
              TextSpan(text: '$firDate ', style: bld),
              const TextSpan(
                text:
                    'गुन्हा दाखल असुन सदर गुन्ह्याचा तपास आम्ही स्वतः करत आहोत. सदर गुन्ह्याच्या तपासकामी आपणास अटक करण्यात येत आहे.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: reg.copyWith(height: 1.6),
            children: [
              const TextSpan(
                text: '        सदर गुन्हा दखलपात्र असुन ',
              ),
              TextSpan(text: '$bailType ', style: bld),
              const TextSpan(
                text:
                    'आहे. आपल्या अटकेबाबतची माहित भारतीय नागरीक सुरक्षा संहिता २०२३ कलम (४८) प्रमाणे आपले नातेवाईक/ मित्र..... ',
              ),
              TextSpan(text: '$relativeDetails ', style: bld),
              const TextSpan(
                text:
                    'यांना समक्ष/फोनद्वारे देण्यात आली असुन अटक पंचनाम्यावर त्यांची स्वाक्षरी घेण्यात आली आहे.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            'करीता आपणास सुचनापत्र देण्यात येत आहे.',
            style: reg,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text('आरोपीची स्वाक्षरी', style: bld),
                const SizedBox(height: 12),
                if (accusedSig.isNotEmpty)
                  Text(accusedSig, style: reg)
                else
                  Container(
                    width: 150,
                    decoration: const BoxDecoration(
                      border: Border(bottom: borderLine),
                    ),
                    height: 1,
                  ),
              ],
            ),
            Column(
              children: [
                Text('तपासी अधिकारी नांव व सही', style: bld),
                const SizedBox(height: 12),
                if (ioNameSig.isNotEmpty)
                  Text(ioNameSig, style: reg)
                else
                  Container(
                    width: 170,
                    decoration: const BoxDecoration(
                      border: Border(bottom: borderLine),
                    ),
                    height: 1,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
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
