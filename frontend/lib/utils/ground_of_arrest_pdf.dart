import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'form_image_pdf_helper.dart';
import 'pdf_font_cache.dart';

Future<void> previewGroundOfArrestPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Ground_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final section = (doc['formSection']?.toString() ?? '').toLowerCase();
  final showMain = section.isEmpty ||
      (section.contains('main') && !section.contains('continuation'));
  final showCont = section.isEmpty || section.contains('continuation');

  final pages = <Widget>[];
  if (showMain) pages.add(_buildPg1Widget(doc));
  if (showCont) pages.add(_buildPg2Widget(doc));

  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: pages,
    fallbackPdfGenerator: () => generateGroundOfArrestPdf(doc),
  );
}

Future<Uint8List> generateGroundOfArrestPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final section = (doc['formSection']?.toString() ?? '').toLowerCase();
  final showMain = section.isEmpty ||
      (section.contains('main') && !section.contains('continuation'));
  final showCont = section.isEmpty || section.contains('continuation');
  final devanagari = await PdfFontCache.devanagariRegular();
  final devanagariBold = await PdfFontCache.devanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 10.5,
    lineSpacing: 5.5,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 13.5,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 1 (Image 1) ──
  // ══════════════════════════════════════════════════════════════════════
  if (showMain) {
    pdf.addPage(
      pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      build: (pw.Context context) {
        final outwardNo = v('');
        final outwardYear = v('');
        final policeStation = v('');
        final taluka = v('');
        final district = v('');
        final noticeDate = v('');

        final accusedNameAddress = v(
          'accusedNameAddress',
          '---------------------------------------------------------------------------------------',
        );
        final accusedNameAddressLine2 = v(
          'accusedNameAddressLine2',
          '----------------------------------------------------------------------------------------------------',
        );

        final subjectPs = v('');
        final subjectCrNo = v('');
        final subjectSection = v('');

        final firPs = v('');
        final firCrNo = v('');
        final firCrYear = v('');
        final firActSec = v('');
        final ioName = v('');

        final briefDescription = v(
          'briefDescription',
          '----------------------------------------------------------------------',
        );
        final briefDescLine2 = v(
          'briefDescLine2',
          '----------------------------------------------------------------------------------------------------',
        );
        final briefDescLine3 = v(
          'briefDescLine3',
          '----------------------------------------------------------------------------------------------------',
        );
        final briefDescLine4 = v(
          'briefDescLine4',
          '----------------------------------------------------------------------------------------------------',
        );
        final briefDescLine5 = v(
          'briefDescLine5',
          '-------------------------------------------------',
        );

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये',
                    style: headerTitle,
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text('सुचनापत्र', style: headerTitle),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Top Right Metadata Box
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 260,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('जावक.क्रमांक- $outwardNo /२०$outwardYear',
                        style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('पोलीस स्टेशन $policeStation', style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('ता.-$taluka -जिल्हा-$district', style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('दिनांक:- $noticeDate', style: regular),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 18),

            // Recipient Section
            pw.Text('प्रति,', style: bold),
            pw.SizedBox(height: 4),
            pw.Text('नाव व पत्ता $accusedNameAddress', style: regular),
            pw.Text(accusedNameAddressLine2, style: regular),
            pw.SizedBox(height: 16),

            // Subject Section
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  pw.TextSpan(
                    text:
                        'विषय:- पोलीस स्टेशन $subjectPs गुन्हा रजि.क्र.$subjectCrNo कलम $subjectSection भा.न्या.स.\n',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text:
                        '        नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक\n        करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Main Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(
                    text:
                        '        आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुद्ध पोलीस ठाणे ',
                  ),
                  pw.TextSpan(text: '$firPs ', style: bold),
                  const pw.TextSpan(text: 'येथे गुन्हा रजि.क्र.'),
                  pw.TextSpan(text: '$firCrNo/$firCrYear ', style: bold),
                  const pw.TextSpan(text: 'कलम '),
                  pw.TextSpan(text: '$firActSec ', style: bold),
                  const pw.TextSpan(
                    text:
                        'भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन, आम्ही ',
                  ),
                  pw.TextSpan(text: '$ioName ', style: bold),
                  const pw.TextSpan(
                    text:
                        'तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत.सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार आपणास अटक करण्यासाठी आधारभूत मुद्दे (भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार ) खालील प्रमाणे आहेत.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // गुन्ह्यांचे संक्षीप्त विवरण
            pw.Text('गुन्ह्यांचे संक्षीप्त विवरण :- $briefDescription',
                style: regular),
            pw.Text(briefDescLine2, style: regular),
            pw.Text(briefDescLine3, style: regular),
            pw.Text(briefDescLine4, style: regular),
            pw.Text(briefDescLine5, style: regular),
            pw.SizedBox(height: 16),

            // Note & Page 2 Indicator
            pw.Text('(अधिक माहितीसाठी फिर्यादीची प्रत सोबत जोडली आहे)',
                style: regular),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('२..', style: bold),
            ),
          ],
        );
      },
    ),
  );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 2 (Image 2) ──
  // ══════════════════════════════════════════════════════════════════════
  if (showCont) {
    pdf.addPage(
      pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      build: (pw.Context context) {
        final ground1 = v('ground1',
            '-----------------------------------------------------------------------------------------------');
        final ground1Line2 = v('ground1Line2',
            '-----------------------------------------------------------------------------------------------');
        final ground2 = v('ground2',
            '-----------------------------------------------------------------------------------------------');
        final ground2Line2 = v('ground2Line2',
            '-----------------------------------------------------------------------------------------------');
        final ground3 = v('ground3',
            '-----------------------------------------------------------------------------------------------');
        final ground3Line2 = v('ground3Line2',
            '-----------------------------------------------------------------------------------------------');
        final ground4 = v('ground4',
            '-----------------------------------------------------------------------------------------------');
        final ground4Line2 = v('ground4Line2',
            '-----------------------------------------------------------------------------------------------');
        final ground5 = v('ground5',
            '-----------------------------------------------------------------------------------------------');
        final ground5Line2 = v('ground5Line2',
            '-----------------------------------------------------------------------------------------------');

        final relativeName = v('');
        final relativeAddress = v('');
        final relativePhone = v('');

        final accusedSig = v('');
        final accusedName = v('');
        final accusedDateTime = v('');

        final ioSig = v('');
        final ioNameRank = v('');
        final ioPs = v('');
        final ioTah = v('');
        final ioDist = v('');

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Continuation Indicator
            pw.Center(
              child: pw.Text('..२..', style: bold),
            ),
            pw.SizedBox(height: 12),

            // Grounds Header
            pw.Center(
              child: pw.Text(
                'अटक करण्यासाठी आधारभूत मुद्दे (GROUNDS OF ARREST)',
                style: headerTitle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 18),

            // Grounds 1 to 5
            pw.Text('१. $ground1', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground1Line2, style: regular),
            ),
            pw.SizedBox(height: 6),

            pw.Text('२. $ground2', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground2Line2, style: regular),
            ),
            pw.SizedBox(height: 6),

            pw.Text('३. $ground3', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground3Line2, style: regular),
            ),
            pw.SizedBox(height: 6),

            pw.Text('४. $ground4', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground4Line2, style: regular),
            ),
            pw.SizedBox(height: 6),

            pw.Text('५. $ground5', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground5Line2, style: regular),
            ),
            pw.SizedBox(height: 16),

            // Paragraph 1 (Bail Inform)
            pw.Text(
              '        आपणास असेही कळविण्यात येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
              style: regular,
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 12),

            // Paragraph 2 (Relative Inform)
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(
                    text: '        आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र ',
                  ),
                  pw.TextSpan(text: '$relativeName ', style: bold),
                  const pw.TextSpan(text: 'रा.'),
                  pw.TextSpan(text: '$relativeAddress ', style: bold),
                  const pw.TextSpan(
                      text: 'यांना लेखी सुचनेद्वारे/फोन क्रमांक '),
                  pw.TextSpan(text: '$relativePhone ', style: bold),
                  const pw.TextSpan(
                    text: 'यावर संपर्क करुन देण्यांत आली आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Paragraph 3 (Closing)
            pw.Text(
              '        याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
              style: regular,
            ),
            pw.Spacer(),

            // Signatures (2 columns)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('मला सुचनापत्र प्राप्त झाले', style: bold),
                      pw.SizedBox(height: 6),
                      pw.Text('(आरोपीची सही $accusedSig)', style: regular),
                      pw.SizedBox(height: 4),
                      pw.Text('आरोपीचे नांव $accusedName', style: regular),
                      pw.SizedBox(height: 4),
                      pw.Text('दिनांक:व वेळ $accusedDateTime', style: regular),
                    ],
                  ),
                ),
                pw.SizedBox(width: 32),

                // Right Column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपास अधि सही/- $ioSig', style: bold),
                      pw.SizedBox(height: 6),
                      pw.Text('नाव/हुद्दा $ioNameRank', style: regular),
                      pw.SizedBox(height: 4),
                      pw.Text('पोलीस स्टेशन $ioPs', style: regular),
                      pw.SizedBox(height: 4),
                      pw.Text('ता.-$ioTah जिल्हा-$ioDist', style: regular),
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
  }

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

  final outwardNo = v('');
  final outwardYear = v('');
  final policeStation = v('');
  final taluka = v('');
  final district = v('');
  final noticeDate = v('');

  final accusedNameAddress = v(
    'accusedNameAddress',
    '---------------------------------------------------------------------------------------',
  );
  final accusedNameAddressLine2 = v(
    'accusedNameAddressLine2',
    '----------------------------------------------------------------------------------------------------',
  );

  final subjectPs = v('');
  final subjectCrNo = v('');
  final subjectSection = v('');

  final firPs = v('');
  final firCrNo = v('');
  final firCrYear = v('');
  final firActSec = v('');
  final ioName = v('');

  final briefDescription = v(
    'briefDescription',
    '----------------------------------------------------------------------',
  );
  final briefDescLine2 = v(
    'briefDescLine2',
    '----------------------------------------------------------------------------------------------------',
  );
  final briefDescLine3 = v(
    'briefDescLine3',
    '----------------------------------------------------------------------------------------------------',
  );
  final briefDescLine4 = v(
    'briefDescLine4',
    '----------------------------------------------------------------------------------------------------',
  );
  final briefDescLine5 = v(
    'briefDescLine5',
    '-------------------------------------------------',
  );

  final reg = FormImagePdfHelper.mReg(10.5, 1.45);
  final bld = FormImagePdfHelper.mBld(10.5, 1.45);
  final headerTitle = FormImagePdfHelper.mBld(13.5, 1.3);

  return Container(
    width: FormImagePdfHelper.a4Width,
    height: FormImagePdfHelper.a4Height,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये',
                style: headerTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text('सुचनापत्र', style: headerTitle),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('जावक.क्रमांक- $outwardNo /२०$outwardYear', style: reg),
                const SizedBox(height: 2),
                Text('पोलीस स्टेशन $policeStation', style: reg),
                const SizedBox(height: 2),
                Text('ता.-$taluka -जिल्हा-$district', style: reg),
                const SizedBox(height: 2),
                Text('दिनांक:- $noticeDate', style: reg),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('प्रति,', style: bld),
        const SizedBox(height: 4),
        Text('नाव व पत्ता $accusedNameAddress', style: reg),
        Text(accusedNameAddressLine2, style: reg),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        Text('गुन्ह्यांचे संक्षीप्त विवरण :- $briefDescription', style: reg),
        Text(briefDescLine2, style: reg),
        Text(briefDescLine3, style: reg),
        Text(briefDescLine4, style: reg),
        Text(briefDescLine5, style: reg),
        const SizedBox(height: 16),
        Text('(अधिक माहितीसाठी फिर्यादीची प्रत सोबत जोडली आहे)', style: reg),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: Text('२..', style: bld),
        ),
      ],
    ),
  );
}

