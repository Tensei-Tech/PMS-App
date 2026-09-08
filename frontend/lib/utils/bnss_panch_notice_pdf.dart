import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewBnssPanchNoticePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateBnssPanchNoticePdf(doc);
  if (!context.mounted) return;
  final fileName =
      'BNSS_Panch_Notice_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateBnssPanchNoticePdf(Map<String, dynamic> doc) async {
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

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 1: घटनास्थळ / जप्ती पंचनामा सुचनापत्र ──
  // ══════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      build: (pw.Context context) {
        final ps = v('p1_policeStation', v('policeStation', '--------'));
        final dateStr = v('p1_date', v('date', '......./ ......../२०...'));

        final panch1 = v('p1_panch1', v('panch1'));
        final panch2 = v('p1_panch2', v('panch2'));

        final firPs = v('p1_firPs', v('firPs', '-----------------'));
        final crimeNo = v('p1_crimeNo', v('crimeNo', '........'));
        final actSec = v(
          'p1_actSec',
          v('actSec', '---------------------------------------------------------------------'),
        );
        final complainantName = v(
          'p1_complainantName',
          v('complainantName', '----------------------------------------------'),
        );
        final complainantResidence = v('p1_complainantResidence', v('complainantResidence', '----------'));
        final complainantTah = v('p1_complainantTah', v('complainantTah', '--------'));
        final complainantDist = v('p1_complainantDist', v('complainantDist', 'यवतमाळ'));

        final ioNameSig = v('p1_ioNameSig', v('ioNameSig'));
        final panch1Receipt = v('p1_panch1Receipt', v('panch1Receipt', '-----------------------'));
        final panch2Receipt = v('p1_panch2Receipt', v('panch2Receipt', '-----------------------'));

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Right
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

            // Header Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('-:: पंच सुचनापत्र ::-', style: headerTitle),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
                    style: headerSub,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Panch Names
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 90,
                  child: pw.Text('पंच नांव  :-', style: bold),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('१) ', style: bold),
                          pw.Expanded(
                            child: pw.Text(
                              panch1.isNotEmpty
                                  ? panch1
                                  : '__________________________________________________\n__________________________________________________',
                              style: regular,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('२) ', style: bold),
                          pw.Expanded(
                            child: pw.Text(
                              panch2.isNotEmpty
                                  ? panch2
                                  : '__________________________________________________\n__________________________________________________',
                              style: regular,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Decorative oooo
            pw.Center(
              child: pw.Text(
                '००००',
                style: pw.TextStyle(
                  font: devanagariBold,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            pw.SizedBox(height: 24),

            // Body Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 5),
                children: [
                  const pw.TextSpan(
                    text:
                        '        आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन ',
                  ),
                  pw.TextSpan(text: '$firPs ', style: bold),
                  const pw.TextSpan(text: 'येथील अप / मर्ग / स्टे.डा क्रमांक '),
                  pw.TextSpan(text: '$crimeNo/२०..... ', style: bold),
                  const pw.TextSpan(text: 'कलम '),
                  pw.TextSpan(text: '$actSec ', style: bold),
                  const pw.TextSpan(text: 'मधील फिर्यादी नामे '),
                  pw.TextSpan(text: '$complainantName ', style: bold),
                  const pw.TextSpan(text: 'रा '),
                  pw.TextSpan(text: '$complainantResidence ', style: bold),
                  const pw.TextSpan(text: 'ता '),
                  pw.TextSpan(text: '$complainantTah ', style: bold),
                  const pw.TextSpan(text: 'जिल्हा '),
                  pw.TextSpan(text: '$complainantDist ', style: bold),
                  const pw.TextSpan(
                    text:
                        'यांनी तक्रार दिली वरून सदरचा गुन्हा नोंद होउन तपासात आहे. तरी सदर गुन्ह्यामधील घटनास्थळचा/ जप्ती पंचनामा करावयाचा असल्याने आपण पंच म्हणुन हजर राहा असे सांगीतल्या वरून पंच हजर आले आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Closing line
            pw.Center(
              child: pw.Text('करीता सुचनापत्र देण्यात येत आहे.', style: regular),
            ),
            pw.Spacer(),

            // Signature block
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Column(
                children: [
                  pw.Text('तपासी अधिकारी नांव व सही', style: bold),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    ioNameSig.isNotEmpty ? ioNameSig : '____________________',
                    style: regular,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Receipt Acknowledgement
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('सुचनापत्र मिळाले आहे.', style: bold),
                pw.SizedBox(height: 6),
                pw.Text('१) $panch1Receipt', style: regular),
                pw.SizedBox(height: 4),
                pw.Text('२) $panch2Receipt', style: regular),
              ],
            ),
            pw.SizedBox(height: 12),

            // MRW Footer
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

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 2: दारूबाबत प्रोहिबीशन रेड पंच सुचनापत्र ──
  // ══════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      build: (pw.Context context) {
        final ps = v('p2_policeStation', v('policeStation', '--------'));
        final dateStr = v('p2_date', v('date', '......./ ......../२०...'));

        final panch1 = v('p2_panch1', v('panch1'));
        final panch2 = v('p2_panch2', v('panch2'));

        final raidDate = v('p2_raidDate', v('raidDate', '......./ ......./२०.....'));
        final village = v('p2_village', v('village', '-------------'));
        final suspectName = v('p2_suspectName', v('suspectName', '-------------------------------------'));
        final suspectAge = v('p2_suspectAge', v('suspectAge', '........'));
        final suspectResidence = v('p2_suspectResidence', v('suspectResidence', '-------------'));
        final suspectTah = v('p2_suspectTah', v('suspectTah', '--------'));
        final suspectDist = v('p2_suspectDist', v('suspectDist', 'यवतमाळ'));

        final ioNameSig = v('p2_ioNameSig', v('ioNameSig'));
        final panch1Receipt = v('p2_panch1Receipt', v('panch1Receipt', '-----------------------'));
        final panch2Receipt = v('p2_panch2Receipt', v('panch2Receipt', '-----------------------'));

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Right
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

            // Header Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('-:: पंच सुचनापत्र ::-', style: headerTitle),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
                    style: headerSub,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Panch Names
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 90,
                  child: pw.Text('पंच नांव  :-', style: bold),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('१) ', style: bold),
                          pw.Expanded(
                            child: pw.Text(
                              panch1.isNotEmpty
                                  ? panch1
                                  : '__________________________________________________\n__________________________________________________',
                              style: regular,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('२) ', style: bold),
                          pw.Expanded(
                            child: pw.Text(
                              panch2.isNotEmpty
                                  ? panch2
                                  : '__________________________________________________\n__________________________________________________',
                              style: regular,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Decorative oooo
            pw.Center(
              child: pw.Text(
                '००००',
                style: pw.TextStyle(
                  font: devanagariBold,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            pw.SizedBox(height: 24),

            // Body Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 5),
                children: [
                  const pw.TextSpan(
                    text:
                        '        आपणास या सुचनापत्र देण्यात येते की, आज दिनांक:',
                  ),
                  pw.TextSpan(text: '$raidDate ', style: bold),
                  const pw.TextSpan(text: 'रोजी ग्राम '),
                  pw.TextSpan(text: '$village ', style: bold),
                  const pw.TextSpan(text: 'येथीलनामे '),
                  pw.TextSpan(text: '$suspectName ', style: bold),
                  const pw.TextSpan(text: 'वय '),
                  pw.TextSpan(text: '$suspectAge ', style: bold),
                  const pw.TextSpan(text: 'वर्ष '),
                  const pw.TextSpan(text: 'रा. '),
                  pw.TextSpan(text: '$suspectResidence ', style: bold),
                  const pw.TextSpan(text: 'ता '),
                  pw.TextSpan(text: '$suspectTah ', style: bold),
                  const pw.TextSpan(text: 'जिल्हा '),
                  pw.TextSpan(text: '$suspectDist ', style: bold),
                  const pw.TextSpan(
                    text:
                        'हा त्याचे घरी दारू विक्री करतो अशा माहिती वरून त्याचे घरी दारूबाबत प्रोहिबीशन रेड करावयाचा असल्याने आपण जप्त पंच म्हणुन सोबत चला व हजर राहावे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Closing line
            pw.Center(
              child: pw.Text('करीता सुचनापत्र देण्यात येत आहे.', style: regular),
            ),
            pw.Spacer(),

            // Signature block
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Column(
                children: [
                  pw.Text('तपासी अधिकारी नांव व सही', style: bold),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    ioNameSig.isNotEmpty ? ioNameSig : '____________________',
                    style: regular,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Receipt Acknowledgement
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('सुचनापत्र मिळाले आहे.', style: bold),
                pw.SizedBox(height: 6),
                pw.Text('१) $panch1Receipt', style: regular),
                pw.SizedBox(height: 4),
                pw.Text('२) $panch2Receipt', style: regular),
              ],
            ),
            pw.SizedBox(height: 12),

            // MRW Footer
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
