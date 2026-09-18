import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';

Future<void> previewBnssPanchNoticePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'BNSS_Panch_Notice_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPg1Widget(doc), _buildPg2Widget(doc)],
    fallbackPdfGenerator: () => generateBnssPanchNoticePdf(doc),
  );
}

Future<Uint8List> generateBnssPanchNoticePdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 10.5,
    lineSpacing: 5,
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
  );
  final headerSub = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 1: घटनास्थळ / जप्ती पंचनामा सुचनापत्र (Image 1) ──
  // ══════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      build: (pw.Context context) {
        final ps = v('p1_policeStation', v('policeStation', '--------'));
        final dateStr = v('p1_date', v('date', '......./ ......./२०...'));

        final panch1 = v('p1_panch1', v('panch1'));
        final panch1Line2 = v('p1_panch1Line2');
        final panch2 = v('p1_panch2', v('panch2'));
        final panch2Line2 = v('p1_panch2Line2');

        final firPs = v('p1_firPs', v('firPs', '-----------'));
        final crimeNo = v('p1_crimeNo', v('crimeNo', '........'));
        final crimeYear = v('p1_crimeYear', '.....');
        final actSec = v(
          'p1_actSec',
          v('actSec', '---------------------------------'),
        );
        final complainantName = v(
          'p1_complainantName',
          v('complainantName', '-------------------------------------'),
        );
        final complainantResidence = v('p1_complainantResidence',
            v('complainantResidence', '-----------'));
        final complainantTah =
            v('p1_complainantTah', v('complainantTah', '-----------'));
        final complainantDist =
            v('p1_complainantDist', v('complainantDist', 'यवतमाळ'));

        final ioNameSig = v('p1_ioNameSig', v('ioNameSig'));
        final panch1Receipt = v(
            'p1_panch1Receipt', v('panch1Receipt', '-----------------------'));
        final panch2Receipt = v(
            'p1_panch2Receipt', v('panch2Receipt', '-----------------------'));

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
                    pw.SizedBox(height: 3),
                    pw.Text('दिनांक :$dateStr', style: regular),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 18),

            // Header Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('—:: पंच सुचनापत्र ::—', style: headerTitle),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
                    style: headerSub.copyWith(
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            // Panch Names
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 90,
                  child: pw.Text('पंच नांव', style: bold),
                ),
                pw.Text(':-   ', style: bold),
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
                                  : '--------------------------------------------------------',
                              style: regular,
                            ),
                          ),
                        ],
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 14),
                        child: pw.Text(
                          panch1Line2.isNotEmpty
                              ? panch1Line2
                              : '--------------------------------------------------------',
                          style: regular,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('२) ', style: bold),
                          pw.Expanded(
                            child: pw.Text(
                              panch2.isNotEmpty
                                  ? panch2
                                  : '--------------------------------------------------------',
                              style: regular,
                            ),
                          ),
                        ],
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 14),
                        child: pw.Text(
                          panch2Line2.isNotEmpty
                              ? panch2Line2
                              : '--------------------------------------------------------',
                          style: regular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Decorative oooo
            pw.Center(
              child: pw.Text(
                '००००',
                style: pw.TextStyle(
                  font: devanagariBold,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Body Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 6),
                children: [
                  const pw.TextSpan(
                    text:
                        '      आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन',
                  ),
                  pw.TextSpan(text: '$firPs ', style: bold),
                  const pw.TextSpan(text: 'येथील अप / मर्ग/ स्टे.डा क्रमांक '),
                  pw.TextSpan(
                    text: '$crimeNo/२०$crimeYear ',
                    style: bold,
                  ),
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
                        'यांनी तक्रार दिली वरून सदरचा गुन्हा नोंद होउन तपासात आहे. तरी सदर गुन्ह्यामधील घटनास्थळाचा/ जप्ती पंचनामा करावयाचा असल्याने आपण पंच म्हणुन हजर राहा असे सांगीतल्या वरून पंच हजर आले आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            // Closing line
            pw.Center(
              child: pw.Text(
                'करीता सुचनापत्र देण्यात येत आहे.',
                style: regular,
              ),
            ),
            pw.Spacer(),

            // Signature block (Right)
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Column(
                children: [
                  pw.Text('तपासी अधिकारी नांव व सही', style: bold),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    ioNameSig.isNotEmpty ? ioNameSig : '____________________',
                    style: regular,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Receipt Acknowledgement (Left)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('सुचनापत्र मिळाले आहे.', style: bold),
                pw.SizedBox(height: 8),
                pw.Text('१) $panch1Receipt', style: regular),
                pw.SizedBox(height: 6),
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
  // ── PAGE 2: दारूबाबत प्रोहिबीशन रेड सुचनापत्र (Image 2) ──
  // ══════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      build: (pw.Context context) {
        final ps = v('p2_policeStation', v('policeStation', '--------'));
        final dateStr = v('p2_date', v('date', '......./ ......./२०...'));

        final panch1 = v('p2_panch1', v('panch1'));
        final panch1Line2 = v('p2_panch1Line2');
        final panch2 = v('p2_panch2', v('panch2'));
        final panch2Line2 = v('p2_panch2Line2');

        final raidDate =
            v('p2_raidDate', v('raidDate', '......./ ......./२०.....'));
        final village = v('p2_village', v('village', '-------------'));
        final suspectName = v('p2_suspectName',
            v('suspectName', '---------------------------------------'));
        final suspectAge = v('p2_suspectAge', v('suspectAge', '........'));
        final suspectResidence =
            v('p2_suspectResidence', v('suspectResidence', '--------------'));
        final suspectTah = v('p2_suspectTah', v('suspectTah', '-----------'));
        final suspectDist = v('p2_suspectDist', v('suspectDist', 'यवतमाळ'));

        final ioNameSig = v('p2_ioNameSig', v('ioNameSig'));
        final panch1Receipt = v(
            'p2_panch1Receipt', v('panch1Receipt', '-----------------------'));
        final panch2Receipt = v(
            'p2_panch2Receipt', v('panch2Receipt', '-----------------------'));

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
                    pw.SizedBox(height: 3),
                    pw.Text('दिनांक :$dateStr', style: regular),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 18),

            // Header Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('—:: पंच सुचनापत्र ::—', style: headerTitle),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
                    style: headerSub.copyWith(
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            // Panch Names
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 90,
                  child: pw.Text('पंच नांव', style: bold),
                ),
                pw.Text(':-   ', style: bold),
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
                                  : '--------------------------------------------------------',
                              style: regular,
                            ),
                          ),
                        ],
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 14),
                        child: pw.Text(
                          panch1Line2.isNotEmpty
                              ? panch1Line2
                              : '--------------------------------------------------------',
                          style: regular,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('२) ', style: bold),
                          pw.Expanded(
                            child: pw.Text(
                              panch2.isNotEmpty
                                  ? panch2
                                  : '--------------------------------------------------------',
                              style: regular,
                            ),
                          ),
                        ],
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 14),
                        child: pw.Text(
                          panch2Line2.isNotEmpty
                              ? panch2Line2
                              : '--------------------------------------------------------',
                          style: regular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Decorative oooo
            pw.Center(
              child: pw.Text(
                '००००',
                style: pw.TextStyle(
                  font: devanagariBold,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Body Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 6),
                children: [
                  const pw.TextSpan(
                    text:
                        '      आपणास या सुचनापत्र देण्यात येते की, आज दिनांक:',
                  ),
                  pw.TextSpan(text: '$raidDate ', style: bold),
                  const pw.TextSpan(text: 'रोजी ग्राम'),
                  pw.TextSpan(text: '$village ', style: bold),
                  const pw.TextSpan(text: 'येथीलनामे'),
                  pw.TextSpan(text: '$suspectName ', style: bold),
                  const pw.TextSpan(text: 'वय'),
                  pw.TextSpan(text: '$suspectAge ', style: bold),
                  const pw.TextSpan(text: 'वर्ष'),
                  const pw.TextSpan(text: '----------- रा.'),
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
            pw.SizedBox(height: 22),

            // Closing line
            pw.Center(
              child: pw.Text(
                'करीता सुचनापत्र देण्यात येत आहे.',
                style: regular,
              ),
            ),
            pw.Spacer(),

            // Signature block (Right)
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Column(
                children: [
                  pw.Text('तपासी अधिकारी नांव व सही', style: bold),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    ioNameSig.isNotEmpty ? ioNameSig : '____________________',
                    style: regular,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Receipt Acknowledgement (Left)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('सुचनापत्र मिळाले आहे.', style: bold),
                pw.SizedBox(height: 8),
                pw.Text('१) $panch1Receipt', style: regular),
                pw.SizedBox(height: 6),
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

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDERS (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

Widget _buildPg1Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final rawPs = v('p1_policeStation', v('policeStation'));
  final ps = rawPs.isNotEmpty ? rawPs : '--------';
  final rawDate = v('p1_date', v('date'));
  final dateStr = rawDate.isNotEmpty ? rawDate : '......./ ......./२०...';

  final panch1 = v('p1_panch1', v('panch1'));
  final panch1Line2 = v('p1_panch1Line2');
  final panch2 = v('p1_panch2', v('panch2'));
  final panch2Line2 = v('p1_panch2Line2');

  final rawFirPs = v('p1_firPs', v('firPs'));
  final firPs = rawFirPs.isNotEmpty ? rawFirPs : ps;
  final rawCrimeNo = v('p1_crimeNo', v('crimeNo'));
  final crimeNo = rawCrimeNo.isNotEmpty ? rawCrimeNo : '....';
  final rawCrimeYear = v('p1_crimeYear', v('crimeYear'));
  final crimeYear = rawCrimeYear.isNotEmpty ? rawCrimeYear : '..';
  final rawActSec = v('p1_actSec', v('actSec'));
  final actSec = rawActSec.isNotEmpty ? rawActSec : '------------';
  final rawComplainantName = v('p1_complainantName', v('complainantName'));
  final complainantName = rawComplainantName.isNotEmpty ? rawComplainantName : '---------------------------------------';
  final rawComplainantResidence = v('p1_complainantResidence', v('complainantResidence'));
  final complainantResidence = rawComplainantResidence.isNotEmpty ? rawComplainantResidence : '------------------';
  final rawComplainantTah = v('p1_complainantTah', v('complainantTah'));
  final complainantTah = rawComplainantTah.isNotEmpty ? rawComplainantTah : '-----------';
  final rawComplainantDist = v('p1_complainantDist', v('complainantDist'));
  final complainantDist = rawComplainantDist.isNotEmpty ? rawComplainantDist : 'यवतमाळ';

  final ioNameSig = v('p1_ioNameSig', v('ioNameSig'));
  final rawPanch1Receipt = v('p1_panch1Receipt', v('panch1Receipt'));
  final panch1Receipt = rawPanch1Receipt.isNotEmpty ? rawPanch1Receipt : '-----------------------';
  final rawPanch2Receipt = v('p1_panch2Receipt', v('panch2Receipt'));
  final panch2Receipt = rawPanch2Receipt.isNotEmpty ? rawPanch2Receipt : '-----------------------';

  final reg = FormImagePdfHelper.mReg(11, 1.6);
  final bld = FormImagePdfHelper.mBld(11, 1.6);
  final headerTitle = FormImagePdfHelper.mBld(16, 1.3);
  final headerSub = FormImagePdfHelper.mBld(11, 1.3);

  TextStyle valBld(String raw) => bld.copyWith(
        decoration: raw.isNotEmpty ? TextDecoration.underline : TextDecoration.none,
      );

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('पोलीस स्टेशन : ', style: reg),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.8, color: Colors.black87),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 1),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ps,
                          maxLines: 1,
                          softWrap: false,
                          style: bld,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('दिनांक : ', style: reg),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.8, color: Colors.black87),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        dateStr,
                        style: bld,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Column(
          children: [
            Text('—:: पंच सुचनापत्र ::—', style: headerTitle),
            const SizedBox(height: 3),
            Text(
              '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
              style: headerSub.copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('पंच नांव', style: bld),
          ),
          Text(':-   ', style: bld),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('१) ', style: bld),
                    Expanded(
                      child: Text(
                        panch1.isNotEmpty
                            ? panch1
                            : '--------------------------------------------------------',
                        style: panch1.isNotEmpty
                            ? bld.copyWith(decoration: TextDecoration.underline)
                            : reg,
                      ),
                    ),
                  ],
                ),
                if (panch1Line2.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(
                      panch1Line2,
                      style: bld.copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('२) ', style: bld),
                    Expanded(
                      child: Text(
                        panch2.isNotEmpty
                            ? panch2
                            : '--------------------------------------------------------',
                        style: panch2.isNotEmpty
                            ? bld.copyWith(decoration: TextDecoration.underline)
                            : reg,
                      ),
                    ),
                  ],
                ),
                if (panch2Line2.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(
                      panch2Line2,
                      style: bld.copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(
          '००००',
          style: bld.copyWith(fontSize: 13, letterSpacing: 4),
        ),
      ),
      const SizedBox(height: 20),
      Text.rich(
        TextSpan(
          style: reg.copyWith(height: 1.7),
          children: [
            const TextSpan(
              text: '      आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन ',
            ),
            TextSpan(text: '$firPs ', style: valBld(rawFirPs)),
            const TextSpan(text: 'येथील अप / मर्ग/ स्टे.डा क्रमांक '),
            TextSpan(text: '$crimeNo/२०$crimeYear ', style: valBld(rawCrimeNo.isNotEmpty ? rawCrimeNo : rawCrimeYear)),
            const TextSpan(text: 'कलम '),
            TextSpan(text: '$actSec ', style: valBld(rawActSec)),
            const TextSpan(text: 'मधील फिर्यादी नामे '),
            TextSpan(text: '$complainantName ', style: valBld(rawComplainantName)),
            const TextSpan(text: 'रा '),
            TextSpan(text: '$complainantResidence ', style: valBld(rawComplainantResidence)),
            const TextSpan(text: 'ता '),
            TextSpan(text: '$complainantTah ', style: valBld(rawComplainantTah)),
            const TextSpan(text: 'जिल्हा '),
            TextSpan(text: '$complainantDist ', style: valBld(rawComplainantDist)),
            const TextSpan(
              text:
                  'यांनी तक्रार दिली वरून सदरचा गुन्हा नोंद होउन तपासात आहे. तरी सदर गुन्ह्यामधील घटनास्थळाचा/ जप्ती पंचनामा करावयाचा असल्याने आपण पंच म्हणुन हजर राहा असे सांगीतल्या वरून पंच हजर आले आहे.',
            ),
          ],
        ),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 22),
      Center(
        child: Text('करीता सुचनापत्र देण्यात येत आहे.', style: reg),
      ),
      const Spacer(),
      Align(
        alignment: Alignment.topRight,
        child: Column(
          children: [
            Text('तपासी अधिकारी नांव व सही', style: bld),
            const SizedBox(height: 6),
            Text(
              ioNameSig.isNotEmpty ? ioNameSig : '____________________',
              style: ioNameSig.isNotEmpty
                  ? bld.copyWith(decoration: TextDecoration.underline)
                  : reg,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('सुचनापत्र मिळाले आहे.', style: bld),
          const SizedBox(height: 8),
          Text(
            '१) $panch1Receipt',
            style: rawPanch1Receipt.isNotEmpty
                ? bld.copyWith(decoration: TextDecoration.underline)
                : reg,
          ),
          const SizedBox(height: 6),
          Text(
            '२) $panch2Receipt',
            style: rawPanch2Receipt.isNotEmpty
                ? bld.copyWith(decoration: TextDecoration.underline)
                : reg,
          ),
        ],
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.bottomRight,
        child: Text('M.R.W',
            style: reg.copyWith(fontSize: 8, color: Colors.grey.shade700)),
      ),
    ],
  );
}

Widget _buildPg2Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final rawPs = v('p2_policeStation', v('policeStation'));
  final ps = rawPs.isNotEmpty ? rawPs : '--------';
  final rawDate = v('p2_date', v('date'));
  final dateStr = rawDate.isNotEmpty ? rawDate : '......./ ......./२०...';

  final panch1 = v('p2_panch1', v('panch1'));
  final panch1Line2 = v('p2_panch1Line2');
  final panch2 = v('p2_panch2', v('panch2'));
  final panch2Line2 = v('p2_panch2Line2');

  final rawRaidDate = v('p2_raidDate', v('raidDate'));
  final raidDate = rawRaidDate.isNotEmpty ? rawRaidDate : '......./ ......./२०.....';
  final rawVillage = v('p2_village', v('village'));
  final village = rawVillage.isNotEmpty ? rawVillage : '-------------';
  final rawSuspectName = v('p2_suspectName', v('suspectName'));
  final suspectName = rawSuspectName.isNotEmpty ? rawSuspectName : '---------------------------------------';
  final rawSuspectAge = v('p2_suspectAge', v('suspectAge'));
  final suspectAge = rawSuspectAge.isNotEmpty ? rawSuspectAge : '........';
  final rawSuspectResidence = v('p2_suspectResidence', v('suspectResidence'));
  final suspectResidence = rawSuspectResidence.isNotEmpty ? rawSuspectResidence : '--------------';
  final rawSuspectTah = v('p2_suspectTah', v('suspectTah'));
  final suspectTah = rawSuspectTah.isNotEmpty ? rawSuspectTah : '-----------';
  final rawSuspectDist = v('p2_suspectDist', v('suspectDist'));
  final suspectDist = rawSuspectDist.isNotEmpty ? rawSuspectDist : 'यवतमाळ';

  final ioNameSig = v('p2_ioNameSig', v('ioNameSig'));
  final rawPanch1Receipt = v('p2_panch1Receipt', v('panch1Receipt'));
  final panch1Receipt = rawPanch1Receipt.isNotEmpty ? rawPanch1Receipt : '-----------------------';
  final rawPanch2Receipt = v('p2_panch2Receipt', v('panch2Receipt'));
  final panch2Receipt = rawPanch2Receipt.isNotEmpty ? rawPanch2Receipt : '-----------------------';

  final reg = FormImagePdfHelper.mReg(11, 1.6);
  final bld = FormImagePdfHelper.mBld(11, 1.6);
  final headerTitle = FormImagePdfHelper.mBld(16, 1.3);
  final headerSub = FormImagePdfHelper.mBld(11, 1.3);

  TextStyle valBld(String raw) => bld.copyWith(
        decoration: raw.isNotEmpty ? TextDecoration.underline : TextDecoration.none,
      );

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('पोलीस स्टेशन : ', style: reg),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.8, color: Colors.black87),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 1),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ps,
                          maxLines: 1,
                          softWrap: false,
                          style: bld,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('दिनांक : ', style: reg),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.8, color: Colors.black87),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        dateStr,
                        style: bld,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Column(
          children: [
            Text('—:: पंच सुचनापत्र ::—', style: headerTitle),
            const SizedBox(height: 3),
            Text(
              '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
              style: headerSub.copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('पंच नांव', style: bld),
          ),
          Text(':-   ', style: bld),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('१) ', style: bld),
                    Expanded(
                      child: Text(
                        panch1.isNotEmpty
                            ? panch1
                            : '--------------------------------------------------------',
                        style: panch1.isNotEmpty
                            ? bld.copyWith(decoration: TextDecoration.underline)
                            : reg,
                      ),
                    ),
                  ],
                ),
                if (panch1Line2.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(
                      panch1Line2,
                      style: bld.copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('२) ', style: bld),
                    Expanded(
                      child: Text(
                        panch2.isNotEmpty
                            ? panch2
                            : '--------------------------------------------------------',
                        style: panch2.isNotEmpty
                            ? bld.copyWith(decoration: TextDecoration.underline)
                            : reg,
                      ),
                    ),
                  ],
                ),
                if (panch2Line2.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(
                      panch2Line2,
                      style: bld.copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(
          '००००',
          style: bld.copyWith(fontSize: 13, letterSpacing: 4),
        ),
      ),
      const SizedBox(height: 20),
      Text.rich(
        TextSpan(
          style: reg.copyWith(height: 1.7),
          children: [
            const TextSpan(
              text: '      आपणास या सुचनापत्र देण्यात येते की, आज दिनांक ',
            ),
            TextSpan(text: '$raidDate ', style: valBld(rawRaidDate)),
            const TextSpan(text: 'रोजी पोलीस स्टेशन हद्दीत मौजे '),
            TextSpan(text: '$village ', style: valBld(rawVillage)),
            const TextSpan(
              text:
                  'येथे प्रोहिबीशन रेड कारवाई करणे बाबत खात्रीशिर बातमी मिळाल्या वरून आम्ही पोलीस पथकासह प्रोहिबीशन रेड कारवाई करणे करीता जात असतांना इसम नामे ',
            ),
            TextSpan(text: '$suspectName ', style: valBld(rawSuspectName)),
            const TextSpan(text: 'वय '),
            TextSpan(text: '$suspectAge ', style: valBld(rawSuspectAge)),
            const TextSpan(text: 'रा '),
            TextSpan(text: '$suspectResidence ', style: valBld(rawSuspectResidence)),
            const TextSpan(text: 'ता '),
            TextSpan(text: '$suspectTah ', style: valBld(rawSuspectTah)),
            const TextSpan(text: 'जिल्हा '),
            TextSpan(text: '$suspectDist ', style: valBld(rawSuspectDist)),
            const TextSpan(
              text:
                  'याचे घराची / जागेची / वाहनाची झडती घेवुन प्रोहिबीशन कारवाई करावयाची असल्याने आपण पंच म्हणुन हजर राहा असे सांगीतल्या वरून पंच हजर आले आहे.',
            ),
          ],
        ),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 22),
      Center(
        child: Text('करीता सुचनापत्र देण्यात येत आहे.', style: reg),
      ),
      const Spacer(),
      Align(
        alignment: Alignment.topRight,
        child: Column(
          children: [
            Text('तपासी अधिकारी नांव व सही', style: bld),
            const SizedBox(height: 6),
            Text(
              ioNameSig.isNotEmpty ? ioNameSig : '____________________',
              style: ioNameSig.isNotEmpty
                  ? bld.copyWith(decoration: TextDecoration.underline)
                  : reg,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('सुचनापत्र मिळाले आहे.', style: bld),
          const SizedBox(height: 8),
          Text(
            '१) $panch1Receipt',
            style: rawPanch1Receipt.isNotEmpty
                ? bld.copyWith(decoration: TextDecoration.underline)
                : reg,
          ),
          const SizedBox(height: 6),
          Text(
            '२) $panch2Receipt',
            style: rawPanch2Receipt.isNotEmpty
                ? bld.copyWith(decoration: TextDecoration.underline)
                : reg,
          ),
        ],
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.bottomRight,
        child: Text('M.R.W',
            style: reg.copyWith(fontSize: 8, color: Colors.grey.shade700)),
      ),
    ],
  );
}