Widget _buildPg2Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final ground1 = v('ground1',
      '-----------------------------------------------------------------------------------------------');
  final ground1Line2 = v('ground1Line2',
      '-----------------------------------------------------------------------------------------------');
  final ground2 = v('ground2',
      '-----------------------------------------------------------------------------------------------');
  final ground2Line2 = v('ground2Line2',
      '-----------------------------------------------------------------------------------------------');
  final ground3 = v('ground3',
      '-----------------------------------------------------------------------------------------------');
  final ground3Line2 = v('ground3Line2',
      '-----------------------------------------------------------------------------------------------');
  final ground4 = v('ground4',
      '-----------------------------------------------------------------------------------------------');
  final ground4Line2 = v('ground4Line2',
      '-----------------------------------------------------------------------------------------------');
  final ground5 = v('ground5',
      '-----------------------------------------------------------------------------------------------');
  final ground5Line2 = v('ground5Line2',
      '-----------------------------------------------------------------------------------------------');

  final relativeName = v('');
  final relativeAddress = v('');
  final relativePhone = v('');

  final accusedSig = v('');
  final accusedName = v('');
  final accusedDateTime = v('');

  final ioSig = v('');
  final ioNameRank = v('');
  final ioPs = v('');
  final ioTah = v('');
  final ioDist = v('');

  final reg = FormImagePdfHelper.mReg(10.5, 1.45);
  final bld = FormImagePdfHelper.mBld(10.5, 1.45);
  final headerTitle = FormImagePdfHelper.mBld(13.5, 1.3);

  return Container(
    width: FormImagePdfHelper.a4Width,
    height: FormImagePdfHelper.a4Height,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Text('..२..', style: bld)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'अटक करण्यासाठी आधारभूत मुद्दे (GROUNDS OF ARREST)',
            style: headerTitle,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        Text('१. $ground1', style: reg),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(ground1Line2, style: reg),
        ),
        const SizedBox(height: 6),
        Text('२. $ground2', style: reg),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(ground2Line2, style: reg),
        ),
        const SizedBox(height: 6),
        Text('३. $ground3', style: reg),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(ground3Line2, style: reg),
        ),
        const SizedBox(height: 6),
        Text('४. $ground4', style: reg),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(ground4Line2, style: reg),
        ),
        const SizedBox(height: 6),
        Text('५. $ground5', style: reg),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(ground5Line2, style: reg),
        ),
        const SizedBox(height: 16),
        Text(
          '        आपणास असेही कळविण्यात येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
          style: reg,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: reg,
            children: [
              const TextSpan(
                text: '        आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र ',
              ),
              TextSpan(text: '$relativeName ', style: bld),
              const TextSpan(text: 'रा.'),
              TextSpan(text: '$relativeAddress ', style: bld),
              const TextSpan(text: 'यांना लेखी सुचनेद्वारे/फोन क्रमांक '),
              TextSpan(text: '$relativePhone ', style: bld),
              const TextSpan(
                text: 'यावर संपर्क करुन देण्यांत आली आहे.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '        याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
          style: reg,
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('मला सुचनापत्र प्राप्त झाले', style: bld),
                  const SizedBox(height: 6),
                  Text('(आरोपीची सही $accusedSig)', style: reg),
                  const SizedBox(height: 4),
                  Text('आरोपीचे नांव $accusedName', style: reg),
                  const SizedBox(height: 4),
                  Text('दिनांक:व वेळ $accusedDateTime', style: reg),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('तपास अधि सही/- $ioSig', style: bld),
                  const SizedBox(height: 6),
                  Text('नाव/हुद्दा $ioNameRank', style: reg),
                  const SizedBox(height: 4),
                  Text('पोलीस स्टेशन $ioPs', style: reg),
                  const SizedBox(height: 4),
                  Text('ता.-$ioTah जिल्हा-$ioDist', style: reg),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
