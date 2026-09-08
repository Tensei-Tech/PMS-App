import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewNoticeToAccusedPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateNoticeToAccusedPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Notice_To_Accused_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateNoticeToAccusedPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 11,
    lineSpacing: 5,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 15,
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

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      build: (pw.Context context) {
        final ps = v('policeStation', '--------');
        final dateStr = v('date', '......./ ......../२०...');

        final accusedNameAddress = v('accusedNameAddress');
        final mobileNo = v('mobileNo', '..................................');
        final aadhaarNo = v('aadhaarNo', '..................................');
        final email = v('email', '.........................................................................');

        final firPs = v('firPs', '...................');
        final crimeNo = v('crimeNo', '............');
        final actSec = v('actSec', '...................................');
        final coActSec = v('coActSec', '.............................');
        final firDate = v('firDate', '...../...../२०.....');

        final bailType = v('bailType', 'अजमीनपात्र/ जामीनपात्र');
        final relativeDetails = v('relativeDetails', '.....................................................................................');

        final accusedSig = v('accusedSig');
        final ioNameSig = v('ioNameSig');

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── TOP RIGHT ──
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 220,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('पोलीस स्टेशन $ps', style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('दिनांक : $dateStr', style: regular),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 16),

            // ── HEADER TITLE ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('-:: आरोपीस सुचनापत्र ::-', style: headerTitle),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '(भारतीय नागरी सुरक्षा संहिता २०२३ कलम ४७ (१)(२))',
                    style: headerSub,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ── ACCUSED SECTION ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('नांव :- ', style: bold),
                pw.Expanded(
                  child: pw.Text(
                    accusedNameAddress.isNotEmpty
                        ? accusedNameAddress
                        : '__________________________________________________________________\n__________________________________________________________________',
                    style: regular,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            pw.Row(
              children: [
                pw.Text('मो.नं.:- $mobileNo', style: regular),
                pw.SizedBox(width: 24),
                pw.Text('आधार क्र :- $aadhaarNo', style: regular),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text('ईमेल :- $email', style: regular),
            pw.SizedBox(height: 24),

            // ── BODY PARAGRAPH 1 ──
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 5),
                children: [
                  const pw.TextSpan(
                    text:
                        '        आपणास याद्वारे सुचीत करण्यात येते की,आपणा विरुध्द पोलीस स्टेशन ',
                  ),
                  pw.TextSpan(text: '$firPs ', style: bold),
                  const pw.TextSpan(text: 'जिल्हा यवतमाळ येथे अपराध क्रमांक'),
                  pw.TextSpan(text: '$crimeNo/२०...... ', style: bold),
                  const pw.TextSpan(text: 'कलम'),
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
            pw.SizedBox(height: 14),

            // ── BODY PARAGRAPH 2 ──
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 5),
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
            pw.SizedBox(height: 14),

            // ── BODY PARAGRAPH 3 ──
            pw.Center(
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
                    if (accusedSig.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(accusedSig, style: regular),
                    ],
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('तपासी अधिकारी नांव व सही', style: bold),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      ioNameSig.isNotEmpty
                          ? ioNameSig
                          : '____________________',
                      style: regular,
                    ),
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
